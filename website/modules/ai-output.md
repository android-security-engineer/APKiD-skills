# ai_output.py — AI 输出格式化

<span class="badge badge-info">AI</span>
<span class="badge badge-info">formatter</span>
<span class="badge badge-info">RULE_DESCRIPTIONS</span>

`apkid/ai_output.py` 把 YARA 的原始 `Match` 对象整理成结构化、AI 友好的 finding 列表。AI CLI 和 MCP 服务器都用它。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `SCHEMA_VERSION` | str | `"1.0.0"`，输出 schema 版本 |
| `RULE_DESCRIPTIONS` | dict | 检测类别 → 人可读描述 |
| `AIOutputFormatter` | class | 格式化器 |

## 📐 SCHEMA_VERSION

```python
SCHEMA_VERSION = "1.0.0"
```

破坏性变更（字段改名、类型改变）时 bump。每个输出顶层带 `schema_version` 字段。详见 [AI 输出格式](../guide/output-format)。

## 🏷️ RULE_DESCRIPTIONS

字典映射检测类别到描述。**这是"加新 tag 要同步更新"的唯一源头**——CLAUDE.md 明确规定：

> 如果你加了一条带新 tag 的 YARA 规则，必须在 `RULE_DESCRIPTIONS` 里加它。

```python
RULE_DESCRIPTIONS = {
    "anti_vm": "Detects anti-VM/anti-emulator techniques",
    "anti_debug": "Detects anti-debugging techniques",
    "packer": "Detects APK packing/obfuscation tools",
    "obfuscator": "Detects code obfuscation tools",
    "protector": "Detects app protection/shielding SDKs",
    "compiler": "Detects compiler or build tool fingerprints",
    # ... 共 20 项
}
```

这个字典同时被 `_categorize_tag()` 用来判定 category（遍历 key，看哪个是 tag 的子串），所以它既是描述表也是分类表。详见 [检测类别](../guide/categories)。

## 🧱 AIOutputFormatter

### 公开方法

```python
formatter.format(results, target, fmt="json", include_types=False) -> str   # → JSON 或文本
formatter.format_dict(results, target, include_types=False) -> Dict           # → 字典（batch/diff 用）
```

`format()` 的 `fmt` 参数：`"json"`（默认）或 `"text"`。文本格式是给人读的简版：

```
Target: /path/to/app.apk

  [packer] jiagu_360_v5
    Detects APK packing/obfuscation tools
  [compiler] dx
    Detects compiler or build tool fingerprints

Scanned at: 2026-07-02T...
```

### _build_result_dict

构造顶层结构：

```python
{
    "schema_version": SCHEMA_VERSION,
    "error": False,
    "target": target,
    "findings": findings,
    "summary": self._build_summary(findings),
    "scanned_at": datetime.now(timezone.utc).isoformat(),
}
```

::: warning scanned_at 用 datetime.now
这里直接调 `datetime.now(timezone.utc)`——在 Claude Code 的 Workflow 脚本里 `Date.now()` 不可用，但这是 APKiD 自己的运行时代码，不受那条限制。
:::

### _match_to_findings

把一个 `yara.Match` 转成若干 finding（一条规则可有多个 tag，每个 tag 一条）：

```python
for tag in match.tags:
    if tag == 'file_type' and not include_types:
        continue   # file_type 默认不输出
    category = self._categorize_tag(tag)
    finding = {
        "tag": f"{tag}::{match.rule}" if match.rule != tag else tag,
        "category": category,
        "description": RULE_DESCRIPTIONS.get(category, "Unknown detection category"),
        "source": source,
        "identifier": match.rule,
        "rule_detail": match.meta.get('description', match.rule),
        "confidence": self._infer_confidence(source),
    }
    if version:
        finding["version"] = version
```

无 tag 的规则退化为单条 finding，tag 直接用规则名。

### _infer_confidence

按 source 路径推断可信度（high=DEX、medium=ELF、low=APK 层）。详见 [AI 输出格式 · 置信度推断](../guide/output-format#置信度推断)。

### _extract_version

从规则名提取版本号。两个正则：

- `r'_v(\d+(?:_\d+)*)'` → `_v3_4` 得 `"3.4"`
- `r'_(\d+_\d+(?:_\d+)*)$'` → `_3_92` 得 `"3.92"`

匹配失败返回 `None`，finding 不带 `version` 字段。

### _categorize_tag

```python
def _categorize_tag(self, tag: str) -> str:
    tag_lower = tag.lower()
    for category in RULE_DESCRIPTIONS:
        if category in tag_lower:
            return category
    return "abnormal"
```

遍历 `RULE_DESCRIPTIONS` 的 key，返回第一个是 tag 子串的。兜底 `abnormal`。

### _build_summary

```python
{
    "total_findings": len(findings),
    "categories": { 类别名: 计数 },
}
```

## 🔗 与其它模块的关系

```
Scanner.scan_file() → Dict[str, List[yara.Match]]
                              │
                              ▼
                    AIOutputFormatter.format()
                              │
                              ▼
              JSON 字符串 / dict → CLI stdout 或 MCP 响应
```

CLI 命令（`cmd_scan` 等）和 MCP 工具（`tools_scan` 等）都调它。**它不依赖 Scanner 的实现细节**，只吃 `Dict[str, List[Match]]`——这让格式化器可独立测试（`tests/test_ai_output.py` 不需要真扫文件）。

## 📍 相关

- [检测类别](../guide/categories) — `RULE_DESCRIPTIONS` 全表。
- [AI 输出格式](../guide/output-format) — 输出 schema。
- [output.py](./output) — 经典（非 AI）输出格式化器。
