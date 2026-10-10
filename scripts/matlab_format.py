#!/usr/bin/env python3
"""Run MISS_HIT, distinguishing parse failures from remaining style issues."""

import shutil
import subprocess
import sys


def main():
    executable = shutil.which("mh_style")
    if executable is None:
        print("Install MISS_HIT with :MasonInstall miss_hit", file=sys.stderr)
        return 2

    result = subprocess.run(
        [executable, "--brief", *sys.argv[1:]], capture_output=True, text=True
    )
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    # MISS_HIT returns 1 both for style findings and for parse errors. Its
    # brief diagnostics contain ': error:' only for errors, without source
    # excerpts that could otherwise produce a false match.
    if ": error:" in result.stdout or ": error:" in result.stderr:
        return 2
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
