This module provides an internal API for working with PDF documents in Business Central. It supports basic PDF manipulation tasks, primarily focused on extracting embedded XML e-invoices and metadata from PDFs, such as Factur-X, XRechnung, and ZUGFeRD formats.

You can use this module to:

- Extract invoice attachments from PDF documents

- Download all attachments as a ZIP archive

- List the names of all embedded attachments

- Retrieve PDF metadata (author, title, page size, etc.)

- Number of pages 

### Extract an embedded invoice from a PDF
```
procedure Example(PdfStream: InStream)
var
    TempBlob: Codeunit "Temp Blob";
    Success: Boolean;
    PDFDocument: Codeunit "PDF Document";
begin
    Success := PDFDocument.GetDocumentAttachmentStream(PdfStream, TempBlob);
    if Success then
        Message('Invoice extracted successfully');
end;
```

### Download all attachments as a ZIP file
```
procedure Example(PdfStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.GetZipArchive(PdfStream);
end;
```

### Get names of embedded files
```
procedure Example(PdfStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
    AttachmentNames: List of [Text];
    AttachmentName: Text;
    Output: Text;
begin
    Names := PDFDocument.GetAttachmentNames(PdfStream);
    foreach AttachmentName in AttachmentNames do begin
        if Output <> '' then
            Output += ', ';
        Output += AttachmentName;
    end;
    Message('Attachments: %1', Output);
end;
```

### Read PDF metadata
```
procedure Example(PdfStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
    Metadata: JsonObject;
begin
    Metadata := PDFDocument.GetPdfProperties(PdfStream);
    Message('PDF author is %1', Metadata.GetValue('author'));
end;
```

### Get number of pages
```
procedure Example(PdfStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
    PageCount: Integer;
begin
    PageCount := PDFDocument.GetPdfPageCount(PdfStream);
    Message('PDF has %1 pages', PageCount);
end;
```