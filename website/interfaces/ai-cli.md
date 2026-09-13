# AI CLI 概览

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-info">JSON</span>

`apkid-ai-cli` 是 APKiD 的 AI 原生接口。基于 Typer + Rich，输出结构化 JSON，专为脚本和 AI 智能体消费设计。

## 🚀 一行扫描

```bash
apkid-ai-cli scan /path/to/app.apk
```

默认输出 JSON（`schema_version: 1.0.0`，含 `findings`/`summary`）。详见 [AI 输出格式](../guide/output-format)。

## 📋 全部命令

| 命令 | 作用 | 文档 |
|------|------|------|
| `scan <file>` | 扫描单文件 | [→](./ai-cli-scan) |
| `batch <dir>` | 批量扫描目录 | [→](./ai-cli-batch) |
| `diff <f1> <f2>` | 对比两文件差异 | [→](./ai-cli-diff) |
| `type <file>` | 识别文件类型（不加载 YARA） | [→](./ai-cli-type) |
| `info` | 版本 + 规则信息 | [→](./ai-cli-info) |
| `list-tags` | 所有检测类别 | [→](./ai-cli-list-tags) |
| `rules <action>` | 规则管理（list/compile） | [→](./ai-cli-rules) |
| `skills` | 自发现命令列表 | [→](./ai-cli-skills) |

## 🎨 文本输出（给人看）

加 `--format text` 得人类可读的简版：

```bash
apkid-ai-cli scan app.apk --format text
```

```
Target: app.apk

  [packer] jiagu_360_v5
    Detects APK packing/obfuscation tools
  [compiler] dx
    Detects compiler or build tool fingerprints

Scanned at: 2026-07-02T...
```

## 🛠️ 常用参数（通用）

几乎所有命令共享这些选项：

| 参数 | 说明 | 默认 |
|------|------|------|
| `--output/-o FILE` | 写文件而非 stdout | stdout |
| `--format/-f` | `json` 或 `text` | json |
| `--timeout/-t` | YARA 超时秒 | 30 |
| `--typing` | `magic`/`filename`/`none` | magic |
| `--scan-depth` | 嵌套 ZIP 深度 | 2 |
| `--include-types` | 含 file_type | off |
| `--verbose/-v` | 调试日志 | off |

`scan`/`batch` 额外有 `--entry-max-scan-size`。`batch` 有 `--recursive/-r`、`--pattern/-p`。

## 📦 典型工作流

### 分析单个样本

```bash
apkid-ai-cli scan app.apk -o result.json
# 看 result.json 的 findings[].category 和 .confidence
```

### 批量分类样本

```bash
apkid-ai-cli batch samples/ -r --pattern "*.apk" -o all.json
# all.json.results[] 每项是一个样本的完整结果
# 按 summary.categories 聚类
```

### 对比版本差异

```bash
apkid-ai-cli diff app-v1.apk app-v2.apk
# added: v2 新增的保护；removed: v2 移除的
```

### 先探类型再决定扫不扫

```bash
apkid-ai-cli type mystery.file    # 秒出，不加载 YARA
# type=null → 不是 Android 二进制，别浪费力气扫
```

## 🤖 给 AI 当工具

AI CLI 的输出设计成 AI 友好：

- **结构化 finding**：每条带 `category`/`identifier`/`confidence`/`source`，AI 能直接推理。
- **summary 聚合**：`{total_findings, categories:{...}}`，一眼看全貌。
- **schema_version**：AI 可检查版本决定如何解析。
- **错误 JSON**：失败也是结构化的，AI 能识别并报告。

典型 AI 提示词链："用 apkid-ai-cli 扫描这个 APK，告诉我它被什么加固了、可信度多高"。

## 🐍 脚本集成

```bash
# 提取所有加固样本的路径
apkid-ai-cli batch samples/ -r | jq '.results[] | select(.summary.categories.packer > 0) | .target'

# 统计每类检测的样本数
apkid-ai-cli batch samples/ -r | jq '[.results[].summary.categories] | add'
```

## 📍 相关

- 各命令详解（见上表）。
- [AI 输出格式](../guide/output-format) — JSON schema。
- [app.py](../modules/cli-app) — 入口源码。
- [common.py](../modules/cli-common) — 共享工具。
- [三种接口对比](./overview) — 与经典 CLI/MCP 对比。
