# Nitor macOS 开发 · nitor-macos-dev

给 Codex 使用的原生 Mac App 开发 Skill：从菜单栏工具或普通窗口工程开始，完成核心功能、原生交互、设置与关于、自动更新及按需签名公证打包。

由 Nitor 使用和维护，GitHub 归属 [TianMingAI](https://github.com/TianMingAI)。仓库地址保持为 `TianMingAI/qiaomu-macos-dev`，Skill 的安装目录和调用名为 `nitor-macos-dev`。

## 能做什么

| 环节 | 提供的内容 |
|---|---|
| 工程 | SwiftUI + AppKit + SwiftPM，菜单栏和普通窗口两种形态 |
| 原生交互 | 全局快捷键、焦点处理、复制粘贴、设置与关于、开机启动 |
| 设计 | 黑白克制配色、Geist / 中文系统字体、深浅色主题、原生窗口和键盘操作 |
| 图标 | Lucide 图形与 Icon Composer 工程 |
| 更新 | Sparkle、EdDSA 签名、GitHub Release appcast |
| 分发 | 通用二进制、Developer ID 签名、Apple 公证、DMG 与本机安装脚本 |
| 排查 | 权限、焦点、输入法、快捷键、更新和打包的经验资料 |

生成器搭好通用基础，具体业务逻辑仍由 Agent 按需求实现。初始 `--selftest` 仅检查应用名称，必须为实际功能补充必要验证。

## 在 Codex 中调用

安装到 `~/.codex/skills/nitor-macos-dev` 后，下一轮对话即可显式调用：

```text
使用 $nitor-macos-dev 做一个 Mac 菜单栏速记工具，按 Option + Space 打开，保存为 Markdown。
```

也支持按原生 macOS 开发需求自动匹配，入口和 UI 元数据分别是 `SKILL.md` 与 `agents/openai.yaml`。安装时使用本仓库，不要安装上游原版。可对 Codex 说：

```text
从 https://github.com/TianMingAI/qiaomu-macos-dev 安装 Skill，安装名称为 nitor-macos-dev。
```

## 固定设计方向

每次使用本 Skill 处理 Mac 界面，优先读取并遵循 `references/ui-polish.md`：黑白、高对比、最多一种强调色、不用紫色和装饰性侧条，保持原生控件、窗口行为和键盘体验。此处的 macOS 规范优先于网站导向的 frontend-design 默认审美；用户当次明确指定其他方向时以新要求为准。这不会修改网站任务或全局偏好。

## Nitor 品牌配置

`assets/brand.json` 统一提供品牌名和个人链接，生成时复制到 App 的 `Resources/About/brand.json`。

- 默认品牌：Nitor；GitHub：TianMingAI。
- 网站、公众号、反馈邮箱尚未提供，留空时隐藏。
- 二维码为可选项：只有主动放入 `assets/brand/wechat-qr.jpg` 或 `assets/brand/reward-qr.png` 才会复制；缺少时不显示空白卡片。
- 不读取其他个人 profile Skill，不包含上游作者头像、二维码或宣传截图。
- 默认示例命名空间为 `ai.nitor.<slug>`，项目仓库为 `TianMingAI/nitor-<slug>`；既有 App 保留已有 bundle ID 和更新源。

## 环境与使用

需要 macOS、Swift 5.9+ 和 Python 3。完整图标构建需要 Xcode 26+ 提供的 `actool`，只有 Command Line Tools 不足以完成这一环节。正式分发还需要 Developer ID Application 证书及公证钥匙串配置；GitHub 发布需要可用的授权工具或已登录的 `gh`。

```bash
python3 scripts/new_app.py --dir /tmp/nitor-ledger --name Ledger --zh Nitor账本 \
  --bundle-id ai.nitor.ledger --repo TianMingAI/nitor-ledger \
  --kind window --tagline "三秒记一笔，月底一目了然" --lucide notebook-pen
cd /tmp/nitor-ledger
./scripts/sparkle-key.sh
./build.sh
build/Ledger.app/Contents/MacOS/Ledger --selftest
```

离线生成可设置 `NITOR_OFFLINE=1`，使用内置图形；SwiftPM 构建仍需依赖已缓存或可联网下载。

## 验证与边界

```bash
python3 -m unittest discover -s tests -v
```

本次改版的验证范围和环境限制见 `reports/validation.md`。旧版运行报告不能证明修改后的应用已完成构建、公证或更新验证；本仓库不沿用旧截图和过期通过记录。

创建仓库、公开、发布和替换已安装 App 必须处于用户授权范围内；已有授权跨阶段有效。私钥和公证凭据只通过钥匙串引用，不写入仓库。Skill 不会自行修改长期记忆或偏好。

## 结构与许可

- `SKILL.md`：入口、任务路由与约束。
- `references/`：设计、品牌、架构、权限、更新、发布和踩坑资料。
- `scripts/new_app.py`：生成器。
- `assets/template/`：Swift 源码及构建、安装、发布脚本。
- `assets/brand.json`：Nitor 品牌资料。
- `tests/`：离线生成与品牌行为验证。

代码采用 MIT 许可。上游版权与来源保留在 [LICENSE](LICENSE) 和 [NOTICE.md](NOTICE.md)，也随生成项目分发；产品展示品牌为 Nitor。Sparkle、KeyboardShortcuts 和 Lucide 的第三方许可需要随实际依赖保留。
