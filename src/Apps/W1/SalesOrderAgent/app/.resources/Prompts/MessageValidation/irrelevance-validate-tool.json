{
    "type": "function",
    "function": {
        "name": "Validate",
        "description": "Validates the message contents provided to the Sales Order Agent.",
        "parameters": {
            "type": "object",
            "properties": {
                "detailedReason": {
                    "type": "string",
                    "description": "A thorough step-by-step reasoning whether the message is relevant or not using the guidelines above (min 3 sentences)."
                },
                "hasSupportedRequest": {
                    "type": "boolean",
                    "description": "True if the message contains a request related to the agent responsibilities, false otherwise."
                },
                "hasNotSupportedRequest": {
                    "type": "boolean",
                    "description": "True if the message contains a request unrelated to the agent responsibilities, false otherwise."
                },
                "isReactionToPreviousMessage": {
                    "type": "boolean",
                    "description": "True if the message acts as an acknowledgment, a confirmation, a complaint, a feedback or a reaction to previous messages. False otherwise."
                },
                "reason": {
                    "type": "string",
                    "description": "The reason why the message is irrelevant (1-2 sentences) in the language of the user, {{LANGUAGE}}."
                }
            }
        }
    }
}
