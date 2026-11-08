"""Brand assets and runtime configuration survive generation without personal-data dependencies."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('new_app', ROOT / 'scripts/new_app.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class BrandingTests(unittest.TestCase):
    def test_optional_assets_are_independent_and_config_is_preserved(self):
        for filename in (None, 'wechat-qr.jpg', 'reward-qr.png'):
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as d:
                fixture = Path(d) / 'skill'
                (fixture / 'assets/brand').mkdir(parents=True)
                shutil.copy2(ROOT / 'NOTICE.md', fixture / 'NOTICE.md')
                config = json.loads((ROOT / 'assets/brand.json').read_text())
                config.update(website='https://example.com/nitor', wechat_name='Nitor "中文"', feedback_email='owner@example.com')
                brand_path = fixture / 'assets/brand.json'
                brand_path.write_text(json.dumps(config, ensure_ascii=False))
                if filename:
                    (fixture / 'assets/brand' / filename).write_bytes(b'owner-supplied-asset')
                target = Path(d) / 'app'
                argv = ['new_app.py', '--dir', str(target), '--name', 'Demo', '--zh', 'Nitor演示',
                        '--bundle-id', 'ai.nitor.demo', '--repo', 'TianMingAI/nitor-demo']
                with patch.object(generator, 'SKILL', fixture), patch.object(generator, 'BRAND', brand_path), \
                     patch.dict(os.environ, {'NITOR_OFFLINE': '1'}), patch('sys.argv', argv), contextlib.redirect_stdout(io.StringIO()):
                    generator.main()
                about = target / 'Resources/About'
                self.assertEqual(json.loads((about / 'brand.json').read_text()), config)
                self.assertEqual({p.name for p in about.iterdir()}, {'brand.json'} | ({filename} if filename else set()))
                if filename:
                    self.assertEqual((about / filename).read_bytes(), b'owner-supplied-asset')
                self.assertIn('向阳乔木', (target / 'LICENSE').read_text())
                self.assertIn('Nitor', (target / 'LICENSE').read_text())
                runtime = '\n'.join(p.read_text() for p in (target / 'Sources').rglob('*.swift'))
                for old_identity in ('qiaomu', 'joeseesun', 'vista8', '乔木'):
                    self.assertNotIn(old_identity, runtime)

    @unittest.skipUnless(shutil.which('swiftc'), 'Swift compiler unavailable')
    def test_swift_brand_loading_and_safe_optional_links(self):
        with tempfile.TemporaryDirectory() as d:
            tmp = Path(d)
            harness = tmp / 'main.swift'
            harness.write_text(r'''
import Foundation
let path = URL(fileURLWithPath: CommandLine.arguments[1])
let b = Brand.load(from: path)
precondition(b.name == "Nitor")
precondition(b.wechat_name.isEmpty)
precondition(Brand.webURL(b.github_url)?.host == "github.com")
precondition(Brand.webURL(b.website) == nil)
precondition(b.feedbackURL == nil)
precondition(Brand.load(from: nil).name == "Nitor")
precondition(Brand.webURL("javascript:alert(1)") == nil)
precondition(Brand.webURL("https:") == nil)
let contact = Brand(name: "Nitor", english_name: "Nitor", github_url: "", website: "",
                    wechat_name: "", feedback_email: "nitor+app@example.com")
precondition(contact.feedbackURL?.scheme == "mailto")
let bad = Brand(name: "Nitor", english_name: "Nitor", github_url: "", website: "",
                wechat_name: "", feedback_email: "nitor@example.com?bcc=someone@example.com")
precondition(bad.feedbackURL == nil)
print("Brand runtime checks passed")
''')
            result = subprocess.run(['swiftc', '-module-cache-path', str(tmp / 'cache'),
                str(ROOT / 'assets/template/Sources/__NAME__/Brand.swift'), str(harness), '-o', str(tmp / 'brand-check')],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run([str(tmp / 'brand-check'), str(ROOT / 'assets/brand.json')], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('Brand runtime checks passed', result.stdout)


if __name__ == '__main__':
    unittest.main()
