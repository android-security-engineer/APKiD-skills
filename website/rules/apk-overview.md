# APK 规则总览

<span class="badge badge-file">APK</span>
<span class="badge badge-pack">packer</span>
<span class="badge badge-protect">protector</span>
<span class="badge badge-obfus">obfuscator</span>

APK 是 Android 应用的分发载体——本质是个 **ZIP 容器**，里面装着 `classes.dex`、`AndroidManifest.xml`、`lib/*/` 原生库、`assets/` 资产文件等。APKiD 的 APK 层规则不深入字节码，而是匹配 **外层 ZIP 条目路径** 和 **资产文件名特征**（如 `assets/libjiagu.so`、`lib/armeabi-v7a/libSecShell.so`），从壳代码留下的"文件足迹"识别加固/保护方案。

## 🎯 为什么 APK 层要单独一套规则

加固方案会把真实 dex 加密藏进 `assets/`，用自研的 so 库在运行时解密还原。这些 so 库和资产文件有 **固定的命名约定**——360 加固一定有 `libjiagu.so`，梆梆 SecShell 一定有 `libSecShell.so`。APK 层规则直接匹配这些路径字符串，**无需解压、无需解析 dex**，扫描最快。

但路径匹配有局限：厂商改名或混淆路径就失效。所以同一方案常在 DEX 层和 ELF 层也有规则，从字节码结构和 so 符号两个角度交叉确认。详见 [DEX 规则总览](./dex-overview) 和 [组织方式](./organization)。

## 📂 子文件清单

`apkid/rules/apk/` 下共 4 个 YARA 文件，101 条公开规则 + 3 条 private 积木（合计 104）：

| 子文件 | 类别 | 规则数 | 文档 |
|--------|------|:---:|------|
| `common.yara` | file_type + internal | 3 | [APK common](./apk-common) |
| `packers.yara` | packer | 75 | [APK 加固](./apk-packers) |
| `protectors.yara` | protector + manipulator | 20 | [APK 保护器](./apk-protectors) |
| `obfuscators.yara` | obfuscator | 5 | [APK 混淆器](./apk-obfuscators) |

## 🔍 APK 层规则长什么样

以 360 加固 v5 为例——只看 `lib/` 下的 so 库文件名：

```yara
rule jiagu_360_v5 : packer {
  strings:
    $lib64 = /lib\/(arm64.*)\/libjiagu(_so)?_64\.so/
    $lib32 = /lib\/(armeabi.*)\/libjiagu(_so)?\.so/
  condition:
    is_apk and $lib64 and ($lib32 or $lib64) and not jiagu_a
}
```

`is_apk` 是 [common.yara](./apk-common) 里的前置条件——先确认这是个 APK（ZIP 头 + `AndroidManifest.xml`），再匹配壳特征。所有 APK 规则都带 `is_apk and ...`。

## 📊 检测置信度

APK 层路径匹配的 finding，`source` 形如 `app.apk!assets/libjiagu.so`，置信度 **`low`**——因为只看到资产文件名，没确认里面真的是壳代码。若同时在 `classes.dex` 命中 DEX 层规则（`source` 含 `.dex`），置信度升为 `high`。详见 [输出格式](../guide/output-format)。

## 🆚 APK 层 vs DEX 层

| 维度 | APK 层 | DEX 层 |
|------|--------|--------|
| 匹配对象 | ZIP 路径/资产文件名 | dex 字节码、string_pool、map_list |
| 速度 | 快（不解压只扫字符串） | 中（需解析 dex 结构） |
| 抗混淆 | 弱（改名即失效） | 强（结构特征难改） |
| 置信度 | low | high |

## 📍 相关

- [APK 加固](./apk-packers) · [APK 保护器](./apk-protectors) · [APK 混淆器](./apk-obfuscators) · [APK common](./apk-common)
- [文件类型](../guide/file-types) — APK/DEX/ELF 的概念
- [DEX 规则总览](./dex-overview) — 字节码层规则
- [packer 类别](./category-packer) · [protector 类别](./category-protector)
- [规则系统概览](./overview) — 全局视角
