# DEX 编译器规则

<span class="badge badge-compiler">compiler</span>
<span class="badge badge-compiler">15 + 11 private</span>

`apkid/rules/dex/compilers.yara` — 15 条公开 compiler 规则 + 1 条 `dexmerge : manipulator` + 11 条 private 积木。这是 APKiD 最精巧的一类：靠 DEX 的 **`map_list` 类型排列顺序指纹** 区分不同编译器工具链。

## 🎯 核心原理：map_list 类型顺序指纹

DEX 文件有个 `map_list`，按顺序列出所有数据段（`TYPE_HEADER_ITEM`、`TYPE_STRING_ID_ITEM`、`TYPE_CODE_ITEM`…）。DEX 规范 **没规定这些类型的排列顺序**，于是不同编译器各自有默认顺序——这成了指纹：

```
dx 顺序：     ... CODE_ITEM, TYPE_LIST, STRING_DATA_ITEM
r8 顺序：     ... CODE_ITEM, DEBUG_INFO_ITEM, TYPE_LIST, STRING_DATA_ITEM
dexlib2 顺序：... STRING_DATA_ITEM, TYPE_LIST（+ null_interfaces 特征）
```

APKiD 用 `dex` 模块读 `dex.map_list.map_item[N].type` 字段做判定。类型常量如：

| 常量 | 值 | 含义 |
|------|----|----|
| `TYPE_HEADER_ITEM` | 0x0000 | 文件头 |
| `TYPE_STRING_ID_ITEM` | 0x0001 | 字符串 ID 表 |
| `TYPE_TYPE_ID_ITEM` | 0x0002 | 类型 ID 表 |
| `TYPE_CLASS_DEF_ITEM` | 0x0006 | 类定义表 |
| `TYPE_CALL_SITE_ID_ITEM` | 0x0007 | 调用点 ID（r8 独有顺序） |
| `TYPE_METHOD_HANDLE_ITEM` | 0x0008 | 方法句柄（r8 独有顺序） |
| `TYPE_MAP_LIST` | 0x1000 | map_list 本身 |
| `TYPE_TYPE_LIST` | 0x1001 | 类型列表 |
| `TYPE_ANNOTATION_*` | 0x1002/0x1003 | 注解（dx 独有顺序） |
| `TYPE_CODE_ITEM` | 0x2001 | 代码项 |
| `TYPE_DEBUG_INFO_ITEM` | 0x2003 | 调试信息（r8 独有顺序） |
| `TYPE_STRING_DATA_ITEM` | 0x2002 | 字符串数据 |

## 📋 公开编译器规则（15 条）

| 规则 | tag | 说明 |
|------|-----|------|
| `jack_4_12` | compiler | Jack 4.12 — `\0<len>emitter: jack-4.12\0` 字符串 |
| `jack_3x` | compiler | Jack 3.x — `jack-3.` emitter 正则 |
| `jack_4x` | compiler | Jack 4.x — `jack-4.` emitter（排除 4.12） |
| `jack_5x` | compiler | Jack 5.x — `jack-5.` emitter |
| `jack_generic` | compiler | Jack (unknown version) — emitter 或匿名方法特征，排除已知版本 |
| `dexlib1` | compiler | dexlib 1.x — `unsorted_string_pool`（字符串池未排序） |
| `dexlib2beta` | compiler | dexlib 2.x beta — `null_interfaces`（排除 dexlib1） |
| `dexlib2` | compiler | dexlib 2.x — `dexlib2_map_type_order`（排除 beta/dexlib1） |
| `dx` | compiler | dx — `dx_map_type_order`（排除 dexlib/r8_marker） |
| `dx_merged` | compiler | dx (possible dexmerge) — `dexmerge_map_type_order` |
| `r8` | compiler | r8 — `r8_marker` + `r8_map_type_order`/`ambiguous_tiny_dex_map_type_order` |
| `r8_merged` | compiler | r8 (possible dexmerge) — `r8_marker` + `dexmerge_map_type_order` |
| `r8_no_marker` | compiler | r8 without marker (suspicious) — 删了 marker 的 r8，靠 map 顺序仍能抓 |
| `dexmerge` | manipulator | dexmerge — `dexmerge_map_type_order`（tag 是 manipulator） |
| `unknown_compiler` | compiler | unknown (please file detection issue!) — 是 dex 但都不匹配，提示提 issue |

## 📋 private 积木规则（11 条）

这些规则 tag 是 `internal`，不直接输出，被公开规则组合引用：

| 私有规则 | 说明 |
|---------|------|
| `unsorted_string_pool` | String pool in non-standard order — `string_ids[i+1].offset < string_ids[i].offset`（dexlib1 特征） |
| `dexlib2_map_type_order` | dexlib2 map_list type order — `map_item[7]==0x2002 and map_item[8]==0x1001` |
| `null_interfaces` | null interfaces offset — `interfaces_offset>0` 但指向 4 个 null 字节（dexlib2 独有） |
| `dx_map_type_order` | dx map_list type order — 9 种 map 顺序组合（覆盖缺各类 ANNOTATION 的情况） |
| `ambiguous_tiny_dex_map_type_order` | ambiguous tiny dex map type order — 极小 dex，dexlib2 与 r8 难区分 |
| `r8_map_type_order` | r8 map_list type order — 6 种组合（含 CALL_SITE_ID/METHOD_HANDLE/DEBUG_INFO） |
| `r8_marker` | r8 hidden marker — `~~D8{"compilation-mode":"...}` 隐藏标记 |
| `dexmerge_map_type_order` | dexmerge map_list type order — `map_item[7].type == 0x1000`（MAP_LIST 提前） |
| `has_jack_anon_methods` | has Jack compiler anonymous methods — `-set0`/`-get0`/`-wrap0` 命名 |
| `jack_emitter` | has Jack compiler emitter string — `emitter: jack-?.?` 正则 |
| `has_javac_anon_methods` | has Javac compiler anonymous methods — `access$000`/`$002`/`$100` 命名 |

## 🔍 规则源码示例

### `r8_marker` — R8 的隐藏 marker

```yara
private rule r8_marker : internal {
  meta:
    description = "r8 hidden marker"
  strings:
    // Example: ~~D8{"compilation-mode":"
    // OR:      ~~D8{"backend":"dex","compilation-mode":"
    // OR:      ~~L8{"compilation-mode":"
    $marker = { 00 [1-2] 7E 7E ( 44 | 52 | 4C ) 38 7B 22 [0-16] 63 6F 6D 70 69 6C 61 74 69 6F 6E 2D 6D 6F 64 65 22 3A 22 }
  condition:
    $marker
}
```

`7E 7E` = `~~`，`( 44 | 52 | 4C )` = `D`/`R`/`L`（D8/R8/L8），`38 7B 22` = `8{"`，后面是 `"compilation-mode":"`。R8 会在 dex 里留这个隐藏 marker 记录编译模式——开发者可删，但删 marker 容易、改 map 顺序难。

### `r8` — marker + map 顺序双重确认

```yara
rule r8 : compiler {
  condition:
    r8_marker
    and (r8_map_type_order or ambiguous_tiny_dex_map_type_order)
}
```

### `dx` — 纯 map 顺序，排除其它

```yara
rule dx : compiler {
  condition:
    dx_map_type_order
    and not dexlib1
    and not dexlib2
    and not dexlib2beta
    and not r8_marker
}
```

dx 没有 marker，全靠 map 顺序——但必须排除 dexlib1/2 和 r8_marker，因为它们的 map 顺序可能与 dx 重叠（尤其缺 ANNOTATION 项时）。

### `r8_no_marker` — 抓"删了 marker 的 r8"

```yara
rule r8_no_marker : compiler {
  meta:
    description = "r8 without marker (suspicious)"
  condition:
    not r8_marker
    and r8_map_type_order
}
```

marker 容易藏（开发者可删），map 顺序难藏（改了就破坏 dex 结构）。这条规则靠 map 顺序仍能抓住"删了 marker 的 r8"，并标记 `suspicious`。

## 🧠 Jack 的特殊识别

Jack 不靠 map 顺序，靠 **emitter 字符串** 和 **匿名方法命名**：

```yara
rule jack_4_12 : compiler {
  strings:
    // \0<len>emitter: jack-4.12\0
    $jack_emitter = {00 12 65 6D 69 74 74 65 72 3A 20 6A 61 63 6B 2D 34 2E 31 32 00}
  condition:
    is_dex and $jack_emitter
}
```

Jack 的匿名方法叫 `-set0`/`-get0`/`-wrap0`（`has_jack_anon_methods`），而 javac 的叫 `access$000`/`$002`/`$100`（`has_javac_anon_methods`）——`jack_generic` 兜底识别未版本化的 Jack。

## 📊 finding 示例

```json
{
  "tag": "compiler::r8",
  "category": "compiler",
  "source": "app.apk!classes.dex",
  "identifier": "r8",
  "confidence": "high"
}
```

DEX 字节码级匹配 → 置信度 `high`。

## 🧠 unknown_compiler 的意义

```yara
rule unknown_compiler : compiler {
  meta:
    description = "unknown (please file detection issue!)"
  condition:
    is_dex
    and not ( (dexlib1 or dexlib2 or dexlib2beta)
           or (dx or dx_merged)
           or (r8 or r8_merged or r8_no_marker)
           or (jack_generic or jack_3x or jack_4x or jack_4_12 or jack_5x)
           or (dexmerge) )
}
```

这是"兜底"规则——是 dex 但不属于任何已知编译器。命中它说明出现了 **新编译器或异常产物**，提示去 [GitHub 提 issue](https://github.com/rednaga/APKiD/issues) 补规则。

## 📍 相关

- [compiler 类别](./category-compiler) — 编译器概念与 map_list 顺序指纹详解
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [DEX common](./dex-common) — `is_dex` 前置
- [obfuscator 类别](./category-obfuscator) — 编译器 vs 混淆器
- [Android Compiler Fingerprinting (HITCON 2016)](http://hitcon.org/2016/CMT/slide/day1-r0-e-1.pdf)
- [编写 YARA 规则](./writing-rules) — DEX 模块用法
