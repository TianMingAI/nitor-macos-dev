"""Generator tests: substitution, shape switch, icon package and guards (offline, no Swift build)."""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GEN = ROOT / "scripts" / "new_app.py"


def generate(target, *extra):
    env = dict(os.environ, HOME=tempfile.mkdtemp())  # no qiaomu-profile assets: exercises the fallback note
    return subprocess.run([sys.executable, str(GEN), "--dir", str(target), "--name", "Demo", "--zh", "乔木演示",
                           "--bundle-id", "ai.qiaomu.demo", "--repo", "joeseesun/qiaomu-demo", "--lucide",
                           "definitely-not-a-lucide-icon", *extra], capture_output=True, text=True, env=env)


class NewAppTests(unittest.TestCase):
    def test_menubar_project(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "app"
            r = generate(p)
            self.assertEqual(r.returncode, 0, r.stderr)
            main = (p / "Sources/Demo/main.swift").read_text()
            self.assertIn("static let menuBar = true", main)
            self.assertIn('static let name = "乔木演示"', main)
            self.assertIn("<key>LSUIElement</key><true/>", (p / "build.sh").read_text())
            leftovers = [str(f) for f in p.rglob("*") if f.is_file() and f.suffix in {".swift", ".sh", ".py"}
                         and "__" in "".join(t for t in ("__NAME", "__REPO", "__BUNDLE", "__MENUBAR", "__TAGLINE")
                                              if t in f.read_text())]
            self.assertEqual(leftovers, [])
            self.assertTrue(os.access(p / "build.sh", os.X_OK))
            self.assertTrue((p / ".git").is_dir())
            self.assertIn("github.com/joeseesun/qiaomu-demo", (p / "Sources/Demo/SettingsView.swift").read_text())

    def test_window_project(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "app"
            r = generate(p, "--kind", "window")
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn("static let menuBar = false", (p / "Sources/Demo/main.swift").read_text())
            self.assertIn("<key>LSUIElement</key><false/>", (p / "build.sh").read_text())
            self.assertIn("拖到「应用程序」", (p / "release.sh").read_text())

    def test_icon_package_with_offline_fallback(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "app"
            generate(p)
            icon = json.loads((p / "Resources/AppIcon.icon/icon.json").read_text())
            self.assertEqual(icon["groups"][0]["layers"][0]["image-name"], "glyph.svg")
            svg = (p / "Resources/AppIcon.icon/Assets/glyph.svg").read_text()
            self.assertIn("translate(176 176) scale(28)", svg)
            self.assertIn("<path", svg)

    def test_rejects_bad_name_and_non_empty_dir(self):
        with tempfile.TemporaryDirectory() as d:
            r = subprocess.run([sys.executable, str(GEN), "--dir", d + "/x", "--name", "my app", "--zh", "x",
                                "--bundle-id", "a.b", "--repo", "a/b"], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)
            (Path(d) / "full").mkdir()
            (Path(d) / "full/file").write_text("x")
            r = subprocess.run([sys.executable, str(GEN), "--dir", d + "/full", "--name", "Ok", "--zh", "x",
                                "--bundle-id", "a.b", "--repo", "a/b"], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)


if __name__ == "__main__":
    unittest.main()
