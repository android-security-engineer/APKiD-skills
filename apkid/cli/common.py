"""Shared types and utilities for the APKiD AI-CLI."""

import json
from enum import Enum
from pathlib import Path
from typing import Optional

import typer

from apkid.ai_output import SCHEMA_VERSION, error_dict
from apkid.apkid import Options, Scanner
from apkid.rules import RulesManager


class TypingMethod(str, Enum):
    magic = "magic"
    filename = "filename"
    none = "none"


class OutputFormat(str, Enum):
    json = "json"
    text = "text"


VALID_TYPING_METHODS = frozenset(("magic", "filename", "none"))


def validate_scan_options(
    timeout: int,
    typing: str,
    scan_depth: int,
    entry_max_scan_size: int,
) -> None:
    """Validate options shared by the AI CLI and MCP adapters.

    Keeping this validation next to ``make_scanner`` prevents the two
    interfaces from accepting different, potentially unsafe values.
    """
    if isinstance(timeout, bool) or not isinstance(timeout, int) or timeout <= 0:
        raise ValueError("timeout must be a positive integer")
    if not isinstance(typing, str) or typing not in VALID_TYPING_METHODS:
        allowed = ", ".join(sorted(VALID_TYPING_METHODS))
        raise ValueError(f"typing must be one of: {allowed}")
    if isinstance(scan_depth, bool) or not isinstance(scan_depth, int) or scan_depth < 0:
        raise ValueError("scan_depth must be a non-negative integer")
    if (
        isinstance(entry_max_scan_size, bool)
        or not isinstance(entry_max_scan_size, int)
        or entry_max_scan_size < 0
    ):
        raise ValueError("entry_max_scan_size must be a non-negative integer")


def make_scanner(
    timeout: int = 30,
    typing: str = "magic",
    scan_depth: int = 2,
    entry_max_scan_size: int = 0,
    include_types: bool = False,
) -> Scanner:
    """Create a Scanner with the given options."""
    validate_scan_options(timeout, typing, scan_depth, entry_max_scan_size)
    rules_mgr = RulesManager()
    rules = rules_mgr.load()
    options = Options(
        timeout=timeout,
        json=True,
        typing=typing,
        scan_depth=scan_depth,
        entry_max_scan_size=entry_max_scan_size,
        include_types=include_types,
    )
    return Scanner(rules=rules, options=options)


def output_result(formatted: str, output: Optional[Path] = None):
    """Write result to file or stdout."""
    if output:
        output.write_text(formatted, encoding="utf-8")
    else:
        typer.echo(formatted)


def error_exit(message: str, detail: str = "", code: int = 1):
    """Print structured error to stderr and exit."""
    error_payload = json.dumps(error_dict(message, detail), ensure_ascii=False)
    typer.echo(error_payload, err=True)
    raise typer.Exit(code=code)
