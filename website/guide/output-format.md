# AI 输出格式

<span class="badge badge-info">JSON</span>
<span class="badge badge-info">schema</span>

AI CLI 与 MCP 服务器都输出结构化 JSON，供 AI 智能体和脚本消费。本文是 schema 的完整参考。

## 📐 schema_version

所有 AI 输出带 `"schema_version": "1.0.0"`。当输出结构发生 **破坏性变更**（字段改名、类型改变）时，这个版本号会 bump。解析方可以先检查它决定如何解析。

## 🧱 单文件扫描结果（scan）

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "target": "/path/to/app.apk",
  "findings": [ ... ],
  "summary": { ... },
  "scanned_at": "2026-07-02T08:30:00.000000+00:00"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `schema_version` | string | schema 版本，当前 `1.0.0` |
| `error` | boolean | `false` 成功；失败时见 [错误对象](#错误对象stderr) |
| `target` | string | 被扫描的文件路径 |
| `findings` | array | 检测结果列表，每项是一个 [finding](#finding-对象) |
| `summary` | object | [汇总对象](#summary-对象) |
| `scanned_at` | string | ISO 8601 UTC 时间戳 |

## 🔎 finding 对象

`findings` 数组的每一项：

```json
{
  "tag": "packer::jiagu_360_v5",
  "category": "packer",
  "description": "Detects APK packing/obfuscation tools",
  "source": "/path/to/app.apk!assets/libjiagu.so",
  "identifier": "jiagu_360_v5",
  "rule_detail": "360 Jiagu v5",
  "confidence": "low",
  "version": "5"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `tag` | string | 检测标签，格式 `category::rule`（如 `packer::bangcle`）；若规则名等于 tag 则直接是 tag |
| `category` | string | 检测类别，见 [检测类别](./categories) |
| `description` | string | 类别人类可读描述（来自 `RULE_DESCRIPTIONS`） |
| `source` | string | 命中来源，格式 `外层文件!内部条目`（如 `app.apk!classes.dex`） |
| `identifier` | string | 规则名（如 `bangcle`、`dx`） |
| `rule_detail` | string | 规则 meta 里的 `description`，具体说明 |
| `confidence` | string | `high` / `medium` / `low`，见 [置信度推断](#置信度推断) |
| `version` | string? | 可选。从规则名提取的版本号（如 `ollvm_v9` → `"9"`） |

### `version` 提取规则

[`_extract_version()`](../modules/ai-output) 用两个正则：

- `_v3_4` / `_v9` / `_v4_0` → 匹配 `_v` 后跟数字，`_` 替换为 `.`，得 `"3.4"`、`"9"`、`"4.0"`。
- `_3_92` / `_0_9_2` / `_2_10_10` → 末尾 `_数字_数字` 模式，得 `"3.92"`、`"0.9.2"`、`"2.10.10"`。

不匹配则省略 `version` 字段。

### 置信度推断

`_infer_confidence(source)` 依据命中来源：

| source 特征 | confidence | 含义 |
|-------------|-----------|------|
| 以 `.dex` 结尾或含 `.dex` | `high` | DEX 字节码级匹配 |
| 以 `.so` 结尾或含 `.so` | `medium` | ELF 符号/节区匹配 |
| 以 `.apk`/`.zip`/`.jar` 结尾 | `low` | APK 层路径匹配（壳的壳） |
| 以 `.elf` 结尾 | `medium` | 直接 ELF 文件 |
| 其它 | `medium` | 默认 |

::: tip 为什么 source 是 "壳的壳"
扫描 `app.apk` 时，APK 自身的魔数/路径会先匹配一遍外层规则——这些命中 `source` 就是 `app.apk` 本体，置信度 `low`。真正有价值的是解包后 `app.apk!classes.dex`、`app.apk!lib/.../libfoo.so` 的命中，置信度 `high`/`medium`。分析时优先看高置信度 finding。
:::

## 📊 summary 对象

```json
"summary": {
  "total_findings": 3,
  "categories": {
    "packer": 1,
    "compiler": 1,
    "obfuscator": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_findings` | integer | finding 总数 |
| `categories` | object | 类别名 → 该类别 finding 数 |

## 📦 批量扫描结果（batch）

```json
{
  "error": false,
  "scanned": 2,
  "results": [ {单文件结果}, {单文件结果} ]
}
```

`results` 数组每项就是一个 [单文件结果](#单文件扫描结果scan)，但 **不含顶层 `error`/`scanned`**——是 `format_dict()` 的产物。无匹配文件时 `findings` 为空数组，仍出现在 `results` 里。

## 🆚 diff 结果（diff）

```json
{
  "error": false,
  "file1": "app-v1.apk",
  "file2": "app-v2.apk",
  "added": [ {finding} ],        // v2 有、v1 没有的
  "removed": [ {finding} ],      // v1 有、v2 没有的
  "common_count": 5,
  "summary": {
    "total_added": 1,
    "total_removed": 0,
    "total_common": 5
  }
}
```

`added`/`removed` 里是完整 finding 对象。比较维度是 `tag`（`category::rule`）的集合差。

## 🔢 type 结果（type）

```json
{
  "error": false,
  "file": "/path/to/file",
  "type": "dex",                 // 或 null（不识别）
  "supported_types": ["dex", "dll", "elf", "res", "zip"]
}
```

不识别时 `type` 为 `null`，附带 `message` 字段说明。

## ⛔ 错误对象（stderr）

出错时输出到 **stderr**，格式：

```json
{
  "error": true,
  "message": "File not found: /path/to/missing.apk",
  "detail": "FileNotFoundError"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `error` | boolean | 恒 `true` |
| `message` | string | 错误描述 |
| `detail` | string | 异常类名（如 `FileNotFoundError`、`ValueError`） |

MCP 工具的错误走相同结构（只是作为工具返回值，不写 stderr）。

## 🚪 退出码

| 退出码 | 含义 |
|--------|------|
| `0` | 成功 |
| `1` | 失败（见 stderr 错误 JSON） |

## 📍 下一步

- [检测类别](./categories) — `category` 与 `description` 的来源。
- [代码模块：ai_output.py](../modules/ai-output) — formatter 源码。
- [AI CLI 概览](../interfaces/ai-cli) — 命令如何产出这些 JSON。
