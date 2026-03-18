# AI tools

AI tools provide specialized AOAI Function implementations for data resolution and matching during e-document import. This subsystem implements four AI-powered features: GL account matching (suggest accounts from line descriptions), historical vendor matching (assign vendors based on past patterns), deferral matching (identify deferral lines), and similar description search (find past purchases with similar text). All tools implement the AOAI Function interface for uniform integration with the AI processing pipeline.

## How it works

Each AI tool is a codeunit implementing both AOAI Function interface (for prompt/execute contract) and IEDocAISystem interface (for integration with import processing). Tools are called during the Prepare step after basic master data resolution completes. They receive E-Document Purchase Line records with [BC] Vendor No. populated and return suggestions for remaining unresolved fields.

EDocGLAccountMatching analyzes line descriptions for non-item lines (services, charges) and suggests GL accounts. It loads the chart of accounts, constructs a prompt with line description + available accounts, calls AOAI with function calling, and receives suggested account numbers with explanations. Suggestions above confidence threshold are auto-applied; lower-confidence suggestions are presented for user review.

EDocHistoricalMatching queries E-Doc. Purchase Line History table for similar past purchases, sends descriptions to AOAI for similarity scoring, and suggests vendors or GL accounts based on highest-scoring historical matches. This learns from user corrections over time, improving accuracy for company-specific purchasing patterns.

EDocDeferralMatching identifies lines that should be deferred (subscriptions, insurance, multi-period services) based on description keywords and date patterns. It uses AOAI to classify lines as immediate expense vs. deferred expense and suggests deferral templates when applicable.

EDocSimilarDescriptions provides similarity search across historical purchase lines. Given a description, it finds past lines with similar text and returns their item/account assignments. This supports both AI-powered matching (used by other tools) and user-initiated search (from review UI).

All tools share a common processing pattern: load context data, construct AOAI prompt with function definitions, execute function calls from AI responses, validate suggestions, apply high-confidence suggestions automatically, and present low-confidence suggestions for user review. Activity Log tracks all AI decisions with confidence scores and explanations for audit.

## Things to know

- **Tools run sequentially** -- AI tools execute in order during Prepare step: Historical matching → GL account matching → Deferral matching. Each tool builds on results from previous tools (e.g., deferral matching uses GL accounts assigned by earlier tools).
- **Function calling pattern** -- All tools use AOAI Function interface with tool definitions. AI can call GetAvailableAccounts(), SearchHistoricalPurchases(), or CreateSuggestion() functions to retrieve data and record decisions.
- **Confidence-based auto-apply** -- Suggestions with confidence >= 0.8 are applied automatically without user review. Confidence 0.6-0.8 requires user review. Confidence < 0.6 is discarded. Thresholds are configurable per tool.
- **Historical data lifecycle** -- E-Doc. Purchase Line History is rebuilt monthly via batch job analyzing last 90 days of posted purchase invoices. Old history is archived to prevent table bloat and maintain query performance.
- **Context window optimization** -- Tools limit context size to fit within AOAI token limits. Historical matching sends top 10 similar purchases (not all matches), GL account matching sends only relevant accounts (filtered by posting group), deferral matching sends date patterns only (not full line data).
- **Grounding per tool** -- Each tool tracks user accept/reject decisions independently. Rejecting a GL account suggestion doesn't affect historical vendor matching accuracy. Tools learn from feedback specific to their domain.
- **Telemetry granularity** -- Each tool logs token usage, latency, and accuracy metrics separately. This enables cost optimization per tool (e.g., disable expensive tools with low accuracy, optimize prompts for high-value tools).
