#!/usr/bin/env python3
"""Scaffold a polished macOS macOS app (SwiftPM; menu bar or window) from qiaomu-macos-dev's template.

Example:
  python3 scripts/new_app.py --dir ~/Code/qiaomu-clip --name Clip --zh 乔木剪 \
      --bundle-id ai.qiaomu.clip --repo joeseesun/qiaomu-clip \
      --tagline "一句话说明它为你做什么" --lucide scissors --symbol scissors

Produces a git-initialised project that builds with ./build.sh, has a settings window with About,
Sparkle auto-update wiring, signing/notarization/DMG scripts, and --snapshot / --selftest modes.
Network: fetches one Lucide SVG from jsdelivr for the icon (falls back to a built-in glyph).
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent
TEMPLATE = SKILL / "assets" / "template"
PROFILE = Path.home() / ".agents/skills/qiaomu-profile/assets"
LUCIDE = "https://cdn.jsdelivr.net/npm/lucide-static@1.67.0/icons/{}.svg"
TEXT_SUFFIXES = {".swift", ".sh", ".py", ".json", ".md", ".entitlements", ".svg", ".txt", ""}


def fail(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def lucide_paths(name):
    """Inner elements of a Lucide icon (24×24 grid, stroke-based)."""
    try:
        with urllib.request.urlopen(LUCIDE.format(name), timeout=15) as r:
            svg = r.read().decode()
    except Exception as e:  # offline or unknown icon: keep scaffolding
        print(f"warning: Lucide icon '{name}' unavailable ({e}); using a built-in glyph")
        return '<path d="M12 3l2.6 5.6L20 11l-5.4 2.4L12 19l-2.6-5.6L4 11l5.4-2.4z"/>'
    body = re.sub(r"<!--.*?-->", "", svg, flags=re.S)
    inner = re.search(r"<svg[^>]*>(.*)</svg>", body, flags=re.S)
    return inner.group(1).strip() if inner else ""


def write_icon(project, lucide):
    """Icon Composer package: dark Vercel-style fill + one white Lucide glyph layer (1024 canvas)."""
    icon = project / "Resources/AppIcon.icon"
    (icon / "Assets").mkdir(parents=True, exist_ok=True)
    glyph = lucide_paths(lucide)
    (icon / "Assets/glyph.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        f'  <!-- Lucide "{lucide}" (ISC) -->\n'
        '  <g transform="translate(176 176) scale(28)" fill="none" stroke="#FFFFFF" stroke-width="1.9" '
        'stroke-linecap="round" stroke-linejoin="round">'
        f"{glyph}</g>\n</svg>\n")
    (icon / "icon.json").write_text(json.dumps({
        "fill": {"automatic-gradient": "srgb:0.07843,0.07843,0.07843,1.00000"},
        "groups": [{
            "layers": [{"image-name": "glyph.svg", "name": "glyph"}],
            "shadow": {"kind": "neutral", "opacity": 0.3},
            "translucency": {"enabled": False, "value": 0.5},
        }],
        "supported-platforms": {"squares": ["macOS"]},
    }, indent=2) + "\n")


def substitute(text, values):
    for k, v in values.items():
        text = text.replace(k, v)
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dir", required=True, help="new project folder (must not exist or be empty)")
    ap.add_argument("--name", required=True, help="ASCII bundle / executable name, e.g. Jot")
    ap.add_argument("--zh", required=True, help="Chinese display name, e.g. 乔木闪记")
    ap.add_argument("--bundle-id", required=True, help="reverse-DNS id; never change it after release")
    ap.add_argument("--repo", required=True, help="GitHub owner/name used for links and the update feed")
    ap.add_argument("--tagline", default="一句话说明它为你做什么")
    ap.add_argument("--lucide", default="sparkles", help="Lucide icon name for the app icon")
    ap.add_argument("--symbol", default="sparkles", help="SF Symbol for the menu bar")
    ap.add_argument("--kind", choices=["menubar", "window"], default="menubar",
                    help="menubar: status item + hotkey panel, no Dock icon; window: normal Dock app with a main window")
    ap.add_argument("--dmg-hint", default=None)
    args = ap.parse_args()

    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", args.name):
        fail("--name must be ASCII letters/digits (it becomes Name.app and the executable)")
    project = Path(args.dir).expanduser().resolve()
    if project.exists() and any(project.iterdir()):
        fail(f"{project} exists and is not empty")
    if args.dmg_hint is None:
        args.dmg_hint = "安装后在菜单栏运行" if args.kind == "menubar" else "拖到「应用程序」即可使用"
    values = {"__MENUBAR__": "true" if args.kind == "menubar" else "false", "__NAME_ZH__": args.zh, "__NAME__": args.name, "__BUNDLE_ID__": args.bundle_id,
              "__REPO__": args.repo, "__TAGLINE__": args.tagline, "__SYMBOL__": args.symbol,
              "__DMG_HINT__": args.dmg_hint}

    for src in TEMPLATE.rglob("*"):
        rel = Path(substitute(str(src.relative_to(TEMPLATE)), values))
        dst = project / rel
        if src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.suffix in TEXT_SUFFIXES:
            dst.write_text(substitute(src.read_text(), values))
        else:
            shutil.copy2(src, dst)
        if src.suffix == ".sh":
            dst.chmod(0o755)

    write_icon(project, args.lucide)
    about = project / "Resources/About"
    about.mkdir(parents=True, exist_ok=True)
    if (PROFILE / "qiaomu_wechat_public_account_qr.jpg").exists():
        shutil.copy2(PROFILE / "qiaomu_wechat_public_account_qr.jpg", about / "wechat-qr.jpg")
        subprocess.run(["sips", "-Z", "520", str(PROFILE / "qiaomu_reward_qr.png"), "--out", str(about / "reward-qr.png")],
                       capture_output=True)
    else:
        print("note: qiaomu-profile QR assets not found; About shows empty cards until Resources/About/*.png exist")

    (project / "VERSION").write_text("0.1.0\n")
    (project / ".gitignore").write_text(".build/\n.swiftpm/\nbuild/\ndist/\n.DS_Store\nxcuserdata/\n")
    (project / "LICENSE").write_text(MIT.format(year=__import__("datetime").date.today().year))
    (project / "THIRD_PARTY_NOTICES.md").write_text(NOTICES.format(name=args.name, zh=args.zh, lucide=args.lucide))
    subprocess.run(["git", "init", "-q", "-b", "main"], cwd=project)
    print(f"Created {project}\nNext: cd '{project}' && ./scripts/sparkle-key.sh && ./build.sh && "
          f"build/{args.name}.app/Contents/MacOS/{args.name} --selftest")


MIT = """MIT License

Copyright (c) {year} 向阳乔木 (Qiaomu, https://github.com/joeseesun)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of
the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

NOTICES = """# Third-Party Notices · 第三方许可

{zh} ({name}) is MIT-licensed. It bundles or depends on:

| Component | Used for | License |
|---|---|---|
| [Sparkle](https://sparkle-project.org) | Auto-update | MIT |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global shortcut recording | MIT |
| [Lucide](https://lucide.dev) "{lucide}" | App icon artwork | ISC |

Keep full license texts in `licenses/` for anything bundled (fonts, icons, sounds).
The QR codes in `Resources/About/` belong to 向阳乔木 and are not covered by the MIT license.
"""

if __name__ == "__main__":
    main()
