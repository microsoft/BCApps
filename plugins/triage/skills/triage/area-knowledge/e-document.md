# E-Document Domain Knowledge

## E-Document Framework Architecture

- The **E-Document** framework provides a modular architecture for creating, sending, receiving, and processing electronic documents.
- Core components: **E-Document Service** (defines the connection/channel), **E-Document Format** (defines the XML/JSON structure), and **E-Document** record (tracks the lifecycle of each electronic document).
- The framework uses a **service-based** approach — multiple e-document services can be configured for different trading partners or countries.
- **Interface codeunits** implement the actual format conversion and communication logic via well-defined interfaces.

## Supported Formats

- **PEPPOL BIS 3.0**: The primary pan-European standard for e-invoicing. Supports Invoice, Credit Note, and related document types.
- **Country-specific formats**: Local implementations extend the base framework for national requirements (e.g., FatturaPA for Italy, Factur-X for France, XRechnung for Germany).
- Format implementations are separate apps that register with the core framework via the **E-Document Format** interface.
- **Document mapping** translates BC sales/purchase documents into the target format's XML/JSON structure.

## Document Lifecycle

- **Create**: A BC sales/purchase document triggers creation of an E-Document record with status "Created".
- **Export**: The format codeunit converts the BC document into the target electronic format (XML/JSON blob).
- **Send**: The service connection transmits the document to the recipient (via API, PEPPOL network, email, etc.).
- **Receive**: Inbound documents are fetched from the service, parsed by the format codeunit, and matched to BC entities.
- **Process**: Received documents create or update purchase invoices/credit memos in BC.
- **Status tracking**: Each step updates the E-Document Log with status, errors, and the actual document blob.

## Extensibility Points

- **IDocumentFormat** interface — implement to add new document formats (export and import methods).
- **IDocumentSender** interface — implement to add new transmission channels (send, check status, cancel).
- **IDocumentReceiver** interface — implement to add inbound document fetching.
- **E-Document events** — integration events on the E-Document table and processing codeunits for customization.
- **E-Document Service** configuration pages allow end-users to set up connections without code changes.

## Integration with Sales/Purchase Documents

- E-Documents are created from **Posted Sales Invoices**, **Posted Sales Credit Memos**, and other posted documents.
- Inbound E-Documents create **Purchase Invoices** or **Purchase Credit Memos** via document matching.
- **Vendor matching** uses GLN (Global Location Number), VAT Registration No., or vendor name to identify the sender.
- **Line matching** attempts to map incoming lines to items, G/L accounts, or item charges using cross-references and descriptions.

## Common Issues

- Format validation failures when required fields (GLN, VAT Reg. No., unit of measure codes) are missing from BC master data
- Service connection errors due to certificate expiry, API endpoint changes, or authentication token refresh failures
- Document mapping failures when the incoming format uses item identifiers that do not match BC cross-references
- Status synchronization issues when the external service reports delivery failure after BC marked the document as sent
- Performance issues when processing large batches of inbound documents with complex line matching
