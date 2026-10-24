import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "update_neovim", Path(__file__).resolve().parents[1] / "scripts/update_neovim.py"
)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.current = root / "current"
        self.release = root / "release"
        for directory, content in ((self.current, "old"), (self.release, "new")):
            for component in ("bin", "lib", "share"):
                (directory / component).mkdir(parents=True)
                (directory / component / "content").write_text(content)

    def test_update_keeps_previous_installation(self):
        with patch.object(updater, "version", side_effect=["v0.11.7", "v0.12.6"]):
            backup = updater.install_release(self.release, self.current, "v0.12.6")
        for component in ("bin", "lib", "share"):
            self.assertEqual((self.current / component / "content").read_text(), "new")
            self.assertEqual((backup / component / "content").read_text(), "old")

    def test_failed_verification_restores_previous_installation(self):
        with patch.object(updater, "version", side_effect=["v0.11.7", "incorrect"]):
            with self.assertRaises(RuntimeError):
                updater.install_release(self.release, self.current, "v0.12.6")
        for component in ("bin", "lib", "share"):
            self.assertEqual((self.current / component / "content").read_text(), "old")

    def test_interrupted_install_restores_all_components(self):
        rename = Path.rename

        def fail_install(path, target):
            if path.name == "lib" and path.parent.name.startswith(".update-"):
                raise OSError("Simulated failed move")
            return rename(path, target)

        with patch.object(updater, "version", return_value="v0.11.7"):
            with patch.object(Path, "rename", fail_install):
                with self.assertRaises(OSError):
                    updater.install_release(self.release, self.current, "v0.12.6")
        for component in ("bin", "lib", "share"):
            self.assertEqual((self.current / component / "content").read_text(), "old")

    def test_corrupt_download_is_rejected(self):
        digest = "sha256:" + hashlib.sha256(b"original").hexdigest()
        updater.verify_archive(b"original", digest)
        with self.assertRaises(RuntimeError):
            updater.verify_archive(b"corrupt", digest)


if __name__ == "__main__":
    unittest.main()
