This module provides an internal API for working with PDF documents in Business Central. It supports basic PDF manipulation tasks, primarily focused on extracting embedded XML e-invoices and metadata from PDFs, such as Factur-X, XRechnung, and ZUGFeRD formats.

You can use this module to:

- Extract invoice attachments from PDF documents

- Download all attachments as a ZIP archive

- Retrieve PDF metadata (author, title, page size, etc.)

- Number of pages 

- List the names of all embedded attachments

### Extract an embedded invoice from a PDF
```
procedure Example(PdfStream: InStream)
var
    TempBlob: Codeunit "Temp Blob";
    Success: Boolean;
    PDFDocumentImpl: Codeunit "PDF Document Impl.";
begin
    Success := PDFDocumentImpl.GetDocumentAttachmentStream(PdfStream, TempBlob);
    if Success then
        Message('Invoice extracted successfully');
end;
```

### Download all attachments as a ZIP file
```
procedure Example(PdfStream: InStream)
var
    PDFDocumentImpl: Codeunit "PDF Document Impl.";
begin
    PDFDocumentImpl.GetZipArchive(PdfStream);
end;
```

### Get names of embedded files
```
procedure Example(PdfStream: InStream)
var
    PDFDocumentImpl: Codeunit "PDF Document Impl.";
    AttachmentNames: List of [Text];
    AttachmentName: Text;
    Output: Text;
begin
    Names := PDFDocumentImpl.GetAttachmentNames(PdfStream);
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
    PDFDocumentImpl: Codeunit "PDF Document Impl.";
    Metadata: JsonObject;
begin
    Metadata := PDFDocumentImpl.GetPdfProperties(PdfStream);
    Message('PDF has %1 pages', Metadata.GetValue('pagecount'));
end;


### Get number of pages
```
procedure Example(PdfStream: InStream)
var
    PDFDocumentImpl: Codeunit "PDF Document Impl.";
    PageCount: Integer;
begin
    PageCount := PDFDocumentImpl.GetPdfPageCount(PdfStream);
    Message('PDF has %1 pages', PageCount);
end;
```