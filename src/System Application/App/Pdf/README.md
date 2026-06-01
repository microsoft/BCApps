This module provides an internal API for working with PDF documents in Business Central. It supports basic PDF manipulation tasks, primarily focused on extracting embedded XML e-invoices and metadata from PDFs, such as Factur-X, XRechnung, and ZUGFeRD formats.

You can use this module to:

- Extract invoice attachments from PDF documents

- Download all attachments as a ZIP archive

- List the names of all embedded attachments

- Retrieve PDF metadata (author, title, page size, etc.)

- Count number of pages

- Add attachments and append files to the rendered PDF

- Protect PDF documents with user/admin codes


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

### Add an attachment to the PDF
```
procedure Example()
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.AddAttachment(
        'factur-x.xml',
        Enum::"PDF Attach. Data Relationship"::Data,
        'application/xml',
        'factur-x.xml',
        'Embedded e-invoice',
        false);
end;
```

### Append a file to the rendered PDF
```
procedure Example()
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.AddFileToAppend('c:\temp\appendix.pdf');
end;

```

### Append a stream to the rendered PDF
```
procedure Example(FileInStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.AddStreamToAppend(FileInStream);
end;
```

### Protect the PDF with user and admin codes
```
procedure Example()
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.ProtectDocument('user123', 'admin456');
end;
```

### Convert PDF to image
```
procedure Example(ImageStream: InStream)
var
    PDFDocument: Codeunit "PDF Document";
begin
    PDFDocument.ConvertPdfToImage(ImageStream, Enum::"Image Format"::PNG, 1);
end;
```

### Generate JSON rendering payload
```
procedure Example(RenderingPayload: JsonObject)
var
    PDFDocument: Codeunit "PDF Document";
    FinalPayload: JsonObject;
begin
    FinalPayload := PDFDocument.ToJson(RenderingPayload);
end;
```

### Count configured attachments
```
procedure Example()
var
    PDFDocument: Codeunit "PDF Document";
    Count: Integer;
begin
    Count := PDFDocument.AttachmentCount();
    Message('There are %1 attachments.', Count);
end;
```

### Count appended documents
```
procedure Example()
var
    PDFDocument: Codeunit "PDF Document";
    Count: Integer;
begin
    Count := PDFDocument.AppendedDocumentCount();
    Message('There are %1 appended documents.', Count);
end;
```