# Business logic

Structure handlers transform unstructured e-document blobs into structured format for field extraction.

## MLLM extraction workflow

EDocumentMLLMHandler.StructureReceivedEDocument implements AI-powered extraction:

1. **Capability check:**
   - Verify Azure OpenAI configuration exists (endpoint, API key)
   - Check Copilot capability registration (required for MLLM features)
   - If missing, fall back to ADI immediately

2. **Schema generation:**
   - Call EDocMLLMSchemaHelper.GetUBLSchema()
   - Generate JSON schema for invoice fields:
     ```json
     {
       "Vendor": {"Name": "string", "TaxId": "string", "Address": "string"},
       "Invoice": {"Number": "string", "Date": "date", "DueDate": "date"},
       "Lines": [{"Description": "string", "Quantity": "number", "Price": "number"}]
     }
     ```
   - Schema includes field descriptions and validation rules

3. **Prompt construction:**
   - Load system prompt from resource: "Prompts/EDocMLLMExtraction-SystemPrompt.md"
   - System prompt instructs AI to extract only visible values, return JSON only
   - Build user prompt: "Extract invoice data into this UBL JSON structure: {schema}"
   - Convert PDF to base64: `data:application/pdf;base64,{base64_content}`
   - Construct AOAI message with vision capability:
     ```al
     AOAIUserMessage.AddText(UserPrompt);
     AOAIUserMessage.AddImage(Base64PdfData);
     ```

4. **API call:**
   - Call Azure OpenAI GPT-4 Vision deployment
   - Set max tokens = 4000 (sufficient for typical invoice)
   - Set temperature = 0.1 (deterministic extraction)
   - Timeout = 60 seconds
   - Log start time for duration measurement

5. **Response parsing:**
   - Receive AOAI response as text
   - Validate response is valid JSON (JsonObject.ReadFrom)
   - Check response contains required fields (vendor name OR address)
   - If validation fails, log error and fall back to ADI
   - If validation succeeds, extract JSON text

6. **Result packaging:**
   - Create IStructuredDataType implementation wrapping JSON
   - Set FileFormat = JSON
   - Set ReadIntoDraftImpl = MLLM (indicates source for telemetry)
   - Return to Structure step for storage

7. **Telemetry:**
   - Log token usage (prompt tokens, completion tokens, total)
   - Log duration (API call time)
   - Log success/failure status
   - Track line count extracted
   - Report via Feature Telemetry for usage analysis

## ADI fallback workflow

When MLLM fails, FallbackToADI attempts alternative extraction:

1. **Determine fallback strategy:**
   - If blob is PDF: Requires OCR text extraction first
   - If blob is XML/JSON: Can use directly with path extraction

2. **For PDF blobs:**
   - Check if OCR service is configured (Azure Document Intelligence)
   - If not configured, fail import (no fallback available)
   - If configured:
     - Convert PDF to image pages
     - Call OCR API to extract text per page
     - Concatenate text from all pages
     - Use text extraction heuristics to identify fields:
       - "Invoice No:" followed by alphanumeric → Sales Invoice No.
       - "Date:" followed by date format → Invoice Date
       - "Total:" followed by amount → Total Amount
     - Build simple JSON from extracted fields
     - Return as IStructuredDataType

3. **For XML/JSON blobs:**
   - Validate blob is well-formed (XML.Parse or JSON.ReadFrom)
   - Wrap in IStructuredDataType without transformation
   - Set ReadIntoDraftImpl = ADI
   - Return for path-based extraction

4. **Fallback logging:**
   - Log warning: "MLLM extraction failed, falling back to ADI"
   - Include failure reason (API error, validation failure, missing fields)
   - Track fallback rate in telemetry for reliability monitoring

## Schema customization

EDocMLLMSchemaHelper generates UBL schema dynamically:

1. Load base UBL schema (standard invoice fields)
2. Query E-Doc. Purch. Line Field Setup for service-specific custom fields
3. For each custom field:
   - Add to schema with appropriate JSON type:
     - Text/Code → "string"
     - Decimal → "number"
     - Date → "date" (ISO 8601 format)
     - Boolean → "boolean"
     - Integer → "integer"
   - Include field description from setup (helps AI understand field purpose)
   - Include validation constraints (min/max values, required/optional)
4. Generate final JSON schema as text
5. Cache schema per service (avoid regenerating on each extraction)

Custom fields in schema example:
```json
{
  "Lines": [
    {
      "Description": "string",
      "Quantity": "number",
      "CustomTaxCode": "string (Partner-specific tax classification)"
    }
  ]
}
```

AI extracts custom fields alongside standard fields, with results stored in E-Document Line - Field table.

## PEPPOL-specific handling

EDocumentPEPPOLHandler extends base structure logic for PEPPOL BIS 3.0:

1. **Schema validation:**
   - Verify root element is `<Invoice>` with PEPPOL namespace
   - Check schemaLocation references PEPPOL BIS 3.0 XSD
   - Validate all mandatory PEPPOL elements present

2. **Extension extraction:**
   - Extract PEPPOL extensions not in base UBL:
     - Invoice type code (380 = commercial invoice, 381 = credit note)
     - Delivery party details
     - Payment means extensions (BIC, IBAN formatting)
     - Tax category codes (S = standard, Z = zero-rated)

3. **Business rules:**
   - Apply PEPPOL validation rules (cardinality, code lists)
   - Check line IDs are sequential
   - Validate tax amounts sum to document tax total
   - Verify currency codes are ISO 4217

4. **Result packaging:**
   - Return IStructuredDataType with PEPPOL-validated XML
   - Include metadata: PEPPOL profile ID, customization ID
   - Flag any validation warnings for user review

PEPPOL handler ensures imported documents conform to PEPPOL business rules before creating purchase drafts.

## Error handling

Structure handlers implement comprehensive error handling:

**MLLM errors:**
- API error 401 (unauthorized): Log "Azure OpenAI credentials invalid", fall back to ADI
- API error 429 (rate limit): Retry with exponential backoff (1s, 2s, 4s), then fall back
- API error 503 (service unavailable): Fall back to ADI immediately
- Response validation failure: Log specific missing fields, fall back to ADI
- JSON parse failure: Log "MLLM returned invalid JSON", fall back to ADI

**ADI errors:**
- XML parse failure: Log "Invalid XML format", fail import (no further fallback)
- JSON parse failure: Log "Invalid JSON format", fail import
- OCR error (PDF): Log "OCR service unavailable", fail import
- Empty result: Log "No data extracted", fail import

All errors log to E-Document Log with:
- Error type (API error, validation failure, parse error)
- Error message (detailed description)
- Attempted fallback (yes/no)
- Fallback result (success/failure)

Users can review error logs to troubleshoot extraction issues.

## Performance optimization

MLLM extraction is I/O bound (API call latency):

**Optimization strategies:**
- Batch imports process multiple documents in parallel (up to 5 concurrent AOAI calls)
- Schema caching reduces prompt size (schema generated once per service, reused)
- Streaming responses reduce latency (process JSON as it arrives vs. waiting for complete response)
- Retry backoff prevents rate limit cascades (exponential delay between retries)

**Performance metrics (typical):**
- MLLM extraction: 5-15 seconds per invoice (includes API latency + JSON parse)
- ADI extraction: <1 second per invoice (local XPath/JSONPath evaluation)
- Fallback overhead: +2-5 seconds (OCR + text extraction for PDF)

Large batches benefit from parallel MLLM processing, reducing total import time by 70-80% vs. sequential processing.
