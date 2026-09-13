---
name: apkid-explain
description: Use when you need to understand what a specific detection tag means, what category it belongs to, and get reverse engineering advice for a detected packer, protector, or obfuscator
allowed-tools: "Bash(apkid-ai-cli:*)"
---

# APKiD Explain Skill

## When to Use

Use this skill when you need to:
- Understand what a specific detection tag or identifier means (e.g. "what is bangcle?")
- Get category classification for a detected tag
- Obtain reverse engineering advice after a scan finds a packer, protector, or anti-debug technique
- Explain scan results to a user in actionable terms

Typical flow: run `apkid-scan` first, then `apkid-explain` on each finding's `identifier` or `tag` field.

## Instructions

1. Run `apkid-ai-cli explain <tag>` with any tag or identifier from a scan result
2. Check `category` to understand what class of protection was detected
3. Use `advice` to guide the next step in analysis or reverse engineering
4. Use `known: false` to flag unrecognized tags to the user

## Commands

### `apkid-ai-cli explain`

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `tag` | Yes | — | Detection tag to explain (e.g. `bangcle`, `anti_vm`, `frida`, `xposed`) |

```bash
apkid-ai-cli explain <tag>
```

## Output Format

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "tag": "bangcle",
  "category": "packer",
  "category_description": "Detects APK packing/obfuscation tools",
  "known": true,
  "advice": "The file is packed. The original DEX is encrypted/compressed and loaded at runtime. Recommend: use a Frida script to dump the decrypted DEX from memory, or find a dedicated unpacker for the identified packer."
}
```

Unknown tag example:
```json
{
  "schema_version": "1.0.0",
  "error": false,
  "tag": "custom_xyz",
  "category": "abnormal",
  "category_description": "Detects abnormal or suspicious modifications",
  "known": false,
  "advice": "The file has abnormal structural characteristics. May indicate manual editing, corruption, or evasion attempts. Recommend: use multiple analysis tools."
}
```

### Fields

| Field | Description |
|-------|-------------|
| `tag` | The tag you queried |
| `category` | The matched category from APKiD's category system |
| `category_description` | What this category detects |
| `known` | `true` if tag maps to a recognized category keyword; `false` if it fell back to "abnormal" |
| `advice` | Actionable reverse engineering guidance for this category |

## Examples

### After a scan, explain each finding

```bash
# Step 1: scan the file
apkid-ai-cli scan suspicious.apk

# Step 2: explain key findings
apkid-ai-cli explain bangcle
apkid-ai-cli explain anti_vm
apkid-ai-cli explain dexlib2
```

### Explain a category directly

```bash
apkid-ai-cli explain packer
apkid-ai-cli explain anti_debug
apkid-ai-cli explain obfuscator
```

### Explain a hook framework

```bash
apkid-ai-cli explain frida
apkid-ai-cli explain xposed
```

## Notes

- The `tag` parameter accepts both category names (`packer`, `anti_vm`) and specific tool names (`bangcle`, `dexguard`)
- For specific tool names, the category is inferred from keywords in the tag name (e.g. `packer` in `packer::bangcle`)
- `known: false` means no recognized category keyword was found in the tag — advice still applies to the fallback category
- This command requires no YARA rules or file system access — it is always fast
