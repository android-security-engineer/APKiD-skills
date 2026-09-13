# output.py — 经典输出格式化

<span class="badge badge-info">经典 CLI</span>
<span class="badge badge-info">OutputFormatter</span>

`apkid/output.py` 是 **经典 CLI**（`apkid` 命令）的输出层。与 [ai_output.py](./ai-output) 平行，但风格不同：彩色终端表格或紧凑 JSON，且支持写多文件目录。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `prt_*` 系列 | lambda | ANSI 颜色辅助函数 |
| `is_windows_cmd()` | func | 检测 Windows cmd（不支持 ANSI） |
| `colorize_tag(tag)` | func | 按 tag 上色 |
| `OutputFormatter` | class | 格式化器 |

## 🎨 彩色系统

```python
prt_red    = lambda s: f"\033[91m{s}\033[00m"
prt_green  = lambda s: f"\033[92m{s}\033[00m"
# ... 共 11 种颜色
```

`colorize_tag` 按 tag 类别选色：

| tag | 颜色 | 含义 |
|-----|------|------|
| `compiler` | cyan | 编译器 |
| `manipulator` | light cyan | 篡改器 |
| `abnormal` | light gray | 异常 |
| `anti_vm`/`anti_debug`/`anti_disassembly`/`anti_root` | purple | 反分析 |
| `packer`/`protector`/`anticheat` | red | 加固/保护 |
| `obfuscator` | yellow | 混淆 |
| `dropper` | green | 释放器 |
| `embedded` | light purple | 内嵌 |
| `file_type` | orange | 文件类型 |
| `internal` | pink | 内部 |

`is_windows_cmd()` 在 Windows 且无 SESSIONNAME 时返回 True，此时禁用颜色（cmd.exe 不认 ANSI）。

## 🧱 OutputFormatter

### 构造

```python
def __init__(self, json_output, output_dir, rules_manager, include_types):
    self.output_dir = output_dir
    self.json = json_output or output_dir   # output_dir 隐含 JSON
    self.version = __version__
    self.rules_hash = rules_manager.hash
    self.include_types = include_types
```

关键：`output_dir` 不为 None 时，`self.json` 强制为 True——写目录必须用 JSON（每文件一个 json）。

### write(results)

```python
def write(self, results):
    if self.output_dir:
        # 取最短 key 作为基准文件名（嵌套时外层最短）
        base_file = sorted(results.keys(), key=lambda k: len(k))[0]
        out_file = os.path.join(self.output_dir, *base_file.split(os.path.sep))
        # 建目录、写 json
    else:
        if self.json:
            self._print_json(results)
        else:
            self._print_console(results)
```

`--output-dir` 模式：把每个扫描结果写成 `<output_dir>/<文件路径>.json`，**保留目录结构**。适合批量特征提取。

### _print_console

```
[*] app.apk!classes.dex
 |-> compiler : dx
[*] app.apk!lib/arm64/libfoo.so
 |-> obfuscator : ollvm_v9
```

TTY 且非 Windows cmd 时给 tag 上色。非 TTY（管道/重定向）输出纯文本，方便脚本处理。

### build_json_output

```python
{
  "apkid_version": "3.1.0",
  "rules_sha256": "...",
  "files": [
    { "filename": "app.apk!classes.dex", "matches": { "compiler": ["dx"] } },
    ...
  ]
}
```

注意这与 [AI 输出格式](../guide/output-format) **不同 schema**——经典 JSON 是 `{files: [{filename, matches}]}`，AI JSON 是 `{findings: [], summary: {}}`。AI 输出更适合程序解析，经典 JSON 是历史格式。

### _build_match_results

把 `List[Match]` 转成 `Dict[tags_string, List[description]]`：

```python
{
  "compiler": ["dx"],
  "obfuscator": ["OLLVM v9", "string encryption"]
}
```

`file_type` tag 在 `include_types=False` 时被过滤。

## 🆚 与 AIOutputFormatter 的区别

| 维度 | OutputFormatter（经典） | AIOutputFormatter（AI） |
|------|------------------------|------------------------|
| 用在哪 | `apkid` 命令 | `apkid-ai-cli`、`apkid-mcp` |
| 终端输出 | 彩色表格 | 文本（可选） |
| JSON schema | `{files:[{filename,matches}]}` | `{findings:[...], summary:{}}` |
| finding 粒度 | 按 tags 分组 | 每条规则每 tag 一条 |
| 置信度 | 无 | high/medium/low |
| schema_version | 无 | `1.0.0` |
| 写多文件 | 支持（`--output-dir`） | 不支持 |

两者共享同一个 `Scanner` 输出（`Dict[str, List[Match]]`），只是格式化方向不同。

## 📍 相关

- [ai_output.py](./ai-output) — AI 输出格式化器。
- [AI 输出格式](../guide/output-format) — AI schema 详解。
- [main.py](./main) — 谁调用 OutputFormatter。
