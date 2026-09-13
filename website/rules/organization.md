# 规则文件组织

<span class="badge badge-info">目录结构</span>
<span class="badge badge-info">命名</span>

APKiD 的规则用"**文件类型 × 检测类别**"二维组织。本文讲清楚目录与命名约定。

## 📂 目录结构

```
apkid/rules/
├── apk/                          # APK（ZIP 容器）层规则
│   ├── common.yara               #   is_apk 等 file_type + internal
│   ├── packers.yara              #   75 条加固检测
│   ├── protectors.yara           #   20 条保护 SDK
│   └── obfuscators.yara          #   5 条混淆
├── dex/                          # DEX 字节码规则
│   ├── common.yara               #   is_dex + yara_issue
│   ├── compilers.yara            #   15 条编译器（用 dex 模块）
│   ├── packers.yara              #   29 条加固（dex 层）
│   ├── protectors.yara           #   31 条保护器
│   ├── obfuscators.yara          #   22 条混淆
│   ├── anti-vm.yara              #   28 条反虚拟机
│   └── abnormal.yara             #   6 条异常结构
├── elf/                          # 原生库/可执行文件规则
│   ├── common.yara               #   is_elf, is_dart
│   ├── packers.yara              #   44 条（含 UPX 全版本）
│   ├── protectors.yara           #   33 条
│   ├── obfuscators.yara          #   46 条（OLLVM 全版本）
│   └── anti-vm.yara              #   1 条
├── dll/                          # Windows PE DLL
│   ├── common.yara               #   is_dll
│   └── obfuscators.yara          #   1 条（beebyte）
├── res/                          # 二进制资源（resources.arsc 等）
│   ├── common.yara               #   is_res
│   ├── obfuscators.yara          #   1 条
│   └── protectors.yara           #   1 条
└── rules.yarc                    # ★ 编译产物，gitignored
```

## 🏷️ 命名约定

### 文件名

`<类别>.yara`——复数形式（`packers`、`obfuscators`、`protectors`、`compilers`）。`common.yara` 放 file_type 和 internal 积木。`anti-vm.yara`、`abnormal.yara` 用单数（因为是一个概念）。

### 规则名

- **加固/保护器/混淆器**：用厂商或工具名，可加版本后缀。
  - `bangcle`、`jiagu_360_v5`、`ollvm_v9`、`upx_elf_3_92`
- **编译器**：工具名，版本用 `_v` 或末尾 `_数字_数字`。
  - `jack_4_12`、`dx`、`r8`、`dexlib2`
- **反虚拟机**：行为描述，`checks_` / `possible_` 前缀。
  - `checks_build_fingerprint`、`possible_vm_check`
- **异常结构**：`abnormal_` / `non_` / `illegal_` 前缀。
  - `abnormal_header_size`、`non_zero_link_size`、`illegal_class_names`
- **private 积木**：`<工具>_<特征>`，如 `dx_map_type_order`、`r8_marker`。

### tag

每条规则恰好一个主 tag（可多 tag，如 `upx_embedded_inside_elf : packer dropper`）。tag 必须是 `RULE_DESCRIPTIONS` 里已定义的类别。新 tag 要同步加进 [`ai_output.py`](../modules/ai-output)。

## 🔀 一个工具可能在多处有规则

同一个加固方案（如 360 加固）可能在不同文件类型下都有规则：

- `apk/packers.yara`：`jiagu_360_v5`（APK 层路径/资产文件特征）
- `dex/packers.yara`：`jiagu_360_dex`（dex 层特征）
- `elf/packers.yara`：`jiagu_native`（so 库特征）

因为扫描会递归 APK 内部，三类规则都会跑，从不同角度确认同一加固。

## 📋 各文件规则数

| 文件 | 规则数（含 private） |
|------|:---:|
| apk/common | 3 |
| apk/obfuscators | 5 |
| apk/packers | 75 |
| apk/protectors | 20 |
| dex/common | 3 |
| dex/compilers | 15 |
| dex/packers | 29 |
| dex/protectors | 31 |
| dex/obfuscators | 22 |
| dex/anti-vm | 28 |
| dex/abnormal | 6 |
| elf/common | 2 |
| elf/packers | 44 |
| elf/protectors | 33 |
| elf/obfuscators | 46 |
| elf/anti-vm | 1 |
| dll/common | 1 |
| dll/obfuscators | 1 |
| res/common | 1 |
| res/obfuscators | 1 |
| res/protectors | 1 |

## 📍 相关

- [编写 YARA 规则](./writing-rules) — 怎么加一条规则。
- [规则系统概览](./overview) — 全貌。
- [YARA 规则系统（指南）](../guide/yara-system) — 概念。
