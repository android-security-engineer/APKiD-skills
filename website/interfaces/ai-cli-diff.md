# AI CLI · diff — 对比两文件差异

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">比较</span>

🔄 `apkid-ai-cli diff` 扫描两个文件并按 tag 集合做差集，找出**新增**、**移除**、**共有**的检测项。专门用于对比同一应用不同版本的加固/混淆变化——比如新版是否换了壳、是否新增了反调试。

## 🚀 一行用法

```bash
apkid-ai-cli diff app-v1.apk app-v2.apk
```

## 🖥️ 命令签名

```bash
apkid-ai-cli diff <file1> <file2> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `file1` | `Path`（必填） | — | 第一个文件（基准版），`exists=True` |
| `file2` | `Path`（必填） | — | 第二个文件（对比版），`exists=True` |
| `--output`, `-o` | `Path` | `None`（stdout） | 写入文件而非标准输出 |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时秒数 |
| `--typing` | `magic` \| `filename` \| `none` | `magic` | 文件类型识别方式 |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档最大递归深度 |
| `--include-types` | `bool` | `False` | 结果含 `file_type` 检测 |

::: warning 参数集比 scan/batch 精简
diff **没有** `--format`、`--entry-max-scan-size`、`--verbose` 选项。`entry_max_scan_size` 在内部硬编码为 `0`（不限），输出恒为 JSON。差异分析不需要 text 格式。
:::

## 🔍 diff 的语义

diff 以 **tag 集合**为单位做运算，不是按 finding 逐条比：

| 字段 | 集合运算 | 含义 |
|------|----------|------|
| `added` | `tags2 − tags1` | file2 有、file1 没有的检测——**新版新增**的保护/技术 |
| `removed` | `tags1 − tags2` | file1 有、file2 没有的检测——**新版移除**的保护/技术 |
| `common_count` | `\|tags1 ∩ tags2\|` | 两者都命中的检测数量（只给数字，不列明细） |

其中 `tag` 是 finding 的完整标签（`类别::规则名`，如 `packer::jiagu_360_v5`）。两条同 tag 的 finding 视为同一检测。

::: tip 为什么按 tag 而非整条 finding
同一个加固（同一 tag）可能在两个版本里都命中，但 `source`（DEX 路径）或 `version` 略有不同。按 tag 比对能抓住"是否还是这个壳"的语义，而按整条 finding 比对会产生噪音差异。要看明细差异仍可对两个文件分别跑 `scan`。
:::

## 📤 输出示例

```bash
apkid-ai-cli diff app-v1.apk app-v2.apk
```

```json
{
  "error": false,
  "file1": "app-v1.apk",
  "file2": "app-v2.apk",
  "added": [
    {
      "tag": "packer::bangcle",
      "category": "packer",
      "description": "Detects APK packing/obfuscation tools",
      "source": "app-v2.apk!classes.dex",
      "identifier": "bangcle",
      "rule_detail": "Bangcle packer",
      "confidence": "high"
    },
    {
      "tag": "anti_debug::ptrace",
      "category": "anti_debug",
      "description": "Detects anti-debugging techniques",
      "source": "app-v2.apk!lib/armeabi-v7a/libnative.so",
      "identifier": "ptrace",
      "rule_detail": "ptrace anti-debug",
      "confidence": "medium"
    }
  ],
  "removed": [],
  "common_count": 3,
  "summary": {
    "total_added": 2,
    "total_removed": 0,
    "total_common": 3
  }
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `added` | file2 相对 file1 新增的检测，findings 从 **file2 的结果**里取 |
| `removed` | file2 相对 file1 移除的检测，findings 从 **file1 的结果**里取 |
| `common_count` | 两者都命中的 tag 数（数字，不含明细） |
| `summary.total_added` / `total_removed` / `total_common` | 分别对齐三类数量 |

## 🧪 实战示例：对比新旧版本发现新增加固

场景：你拿到一个应用 v1（已知无壳）和 v2（疑似被加固），想确认 v2 是否新增了保护。

```bash
# 1. 跑 diff
apkid-ai-cli diff app-v1.apk app-v2.apk -o diff.json

# 2. 看新版新增了什么
jq '.added' diff.json
# 命中 packer::bangcle + anti_debug::ptrace → v2 确实加了壳和反调试

# 3. 一句话总结
jq '"v2 新增 \(.summary.total_added) 项，移除 \(.summary.total_removed) 项，共有 \(.summary.total_common) 项"' diff.json

# 4. 只看新增的加固类
jq '.added[] | select(.category=="packer") | .identifier' diff.json
```

输出 `packer::bangcle` 即可下结论：**v2 相比 v1 新增了 Bangcle 加固**。

::: tip 配合 scan 看明细
diff 只告诉你"新增了 bangcle"。要看 bangcle 命中的具体 source/version，再对 v2 跑一次 `apkid-ai-cli scan app-v2.apk | jq '.findings[] | select(.identifier=="bangcle")'`。
:::

::: warning 顺序很重要
`file1` 是基准、`file2` 是对比版。`added` 永远是"file2 比 file1 多的"。如果想反过来看，交换两个参数即可，added/removed 会互换。
:::

## 📍 相关

- [diff 命令源码](../modules/cli-cmd-diff) — `cmd_diff.py` 的集合运算实现。
- [scan 命令](./ai-cli-scan) — `added`/`removed` 里每条 finding 的结构与 scan 输出一致。
- [AI 输出格式](../guide/output-format) — diff 结果结构。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
