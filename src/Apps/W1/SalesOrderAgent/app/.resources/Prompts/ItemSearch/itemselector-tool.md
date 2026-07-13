
{
  "type": "function",
  "function": {
    "name": "select_best_matching_item",
    "description": "Select the best matching item(s) and variant codes from candidates based on the search query. Prioritize exact matches on structured identifiers before semantic similarity, and use the Variants column only when the query gives enough variant signal.",
    "parameters": {
      "type": "object",
      "properties": {
        "selected_items": {
          "type": "array",
          "description": "Array of items with per-item confidence levels and optional variant codes. Return matching items first, followed by optional alternatives.",
          "items": {
            "type": "object",
            "properties": {
              "item_no": {
                "type": "string",
                "description": "The Item No. value"
              },
              "variant_code": {
                "type": "string",
                "description": "The selected Item Variant Code from the candidate's Variants column. Return an empty string when no variant is explicitly or semantically identified by the query. Do not invent variant codes."
              },
              "confidence": {
                "type": "string",
                "enum": ["matching", "alternative", "none"],
                "description": "\"matching\" → high confidence (strong identifier or clear semantic match); \"alternative\" → related but less precise match within the same product family or intent; \"none\" → no meaningful relation to the query (must NOT be returned)"
              },
              "reason": {
                "type": "string",
                "description": "Short explanation of how the item was evaluated against the query."
              }
            },
            "required": ["item_no", "variant_code", "confidence", "reason"]
          }
        }
      },
      "required": ["selected_items"]
    }
  },
  "additional_instructions": [
    "Only return items with confidence \"matching\" or \"alternative\"",
    "Items marked as \"none\" must NOT be included in the final output",
    "Always return \"matching\" items first",
    "Return variant_code only when it exists in the candidate Variants data and the query identifies it explicitly or semantically",
    "Return an empty variant_code when the query names only the item and does not imply a specific variant",
    "Include up to 3 \"alternative\" items if relevant",
    "Do not return unrelated items",
    "For each returned item, include \"reason\" with a concise description of why it was selected"
  ]
}

