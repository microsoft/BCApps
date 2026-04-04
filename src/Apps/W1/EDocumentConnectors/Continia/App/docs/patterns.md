# Implementation Patterns

## Authentication and Token Management

### Session-Based Token Caching

**ContiniaSessionManager** (SingleInstance codeunit)

Caches authentication tokens across HTTP requests within the same session to avoid repeated authentication overhead.

**Token refresh logic:**
- 25% threshold: Request new token when 25% of lifetime remains
- 95% expiry threshold: Force refresh if token is 95% expired
- 23-hour grace period: Fallback expiry calculation if CDN doesn't return explicit expiry time

**Security:**
- Token access methods marked `NonDebuggable` to prevent token exposure in debugger
- Tokens stored in session memory only, never persisted to database

## API Communication

### XML Serialization

All CDN API calls use XML payloads, not JSON. **ContiniaApiRequests** (1126 lines) handles:
- Request serialization to XML
- Response deserialization from XML
- HTTP verb abstraction (GET/POST/PATCH/DELETE)

**ExecuteRequest() overloads:**
```al
ExecuteRequest(Method: Enum "Http Method"; Endpoint: Text): Text
ExecuteRequest(Method: Enum "Http Method"; Endpoint: Text; RequestBody: Text): Text
```

### Pagination Pattern

CDN returns total count via `X-Total-Count` HTTP header. The connector loops until all records are retrieved:

```al
repeat
    Response := GetBatch(Offset, BatchSize);
    ProcessRecords(Response);
    HandledRecordsCount += Response.Count();
    Offset += BatchSize;
until (HandledRecordsCount >= TotalCount) or (Response.Count() = 0);
```

**Parameters:**
- Batch size: 100 records
- Used for: participant profiles, identifiers, document lists

## Data Transfer Objects

### Temporary Tables as DTOs

The onboarding flow uses temporary table copies to stage changes before committing:

**Continia Participation** (temp)
- Staged changes to participation status
- `IsParticipationChanged()` compares temp vs persistent records
- PATCH request only sent if changes detected

**Continia Activated Prof.** (temp)
- Staged profile activations
- Prevents unnecessary API calls when user cancels wizard

This pattern avoids partial state if wizard is abandoned mid-flow.

## Enum and API String Mapping

The CDN API uses suffixed enum strings that don't match BC enum names directly:

**API enum formats:**
- `DraftEnum` -- profiles in draft state
- `ConnectedEnum` -- profiles in connected state

**Mapping approach:**
Dedicated conversion procedures translate between BC enum values and CDN API strings.

**Example:** `Status` enum in BC maps to `StatusDraftEnum` and `StatusConnectedEnum` strings in API requests.

## Conflict Detection

### Timestamp-Based Optimistic Locking

PATCH requests include `Cdn Timestamp` field from the cached record. The CDN API:
1. Compares submitted timestamp against current record timestamp
2. Rejects request if timestamp is stale (409 Conflict)
3. Returns updated timestamp in response

This prevents lost updates when multiple users or systems modify the same record.

## Legacy Patterns

The following patterns exist in the current implementation but represent technical debt:

### Hardcoded BaseAppId GUID

Version detection uses a hardcoded GUID for the base application:
```al
BaseAppId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
```

This couples the connector to Microsoft's base app identity and breaks in environments with modified base apps.

**Better approach:** Use application system table queries or version APIs.

### Mixed Concerns in ContiniaApiUrl

The URL builder codeunit also contains localization logic for AU/NZ and NL region handling. This violates single responsibility and complicates testing.

**Better approach:** Separate URL construction from region resolution.

### Global Error String Variables

Error messages are stored in global text variables instead of being defined as labels or in separate error message resources:
```al
var
    ServiceIntegrationErr: Label 'Service Integration must be Continia';
```

**Better approach:** Centralize error messages in a dedicated error management codeunit or use label resources with consistent naming.

### Overly Broad Permission Requests

ContiniaApiRequests requests `TableData` permissions for multiple tables that it only reads, not modifies:
```al
Permissions = tabledata "E-Document Service" = r,
              tabledata "Continia Connection Setup" = r;
```

The `tabledata` keyword is deprecated. Modern AL uses `table` for read-only access.

**Better approach:** Request minimal permissions using the `table` keyword for read scenarios.

## Recommended Patterns for Extensions

If you extend the Continia connector via the URL override events:

1. **Cache derived URLs** -- Don't recompute regional URLs on every request
2. **Honor timestamp semantics** -- If you intercept PATCH operations, preserve conflict detection
3. **Respect NonDebuggable** -- Don't log or expose token values
4. **Test pagination edge cases** -- Ensure your endpoint handles offset/limit correctly
5. **Validate XML schema** -- The CDN expects specific XML structures; validate before sending
