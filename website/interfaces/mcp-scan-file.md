# scan_file — 扫描单文件

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-success">核心</span>

🔍 `scan_file` 是 `apkid-mcp` 最常用、最基础的 MCP 工具。扫描单个 APK/DEX/ELF 文件，识别加壳、签名、编译器、保护器、反调试/反虚拟机等标识。

## 📋 工具签名

```
scan_file(target, timeout?, typing?, scan_depth?, include_types?) → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| `target` | `str` | — | ✅ | 待扫描的 APK/DEX/ELF 文件路径 |
| `timeout` | `int` | `30` | — | YARA 扫描超时（秒） |
| `typing` | `str` | `"magic"` | — | 文件识别方式：`magic`/`filename`/`none` |
| `scan_depth` | `int` | `2` | — | 嵌套 ZIP 归档最大递归深度 |
| `include_types` | `bool` | `False` | — | 结果中是否包含 `file_type` 检测 |

::: tip 参数全是位置或关键字皆可
MCP 客户端（如 Claude）既可按位置传参，也可按关键字名传参。FastMCP 把函数的类型注解和 docstring 自动转成工具 schema，所以客户端看到的就是上面的参数表。
:::

## 🔧 设计要点

`scan_file` 是 [AI CLI `scan`](./ai-cli-scan) 的 MCP 适配器，核心扫描逻辑 **完全复用** `common.make_scanner()` + `AIOutputFormatter`：

```python
scanner = make_scanner(timeout=timeout, typing=typing,
                       scan_depth=scan_depth,
                       entry_max_scan_size=0,        # ← MCP 固定 0（不限）
                       include_types=include_types)
results = scanner.scan_file(target)
formatter = AIOutputFormatter()
result_dict = formatter.format_dict(results, target, include_types=include_types)
return json.dumps(result_dict, ensure_ascii=False)
```

几个关键点：

- **与 CLI 共享 `make_scanner`**：扫描行为、规则加载、YARA 引擎调用完全一致——MCP 和 CLI 扫同一个文件结果必然相同。参见 [make_scanner](../modules/cli-common)。
- **`entry_max_scan_size` 固定为 `0`**：MCP 版不像经典 CLI 默认 100MB 限制，而是 0（不限）。这是 MCP 与经典 CLI 的默认值差异之一（AI CLI 也用 0）。
- **永远返回 JSON**：没有 `--format` 选项，MCP 版恒返回 `format_dict` 的 JSON——与 CLI `scan --format json` **完全相同的输出结构**。
- **错误用 `return` 而非 `exit`**：文件不存在或扫描异常时，返回错误 JSON 字符串，**不调用 `sys.exit`**——因为 MCP 工具不该让服务器进程退出。

## 📤 返回示例

### 成功

返回 [`format_dict`](../modules/ai-output) 的 JSON，结构详见 [AI 输出格式](../guide/output-format)：

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "target": "/path/to/app.apk",
  "findings": [
    {
      "tag": "packer::jiagu_360_v5",
      "category": "packer",
      "description": "Detects APK packing/obfuscation tools",
      "source": "/path/to/app.apk!assets/libjiagu.so",
      "identifier": "jiagu_360_v5",
      "rule_detail": "360 Jiagu v5",
      "confidence": "medium",
      "version": "5"
    }
  ],
  "summary": {
    "total_findings": 1,
    "categories": { "packer": 1 }
  },
  "scanned_at": "2026-07-02T08:30:00.000000+00:00"
}
```

### 文件不存在

```json
{ "error": true, "message": "File not found: /path/to/missing.apk" }
```

注意：这种情况 **没有 `detail` 字段**（仅 `message`）。而扫描过程中抛异常时才会带 `detail`（异常类名）。

### 扫描异常

```json
{ "error": true, "message": "...", "detail": "ValueError" }
```

## 🤖 在 Claude 里的使用

配置好 `apkid-mcp` 后（见 [MCP 概览](./mcp)），直接对 Claude 说：

> 帮我扫描 /home/user/app.apk，看看用了什么加固

Claude 会自动调用 `scan_file`，拿到上面的 JSON，然后用自然语言解读："这个 APK 用了 360 加固 v5，命中来源是 `assets/libjiagu.so`，置信度 medium……"

也可以显式指定参数：

> 用 scan_file 扫描 /home/user/app.apk，timeout 设 60 秒，include_types 开启

::: tip 让 Claude 先探类型
如果不确定文件是不是 Android 二进制，可以让 Claude 先调 [`type_file`](./mcp-type-file)（秒级，不加载 YARA），确认 `type` 非 `null` 再调 `scan_file`，避免无谓的 YARA 加载。
:::

## 🆚 与 CLI `scan` 的差异

| 维度 | MCP `scan_file` | AI CLI `scan` | 经典 CLI `apkid` |
|------|-----------------|---------------|------------------|
| 输出格式 | 恒 JSON（无 `--format`） | `--format json`/`text` | 人类可读（`-j` 转 JSON） |
| `entry_max_scan_size` | 固定 `0`（不限） | 默认 `0`（不限） | 默认 100MB |
| `--output/-o` 写文件 | ❌ 无 | ✅ 有 | ✅ 有 |
| `--verbose/-v` 调试日志 | ❌ 无 | ✅ 有 | ✅ 有 |
| 文件不存在 | `return` 错误 JSON | `error_exit`（stderr + exit 1） | 报错退出 |
| 调用方式 | MCP 协议工具调用 | shell 命令 | shell 命令 |

逻辑层面：两者调同一个 `make_scanner()`，`findings`/`summary` 结构完全一致。差异只在 **传输层**（MCP 文本响应 vs stdout）和 **错误处理**（return vs exit）。详见 [tools_scan.py 源码](../modules/mcp-tools-scan)。

::: warning MCP 没有 `--format text`
CLI 加 `--format text` 可得人类可读简版，MCP 版没有这个选项——永远返回 JSON。如果想让 Claude 给你人类可读的总结，直接让它扫完后用自然语言描述即可，无需在工具层做格式转换。
:::

## 🔗 调用链

```
MCP client → FastMCP → scan_file(target)
                          │
                          ├─ Path(target).exists()?  → 否: return {error:true,message}
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

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · scan](./ai-cli-scan) — 对应的 CLI 命令（用户视角）。
- [tools_scan.py](../modules/mcp-tools-scan) — 适配器源码详解。
- [AI 输出格式](../guide/output-format) — 返回 JSON 的完整 schema。
- [common.make_scanner](../modules/cli-common) — 共享扫描器构造。
- [扫描深度与递归](../guide/scan-depth) — `scan_depth` 参数详解。
