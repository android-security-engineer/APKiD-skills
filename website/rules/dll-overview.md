# DLL 规则

<span class="badge badge-info">DLL</span>
<span class="badge badge-info">file_type</span>
<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-info">2 条</span>

`dll/` 目录检测 Windows PE DLL。DLL 是 PE 格式（MZ 魔数），在 Android 场景较少见——但某些跨平台 SDK、游戏引擎或混合开发框架会把 Windows DLL 一起打包进来，APKiD 仍会扫描它们。

## 🎯 为什么 Android 里会有 DLL

典型出现 DLL 的场景：

- **跨平台游戏引擎**：Unity、Unreal 的某些插件含 Windows DLL。
- **跨平台 SDK**：部分金融/DRM SDK 同时提供 Windows 实现。
- **混合开发框架**：某些桌面端移植的应用残留 DLL。
- **恶意样本**：少量跨平台恶意软件携带 Windows payload。

APKiD 递归扫描 APK 内所有文件，遇到 PE DLL 会跑 `dll/` 规则。

## 📂 子文件结构

`apkid/rules/dll/` 共 2 个源文件、2 条规则：

| 文件 | 规则数 | 主类别 | 说明 |
|------|:---:|------|------|
| `common.yara` | 1 | file_type | `is_dll` 判断文件是 PE DLL |
| `obfuscators.yara` | 1 | obfuscator | `beebyte` .NET 混淆器 |

无 packers/protectors/anti-vm 文件——DLL 在 Android 场景太少，不值得细分。

## 📋 规则清单

| 规则 | tag | 文件 | 说明 |
|------|-----|------|------|
| `is_dll` | file_type | `common.yara` | 判断文件是 PE DLL（`pe.DLL` 特征位） |
| `beebyte` | obfuscator | `obfuscators.yara` | Beebyte .NET 混淆器（`\x00Beebyte.Obfuscator\x00`） |

## 🔍 检测原理要点

### is_dll：YARA pe 模块

```yara
import "pe"

rule is_dll : file_type {
  meta:
    description = "DLL"
  condition:
    pe.characteristics and pe.DLL
}
```

`pe.DLL` 是 PE 头 `Characteristics` 字段里的 `IMAGE_FILE_HEADER_DLL`（0x2000）位，区分 DLL（`ET_DYN` 等价）与 EXE。`pe.characteristics and pe.DLL` 确保文件是合法 PE 且特征位指示为 DLL。

### beebyte：.NET 混淆器出现在 DLL 说明什么

```yara
rule beebyte : obfuscator {
  meta:
    description = "Beebyte"
    url = "https://www.beebyte.co.uk/"
  strings:
    $name = "\x00Beebyte.Obfuscator\x00"
  condition:
    is_dll and all of them
}
```

[Beebyte](https://www.beebyte.co.uk/) 是 Unity 生态常用的 .NET 混淆器，混淆 C# 程序集。它出现在 DLL 里，通常说明这是 Unity 游戏的托管程序集（`.dll`）——Unity 把 C# 脚本编译成 .NET DLL，再用 Beebyte 混淆。这是跨平台样本的强信号：原生 Android 应用不会出现 .NET 混淆器。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::beebyte",
  "category": "obfuscator",
  "source": "app.apk!assets/Managed/Assembly-CSharp.dll",
  "identifier": "beebyte",
  "confidence": "medium"
}
```

`source` 含 `Managed/*.dll` 是 Unity 托管程序集的典型路径。

## 📍 相关

- [file_type 类别](./category-file-type) — `is_dll` 的归类
- [obfuscator 类别](./category-obfuscator) — Beebyte 的归类与其它混淆器
- [规则文件组织](./organization) — DLL 在目录结构中的位置
- [文件类型识别（指南）](../guide/file-types)
