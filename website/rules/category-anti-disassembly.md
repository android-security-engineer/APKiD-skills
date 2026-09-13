# 类别：anti_disassembly 反汇编

<span class="badge badge-anti">anti_disassembly</span>

`anti_disassembly` 类别检测 **让反汇编器/反编译器出错或崩溃的结构篡改**——故意制造 DEX 规范的边缘情况，让 baksmali/jadx 等工具无法正确解析。

## 🎯 常见手段

- **非零 link_size/link_offset**：DEX 的 `link_data` 本应空着，给它塞数据会让很多解析器困惑。
- **非法类名**：类名包含规范不允许的字符。
- **错位的结构**：故意让某个偏移指向不该指的地方。

## 📋 规则分布

`anti_disassembly` tag 的规则在 `dex/abnormal.yara`：

| 规则 | 检测 |
|------|------|
| `non_zero_link_size` | DEX header 的 `link_size` 非 0 |
| `non_zero_link_offset` | DEX header 的 `link_offset` 非 0 |
| `illegal_class_names` | 类名含非法字符 |

## 🔍 规则示例

```yara
rule non_zero_link_size : anti_disassembly {
  condition:
    is_dex and dex.header.link_size != 0
}
```

正常的 DEX `link_size` 和 `link_offset` 都是 0（link 段已弃用）。非 0 说明被故意塞了数据——常见于混淆/加固产物，目的是让标准解析器报错或走非常规路径。

## 📊 finding 示例

```json
{
  "tag": "anti_disassembly::non_zero_link_size",
  "category": "anti_disassembly",
  "description": "Detects anti-disassembly techniques",
  "source": "app.apk!classes.dex",
  "identifier": "non_zero_link_size",
  "confidence": "high"
}
```

## 🆚 与 abnormal 的区别

- **anti_disassembly**：篡改是 **故意的对抗手段**，有明确目的（让工具出错）。
- **abnormal**：结构异常，可能是 bug、非常规编译器或损坏，不一定有对抗意图。

详见 [abnormal 类别](./category-abnormal)。

## 📍 相关

- [DEX 异常结构](./dex-abnormal) — 同一文件的规则。
- [abnormal 类别](./category-abnormal) — 区别。
- [检测类别](../guide/categories)
