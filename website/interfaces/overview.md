# 三种接口对比

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">MCP</span>

APKiD 提供三个等价的接口，背后共享同一套扫描引擎。本文帮你选对接口。

## 📊 一图看清

| 维度 | 经典 CLI `apkid` | AI CLI `apkid-ai-cli` | MCP `apkid-mcp` |
|------|------------------|----------------------|-----------------|
| 框架 | argparse | typer + rich | FastMCP |
| 输出 | 彩色终端 / JSON | 结构化 JSON（默认） | JSON 字符串（MCP 协议） |
| 适合谁 | 人类分析师终端用 | 脚本 / AI 智能体 | MCP 客户端（Claude/Cursor） |
| schema_version | 无 | `1.0.0` | `1.0.0` |
| 共享 make_scanner | ❌（独立路径） | ✅ | ✅ |
| 进度条 | 无 | rich Progress | 无 |
| 写多文件目录 | ✅ `--output-dir` | ❌（单 `-o`） | ❌ |
| 安装 | `pip install apkid` | 同左 | `pip install apkid[mcp]` |
| 入口 | `apkid.main:main` | `apkid.cli:ai_cli` | `apkid.mcp:run` |

## 🎯 怎么选

### 用经典 CLI（`apkid`）当…

- 你在终端手动分析样本，想看 **彩色、人类可读** 的输出。
- 你要 **批量写结果到目录**（`--output-dir` 保留路径结构），做特征提取。
- 你要兼容老脚本（经典 JSON schema）。

### 用 AI CLI（`apkid-ai-cli`）当…

- 你在写脚本/流水线，要 **结构化 JSON** 好解析。
- 你给 AI 智能体当工具——`findings`/`summary`/`confidence` 设计成 AI 友好。
- 你要 `diff`/`batch`/`type` 等高级命令（经典 CLI 没有）。

### 用 MCP（`apkid-mcp`）当…

- 你用 Claude Desktop、Cursor 等 **MCP 客户端**，想让 AI 直接调扫描。
- 你想要 AI 在对话里"扫一下这个 APK"而不用切终端。
- 你想要工具自描述（`skills`/`info`/`list_tags` 让 AI 自发现能力）。

## 🔁 三者等价性

同一个 APK，三个接口的 **检测结果一致**（AI CLI 与 MCP 逐行共享代码，经典 CLI 走平行路径但用同一 `Scanner` + 同一 `rules.yarc`）：

```bash
# 三种方式扫同一个文件，findings 内容一致
apkid app.apk                          # 彩色终端
apkid-ai-cli scan app.apk              # 结构化 JSON
# MCP: scan_file({target: "app.apk"}) # 同样的 JSON
```

差别只在 **输出格式** 和 **可选参数默认值**（如 `entry-max-scan-size`：经典 100MB，AI/MCP 0 不限）。

## 📋 命令/工具对应表

| 功能 | 经典 CLI | AI CLI | MCP |
|------|---------|--------|-----|
| 扫单文件 | `apkid app.apk` | `scan` | `scan_file` |
| 批量扫描 | `apkid -r samples/` | `batch` | `batch_scan` |
| 对比差异 | — | `diff` | `diff_files` |
| 文件类型 | — | `type` | `type_file` |
| 版本信息 | （横幅） | `info` | `info` |
| 列类别 | — | `list-tags` | `list-tags` |
| 规则管理 | — | `rules` | `rules` |
| 自发现 | — | `skills` | `skills` |

经典 CLI 功能最少（历史包袱），AI CLI 和 MCP 功能对等。

## 📚 各接口文档

- [经典 CLI 概览](./classic-cli)
- AI CLI：[概览](./ai-cli) + [scan](./ai-cli-scan)、[batch](./ai-cli-batch)、[diff](./ai-cli-diff)、[type](./ai-cli-type)、[info](./ai-cli-info)、[list-tags](./ai-cli-list-tags)、[rules](./ai-cli-rules)、[skills](./ai-cli-skills)
- MCP：[概览](./mcp) + [scan_file](./mcp-scan-file)、[batch_scan](./mcp-batch-scan)、[diff_files](./mcp-diff-files)、[type_file](./mcp-type-file)、[info](./mcp-info)、[list_tags](./mcp-list-tags)、[rules](./mcp-rules)、[skills](./mcp-skills)

## 📍 相关

- [架构概览](../guide/architecture) — 三接口共享引擎的代码视角。
- [AI 输出格式](../guide/output-format) — AI CLI/MCP 的 JSON schema。
