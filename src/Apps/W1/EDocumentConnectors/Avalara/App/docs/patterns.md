# Patterns

## IsolatedStorage for secrets

Client ID, Client Secret, and OAuth Bearer Token are never stored in plaintext database fields. Instead, the Connection Setup table stores GUIDs that point to values in IsolatedStorage. All procedures that handle these secrets are marked [NonDebuggable] to prevent accidental exposure in debug sessions. This pattern complies with security requirements for SaaS extensions -- secrets must remain opaque to database administrators and support personnel.

**Example**: In Authentication.Codeunit.al, GetBearerToken() retrieves the GUID from Connection Setup, then calls IsolatedStorage.Get() with that GUID to retrieve the actual token value.

**Gotcha**: IsolatedStorage is per-company. If you copy a Connection Setup record between companies, the GUID references will break because the target company's IsolatedStorage doesn't contain those keys. Always use the provided Set/Get methods, never copy secret GUID fields directly.

## Token caching with TTL

The OAuth bearer token is reused across API calls if its expiry timestamp is more than 60 seconds in the future. This reduces load on Avalara's authentication endpoint and improves throughput for batch operations. The token and expiry are stored together in Connection Setup -- the GetBearerToken() method checks expiry before returning the cached token.

**Example**: In Authentication.Codeunit.al, GetBearerToken() compares ConnectionSetup."Avalara Token Expiry" to CurrentDateTime + 60 seconds. If the token is still valid, it returns the cached value. Otherwise, it calls RequestToken() to fetch a new one.

**Gotcha**: Revoked tokens aren't detected until they expire. If Avalara revokes a token server-side, the connector will continue using it for up to 1 minute, failing all API calls during that window. This is acceptable because token revocation is rare and the impact is temporary.

## Temporary tables for API lookups

The Mandate (table 6372) and Avalara Company (table 6373) tables are marked TableType = Temporary. They're populated on-demand from Avalara's API, never persisted to the database. This ensures users always see current data from Avalara (mandates and company registrations can change without BC knowing), but it also means there's no offline fallback.

**Example**: In IntegrationImpl.Codeunit.al, the GetMandates() method calls AvalaraAPIRequests.GetMandates(), which populates a temporary Mandate record with values parsed from the /einvoicing/mandates endpoint. Callers consume this temporary table, then it's discarded.

**Gotcha**: Dropdown lookups for mandates hit the Avalara API every time the user opens the page. For high-latency connections or rate-limited environments, this creates noticeable UI lag. Consider caching mandate lists in a session variable if users frequently switch between services.

## Metadata builder pattern

The Metadata codeunit provides a fluent API for constructing the JSON metadata object included in document submissions. Methods like SetWorkflowId(), SetDataFormat(), SetCountry(), SetMandate() return the codeunit instance, allowing chained calls. The final ToString() method serializes the accumulated metadata to a JSON string.

**Example**: In IntegrationImpl.Codeunit.al, the Send() method builds metadata like this:
```al
MetadataJson := Metadata.SetWorkflowId('workflow-id')
                        .SetDataFormat('xml')
                        .SetCountry('NO')
                        .SetMandate('peppol-bis-billing-3')
                        .ToString();
```

**Gotcha**: The builder maintains state -- calling SetCountry('NO') then SetCountry('US') overwrites the first value, not creates two entries. If you need to build multiple metadata objects in the same method, create separate instances or call Clear() between builds.

## Multipart form-data via TextBuilder

Avalara's submit document endpoint expects multipart/form-data with two parts: metadata (JSON) and file (XML). AL has no built-in encoder for this format, so Requests.CreateSubmitDocumentRequest() manually constructs the body using TextBuilder. The boundary string is a GUID, and each part includes Content-Disposition and Content-Type headers.

**Example**: In Requests.Codeunit.al, CreateSubmitDocumentRequest() builds:
```
--{boundary}
Content-Disposition: form-data; name="metadata"
Content-Type: application/json

{json content}
--{boundary}
Content-Disposition: form-data; name="file"; filename="document.xml"
Content-Type: application/xml

{xml content}
--{boundary}--
```

**Gotcha**: The final boundary must include a trailing `--` (RFC 2046 requirement). Forgetting this causes Avalara to treat the request as incomplete and return 400 Bad Request. The pattern is `--{boundary}--` at the end, not `--{boundary}`.

## Recursive pagination

The ReceiveDocuments() implementation follows Avalara's @nextLink pagination recursively. Each API response may include a `@nextLink` field pointing to the next page of results. The ReceiveDocumentInner() helper method extracts the data array from the current response, then checks for @nextLink and recursively calls itself if present, accumulating all results in a single JsonArray.

**Example**: In IntegrationImpl.Codeunit.al, ReceiveDocumentInner() calls itself when `ResponseJson.Get('@nextLink', NextLinkToken)` succeeds, passing the updated URL.

**Gotcha**: No protection against infinite loops if Avalara returns cyclic pagination links. The BC platform will eventually hit stack depth limits and throw an error, but this leaves the receive operation in an inconsistent state. Consider adding a maximum page count guard if you see pagination anomalies.

## Legacy patterns

### Obsolete Send Mode field

**What it is**: The original "Send Mode" field (EDocExtSendMode enum) was deprecated in version 27.0 and replaced with "Avalara Send Mode" (AvalaraSendMode enum). Both fields coexisted during the transition period.

**Where it appears**: Table 6103 "E-Document Service" extension (EDocService.TableExt.al) defines both fields. The old field is marked `ObsoleteState = Pending; ObsoleteReason = 'Replaced by Avalara Send Mode field'; ObsoleteTag = '27.0'`.

**Why it exists**: The original enum included a "Company Defined" value that was never implemented. Rather than modify the public enum (breaking change), a new enum was introduced with only the supported values (Asynchronous, Synchronous).

**What to do instead**: Always use "Avalara Send Mode" field. The upgrade codeunit (Upgrade.Codeunit.al) migrates existing data on platform upgrade. New code should never reference the old "Send Mode" field.

### Compiler directives for cleanup

**What it is**: `#if CLEAN27` directives wrap obsolete code that will be removed when version 27.0 becomes the minimum supported version. The old Send Mode field, related enum values, and migration logic are all wrapped in these directives.

**Where it appears**: Throughout table and page extensions where the old Send Mode field was referenced.

**Why it exists**: Platform policy requires deprecated features to remain available for at least one major version to allow customers time to upgrade. The directives let developers see what code is temporary.

**What to do instead**: For new deprecations, use ObsoleteState and ObsoleteTag attributes without compiler directives. Move migration logic entirely into upgrade codeunits instead of maintaining parallel code paths. This keeps production code cleaner and makes the upgrade codeunit the single source of truth for breaking changes.

### Magic strings for API endpoints

**What it is**: Endpoint paths like '/einvoicing/documents', '/scs/companies', '/einvoicing/mandates' are hardcoded string literals scattered throughout Requests.Codeunit.al and Authentication.Codeunit.al.

**Where it appears**: Every method that constructs an HttpRequestMessage has at least one endpoint string literal.

**Why it exists**: These endpoints are stable (defined by Avalara's API contract) and unlikely to change. The connector was written quickly to match a fixed API version.

**What to do instead**: Define endpoint constants in a dedicated codeunit or as fields in the Connection Setup table (for per-environment overrides). Example:
```al
codeunit 50100 "Avalara Endpoints"
{
    procedure GetMandatesEndpoint(): Text
    begin
        exit('/einvoicing/mandates');
    end;
}
```
This centralizes endpoint definitions and makes API version upgrades easier.

### No validation on mandate format

**What it is**: The connector parses mandate IDs by splitting on '-' and taking the first segment as the country code (e.g., 'NO-peppol-bis' yields 'NO'). There's no validation that the mandate actually matches this format.

**Where it appears**: Metadata.Codeunit.al, SetMandate() method.

**Why it exists**: All Avalara mandates observed during development followed COUNTRY-MANDATE format. The code assumed this would always be true.

**What to do instead**: Validate mandate format and fail fast if it's unexpected. Example:
```al
if StrPos(MandateId, '-') = 0 then
    Error('Mandate ID must be in COUNTRY-MANDATE format: %1', MandateId);
```
This surfaces API contract changes immediately instead of silently producing wrong metadata.
