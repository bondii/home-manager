"""Exercise only custom hook bodies; never run a Home Manager activation."""
import json
import pathlib
import subprocess
import sys
import tempfile


hooks = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert set(hooks) == {"createNpmPrefix", "createNvimUndoDir"}
for name, hook in hooks.items():
    assert "writeBoundary" in hook["after"], name
    body = hook["data"]
    assert body.strip().startswith("run "), (name, body)
    assert all(word not in body for word in ["sudo", "npm install", "curl", "/usr/local", "/usr/lib"])
    with tempfile.TemporaryDirectory() as tmp:
        # run never executes its arguments in dry-run mode, including absolute
        # home paths embedded by evaluation. Unexpected direct commands fail.
        script = '''set -euo pipefail
export DRY_RUN=1
run() { printf 'dry-run: %s\\n' "$*"; }
''' + body
        result = subprocess.run(
            ["bash", "-c", script], cwd=tmp,
            env={"HOME": tmp, "PATH": "/nonexistent"},
            executable=sys.argv[2], capture_output=True, text=True,
        )
        assert result.returncode == 0, result.stderr
        assert "dry-run:" in result.stdout, result.stdout
        assert list(pathlib.Path(tmp).iterdir()) == [], name
print("Custom activation hooks honor dry run and writeBoundary")
