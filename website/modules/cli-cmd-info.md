# cli/cmd_info.py — info 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">元数据</span>

ℹ️ `apkid-ai-cli info` 输出 APKiD 版本、规则 SHA256、规则数量。无参数，纯元数据查询，是排查"用的哪个规则版本"的第一步。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `info()` | func | typer 命令回调，输出版本与规则信息 |

模块仅导出 `info` 函数，由 `app.py` 注册为 `info` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli info
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 🔧 源码要点

```python
from apkid import __version__
from apkid.rules import RulesManager

def info():
    """Show version, rules hash, and rules count."""
    rules_mgr = RulesManager()
    rules_hash = rules_mgr.hash
    try:
        rules = rules_mgr.load()
        rules_count = len(set(r.identifier for r in rules))
    except Exception:
        rules_count = 0
    result = {
        "version": __version__,
        "rules_sha256": rules_hash,
        "rules_count": rules_count,
    }
    typer.echo(json.dumps(result, ensure_ascii=False, indent=2))
```

要点：

- **`rules_mgr.hash`**：在 `load()` 之前取规则文件哈希——即使规则加载失败，哈希仍可输出（用于标识"机器上 rules.yarc 是哪个版本"）。
- **`rules_mgr.load()` 包在 try 里**：`rules.yarc` 可能不存在（未跑 `prep-release.py`）或损坏。加载失败时 `rules_count=0`，**不报错**——info 命令的定位是"尽力给出元数据"，规则缺失不应让 `info` 整体失败。
- **`len(set(r.identifier for r in rules))`**：用 `set` 去重，因为同一条规则可能因多文件匹配产生重复 identifier。`identifier` 是 YARA 规则名。
- **不调 `make_scanner`**：与 type 类似，info 不需要构造完整 Scanner（不扫描），直接用 `RulesManager` 的底层 API。
- **直接 `typer.echo`**：不走 `output_result`（无 `--output`），不走 `AIOutputFormatter`（元数据不是检测结果）。
- **无异常向外抛**：`load` 的异常被吞掉，`info` 几乎不会失败（除非 `typer.echo` 本身出错）。

## 🔗 调用链

```
info() → RulesManager().hash              # 规则文件 SHA256
       → RulesManager().load()            # 加载 rules.yarc（可能失败）
       → len(set(r.identifier ...))       # 去重计数
       → typer.echo(json.dumps({version, rules_sha256, rules_count}))
```

## 🤝 与其它模块的关系

- **依赖 [rules 模块](./rules)**：`RulesManager` 的 `hash`/`load`。
- **依赖 `apkid.__version__`**：包级版本号。
- **不依赖 [common.py](./cli-common)**：不调 `make_scanner`/`output_result`/`error_exit`——这是少数不依赖 common 的命令（与 type 类似，type 至少用了 `error_exit`，info 连这个都不用）。
- **被 [app.py](./cli-app) 注册**：`app.command()(cmd_info.info)`。
- **与 [cmd_rules.py](./cli-cmd-rules) 互补**：info 给"当前规则摘要"，rules 给"规则文件列表/重编译"。

## 📍 相关

- [AI CLI · info](../interfaces/ai-cli-info) — 用户视角用法与示例。
- [RulesManager](./rules) — `hash`/`load`/`compile` 的实现。
- [cmd_rules.py](./cli-cmd-rules) — 规则列表与重编译。
- [cmd_tags.py](./cli-cmd-tags) — 检测类别列表。
