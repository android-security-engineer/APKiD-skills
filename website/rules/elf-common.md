# ELF 通用 (common)

<span class="badge badge-info">file_type</span>
<span class="badge badge-info">ELF</span>
<span class="badge badge-info">2 条</span>

`elf/common.yara` 定义 ELF 规则的前置条件与文件类型识别。它只有两条规则，但 **所有 ELF packer/protector/obfuscator/anti-vm 规则都以 `is_elf` 为前置条件**，是 ELF 规则体系的基石。

## 🎯 common 的职责

`common.yara` 不做具体检测，而是提供两类"积木"：

1. **file_type 规则**：判断被扫描文件是不是 ELF，输出文件类型信息。
2. **被引用的前置条件**：`is_elf` 被其它规则 `include` 后作为 condition 起点。

## 📋 规则清单

| 规则 | tag | 说明 |
|------|-----|------|
| `is_elf` | file_type | 判断文件是 ELF（用 `elf` 模块的 `number_of_sections >= 0`） |
| `is_dart` | file_type | 判断文件是 Dart AOT 快照（Flutter 的 `libapp.so`） |

## 🔍 检测原理要点

### is_elf：YARA elf 模块的前置条件

```yara
import "elf"

rule is_elf : file_type {
  meta:
    description = "ELF"
  condition:
    elf.number_of_sections >= 0
}
```

`elf.number_of_sections >= 0` 看似恒真，实则是 YARA `elf` 模块的"文件能被解析为 ELF"检查——非 ELF 文件会让 `elf` 模块字段返回默认值 0 或无法访问，规则不触发。它依赖 [yara-python-dex](https://github.com/rednaga/yara-dex-module) 提供的 `elf` 模块。

几乎所有 ELF 规则的 condition 都以 `is_elf and ...` 开头：

```yara
rule jiagu_native : packer {
  condition:
    is_elf and ($a and $b and $c) and any of ($d, $e, $f, $g)
}
```

### is_dart：识别 Flutter 的 libapp.so

Flutter 应用把 Dart 代码编译成 AOT 快照，存在 `lib/<abi>/libapp.so`，本质是 ELF。`is_dart` 用 Dart 运行时的特征字符串识别：

```yara
rule is_dart : file_type {
  strings:
    $s1   = "dart:core" ascii
    $s2   = "dart:async" ascii
    $s3   = "_kDartVmSnapshotData" ascii
    $s4   = "_kDartVmSnapshotInstructions" ascii
    $s5   = "flutter_assets" ascii
    $ksnl = { 4B 53 4E 4C }   // "KSNL" 魔数
  condition:
    is_elf and 2 of ($s*) or $ksnl
}
```

- `dart:core`/`dart:async`：Dart 核心库路径。
- `_kDartVmSnapshot*`：Flutter 引擎加载 AOT 快照的导出符号。
- `flutter_assets`：Flutter 资源目录名。
- `KSNL`（`4B 53 4E 4C`）：Dart VM 快照的"Kernel Snapshot"魔数。

`is_dart` 是 `free_rasp_dart`（FreeRASP for Flutter）规则的入口——只有先确认是 Dart AOT 快照，才会去匹配 FreeRASP 的 Dart 路径串。

## 📊 finding 示例

```json
{
  "tag": "file_type::is_elf",
  "category": "file_type",
  "description": "Detects file type information",
  "source": "app.apk!lib/arm64-v8a/libfoo.so",
  "identifier": "is_elf",
  "confidence": "high"
}
```

`is_elf`/`is_dart` 默认在标准扫描中输出（带 `include_types: true` 时），用于标注被扫描的每个 `.so` 的文件类型。

## 📍 相关

- [file_type 类别](./category-file-type) — 文件类型识别概念
- [ELF 规则总览](./elf-overview) — `is_elf` 是所有 ELF 规则的前置
- [ELF 保护器](./elf-protectors) — `free_rasp_dart` 依赖 `is_dart`
- [规则文件组织](./organization) — common.yara 的定位
- [文件类型识别（指南）](../guide/file-types)
