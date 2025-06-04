This module provides an internal API for working with PDF documents in Business Central. It supports basic PDF manipulation tasks, primarily focused on extracting embedded XML e-invoices and metadata from PDFs, such as Factur-X, XRechnung, and ZUGFeRD formats.

You can use this module to:

- Extract invoice attachments from PDF documents

- Download all attachments as a ZIP archive

- Retrieve PDF metadata (author, title, page size, etc.)

- List the names of all embedded attachments

### Extract an embedded invoice from a PDF
procedure Example(PdfStream: InStream)
var
    TempBlob: Codeunit "Temp Blob";
    Success: Boolean;
    PdfHelper: Codeunit "PDF Helper Impl";
begin
    Success := PdfHelper.GetInvoiceAttachmentStream(PdfStream, TempBlob);
    if Success then
        Message('Invoice extracted successfully');
end;

### Download all attachments as a ZIP file
procedure Example(PdfStream: InStream)
var
    PdfHelper: Codeunit "PDF Helper Impl";
begin
    PdfHelper.GetZipArchive(PdfStream);
end;

### Get names of embedded files
procedure Example(PdfStream: InStream)
var
    PdfHelper: Codeunit "PDF Helper Impl";
    Names: Text;
begin
    Names := PdfHelper.ShowNames(PdfStream);
    Message('Attachments: %1', Names);
end;

### Read PDF metadata
procedure Example(PdfStream: InStream)
var
    PdfHelper: Codeunit "PDF Helper Impl";
    Metadata: JsonObject;
begin
    Metadata := PdfHelper.GetPdfProperties(PdfStream);
    Message('PDF has %1 pages', Metadata.GetValue('pagecount'));
end;
