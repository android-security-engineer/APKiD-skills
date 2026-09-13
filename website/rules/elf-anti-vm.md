# ELF 反虚拟机 (anti-vm)

<span class="badge badge-anti">anti_vm</span>
<span class="badge badge-info">ELF</span>
<span class="badge badge-info">1 条</span>

`elf/anti-vm.yara` 只有一条规则，专门在原生层检测 QEMU 模拟器的熵特征。与 `dex/anti-vm.yara`（28 条，查 `Build.FINGERPRINT`、SIM、`/proc/cpuinfo` 等 Java 层特征）形成互补。

## 🎯 原生层反虚拟机

DEX 层的反 VM 检测查的是 Android Framework API（`Build.*`、`TelephonyManager`），而 ELF 层的反 VM 直接在原生代码里检测 QEMU 的行为痕迹——通常通过 QEMU 翻译块缓存的熵异常、特定全局变量命名等低层特征识别。

这条规则源自 [Fuzion24/AndroidHostileEnvironmentDetection](https://github.com/Fuzion24/AndroidHostileEnvironmentDetection) 的 `emudetect.c`，该工具用 QEMU 在某些全局变量行为上的熵差异判断是否运行在 QEMU 翻译模式下。

## 📋 规则清单

| 规则 | tag | 说明 |
|------|-----|------|
| `check_qemu_entropy` | anti_vm | 原生库检测 QEMU 熵特征 |

## 🔍 检测原理要点

规则匹配两个特征字符串，命中其一即可：

```yara
rule check_qemu_entropy : anti_vm {
  meta:
    description = "Checks for QEMU entropy"
    url = "https://github.com/Fuzion24/AndroidHostileEnvironmentDetection/blob/master/app/jni/emudetect.c"
  strings:
    $a = "atomicallyIncreasingGlobalVarThread"
    $b = "_qemuFingerPrint"
  condition:
    is_elf and any of them
}
```

- `atomicallyIncreasingGlobalVarThread`：emudetect 用来测 QEMU 线程调度熵的原子递增全局变量。
- `_qemuFingerPrint`：QEMU 指纹检测函数名。

这两个符号是 emudetect 工具的内部命名，被原生库引用即说明该库集成了 QEMU 熵检测逻辑。前置条件 `is_elf` 确保只对原生库触发。

## 🆚 与 dex/anti-vm 的区别

| 维度 | `elf/anti-vm.yara` | `dex/anti-vm.yara` |
|------|------|------|
| 规则数 | 1 | 28 |
| 检测层 | 原生（so 库） | Java/DEX 字节码 |
| 检测对象 | QEMU 熵特征（低层） | `Build.*`、SIM、`/proc` 文件（API 层） |
| 典型规则 | `check_qemu_entropy` | `checks_build_fingerprint`、`checks_kernel_qemu` |
| 来源 | emudetect 工具符号 | Android Framework API 调用 |

DEX 层规则查"调用了哪个查询类"，ELF 层规则查"是否集成了 emudetect 这类原生检测工具"。两者从不同角度覆盖反 VM 技术。

## 📊 finding 示例

```json
{
  "tag": "anti_vm::check_qemu_entropy",
  "category": "anti_vm",
  "description": "Detects anti-VM/anti-emulator techniques",
  "source": "app.apk!lib/armeabi-v7a/libfoo.so",
  "identifier": "check_qemu_entropy",
  "confidence": "medium"
}
```

::: warning 是"检测了什么"，不是"是不是恶意"
命中此规则只说明原生库 **集成了 QEMU 熵检测**，不一定是恶意——合法应用（如反作弊游戏、银行 SDK）也做模拟器检测。需结合上下文判断。
:::

## 📍 相关

- [anti_vm 类别](./category-anti-vm) — 概念与 DEX 层规则全览
- [DEX 反虚拟机规则](./dex-anti-vm) — 28 条 Java 层规则
- [ELF 规则总览](./elf-overview) · [ELF 通用 (common)](./elf-common)
- [文件类型识别（指南）](../guide/file-types)
