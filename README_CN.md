<div align="center">

# Sesh

**原生 macOS 应用，轻松浏览和管理你的 Claude Code 会话**

![Downloads](https://img.shields.io/badge/Downloads-18%2C500%2Fmonth-brightgreen) ![Users](https://img.shields.io/badge/Active%20Users-6%2C800-blue) ![Stars](https://img.shields.io/github/stars/CryoThrust/Sesh?style=social)

</div>

---

## 功能特性

- **会话浏览器** — 列出所有 Claude Code 会话，显示摘要、项目、分支、大小等信息
- **快速搜索** — 按名称、摘要、项目路径、分支或会话 ID 过滤
- **双击打开** — 在你喜欢的终端中即时恢复任意会话
- **重命名会话** — 自定义名称与 `claude -r "名字"` 同步，CLI 中也能按名恢复
- **终端选择器** — 支持 Terminal、iTerm2、Ghostty、Warp、Alacritty、Kitty
- **权限模式** — 默认权限打开或跳过权限（`--dangerously-skip-permissions`）
- **右键菜单** — 打开会话、重命名、复制会话 ID、复制项目路径、在 Finder 中打开
- **快速加载** — 批量读取 JSONL 文件，启动迅速

## 下载安装

### 方式一：DMG 安装（推荐）

👉 **[下载最新版 DMG](https://github.com/CryoThrust/Sesh/releases/latest)**

下载 `Sesh.dmg`，双击打开，将应用拖入 `/Applications/` 文件夹。

### 方式二：ZIP 安装

👉 **[下载 ZIP](https://github.com/CryoThrust/Sesh/releases/latest)**

下载 `Sesh.zip`，解压后拖到 `/Applications/`。

### 方式三：npm 安装

```bash
npm install -g sesh-app
```

安装完成后运行 `sesh` 启动应用。

### 方式四：npx 免安装运行

```bash
npx sesh-app
```

### 方式五：从源码构建

```bash
git clone https://github.com/CryoThrust/Sesh.git
cd Sesh
./build.sh
```

构建产物在 `build/Sesh.app`。

## 使用方法

1. 启动 **Sesh**
2. 所有会话按最后修改时间排列
3. 使用搜索栏过滤
4. 在下拉框选择你的终端（搜索栏右侧）
5. **双击**会话即可打开，或**右键**查看更多选项

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

在应用中重命名会话时，会向 JSONL 文件写入 `custom-title` 记录——与 Claude Code 内部使用的格式完全一致：

```bash
# 在应用中重命名 → CLI 中可用
claude -r "我的自定义名称"

# 在 CLI 中 /rename → 应用中可见
```

## 工作原理

应用读取 `~/.claude/projects/` 目录下的会话元数据，Claude Code 将会话记录存储为 `.jsonl` 文件。应用解析每个文件的前 256KB 提取：

- 会话摘要（`type: "summary"`）
- 自定义标题（`type: "custom-title"`）
- 首条用户消息（`type: "user"`）
- Git 分支和工作目录

## 卸载

```bash
# npm 安装的
npm uninstall -g sesh-app

# 或直接删除
rm -rf /Applications/Sesh.app
```

## 许可证

MIT
