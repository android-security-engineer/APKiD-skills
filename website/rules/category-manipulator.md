# 类别：manipulator 篡改器

<span class="badge badge-neutral">manipulator</span>

`manipulator` 类别检测 **APK 篡改/操纵工具**——对已编译的 dex/apk 做二次处理的工具，既非编译器也非加固。

## 📋 规则分布

`manipulator` tag 的规则：

| 规则 | 文件 | 检测 |
|------|------|------|
| `dexmerge` | dex/compilers.yara | Android dexmerge 工具合并的 dex |
| `andres` | apk/protectors.yara | [AndresGuard](https://github.com/chenenyu/AndResGuard) 资源混淆 |

注意 `dexmerge` 物理上在 `compilers.yara`，但 tag 是 `manipulator`——因为 dexmerge 不是编译器，而是合并已编译 dex 的操纵工具。`_categorize_tag()` 按 tag 归类，所以它进 `manipulator` 而非 `compiler`。

## 🔍 dexmerge 检测

```yara
private rule dexmerge_map_type_order : internal {
  condition:
    dex.map_list.map_item[7].type == 0x1000  // TYPE_MAP_LIST 出现在第 7 位
}

rule dexmerge : manipulator {
  condition:
    dexmerge_map_type_order
}
```

dexmerge 把多个 dex 合并时，map_list 的类型顺序有独特特征（`TYPE_MAP_LIST` 出现在非常规位置）。详见 [DEX 编译器](./dex-compilers) 里 `dx_merged`/`r8_merged` 的对比——它们也用 `dexmerge_map_type_order` 但额外带编译器特征。

## 📊 finding 示例

```json
{
  "tag": "manipulator::dexmerge",
  "category": "manipulator",
  "description": "Detects APK manipulation tools",
  "source": "app.apk!classes.dex",
  "identifier": "dexmerge",
  "confidence": "high"
}
```

## 🆚 与 compiler / packer 的区别

- **compiler**：从源码生成 dex（dx、r8）。
- **manipulator**：对已生成的 dex 做后续操纵（dexmerge 合并、AndresGuard 混资源）。
- **packer**：加密重打包整个 dex。

`dx_merged` 同时是 compiler（dx 编译）+ manipulator（dexmerge 合并）特征，APKiD 用 `dx_merged` 规则抓这种"编译后又合并"的产物。

## 📍 相关

- [DEX 编译器](./dex-compilers) — `dexmerge` 与 `dx_merged`/`r8_merged` 的关系。
- [compiler 类别](./category-compiler) — 区别。
- [packer 类别](./category-packer) — 区别。
- [检测类别](../guide/categories)
