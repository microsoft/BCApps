
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
          "description": "Selected items with item and variant match classifications. For a variant-specific request, keep alternatives on the best matching item unless the customer explicitly requests different products.",
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
                "description": "The overall selection classification used to separate direct matches from suggestions. Must be alternative when variant_match is alternative."
              },
              "variant_match": {
                "type": "string",
                "enum": ["matching", "alternative", "not_requested"],
                "description": "Whether variant_code fulfills the variant request, is a safe interchangeable substitute, or is omitted because no variant was requested. Never classify changes to size, fit, compatibility, capacity, technical specification, safety classification, or intended user as alternative unless the customer explicitly permits that change."
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

