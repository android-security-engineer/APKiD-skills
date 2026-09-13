# APKiD 解决了什么问题

<span class="badge badge-info">背景</span>
<span class="badge badge-info">动机</span>

逆向分析 Android 应用时，**"它被怎么处理过"** 这个问题横在每一个样本面前。APKiD 专门解决它。

## 💔 没有 APKiD 之前的痛点

### 1. 看不出样本被加固了

一个被 360 加固的 APK，解压后 `classes.dex` 只是个壳——真正的代码被加密塞在 `lib/.../libjiagu.so` 里。分析师若不知道这是加固，会一头雾水："这个 dex 怎么只有一个 Application 类？代码哪去了？"

加固厂商在中国尤其多：梆梆、360、腾讯乐固、百度、爱加密、阿里……每家都有自己的特征文件名和 so 库符号。**靠肉眼记不住**。

### 2. 不知道编译器，就不知道下一步用什么工具

- **dx** 编译的 dex → 可以用 baksmali
- **D8/R8** 编译的 dex → 可能有 marker，结构略不同
- **Jack** 编译的 dex → 有匿名方法特征 `-set0` `-get0`，smali 还原要小心
- 被 **dexmerge** 合并过 → 多 dex 合并痕迹

不识别编译器，反编译工具链的选择就变成瞎猜。

### 3. 原生库是否被 OLLVM 混淆，直接影响逆向成本

`libfoo.so` 若被 OLLVM 做了控制流平坦化（CFF）、虚假控制流（BCF）、字符串加密，IDA 打开就是一片雪花。**提前知道是不是 OLLVM、哪个版本**，能决定是直接逆还是先脱混淆。

### 4. 恶意软件的对抗技术藏在细节里

反虚拟机样本会在 `classes.dex` 里检查 `Build.FINGERPRINT`、`Build.MODEL`、SIM 运营商、`/proc/cpuinfo`、`/sys/qemu_trace`……分析师在沙箱里跑不起来，却不知道为什么。APKiD 一扫就能列出它检测了哪些环境特征。

## ✅ APKiD 怎么解决

APKiD 把"识别二进制来源"这件事 **规则化** 了：

1. **特征入库**：每个加固/混淆/编译器方案，都有人提炼出它独有的指纹（字符串、路径、结构特征），写成一条 YARA 规则。
2. **统一引擎**：用 YARA 引擎一次性匹配所有规则，避免手写一堆 `if/else`。
3. **递归解包**：APK 是 ZIP，APKiD 自动解压、识别内部条目、递归扫描嵌套包，对 `classes.dex`、`lib/*.so` 分别匹配相应规则。
4. **结构化输出**：把 YARA 的 `Match` 对象整理成带 `category`、`identifier`、`confidence`、`source` 的 finding 列表，既给人看也给 AI 看。

```
未知 APK
  │
  ▼
APKiD 扫描
  │  ├─ 识别为 zip → 解包
  │  ├─ classes.dex  → 匹配 dex/* 规则 → compiler::dx, packer::bangcle_dex
  │  ├─ lib/.../libjiagu.so → 匹配 elf/* 规则 → packer::jiagu_native
  │  └─ AndroidManifest.xml 路径 → 匹配 apk/* 规则 → packer::jiagu_360_v5
  ▼
结构化结论：这个 APK 被 360 加固 v5 包裹，dex 用 dx 编译
```

## 🎯 典型使用场景

| 场景 | APKiD 的作用 |
|------|--------------|
| 恶意软件分析 | 快速判断样本是否加固、是否带反虚拟机/反调试，决定沙箱策略 |
| 防盗版 / 应用溯源 | 识别应用是否被二次打包、用了哪种加固方案 |
| 应用安全评估 | 列出样本使用的保护 SDK，评估保护强度 |
| 批量样本分类 | `batch` 命令扫一整个目录，按加固方案聚类 |
| 版本对比 | `diff` 命令对比新旧版本，发现新增/移除的保护 |
| AI 智能体分析 | MCP/AI-CLI 让 AI 直接调用，把"识别"作为分析流水线的一环 |

## 🚫 它不做什么

APKiD **不**做这些事（需要其它工具配合）：

- ❌ **脱壳/还原原始 dex**：它只告诉你"被加固了"，不负责解开。脱壳用 [FRIDA-DEXDump](https://github.com/hluwa/FRIDA-DEXDump) 等。
- ❌ **反编译**：它不把 dex 还原成 Java/smali。用 [jadx](https://github.com/skylot/jadx)、[apktool](https://ibotpeaches.github.io/Apktool/)。
- ❌ **漏洞挖掘**：它不分析逻辑漏洞。
- ❌ **行为分析**：它不运行样本，只做静态指纹匹配。

APKiD 的定位是分析流水线的 **第一道工序**——先用它把样本"是什么"搞清楚，再决定后续用什么工具。

## 📍 下一步

- [工作原理](./how-it-works) — 看看扫描引擎具体怎么跑。
- [架构概览](./architecture) — 三个接口如何共享同一套代码。
