# AI CLI · scan — 扫描单个文件

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">核心</span>

🔍 `apkid-ai-cli scan` 是 APKiD 最基础、最常用的命令：扫描单个 APK/DEX/ELF 文件，识别加壳、混淆、保护器、签名、编译器、反调试/反 VM 等标识，输出结构化 JSON（或人类可读的文本）。

## 🚀 一行用法

```bash
apkid-ai-cli scan /path/to/app.apk
```

默认输出 JSON，含 `schema_version`、`findings`、`summary`。

## 🖥️ 命令签名

```bash
apkid-ai-cli scan <target> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `target` | `Path`（必填） | — | 待扫描的 APK/DEX/ELF 文件，typer 会校验文件存在（`exists=True`） |
| `--output`, `-o` | `Path` | `None`（stdout） | 把结果写入文件而非标准输出 |
| `--format`, `-f` | `json` \| `text` | `json` | 输出格式：`json` 给脚本/AI，`text` 给人看 |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时秒数，超时则中断匹配 |
| `--typing` | `magic` \| `filename` \| `none` | `magic` | 文件类型识别方式：`magic` 读魔数、`filename` 看扩展名、`none` 全交给 YARA |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档的最大递归深度（解一层 APK 再解里面的 DEX 等） |
| `--entry-max-scan-size` | `int` | `0` | 单个 ZIP 条目最大扫描字节数，`0` 表示不限 |
| `--include-types` | `bool` | `False` | 结果中是否包含 `file_type` 类检测 |
| `--verbose`, `-v` | `bool` | `False` | 调试日志开关 |

::: tip 何时调 `--typing`
默认 `magic` 又快又准，绝大多数场景保持默认即可。仅当文件被改了魔数（如 DEX 改名 `.gif` 但首字节也篡改）导致漏判时，才用 `--typing none` 强制全量喂给 YARA——代价是慢。
:::

::: warning `--entry-max-scan-size` 的默认值差异
AI CLI 默认 `0`（不限条目大小），而经典 CLI 默认 100MB。批量扫描超大 APK 时，AI CLI 的默认值更彻底但更慢；如需提速可显式设上限。
:::

## 📤 输出示例

### JSON 输出（默认）

```bash
apkid-ai-cli scan app.apk
```

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "target": "app.apk",
  "findings": [
    {
      "tag": "packer::jiagu_360_v5",
      "category": "packer",
      "description": "Detects APK packing/obfuscation tools",
      "source": "app.apk!classes.dex",
      "identifier": "jiagu_360_v5",
      "rule_detail": "360 Jiagu v5",
      "confidence": "high"
    },
    {
      "tag": "compiler::dx",
      "category": "compiler",
      "description": "Detects compiler or build tool fingerprints",
      "source": "app.apk!classes.dex",
      "identifier": "dx",
      "rule_detail": "dx compiler",
      "confidence": "high"
    }
  ],
  "summary": {
    "total_findings": 2,
    "categories": {
      "packer": 1,
      "compiler": 1
    }
  },
  "scanned_at": "2026-07-02T08:30:12.456789+00:00"
}
```

### text 输出（给人看）

```bash
apkid-ai-cli scan app.apk --format text
```

```
Target: app.apk

  [packer] jiagu_360_v5
    Detects APK packing/obfuscation tools
  [compiler] dx
    Detects compiler or build tool fingerprints

Scanned at: 2026-07-02T08:30:12.456789+00:00
```

## 🔍 字段解读

### `findings[]`

每条 finding 是一个命中的检测项，关键字段：

| 字段 | 含义 |
|------|------|
| `tag` | 完整检测标签，格式 `类别::规则名`（如 `packer::jiagu_360_v5`）；规则名与类别相同时只输出类别 |
| `category` | 归一化的检测类别，对应 [list-tags](./ai-cli-list-tags) 里的 20 类之一 |
| `description` | 该类别的人类可读描述，来自 `RULE_DESCRIPTIONS` |
| `source` | 命中所在的源文件路径，形如 `app.apk!classes.dex`（APK 内的 DEX）或 `app.apk!lib/armeabi-v7a/libfoo.so` |
| `identifier` | 命中的 YARA 规则名，即具体识别出的工具/技术 |
| `rule_detail` | 规则的 `description` 元数据，比 `identifier` 更友好 |
| `confidence` | 可信度推断，见下表 |
| `version` | 若规则名含版本信息（如 `ollvm_v3_4` → `3.4`），自动抽取 |

### `confidence` 含义

APKiD 根据命中 `source` 的文件类型推断可信度，反映"这条检测有多可靠"：

| confidence | 触发条件 | 解读 |
|------------|----------|------|
| `high` | source 含 `.dex`（DEX 字节码级匹配） | 最可靠，规则直接命中 DEX 字节码特征 |
| `medium` | source 含 `.so`/`.elf`（ELF 符号/段匹配） | 较可靠，命中 native 库特征 |
| `low` | source 是 `.apk`/`.zip`/`.jar`（APK 层路径匹配） | 偏弱，仅根据 APK 内路径判断，可能有误报 |
| `medium` | 其它未知来源 | 兜底默认值 |

::: tip 怎么用 confidence
分析加固结论时优先采信 `high` 的 finding。`low` 的 APK 层匹配可作为辅证，但别单独下"加壳"结论——它可能只是路径里恰好有特征字符串。
:::

### `summary`

```json
"summary": {
  "total_findings": 2,
  "categories": { "packer": 1, "compiler": 1 }
}
```

`total_findings` 是 findings 数组长度；`categories` 按类别聚合计数，一眼看出该样本主要被哪些技术覆盖。

## 🧪 示例命令

```bash
# 扫描并保存结果
apkid-ai-cli scan app.apk -o result.json

# 只要人类可读的简版
apkid-ai-cli scan app.apk --format text

# 深入扫嵌套 ZIP（某些加固会层层套壳）
apkid-ai-cli scan app.apk --scan-depth 4

# 把 file_type 检测也带上（默认会过滤掉）
apkid-ai-cli scan app.apk --include-types

# 用 jq 只抽加固类 finding
apkid-ai-cli scan app.apk | jq '.findings[] | select(.category=="packer")'

# 直接扫一个 DEX
apkid-ai-cli scan classes.dex

# 直接扫一个 native so
apkid-ai-cli scan lib/arm64-v8a/libnative.so
```

## 💡 常见场景

- **判断 APK 是否加固**：看 `summary.categories.packer` 是否 > 0，以及对应 finding 的 `confidence` 与 `identifier`。
- **取证留档**：`-o report.json` 存完整结构化结果，含 `scanned_at` 时间戳。
- **CI 卡点**：在流水线里 scan，用 jq 判断是否命中黑名单 `identifier`，命中即失败。

::: warning 大文件超时
巨型 APK（数百 MB）扫描可能接近 `--timeout`。若出现超时，先调大 `-t`，或用 `--typing filename` 仅扫已知扩展名以减少解压量。
:::

## 📍 相关

- [AI 输出格式](../guide/output-format) — JSON schema 与各字段完整定义。
- [scan 命令源码](../modules/cli-cmd-scan) — `cmd_scan.py` 实现细节。
- [AI CLI 概览](./ai-cli) — 全部命令索引与通用参数。
- [检测类别](../guide/categories) — 20 个 category 的含义。
