"""APKiD MCP Server — Model Context Protocol integration.

This module provides an MCP server that exposes APKiD's scanning
capabilities as tools callable by AI agents via the MCP protocol.

The MCP module is intentionally isolated from the rest of the codebase.
It only depends on `apkid.cli.common` and `apkid.ai_output` — never
the reverse.

Requires: mcp>=1.5.0  (install with: pip install "apkid[mcp]")
"""

try:
    from apkid.mcp.server import mcp, run
except ImportError as _exc:
    raise ImportError(
        "The 'mcp' package is required for MCP server functionality. "
        "Install it with: pip install 'apkid[mcp]'  "
        "or: uv add 'apkid[mcp]'"
    ) from _exc

__all__ = ["mcp", "run"]
