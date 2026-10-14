{
    "type": "function",
    "function": {
        "name": "split_item_keywords",
        "description": "Split an item-search phrase into structured keywords for catalog matching: item_name, item_name_plural, optional features, optional common synonyms, and optional concatenated_keyword.",
        "parameters": {
            "type": "object",
            "properties": {
                "results": {
                    "type": "array",
                    "description": "Contains the resulting set of keywords split into item name, features and synonyms.",
                    "items": {
                        "type": "object",
                        "properties": {
                            "item_name": {
                                "type": "string",
                                "description": "Keyword identifying the item."
                            },
                            "features": {
                                "type": "array",
                                "description": "A string array stores all the features such as color, size, weight, type, brand, etc. that further describes the item.",
                                "items": {
                                    "type": "string",
                                    "description": "A string stores one feature, such as ''red'',''25 kg'',''middle size''"
                                }
                            },
                            "synonyms": {
                                "type": "array",
                                "description": "This array stores possible synonyms of the item name. We want the synonyms to be useful and common. For example, if the item''s name is ''bike'', you should find the possible synonyms is ''bicycle'', vice versa. If it has one or more synonyms, you can put all the synonyms in the array. ",
                                "items": {
                                    "type": "string",
                                    "description": "Synonyms of item name."
                                }
                            },
							"concatenated_keyword": {
                                "type": "string",
                                "description": "Concatenated keyword that is commonly used as an alternate."
                            },
							"item_name_plural": {
                                "type": "string",
                                "description": "Keyword that will keep plural of the item name."
                            }
                        },
                        "required": [
                            "item_name",
                            "item_name_plural"
                        ]
                    }
                }
            },
            "required": [
                "results"
            ]
        }
    }
}
