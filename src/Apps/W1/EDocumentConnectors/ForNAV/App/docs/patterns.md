# ForNAV Patterns

## Active patterns

### 1. Dummy URLs for integration logging

The E-Document Integration Log table requires a URL field for all HTTP operations, but ForNAV routes requests internally through its service. The connector uses placeholder URLs to satisfy the schema while maintaining meaningful log filtering.

**Implementation**: `ForNAVIntegrationImpl` codeunit (6418) uses URLs like:
- `https://sendfilepostrequest/` for send operations
- `https://gettargetdocumentrequest/` for receive operations

The `DocumentLog()` procedure filters log entries by matching these URLs.

**Trade-off**: This approach is fragile. If the URL format changes or collides with real endpoints, log filtering breaks silently. Consider adding a custom dimension or log category field to the integration log schema instead.

### 2. OAuth retry with sleep

The `AcquireTokenWithClientCredentials()` method in the authentication flow retries token acquisition three times with a 10-second delay between attempts. This handles the propagation delay when AAD secrets are rotated.

**Implementation**: `ForNAVPeppolAadApp` codeunit (6411)

```al
for i := 1 to 3 do begin
    if TryAcquireToken() then
        exit(true);
    Sleep(10000);
end;
```

**Trade-off**: The `Sleep()` function blocks the AL thread, preventing the user from interacting with the session. AL has no async/await alternative. For long delays, consider showing a progress dialog or deferring the operation to a job queue entry.

**Security**: Sensitive authentication methods are marked `[NonDebuggable]` to prevent secret exposure in debugger sessions.

### 3. Blob field abstraction

The ForNAV Incoming E-Document table stores three blob fields: Doc, Message, and HTML Preview. Direct field access requires `CalcFields()` and stream handling. Helper procedures encapsulate this pattern.

**Implementation**: `ForNAV Incoming E-Document` table (6420)

```al
procedure GetDoc(): Text
procedure GetHtml(): Text
procedure GetComment(): Text
```

Each method handles `CalcFields()`, stream initialization, and reading. Callers should never access blob fields directly.

**Benefits**: Consistent error handling, single responsibility, easier refactoring if storage moves from blobs to external storage.

### 4. Hash-based setup validation

The `GetSetupFile()` method retrieves configuration from the ForNAV service and validates the response integrity using a hash challenge. The server returns a hash computed from `CompanyName + IdentificationValue + InstallationId`, which the client verifies with `TestHash()`.

**Implementation**: `ForNAVIntegrationImpl` codeunit (6418)

**Purpose**: Prevents credential injection attacks where a malicious actor replaces the setup payload. The hash binds the configuration to the specific company and installation.

**Limitation**: The hash algorithm and format are not versioned. Future changes require coordinated service and AL updates.

### 5. Rich SMP status codes

The `ParticipantExists()` method queries the SMP (Service Metadata Publisher) and maps HTTP status codes to semantic states stored in the Setup table.

**Status codes**:
- `0` -- Service offline
- `200` -- Participant published successfully
- `402` -- Unlicensed (payment required)
- `409` -- Registered to another company in the same tenant
- `423` -- Registered to another AAD tenant
- `451` -- Registered to another Access Point

**Implementation**: `ForNAVIntegrationImpl` codeunit (6418), stored in `ForNAV Peppol Setup` table (6415) Status field

**Benefits**: The UI can show meaningful guidance (e.g., "This participant is registered in another company") rather than raw HTTP errors.

**Trade-off**: The mapping must stay synchronized with the service. If the service adds new codes, the AL code interprets them incorrectly until updated.

### 6. Auto-initialization singleton

The ForNAV Peppol Setup table creates its single record automatically on first access via `InitSetup()`. The method populates default values from Company Information (VAT registration number, company name).

**Implementation**: `ForNAV Peppol Setup` table (6415)

```al
procedure GetSetup(): Record "ForNAV Peppol Setup"
begin
    if not Get() then
        InitSetup();
    exit(Rec);
end;
```

**Benefits**: No manual setup required for default configuration. The user can publish immediately if Company Information is complete.

**Trade-off**: If Company Information contains incorrect data, the setup inherits those errors. The user must explicitly review and fix values.

## Legacy patterns

### 1. Hardcoded dummy URLs for log filtering

The placeholder URL approach works but creates maintenance burden. If the integration log schema evolves to support custom dimensions, migrate to a dedicated category field.

**Recommendation**: Propose an `Integration Category` field on the E-Document Integration Log table to replace URL-based filtering.

### 2. Sleep() in token acquisition

Blocking the AL thread for 10 seconds during authentication creates a poor user experience. If the delay is unavoidable, consider:
- Showing a progress dialog with retry countdown
- Moving authentication to a background job queue entry
- Caching tokens and refreshing them asynchronously before expiry

### 3. Mixed concerns in ForNAVPeppolSetup

The setup table (6415) combines:
- HTTP headers for service requests
- License and subscription information
- Cryptographic installation ID

**Recommendation**: Split into separate tables or move HTTP headers to a request builder codeunit. The setup table should contain only user-editable configuration.

## File references

- `ForNAVIntegrationImpl` codeunit: `C:\repos\NAV1\App\BCApps\src\Apps\W1\EDocumentConnectors\ForNAV\App\src\ForNAVIntegrationImpl.Codeunit.al`
- `ForNAVPeppolAadApp` codeunit: `C:\repos\NAV1\App\BCApps\src\Apps\W1\EDocumentConnectors\ForNAV\App\src\ForNAVPeppolAadApp.Codeunit.al`
- `ForNAV Peppol Setup` table: `C:\repos\NAV1\App\BCApps\src\Apps\W1\EDocumentConnectors\ForNAV\App\src\ForNAVPeppolSetup.Table.al`
- `ForNAV Incoming E-Document` table: `C:\repos\NAV1\App\BCApps\src\Apps\W1\EDocumentConnectors\ForNAV\App\src\ForNAVIncomingEDocument.Table.al`
