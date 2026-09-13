# diff_files — 对比两文件

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-success">对比</span>

🆚 `diff_files` 扫描两个文件，对比它们的检测结果，找出 **新增**（file2 有、file1 没有）和 **移除**（file1 有、file2 没有）的保护/加固/混淆差异。常用于版本对比、脱壳前后对比。

## 📋 工具签名

```
diff_files(file1, file2, timeout?, typing?, scan_depth?, include_types?) → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| `file1` | `str` | — | ✅ | 第一个文件路径（基线） |
| `file2` | `str` | — | ✅ | 第二个文件路径（对比对象） |
| `timeout` | `int` | `30` | — | YARA 扫描超时（秒，每个文件独立计时） |
| `typing` | `str` | `"magic"` | — | 文件识别方式：`magic`/`filename`/`none` |
| `scan_depth` | `int` | `2` | — | 嵌套 ZIP 归档最大递归深度 |
| `include_types` | `bool` | `False` | — | 结果中是否包含 `file_type` 检测 |

::: tip file1 是基线
`added` = file2 相对 file1 **新增** 的；`removed` = file2 相对 file1 **移除** 的。所以"file1→file2 升级后多了什么保护"，file1 放旧版、file2 放新版。
:::

## 🔧 设计要点

```python
for f, label in [(file1, "file1"), (file2, "file2")]:
    if not Path(f).exists():
        return json.dumps({"error": True, "message": f"{label} not found: {f}"})
scanner = make_scanner(...)
dict1 = formatter.format_dict(scanner.scan_file(file1), file1, ...)
dict2 = formatter.format_dict(scanner.scan_file(file2), file2, ...)

tags1 = {f["tag"] for f in dict1.get("findings", [])}
tags2 = {f["tag"] for f in dict2.get("findings", [])}
added_tags = sorted(tags2 - tags1)
removed_tags = sorted(tags1 - tags2)
common_tags = sorted(tags1 & tags2)
```

- **双扫描**：分别扫两个文件，各调一次 `scan_file` + `format_dict`。
- **比较维度是 `tag`**：用 finding 的 `tag`（`category::rule`）做集合差，不是逐字节对比文件。
- **`added`/`removed` 是完整 finding 对象**：不止是 tag 字符串，而是整个 finding（含 `source`、`confidence` 等）。
- **`common_count` 只给数量**：两文件都有的 tag 数，但不列出具体哪些——避免响应过大。
- **与 CLI `diff` 逻辑逐行对应**：代码几乎复制粘贴，唯一差异是返回 `json.dumps` 字符串 vs `output_result` 写 stdout。详见 [tools_scan.py](../modules/mcp-tools-scan)。

## 📤 返回示例

### 成功

```json
{
  "error": false,
  "file1": "/path/to/app-v1.apk",
  "file2": "/path/to/app-v2.apk",
  "added": [
    {
      "tag": "protector::bangcle",
      "category": "protector",
      "description": "...",
      "source": "/path/to/app-v2.apk!classes.dex",
      "identifier": "bangcle",
      "confidence": "high"
    }
  ],
  "removed": [],
  "common_count": 3,
  "summary": {
    "total_added": 1,
    "total_removed": 0,
    "total_common": 3
  }
}
```

### 文件不存在

```json
{ "error": true, "message": "file1 not found: /path/to/missing.apk" }
```

注意 `message` 里会标明是 `file1` 还是 `file2` 缺失，方便定位。

::: tip 如何解读
- `added` 非空 → v2 新引入了这些保护（可能升级了加固）。
- `removed` 非空 → v2 去掉了这些保护（可能脱壳了，或换了方案）。
- `common_count` 高、`added`/`removed` 都空 → 两版保护方案基本一致。
- `common_count=0` 且两边都有 finding → 两版用了完全不同的加固方案。
:::

## 🤖 在 Claude 里的使用

> 对比 /home/user/app-v1.apk 和 /home/user/app-v2.apk 的保护差异

Claude 调 `diff_files`，拿到 `added`/`removed` 后解读：

> v2 相比 v1 新增了 bangcle 保护（命中 `classes.dex`，置信度 high），原有 3 项检测两版都有。看起来 v2 换了加固方案。

也适合脱壳前后对比：

> 帮我对比原版 app.apk 和脱壳后的 app-unpacked.apk，看 removed 里是不是把壳去掉了

## 🆚 与 CLI `diff` 的差异

| 维度 | MCP `diff_files` | AI CLI `diff` |
|------|------------------|---------------|
| `--output/-o` 写文件 | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| `--verbose/-v` | ❌ 无 | ✅ 有 |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| 对比逻辑 | 同（tag 集合差） | 同（tag 集合差） |

逻辑层面：两者产出完全相同的 `added`/`removed`/`common_count`/`summary` 结构。差异仅在传输层和错误处理。

::: tip 为何不抽公共函数
`cmd_diff` 和 `diff_files` 的核心逻辑确实重复。没抽出来是因为 CLI 版要配合 `output_result`（支持 `-o` 写文件）和 `error_exit`，MCP 版要 `return` 字符串。抽象会增加耦合且收益有限。这是项目里有意识的权衡，详见 [tools_scan.py 源码文档](../modules/mcp-tools-scan#🆚-diff_files)。
:::

## 🔗 调用链

```
MCP client → FastMCP → diff_files(file1, file2, ...)
                          │
                          ├─ file1/file2 存在?  → 否: return {error:true,message:"fileN not found"}
                          │
                          └─ make_scanner()  ← 与 CLI 共享
                                 │
                                 ├─ scan_file(file1) → format_dict() → dict1
                                 ├─ scan_file(file2) → format_dict() → dict2
                                 │
                                 └─ tags1 ∆ tags2
                                      │
                                      ├─ added   = findings in dict2 whose tag ∉ tags1
                                      ├─ removed = findings in dict1 whose tag ∉ tags2
                                      └─ common_count = |tags1 ∩ tags2|
                                 │
                                 └─ return {error:false, file1, file2, added, removed, common_count, summary}
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · diff](./ai-cli-diff) — 对应的 CLI 命令。
- [scan_file](./mcp-scan-file) — diff 内部就是双次 scan。
- [tools_scan.py](../modules/mcp-tools-scan) — 适配器源码详解。
- [AI 输出格式 · diff 结果](../guide/output-format#🆚-diff-结果diff) — 返回结构说明。
- [检测类别](../guide/categories) — `tag` 的 `category` 部分。
