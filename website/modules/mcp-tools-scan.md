# mcp/tools_scan.py — 扫描工具适配器

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">适配器</span>

`apkid/mcp/tools_scan.py` 把 4 个扫描操作暴露为 MCP 工具。每个适配器函数返回 JSON 字符串，FastMCP 把它包成文本内容响应。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `scan_file(...)` | func | 扫描单文件 |
| `batch_scan(...)` | func | 批量扫描目录 |
| `diff_files(...)` | func | 对比两文件 |
| `type_file(...)` | func | 文件类型识别 |

## 🎯 设计模式：适配器

每个函数是 **CLI 命令的 MCP 适配器**——核心逻辑完全复用 `common.make_scanner()` + `AIOutputFormatter`，只在外层：

1. 把 MCP 的 `str` 参数转成内部需要的类型（路径检查用 `Path`）。
2. 文件不存在时返回错误 JSON（而非抛异常）。
3. `json.dumps()` 返回字符串。

```python
def scan_file(target, timeout=30, typing="magic", scan_depth=2, include_types=False) -> str:
    if not Path(target).exists():
        return json.dumps({"error": True, "message": f"File not found: {target}"})
    try:
        scanner = make_scanner(...)              # ← 与 CLI 同一个
        results = scanner.scan_file(target)
        formatter = AIOutputFormatter()
        result_dict = formatter.format_dict(results, target, include_types=include_types)
        return json.dumps(result_dict, ensure_ascii=False)
    except Exception as e:
        return json.dumps({"error": True, "message": str(e), "detail": type(e).__name__})
```

对比 [`cmd_scan.py`](./cli-cmd-scan)：CLI 版用 `error_exit`（stderr + `typer.Exit`），MCP 版 `return` 错误 JSON。**因为 MCP 工具不该让进程退出**——它得把错误作为响应返回给客户端。

## 🔧 scan_file

```python
def scan_file(target: str, timeout=30, typing="magic",
              scan_depth=2, include_types=False) -> str
```

参数与 CLI `scan` 一致（除 `--format`，MCP 永远返回 JSON；除 `--entry-max-scan-size`，MCP 固定 0）。docstring 会被 FastMCP 转成工具 schema。

返回 `format_dict` 的 JSON——与 CLI `scan --format json` **完全相同**的输出结构。

## 📦 batch_scan

```python
def batch_scan(directory: str, recursive=False, pattern="*.apk",
               timeout=30, typing="magic", scan_depth=2, include_types=False) -> str
```

与 CLI `batch` 的差别：**无进度条**（MCP 调用不适合交互式进度）。`Path.rglob`/`glob` 收集文件，空集合返回 `{error:false,scanned:0,results:[],message}`，否则 `{error:false,scanned:N,results:[...]}`。

## 🆚 diff_files

```python
def diff_files(file1: str, file2: str, timeout=30, typing="magic",
               scan_depth=2, include_types=False) -> str
```

双扫描、tag 集合差集，输出 `added`/`removed`/`common_count`/`summary`。与 CLI `diff` 逻辑逐行对应——其实代码几乎复制粘贴，唯一差异是返回 `json.dumps` 字符串 vs `output_result` 写 stdout。

::: tip 为何不抽公共函数
`cmd_diff` 和 `diff_files` 的核心逻辑确实重复。没抽出来是因为 CLI 版要配合 `output_result`（支持 `-o` 写文件）和 `error_exit`，MCP 版要 `return` 字符串。抽象会增加耦合且收益有限。这是项目里有意识的权衡。
:::

## 🔢 type_file

```python
def type_file(target: str) -> str
```

唯一不调 `make_scanner` 的扫描工具——它不需要 YARA 规则。直接 `Scanner._type_file(f)` 读魔数。与 CLI `type` 一致：识别输出 `{error,file,type,supported_types}`，不识别 `{error,file,type:null,message}`。

## 📋 错误处理对比

| 情况 | CLI 行为 | MCP 行为 |
|------|---------|---------|
| 文件不存在 | `error_exit` → stderr JSON + exit 1 | `return` 错误 JSON 字符串 |
| 扫描异常 | `error_exit` → stderr + exit 1 | `return` 错误 JSON 字符串 |
| 成功 | `output_result` → stdout | `return` 结果 JSON 字符串 |

MCP 永远不退出进程、永远返回字符串。客户端据 `error` 字段判断成败。

## 🔗 调用链

```
MCP client → FastMCP → tools_scan.scan_file(target)
                          │
                          ├─ Path(target).exists()?  → 否: return error JSON
                          │
                          └─ common.make_scanner()  ← 与 CLI 共享
                                 │
                                 └─ Scanner.scan_file()
                                        │
                                        └─ AIOutputFormatter.format_dict()
                                               │
                                               └─ json.dumps() → return 字符串
                                                    │
                                                    ▼
                                          FastMCP 包装成 MCP 文本响应
```

## 📍 相关

- [mcp/server.py](./mcp-server) — 注册这些工具的地方。
- [tools_info.py](./mcp-tools-info) — 信息类工具。
- [CLI 命令文档](./cli-cmd-scan) — 对应的 CLI 版本。
- [架构概览](../guide/architecture) — 共享 make_scanner 原则。
