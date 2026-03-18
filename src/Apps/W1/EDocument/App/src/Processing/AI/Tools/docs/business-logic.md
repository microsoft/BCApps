# Business logic

AI tools implement specialized data resolution and matching logic using AOAI Function pattern.

## GL account matching

EDocGLAccountMatching suggests GL accounts for non-item purchase lines:

1. **Trigger conditions:**
   - Line has "[BC] Purchase Type" = blank or G/L Account
   - Line has "[BC] Purchase Type No." = blank (no account assigned yet)
   - Line description is not empty

2. **Context preparation:**
   - Load Chart of Accounts filtered by:
     - Direct Posting = true (can post directly)
     - Income/Balance = Income Statement (expense accounts)
     - Account Type = Posting (not heading or total)
   - Apply vendor posting group filters (reduce irrelevant accounts)
   - Load last 10 purchases for this vendor (historical patterns)

3. **Prompt construction:**
   ```
   System: You are a GL account assignment assistant. Analyze the line description
   and suggest the most appropriate expense account.

   Available GL accounts:
   - 5100 Office Supplies (Posted 150 times, avg amount $200)
   - 5200 IT Services (Posted 80 times, avg amount $1500)
   - 5300 Professional Fees (Posted 45 times, avg amount $5000)

   Historical purchases from this vendor:
   - "Microsoft Office subscription" → 5200 IT Services
   - "Printer toner cartridge" → 5100 Office Supplies

   Imported line:
   Description: "Adobe Creative Cloud annual license"
   Amount: $599

   Use function CreateSuggestion to propose GL account with confidence score.
   ```

4. **Function execution:**
   - AI calls CreateSuggestion with parameters:
     ```json
     {
       "glAccountNo": "5200",
       "confidence": 0.85,
       "reason": "Software subscription matches historical IT Services pattern"
     }
     ```
   - Tool validates GL Account exists and is postable
   - If confidence >= 0.8: Auto-apply to line "[BC] Purchase Type No."
   - If confidence 0.6-0.8: Add to suggestion buffer for review
   - If confidence < 0.6: Discard

5. **Result application:**
   - High-confidence matches update E-Document Purchase Line:
     ```al
     EDocPurchaseLine."[BC] Purchase Type" := "Purchase Type"::"G/L Account";
     EDocPurchaseLine."[BC] Purchase Type No." := "5200";
     EDocPurchaseLine.Modify(true);
     ```
   - Log to Activity Log with confidence and reason
   - Track token usage and latency for telemetry

## Historical vendor matching

EDocHistoricalMatching assigns vendors based on past purchase patterns:

1. **Trigger conditions:**
   - E-Document Purchase Header has "[BC] Vendor No." = blank
   - Header has "Vendor Company Name" populated (external identifier)
   - Historical matching is enabled on service

2. **Historical data query:**
   - Query E-Doc. Vendor Assign History for similar vendor names:
     ```al
     VendorHistory.SetFilter("External Vendor Name", '@*%1*', VendorCompanyName);
     VendorHistory.SetRange("Use Count", '>5'); // Min frequency
     VendorHistory.SetFilter("Last Assignment Date", '>=%1', CalcDate('-90D', Today));
     ```
   - Load top 10 matches by Use Count (most frequent assignments)

3. **Prompt construction:**
   ```
   System: You are a vendor assignment assistant. Match the external vendor name
   to Business Central vendor based on historical assignments.

   Imported vendor: "ACME CORPORATION INC"

   Historical assignments:
   - "Acme Corp Ltd" → V001 (assigned 15 times, last used 2024-03-01)
   - "ACME Inc." → V001 (assigned 8 times, last used 2024-02-15)
   - "ABC Corporation" → V002 (assigned 3 times, last used 2024-01-10)

   Use function CreateVendorSuggestion to propose vendor with confidence score.
   Consider name variations, abbreviations, and legal entity suffixes.
   ```

4. **Function execution:**
   - AI analyzes name similarity (fuzzy matching, entity name normalization)
   - Returns suggestion:
     ```json
     {
       "vendorNo": "V001",
       "confidence": 0.95,
       "reason": "Name matches historical variants Acme Corp Ltd and ACME Inc."
     }
     ```
   - If confidence >= 0.8: Auto-assign vendor
   - If confidence 0.6-0.8: Suggest for review
   - If confidence < 0.6: Leave blank (require manual resolution)

5. **History update:**
   - When user accepts suggestion (or auto-applied), update history:
     ```al
     VendorHistory.Get("ACME CORPORATION INC");
     VendorHistory."Use Count" += 1;
     VendorHistory."Last Assignment Date" := CurrentDateTime;
     VendorHistory.Modify();
     ```
   - Add external name variant if not already tracked
   - History improves accuracy for future imports from same vendor

## Deferral matching

EDocDeferralMatching identifies lines requiring deferral treatment:

1. **Trigger conditions:**
   - Line has "[BC] Purchase Type No." assigned (item or GL account)
   - Line description contains keywords: subscription, annual, insurance, maintenance, license, warranty
   - Line amount is significant (configurable threshold, default $500)

2. **Context preparation:**
   - Load Deferral Template table (predefined deferral rules)
   - Extract date patterns from description (annual, monthly, quarterly)
   - Calculate potential deferral period from dates in document

3. **Prompt construction:**
   ```
   System: You are a deferral classification assistant. Identify lines that represent
   multi-period expenses requiring deferral.

   Available deferral templates:
   - ANNUAL: Defer over 12 months
   - QUARTERLY: Defer over 3 months
   - INSURANCE: Defer based on policy period

   Imported line:
   Description: "Microsoft 365 E5 license annual subscription"
   Amount: $1,200
   Invoice Date: 2024-03-15

   Identify if deferral is needed and suggest template with start/end dates.
   ```

4. **Function execution:**
   - AI identifies deferral need and period:
     ```json
     {
       "deferralTemplateCode": "ANNUAL",
       "startDate": "2024-03-15",
       "endDate": "2025-03-14",
       "confidence": 0.9,
       "reason": "Annual license clearly indicates 12-month period"
     }
     ```
   - If confidence >= 0.8: Auto-apply deferral template
   - If confidence 0.6-0.8: Suggest for review with calculated dates

5. **Result application:**
   - Update purchase line with deferral:
     ```al
     PurchaseLine."Deferral Code" := "ANNUAL";
     PurchaseLine."Deferral Start Date" := StartDate;
     PurchaseLine."Deferral End Date" := EndDate;
     ```
   - Deferral schedules are created when invoice is posted

## Similar description search

EDocSimilarDescriptions finds historical purchases with similar line descriptions:

1. **Invocation:**
   - Called by other AI tools (GL account matching, historical matching)
   - Called from UI: User selects imported line, clicks "Find Similar Purchases"

2. **Search execution:**
   - Normalize search description (remove punctuation, convert to lowercase)
   - Query E-Doc. Purchase Line History:
     ```al
     // First try exact match
     LineHistory.SetRange("Description Hash", DescriptionHash);
     if LineHistory.FindSet() then
         return Results;

     // Fall back to partial match
     LineHistory.SetFilter(Description, '@*%1*', NormalizedDescription);
     LineHistory.SetCurrentKey("Use Count"); // Order by frequency
     LineHistory.Ascending(false);
     if LineHistory.FindSet() then
         return Top10Results;
     ```

3. **AOAI similarity scoring:**
   - If partial matches found, call AOAI to score similarity:
     ```
     System: Score similarity between descriptions on scale 0.0-1.0.

     Search description: "Microsoft Office 365 subscription"

     Candidates:
     1. "Microsoft 365 E5 license" (Item 1000, used 25 times)
     2. "Office 365 Business Premium" (Item 1001, used 18 times)
     3. "Adobe Creative Cloud" (Item 1010, used 12 times)

     Return JSON array with similarity scores.
     ```

4. **Result ranking:**
   - AI returns similarity scores:
     ```json
     [
       {"candidate": 1, "score": 0.95, "reason": "Same product family"},
       {"candidate": 2, "score": 0.90, "reason": "Very similar, different tier"},
       {"candidate": 3, "score": 0.30, "reason": "Different software vendor"}
     ]
     ```
   - Combine similarity score with usage frequency:
     ```
     Ranking = (0.7 * SimilarityScore) + (0.3 * NormalizedUseCount)
     ```
   - Return top 5 ranked results

5. **UI display:**
   - E-Doc. Similar Purchases page shows results:
     - Historical description + similarity score
     - Item No. or GL Account No. assigned
     - Use count (frequency)
     - Last used date
     - "Apply" button to use assignment for current line
   - User clicks Apply: Copy Item No./GL Account No. to imported line

## Common processing pattern

All AI tools follow this workflow:

1. **Check prerequisites:**
   - Azure OpenAI configured
   - Tool enabled on service
   - Trigger conditions met

2. **Load context:**
   - Query relevant master data (accounts, items, history)
   - Filter to reduce token usage (top N results only)
   - Format as structured data for AOAI

3. **Construct prompt:**
   - System prompt: Tool purpose and instructions
   - User prompt: Imported line data + context
   - Function definitions: Available tools AI can call

4. **Call AOAI:**
   - Send prompt to GPT-4 deployment
   - Enable function calling
   - Set temperature = 0.1 (deterministic results)
   - Set max tokens = 1000 (sufficient for most responses)

5. **Execute functions:**
   - Parse function calls from AOAI response
   - Execute each function (load data, create suggestion)
   - Return results to AOAI for next turn

6. **Process suggestions:**
   - Validate confidence scores
   - Auto-apply high-confidence suggestions
   - Buffer moderate-confidence for user review
   - Discard low-confidence

7. **Log and track:**
   - Log to Activity Log with confidence and reason
   - Track token usage for cost analysis
   - Track accuracy for model improvement
   - Update historical data for future learning

## Error handling

AI tools implement robust error handling:

**AOAI API errors:**
- 429 Rate Limit: Retry with exponential backoff, max 3 attempts
- 503 Service Unavailable: Log warning, skip tool (don't fail import)
- Timeout: Cancel request after 30s, log warning, skip tool

**Response validation errors:**
- Invalid confidence: Set to 0.5 (neutral)
- Invalid GL account: Discard suggestion, log error
- Invalid deferral dates: Discard suggestion, request correction

**Data errors:**
- Empty history: Log info message, skip historical matching
- No matching accounts: Log warning, leave line for manual resolution
- Ambiguous suggestions: Present all to user for disambiguation

All errors log to E-Document Log with context. Import continues even if AI tools fail (degrades to manual resolution).

## Performance optimization

AI tools run during Prepare step (batch processing):

**Optimization strategies:**
- Parallel processing: Run multiple tools concurrently (GL account + deferral)
- Batch function calls: Group multiple lines into single AOAI request
- Cache context: Load chart of accounts once, reuse for all lines
- Limit results: Query top 10 historical matches (not all)

**Typical performance (per document):**
- GL account matching: 2-5 seconds (1 AOAI call per 5 lines)
- Historical vendor matching: 1-2 seconds (1 AOAI call per header)
- Deferral matching: 1-3 seconds (1 AOAI call per 5 lines)
- Similar description search: <1 second (local query + optional AOAI)

Total AI processing adds 5-10 seconds to Prepare step for typical 10-line invoice.
