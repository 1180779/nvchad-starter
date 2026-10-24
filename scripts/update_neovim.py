#!/usr/bin/env python3
"""Update a writable Neovim tarball installation from the official stable release."""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "neovim-updater"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def version(binary):
    output = subprocess.check_output([str(binary), "--version"], text=True)
    return output.splitlines()[0].removeprefix("NVIM ")


def verify_archive(data, digest):
    actual = "sha256:" + hashlib.sha256(data).hexdigest()
    if actual != digest:
        raise RuntimeError("Archive SHA-256 does not match GitHub release metadata")


def install_release(source, destination, expected_version):
    """Replace bin/lib/share together, retaining the old files for rollback."""
    components = ("bin", "lib", "share")
    old_version = version(destination / "bin/nvim")
    backup = Path(tempfile.mkdtemp(prefix=f".backup-{old_version}-", dir=destination))
    saved = []
    installed = []
    with tempfile.TemporaryDirectory(prefix=".update-", dir=destination) as staging:
        staging = Path(staging)
        try:
            for component in components:
                shutil.copytree(source / component, staging / component, symlinks=True)
            for component in components:
                (destination / component).rename(backup / component)
                saved.append(component)
                (staging / component).rename(destination / component)
                installed.append(component)
            if version(destination / "bin/nvim") != expected_version:
                raise RuntimeError("Installed Neovim version does not match the release")
        except BaseException:
            for component in reversed(installed):
                shutil.rmtree(destination / component)
            for component in reversed(saved):
                (backup / component).rename(destination / component)
            raise
    return backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--install-dir", type=Path, default=Path("/usr/local/nvim"))
    args = parser.parse_args()
    destination = args.install_dir.resolve()
    if not (destination / "bin/nvim").is_file():
        parser.error(f"No existing Neovim tarball installation in {destination}")

    architecture = subprocess.check_output(["uname", "-m"], text=True).strip()
    architecture = {"x86_64": "x86_64", "aarch64": "arm64"}.get(architecture)
    if architecture is None:
        parser.error("Only Linux x86_64 and arm64 releases are supported")

    release = json.loads(fetch("https://api.github.com/repos/neovim/neovim/releases/latest"))
    latest = release["tag_name"]
    if release["prerelease"] or release["draft"] or not re.fullmatch(r"v\d+\.\d+\.\d+", latest):
        raise RuntimeError("GitHub did not return a stable release")
    current = version(destination / "bin/nvim")
    if current == latest:
        print(f"Neovim {latest} is already installed")
        return

    asset_name = f"nvim-linux-{architecture}.tar.gz"
    asset = next(asset for asset in release["assets"] if asset["name"] == asset_name)
    digest = asset.get("digest", "") or ""
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise RuntimeError("GitHub release metadata has no SHA-256 for this archive")
    print(f"Downloading Neovim {latest} (currently {current})", flush=True)
    archive = fetch(f"https://github.com/neovim/neovim/releases/download/{latest}/{asset_name}")
    verify_archive(archive, digest)

    with tempfile.TemporaryDirectory(prefix="neovim-download-") as temporary:
        temporary = Path(temporary)
        archive_path = temporary / asset_name
        archive_path.write_bytes(archive)
        with tarfile.open(archive_path) as package:
            package.extractall(temporary, filter="data")
        source = temporary / f"nvim-linux-{architecture}"
        if version(source / "bin/nvim") != latest:
            raise RuntimeError("Downloaded Neovim version does not match the release")
        print("Archive verified; installing. Close other Neovim sessions before updating.", flush=True)
        backup = install_release(source, destination, latest)

    print(f"Installed Neovim {latest} in {destination}")
    print(f"Previous installation saved in {backup}")
    print("Restart Neovim to use the new version.")


if __name__ == "__main__":
    main()
