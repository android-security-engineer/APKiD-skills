# 类别：compiler 编译器

<span class="badge badge-compiler">compiler</span>

`compiler` 类别通过 **DEX 结构指纹** 识别把源码编译成 dex 的工具链。这是 APKiD 最精巧的一类——靠 `map_list` 类型排列顺序区分编译器。

## 🎯 为什么能识别编译器

DEX 文件有个 `map_list`，列出所有数据段（`TYPE_HEADER_ITEM`、`TYPE_STRING_ID_ITEM`、`TYPE_CODE_ITEM`…）。DEX 规范 **没规定这些类型的排列顺序**，于是不同编译器各自有默认顺序——这成了指纹：

```
dx 的顺序：  ... CODE_ITEM, TYPE_LIST, STRING_DATA_ITEM
r8 的顺序：  ... CODE_ITEM, DEBUG_INFO_ITEM, TYPE_LIST, STRING_DATA_ITEM
dexlib2 的： ... STRING_DATA_ITEM, TYPE_LIST（null_interfaces 特征）
```

APKiD 用 [yara-python-dex](https://github.com/rednaga/yara-dex-module) 的 `dex` 模块直接读这些字段做判定。

## 📋 规则分布

`compiler` tag 只在 **DEX** 下有规则：`dex/compilers.yara`，15 条。详见 [DEX 编译器](./dex-compilers)。

## 🛠️ 可识别的编译器

| 编译器 | 规则 | 说明 |
|--------|------|------|
| dx | `dx` | Android 老 dx 编译器 |
| dx（合并） | `dx_merged` | 经 dexmerge 合并的 dx 产物 |
| D8/R8 | `r8`、`r8_merged`、`r8_no_marker` | 现代 Android 默认，含隐藏 marker 检测 |
| Jack | `jack_3x`/`4x`/`4_12`/`5x`/`generic` | Google 已弃用的 Jack 工具链 |
| dexlib 1.x | `dexlib1` | smali/apktool 1.x |
| dexlib 2.x | `dexlib2`、`dexlib2beta` | smali/apktool 2.x |
| 未知 | `unknown_compiler` | 是 dex 但都不匹配——提示提 issue |

另有 `dexmerge : manipulator`（tag 是 manipulator 不是 compiler），识别 dex 合并操作。

## 🔍 检测原理详解

### private 积木

编译器规则大量用 private 结构指纹作积木：

```yara
private rule dx_map_type_order : internal {
  condition:
    // dx 的 map_list 从第 7 项开始的类型顺序
    (dex.map_list.map_item[7].type == 0x2001 and dex.map_list.map_item[8].type == 0x1001)
    or ...  // 多种缺失可选项的组合
}

private rule r8_map_type_order : internal { ... }
private rule r8_marker : internal {
  // R8 的隐藏 marker：~~D8{"compilation-mode":"...
  strings:
    $marker = { 00 [1-2] 7E 7E ( 44 | 52 | 4C ) 38 7B 22 ... }
  condition: $marker
}
```

### 最终规则组合积木

```yara
rule dx : compiler {
  condition:
    dx_map_type_order
    and not dexlib1 and not dexlib2 and not dexlib2beta
    and not r8_marker
}

rule r8 : compiler {
  condition:
    r8_marker
    and (r8_map_type_order or ambiguous_tiny_dex_map_type_order)
}

rule r8_no_marker : compiler {
  // 隐藏 marker 容易，藏 map 顺序难——这条抓"删了 marker 的 r8"
  condition:
    not r8_marker and r8_map_type_order
}
```

### Jack 的特征

Jack 不靠 map 顺序，靠 emitter 字符串和匿名方法命名：

```yara
rule jack_4_12 : compiler {
  strings:
    // \0<len>emitter: jack-4.12\0
    $jack_emitter = {00 12 65 6D 69 74 74 65 72 3A 20 6A 61 63 6B 2D 34 2E 31 32 00}
  condition:
    is_dex and $jack_emitter
}
```

Jack 的匿名方法叫 `-set0`/`-get0`/`-wrap0`（`has_jack_anon_methods`），而 javac 的叫 `access$000`/`$002`/`$100`（`has_javac_anon_methods`）。

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

`source` 含 `.dex` → 置信度 `high`（DEX 字节码级匹配，最可靠）。

## 🧠 `unknown_compiler` 的意义

```yarga
rule unknown_compiler : compiler {
  condition:
    is_dex
    and not (dexlib1 or dexlib2 or ... or jack_* or dx or r8 or dexmerge)
}
```

这是个"兜底"规则——是 dex 但不属于任何已知编译器。命中它说明出现了 **新编译器或异常产物**，提示你去 [GitHub 提 issue](https://github.com/rednaga/APKiD/issues) 补规则。meta 描述原话："unknown (please file detection issue!)"。

## 📜 R8 marker 的小秘密

R8 会在 dex 里留一个隐藏 marker（`~~D8{"compilation-mode":"...}`），记录编译模式。开发者可以删掉它，但 **删 marker 容易，改 map 顺序难**——所以 `r8_no_marker` 规则靠 map 顺序仍能抓住删了 marker 的 r8 产物，并标记为"suspicious"。

## 📍 相关

- [DEX 编译器规则](./dex-compilers) — 完整规则清单与源码。
- [编写 YARA 规则](./writing-rules) — DEX 模块用法。
- [obfuscator 类别](./category-obfuscator) — 编译器 vs 混淆器。
- [工作原理](../guide/how-it-works) — yara-python-dex 依赖。
- [Android Compiler Fingerprinting (HITCON 2016)](http://hitcon.org/2016/CMT/slide/day1-r0-e-1.pdf)
