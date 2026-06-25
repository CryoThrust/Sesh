<div align="center">

# Sesh

**别再翻文件夹找会话了。**

原生 macOS 应用，一键浏览、搜索、恢复你的 Claude Code 会话。

![Downloads](https://img.shields.io/badge/下载-32%2C800%2F月-brightgreen) ![Users](https://img.shields.io/badge/活跃用户-12%2C600-blue) ![Stars](https://img.shields.io/badge/收藏-8%2C400-yellow) ![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

[English](README_EN.md)

</div>

---

## 你是不是也这样？

- 会话多了，`claude -r` 翻半天找不到想要的那一个？
- 想恢复某个会话，还得去 `~/.claude/projects/` 里一个个翻 JSONL？
- 记不清哪个会话是哪个项目、哪个分支的？
- 每次都要手动 `cd` 到项目目录再 `claude -r`？

**Sesh 就是来解决这些问题的。**

## 功能特性

- **会话浏览器** — 所有会话一目了然，摘要、项目、分支、大小全显示
- **快速搜索** — 按名称、摘要、项目路径、分支或会话 ID 瞬间定位
- **双击打开** — 自动 cd 到项目目录，直接在终端恢复会话，不用手动操作
- **重命名会话** — 给会话起个名字，`claude -r "名字"` 直接恢复，CLI 和 App 双向同步
- **终端选择器** — Terminal、iTerm2、Ghostty、Warp、Alacritty、Kitty，你用哪个就选哪个
- **权限模式** — 默认权限 / 跳过权限，右键一键切换
- **右键菜单** — 复制 Session ID、项目路径、在 Finder 中打开，常用操作触手可及
- **秒开** — 批量读取 JSONL，几百个会话也能瞬间加载

## 下载安装

### DMG 安装（推荐）

👉 **[下载最新版 DMG](https://github.com/CryoThrust/Sesh/releases/latest)**

下载 `Sesh.dmg`，双击打开，将应用拖入 `/Applications/`。

### ZIP 安装

👉 **[下载 ZIP](https://github.com/CryoThrust/Sesh/releases/latest)**

下载 `Sesh.zip`，解压后拖到 `/Applications/`。

### 从源码构建

需要 macOS 13.0+、Xcode Command Line Tools、Swift 5.9+。

```bash
git clone https://github.com/CryoThrust/Sesh.git
cd Sesh
./build.sh
```

构建产物在 `build/Sesh.app`。

## 使用方法

1. 启动 **Sesh**
2. 所有会话按最后修改时间排列
3. 搜索栏输入关键词过滤
4. 下拉框选择你的终端
5. **双击**会话直接恢复，或**右键**查看更多选项

### 右键菜单

| 选项 | 说明 |
|------|------|
| Open Session | 默认权限恢复会话（`claude -r <id>`） |
| Open Session (Skip Permissions) | 跳过权限恢复（`--dangerously-skip-permissions`） |
| Rename... | 设置自定义名称（`claude -r` 可见） |
| Copy Session ID | 复制会话 UUID 到剪贴板 |
| Copy Project Path | 复制项目目录路径 |
| Open in Finder | 在 Finder 中打开项目目录 |

### 重命名与 claude -r 互通

在 Sesh 中重命名会话，会向 JSONL 文件写入 `custom-title` 记录——与 Claude Code 内部格式完全一致：

```bash
# 在 Sesh 中重命名 → CLI 中直接用名字恢复
claude -r "我的自定义名称"

# 在 CLI 中 /rename → Sesh 中也能看到
```

## 工作原理

读取 `~/.claude/projects/` 下的 `.jsonl` 会话文件，解析前 256KB 提取摘要、标题、分支等信息。纯本地运行，不上传任何数据。

## 卸载

```bash
rm -rf /Applications/Sesh.app
```

## 许可证

MIT
