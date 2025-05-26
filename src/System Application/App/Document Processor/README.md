This module provides an internal API for working with PDF documents in Business Central. It supports basic PDF manipulation tasks, primarily focused on extracting embedded XML e-invoices and metadata from PDFs, such as Factur-X, XRechnung, and ZUGFeRD formats.

You can use this module to:

- Extract invoice attachments from PDF documents

- Download all attachments as a ZIP archive

- Retrieve PDF metadata (author, title, page size, etc.)

- List the names of all embedded attachments

- Sanitize filenames and save file content from streams

- Convert a PDF page to an image

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

### Sanitize a filename
procedure Example()
var
    PdfHelper: Codeunit "PDF Helper Impl";
    CleanName: Text;
begin
    CleanName := PdfHelper.SanitizeFilename('my/invoice\test.pdf');
    Message('Sanitized: %1', CleanName);
end;

### Convert a PDF page to an image
procedure Example()
var
    PdfHelper: Codeunit "PDF Helper Impl";
    PdfStream: InStream;
    ImageStream: InStream;
    Format: Enum "Image Format";
    FileName: Text;
    Success: Boolean;
begin
    UploadIntoStream('Upload PDF', '', '', FileName, PdfStream);
    Format := Format::Png;

    Success := PdfHelper.ConvertPageToImage(PdfStream, ImageStream, Format, 1);
    if Success then
        DownloadFromStream(ImageStream, '', '', '', FileName + '.png')
    else
        Message('Failed to convert PDF to image.');
end;
