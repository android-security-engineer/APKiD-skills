# DEX 反虚拟机规则

<span class="badge badge-anti">anti_vm</span>
<span class="badge badge-debug">anti_debug</span>
<span class="badge badge-anti">28 + 3 private</span>

`apkid/rules/dex/anti-vm.yara` — 28 条公开规则 + 3 条 private 积木。检测 **反虚拟机/反模拟器技术**——应用查询各种环境特征判断自己是否运行在沙箱/模拟器/QEMU 里。其中 `checks_debugger_present` 的 tag 是 `anti_debug`（反调试）。

## 🎯 检测原理

反虚拟机技术分几大类：

1. **Build 属性检测**：查 `Build.FINGERPRINT`/`MODEL`/`BRAND` 等是否匹配 "generic"/"sdk"/"google_sdk"/"goldfish" 等模拟器特征值。
2. **TelephonyManager 检测**：查 SIM 运营商、设备 ID、手机号是否为模拟器默认值（如 `000000000000000`、`155552155`）。
3. **文件系统检测**：查 `/sys/qemu_trace`、`/dev/qemu_pipe`、`/init.goldfish.rc` 等 QEMU 痕迹文件。
4. **系统属性检测**：查 `ro.hardware`、`ro.kernel.qemu`、`ro.secure` 等 `getprop` 值。
5. **调试检测**：`Debug.isDebuggerConnected()`。

APKiD 用 3 个 private 积木识别"调用了哪个查询类"（`Build`/`Debug`/`TelephonyManager`），再细分具体检测项。

## 📋 private 积木规则（3 条）

| 私有规则 | 说明 |
|---------|------|
| `uses_build_class` | References `android.os.Build` 类 — `Landroid/os/Build;` 类名引用 |
| `uses_debug_class` | References `android.os.Debug` 类 — `Landroid/os/Debug;` 类名引用 |
| `uses_telephony_class` | References `android.telephony.TelephonyManager` 类 — 类名引用 |

Build 系列检测都要求 `uses_build_class`，Telephony 系列要求 `uses_telephony_class`——先确认"引用了这个类"，再看具体检测字符串，降低误报。

## 📋 公开规则（28 条）

### 📱 Build 属性检测（12 条，anti_vm）

| 规则 | tag | 说明 |
|------|-----|------|
| `checks_build_fingerprint` | anti_vm | Build.FINGERPRINT check — 匹配 "generic"/"unknown"/"generic/sdk/generic" 等 |
| `checks_build_model` | anti_vm | Build.MODEL check — "google_sdk"/"sdk"/"Emulator"/"Android SDK built for x86" |
| `checks_build_manufacturer` | anti_vm | Build.MANUFACTURER check — "Genymotion"/"unknown" |
| `checks_build_brand` | anti_vm | Build.BRAND check — "generic" |
| `checks_build_device` | anti_vm | Build.DEVICE check — "generic" |
| `checks_build_product` | anti_vm | Build.PRODUCT check — "google_sdk"/"sdk" |
| `checks_build_hardware` | anti_vm | Build.HARDWARE check — "goldfish"/"ranchu"/"vbox86" |
| `checks_build_board` | anti_vm | Build.BOARD check — "unknown" |
| `checks_build_id` | anti_vm | Build.ID check — "FRF91" |
| `possible_build_serial_check` | anti_vm | possible Build.SERIAL check — 只查 SERIAL 字符串（无字面量） |
| `checks_build_tags` | anti_vm | Build.TAGS check — "test-keys" |
| `checks_build_user` | anti_vm | Build.USER check — "android-build" |

### 📞 TelephonyManager 检测（7 条，anti_vm）

| 规则 | tag | 说明 |
|------|-----|------|
| `checks_sim_operator` | anti_vm | SIM operator check — `getSimOperator` + "Android" |
| `checks_network_operator` | anti_vm | network operator name check — `getNetworkOperatorName` + "Android" |
| `checks_device_id` | anti_vm | device ID check — `getDeviceId` + `000000000000000` |
| `checks_line1_number` | anti_vm | line 1 number check — `getLine1Number` + `155552155` |
| `checks_voicemail_number` | anti_vm | voice mail number check — `getVoiceMailNumber` + `15552175049` |
| `checks_subscriber_id` | anti_vm | subscriber ID check — `getSubscriberId` + `0000000000` |
| `checks_network_interface_names` | anti_vm | network interface name check — `NetworkInterface.getName` + `eth0` |

### 🖥️ 文件/属性/QEMU 检测（8 条，anti_vm）

| 规则 | tag | 说明 |
|------|-----|------|
| `checks_cpuinfo` | anti_vm | `/proc/cpuinfo` check — 文件路径 + "Goldfish" |
| `checks_build_type` | anti_vm | `ro.build.type` check — 属性 + "user" |
| `checks_hardware` | anti_vm | `ro.hardware` check — "goldfish"/"ranchu" |
| `checks_product_device` | anti_vm | `ro.product.device` check — "generic" |
| `checks_kernel_qemu` | anti_vm | `ro.kernel.qemu` check — 只查属性字符串 |
| `possible_ro_secure_check` | anti_vm | possible `ro.secure` check — 只查属性字符串 |
| `checks_qemu_file` | anti_vm | emulator file check — `/init.goldfish.rc`/`/sys/qemu_trace`/`/dev/qemu_pipe` 等 9 个路径 |
| `possible_vm_check` | anti_vm | possible VM check — `isEmulator` 方法名 |

### 🐛 反调试（1 条，anti_debug）

| 规则 | tag | 说明 |
|------|-----|------|
| `checks_debugger_present` | anti_debug | `Debug.isDebuggerConnected()` check — `Debug` + `isDebuggerConnected` 字符串 |

注意 `checks_debugger_present` 的 tag 是 **`anti_debug`**，因为反调试属于独立类别。详见 [anti-debug 类别](./category-anti-debug)。

## 🔍 规则源码示例

### `checks_build_fingerprint` — Build 属性 + 模拟器特征值

```yara
rule checks_build_fingerprint : anti_vm {
  strings:
    $prop = {00 0B 46 49 4E 47 45 52 50 52 49 4E 54 00}  // FINGERPRINT
    $str_1 = {00 07 67 65 6E 65 72 69 63 00 0A}            // generic
    $str_2 = {00 07 75 6E 6B 6E 6F 77 6E 00}              // unknown
    $str_3 = "generic/sdk/generic"
    $str_4 = "generic/generic/generic"
    $str_5 = "generic/google_sdk/generic"
    $str_6 = "generic_x86/sdk_x86/generic_x86"
    $str_7 = "Android/full_x86/generic_x86"
    $str_8 = "generic/vbox86p/vbox86p"
  condition:
    uses_build_class and $prop and 1 of ($str_*)
}
```

逻辑：引用了 `Build` 类 + 出现 `FINGERPRINT` 字符串 + 出现至少 1 个模拟器特征值（如 "generic/sdk/generic"）→ 判定做了 FINGERPRINT 反虚拟机检测。`$str_*` 是常见模拟器的 fingerprint 值。

### `checks_qemu_file` — QEMU 痕迹文件

```yara
rule checks_qemu_file : anti_vm {
  strings:
    $a = "/init.goldfish.rc"
    $b = "/sys/qemu_trace"
    $c = "/system/bin/qemud"
    $d = "/system/bin/qemu-props"
    $e = "/system/lib/libc_malloc_debug_qemu.so"
    $f = "/dev/qemu_pipe"
    $g = "/dev/socket/qemud"
    $h = "/dev/socket/genyd"             // Geny 检测
    $i = "/dev/socket/baseband_genyd"
  condition:
    is_dex and 1 of them
}
```

模拟器（尤其 QEMU/Genymotion）会在文件系统留下这些特殊文件。命中 1 个即判定。

### `checks_debugger_present` — 反调试

```yara
rule checks_debugger_present : anti_debug {
  strings:
    $debug = "Debug"
    $debugger_connected = "isDebuggerConnected"
  condition:
    uses_debug_class and $debug and $debugger_connected
}
```

引用 `Debug` 类 + `isDebuggerConnected` 方法名 → 判定做了反调试检测。

## 📊 finding 示例

```json
{
  "tag": "anti_vm::checks_build_fingerprint",
  "category": "anti_vm",
  "source": "app.apk!classes.dex",
  "identifier": "checks_build_fingerprint",
  "confidence": "high"
}
```

## 🧠 反虚拟机不等于恶意

很多正规金融/DRM/游戏应用也做反虚拟机检测（防在模拟器上跑挂机/作弊）。APKiD 只标"有这个检测"，是否恶意要看上下文。`possible_*` 前缀的规则（`possible_build_serial_check`、`possible_ro_secure_check`、`possible_vm_check`）是弱信号——只查了属性/方法名字符串，没确认对比值，可能是误报。

## 📍 相关

- [anti_vm 类别](./category-anti-vm) — 反虚拟机概念与全文件类型分布
- [anti-debug 类别](./category-anti-debug) — `checks_debugger_present` 的 tag 归属
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [DEX 保护器](./dex-protectors) — 部分保护器 SDK 含反 root/反调试
- [ELF 反虚拟机](./elf-anti-vm) — 原生层反虚拟机（1 条）
- [规则文件组织](./organization) — `checks_`/`possible_` 命名约定
