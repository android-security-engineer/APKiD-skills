---
name: apkid-list-tags
description: Use when you need to know all available detection tag categories before filtering scan results or checking rule coverage
allowed-tools: "Bash(apkid-ai-cli:*)"
---

# APKiD Tags

List all available detection tag categories and their descriptions.

## When to Use

- Before filtering `apkid-ai-cli scan` output by category
- When explaining what types of detections APKiD can make
- When checking which categories have YARA rules (for rule development)
- When building automated pipelines that branch on detection category

## Instructions

1. Run `apkid-ai-cli list-tags`
2. Each entry in `tags` has a `tag` (identifier used in findings) and `description`
3. Use the `tag` value to filter scan findings by category

## Commands

```bash
apkid-ai-cli list-tags
```

No parameters.

## Output Format

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "tags": [
    {"tag": "abnormal", "description": "Detects abnormal or suspicious modifications"},
    {"tag": "anti_debug", "description": "Detects anti-debugging techniques"},
    {"tag": "anti_disassembly", "description": "Detects anti-disassembly techniques"},
    {"tag": "anti_hook", "description": "Detects anti-hooking techniques (anti-Frida, anti-Xposed)"},
    {"tag": "anti_root", "description": "Detects anti-root techniques"},
    {"tag": "anti_vm", "description": "Detects anti-VM/anti-emulator techniques"},
    {"tag": "anticheat", "description": "Detects anti-cheat SDKs"},
    {"tag": "compiler", "description": "Detects compiler or build tool fingerprints"},
    {"tag": "dropper", "description": "Detects dropper/loader behavior patterns"},
    {"tag": "embedded", "description": "Detects embedded payloads"},
    {"tag": "file_type", "description": "Detects file type information"},
    {"tag": "hook", "description": "Detects hooking frameworks (Xposed, Frida, etc.)"},
    {"tag": "internal", "description": "Detects internal/development artifacts"},
    {"tag": "manipulator", "description": "Detects APK manipulation tools"},
    {"tag": "obfuscator", "description": "Detects code obfuscation tools"},
    {"tag": "packer", "description": "Detects APK packing/obfuscation tools"},
    {"tag": "protector", "description": "Detects app protection/shielding SDKs"},
    {"tag": "root", "description": "Detects root detection or root-related libraries"},
    {"tag": "signer", "description": "Detects APK signing certificates and signers"},
    {"tag": "yara_issue", "description": "Detects YARA engine issues"}
  ]
}
```

## Examples

```bash
# List all tags
apkid-ai-cli list-tags

# Get just tag names
apkid-ai-cli list-tags | jq -r '.tags[].tag'

# Filter scan results by a specific category
apkid-ai-cli scan app.apk | jq '[.findings[] | select(.category == "packer")]'
```

## Notes

- Tags are returned sorted alphabetically
- The `tag` field in scan findings matches these tag identifiers
- Some categories (e.g. `file_type`, `internal`) are used for internal YARA helpers and may not appear in normal output unless `--include-types` is passed
