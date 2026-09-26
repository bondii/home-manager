#!/usr/bin/env python3
"""Exercise editor functions from evaluated Zsh init without loading user config."""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


class ZshHelperTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.temp = Path(self.temp_dir.name)
        self.repo = self.temp / "repo"
        self.repo.mkdir()
        self.args_file = self.temp / "nvim-args"
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(self.temp),
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_NOSYSTEM="1",
            LC_ALL="C",
            NVIM_ARGS=str(self.args_file),
        )
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("commit", "--allow-empty", "-qm", "initial")

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.repo, env=self.env,
            check=True, capture_output=True,
        )

    def run_helper(self, helper):
        self.args_file.unlink(missing_ok=True)
        # Load only the actual generated helper definitions: the rest of the
        # init config expects an interactive terminal and installed plugins.
        script = self.functions + '\nnvim() { printf "%s\\0" "$@" > "$NVIM_ARGS"; }\n'
        subprocess.run(
            ["zsh", "-f", "-c", script + helper],
            cwd=self.repo, env=self.env, check=True, capture_output=True,
        )
        if not self.args_file.exists():
            return None
        return self.args_file.read_bytes().split(b"\0")[:-1]

    def test_clean_repository_does_not_launch_editor(self):
        for helper in ("nva", "nvu", "nvs"):
            with self.subTest(helper=helper):
                self.assertIsNone(self.run_helper(helper))

    def test_selection_deduplication_and_deleted_files(self):
        for name in ("staged", "unstaged", "both", "deleted", "deleted-staged"):
            (self.repo / name).write_text("original\n")
        self.git("add", ".")
        self.git("commit", "-qm", "fixtures")
        for name in ("staged", "both"):
            (self.repo / name).write_text("staged change\n")
        self.git("add", "staged", "both")
        for name in ("unstaged", "both", "untracked"):
            (self.repo / name).write_text("working change\n")
        (self.repo / "deleted").unlink()
        self.git("rm", "deleted-staged")
        for helper, names in {
            "nva": [b"both", b"staged", b"unstaged", b"untracked"],
            "nvu": [b"both", b"unstaged"],
            "nvs": [b"both", b"staged"],
        }.items():
            with self.subTest(helper=helper):
                self.assertEqual(self.run_helper(helper), [b"--", *names])

    def test_filename_boundaries_for_each_selection(self):
        names = [
            "space name", "tab\tname", "new\nline", "trailing\n",
            "räksmörgås", "-leading", 'quote"name', "back\\slash",
        ]
        expected = [b"--", *sorted(name.encode() for name in names)]
        for name in names:
            (self.repo / name).write_text("original\n")
        self.assertEqual(self.run_helper("nva"), expected)
        self.assertIsNone(self.run_helper("nvu"))
        self.assertIsNone(self.run_helper("nvs"))
        self.git("add", ".")
        self.assertEqual(self.run_helper("nvs"), expected)
        self.assertEqual(self.run_helper("nva"), expected)
        self.git("commit", "-qm", "filenames")
        for name in names:
            (self.repo / name).write_text("changed\n")
        self.assertEqual(self.run_helper("nvu"), expected)
        self.assertEqual(self.run_helper("nva"), expected)
        self.assertIsNone(self.run_helper("nvs"))


if __name__ == "__main__":
    init = Path(sys.argv.pop(1)).read_text()
    functions = []
    for helper in ("nva", "nvu", "nvs"):
        match = re.search(r"(?ms)^ *" + helper + r"\(\) \{.*?^ *\}[ \t]*$", init)
        if match is None:
            raise ValueError(f"Missing generated {helper} function")
        functions.append(match.group())
    ZshHelperTests.functions = "\n".join(functions)
    unittest.main()
