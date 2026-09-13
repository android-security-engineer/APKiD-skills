# YARA 规则系统

<span class="badge badge-info">YARA</span>
<span class="badge badge-info">规则</span>

APKiD 的"识别能力"全部来自 YARA 规则。引擎只是个跑规则的运行器。本文讲规则系统的全貌。

## 🧱 规则的三要素

每条 APKiD 规则是一个 YARA rule，包含：

```yara
rule bangcle : packer              // ① 规则名 + tag（决定 category）
{
  meta:
    description = "Bangcle (梆梆)"  // ② 元信息，写进 rule_detail
    sample = "b6a92aec..."          //    可选：已知样本哈希

  strings:
    $lib = "libDexHelper.so"        // ③ 指纹特征（字符串/十六进制/正则）

  condition:
    is_apk and $lib                 // ④ 匹配条件
}
```

- **tag** → 决定 finding 的 `category`（如 `packer`、`compiler`）。详见 [检测类别](./categories)。
- **meta.description** → 写进 finding 的 `rule_detail`，是人类可读的说明。
- **strings** → 指纹。可以是 ASCII 字符串、`{ hex }` 字节序列、`/regex/` 正则。
- **condition** → 通常以 `is_apk`/`is_dex`/`is_elf` 这类 file_type 规则作前置条件，限定只在该类文件里匹配。

## 📂 规则文件组织

源规则在 `apkid/rules/`，**按文件类型分子目录**：

```
apkid/rules/
├── apk/    common, packers, protectors, obfuscators
├── dex/    common, compilers, packers, protectors, obfuscators, anti-vm, abnormal
├── elf/    common, packers, protectors, obfuscators, anti-vm
├── dll/    common, obfuscators
└── res/    common, obfuscators, protectors
```

每个子目录下再按 **类别** 拆文件（`packers.yara`、`compilers.yara`…）。这种"类型 × 类别"的二维组织让定位某条规则很容易。

详见 [规则文件组织](../rules/organization)。

## 🔌 DEX 模块：结构级指纹

APKiD 用的是 [yara-python-dex](https://github.com/rednaga/yara-dex-module)，带 `import "dex"` 模块。这让规则能访问 DEX 的结构字段，做 **结构级指纹**——比纯字符串匹配更难伪造：

```yara
import "dex"

private rule dx_map_type_order : internal {
  condition:
    // dx 编译器把 map_list 类型按特定顺序排列
    dex.map_list.map_item[7].type == 0x2001  // TYPE_CODE_ITEM
    and dex.map_list.map_item[8].type == 0x1001  // TYPE_TYPE_LIST
    or ...
}
```

正是靠 `map_list` 的类型排列顺序，APKiD 能区分 `dx`、`r8`、`dexlib2`、`dexmerge` 这几个编译器——它们生成的顺序各有差异。详见 [编译器指纹](../rules/dex-compilers)。

## 🏗️ 编译与加载

源 `.yara` 需编译成二进制 `rules.yarc` 才能高效加载。[`RulesManager`](../modules/rules) 管理这个过程：

```
源 .yara 文件（21 个）
     │
     │  RulesManager.compile()  → yara.compile(filepaths=...)
     ▼
yara.Rules 对象
     │
     │  RulesManager.save()     → rules.save('rules.yarc')
     ▼
apkid/rules/rules.yarc   ← gitignored，发布产物
     │
     │  RulesManager.load()    → yara.load('rules.yarc')
     ▼
运行时 yara.Rules（毫秒级加载）
```

编译时机：
- **开发时**：`python prep-release.py` 或 `apkid-ai-cli rules compile`。
- **打包时**：CI/发布流程调 `prep-release.py`，`rules.yarc` 随包分发。
- **运行时**：只 `load()`，不 `compile()`——加载比编译快得多。

::: tip 规则哈希
`RulesManager.hash` 对所有源 `.yara` 文件算 SHA-256，作为规则集指纹。每次扫描输出都会带 `rules_sha256`，让你能溯源"这次扫描用的是哪一版规则"。
:::

## 🧩 private 规则：可复用的积木

带 `private` 修饰的规则 **不作为结果输出**，只被其它规则引用。APKiD 大量用它封装结构指纹：

```yara
private rule r8_marker : internal { ... }       // R8 的隐藏标记
private rule r8_map_type_order : internal { ... } // R8 的 map 顺序

rule r8 : compiler {
  condition: r8_marker and (r8_map_type_order or ambiguous_tiny_dex_map_type_order)
}
```

这让规则能组合复用，避免重复。`internal` tag 加上 `private`，确保这些积木不会污染最终输出。

## 📈 规则规模

- **365+** 条规则（含 private）。
- 覆盖 **5 种文件类型**（APK/DEX/ELF/DLL/RES）。
- 跨 **20 个检测类别**。

每个文件类型、每个类别的规则清单，见 [检测规则](../rules/overview) 的子页面。

## 📍 下一步

- [规则文件组织](../rules/organization) — 目录与命名约定。
- [编写 YARA 规则](../rules/writing-rules) — 加一条新规则。
- [编译与发布](../rules/compilation) — rules.yarc 怎么来。
- [代码模块：rules.py](../modules/rules) — RulesManager 源码。
