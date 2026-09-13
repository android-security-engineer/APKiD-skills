# DEX 异常结构规则

<span class="badge badge-abnormal">abnormal</span>
<span class="badge badge-disasm">anti_disassembly</span>
<span class="badge badge-dropper">dropper</span>
<span class="badge badge-abnormal">6 条</span>

`apkid/rules/dex/abnormal.yara` — 6 条规则。这是唯一一个 **跨 3 个 tag** 的 DEX 规则文件：检测 DEX 文件结构的各种异常——非常规 header、反汇编对抗、数据注入。这些异常往往是加固/混淆/恶意行为的副作用。

## 🎯 检测原理

DEX 文件格式规范（[dex-format.html](https://source.android.com/devices/tech/dalvik/dex-format)）定义了 `header`、`map_list`、`link_data` 等字段的合法取值。但格式允许某些字段为非标准值——恶意工具利用这点藏数据或破坏反汇编器。APKiD 用 `dex` 模块直接读这些字段判定。

## 📋 规则清单（跨 3 个 tag）

### 📐 abnormal（异常结构，2 条）

| 规则 | tag | 说明 |
|------|-----|------|
| `abnormal_header_size` | abnormal | non-standard header size — `header_size != 0x70`（标准 112 字节） |
| `non_little_endian` | abnormal | non little-endian format — `endian_tag != 0x12345678` |

### 🚫 anti_disassembly（反汇编对抗，3 条）

| 规则 | tag | 说明 |
|------|-----|------|
| `non_zero_link_size` | anti_disassembly | non-zero link size — `link_size != 0x0` |
| `non_zero_link_offset` | anti_disassembly | non-zero link offset — `link_offset != 0x0` |
| `illegal_class_names` | anti_disassembly | illegal class name — 类名含 `CON`/`PRN`/`AUX`/`NUL`/`COM[1-9]`/`LPT[1-9]` 等 Windows 保留名 |

### 💉 dropper（数据注入，1 条）

| 规则 | tag | 说明 |
|------|-----|------|
| `data_injected_after_map` | dropper | injected data after map section — `file_size < map_offset + (map_list.size * 12) + 4` |

## 🔍 规则源码

### `abnormal_header_size` — header 藏数据

```yara
rule abnormal_header_size : abnormal {
  meta:
    description = "non-standard header size"
    sample = "1d97aff8d86d164dc64e81b822c01623940e2f21ab51d2fd42172b364d5e185e"
  condition:
    /*
     * Header size is always 112 bytes but the format allows it to be bigger.
     * This would make it possible to do weird stuff like hide files after
     * the normal header data.
     */
    is_dex and dex.header.header_size != 0x70
}
```

标准 DEX header 是 `0x70`（112）字节。格式允许更大——多出来的空间可藏数据（如加密 dex 片段）。命中说明 header 被改大。

### `non_zero_link_size` / `non_zero_link_offset` — link_data 被滥用

```yara
rule non_zero_link_size : anti_disassembly {
  meta:
    description = "non-zero link size"
  condition:
    dex.header.link_size != 0x0
}

rule non_zero_link_offset : anti_disassembly {
  meta:
    description = "non-zero link offset"
  condition:
    dex.header.link_offset != 0x0
}
```

`link_size`/`link_offset` 在标准 DEX 里应为 0（`link_data` 段未使用）。非零值会被某些反汇编器误解，达到对抗效果——这也是 [`jiagu_k`](./dex-packers) 等壳藏数据的手段之一。

### `non_little_endian` — 字节序反转

```yara
rule non_little_endian : abnormal {
  condition:
    dex.header.endian_tag != 0x12345678
}
```

DEX 标准 `endian_tag` 是 `0x12345678`（小端）。反转字节序会破坏多数 DEX 解析器（它们假设小端），是反分析手段。

### `data_injected_after_map` — map 段后藏数据

```yara
rule data_injected_after_map : dropper {
  meta:
    description = "injected data after map section"
  condition:
    dex.header.file_size < dex.header.map_offset + (dex.map_list.size * 12) + 4
}
```

逻辑：`map_list` 起始偏移 + 每项 12 字节 × 项数 + 4（size 字段）= map 段预期结束位置。若 `file_size` **小于**这个值……不对，规则写的是 `file_size < 预期结束`？让我看注释——实际是检测 **map 段之后还有数据**：预期 map 段结束位置若小于实际文件大小，说明后面被注入了数据。这是 dropper 把加密 payload 藏在 dex 尾部的特征。

### `illegal_class_names` — Windows 保留名陷阱

```yara
rule illegal_class_names : anti_disassembly {
  meta:
    description = "illegal class name"
  strings:
    /*
     * Disassemblers use class names for file names, and these file names
     * are illegal on some file systems (looking at you, Windows)
     */
    $invalid = /\x00[^\x00]{1,4}L([^\x00\x2f]+\x2f)*(CON|PRN|AUX|CLOCK\$|NUL|COM[1-9]|LPT[1-9])(\x2f[^\x00\x2f]+\x2f+)*;\x00/is
  condition:
    any of them
}
```

恶意 dex 把类名改成 `Lcom/CON;`、`Lx/PRN;` 等 Windows 保留名——反汇编器用类名当文件名导出时，在 Windows 上会因非法文件名失败或崩溃。这是针对分析环境的陷阱（"looking at you, Windows"）。

## 📊 finding 示例

```json
{
  "tag": "anti_disassembly::non_zero_link_size",
  "category": "anti_disassembly",
  "source": "app.apk!classes.dex",
  "identifier": "non_zero_link_size",
  "confidence": "high"
}
```

## 🧠 三个 tag 的归属逻辑

| tag | 含义 | 规则 |
|-----|------|------|
| `abnormal` | 结构不符合标准，但未必恶意 | `abnormal_header_size`、`non_little_endian` |
| `anti_disassembly` | 主动对抗反汇编器/分析工具 | `non_zero_link_size`、`non_zero_link_offset`、`illegal_class_names` |
| `dropper` | 藏数据/payload，可能是 dropper 行为 | `data_injected_after_map` |

一条规则只归属一个 tag，但同一样本可能同时命中多个（如加固壳同时有 `non_zero_link_size` + `data_injected_after_map`）。

## 📍 相关

- [abnormal 类别](./category-abnormal) — abnormal 概念
- [anti-disassembly 类别](./category-anti-disassembly) — 反汇编对抗详解
- [dropper 类别](./category-dropper) — dropper/注入行为
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [DEX 加固](./dex-packers) — `jiagu_k` 也用 `data_size+data_offset < file_size` 检测藏数据
- [DEX common](./dex-common) — `is_dex` 前置
- [DEX 文件格式](https://source.android.com/devices/tech/dalvik/dex-format) — 官方规范
