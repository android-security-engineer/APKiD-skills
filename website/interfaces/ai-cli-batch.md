# AI CLI · batch — 批量扫描目录

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">批量</span>

📦 `apkid-ai-cli batch` 批量扫描目录下的多个文件，把每个样本的结果聚合成单个 JSON 数组输出。进度条走 stderr，不污染 stdout 的可解析输出——专为脚本和 AI 智能体的批量处理设计。

## 🚀 一行用法

```bash
apkid-ai-cli batch /path/to/samples/ -r
```

## 🖥️ 命令签名

```bash
apkid-ai-cli batch <directory> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `directory` | `Path`（必填） | — | 含待扫描文件的目录，`exists=True` 校验 |
| `--recursive`, `-r` | `bool` | `False` | 是否递归扫描子目录（`rglob`） |
| `--pattern`, `-p` | `str` | `*.apk` | 文件 glob 模式 |
| `--output`, `-o` | `Path` | `None`（stdout） | 把结果写入文件而非标准输出 |
| `--format`, `-f` | `json` \| `text` | `json` | 输出格式 |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时秒数 |
| `--typing` | `magic` \| `filename` \| `none` | `magic` | 文件类型识别方式 |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档最大递归深度 |
| `--entry-max-scan-size` | `int` | `0` | 单个 ZIP 条目最大扫描字节数（0=不限） |
| `--include-types` | `bool` | `False` | 结果含 `file_type` 检测 |
| `--verbose`, `-v` | `bool` | `False` | 调试日志 |

## 🔧 rglob / glob 文件收集

```python
if recursive:
    files = sorted(target_path.rglob(pattern))   # 含子目录
else:
    files = sorted(target_path.glob(pattern))     # 仅顶层
```

- `--recursive` 用 `rglob` 遍历整棵目录树；不加 `-r` 只扫顶层。
- `--pattern` 是 glob 模式，默认 `*.apk`。扫 DEX 用 `*.dex`，扫所有可识别文件可传 `*`（但会被 typing 过滤）。
- 结果 `sorted` 排序，保证跨运行的输出顺序稳定。

::: tip pattern 与 typing 的关系
`--pattern` 决定"收集哪些文件名"，`--typing` 决定"收集到的文件是否真去扫"。即便 `pattern=*` 收了一堆图片，`magic` typing 也会跳过非 APK/DEX/ELF 文件。所以批量扫混合目录时，传 `pattern=*` + 默认 typing 是安全的。
:::

## 📊 进度条走 stderr

```bash
apkid-ai-cli batch samples/ -r | jq '.scanned'   # stdout 纯 JSON
```

进度条用 rich `Progress` 渲染，但其 Console 是 `Console(stderr=True)`——所有 spinner 和进度文本都打到 stderr，**stdout 永远只有最终 JSON**。这意味着管道给 `jq`/AI 解析器时不会被进度条文本干扰。

::: tip 想看进度就别重定向 stderr
若把 `2>/dev/null` 丢弃了 stderr，你会看不到进度。脚本里要静默就 `2>/dev/null`，交互跑就留着。
:::

## 📤 输出示例

### 空结果（没匹配到文件）

当目录里没有任何匹配 `--pattern` 的文件时，输出**不是错误**：

```json
{
  "error": false,
  "scanned": 0,
  "results": [],
  "message": "No files matching '*.apk' found in samples/"
}
```

::: warning 空集合 ≠ 出错
`error: false` 表示命令正常完成，只是没找到文件。区别于真正的异常路径（如目录不存在、YARA 加载失败）会走 `error_exit`，输出 `error: true` 并退出码 1。脚本里判断时只看 `error` 字段即可，`scanned: 0` 不算失败。
:::

### 批量结果（扫到 N 个文件）

```json
{
  "error": false,
  "scanned": 2,
  "results": [
    {
      "schema_version": "1.0.0",
      "error": false,
      "target": "samples/app-v1.apk",
      "findings": [ /* ...单个样本的完整结果，同 scan 命令的 findings... */ ],
      "summary": { "total_findings": 1, "categories": { "packer": 1 } },
      "scanned_at": "2026-07-02T08:31:00.000000+00:00"
    },
    {
      "schema_version": "1.0.0",
      "error": false,
      "target": "samples/app-v2.apk",
      "findings": [ /* ... */ ],
      "summary": { "total_findings": 0, "categories": {} },
      "scanned_at": "2026-07-02T08:31:05.000000+00:00"
    }
  ]
}
```

`scanned` 是结果数组长度；`results[]` 每项是一个样本的完整扫描结果，结构同 `scan` 命令的单文件输出（含 `schema_version`、`findings`、`summary`、`scanned_at`）。

## 🧪 示例命令与 jq 技巧

```bash
# 递归扫所有 APK 并存档
apkid-ai-cli batch samples/ -r -o all.json

# 扫所有 DEX
apkid-ai-cli batch extracted/ -r --pattern "*.dex"

# 统计扫了多少个、命中加固的有几个
apkid-ai-cli batch samples/ -r | jq '{scanned: .scanned, packed: ([.results[] | select(.summary.categories.packer > 0)] | length)}'

# 提取所有命中加固的样本路径
apkid-ai-cli batch samples/ -r | jq '.results[] | select(.summary.categories.packer > 0) | .target'

# 按检测类别聚类：统计每类命中的样本数
apkid-ai-cli batch samples/ -r | jq '[.results[].summary.categories] | add'

# 列出每个样本的最高可信度加固项
apkid-ai-cli batch samples/ -r | jq '.results[] | {target: .target, packers: [.findings[] | select(.category=="packer") | {id: .identifier, conf: .confidence}]}'

# 找出零命中的样本（可能未加壳或被新壳绕过）
apkid-ai-cli batch samples/ -r | jq '.results[] | select(.summary.total_findings == 0) | .target'
```

::: tip YARA 只加载一次
batch 复用同一个 `scanner` 实例扫所有文件，规则编译/加载只发生一次。所以扫 1000 个文件不会重复加载 1000 次规则，吞吐有保障。
:::

## 📍 相关

- [batch 命令源码](../modules/cli-cmd-batch) — `cmd_batch.py` 实现细节。
- [scan 命令](./ai-cli-scan) — `results[]` 每项的字段结构与 scan 输出一致。
- [AI 输出格式](../guide/output-format) — 批量结果的整体结构。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
