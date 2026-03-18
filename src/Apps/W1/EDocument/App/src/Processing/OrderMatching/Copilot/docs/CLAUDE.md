# Copilot order matching

AI-powered matching proposals for the V1 purchase order matching flow. Uses Azure OpenAI to suggest which imported e-document lines correspond to which purchase order lines, then grounds the AI suggestions against actual quantity and cost constraints.

## How it works

`EDocPOCopilotMatching` builds prompts from e-document imported lines and purchase order lines, filtering to only include PO lines within a cost difference threshold (configurable in `Purchases & Payables Setup."E-Document Matching Difference"`). It sends these to Azure OpenAI via the AOAI SDK using a function-calling pattern -- the model returns structured match proposals through `EDocPOAOAIFunction`.

The AI proposals are stored in `E-Doc. PO Match Prop. Buffer` (temporary table) and optionally "grounded" -- meaning each AI-suggested match is validated against actual available quantities by calling `EDocLineMatching.MatchOneToOne`. Proposals that fail grounding (zero matched quantity) are deleted.

The `EDocPOCopilotProp` page displays the AI proposals for user review before they are accepted into the real match table.

## Things to know

- The system prompt is fetched from Azure Key Vault (`EDocumentMappingPromptV2`), not hardcoded. If the secret is missing, the entire Copilot matching silently fails with a telemetry error.

- Prompt batching: if the combined token count exceeds 22,000 (about two-thirds of the GPT-4 32K limit), the system splits into multiple API calls. Each call processes whatever lines have accumulated since the last send.

- Temperature is set to 0 for deterministic matching. The model is GPT-4.1 Latest, and the function-calling pattern means the model returns structured JSON, not free text.

- Grounding is optional (`SetGrounding` method). When enabled, every AI proposal is validated by actually attempting the match. When disabled, proposals are taken at face value -- useful for testing but risky in production.

- The Copilot capability is registered as `"E-Document Matching Assistance"` and only on SaaS infrastructure. On-premises deployments do not get the registration.

- Cost filtering happens before prompting: only PO lines within the `CostDifferenceThreshold` of the imported line's cost (accounting for discounts) are included in the prompt. This pre-filtering is critical for prompt quality and token efficiency.
