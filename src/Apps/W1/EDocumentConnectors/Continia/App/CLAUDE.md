# E-Document Connector - Continia

Bridges Business Central's E-Document framework to the Continia Delivery Network (CDN) for PEPPOL and NemHandel e-invoicing. This connector transforms BC's generic send/receive abstraction into CDN's participation-based model, where companies register network identities (GLN, VAT, CVR) and activate document profiles per network. Unlike other connectors that work per-document, Continia requires upfront network registration before any documents can flow.

## Quick reference

- **ID range**: 6380-6399
- **Dependencies**: E-Document Core
- **Interface count**: 5 (IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, ISentDocumentActions, IReceivedDocumentMarker)

## How it works

The connector maps BC's per-document workflow onto CDN's participation model. Before sending or receiving, a company must register a "participation" -- a combination of network (PEPPOL, NemHandel), identifier type (GLN, VAT, etc.), and identifier value. Each participation can have multiple activated profiles (outbound invoice, inbound order, etc.). The onboarding wizard fetches available metadata from CDN, creates participations, and activates profiles. Only after activation can documents flow.

OAuth2 credentials live in IsolatedStorage via ConnectionSetup singleton. The SessionManager codeunit caches tokens in-session with a 25% refresh threshold -- if 75% of the token lifetime remains, it uses the cache. At 95% expiry it forces refresh. This avoids repeated OAuth roundtrips during batch operations while preventing stale token failures.

Send workflow: POST document as Base64-encoded XML, receive tracking ID, poll GetResponse for technical acceptance (schema validation, network delivery), then poll GetApprovalStatus for business response (approved/rejected by recipient). Receive workflow: paginated GET per activated profile, returns metadata blobs containing file_token URLs, download full document via token, then MarkFetched to confirm processing. All API responses are XML parsed via XmlDocument, not JSON. Pagination uses X-Total-Count header.

Three integration events allow URL customization per environment -- OnGetCOBaseUrl for Continia Online, OnGetCdnBaseUrl for CDN endpoints, OnBeforeGetBaseUrlForLocalization for country-specific routing. Default URLs point to production CDN; tests and sandboxes override via event subscribers.

## Structure

- **API Requests** -- HTTP wrapper (ContiniaAPIRequests) and URL builder (ContiniaApiUrl) with integration events
- **Implementation** -- Core send/receive logic (ContiniaEDocumentProcessing), interface glue (ContiniaIntegrationImpl), ConnectionSetup table and page
- **Metadata** -- Network enums, identifier types, profile definitions fetched from CDN
- **Onboarding** -- Wizard pages (ContiniaOnboardingGuide, profile selection) and helper codeunit for registration flow
- **Participation Setup** -- Participations table/page, activated profiles table/page, registration status tracking
- **Subscription and Access** -- OAuth2 flow (ContiniaCredentialManagement), token caching (ContiniaSessionManager), subscription validation
- **Permissions** -- Read/Edit/User permission sets extending E-Document Core permissions

## Things to know

- **Participations before documents** -- You cannot send or receive until at least one participation is registered and has activated profiles. The wizard is mandatory for first-time setup.
- **Singleton ConnectionSetup** -- One OAuth2 client per company. Credentials in IsolatedStorage, tokens cached in SessionManager singleton. Do not store tokens in temp tables or globals outside SessionManager.
- **XML everywhere** -- CDN returns XML, not JSON. Use XmlDocument.ReadFrom and SelectSingleNode, not JsonObject. Document content is Base64-encoded XML inside XML envelopes.
- **Polling is manual** -- GetResponse and GetApprovalStatus do not auto-poll. E-Document Core's job queue calls these methods; you control retry logic via service configuration.
- **Profile direction matters** -- Profiles have direction enum (Outbound, Inbound). Activated profiles with Outbound participate in sends, Inbound in receives. One participation can have both.
- **X-Total-Count header drives pagination** -- ReceiveDocuments reads this header to determine total available documents. Missing header means single page.
- **Session-scoped token cache** -- SessionManager is SingleInstance. Tokens persist across calls in one session but reset on new session start. Child sessions call AcquireTokenFromCache with fallback to parent token.
- **Integration events for URLs** -- Override OnGetCOBaseUrl or OnGetCdnBaseUrl in test apps or country layers to redirect to sandbox endpoints. Do not hardcode URLs in processing codeunits.
- **MarkFetched is async** -- After downloading a document, MarkFetched POSTs confirmation to CDN. If this fails, the document reappears on next receive poll. Idempotency matters.
- **Metadata is dynamic** -- Network identifiers and profiles come from CDN API, not hardcoded enums (except top-level networks). Refresh metadata if CDN adds new document types.
