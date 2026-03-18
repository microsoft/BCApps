# Business logic

File format handlers provide format identification and structure routing logic.

## Format detection

When e-document blob arrives, system determines file format:

**Extension-based detection:**
1. Read "Name" field from E-Doc. Data Storage (e.g., "invoice.xml")
2. Extract extension via FileManagement.GetExtension (returns "xml")
3. Lookup enum value: "xml" → E-Doc. File Format::XML
4. Instantiate IEDocFileFormat from enum

**Content-based detection (fallback):**
1. If extension is missing or ambiguous, read first 16 bytes of blob
2. Check magic numbers:
   - `%PDF` → PDF format
   - `<?xml` or `<` → XML format
   - `{` or `[` → JSON format
   - `89 50 4E 47` → PNG image (unsupported, error)
3. Instantiate corresponding IEDocFileFormat

**HTTP header detection:**
1. If blob arrived via API, check Content-Type header
2. Map MIME types:
   - `application/xml` or `text/xml` → XML
   - `application/json` → JSON
   - `application/pdf` → PDF
3. Instantiate IEDocFileFormat from MIME type

Detection priority: Extension → Content → HTTP header. First successful detection wins.

## Structure preference determination

Each file format specifies preferred structure implementation:

**XML format (EDocXMLFileFormat):**
```al
procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
begin
    exit("Structure Received E-Doc."::"Already Structured");
end;
```
XML is already structured (tree format), requires no transformation. ADI can extract values via XPath immediately.

**JSON format (EDocJSONFileFormat):**
```al
procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
begin
    exit("Structure Received E-Doc."::"Already Structured");
end;
```
JSON is already structured (object format), requires no transformation. ADI can extract values via JSONPath immediately.

**PDF format (EDocPDFFileFormat):**
```al
procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
begin
    exit("Structure Received E-Doc."::MLLM);
end;
```
PDF is unstructured (image + embedded text), requires MLLM extraction to convert to structured JSON conforming to UBL schema.

## Structure step execution

During Structure step, ImportEDocumentProcess calls:

```al
IFileFormat := EDocumentDataStorage."File Format";
if EDocument."Structure Data Impl." = "Structure Received E-Doc."::Unspecified then
    EDocument."Structure Data Impl." := IFileFormat.PreferredStructureDataImplementation();
```

This sets default structure implementation based on format preference. Services can override by explicitly setting "Structure Data Impl." field to "ADI" or "MLLM" before Structure step.

For "Already Structured" formats:
1. Validate blob is valid XML/JSON (parse without error)
2. Return blob as-is via IStructuredDataType interface
3. Set "Structured Data Entry No." to reference same blob
4. ADI extraction proceeds directly

For "MLLM" formats:
1. Convert PDF blob to base64 string
2. Call EDocumentMLLMHandler with base64 + UBL schema
3. AOAI responds with extracted JSON
4. Validate JSON schema matches expected structure
5. Save JSON as new blob in "Structured Data Entry No."
6. Original PDF preserved in "Unstructured Data Entry No." as attachment

## Preview implementation

**XML preview (EDocXMLFileFormat.PreviewContent):**
```al
procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
var
    InStr: InStream;
    Content: Text;
begin
    TempBlob.CreateInStream(InStr);
    InStr.Read(Content);
    if StrLen(Content) > 1048576 then // 1MB limit
        Content := CopyStr(Content, 1, 1048576) + '\n[Content truncated]';
    Message(Content); // Or open in text editor page
end;
```

**JSON preview** -- Same as XML, displays raw JSON text.

**PDF preview (EDocPDFFileFormat.PreviewContent):**
```al
procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
var
    DocumentSharing: Codeunit "Document Sharing";
begin
    DocumentSharing.Share(FileName, TempBlob); // Opens in browser PDF viewer
end;
```

**Unsupported format preview:**
```al
procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
begin
    Error('Content can''t be previewed');
end;
```

## MLLM fallback to ADI

PDF format prefers MLLM but can fall back to ADI if AI fails:

1. Structure step calls EDocumentMLLMHandler
2. MLLM extraction attempts AOAI API call
3. If API returns error (service unavailable, quota exceeded):
   - Log error to E-Document Log
   - Call FallbackToADI method
   - Extract text from PDF using OCR (if configured)
   - Convert extracted text to structured XML/JSON
   - Proceed with ADI extraction
4. If MLLM succeeds, ADI is skipped

Fallback ensures processing continues even when AI services are unavailable, at cost of lower extraction accuracy for complex PDF layouts.

## Custom format implementation

Partners can add custom formats by extending E-Doc. File Format enum:

```al
enumextension 50100 "My Custom Format" extends "E-Doc. File Format"
{
    value(50100; "CSV")
    {
        Caption = 'CSV';
        Implementation = IEDocFileFormat = "E-Doc. CSV File Format";
    }
}

codeunit 50100 "E-Doc. CSV File Format" implements IEDocFileFormat
{
    procedure FileExtension(): Text
    begin
        exit('csv');
    end;

    procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
    begin
        // Display CSV grid preview
    end;

    procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
    begin
        // CSV needs custom parser to convert to JSON
        exit("Structure Received E-Doc."::"Custom CSV Parser");
    end;
}
```

Custom formats must also implement IStructureReceivedEDocument to handle structure transformation.

## Content-type negotiation

When services send/receive via API, HTTP Content-Type header specifies format:

**Outbound (export):**
```al
HttpContent.GetHeaders(Headers);
case IFileFormat.FileExtension() of
    'xml': Headers.Add('Content-Type', 'application/xml; charset=utf-8');
    'json': Headers.Add('Content-Type', 'application/json; charset=utf-8');
    'pdf': Headers.Add('Content-Type', 'application/pdf');
end;
```

**Inbound (import):**
```al
HttpResponse.Content.GetHeaders(Headers);
Headers.TryGetValues('Content-Type', ContentTypes);
ContentType := ContentTypes.Get(1);
case ContentType of
    'application/xml', 'text/xml':
        EDocDataStorage."File Format" := "E-Doc. File Format"::XML;
    'application/json':
        EDocDataStorage."File Format" := "E-Doc. File Format"::JSON;
    'application/pdf':
        EDocDataStorage."File Format" := "E-Doc. File Format"::PDF;
end;
```

Content-Type negotiation enables services to dynamically handle multiple formats without explicit configuration per format.
