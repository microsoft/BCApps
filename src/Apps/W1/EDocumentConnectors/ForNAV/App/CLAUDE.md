# E-Document Connector - ForNAV

Connects Business Central's E-Document framework to the PEPPOL network through
the ForNAV cloud service. Implements sending, receiving, and application
response handling for PEPPOL documents using OAuth2 authentication.

## Quick reference

- **ID range**: 6410-6426
- **Dependencies**: E-Document Core (6100-6199)
- **Object count**: 34 (17 codeunits, 3 tables, 2 table extensions, 4 pages, 1 enum, 1 enum extension, 6 permissions)
- **Interfaces**: IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, ISentDocumentActions, IConsentManager
- **Authentication**: OAuth2 client credentials flow with secret rotation support
- **API**: ForNAV REST endpoints for outgoing, inbox, and SMP operations

## How it works

**Sending documents**: The sender converts BC e-documents to PEPPOL XML format
and posts them to the ForNAV `/Outgoing` endpoint. The ForNAV service returns
a document ID that BC stores for tracking. The connector then polls for
responses (acknowledgment, application response, or error) and updates the
e-document status accordingly. Sending is synchronous within the BC user session.

**Receiving documents**: A job queue entry runs every 30 minutes to poll the
ForNAV `/Inbox` endpoint with pagination support (100 docs per page). Downloaded
PEPPOL XML is stored as a Blob in the ForNAV Incoming E-Document table before
BC processes it into the standard e-document workflow. After successful
processing, the connector sends a DELETE request to mark the document as
processed in the ForNAV service. This prevents duplicate processing.

**Application responses**: When a user approves or rejects an incoming document,
the connector generates a PEPPOL ApplicationResponse XML. Approval creates a
response with code AP (Acknowledged); rejection creates a response with code RE
(Rejected) plus the user-supplied reason. The response is sent back through the
PEPPOL network to the original sender using the same outgoing flow.

**Authentication and setup**: OAuth2 tokens are stored in IsolatedStorage with
module scope and refreshed automatically. The setup wizard exchanges a passcode
for credentials using SHA256 hash validation. If authentication fails due to
secret rotation, the connector retries up to 3 times with 10-second delays to
allow IsolatedStorage cache invalidation. The SMP (Service Metadata Publisher)
integration checks participant registration status with detailed status codes
(0=offline, 200=published, 402=unlicensed, 404=not found, etc.).

## Structure

```
ForNAV/
  ForNavPeppolProcessing.Codeunit.al        -- Core send/receive logic
  ForNavIncomingEDocument.Table.al          -- Blob storage for incoming XML
Integration/
  ForNavDocumentSender.Codeunit.al          -- IDocumentSender implementation
  ForNavDocumentReceiver.Codeunit.al        -- IDocumentReceiver implementation
  ForNavResponseHandler.Codeunit.al         -- IDocumentResponseHandler implementation
  ForNavSentDocActions.Codeunit.al          -- ISentDocumentActions implementation
  ForNavConsentMgmt.Codeunit.al             -- IConsentManager implementation
  ForNavIntegration.Codeunit.al             -- Interface registration
Setup/
  ForNavPeppolSetup.Table.al                -- Singleton setup per company
  ForNavAuth.Codeunit.al                    -- OAuth2 token management
  ForNavCryptoMgmt.Codeunit.al              -- Hash validation for setup
  ForNavSMP.Codeunit.al                     -- Service metadata publisher checks
  ForNavSetupWizard.Page.al                 -- Guided setup for credentials
Permissions/
  [6 permission set objects]                -- Read, Edit, Admin permissions
```

## Documentation links

- E-Document Core framework documentation (see E-Document Core app)
- PEPPOL specifications: https://peppol.org/specifications/
- ForNAV service API documentation (vendor-specific)

## Things to know

- Setup is per-company singleton; each company needs separate credentials
- Incoming document polling runs every 30 minutes via job queue entry created during setup
- ForNAV service assigns each document a unique ID that BC stores for tracking and status updates
- OAuth2 tokens are cached in IsolatedStorage; 3-try retry pattern handles secret rotation gracefully
- DELETE endpoint marks incoming documents as processed; prevents duplicate imports
- Application responses use standard PEPPOL codes: AP (approved), RE (rejected)
- SMP integration provides rich participant status beyond simple exists/not-exists checks
- Pagination for inbox retrieval prevents timeout on large incoming queues (100 docs/page)
- All PEPPOL XML is stored as Blob in BC before processing; supports audit trail
- Setup wizard uses passcode + SHA256 hash exchange to validate credential ownership
- Retry logic with 10-second sleep allows IsolatedStorage cache to invalidate on secret updates
- Error responses from ForNAV service are captured and displayed in e-document error logs
