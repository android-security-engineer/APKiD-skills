"""apkid-ai-cli explain — Explain a detection tag."""

import json

import typer

from apkid.ai_output import RULE_DESCRIPTIONS, CATEGORY_ADVICE, SCHEMA_VERSION


def _resolve_category(tag: str):
    """Resolve category from tag: direct match, compound 'cat::rule', then substring."""
    t = tag.lower()
    if t in RULE_DESCRIPTIONS:
        return t
    if "::" in t:
        prefix = t.split("::")[0]
        if prefix in RULE_DESCRIPTIONS:
            return prefix
    for cat in RULE_DESCRIPTIONS:
        if cat in t:
            return cat
    return None


def explain(
    tag: str = typer.Argument(..., help="Detection tag to explain (e.g. 'packer::bangcle', 'anti_vm', 'frida')"),
):
    """Explain a detection tag: category, description, and analysis advice."""
    category = _resolve_category(tag)
    known = category is not None
    category = category or "unknown"
    category_desc = RULE_DESCRIPTIONS.get(category, "Unknown detection category")
    advice = CATEGORY_ADVICE.get(category, "No specific advice available for this category.")
    result = {
        "schema_version": SCHEMA_VERSION,
        "error": False,
        "tag": tag,
        "category": category,
        "category_description": category_desc,
        "known": known,
        "advice": advice,
    }
    typer.echo(json.dumps(result, ensure_ascii=False, indent=2))
