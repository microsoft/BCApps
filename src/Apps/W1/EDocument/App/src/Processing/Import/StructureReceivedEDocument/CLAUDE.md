# Structure handlers

Structure handlers implement IStructureReceivedEDocument interface to parse unstructured blobs into structured data. This subsystem provides MLLM-based AI extraction (for PDFs and unstructured content) and ADI-based path extraction (for XML/JSON), with automatic fallback between methods.

## How it works

Structure handlers are called during the Structure step to transform raw e-document blobs into structured format suitable for field extraction. The main handlers are EDocumentMLLMHandler (AI-powered extraction using Azure OpenAI vision models) and EDocumentADIHandler (path-based extraction using XPath/JSONPath for XML/JSON).

EDocumentMLLMHandler converts PDF documents to base64, constructs a prompt with UBL JSON schema definition, and calls Azure OpenAI with vision capability. The AI analyzes the PDF layout, extracts invoice fields, and returns structured JSON conforming to the UBL schema. The handler validates the response contains minimum required fields (vendor name or address) and returns an IStructuredDataType containing the JSON.

EDocumentADIHandler handles already-structured formats (XML, JSON). It validates the blob is well-formed, wraps it in IStructuredDataType interface without transformation, and returns it for direct ADI extraction. This zero-copy approach is performant for structured formats.

MLLM fallback logic: When MLLM extraction fails (API error, invalid response, missing required fields), the system automatically calls FallbackToADI to attempt path-based extraction. For PDF, this requires OCR conversion to extract text, then text-to-structure transformation. The fallback ensures processing continues even when AI services are unavailable, though accuracy may be reduced for complex layouts.

EDocMLLMSchemaHelper generates UBL JSON schema definitions dynamically based on E-Document Service configuration. This enables services to customize which fields are extracted (standard invoice fields, custom extensions, tax details) without modifying MLLM prompts.

## Things to know

- **MLLM uses vision models** -- Azure OpenAI GPT-4 Vision analyzes PDF as image, extracting text and layout simultaneously. This handles complex invoices with tables, multi-column layouts, and embedded images better than OCR + text extraction.
- **Schema-driven extraction** -- MLLM prompt includes complete UBL JSON schema with field types, descriptions, and validation rules. This constrains AI to return valid structured data rather than freeform text.
- **Fallback is automatic** -- If MLLM fails for any reason (network error, rate limit, invalid response), system immediately tries ADI without user intervention. Fallback is logged to E-Document Log for troubleshooting.
- **Minimum field validation** -- MLLM responses are rejected if they lack minimum required fields (vendor name OR vendor address must be present). This prevents accepting garbage responses that would fail downstream.
- **Token usage optimization** -- MLLM handler tracks Azure OpenAI token usage per request, logging to telemetry. This enables cost analysis and prompt optimization (reducing schema size, optimizing system prompts).
- **PEPPOL handler specialization** -- EDocumentPEPPOLHandler is specialized structure handler for PEPPOL BIS 3.0 format. It validates UBL XML schema compliance and extracts PEPPOL-specific extensions not handled by generic ADI.
- **Retry logic** -- MLLM handler implements exponential backoff for transient API errors (429 rate limit, 503 service unavailable). After 3 retries it falls back to ADI rather than failing the import.
