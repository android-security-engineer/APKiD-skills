"""apkid-ai-cli list-tags — List all detection tags."""

import json

import typer

from apkid.ai_output import RULE_DESCRIPTIONS, SCHEMA_VERSION


def list_tags():
    """List all available detection tags and their descriptions."""
    tags = []
    for tag, desc in sorted(RULE_DESCRIPTIONS.items()):
        tags.append({"tag": tag, "description": desc})
    typer.echo(json.dumps({
        "schema_version": SCHEMA_VERSION,
        "error": False,
        "tags": tags,
    }, ensure_ascii=False, indent=2))
