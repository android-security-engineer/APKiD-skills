"""APKiD MCP Server — FastMCP server definition and tool registration.

Uses the official MCP Python SDK (mcp>=1.5.0) and its FastMCP
high-level API. FastMCP handles protocol serialization, tool schema
generation from type hints and docstrings, and transport automatically.

Design: Tool adapter functions return JSON strings. FastMCP wraps each
return value into the MCP protocol response. All tools are registered
with ``structured_output=False`` so the SDK does not attempt to wrap
the return type annotation into a pydantic model.

Transport configuration via environment variables:
  APKID_MCP_TRANSPORT  — 'stdio' (default), 'sse', or 'streamable-http'
  APKID_MCP_HOST       — bind host for SSE/streamable-http (default: 127.0.0.1)
  APKID_MCP_PORT       — bind port for SSE/streamable-http (default: 8000)
"""

from mcp.server.fastmcp import FastMCP

from apkid.mcp.tools_scan import scan_file, batch_scan, diff_files, type_file
from apkid.mcp.tools_info import info, list_tags, rules, skills
from apkid.mcp.tools_explain import explain_tag

MCP_SERVER_NAME = "apkid"
MCP_SERVER_INSTRUCTIONS = (
    "APKiD MCP Server — Android APK/DEX/ELF identifier.\n"
    "Scanning: scan_file (single file), batch_scan (directory), diff_files (compare two), type_file (magic-byte type check).\n"
    "Analysis: explain_tag (get category, description, and reverse-engineering advice for any detection tag).\n"
    "Metadata: info (version + rules hash), list-tags (all categories), rules (list/compile YARA sources), skills (tool list).\n"
    "All tools return JSON. On error, output contains {\"error\": true, \"message\": \"...\"}."
)

mcp = FastMCP(
    MCP_SERVER_NAME,
    instructions=MCP_SERVER_INSTRUCTIONS,
)

# --- Scanning tools ---
mcp.tool(title="Scan File", structured_output=False)(scan_file)
mcp.tool(title="Batch Scan", structured_output=False)(batch_scan)
mcp.tool(title="Diff Files", structured_output=False)(diff_files)
mcp.tool(title="File Type", structured_output=False)(type_file)

# --- Metadata tools ---
mcp.tool(title="APKiD Info", structured_output=False)(info)
mcp.tool(name="list-tags", title="List Tags", structured_output=False)(list_tags)
mcp.tool(title="YARA Rules", structured_output=False)(rules)
mcp.tool(title="Skills", structured_output=False)(skills)

# --- Explain tool ---
mcp.tool(title="Explain Tag", structured_output=False)(explain_tag)


def run():
    """Entry point for the apkid-mcp console script.

    Transport and binding are configured via environment variables:
      APKID_MCP_TRANSPORT — 'stdio' (default), 'sse', 'streamable-http'
      APKID_MCP_HOST      — host to bind for SSE/streamable-http (default: 127.0.0.1)
      APKID_MCP_PORT      — port to bind for SSE/streamable-http (default: 8000)

    Claude Desktop / Claude Code (stdio):
      No env vars needed — stdio is the default.

    Remote MCP host (SSE):
      APKID_MCP_TRANSPORT=sse APKID_MCP_HOST=0.0.0.0 APKID_MCP_PORT=8765 apkid-mcp
    """
    import os
    import sys

    transport = os.environ.get("APKID_MCP_TRANSPORT", "stdio")
    valid = ("stdio", "sse", "streamable-http")
    if transport not in valid:
        print(
            f"Error: APKID_MCP_TRANSPORT must be one of {valid}, got: {transport!r}",
            file=sys.stderr,
        )
        sys.exit(1)

    if transport in ("sse", "streamable-http"):
        host = os.environ.get("APKID_MCP_HOST", "127.0.0.1")
        port_str = os.environ.get("APKID_MCP_PORT", "8000")
        try:
            port = int(port_str)
        except ValueError:
            print(
                f"Error: APKID_MCP_PORT must be an integer, got: {port_str!r}",
                file=sys.stderr,
            )
            sys.exit(1)
        mcp.host = host
        mcp.port = port

    mcp.run(transport=transport)  # type: ignore[arg-type]
