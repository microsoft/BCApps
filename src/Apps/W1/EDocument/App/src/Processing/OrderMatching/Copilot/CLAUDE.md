# Copilot matching

Copilot matching provides AI-powered purchase order line matching using Azure OpenAI. It analyzes imported invoice line descriptions and suggests matches to existing PO lines based on semantic similarity, quantity compatibility, and price variance. This subsystem implements the AOAI Function pattern with grounding and confidence scoring.

## How it works

EDocPOCopilotMatching codeunit orchestrates AI-powered matching. It receives imported lines and candidate PO lines, constructs prompts with line descriptions and constraints, calls Azure OpenAI GPT-4 with function calling capability, and parses returned match suggestions with confidence scores.

The system builds prompts dynamically using a system prompt (loaded from Azure Key Vault for security) and user prompts containing line data. The system prompt instructs the AI to match lines based on description similarity, quantity feasibility, and price reasonableness. Function definitions describe available tools (GetCandidatePOLines, CreateMatch) that the AI can call to retrieve data and record matches.

AOAI Function responses are parsed by EDocPOAOAIFunction codeunit, which implements the AOAI Function interface. Function calls from AI are executed (loading PO lines, creating match proposals), results are returned to AI context, and the AI continues until all lines are processed. This multi-turn conversation enables the AI to refine matches based on retrieved data.

Match proposals are stored in E-Doc. PO Match Prop. Buffer temporary table with confidence scores. Proposals above the configured threshold (default 0.7) are auto-accepted and converted to E-Doc. Order Match records. Proposals below threshold are presented to users in E-Doc. PO Copilot Prop. page for review and manual acceptance/rejection.

Grounding captures user feedback on suggestions. When users accept or reject Copilot proposals, their decisions are logged to Activity Log. Future matching sessions include this feedback in the prompt context, teaching the AI company-specific matching preferences over time.

## Things to know

- **GPT-4 required** -- Copilot matching uses GPT-4 models (not GPT-3.5) due to function calling capability requirements. GPT-4 Turbo provides better accuracy at lower cost per match.
- **System prompt in Key Vault** -- The system prompt containing matching instructions is stored in Azure Key Vault rather than code. This enables prompt updates without app updates, supporting A/B testing and continuous improvement.
- **Token budget management** -- Each matching session has a token budget (default 8000 tokens). If imported lines + candidate PO lines exceed budget, lines are batched into multiple AI calls to avoid truncation.
- **Confidence threshold is configurable** -- Default 0.7 threshold can be adjusted per service in E-Doc. PO Matching Setup. Higher thresholds (0.8-0.9) reduce auto-accept rate but improve accuracy. Lower thresholds (0.5-0.6) increase automation but may require more user review.
- **Cost tracking** -- Each AOAI call logs token usage (prompt + completion tokens) to telemetry. Finance can analyze cost per match and optimize prompt efficiency to reduce Azure OpenAI spend.
- **Grounding is automatic** -- User accept/reject decisions automatically feed back into future prompts. No explicit training step required. Grounding accumulates over time, improving accuracy for company-specific patterns.
- **Fallback to manual** -- If AOAI API is unavailable (network error, quota exceeded), matching falls back to manual mode. Users see message "Copilot unavailable, use manual matching" and can proceed without AI.
