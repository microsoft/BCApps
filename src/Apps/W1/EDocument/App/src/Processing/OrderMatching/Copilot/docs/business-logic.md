# Business logic

Copilot matching implements AI-powered purchase order line matching using Azure OpenAI function calling.

## Matching invocation

EDocPOCopilotMatching.MatchWithCopilot is called during Prepare step:

1. **Preconditions:**
   - E-Document Service has "Copilot PO Matching Enabled" = true
   - Imported lines have "[BC] Vendor No." resolved (required for candidate filtering)
   - Azure OpenAI configuration exists (endpoint, API key, deployment)

2. **Input preparation:**
   - Load imported lines into temporary table (filters applied, sorted by line no.)
   - For each imported line, load candidate PO lines via EDocPOMatching
   - Validate candidates exist (skip lines with zero candidates)
   - Calculate token budget remaining after system prompt

3. **Batch determination:**
   - Estimate tokens per line: ~100 for imported line description + ~50 per candidate PO line
   - If total exceeds token budget (8000), split into batches
   - Each batch processed separately to AOAI, results accumulated

4. **AOAI call:**
   - Construct user prompt with imported line data and candidate PO lines
   - Call Azure OpenAI GPT-4 with function calling enabled
   - Parse function call responses
   - Execute function calls (load additional data, create match proposals)
   - Continue multi-turn conversation until AI completes all lines

5. **Result processing:**
   - Collect match proposals from AOAI function responses
   - For each proposal:
     - Validate confidence score >= 0.0 and <= 1.0
     - If confidence >= threshold: Auto-accept (create E-Doc. Order Match)
     - If confidence < threshold: Add to suggestion buffer for user review
   - Log token usage and duration to telemetry

6. **Grounding:**
   - If grounding enabled, load recent user accept/reject decisions
   - Filter last 30 days of match activity for same vendor
   - Include in next prompt as examples for AI learning

## System prompt construction

System prompt loaded from Azure Key Vault secret:

```
You are a purchase order matching assistant. Your goal is to match imported invoice
lines to existing purchase order lines based on these criteria:

1. Description similarity: Compare item descriptions using semantic understanding.
   Exact matches score 1.0, high similarity 0.8+, moderate 0.5+, low 0.0-0.5.

2. Quantity compatibility: Invoice quantity should not exceed PO outstanding quantity.
   Under-invoice (invoice < PO) is acceptable and scores 0.9.
   Over-invoice by 0-10% scores 0.7, over >10% scores 0.3.

3. Price compatibility: Invoice price should be within tolerance of PO price.
   Price difference 0-2% scores 1.0, 2-5% scores 0.8, 5-10% scores 0.6, >10% scores 0.3.

Calculate overall confidence as: 0.5 * Description + 0.25 * Quantity + 0.25 * Price

Only suggest matches with confidence >= 0.5. For confidence >= 0.7, include "auto_accept": true.

Available functions:
- GetCandidatePOLines: Retrieve PO lines for a vendor
- CreateMatch: Record a match suggestion

Process each imported line sequentially. If no good match exists, skip the line.
```

Prompt is versioned in Key Vault, enabling updates without app deployment.

## User prompt construction

User prompt contains line data formatted for AI:

```
E-document lines:
Line 10000: Description "Office supplies - Paper reams", Quantity 50, Unit Price 5.99
Line 20000: Description "Printer toner cartridges", Quantity 10, Unit Price 89.99

Purchase order lines (Vendor V001):
PO-001 Line 10000: Item 1000 "A4 Paper 500 sheets", Qty Outstanding 100, Unit Cost 5.95
PO-001 Line 20000: Item 1001 "HP Toner Black", Qty Outstanding 15, Unit Cost 89.50
PO-002 Line 10000: Item 1002 "Office Chair", Qty Outstanding 5, Unit Cost 199.99

Match imported lines to PO lines and provide confidence scores.
```

Prompt is constructed dynamically per batch, optimized for token efficiency.

## Function calling flow

AI calls defined functions to retrieve data and propose matches:

**GetCandidatePOLines function:**
```json
{
  "name": "GetCandidatePOLines",
  "parameters": {
    "vendorNo": "V001",
    "filters": {
      "itemNo": "1000",
      "dateFrom": "2024-01-01"
    }
  }
}
```

EDocPOAOAIFunction executes function:
```al
procedure Execute(Arguments: JsonObject): Variant
var
    VendorNo: Code[20];
    PurchaseLine: Record "Purchase Line";
begin
    Arguments.Get('vendorNo', VendorNo);
    PurchaseLine.SetRange("Pay-to Vendor No.", VendorNo);
    // Apply additional filters from Arguments
    exit(BuildPOLineJson(PurchaseLine)); // Return JSON array
end;
```

AI receives PO line data and continues with matching.

**CreateMatch function:**
```json
{
  "name": "CreateMatch",
  "parameters": {
    "importedLineNo": 10000,
    "poDocumentNo": "PO-001",
    "poLineNo": 10000,
    "confidence": 0.85,
    "reason": "Description matches and quantity compatible"
  }
}
```

EDocPOAOAIFunction executes function:
```al
procedure Execute(Arguments: JsonObject): Variant
var
    TempMatchProposal: Record "E-Doc. PO Match Prop. Buffer" temporary;
begin
    Arguments.Get('importedLineNo', TempMatchProposal."Imported Line No.");
    Arguments.Get('poDocumentNo', TempMatchProposal."PO Document No.");
    Arguments.Get('confidence', TempMatchProposal.Confidence);
    Arguments.Get('reason', TempMatchProposal."Match Reason");
    TempMatchProposal.Insert();
    exit('Match proposal created'); // Confirmation to AI
end;
```

AI receives confirmation and continues with next line.

## Confidence calculation details

AI calculates confidence using weighted factors:

**Description similarity (50% weight):**
- Uses semantic embeddings (vector similarity) rather than exact string matching
- Handles synonyms: "Paper reams" matches "A4 Paper 500 sheets" with 0.8 similarity
- Handles abbreviations: "Printer toner" matches "HP Toner Black" with 0.9 similarity
- Multi-word matching: Considers word order and importance (nouns weighted higher)

**Quantity compatibility (25% weight):**
```
If ImportedQty <= POOutstandingQty:
    Score = 1.0 - (POOutstandingQty - ImportedQty) / POOutstandingQty * 0.1
    // Under-invoicing scores high (0.9-1.0)
Else:
    Excess = (ImportedQty - POOutstandingQty) / POOutstandingQty
    If Excess <= 0.1: Score = 0.7
    Else: Score = 0.3
    // Over-invoicing scores low
```

**Price compatibility (25% weight):**
```
Variance = Abs(ImportedPrice - POPrice) / POPrice
If Variance <= 0.02: Score = 1.0
Else If Variance <= 0.05: Score = 0.8
Else If Variance <= 0.10: Score = 0.6
Else: Score = 0.3
```

**Final confidence:**
```
Confidence = 0.5 * DescriptionScore + 0.25 * QuantityScore + 0.25 * PriceScore
```

Confidence ranges:
- 0.9-1.0: Very high confidence, rare false positives
- 0.7-0.9: High confidence, acceptable for auto-accept
- 0.5-0.7: Moderate confidence, suggest for user review
- 0.0-0.5: Low confidence, discard (don't suggest)

## Auto-accept logic

Matches above threshold are automatically accepted:

```al
if TempMatchProposal.Confidence >= CopilotConfidenceThreshold then begin
    CreateEDocOrderMatch(TempMatchProposal);
    TempMatchProposal.Status := TempMatchProposal.Status::Accepted;
    TempMatchProposal."Accepted Automatically" := true;
end else begin
    TempMatchProposal.Status := TempMatchProposal.Status::"Pending Review";
    AddToSuggestionList(TempMatchProposal);
end;
```

Auto-accepted matches create E-Doc. Order Match records immediately. User never sees these suggestions unless they explicitly open "Review Auto-Accepted Matches" page.

## User review workflow

Suggestions below threshold require user review:

1. **Display suggestions:**
   - Open E-Doc. PO Copilot Prop. page after matching completes
   - Show grid with columns:
     - Imported Line No. + Description
     - PO Document No. + Line No. + Description
     - Confidence (bar chart visual)
     - Match Reason (AI explanation)
     - Accept/Reject buttons

2. **User decision:**
   - User clicks Accept button: Create E-Doc. Order Match, log acceptance
   - User clicks Reject button: Discard proposal, log rejection with reason
   - User clicks "Accept All >= 0.6": Batch accept moderate-confidence matches

3. **Grounding feedback:**
   - Accepted suggestions log to Activity Log with "User Confirmed" flag
   - Rejected suggestions log with rejection reason (if provided)
   - Feedback accumulates for use in future matching sessions

4. **Unresolved lines:**
   - Lines with no accepted suggestions remain unmatched
   - User can manually match these lines via standard matching UI
   - Or leave unmatched to create standalone invoice lines

## Grounding implementation

Grounding teaches AI from user decisions:

1. **Capture feedback:**
   - When user accepts suggestion, log Activity Log entry:
     ```
     Type: AI Decision Confirmed
     Context: Matched imported line 10000 to PO-001 line 10000
     Reason: User accepted Copilot suggestion (confidence 0.75)
     ```
   - When user rejects suggestion, log with rejection reason:
     ```
     Type: AI Decision Rejected
     Context: Rejected match of imported line 20000 to PO-002 line 10000
     Reason: User note "Wrong item, descriptions don't actually match"
     ```

2. **Build grounding context:**
   - Query Activity Log for last 30 days, filter by vendor
   - Extract confirmed matches: Imported description → PO description → Accepted
   - Extract rejected matches: Imported description → PO description → Rejected
   - Format as examples for system prompt

3. **Include in next prompt:**
   ```
   Previous matching decisions for this vendor:
   - "Office supplies - Paper reams" matched to "A4 Paper 500 sheets" (Accepted)
   - "Printer toner cartridges" matched to "HP Toner Black" (Accepted)
   - "Computer monitor" matched to "Office Chair" (Rejected - wrong item type)

   Use these examples to guide current matching decisions.
   ```

4. **AI learning:**
   - AI adjusts confidence scores based on examples
   - Patterns from accepted matches are reinforced (similar descriptions score higher)
   - Patterns from rejected matches are avoided (dissimilar items score lower)
   - Over time, AI learns company-specific terminology and preferences

## Cost optimization

AOAI calls consume tokens, incurring cost:

**Token reduction strategies:**
- Truncate long descriptions to 100 characters (preserve key terms)
- Limit candidate PO lines to 10 per imported line (filter by relevance)
- Cache system prompt (don't re-send on each call)
- Use streaming responses (process as tokens arrive, reduce latency)

**Batching strategy:**
- Process imported lines in batches of 10 (typical token usage ~2000 per batch)
- Run multiple batches in parallel (up to 5 concurrent AOAI calls)
- Balance token usage against API rate limits (1000 tokens/second limit)

**Token usage tracking:**
```al
Telemetry.LogMessage('Copilot PO Matching Token Usage',
    StrSubstNo('Prompt tokens: %1, Completion tokens: %2, Total cost: $%3',
        PromptTokens, CompletionTokens, TotalCost));
```

Finance can analyze telemetry to optimize prompt efficiency and reduce cost per matched line.

## Error handling

AOAI calls can fail for various reasons:

**API errors:**
- 401 Unauthorized: Azure OpenAI credentials invalid → Fall back to manual matching
- 429 Rate Limit: Too many requests → Retry with exponential backoff (1s, 2s, 4s)
- 503 Service Unavailable: Azure OpenAI down → Fall back to manual matching
- Timeout (>60s): Long-running request → Cancel and retry with smaller batch

**Response errors:**
- Invalid JSON: AI returned malformed response → Log error, fall back to manual
- Missing confidence: AI omitted confidence score → Assign default 0.5
- Invalid function call: AI called undefined function → Log error, request correction
- Hallucinated data: AI invented PO numbers that don't exist → Discard match

All errors log to E-Document Log with context for troubleshooting. Users see message "Copilot matching failed, use manual matching" and can proceed without AI.
