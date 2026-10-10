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
    errors = [
        line
        for line in (result.stdout + result.stderr).splitlines()
        if ": error:" in line and "file is not auto-fixed" not in line
    ]
    if ": error:" in result.stdout or ": error:" in result.stderr:
        for line in errors:
            if "script-global functions are an Octave-specific feature" in line:
                line = line.split(": error:", 1)[0] + (
                    ": error: MISS_HIT does not support local functions midway "
                    "through a MATLAB script. Move local functions to the end "
                    "of the file."
                )
            print(line, file=sys.stderr)
        return 2
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
