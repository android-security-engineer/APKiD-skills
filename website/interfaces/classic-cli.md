# 经典 CLI 概览

<span class="badge badge-info">经典 CLI</span>
<span class="badge badge-info">argparse</span>

`apkid` 命令是 APKiD 的经典接口，基于 argparse，提供彩色终端输出与 JSON 输出。适合终端手动分析。

## 🚀 用法

```
usage: apkid [-h] [-v] [-t TIMEOUT] [-r] [--scan-depth SCAN_DEPTH]
             [--entry-max-scan-size ENTRY_MAX_SCAN_SIZE]
             [--typing {magic,filename,none}] [-j]
             [-o DIR] [FILE [FILE ...]]

APKiD - Android Application Identifier v3.1.0
```

## 📋 参数

| 参数 | 说明 | 默认 |
|------|------|------|
| `FILE...` | APK/DEX/ELF 文件或目录（可多个） | — |
| `-h` | 帮助 | — |
| `-v` / `--verbose` | 调试日志 | off |
| `-t` / `--timeout` | YARA 超时秒 | 30 |
| `-r` / `--recursive` | 递归子目录 | off |
| `--scan-depth` | 嵌套 ZIP 深度 | 2 |
| `--entry-max-scan-size` | ZIP 条目大小上限 | 100 MB |
| `--typing` | 文件识别策略 `magic`/`filename`/`none` | magic |
| `-j` / `--json` | JSON 输出 | off |
| `-o` / `--output-dir DIR` | 写多文件目录（隐含 `-j`） | — |
| `--include-types` | 含 file_type 检测 | off |

## 🎨 终端输出示例

```bash
apkid app.apk
```

```
[+] APKiD 3.1.0 :: from RedNaga :: rednaga.io
[*] app.apk!classes.dex
 |-> compiler : dx
[*] app.apk!lib/arm64-v8a/libfoo.so
 |-> obfuscator : ollvm_v9
[*] app.apk!assets/libjiagu.so
 |-> packer : 360 Jiagu v5
```

tag 按类别上色（compiler=cyan、packer=red、obfuscator=yellow 等，见 [output.py](../modules/output)）。非 TTY（管道/重定向）时自动不上色。

## 📄 JSON 输出

```bash
apkid -j app.apk
```

```json
{
  "apkid_version": "3.1.0",
  "rules_sha256": "abc123...",
  "files": [
    {
      "filename": "app.apk!classes.dex",
      "matches": { "compiler": ["dx"] }
    },
    {
      "filename": "app.apk!lib/arm64-v8a/libfoo.so",
      "matches": { "obfuscator": ["OLLVM v9"] }
    }
  ]
}
```

::: warning 与 AI CLI JSON 不同
经典 JSON schema 是 `{apkid_version, rules_sha256, files:[{filename, matches:{tag:[desc]}}]}`。AI CLI 用的是 `{schema_version, findings:[...], summary:{}}`。两套不通用。新脚本建议用 AI CLI。
:::

## 📁 批量写目录

```bash
# 扫整个目录，每个文件一个 JSON，保留路径结构
apkid -r -j -o results/ samples/

# 结果：results/samples/app.apk.json, results/samples/sub/other.apk.json ...
```

`--output-dir` 隐含 `-j`，按原始文件路径建子目录。适合批量特征提取入库。

## 🆚 与 AI CLI 的差异

经典 CLI **没有** 这些命令：`diff`、`type`、`info`、`list-tags`、`rules`、`skills`。它只做"扫文件/目录"这一件事。需要对比、查类型、管理规则时用 `apkid-ai-cli`。

| 能力 | 经典 | AI |
|------|:---:|:---:|
| 扫单文件/目录 | ✅ | ✅ |
| 彩色终端 | ✅ | （`--format text`） |
| 写多文件目录 | ✅ | ❌ |
| `diff` 对比 | ❌ | ✅ |
| `type` 类型 | ❌ | ✅ |
| `info`/`list-tags`/`rules`/`skills` | ❌ | ✅ |
| 结构化 finding + 置信度 | ❌ | ✅ |

## 🐳 Docker 里的经典 CLI

```bash
docker/apkid.sh ~/path/to/app.apk
# 或
docker run --rm -v /path:/input:ro rednaga:apkid apkid /input/app.apk
```

## 📍 相关

- [main.py](../modules/main) — 入口源码。
- [output.py](../modules/output) — 输出格式化。
- [AI CLI 概览](./ai-cli) — 功能更全的接口。
- [快速开始](../guide/quickstart) — 第一次使用。
