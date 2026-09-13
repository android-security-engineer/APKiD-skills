---
name: apkid-rules
description: Use when listing YARA rule source files or recompiling rules.yarc after editing or adding YARA rules
allowed-tools:
  - "Bash(apkid-ai-cli:*)"
  - "Bash(python:*)"
---

# APKiD Rules

List YARA rule source files or recompile `rules.yarc` from source.

## When to Use

- After editing or adding a `.yara` file, to recompile `rules.yarc`
- To verify which YARA source files are loaded by the engine
- To confirm compilation succeeded and get the updated rule count
- As part of the rule development workflow before testing with `apkid-ai-cli scan`

## Instructions

### List rule files

1. Run `apkid-ai-cli rules list`
2. Review the `rules` array — paths are relative to `apkid/rules/`
3. Use this to confirm a new `.yara` file was picked up before compiling

### Compile rules

1. After editing a `.yara` file, run `apkid-ai-cli rules compile`
2. Check `compiled: true` and note the updated `rules_count`
3. If compilation fails, check stderr for the error message

## Commands

### List source files

```bash
apkid-ai-cli rules list
```

### Compile rules.yarc

```bash
apkid-ai-cli rules compile
```

| Argument | Required | Description |
|----------|----------|-------------|
| `action` | Yes | `list` — show source files; `compile` — rebuild rules.yarc |

## Output Format

**list:**
```json
{
  "schema_version": "1.0.0",
  "error": false,
  "rules": [
    "apk/common.yara",
    "apk/obfuscators.yara",
    "apk/packers.yara",
    "apk/protectors.yara",
    "dex/abnormal.yara",
    "dex/anti-vm.yara",
    "dex/compilers.yara",
    "dex/obfuscators.yara",
    "dex/packers.yara",
    "dex/protectors.yara"
  ],
  "count": 21
}
```

**compile:**
```json
{
  "schema_version": "1.0.0",
  "error": false,
  "compiled": true,
  "rules_count": 365
}
```

## Examples

```bash
# See which .yara files are loaded
apkid-ai-cli rules list

# Recompile after editing a rule
apkid-ai-cli rules compile

# Full rule dev cycle
# 1. Edit apkid/rules/dex/packers.yara
# 2. Compile
apkid-ai-cli rules compile
# 3. Test
apkid-ai-cli scan sample.apk
```

## Notes

- `rules.yarc` is the compiled binary used at scan time; source `.yara` files are not used directly during scans
- Alternatively, `python prep-release.py` also compiles rules (equivalent to `rules compile`)
- If `compile` errors, the YARA rule syntax is invalid — check the stderr message for the offending rule name
