---
layout: home

hero:
  name: APKiD
  text: Android 二进制识别工具
  tagline: 识别 APK 是如何被构建、加固、混淆与保护的 —— Android 版的 PEiD
  image:
    src: /favicon.svg
    alt: APKiD
  actions:
    - theme: brand
      text: 快速开始
      link: /guide/quickstart
    - theme: alt
      text: APKiD 是什么
      link: /guide/what-is-apkid
    - theme: alt
      text: GitHub
      link: https://github.com/rednaga/APKiD

features:
  - icon: 🛡️
    title: 识别加固与保护
    details: 检测 360 加固、腾讯乐固、梆梆、爱加密、百度加固等 75+ APK 加固方案，以及 Vkey、Verimatrix 等 RASP 保护 SDK。
  - icon: 🔍
    title: 编译器指纹
    details: 通过 DEX 的 map_list 类型排列顺序等结构特征，识别 dx、D8/R8、Jack、dexlib 等编译工具链。
  - icon: 🧩
    title: 混淆器识别
    details: 识别 OLLVM（v3~v9）、DexGuard、Arxan、StringFog、Allatori 等代码混淆方案，覆盖 DEX 与原生 ELF。
  - icon: 🤖
    title: AI 原生接口
    details: 提供 apkid-ai-cli（结构化 JSON）与 apkid-mcp（标准 MCP 协议）两种 AI 友好接口，供智能体直接调用。
  - icon: 🐛
    title: 反分析检测
    details: 识别反虚拟机、反调试、反 Root、反 Hook（Frida/Xposed）等恶意软件常用的对抗技术。
  - icon: 📦
    title: 多层递归扫描
    details: 自动解压 APK/ZIP 并递归扫描嵌套条目，支持 XZ 压缩，对嵌套 ZIP 炸弹有深度限制防护。
---

<style>
:root {
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: -webkit-linear-gradient(120deg, #3aa675, #2d8060);
  --vp-home-hero-image-background-image: linear-gradient(-45deg, #d4f0e4 50%, #cdeee0 50%);
  --vp-home-hero-image-filter: blur(44px);
  --vp-button-brand-bg: #3aa675;
  --vp-button-brand-hover-bg: #2d8060;
}
</style>

<div class="stats-bar">

| 📊 规则总数 | 🗂️ 文件类型 | 🤖 接口数量 | 🏷️ 检测类别 |
|:---:|:---:|:---:|:---:|
| 365+ | 6 | 3 | 18+ |

</div>

## 📚 文档导览

- **初次接触**：从 [APKiD 是什么](./guide/what-is-apkid) 开始，了解它[解决了什么问题](./guide/problem-it-solves)、[工作原理](./guide/how-it-works)。
- **想要使用**：查看[快速开始](./guide/quickstart)与[三种接口对比](./interfaces/overview)。
- **深入代码**：阅读[代码模块文档](./modules/core-apkid)，逐文件理解实现。
- **检测细节**：在[检测规则](./rules/overview)中按类别与文件类型查阅每一类指纹。
- **部署站点**：参考 [CI/CD 与 GitHub Pages 部署](./deploy/cicd)。

```bash
# 一行命令开始扫描
pip install apkid
apkid-ai-cli scan app.apk
```
