# main.py — 经典 CLI 入口

<span class="badge badge-info">经典 CLI</span>
<span class="badge badge-info">argparse</span>

`apkid/main.py` 是 `apkid` 命令的入口（`setup.py` 注册 `apkid=apkid.main:main`）。它用 `argparse` 解析参数、构造 `Options`、跑 `Scanner`、用 `OutputFormatter` 输出。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `get_parser()` | func | 构造 argparse parser |
| `build_options(args)` | func | 把 argparse namespace 转 `Options` |
| `main()` | func | 主流程 |

## ⚙️ get_parser()

定义了经典 CLI 的全部参数：

```
usage: apkid [-h] [-v] [-t TIMEOUT] [-r] [--scan-depth SCAN_DEPTH]
             [--entry-max-scan-size ENTRY_MAX_SCAN_SIZE]
             [--typing {magic,filename,none}] [-j]
             [-o DIR] [FILE [FILE ...]]
```

| 参数 | 说明 | 默认 |
|------|------|------|
| `FILE` | 输入文件/目录（可多个） | — |
| `-v/--verbose` | 调试日志 | False |
| `-t/--timeout` | YARA 超时秒 | 30 |
| `-r/--recursive` | 递归子目录 | False |
| `--scan-depth` | 嵌套 ZIP 深度 | 2 |
| `--entry-max-scan-size` | 条目大小上限 | 100 MB |
| `--typing` | 文件识别策略 | magic |
| `-j/--json` | JSON 输出 | False |
| `-o/--output-dir` | 写多文件目录 | None |
| `--include-types` | 含 file_type | False |

用 `ArgumentDefaultsHelpFormatter`，help 里会显示默认值。

## 🔧 build_options(args)

```python
def build_options(args) -> Options:
    return Options(
        timeout=args.timeout, verbose=args.verbose, json=args.json,
        output_dir=args.output_dir, typing=args.typing,
        entry_max_scan_size=args.entry_max_scan_size,
        scan_depth=args.scan_depth, recursive=args.recursive,
        include_types=args.include_types,
    )
```

注意 `Options` 构造时已 `RulesManager()` + `OutputFormatter(...)` 就绪，这里只是把 argparse 字段映射过去。

## 🚀 main()

```python
def main():
    parser = get_parser()
    args = parser.parse_args()
    options = build_options(args)

    if not options.output.json:
        print(f"[+] APKiD {__version__} :: from RedNaga :: rednaga.io")  # 横幅

    rules = options.rules_manager.load()      # 加载 rules.yarc
    scanner = Scanner(rules, options)

    for input in args.input:
        scanner.scan(input)                   # 扫描，OutputFormatter 直接写
```

特点：
- **不走 `common.make_scanner()`**——经典 CLI 用自己的 `Options` + `Scanner` + `OutputFormatter` 路径。
- 非输出时打印横幅（`[+] APKiD ...`）。
- 支持多输入文件/目录，循环扫描。
- `Scanner.scan()` 内部已调 `OutputFormatter.write()`，所以 main 不直接处理结果。

## 🆚 与 AI CLI 入口的区别

| 维度 | main.py（经典） | cli/app.py（AI） |
|------|----------------|-----------------|
| 参数解析 | argparse | typer |
| 默认 entry_max_scan_size | 100 MB | 0（不限） |
| 输出 | OutputFormatter | AIOutputFormatter |
| 横幅 | 有 | 无 |
| 共享 make_scanner | 否 | 是 |

经典 CLI 的 `--entry-max-scan-size` 默认 100MB 是历史默认，偏保守；AI CLI 默认 0（不限）更贴合"扫到底"的 AI 用例。

## 📍 相关

- [output.py](./output) — 它用的格式化器。
- [cli/app.py](./cli-app) — AI CLI 入口对比。
- [经典 CLI 概览](../interfaces/classic-cli) — 用户视角。
