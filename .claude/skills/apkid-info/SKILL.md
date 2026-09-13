---
name: apkid-info
description: Use when checking APKiD version, rules integrity, or verifying installation status before scanning
allowed-tools: "Bash(apkid-ai-cli:*)"
---

# APKiD Info

Show APKiD version, compiled rules hash, and rules count.

## When to Use

- Before scanning, to verify APKiD is installed and rules are compiled
- In CI/CD pipelines to check that rules are up to date
- When diagnosing scan failures or unexpected results
- When reporting the toolchain version alongside analysis results

## Instructions

1. Run `apkid-ai-cli info`
2. Check `error` field — if `true`, rules are not compiled (run `python prep-release.py`)
3. Use `rules_sha256` to verify rule integrity across environments
4. Use `rules_count` to confirm the expected number of rules is loaded

## Commands

```bash
apkid-ai-cli info
```

No parameters.

## Output Format

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "version": "3.1.0",
  "rules_sha256": "a3f2c1...",
  "rules_count": 365
}
```

Error (rules not compiled):
```json
{
  "error": true,
  "message": "Unable to load compiled rules: ...",
  "type": "FileNotFoundError"
}
```

## Examples

```bash
# Check installation status
apkid-ai-cli info

# Use in a pipeline pre-flight check
apkid-ai-cli info | jq -e '.error == false'
```

## Notes

- If `error` is true, run `python prep-release.py` to compile `rules.yarc`
- `rules_sha256` is the SHA-256 of the compiled `rules.yarc` file
- `rules_count` counts unique rule identifiers, not raw YARA rule blocks
