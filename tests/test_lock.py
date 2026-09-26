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
fd = os.environ.get("XSS_SLEEP_LOCK_FD")
if name != "i3lock" and fd and Path(f"/proc/self/fd/{fd}").exists():
    (state / "preparation-inherited-fd").touch()
if name in ("mktemp", "maim", "magick"):
    (state / "preparation-calls").open("a").write(name + "\n")
for delay in os.environ.get("LOCK_TEST_PREP_DELAYS", "").split(","):
    if delay.startswith(name + ":"):
        time.sleep(float(delay.split(":", 1)[1]))
if os.environ.get("LOCK_TEST_HANG") == name:
    (state / f"{name}-pid").write_text(str(os.getpid()))
    time.sleep(10)

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
    Path(output).write_bytes(b"" if mode == "empty-image" else data)
elif name == "rm":
    Path(sys.argv[-1]).unlink(missing_ok=True)
elif name == "i3lock":
    with (state / "calls").open("a") as calls:
        calls.write(" ".join(sys.argv[1:]) + "\n")
    (state / "locker-pid").write_text(str(os.getpid()))
    fd = os.environ.get("XSS_SLEEP_LOCK_FD")
    ready_barrier = os.environ.get("LOCK_TEST_READY_BARRIER")
    wait_file = os.environ.get("LOCK_TEST_WAIT_FILE")
    if wait_file:
        def stop(_signal, _frame):
            (state / "locker-signalled").touch()
            sys.exit(128 + _signal)
        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
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
    if wait_file:
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
        for name in ("mktemp", "maim", "magick", "rm", "i3lock"):
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

    def assert_no_preparation_fd(self):
        self.assertFalse((self.state / "preparation-inherited-fd").exists())

    def preparation_calls(self):
        path = self.state / "preparation-calls"
        return path.read_text().splitlines() if path.exists() else []

    def assert_image_preparation(self):
        calls = self.preparation_calls()
        self.assertEqual(calls[:1], ["mktemp"])
        self.assertCountEqual(calls[1:], ["maim", "magick"])

    def clear_state(self):
        for path in self.state.iterdir():
            path.unlink()

    def test_image_mode_and_private_cleanup(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertRegex(self.calls()[0], r"^-n -i .+lock-pixel\..+\.png$")
        path = Path((self.state / "tmp-path").read_text())
        self.assertEqual((self.state / "tmp-mode").read_text(), "0o600")
        self.assertFalse(path.exists())

    def test_manual_image_preparation_keeps_its_existing_time_budget(self):
        env = self.env()
        env["LOCK_TEST_PREP_DELAYS"] = "maim:2.2"
        result = subprocess.run(
            ["bash", "-e", str(SCRIPT)], env=env, capture_output=True, text=True, timeout=5
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn("-n -i", self.calls()[0])
        self.assert_no_temp_image()

    def test_preparation_failures_fall_back_to_solid(self):
        for failure in ("mktemp", "maim", "magick", "empty-image"):
            with self.subTest(failure=failure):
                self.clear_state()
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
                self.clear_state()
                env = self.env()
                env["XSS_SLEEP_LOCK_FD"] = value
                result = subprocess.run(
                    ["bash", "-e", str(SCRIPT)], env=env, capture_output=True, text=True, timeout=5
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(self.calls()), 1)

    def test_suspend_uses_solid_without_runtime_directory(self):
        read_fd, write_fd = os.pipe()
        env = self.env()
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        env["XDG_RUNTIME_DIR"] = str(self.base / "missing-runtime")
        try:
            result = subprocess.run(
                ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,), capture_output=True, text=True, timeout=5
            )
            os.close(write_fd)
            write_fd = -1
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.calls(), ["-n -c 000000"])
            self.assertEqual(self.preparation_calls(), ["mktemp"])
            self.assert_no_preparation_fd()
            self.assertEqual(os.read(read_fd, 1), b"")
        finally:
            os.close(read_fd)
            if write_fd != -1:
                os.close(write_fd)

    def test_suspend_preparation_failures_hold_inhibitor_until_solid_ready(self):
        for failure in ("mktemp", "maim", "magick", "empty-image"):
            with self.subTest(failure=failure):
                self.clear_state()
                read_fd, write_fd = os.pipe()
                barrier = self.base / f"ready-after-{failure}"
                release = self.base / f"unlock-after-{failure}"
                env = self.env(failure)
                env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
                env["LOCK_TEST_READY_BARRIER"] = str(barrier)
                env["LOCK_TEST_WAIT_FILE"] = str(release)
                process = subprocess.Popen(
                    ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                )
                os.close(write_fd)
                try:
                    deadline = time.monotonic() + 3
                    while not (self.state / "before-ready").exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue((self.state / "before-ready").exists())
                    self.assertEqual(self.calls(), ["-n -c 000000"])
                    self.assert_no_preparation_fd()
                    selector = selectors.DefaultSelector()
                    selector.register(read_fd, selectors.EVENT_READ)
                    self.assertFalse(selector.select(timeout=0.1), "inhibitor closed before solid locker readiness")
                    barrier.touch()
                    self.assertTrue(selector.select(timeout=1), "inhibitor did not close at readiness")
                    self.assertEqual(os.read(read_fd, 1), b"")
                    release.touch()
                    self.assertEqual(process.wait(timeout=3), 0)
                    process.communicate()
                    self.assert_no_temp_image()
                finally:
                    os.close(read_fd)
                    if process.poll() is None:
                        process.kill()
                        process.communicate()

    def test_suspend_one_deadline_covers_mktemp_and_capture(self):
        read_fd, write_fd = os.pipe()
        env = self.env()
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        env["LOCK_TEST_PREP_DELAYS"] = "mktemp:1.1,maim:1.1"
        try:
            started = time.monotonic()
            result = subprocess.run(
                ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
                capture_output=True, text=True, timeout=5,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertLess(time.monotonic() - started, 3.5)
            self.assertEqual(self.calls(), ["-n -c 000000"])
            self.assert_no_preparation_fd()
            self.assert_no_temp_image()
        finally:
            os.close(read_fd)
            os.close(write_fd)

    def test_suspend_hung_capture_falls_back_and_reaps_helpers(self):
        for name in ("mktemp", "maim", "magick"):
            with self.subTest(name=name):
                self.clear_state()
                read_fd, write_fd = os.pipe()
                env = self.env()
                env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
                env["LOCK_TEST_HANG"] = name
                try:
                    result = subprocess.run(
                        ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
                        capture_output=True, text=True, timeout=5,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(self.calls(), ["-n -c 000000"])
                    self.assert_no_preparation_fd()
                    self.assert_no_temp_image()
                    pid = int((self.state / f"{name}-pid").read_text())
                    with self.assertRaises(OSError) as error:
                        os.kill(pid, 0)
                    self.assertEqual(error.exception.errno, errno.ESRCH)
                finally:
                    os.close(read_fd)
                    os.close(write_fd)

    def test_suspend_holds_inhibitor_while_capturing(self):
        read_fd, write_fd = os.pipe()
        env = self.env()
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        env["LOCK_TEST_HANG"] = "maim"
        process = subprocess.Popen(
            ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        os.close(write_fd)
        try:
            deadline = time.monotonic() + 1
            while not (self.state / "maim-pid").exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue((self.state / "maim-pid").exists())
            selector = selectors.DefaultSelector()
            selector.register(read_fd, selectors.EVENT_READ)
            self.assertFalse(selector.select(timeout=0.1), "inhibitor closed during image capture")
            self.assert_no_preparation_fd()
            self.assertEqual(process.wait(timeout=4), 0)
            process.communicate()
            self.assertEqual(self.calls(), ["-n -c 000000"])
            self.assertTrue(selector.select(timeout=1))
            self.assertEqual(os.read(read_fd, 1), b"")
            self.assert_no_temp_image()
        finally:
            os.close(read_fd)
            if process.poll() is None:
                process.kill()
                process.communicate()

    def test_suspend_signal_during_capture_stops_preparation(self):
        for sent_signal, expected_status in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            with self.subTest(sent_signal=sent_signal):
                self.clear_state()
                read_fd, write_fd = os.pipe()
                env = self.env()
                env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
                env["LOCK_TEST_HANG"] = "maim"
                process = subprocess.Popen(
                    ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                )
                os.close(write_fd)
                try:
                    deadline = time.monotonic() + 2
                    while not (self.state / "maim-pid").exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue((self.state / "maim-pid").exists())
                    process.send_signal(sent_signal)
                    self.assertEqual(process.wait(timeout=3), expected_status)
                    process.communicate()
                    self.assert_no_preparation_fd()
                    self.assert_no_temp_image()
                    self.assertEqual(os.read(read_fd, 1), b"")
                    pid = int((self.state / "maim-pid").read_text())
                    with self.assertRaises(OSError) as error:
                        os.kill(pid, 0)
                    self.assertEqual(error.exception.errno, errno.ESRCH)
                finally:
                    os.close(read_fd)
                    if process.poll() is None:
                        process.kill()
                        process.communicate()

    def test_suspend_signal_during_mktemp_cleans_up_after_timeout(self):
        read_fd, write_fd = os.pipe()
        env = self.env()
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        env["LOCK_TEST_HANG"] = "mktemp"
        process = subprocess.Popen(
            ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        os.close(write_fd)
        try:
            deadline = time.monotonic() + 1
            while not (self.state / "mktemp-pid").exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue((self.state / "mktemp-pid").exists())
            process.send_signal(signal.SIGTERM)
            self.assertEqual(process.wait(timeout=3), 143)
            process.communicate()
            self.assert_no_preparation_fd()
            self.assert_no_temp_image()
            self.assertEqual(self.calls(), [])
            self.assertEqual(os.read(read_fd, 1), b"")
            pid = int((self.state / "mktemp-pid").read_text())
            with self.assertRaises(OSError) as error:
                os.kill(pid, 0)
            self.assertEqual(error.exception.errno, errno.ESRCH)
        finally:
            os.close(read_fd)
            if process.poll() is None:
                process.kill()
                process.communicate()

    def test_suspend_image_locker_failure_tries_solid(self):
        read_fd, write_fd = os.pipe()
        env = self.env("both-lockers")
        env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
        try:
            result = subprocess.run(
                ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,), capture_output=True, text=True, timeout=5
            )
            self.assertEqual(result.returncode, 9, result.stderr)
            self.assertEqual(len(self.calls()), 2)
            self.assertIn("-n -i", self.calls()[0])
            self.assertEqual((self.state / "tmp-mode").read_text(), "0o600")
            self.assertEqual(self.calls()[1], "-n -c 000000")
            self.assert_image_preparation()
            self.assert_no_preparation_fd()
            self.assert_no_temp_image()
        finally:
            os.close(read_fd)
            os.close(write_fd)

    def test_suspend_signals_before_readiness(self):
        for sent_signal, expected_status in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            with self.subTest(sent_signal=sent_signal):
                self.clear_state()
                read_fd, write_fd = os.pipe()
                barrier = self.base / f"barrier-{sent_signal}"
                env = self.env()
                env["XSS_SLEEP_LOCK_FD"] = str(write_fd)
                env["LOCK_TEST_READY_BARRIER"] = str(barrier)
                env["LOCK_TEST_WAIT_FILE"] = str(self.base / f"never-release-{sent_signal}")
                process = subprocess.Popen(
                    ["bash", "-e", str(SCRIPT)], env=env, pass_fds=(write_fd,), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
                )
                os.close(write_fd)
                try:
                    deadline = time.monotonic() + 3
                    while not (self.state / "before-ready").exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue((self.state / "before-ready").exists())
                    process.send_signal(sent_signal)
                    self.assertEqual(process.wait(timeout=3), expected_status)
                    process.communicate()
                    self.assertEqual(len(self.calls()), 1)
                    self.assertIn("-n -i", self.calls()[0])
                    self.assert_image_preparation()
                    self.assert_no_preparation_fd()
                    self.assertTrue((self.state / "locker-signalled").exists())
                    self.assertEqual(os.read(read_fd, 1), b"")
                    locker_pid = int((self.state / "locker-pid").read_text())
                    with self.assertRaises(OSError) as error:
                        os.kill(locker_pid, 0)
                    self.assertEqual(error.exception.errno, errno.ESRCH)
                finally:
                    os.close(read_fd)
                    if process.poll() is None:
                        process.kill()
                        process.wait()

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
            self.assert_image_preparation()
            self.assert_no_preparation_fd()
            self.assertIn("-n -i", self.calls()[0])
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
            self.assert_no_temp_image()
        finally:
            os.close(read_fd)
            if process.poll() is None:
                process.kill()
                process.wait()

    def test_term_and_int_are_forwarded_and_clean_up(self):
        for sent_signal, expected_status in ((signal.SIGTERM, 143), (signal.SIGINT, 130)):
            with self.subTest(sent_signal=sent_signal):
                self.clear_state()
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
