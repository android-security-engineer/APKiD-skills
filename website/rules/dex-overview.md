# DEX 规则总览

<span class="badge badge-file">DEX</span>
<span class="badge badge-compiler">compiler</span>
<span class="badge badge-pack">packer</span>
<span class="badge badge-protect">protector</span>
<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-anti">anti_vm</span>
<span class="badge badge-abnormal">abnormal</span>

DEX 是 Dalvik 字节码的容器格式（`dex\n035` 魔数开头）。APKiD 的 DEX 层规则是 **最丰富、最精巧** 的一类——用 [yara-python-dex](https://github.com/rednaga/yara-dex-module) 的 `dex` 模块直接解析 DEX 结构（`map_list`、`string_ids`、`class_defs`、`header`），做字节码级结构指纹。这是 APKiD 检测的"重头戏"。

## 🎯 为什么 DEX 层规则最多

DEX 文件结构丰富——`map_list` 的类型排列顺序、`string_pool` 的排序、`header` 的字段值、`class_defs` 的 `interfaces_offset`……每个编译器/加固/混淆工具都会留下独特的结构足迹。相比 APK 层只看路径字符串，DEX 层能做更细粒度、抗混淆能力更强的检测：

- **编译器**：`map_list` 类型顺序指纹（dx vs r8 vs dexlib2 各不同）
- **加固**：壳注入的 stub 类名（如 `Lcom/stub/StubApp;`）
- **混淆器**：Unicode 字段名、字符串加密 opcode 序列
- **反虚拟机**：`Build.FINGERPRINT` 等环境检测字符串
- **异常结构**：`header_size`、`link_size` 等字段异常值

## 📂 子文件清单

`apkid/rules/dex/` 下共 8 个 YARA 文件，133 条公开规则 + 17 条 private 积木（合计 150）：

| 子文件 | 类别 | 规则数 | 文档 |
|--------|------|:---:|------|
| `common.yara` | file_type + yara_issue | 3 | [DEX common](./dex-common) |
| `compilers.yara` | compiler | 15 + 11 private | [DEX 编译器](./dex-compilers) |
| `packers.yara` | packer | 29 | [DEX 加固](./dex-packers) |
| `protectors.yara` | protector + anti_root | 31 | [DEX 保护器](./dex-protectors) |
| `obfuscators.yara` | obfuscator | 22 + 2 private | [DEX 混淆器](./dex-obfuscators) |
| `anti-vm.yara` | anti_vm + anti_debug | 28 + 3 private | [DEX 反虚拟机](./dex-anti-vm) |
| `abnormal.yara` | abnormal + anti_disassembly + dropper | 6 | [DEX 异常结构](./dex-abnormal) |

## 🔍 DEX 层规则长什么样

以 R8 编译器为例——靠 `map_list` 类型顺序 + 隐藏 marker：

```yara
rule r8 : compiler {
  condition:
    r8_marker                                    // ~~D8{"compilation-mode":...
    and (r8_map_type_order or ambiguous_tiny_dex_map_type_order)
}
```

`r8_marker` 和 `r8_map_type_order` 都是 private 积木规则，读取 `dex.map_list.map_item[N].type` 字段做判定。详见 [DEX 编译器](./dex-compilers)。

## 📊 检测置信度

DEX 层规则的 finding，`source` 形如 `app.apk!classes.dex`，置信度 **`high`**——字节码级结构匹配，最可靠。相比之下 APK 层路径匹配是 `low`。两者同时命中同一方案时，取 high。详见 [输出格式](../guide/output-format)。

## 🧠 dex 模块是关键依赖

DEX 层规则依赖 [yara-python-dex](https://github.com/rednaga/yara-dex-module)——一个自定义 YARA 模块，暴露 `dex.header.*`、`dex.map_list.*`、`dex.string_ids[]`、`dex.class_defs[]`、`dex.field[]`、`dex.method[]` 等字段。没有它，DEX 层规则全部失效（会触发 [`yara_undetected_dex`](./dex-common) 诊断信号）。安装见 [YARA 规则系统](../guide/yara-system)。

## 🆚 DEX 层 vs APK 层

| 维度 | DEX 层 | APK 层 |
|------|--------|--------|
| 匹配对象 | dex 字节码结构、string_pool | ZIP 路径/资产文件名 |
| 依赖 | yara-python-dex 模块 | 无（纯字符串） |
| 抗混淆 | 强（结构特征难改） | 弱（改名即失效） |
| 置信度 | high | low |
| 规则数 | 133 + 17 private | 101 + 3 private |

## 📍 相关

- [DEX 编译器](./dex-compilers) · [DEX 加固](./dex-packers) · [DEX 保护器](./dex-protectors) · [DEX 混淆器](./dex-obfuscators)
- [DEX 反虚拟机](./dex-anti-vm) · [DEX 异常结构](./dex-abnormal) · [DEX common](./dex-common)
- [YARA 规则系统（指南）](../guide/yara-system) — yara-python-dex 依赖
- [APK 规则总览](./apk-overview) — 对照 APK 层
- [规则系统概览](./overview) — 全局视角
