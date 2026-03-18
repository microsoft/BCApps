# API endpoints

OData/REST API v1.0 pages for external integration with the E-Document framework. These pages expose e-document data and operations to external systems -- ERP connectors, document management platforms, and automation tools.

## How it works

Five API pages under `APIGroup = 'edocument'`, `APIPublisher = 'microsoft'`, `APIVersion = 'v1.0'`:

- `EDocumentsAPI` (6112) -- read-only list of all E-Documents with key fields (entry number, document type, status, amounts, dates, direction). Includes a subpage part for `E-Document Service Status`.
- `NewEDocumentsAPI` -- writable endpoint for creating new incoming e-documents via API. External systems post document data here to trigger import processing.
- `EDocumentServicesAPI` -- exposes E-Document Service configuration.
- `EDocumentServiceStatusAPI` -- per-service status records for monitoring processing state.
- `EDocFileContentAPI` -- access to the blob content stored in `E-Doc. File Content API Buffer`, allowing external systems to upload or download document files.

Supporting objects in the parent `API/` directory include `EDocFileContentAPIBuffer` (buffer table for file content transfer), `EDocumentBusinessEvents` (codeunit that raises business events for external automation), and `EDocEventCategory` (enum extension for the event category).

## Things to know

- All API pages use `SystemId` as OData key, not entry number. This follows the BC API v2 convention for stable external identifiers.

- The `EDocumentsAPI` page is read-only (`Editable = false`, `DataAccessIntent = ReadOnly`). Creating documents is done through `NewEDocumentsAPI`.

- Business events in `EDocumentBusinessEvents` fire on key state transitions, allowing external systems to subscribe to webhooks for document creation, export completion, import processing, and errors.

- The `EDocFileContentAPI` uses a buffer table pattern rather than directly exposing blob storage, which allows content to be streamed through the API without loading entire blobs into memory on the server.
