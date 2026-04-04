# Continia connector business logic

This document describes the core business processes implemented by the Continia E-Document connector. The connector integrates Business Central with Continia Delivery Network (CDN) for sending and receiving electronic documents over networks like PEPPOL and Nemhandel.

## Send flow

When Business Central needs to send an e-document through Continia, the request flows through three main codeunits. The entry point is `ContiniaIntegrationImpl.Send()`, which delegates to `ContiniaEDocumentProcessing.SendEDocument()`. This method checks the current service status -- if the document is newly exported or previously failed with no CDN document ID, it calls `ContiniaAPIRequests.SendDocument()`.

The send operation converts the document to Base64-encoded XML and POSTs it to `/documents.xml`. The CDN responds with a document ID, which is stored in the `E-Document` record's `Continia Document Id` field. This ID becomes the reference for all subsequent polling and status checks.

After sending, Business Central polls for the technical response by calling `GetTechnicalResponse()`. This method sets suppress-error mode to avoid throwing exceptions when the response isn't ready yet, then performs a GET request to `/documents/{id}/technical_response.xml`. The response contains a `document_status` node with either `SuccessEnum` or `ErrorEnum`. On success, the document is marked as processed. On error, the connector extracts `error_code` and `error_message` nodes, logs them via E-Document Error Helper, and marks the document as processed to prevent further polling.

Business response polling happens separately via `GetLastDocumentBusinessResponses()`. This retrieves the CDN's assessment of whether the recipient accepted or rejected the document. The method calls `GetBusinessResponses()` to fetch `/documents/{id}/business_response.xml`, then parses the XML for `response_code` values. Approval codes are AP, CA, PD, or BusinessAccept. Rejection codes are RE or BusinessReject. The connector iterates through all business response nodes -- if any response indicates rejection, the entire check returns rejected. Only when at least one approval exists and no rejections are found does the document move to approved status.

When extracting rejection reasons, the connector looks for `reason_code` and `reason` nodes. If neither exists, it logs "Unknown rejection reason". Otherwise, it formats the reason as "Reason: {code} - {description}" and logs it as a warning on the E-Document record.

## Receive flow

Receiving documents from CDN happens per activated network profile. The connector iterates through all profiles associated with an E-Document Service, calling `GetDocuments()` for each one. This endpoint supports pagination -- the connector requests 100 documents at a time, reading the `X-Total-Count` header to determine when all pages have been fetched.

Each GET request to `/participations/{participation_id}/profiles/{profile_id}/documents` returns XML with a `documents/document` node list. The connector parses these into temporary blobs, writing each document node to an OutStream and adding it to the received documents collection.

When Business Central processes a received document, it calls `DownloadDocument()`. This method extracts two critical pieces of data from the document metadata XML. First, it reads the `document_id` node and stores it as the E-Document's CDN document ID. Second, it extracts the `xml_document/file_token` node, which contains a signed URL for downloading the actual document content. The connector calls `DownloadFileFromUrl()` to fetch the file via standard HTTP GET and stores the result in a TempBlob passed through the ReceiveContext.

After successful import, the connector marks the document as processed on CDN's side via `MarkDocumentAsProcessed()`. This sends a POST to `/documents/{id}/action` with an action enum value of `MarkAsProcessedEnum`, signaling to CDN that the document no longer needs to appear in future receive queries.

## Registration and onboarding

The onboarding wizard is managed by `ContiniaOnboardingHelper`, which spans 634 lines and contains more than 35 procedures. The wizard follows a multi-step flow to register a company on CDN.

Step one is initialization. `InitializeGeneralScenario()` pre-populates company information from Business Central's Company Information table, including name, VAT registration number, address, and post code. If client credentials already exist, the connector calls `GetNetworkMetadata()` to fetch reference data from CDN -- network profiles and identifier types for both PEPPOL and Nemhandel networks. This metadata includes validation rules, country-specific defaults, and mandatory profile flags.

Identifier validation happens through `ValidateIdentifierType()` and `ValidateIdentifierValue()`. The former looks up the selected scheme ID in the cached network identifier table. The latter applies regex-based validation using the `Validation Rule` field from CDN metadata. If the identifier value doesn't match the expected pattern, the connector throws an error showing the invalid value and the rule that failed.

Profile selection varies by country and network. For German companies on PEPPOL, the connector automatically includes all profiles with `Mandatory for Country = DE`, which ensures compliance with XRechnung requirements. For Dutch companies, it adds SI-UBL 2.0 invoice and credit note profiles. For Norwegian companies, it includes EHF Advanced Order profiles. The wizard provides helper methods like `AddInvoiceCreditMemoProfiles()`, `AddOrderProfiles()`, and `AddInvoiceResponseProfiles()` to populate these selections based on country code and document type.

Before registration, the connector calls `CheckProfilesNotRegistered()` to prevent duplicate participation. This queries `/networks/{network}/participations/lookup` with the identifier type and value. If CDN returns any existing registrations, the connector extracts access point details -- name, email, and supported profiles -- then builds a detailed error message listing which profiles are already claimed and by whom.

Registration itself happens in `RegisterParticipation()`. The connector POSTs the participation record to `/networks/{network}/participations.xml`, receiving a participation ID in response. It then iterates through all selected profiles, POSTing each one to `/networks/{network}/participations/{id}/profiles.xml`. After all profiles are created, it patches the participation record to set the registration status to InProcess, which triggers CDN's internal validation and activation workflow. For Nemhandel participations, the connector also updates Business Central's Company Information with the registration number if it was previously blank.

Metadata synchronization uses paginated fetches. `GetNetworkProfiles()` and `GetNetworkIdTypes()` start at page 1 with a page size of 100, incrementing the page number until the total count is reached. Each response includes an `X-Total-Count` header indicating the total number of records available. The connector parses the XML, creates or updates local cache records, and tracks which profiles are mandatory for specific countries and which identifier types are defaults.

## Authentication

Authentication is handled by `ContiniaSubscriptionMgt` and `ContiniaSessionManager`. The initialization flow starts with `InitializeContiniaClient()`, which takes partner credentials and exchanges them for an access token.

First, the connector POSTs partner username and password to `/partner_zone/access_token` to receive a partner access token. This token is then included in the header when calling `/client/environment/initialize`. CDN responds with client credentials -- a client ID and client secret -- which are stored in IsolatedStorage via `ContiniaCredentialManagement`.

Token acquisition happens in `TryAcquireClientToken()`. The connector POSTs the client ID and secret to `/client/access_token` and receives an access token plus expiration time in seconds. The session manager converts this to milliseconds and calculates the next update time.

Token caching uses a two-tier strategy implemented in `ContiniaSessionManager`. The codeunit is marked SingleInstance = true, meaning its state persists across invocations within the same user session. When `GetAccessToken()` is called, it first checks the in-memory cache. If the token was requested recently and hasn't crossed the refresh threshold, it returns the cached value immediately.

The refresh threshold is set at 25% of the token's remaining lifetime. If the token expires in 3600 seconds, the connector will attempt to refresh it after 900 seconds. This calculation happens in `ConnectionSetup.AcquireTokenFromCache()`, which compares the current time against the token timestamp plus 75% of the expiration window.

If a refresh attempt fails, the connector falls back to a 23-hour grace period. It considers tokens valid for 95% of their stated lifetime, then allows an additional grace period before forcing re-authentication. This prevents authentication failures during temporary CDN outages while still ensuring tokens don't become dangerously stale.

Session persistence is critical because re-initializing credentials on every API call would trigger rate limits and create performance bottlenecks. The single-instance session manager ensures that within a given user session, authentication happens once and subsequent calls reuse the cached token until refresh is needed.

## Error handling

Error handling distinguishes between expected conditions and true failures. The connector uses a suppress-error flag controlled by `SetSuppressError()`. When enabled, API errors return false rather than throwing exceptions. This is essential for polling operations where "not ready yet" is a normal state, not an error.

HTTP response handling happens in `HandleApiError()`. The method checks the status code first -- 200, 201, and 202 are considered success. For all other codes, it reads the response body and attempts to parse it as XML. If parsing fails, it throws "unexpected API error".

For well-formed error responses, `ReadErrorResponse()` extracts `code` and `message` nodes from the `/error` element. Status codes in the 400 range (bad request, unauthorized, not found, conflict, unprocessable entity) produce user-facing errors formatted as "Error Code {code} - {message}". Status 500 and 501 are treated as system errors and formatted differently to indicate the issue is on CDN's side.

The E-Document Error Helper integration provides structured logging. Simple messages are logged via `LogSimpleErrorMessage()`, which adds an error to the E-Document log without detailed breakdown. Warning messages use `LogWarningMessage()`, which logs the issue but doesn't block further processing. This distinction matters for business responses -- a rejection with a clear reason code should be logged as a warning, while a malformed API response should be logged as an error.

Document actions like cancellation use the same error suppression pattern. `CancelDocument()` calls `PerformActionOnDocument()` with action = CancelEnum, then updates the E-Document status only if the call succeeds. If the call fails, the error is surfaced through the ActionContext, allowing the framework to decide whether to retry or report the failure to the user.
