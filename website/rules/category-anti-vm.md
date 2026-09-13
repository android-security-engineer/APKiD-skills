# 类别：anti_vm 反虚拟机

<span class="badge badge-anti">anti_vm</span>

`anti_vm` 类别检测 **反虚拟机/反模拟器技术**——恶意软件用来判断自己是否运行在沙箱/模拟器里，若是则静默或伪装。

## 🎯 检测原理

恶意软件会查询一系列环境特征来判断"我是不是在虚拟机/模拟器里"：

- `Build.FINGERPRINT` / `Build.MODEL` / `Build.BRAND` → 匹配 "generic"、"sdk"、"google_sdk"
- `Build.HARDWARE` → "goldfish"、"ranchu"
- `TelephonyManager` → SIM 运营商、设备 ID、手机号
- `/proc/cpuinfo`、`/sys/qemu_trace`、`/proc/cpuinfo` → QEMU 痕迹
- `ro.secure` 属性

APKiD 的 `dex/anti-vm.yara` 用 private 规则识别"调用了哪个查询类"，再细分具体检测项。

## 📋 规则分布

| 文件类型 | 文件 | 规则数 | 子文档 |
|---------|------|:---:|------|
| DEX | `dex/anti-vm.yara` | 28 | [DEX 反虚拟机](./dex-anti-vm) |
| ELF | `elf/anti-vm.yara` | 1 | [ELF 反虚拟机](./elf-anti-vm) |

## 🛠️ 主要规则

### Build 指纹检测

| 规则 | 检测 |
|------|------|
| `checks_build_fingerprint` | `Build.FINGERPRINT` |
| `checks_build_model`/`manufacturer`/`brand`/`device`/`product`/`hardware`/`board`/`id`/`type`/`tags`/`user` | 各 Build 字段 |
| `checks_product_device` | `Build.PRODUCT`/`DEVICE` |
| `checks_hardware` | `Build.HARDWARE` |
| `possible_build_serial_check` | `Build.SERIAL` |

### SIM/电话检测

| 规则 | 检测 |
|------|------|
| `checks_sim_operator` | SIM 运营商（模拟器常为空/特定值） |
| `checks_network_operator` | 网络运营商 |
| `checks_device_id` | IMEI |
| `checks_line1_number` | 手机号 |
| `checks_voicemail_number` | 语音信箱号 |
| `checks_subscriber_id` | IMSI |

### QEMU/文件检测

| 规则 | 检测 |
|------|------|
| `checks_kernel_qemu` | 内核 QEMU 痕迹 |
| `checks_qemu_file` | `/sys/qemu_trace` 等文件 |
| `checks_cpuinfo` | `/proc/cpuinfo` |
| `checks_network_interface_names` | 网卡名（eth0 等） |
| `possible_ro_secure_check` | `ro.secure` 属性 |
| `possible_vm_check` | 通用 VM 检测 |

### private 积木

```yara
private rule uses_build_class : internal { ... }  // 引用了 android.os.Build
private rule uses_telephony_class : internal { ... }  // 引用了 TelephonyManager
```

### ELF 层

`check_qemu_entropy : anti_vm`——原生库检测 QEMU 的熵特征。

## 🔍 规则示例

```yara
rule checks_build_fingerprint : anti_vm {
  condition:
    uses_build_class and $fingerprint_method
}
```

## 📊 finding 示例

```json
{
  "tag": "anti_vm::checks_build_fingerprint",
  "category": "anti_vm",
  "description": "Detects anti-VM/anti-emulator techniques",
  "source": "app.apk!classes.dex",
  "identifier": "checks_build_fingerprint",
  "confidence": "high"
}
```

::: warning 这是"检测了什么"，不是"是不是恶意"
命中 `anti_vm` 规则只说明样本 **检测了** 这些环境特征，不等于它一定是恶意软件——合法应用也做模拟器检测（如反作弊游戏）。需结合上下文判断。
:::

## 📍 相关

- [DEX 反虚拟机规则](./dex-anti-vm) — 完整清单。
- [anti_debug](./category-anti-debug) · [anti_root](./category-anti-root) — 相关反分析。
- [检测类别](../guide/categories)
