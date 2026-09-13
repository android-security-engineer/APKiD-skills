# cli/cmd_diff.py — diff 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">比较</span>

🔄 `apkid-ai-cli diff` 扫描两个文件并按 tag 集合做差集，找出新增/移除/共有的检测项，用于对比同一应用不同版本的加固/混淆变化。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `diff(...)` | func | typer 命令回调，比较两文件扫描结果 |

模块仅导出 `diff` 函数，由 `app.py` 注册为 `diff` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli diff <file1> <file2> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `file1` | `Path` | （必填） | 第一个文件，`exists=True` |
| `file2` | `Path` | （必填） | 第二个文件，`exists=True` |
| `--output`, `-o` | `Optional[Path]` | `None` | 写入文件而非 stdout（注意参数名 `output_path`） |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时（秒） |
| `--typing` | `TypingMethod` | `magic` | 文件识别方式 |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档最大递归深度 |
| `--include-types` | `bool` | `False` | 结果含 `file_type` 检测 |

注意：diff **没有** `--format`、`--entry-max-scan-size`、`--verbose` 选项——参数集比 scan/batch 精简。`entry_max_scan_size` 在函数内硬编码为 `0`。

## 🔧 源码要点

### 双扫描

```python
scanner = make_scanner(
    timeout=timeout,
    typing=typing.value,
    scan_depth=scan_depth,
    entry_max_scan_size=0,          # ← 硬编码，无 CLI 选项
    include_types=include_types,
)
formatter = AIOutputFormatter()
results1 = scanner.scan_file(str(file1))
dict1 = formatter.format_dict(results1, str(file1), include_types=include_types)
results2 = scanner.scan_file(str(file2))
dict2 = formatter.format_dict(results2, str(file2), include_types=include_types)
```

要点：

- **用 `format_dict` 而非 `format`**：要拿到结构化 `findings` 列表做集合运算，必须拿 dict；`format` 出字符串无法拆解。
- **同一个 scanner 扫两次**：规则只加载一次，复用 Scanner 实例。

### tag 集合运算

```python
tags1 = {f["tag"] for f in dict1.get("findings", [])}
tags2 = {f["tag"] for f in dict2.get("findings", [])}

added_tags = sorted(tags2 - tags1)     # file2 有、file1 没有
removed_tags = sorted(tags1 - tags2)   # file1 有、file2 没有
common_tags = sorted(tags1 & tags2)    # 两者都有
```

- `added` = `tags2 - tags1`：file2 相对 file1 **新增**的检测。
- `removed` = `tags1 - tags2`：file2 相对 file1 **移除**的检测。
- `common` = 交集：两者都命中的检测。

### 从 tag 反查 findings

```python
findings_added = [
    f for f in dict2.get("findings", []) if f["tag"] in added_tags
]
findings_removed = [
    f for f in dict1.get("findings", []) if f["tag"] in removed_tags
]
```

- `added` 的 findings 从 **dict2** 取（新增项在 file2 的结果里）。
- `removed` 的 findings 从 **dict1** 取（移除项在 file1 的结果里）。

### 输出结构

```python
diff_result = {
    "error": False,
    "file1": str(file1),
    "file2": str(file2),
    "added": findings_added,
    "removed": findings_removed,
    "common_count": len(common_tags),
    "summary": {
        "total_added": len(added_tags),
        "total_removed": len(removed_tags),
        "total_common": len(common_tags),
    },
}
formatted = json.dumps(diff_result, ensure_ascii=False, indent=2)
output_result(formatted, output_path)
```

注意：

- `common_count` 是数字（交集大小），**不输出** common 的 findings 列表（避免冗余）。
- `summary` 三项分别对齐 added/removed/common 的 tag 数量。
- `output_path` 参数名与 scan/batch 的 `output` 不同（仅本地变量名差异，CLI 选项仍是 `--output/-o`）。

## 🔗 调用链

```
diff() → common.make_scanner() → AIOutputFormatter
       → scanner.scan_file(file1) → format_dict → dict1
       → scanner.scan_file(file2) → format_dict → dict2
       → tag 集合差/交 → 反查 findings
       → json.dumps → common.output_result()
异常 → common.error_exit()
```

## 🤝 与其它模块的关系

- **依赖 [common.py](./cli-common)**：`make_scanner`、`output_result`、`error_exit`、`TypingMethod`（未用 `OutputFormat`）。
- **依赖 [ai_output.py](./ai-output)**：`AIOutputFormatter.format_dict`。
- **与 [cmd_scan.py](./cli-cmd-scan) 对比**：scan 输出单文件完整结果；diff 输出两文件差异。
- **与 [cmd_batch.py](./cli-cmd-batch) 对比**：batch 聚合多文件全量结果；diff 聚合两文件差集。

## 📍 相关

- [AI CLI · diff](../interfaces/ai-cli-diff) — 用户视角用法与示例。
- [AI 输出格式](../guide/output-format) — diff 结果结构。
- [cmd_scan.py](./cli-cmd-scan) — 单文件扫描（dict 来源）。
- [ai_output.py](./ai-output) — `format_dict` 与 `findings` 结构。
