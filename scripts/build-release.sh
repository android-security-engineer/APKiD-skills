#!/usr/bin/env bash
#
# build-release.sh — Build a self-contained source tarball for a GitHub Release.
#
# Produces dist/apkid-<VERSION>.tar.gz containing:
#   - the full clean source tree from git HEAD (.yara rule sources, CLI, MCP,
#     SKILL.md, docs)
#   - a freshly compiled apkid/rules/rules.yarc (required so agents on the
#     source tarball don't need to recompile; the git archive itself does NOT
#     include rules.yarc because it is gitignored)
#
# Usage:
#   scripts/build-release.sh [VERSION]     # default 4.0.0
#
# IMPORTANT: Run AFTER committing and tagging. This exports git HEAD, so any
# uncommitted changes will NOT be in the tarball.
set -euo pipefail

VERSION="${1:-4.0.0}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${REPO_ROOT}/dist"
STAGE="$(mktemp -d)"
PKG_DIR="${STAGE}/apkid-${VERSION}"

echo "[*] Version: ${VERSION}"
echo "[*] Exporting clean source tree from git HEAD..."
mkdir -p "${PKG_DIR}"
git -C "${REPO_ROOT}" archive HEAD | tar -x -C "${PKG_DIR}"

echo "[*] Compiling rules.yarc from .yara sources..."
(
  cd "${PKG_DIR}"
  python3 -c "
from apkid.rules import RulesManager
m = RulesManager()
m.compile()
n = m.save()
print(f'    compiled {n} rules -> apkid/rules/rules.yarc')
"
)

mkdir -p "${OUT_DIR}"
tar -C "${STAGE}" -czf "${OUT_DIR}/apkid-${VERSION}.tar.gz" "apkid-${VERSION}"
rm -rf "${STAGE}"

echo "[*] Wrote ${OUT_DIR}/apkid-${VERSION}.tar.gz"
echo "[*] Contents (first 20):"
tar -tzf "${OUT_DIR}/apkid-${VERSION}.tar.gz" | sort | head -20
echo "[*] rules.yarc present:"
tar -tzf "${OUT_DIR}/apkid-${VERSION}.tar.gz" | grep -c 'rules\.yarc$' || true
