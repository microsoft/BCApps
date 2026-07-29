
{
  "type": "function",
  "function": {
    "name": "select_best_matching_item",
    "description": "Select the best matching item(s) and variant codes from candidates based primarily on the search query, using message content only as supporting context for that same item. Prioritize exact matches on structured identifiers before semantic similarity, and use the Variants column only when the query or relevant same-item context gives enough variant signal.",
    "parameters": {
      "type": "object",
      "properties": {
        "selected_items": {
          "type": "array",
          "description": "Array of items with per-item confidence levels and optional variant codes. Return matching items first, followed by optional alternatives. The same item_no may appear more than once only for different variant_code alternatives.",
          "items": {
            "type": "object",
            "properties": {
              "item_no": {
                "type": "string",
                "description": "The Item No. value"
              },
              "variant_code": {
                "type": "string",
                "description": "The selected Item Variant Code from the candidate's Variants column. Return an empty string when no variant is explicitly or semantically identified by the query or relevant same-item message context. Do not invent variant codes."
              },
              "confidence": {
                "type": "string",
                "enum": ["matching", "alternative", "none"],
                "description": "\"matching\" → high confidence (strong identifier or clear semantic match); \"alternative\" → related but less precise match within the same product family or intent; \"none\" → no meaningful relation to the query (must NOT be returned)"
              },
              "variant_resolution": {
                "type": "string",
                "enum": ["not_requested", "resolved", "unresolved_interchangeable", "unresolved_non_interchangeable"],
                "description": "Whether no variant was requested, variant_code resolves the request, the requested value is absent but safe alternatives are allowed, or the requested value is absent and alternatives would change suitability"
              },
              "reason": {
                "type": "string",
                "description": "Short explanation of how the item was evaluated against the query."
              }
            },
            "required": ["item_no", "variant_code", "confidence", "variant_resolution", "reason"]
          }
        },
        "unresolved_variant_requests": {
          "type": "array",
          "description": "Items for which the query requests a variant value that is not present in the candidate's Variants data. Return an empty array when no requested variant is unresolved.",
          "items": {
            "type": "object",
            "properties": {
              "item_no": {
                "type": "string",
                "description": "The Item No. whose requested variant is unresolved"
              },
              "alternatives_allowed": {
                "type": "boolean",
                "description": "True for presentation-only dimensions that preserve suitability unless exact substitution is forbidden; false for dimensions that can affect fit, compatibility, function, safety, capacity, technical requirements, or intended user group"
              }
            },
            "required": ["item_no", "alternatives_allowed"]
          }
        }
      },
      "required": ["selected_items", "unresolved_variant_requests"]
    }
  },
  "additional_instructions": [
    "Only return items with confidence \"matching\" or \"alternative\"",
    "Items marked as \"none\" must NOT be included in the final output",
    "Always return \"matching\" items first",
    "Return variant_code only when it exists in the candidate Variants data and the query or relevant same-item message context identifies it explicitly or semantically",
    "Use message content only as supporting context for the current search query; do not borrow item or variant intent from unrelated lines in a multi-item message",
    "Return an empty variant_code when the query names only the item and relevant same-item message context does not imply a specific variant",
    "Never suggest a variant that changes fit, compatibility, or another non-interchangeable requirement unless the customer explicitly allows that change; this rule overrides every instruction to return alternatives",
    "Infer the requested variant dimension from the query and the candidate variant codes and descriptions; an absent requested value does not make the base product unrelated",
    "Treat presentation-only dimensions such as color, finish, pattern, or decorative style as interchangeable by default and set alternatives_allowed to true unless the customer explicitly requires the exact value or rejects substitutions",
    "Treat dimensions affecting physical fit, dimensions, capacity, compatibility, technical specification, safety classification, or intended user group as non-interchangeable by default",
    "Availability does not make a variant interchangeable; select the requested variant when present and let downstream logic evaluate availability",
    "When the query explicitly or semantically requests a variant value, never return that item as matching with an empty variant_code",
    "Every selected item must declare variant_resolution; use unresolved_interchangeable or unresolved_non_interchangeable whenever a requested variant value is absent from that item's Variants data",
    "For every requested variant value absent from an item's Variants data, add that item to unresolved_variant_requests and set alternatives_allowed according to whether changing the variant preserves suitability",
    "Always include the matching base item in unresolved_variant_requests when its requested variant value is absent, even if selected_items contains only concrete alternatives or is empty",
    "Do not add an item to unresolved_variant_requests when the requested variant exists in its Variants data; downstream logic evaluates availability",
    "When the selected item has a specific matching variant_code, also return genuinely interchangeable same-item variant alternatives as separate selected_items entries with confidence \"alternative\"; return no alternatives for fit, compatibility, or other non-interchangeable requirements",
    "When the requested variant is not present, return up to 3 valid same-item variants with confidence \"alternative\" only when that variant dimension is interchangeable; do not also return the item with an empty variant_code, and return no alternatives if changing the variant affects suitability",
    "Include up to 3 \"alternative\" items if relevant",
    "Do not return unrelated items",
    "For each returned item, include \"reason\" with a concise description of why it was selected"
  ]
}

