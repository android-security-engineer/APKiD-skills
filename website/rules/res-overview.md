# RES 规则

<span class="badge badge-info">RES</span>
<span class="badge badge-info">file_type</span>
<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-protect">protector</span>
<span class="badge badge-info">3 条</span>

`res/` 目录检测 Android 二进制资源文件，主要是 `resources.arsc`（编译后的资源表，魔数 `02 00 0C 00`）。APKiD 在 APK 解包后会扫描这个文件，识别资源层的混淆与保护。

## 🎯 什么是 RES

`resources.arsc` 是 Android 资源编译器（aapt）把 `res/` 下的 XML 和值打包成的二进制资源表。它包含：

- 字符串池（资源 key、值）
- 资源 ID → 类型的映射
- 包配置（package name）

某些保护/混淆工具会直接修改 `resources.arsc`——加密资源值、注入保护标记、改写资源 ID。APKiD 的 RES 规则识别这些修改。

## 📂 子文件结构

`apkid/rules/res/` 共 3 个源文件、3 条规则：

| 文件 | 规则数 | 主类别 | 说明 |
|------|:---:|------|------|
| `common.yara` | 1 | file_type | `is_res` 判断文件是 `resources.arsc` |
| `obfuscators.yara` | 1 | obfuscator | `mtprotector_res` MT Protector |
| `protectors.yara` | 1 | protector | `bugsmirror` BugsMirror |

无 packers/anti-vm 文件——RES 层加固和保护场景极少。

## 📋 规则清单

| 规则 | tag | 文件 | 说明 |
|------|-----|------|------|
| `is_res` | file_type | `common.yara` | 判断文件是 `resources.arsc`（魔数 `02 00 0C 00`） |
| `mtprotector_res` | obfuscator | `obfuscators.yara` | MT Protector（`MT_Protector` 签名） |
| `bugsmirror` | protector | `protectors.yara` | BugsMirror（`Secured by Bugsmirror`/`secured_by_bugsmirror`） |

## 🔍 检测原理要点

### is_res：resources.arsc 魔数

```yara
rule is_res : file_type {
  meta:
    description = "RES"
  strings:
    $magic = { 02 00 0C 00 }   // RES_TABLE_TYPE 魔数
    $type1 = { 01 00 1C 00 }   // RES_STRING_POOL_TYPE
    $type2 = { 03 00 00 00 }   // RES_TABLE_PACKAGE_TYPE
    $type3 = { 00 02 00 00 }
  condition:
    $magic at 0 and 1 of ($type*)
}
```

`resources.arsc` 文件头前 4 字节是 `02 00 0C 00`（`RES_TABLE_TYPE`，type=0x0002，headerSize=0x000c）。规则要求魔数在偏移 0，并命中至少一个类型块特征，确保是合法的 arsc 而非碰巧同字节的数据。`is_res` 是 `mtprotector_res` 和 `bugsmirror` 的前置条件。

### mtprotector_res：MT Protector 签名

```yara
rule mtprotector_res : obfuscator {
  meta:
    description = "MT Protector"
    url = "https://mt2.cn/download/"
  strings:
    $sign = {
      0000 0c0c                         // 额外字节
      4d54 5f50 726f 7465 6374 6f72 00  // ..MT_Protector.
    }
  condition:
    is_res and all of them
}
```

[MT Protector](https://mt2.cn/download/) 是 MT 管理器配套的资源混淆工具，往 `resources.arsc` 注入 `MT_Protector` 签名并加密资源。规则匹配这个签名串，前置 `is_res` 防误报。

### bugsmirror：BugsMirror 保护标记

```yara
rule bugsmirror : protector {
  meta:
    description = "BugsMirror"
    url = "https://www.bugsmirror.com/"
  strings:
    $comment  = { 00 ?? ?? 53 65 63 75 72 65 64 20 62 79 20
                  42 75 67 73 6D 69 72 72 6F 72 00 }   // Secured by Bugsmirror
    $comment2 = { ?? 73 65 63 75 72 65 64 5F 62 79 5F 62 75
                  67 73 6D 69 72 72 6F 72 00 }          // secured_by_bugsmirror
  condition:
    is_res and any of them
}
```

[BugsMirror](https://www.bugsmirror.com/) 在受保护的 `resources.arsc` 里留下 `Secured by Bugsmirror` 或 `secured_by_bugsmirror` 标记。规则匹配两种变体之一即可。注意 `bugsmirror` 在 `elf/protectors.yara` 也有一条同名规则（识别 `libdefender.so` + `.crypted` 节区），两条从不同文件类型角度确认同一保护 SDK。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::mtprotector_res",
  "category": "obfuscator",
  "source": "app.apk!resources.arsc",
  "identifier": "mtprotector_res",
  "confidence": "medium"
}
```

`source` 是 `resources.arsc` → RES 层匹配。

## 📍 相关

- [file_type 类别](./category-file-type) — `is_res` 的归类
- [obfuscator 类别](./category-obfuscator) — `mtprotector_res` 的归类
- [protector 类别](./category-protector) — `bugsmirror` 的归类与 ELF 同名规则
- [ELF 保护器](./elf-protectors) — `bugsmirror` 的 ELF 版本（`libdefender.so` + `.crypted`）
- [规则文件组织](./organization) — RES 在目录结构中的位置
- [文件类型识别（指南）](../guide/file-types)
