# AI

AI-powered tools for the e-document import pipeline, invoked through BC's Copilot framework. Each tool is a specialized codeunit that handles one aspect of the matching problem.

## Tool architecture

`EDocAIToolProcessor.Codeunit.al` is the orchestrator that registers and dispatches to individual AI tools. The Copilot framework calls this processor, which selects and invokes the appropriate tools based on the matching context.

`EDocHistoricalMatchBuffer.Table.al` and `EDocLineMatchBuffer.Table.al` are temporary buffer tables that hold intermediate results during AI processing -- they accumulate candidate matches from multiple tools before a final ranking step.

## Tools

Each tool in the `Tools/` subfolder handles a different matching strategy:

- `EDocHistoricalMatching.Codeunit.al` -- looks up E-Doc. Purchase Line History to find how previous invoices from the same vendor were matched. If vendor X's line "Widget A" was mapped to item 1000 three times before, it suggests the same mapping again. This is the highest-confidence tool.
- `EDocGLAccountMatching.Codeunit.al` -- for invoice lines that do not map to inventory items, suggests G/L accounts based on the line description and existing account mappings.
- `EDocDeferralMatching.Codeunit.al` -- identifies lines that match deferral patterns (subscriptions, prepayments) and suggests appropriate deferral templates.
- `EDocSimilarDescriptions.Codeunit.al` -- fuzzy text matching for cases where vendor product codes do not match the buyer's item numbers but descriptions are semantically similar.

System prompts that define the LLM behavior live in `.resources/Prompts/` at the app level. The tools pass structured context (line data, history, account lists) and the LLM returns ranked match proposals.
