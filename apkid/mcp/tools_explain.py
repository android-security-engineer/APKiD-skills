"""MCP tool adapter for explain operations."""

import json

from apkid.ai_output import RULE_DESCRIPTIONS, CATEGORY_ADVICE, SCHEMA_VERSION


def _resolve_category(tag: str):
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


def explain_tag(tag: str) -> str:
    """Explain a detection tag: its category, description, and analysis advice for reverse engineering.

    Args:
        tag: Detection tag to explain. Accepts: category name ('packer'), compound tag ('packer::bangcle_dex'), or any tag from scan findings.

    Returns:
        JSON string with tag explanation and reverse engineering advice
    """
    category = _resolve_category(tag)
    known = category is not None
    category = category or "unknown"
    category_desc = RULE_DESCRIPTIONS.get(category, "Unknown detection category")
    advice = CATEGORY_ADVICE.get(category, "No specific advice available for this category.")
    return json.dumps({
        "schema_version": SCHEMA_VERSION,
        "error": False,
        "tag": tag,
        "category": category,
        "category_description": category_desc,
        "known": known,
        "advice": advice,
    }, ensure_ascii=False, indent=2)
