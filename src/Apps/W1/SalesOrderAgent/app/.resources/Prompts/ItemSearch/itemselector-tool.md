
{
  "type": "function",
  "function": {
    "name": "select_best_matching_item",
    "description": "Return selected item candidates and variant decisions.",
    "parameters": {
      "type": "object",
      "properties": {
        "selected_items": {
          "type": "array",
          "description": "Selected items with item and variant match classifications.",
          "items": {
            "type": "object",
            "properties": {
              "item_no": {
                "type": "string",
                "description": "The Item No. value"
              },
              "variant_code": {
                "type": "string",
                "description": "The selected Item Variant Code from the candidate's Variants column. Include only when a variant is explicitly or semantically identified by the query or relevant same-item message context. Do not invent variant codes."
              },
              "confidence": {
                "type": "string",
                "enum": ["matching", "alternative"],
                "description": "The item-level match classification."
              },
              "variant_match": {
                "type": "string",
                "enum": ["matching", "alternative", "not_requested"],
                "description": "Whether variant_code fulfills the variant request, is a safe substitute, or is omitted because no variant was requested"
              },
              "reason": {
                "type": "string",
                "description": "A concise explanation of the item and variant decision."
              }
            },
            "required": ["item_no", "confidence", "variant_match", "reason"]
          }
        }
      },
      "required": ["selected_items"]
    }
  }
}

