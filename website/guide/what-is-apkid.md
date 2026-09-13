# APKiD 是什么

<span class="badge badge-info">Android</span>
<span class="badge badge-info">逆向分析</span>
<span class="badge badge-info">YARA</span>

APKiD 是一个 **Android 二进制识别工具**。它告诉你一个 APK（或 DEX、ELF、DLL）是 *怎么被制造出来的*——用了哪个编译器、是否经过加固（packer）、用了哪种混淆器（obfuscator）、是否被保护 SDK（protector）包裹、以及是否包含反虚拟机/反调试等对抗技术。

一句话概括：**它是 Android 世界的 [PEiD](https://www.aldeid.com/wiki/PEiD)**。

## 🎯 它回答什么问题

拿到一个陌生的 APK，你通常无法直接知道：

- 它是被 **360 加固** 还是 **腾讯乐固** 包裹的？
- 那个 `lib/armeabi-v7a/libfoo.so` 是被 **OLLVM** 混淆过的吗？
- `classes.dex` 是 **dx** 编译的，还是 **D8/R8**？有没有被 **dexmerge** 合并过？
- 它在检测 **模拟器** 吗？在检测 **Root** 吗？在检测 **Frida** 吗？

APKiD 通过一组 **YARA 规则** 回答这些问题。规则匹配的不是源码，而是二进制中的 **结构指纹**——文件魔数、字符串特征、DEX 的 `map_list` 排列、ELF 节区符号、ZIP 条目路径等。

## 🧰 它能识别什么

| 类别 | 例子 | 数量级 |
|------|------|--------|
| 加固（packer） | 360 加固、腾讯乐固、梆梆、爱加密、百度加固 | 75+ |
| 保护器（protector） | Vkey、Verimatrix、Denuvo、Appdome、FreeRASP | 50+ |
| 混淆器（obfuscator） | OLLVM v3~v9、DexGuard、Arxan、StringFog | 70+ |
| 编译器（compiler） | dx、D8/R8、Jack、dexlib1/2 | 15 |
| 反虚拟机（anti_vm） | 检测 Build 指纹、SIM、QEMU 文件 | 28+ |
| 反调试 / 反 Root / 反 Hook | ptrace、RootBeer、Magisk、Frida、Xposed | 若干 |
| 异常结构 / 释放器 | 非法类名、map 后注入数据、ZIP 炸弹 | 若干 |

规则总数 **365+**，覆盖 APK、DEX、ELF、DLL、RES 五种文件类型。详见[检测规则总览](../rules/overview)。

## 🤖 三种使用方式

APKiD 提供三个等价的接口，背后共享同一套扫描引擎：

1. **经典 CLI** — `apkid`：argparse，人类可读的彩色终端输出，适合手动分析。
2. **AI CLI** — `apkid-ai-cli`：Typer + Rich，结构化 JSON 输出，专为 AI 智能体消费设计。
3. **MCP 服务器** — `apkid-mcp`：标准 MCP 协议（stdio），可被 Claude、Cursor 等 MCP 客户端直接调用。

对比详见 [三种接口对比](../interfaces/overview)。

## 📜 项目背景

APKiD 由 [RedNaga](https://rednaga.io) 维护，基于 GPL & Commercial 双重许可。它脱胎于 Android 恶意软件分析与防盗版研究，曾在 BlackHat EU/UK Arsenal（2018）、NowSecure Connect（2019）、BlackHat USA Arsenal（2023）等会议上展示。

相关资料：

- [Android Compiler Fingerprinting (HITCON 2016)](http://hitcon.org/2016/CMT/slide/day1-r0-e-1.pdf)
- [Detecting Pirated and Malicious Android Apps with APKiD](http://rednaga.io/2016/07/31/detecting_pirated_and_malicious_android_apps_with_apkid/)
- [APKiD: PEiD for Android Apps (BlackHat EU 2018)](https://github.com/enovella/cve-bio-enovella/blob/master/slides/bheu18-enovella-APKID.pdf)
- [APKiD: Fast Identification of Mobile RASP SDKs (BlackHat USA 2023)](https://github.com/enovella/cve-bio-enovella/blob/master/slides/bheu23-enovella-APKID.pdf)

## 📍 下一步

- 想知道为什么需要它？看 [解决了什么问题](./problem-it-solves)。
- 想了解它怎么扫描？看 [工作原理](./how-it-works)。
- 想立刻上手？看 [快速开始](./quickstart)。
