# 规则系统概览

<span class="badge badge-info">YARA</span>
<span class="badge badge-info">规则</span>

APKiD 的全部识别能力来自 YARA 规则。本文是规则系统的总入口。

## 📊 规模一览

| 维度 | 数量 |
|------|:---:|
| 源 `.yara` 文件 | 21 |
| 规则总数（含 private） | 365+ |
| 文件类型目录 | 6（apk/dex/elf/dll/res + 编译产物） |
| 检测类别 | 20 |

## 📂 按文件类型组织

规则在 `apkid/rules/` 下按 **被扫描文件的类型** 分目录：

| 目录 | 文件类型 | 规则文件 |
|------|---------|---------|
| `apk/` | APK（ZIP） | common, packers, protectors, obfuscators |
| `dex/` | Dalvik 字节码 | common, compilers, packers, protectors, obfuscators, anti-vm, abnormal |
| `elf/` | 原生库/可执行文件 | common, packers, protectors, obfuscators, anti-vm |
| `dll/` | Windows PE DLL | common, obfuscators |
| `res/` | 二进制资源 | common, obfuscators, protectors |

每个目录下再按 **检测类别** 拆文件。详见 [规则文件组织](./organization)。

## 🏷️ 按检测类别

每个规则带一个 tag，决定它的 `category`。主要类别：

| 类别 | 图标 | 规模 | 说明 |
|------|:---:|:---:|------|
| [packer](./category-packer) | 🛡️ | 150+ | APK 加固/打包 |
| [protector](./category-protector) | 🏰 | 90+ | 保护 SDK（RASP） |
| [obfuscator](./category-obfuscator) | 🧩 | 75+ | 代码混淆 |
| [compiler](./category-compiler) | 🔧 | 15 | 编译器指纹 |
| [anti_vm](./category-anti-vm) | 🖥️ | 29+ | 反虚拟机 |
| [anti_debug](./category-anti-debug) | 🐛 | — | 反调试 |
| [anti_disassembly](./category-anti-disassembly) | 📐 | 4 | 反汇编 |
| [anti_root](./category-anti-root) | 🌱 | 5 | 反 Root |
| [abnormal](./category-abnormal) | ⚠️ | 3 | 异常结构 |
| [dropper](./category-dropper) | 📦 | 2+ | 释放器 |
| [manipulator](./category-manipulator) | ✂️ | 3 | 篡改器 |
| [file_type](./category-file-type) | 📄 | 6 | 文件类型 |

详见各类别子页（侧边栏"检测类别"组）。

## 🧩 private 规则

带 `private` 的规则 **不输出**，只被其它规则引用。APKiD 用它封装可复用的结构指纹（如 `dx_map_type_order`、`r8_marker`）。带 `internal` tag + `private`，确保不污染结果。

## 🔌 DEX 模块

APKiD 用 [yara-python-dex](https://github.com/rednaga/yara-dex-module)，带 `import "dex"` 模块。这让 DEX 规则能访问结构字段（`dex.map_list.map_item[i].type` 等），做结构级指纹。详见 [DEX 编译器](./dex-compilers)。

## 📦 编译产物：rules.yarc

源 `.yara` 编译成二进制 `rules.yarc`（gitignored），运行时只 `yara.load()` 它。详见 [编译与发布](./compilation)。

## 📚 文档导览

- **总览类**：[文件组织](./organization) · [编写规则](./writing-rules) · [编译发布](./compilation)
- **类别详解**：侧边栏"检测类别"组的 12+ 篇
- **按文件类型**：侧边栏"APK/DEX/ELF/DLL/RES 规则"组

## 📍 相关

- [YARA 规则系统（指南）](../guide/yara-system) — 概念性介绍。
- [rules.py](../modules/rules) — RulesManager 源码。
- [编写 YARA 规则](./writing-rules) — 加一条新规则。
