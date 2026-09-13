# cli/cmd_tags.py — list-tags 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">目录</span>

🏷️ `apkid-ai-cli list-tags` 列出所有检测类别（tag）及其描述。无参数，数据源是 `ai_output.RULE_DESCRIPTIONS` 字典——这是"APKiD 能检测什么"的权威清单。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `list_tags()` | func | typer 命令回调，列出所有检测 tag |

模块仅导出 `list_tags` 函数。`app.py` 用 `app.command(name="list-tags")(cmd_tags.list_tags)` 注册——函数名 `list_tags`（下划线），命令名 `list-tags`（连字符，更 CLI 化）。

## 🖥️ 命令签名

```bash
apkid-ai-cli list-tags
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 🔧 源码要点

```python
from apkid.ai_output import RULE_DESCRIPTIONS

def list_tags():
    """List all available detection tags and their descriptions."""
    tags = []
    for tag, desc in sorted(RULE_DESCRIPTIONS.items()):
        tags.append({"tag": tag, "description": desc})
    typer.echo(json.dumps({"tags": tags}, ensure_ascii=False, indent=2))
```

要点：

- **数据源是 `RULE_DESCRIPTIONS`**：这是 [ai_output.py](./ai-output) 里的字典，key 是 tag 名（如 `compiler`、`packer`、`obfuscator`），value 是人类可读描述。**加新 YARA 规则带新 tag 时必须在这里登记**，否则 `list-tags` 看不到、AI 输出也缺描述。
- **`sorted(...)`**：按 tag 名字典序输出，结果稳定。
- **输出结构**：`{"tags": [{"tag": ..., "description": ...}, ...]}`，扁平数组，便于 AI 遍历。
- **不调 `make_scanner`、不加载规则**：tag 描述是静态字典，与 `rules.yarc` 是否编译无关。
- **直接 `typer.echo`**：不走 `output_result`（无 `--output`），不走 `AIOutputFormatter`（这本身就是元数据，不是扫描结果）。
- **无 try/except**：函数几乎不可能失败（除非 `RULE_DESCRIPTIONS` 导入出错），所以没有错误处理。

## 🔗 调用链

```
list_tags() → ai_output.RULE_DESCRIPTIONS.items()
            → sorted
            → [{"tag", "description"}, ...]
            → typer.echo(json.dumps({"tags": [...]}))
```

## 🤝 与其它模块的关系

- **依赖 [ai_output.py](./ai-output)**：`RULE_DESCRIPTIONS` 字典——这是唯一数据源。
- **不依赖 [common.py](./cli-common)**：不调任何 common 函数。
- **被 [app.py](./cli-app) 注册**：`app.command(name="list-tags")(cmd_tags.list_tags)`，名字重映射。
- **与 [cmd_info.py](./cli-cmd-info) 互补**：info 给"规则数量/哈希"，list-tags 给"规则能检测哪些类别"。
- **与 [cmd_rules.py](./cli-cmd-rules) 区分**：rules list 列的是 **YARA 源文件**（`.yara` 文件名），list-tags 列的是 **检测类别**（tag 名）。

## 📍 相关

- [AI CLI · list-tags](../interfaces/ai-cli-list-tags) — 用户视角用法与示例。
- [ai_output.py](./ai-output) — `RULE_DESCRIPTIONS` 字典定义处。
- [cmd_info.py](./cli-cmd-info) — 规则元数据。
- [cmd_rules.py](./cli-cmd-rules) — YARA 源文件列表。
- [检测类别](../guide/categories) — 各 tag 的含义详解。
