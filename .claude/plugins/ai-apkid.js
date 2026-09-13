const plugin = {
  name: "ai-apkid",
  description: "Android APK/DEX/ELF identifier for AI agents - detect packers, protectors, obfuscators, and more",
  version: "4.0.0",
  skills: [
    {
      name: "apkid-scan",
      path: "skills/apkid-scan/SKILL.md",
      description: "Scan Android APK/DEX/ELF files for packer, signer, compiler, and protector identifiers"
    },
    {
      name: "apkid-batch",
      path: "skills/apkid-batch/SKILL.md",
      description: "Batch scan directories of Android APK/DEX/ELF files"
    },
    {
      name: "apkid-diff",
      path: "skills/apkid-diff/SKILL.md",
      description: "Compare two APK/DEX/ELF files to find added or removed protections"
    },
    {
      name: "apkid-type",
      path: "skills/apkid-type/SKILL.md",
      description: "Quickly identify whether a file is an APK, DEX, ELF, or other Android binary format"
    },
    {
      name: "apkid-rule-dev",
      path: "skills/apkid-rule-dev/SKILL.md",
      description: "Develop and test YARA rules for AI-APKiD"
    },
    {
      name: "apkid-skills",
      path: "skills/apkid-skills/SKILL.md",
      description: "Self-discover available apkid-ai-cli commands and capabilities"
    },
    {
      name: "apkid-info",
      path: "skills/apkid-info/SKILL.md",
      description: "Check APKiD version, rules integrity, and installation status"
    },
    {
      name: "apkid-list-tags",
      path: "skills/apkid-list-tags/SKILL.md",
      description: "List all available detection tag categories and their descriptions"
    },
    {
      name: "apkid-rules",
      path: "skills/apkid-rules/SKILL.md",
      description: "List YARA rule source files or recompile rules.yarc"
    },
    {
      name: "apkid-explain",
      path: "skills/apkid-explain/SKILL.md",
      description: "Explain a detection tag and get reverse engineering advice for the identified protection"
    }
  ]
};

module.exports = plugin;