# list_tags — 所有检测类别

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-info">元数据</span>

🏷️ `list-tags` 工具返回 APKiD 所有可能出现的检测标签（tag）及其人类可读描述。是让 AI 客户端"知道有哪些检测维度"的自发现工具——扫描前先调它，能理解 `findings[].tag`/`category` 的含义。

::: warning 工具名带连字符
MCP 注册的工具名是 **`list-tags`**（连字符），但底层 Python 函数名是 `list_tags`（下划线）。在 `server.py` 里用 `mcp.tool(name="list-tags")` 显式指定了工具名。MCP 客户端调用时用 `list-tags`。详见 [server.py](../modules/mcp-server)。
:::

## 📋 工具签名

```
list-tags() → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| （无） | — | — | — | `list-tags` 不接受任何参数 |

零参数工具，调用时什么都不传。

## 🔧 设计要点

```python
def list_tags() -> str:
    tags = [{"tag": tag, "description": desc}
            for tag, desc in sorted(RULE_DESCRIPTIONS.items())]
    return json.dumps({"error": False, "tags": tags}, ensure_ascii=False, indent=2)
```

- **遍历 `RULE_DESCRIPTIONS`**：这个字典定义在 [`ai_output.py`](../modules/ai-output)，是所有检测类别的权威来源。每条形如 `"packer": "Detects APK packing/obfuscation tools"`。
- **`sorted(by key)`**：按 tag 名字母序排序，输出稳定。
- **每项是 `{tag, description}`**：`tag` 是类别名（如 `packer`、`anti_debug`），`description` 是人类可读说明。
- **不调 `make_scanner`**：纯静态字典查询，不需要 YARA、不需要 `rules.yarc`。即使规则没编译也能正常返回。
- **与 CLI `list-tags` 完全一致**：同样的字典、同样的排序、同样的返回结构。

::: tip tag 与 category 的关系
`list-tags` 返回的 `tag` 字段就是 [finding](../guide/output-format#🔎-finding-对象) 里的 `category` 值（如 `packer`、`compiler`）。但 finding 里还有个更具体的 `tag` 字段，格式是 `category::rule`（如 `packer::bangcle`）。别混淆：

- `list-tags` 的 `tag` = 类别名 = finding 的 `category`。
- finding 的 `tag` = `category::rule`，更具体。

详见 [检测类别](../guide/categories)。
:::

## 📤 返回示例

```json
{
  "error": false,
  "tags": [
    { "tag": "abnormal", "description": "Abnormal or suspicious modifications" },
    { "tag": "anti_debug", "description": "Anti-debugging techniques" },
    { "tag": "anti_disassembly", "description": "Anti-disassembly techniques" },
    { "tag": "anti_hook", "description": "Anti-hooking (anti-Frida, anti-Xposed)" },
    { "tag": "anti_root", "description": "Anti-root detection" },
    { "tag": "anti_vm", "description": "Anti-VM/anti-emulator" },
    { "tag": "anticheat", "description": "Anti-cheat SDKs" },
    { "tag": "compiler", "description": "Compiler or build tool fingerprints" },
    { "tag": "dropper", "description": "Dropper/loader behavior" },
    { "tag": "embedded", "description": "Embedded payloads" },
    { "tag": "file_type", "description": "File type information" },
    { "tag": "hook", "description": "Hooking frameworks (Xposed, Frida)" },
    { "tag": "internal", "description": "Internal/dev artifacts (private rules)" },
    { "tag": "manipulator", "description": "APK manipulation tools" },
    { "tag": "obfuscator", "description": "Code obfuscation tools" },
    { "tag": "packer", "description": "APK packing/obfuscation tools" },
    { "tag": "protector", "description": "App protection/hardening SDKs (RASP)" },
    { "tag": "root", "description": "Root detection or root-related libraries" },
    { "tag": "signer", "description": "APK signing certificates and signers" },
    { "tag": "yara_issue", "description": "YARA engine issues" }
  ]
}
```

实际输出顺序按 `tag` 字母序。完整类别说明见 [检测类别](../guide/categories)。

## 🤖 在 Claude 里的使用

> APKiD 都能检测哪些类别的保护？列出来

Claude 调 `list-tags`，拿到全部类别后整理：

> APKiD 能识别 20 类检测：packer（加固）、protector（保护器）、obfuscator（混淆器）、compiler（编译器）、anti_debug/anti_vm/anti_root/anti_hook（反分析）、signer（签名）、dropper/embedded（载荷）、abnormal/manipulator（异常与篡改）、hook/root（框架与 Root）、anticheat（反作弊）、file_type（文件类型）、internal（内部构件）、yara_issue（引擎问题）。

也适合让 Claude 在扫描后解释 finding：

> 扫描结果里有 `anti_debug` 类别，这是什么？→ Claude 已从 list_tags 知道是"反调试技术"

## 🆚 与 CLI `list-tags` 的差异

| 维度 | MCP `list-tags` | AI CLI `list-tags` |
|------|-----------------|--------------------|
| 工具/命令名 | `list-tags`（连字符） | `list-tags`（连字符） |
| 参数 | 无 | 无 |
| `--output/-o` | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| 返回字段 | 同（`tags:[{tag,description}]`） | 同 |

逻辑层面完全一致，差异仅在传输层。

::: tip 何时调 list_tags
- **扫描前**：让 AI 知道有哪些检测维度，便于后续解读 finding。
- **扫描后**：finding 的 `description` 字段其实就是 `RULE_DESCRIPTIONS[tag]`——如果 finding 里没带 description（某些精简场景），可调 `list_tags` 反查。
- **编写规则时**：新增 YARA 规则带新 tag，要先确认 `RULE_DESCRIPTIONS` 里有对应条目，否则 finding 的 `description` 会缺失。`list_tags` 能快速核对。
:::

## 🔗 调用链

```
MCP client → FastMCP → list_tags()  （注册名 list-tags）
                          │
                          └─ 遍历 ai_output.RULE_DESCRIPTIONS（sorted by key）
                                 │
                                 └─ [{tag, description}, ...]
                                        │
                                        └─ return json.dumps({error:false, tags:[...]})
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · list-tags](./ai-cli-list-tags) — 对应的 CLI 命令。
- [检测类别](../guide/categories) — 所有类别的详解与图标。
- [tools_info.py](../modules/mcp-tools-info) — 适配器源码详解。
- [ai_output.py](../modules/ai-output) — `RULE_DESCRIPTIONS` 字典来源。
- [AI 输出格式 · finding](../guide/output-format#🔎-finding-对象) — `category` 字段就是这里的 `tag`。
