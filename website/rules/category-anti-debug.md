# 类别：anti_debug 反调试

<span class="badge badge-anti">anti_debug</span>

`anti_debug` 类别检测 **反调试技术**——样本用来判断自己是否正被调试器附加，若是则改变行为。

## 🎯 常见反调试手段

- **ptrace 检测**：自己 ptrace 自己，若失败说明已被调试器附加。
- **调试器检测**：检查 `Debug.isDebuggerConnected()`。
- **进程扫描**：查 `gdb`、`lldb`、`android_server` 进程。
- **时间检测**：某段代码执行耗时异常→被单步了。
- **/proc/self/status**：读 `TracerPid` 字段，非 0 表示被 trace。

## 📋 规则分布

`anti_debug` tag 的规则：

| 规则 | 检测 |
|------|------|
| `checks_debugger_present` | `Debug.isDebuggerConnected()` 调用 |

APKiD 的 anti_debug 规则较少——很多反调试技术发生在原生层（so 库），属于 `anti_root`/protector 的覆盖范围。DEX 层主要抓 Java API 的调试检测。

::: tip 与其它反分析的关系
反调试常与 [反 Root](./category-anti-root)、[反 Hook](./category-anti-root) 共存——一个完整的对抗样本会同时检测调试器、Root、Frida。APKiD 会分别报告。
:::

## 📊 finding 示例

```json
{
  "tag": "anti_debug::checks_debugger_present",
  "category": "anti_debug",
  "description": "Detects anti-debugging techniques",
  "source": "app.apk!classes.dex",
  "identifier": "checks_debugger_present",
  "confidence": "high"
}
```

## 📍 相关

- [anti_vm 类别](./category-anti-vm) — 相关反分析。
- [anti_root 类别](./category-anti-root) — 含 ptrace 类检测。
- [DEX 异常结构](./dex-abnormal) — 部分反调试靠篡改 dex 结构。
- [检测类别](../guide/categories)
