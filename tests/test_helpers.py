#!/usr/bin/env python3
"""Smoke tests for the interactive helper applications.

The helpers are passed as absolute paths so this test exercises the generated
writeShellApplication wrappers, including their declared runtime inputs.
"""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class HelperTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.temp = Path(self.temp_dir.name)
        self.home = self.temp / "home"
        self.home.mkdir()
        self.bin_dir = self.temp / "bin"
        self.bin_dir.mkdir()
        self.nvim_args = self.temp / "nvim-args"
        (self.bin_dir / "nvim").write_text(
            '#!/bin/sh\nprintf \'%s\\0\' "$@" > "$NVIM_ARGS"\n'
        )
        (self.bin_dir / "nvim").chmod(0o755)

    def tearDown(self):
        self.temp_dir.cleanup()

    def env(self, *, fzf_filter=None, **extra):
        result = os.environ.copy()
        result.update(
            {
                "HOME": str(self.home),
                "HISTFILE": str(self.home / ".histfile"),
                "NVIM_ARGS": str(self.nvim_args),
                "PATH": f"{self.bin_dir}:{result['PATH']}",
            }
        )
        if fzf_filter is not None:
            fzf_options = self.temp / "fzf-options"
            fzf_options.write_text(f"--filter={fzf_filter}\n")
            result["FZF_DEFAULT_OPTS_FILE"] = str(fzf_options)
        result.update(extra)
        return result

    def run_command(self, command, *, cwd, env):
        return subprocess.run(
            command,
            check=True,
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
        )

    def captured_nvim_args(self):
        return self.nvim_args.read_bytes().split(b"\0")[:-1]

    def test_file_helpers_open_spaced_filename_and_preserve_history(self):
        project = self.temp / "project"
        project.mkdir()
        file_name = "file with spaces.txt"
        (project / file_name).write_text("needle\n")

        self.run_command(
            [self.helpers.sf, "file with spaces"],
            cwd=project,
            env=self.env(fzf_filter="spaces"),
        )
        self.assertEqual(self.captured_nvim_args(), [file_name.encode()])
        history = (self.home / ".histfile").read_text()
        self.assertIn("nv", history)
        self.assertIn("file", history)

        self.run_command(
            [self.helpers.sfg, "needle"],
            cwd=project,
            env=self.env(fzf_filter="spaces"),
        )
        self.assertEqual(self.captured_nvim_args(), [file_name.encode()])

        self.run_command(
            [self.helpers.sg, "needle"],
            cwd=project,
            env=self.env(fzf_filter="spaces"),
        )
        self.assertEqual(
            self.captured_nvim_args(),
            [b"+call cursor(1,1)", b"--", f"./{file_name}".encode()],
        )
        self.assertIn("nv", (self.home / ".histfile").read_text())

    def test_opac_worktree_copies_local_configuration_from_spaced_repo(self):
        repository = self.temp / "repository with spaces"
        repository.mkdir()
        self.run_command(["git", "init"], cwd=repository, env=self.env())
        self.run_command(
            ["git", "config", "user.email", "test@example.invalid"],
            cwd=repository,
            env=self.env(),
        )
        self.run_command(
            ["git", "config", "user.name", "Test User"], cwd=repository, env=self.env()
        )
        files = {
            ".env": "SECRET=value\n",
            ".envrc": "use flake\n",
            "AGENTS.md": "instructions\n",
            "tracked.txt": "tracked\n",
        }
        for name, contents in files.items():
            (repository / name).write_text(contents)
        self.run_command(["git", "add", "."], cwd=repository, env=self.env())
        self.run_command(
            ["git", "commit", "-m", "initial"], cwd=repository, env=self.env()
        )

        branch = "feature/test"
        self.run_command([self.helpers.opac_wt, branch], cwd=repository, env=self.env())
        worktree = self.home / "opac" / "wt" / repository.name / "feature" / "test"
        self.assertEqual(
            self.run_command(
                ["git", "rev-parse", "--show-toplevel"], cwd=worktree, env=self.env()
            ).stdout.strip(),
            str(worktree),
        )
        for name, contents in files.items():
            if name != "tracked.txt":
                self.assertEqual((worktree / name).read_text(), contents)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("sf")
    parser.add_argument("sg")
    parser.add_argument("sfg")
    parser.add_argument("opac_wt")
    HelperTests.helpers = parser.parse_args()
    unittest.main(argv=[sys.argv[0]])
