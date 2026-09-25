#!/usr/bin/env python3
import errno
import os
from pathlib import Path
import selectors
import signal
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "lib" / "lock-pixel.sh"


MOCK = r'''#!/usr/bin/env python3
import os
from pathlib import Path
import signal
import sys
import time

name = Path(sys.argv[0]).name
state = Path(os.environ["LOCK_TEST_STATE"])
mode = os.environ.get("LOCK_TEST_FAIL", "")

if name == "mktemp":
    if mode == "mktemp":
        sys.exit(1)
    runtime = next(a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--tmpdir="))
    fd, path = __import__("tempfile").mkstemp(prefix="lock-pixel.", suffix=".png", dir=runtime)
    os.close(fd)
    (state / "tmp-path").write_text(path)
    print(path)
elif name == "maim":
    if mode == "maim":
        sys.exit(2)
    sys.stdout.buffer.write(b"screen")
elif name == "magick":
    data = sys.stdin.buffer.read()
    if mode == "magick":
        sys.exit(3)
    output = sys.argv[-1].split(":", 1)[1]
    (state / "tmp-mode").write_text(oct(Path(output).stat().st_mode & 0o777))
    Path(output).write_bytes(data)
elif name == "i3lock":
    with (state / "calls").open("a") as calls:
        calls.write(" ".join(sys.argv[1:]) + "\n")
    (state / "locker-pid").write_text(str(os.getpid()))
    fd = os.environ.get("XSS_SLEEP_LOCK_FD")
    ready_barrier = os.environ.get("LOCK_TEST_READY_BARRIER")
    if ready_barrier:
        (state / "before-ready").touch()
        while not Path(ready_barrier).exists():
            time.sleep(0.01)
    if fd:
        os.close(int(fd))
    (state / "ready").touch()
    if "-i" in sys.argv and mode == "image-locker":
        sys.exit(7)
    if "-c" in sys.argv and mode in ("solid-locker", "both-lockers"):
        sys.exit(9)
    if "-i" in sys.argv and mode == "both-lockers":
        sys.exit(7)
    wait_file = os.environ.get("LOCK_TEST_WAIT_FILE")
    if wait_file:
        def stop(_signal, _frame):
            (state / "locker-signalled").touch()
            sys.exit(128 + _signal)
        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        while not Path(wait_file).exists():
            time.sleep(0.01)
'''


class LockPixelTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.state = self.base / "state"
        self.runtime = self.base / "runtime"
        self.bin.mkdir()
        self.state.mkdir()
        self.runtime.mkdir()
        for name in ("mktemp", "maim", "magick", "i3lock"):
            path = self.bin / name
            path.write_text(f"#!{sys.executable}\n" + MOCK.split("\n", 1)[1])
            path.chmod(0o755)

    def tearDown(self):
        self.temp.cleanup()

    def env(self, failure=""):
        env = os.environ.copy()
        env.update(
            PATH=f"{self.bin}:{env['PATH']}",
            LOCK_PIXEL_LOCKER=str(self.bin / "i3lock"),
            LOCK_TEST_STATE=str(self.state),
            LOCK_TEST_FAIL=failure,
            XDG_RUNTIME_DIR=str(self.runtime),
        )
        env.pop("XSS_SLEEP_LOCK_FD", None)
        return env

    def run_script(self, failure="", **kwargs):
        return subprocess.run(
            ["bash", "-e", str(SCRIPT)],
            env=self.env(failure),
            text=True,
            capture_output=True,
            timeout=5,
            **kwargs,
        )

    def calls(self):
        path = self.state / "calls"
        return path.read_text().splitlines() if path.exists() else []

    def assert_no_temp_image(self):
        recorded = self.state / "tmp-path"
        if recorded.exists():
            self.assertFalse(Path(recorded.read_text()).exists())

    def test_image_mode_and_private_cleanup(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertRegex(self.calls()[0], r"^-n -i .+lock-pixel\..+\.png$")
        path = Path((self.state / "tmp-path").read_text())
        self.assertEqual((self.state / "tmp-mode").read_text(), "0o600")
        self.assertFalse(path.exists())

    def test_preparation_failures_fall_back_to_solid(self):
        for failure in ("mktemp", "maim", "magick"):
            with self.subTest(failure=failure):
                for path in self.state.iterdir():
                    path.unlink()
                result = self.run_script(failure)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.calls(), ["-n -c 000000"])
                self.assert_no_temp_image()

    def test_image_locker_failure_retries_and_propagates_fallback_failure(self):
        result = self.run_script("both-lockers")
        self.assertEqual(result.returncode, 9, result.stderr)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn("-n -i", self.calls()[0])
        self.assertEqual(self.calls()[1], "-n -c 000000")
        self.assert_no_temp_image()

    def test_invalid_descriptor_does_not_prevent_locking(self):
        for value in ("bogus", "08", "99999999999999999999", "9999", "2"):
            with self.subTest(value=value):
                for path in self.state.iterdir():
                    path.unlink()
                env = self.env()
                env["XSS_SLEEP_LOCK_FD"] = value
                result = subprocess.run(
                    ["bash", "-e", str(SCRIPT)], env=env, capture_output=True, text=True, timeout=5
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(self.calls()), 1)

    def test_parent_releases_descriptor_while_locker_remains_alive(self):
        read_fd, write_fd = os.pipe()
        release = self.base / "release"
        ready_barrier = self.base / "allow-ready"
        env = self.env()
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        env["LOCK_TEST_WAIT_FILE"] = str(release)
        env["LOCK_TEST_READY_BARRIER"] = str(ready_barrier)
        process = subprocess.Popen(
            ["bash", "-e", str(SCRIPT)],
            env=env,
            pass_fds=(write_fd,),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        os.close(write_fd)
        try:
            deadline = time.monotonic() + 3
            while not (self.state / "before-ready").exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue((self.state / "before-ready").exists())
            self.assertIsNone(process.poll())
            selector = selectors.DefaultSelector()
            selector.register(read_fd, selectors.EVENT_READ)
            self.assertFalse(
                selector.select(timeout=0.1),
                "sleep descriptor reached EOF before the locker readiness barrier",
            )

            ready_barrier.touch()
            while not (self.state / "ready").exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue((self.state / "ready").exists())
            self.assertIsNone(process.poll())
            self.assertTrue(selector.select(timeout=1), "sleep descriptor never became readable")
            self.assertEqual(os.read(read_fd, 1), b"", "sleep descriptor was still held open")
            self.assertIsNone(process.poll(), "wrapper exited before unlock")
            release.touch()
            self.assertEqual(process.wait(timeout=3), 0)
            process.communicate()
        finally:
            os.close(read_fd)
            if process.poll() is None:
                process.kill()
                process.wait()

    def test_term_and_int_are_forwarded_and_clean_up(self):
        for sent_signal, expected_status in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            with self.subTest(sent_signal=sent_signal):
                for path in self.state.iterdir():
                    path.unlink()
                release = self.base / f"never-release-{sent_signal}"
                env = self.env()
                env["LOCK_TEST_WAIT_FILE"] = str(release)
                process = subprocess.Popen(
                    ["bash", "-e", str(SCRIPT)],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
                deadline = time.monotonic() + 3
                while not (self.state / "ready").exists() and time.monotonic() < deadline:
                    time.sleep(0.01)
                self.assertTrue((self.state / "ready").exists())
                locker_pid = int((self.state / "locker-pid").read_text())
                process.send_signal(sent_signal)
                self.assertEqual(process.wait(timeout=3), expected_status)
                process.communicate()
                self.assertTrue((self.state / "locker-signalled").exists())
                self.assert_no_temp_image()
                with self.assertRaises(OSError) as error:
                    os.kill(locker_pid, 0)
                self.assertEqual(error.exception.errno, errno.ESRCH)


if __name__ == "__main__":
    unittest.main()
