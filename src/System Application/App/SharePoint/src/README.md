# SharePoint Graph API Module — Architecture

## 1. Module Dependency Graph

How the SharePoint Graph API module depends on shared System Application modules.

```mermaid
graph TD
    subgraph SharePoint Module
        REST["SharePoint Client (REST)<br/>(Codeunit 9100)"]
        GRAPH["SharePoint Graph Client<br/>(Codeunit 9119)"]
    end

    SPAuth["SharePoint Authorization<br/><br/>- Authorization Code flow<br/>- Client Credentials"]
    MSGraph["Microsoft Graph Module<br/><br/>- Graph Client (9350)<br/>- Graph Authorization (9355)<br/>- Optional Parameters<br/>- Pagination<br/>- Enums"]
    OAuthMod["OAuth Module"]
    RestClientMod["Rest Client Module<br/><br/>- RestClient codeunit<br/>- HttpClientHandler interface<br/>- HttpAuthentication interface<br/>- HttpRequestMessage / Response<br/>- HttpAuthOAuthClientCredentials"]
    URIMod["URI Module"]
    BLOBMod["BLOB Storage"]
    DotNetMod["DotNet Aliases"]

    REST --> SPAuth
    REST --> RestClientMod
    GRAPH --> MSGraph
    SPAuth --> OAuthMod
    MSGraph --> RestClientMod
    RestClientMod --> URIMod
    RestClientMod --> BLOBMod
    RestClientMod --> DotNetMod

    style GRAPH fill:#2d6a4f,stroke:#1b4332,color:#fff
    style MSGraph fill:#264653,stroke:#1d3557,color:#fff
```

## 2. Internal Layered Architecture

Detailed internal architecture of the SharePoint Graph API module.

```mermaid
graph TD
    subgraph PUBLIC["PUBLIC API LAYER"]
        Client["SharePointGraphClient<br/>(9119)<br/>Public Facade"]
        Response["SharePointGraphResponse<br/>(9129)<br/>Public Return Type"]
        OptParams["Graph Optional Parameters<br/>(from Microsoft Graph Module)"]
    end

    subgraph INTERNAL["INTERNAL IMPLEMENTATION LAYER"]
        Impl["SharePointGraphClientImpl<br/>(9120)<br/><br/>- URL parsing<br/>- SiteId / DriveId caching<br/>- Business logic<br/>- Large file chunking<br/>- Async copy orchestration<br/>- Item update / rename"]

        UriBuilder["SP Graph Uri Builder<br/>(9121)<br/><br/>/sites/{siteId}/lists<br/>/sites/{siteId}/drives<br/>/sites/{siteId}/drive/items<br/>/sites/{siteId}/drive/root:/path<br/>+ OData params"]

        ReqHelper["SP Graph Req. Helper<br/>(9123)<br/><br/>- Get / Post / Put<br/>- Patch / Delete / PutContent<br/>- DownloadFile<br/>- DownloadChunk<br/>- UploadFile<br/>- UploadChunk<br/>- CreateUploadSession<br/>- GetAllPages"]

        Parser["SP Graph Parser<br/>(9122)<br/><br/>- ParseListCollection<br/>- ParseListItemCollection<br/>- ParseDriveItemCollection<br/>- ParseDriveCollection<br/>- ExtractNextLink<br/><br/>JSON ➜ Temp Records"]
    end

    subgraph EXTERNAL["EXTERNAL DEPENDENCIES (other modules)"]
        GraphClient["Graph Client (9350)<br/>Microsoft Graph Module<br/><br/>- HTTP methods<br/>- Pagination<br/>- Base URL config"]
        GraphAuth["Graph Authorization (9355)<br/><br/>- Client Credentials (Secret)<br/>- Client Credentials (Certificate)"]
        RestMod["Rest Client Module<br/><br/>RestClient ➜ HttpClientHandler ➜ HTTPS"]
    end

    Client --> Impl
    Client --> Response
    Client -.-> OptParams
    Impl --> UriBuilder
    Impl --> ReqHelper
    Impl --> Parser
    Impl --> Response
    ReqHelper --> GraphClient
    GraphClient --> GraphAuth
    GraphClient --> RestMod

    style PUBLIC fill:#f0f0f0,stroke:#333,color:#000
    style INTERNAL fill:#e8e8e8,stroke:#333,color:#000
    style EXTERNAL fill:#e0e0e0,stroke:#333,color:#000
    style Client fill:#2d6a4f,stroke:#1b4332,color:#fff
    style Response fill:#2d6a4f,stroke:#1b4332,color:#fff
```

## 3. Data Model (Temporary Tables)

```mermaid
erDiagram
    SHAREPOINT_GRAPH_DRIVE {
        Text_250 Id PK
        Text_250 Name
        Text_50 DriveType
        Text_2048 Description
        Text_2048 WebUrl
        Text_250 OwnerName
        Text_250 OwnerEmail
        DateTime CreatedDateTime
        DateTime LastModifiedDateTime
        BigInteger QuotaTotal
        BigInteger QuotaUsed
        BigInteger QuotaRemaining
        Text_50 QuotaState
    }

    SHAREPOINT_GRAPH_LIST {
        Text_250 Id PK
        Text_250 DisplayName
        Text_250 Name
        Text_2048 Description
        Text_2048 WebUrl
        Text_100 Template
        Text_250 ListItemEntityType
        Text_250 DriveId FK
        DateTime CreatedDateTime
        DateTime LastModifiedDateTime
    }

    SHAREPOINT_GRAPH_LIST_ITEM {
        Text_250 Id PK
        Text_250 ListId FK
        Text_250 Title
        Text_100 ContentType
        Text_2048 WebUrl
        DateTime CreatedDateTime
        DateTime LastModifiedDateTime
        Blob FieldsJson
    }

    SHAREPOINT_GRAPH_DRIVE_ITEM {
        Text_250 Id PK
        Text_250 DriveId FK
        Text_250 Name
        Boolean IsFolder
        Text_50 FileType
        BigInteger Size
        Text_250 ParentId
        Text_2048 Path
        Text_2048 WebUrl
        DateTime CreatedDateTime
        DateTime LastModifiedDateTime
    }

    SHAREPOINT_GRAPH_DRIVE ||--o{ SHAREPOINT_GRAPH_DRIVE_ITEM : "contains"
    SHAREPOINT_GRAPH_DRIVE ||--o{ SHAREPOINT_GRAPH_LIST : "has"
    SHAREPOINT_GRAPH_LIST ||--o{ SHAREPOINT_GRAPH_LIST_ITEM : "has items"
```

> **Note:** All tables are `Access = Public`, `Temporary = true`, `Extensible = false`, `DataClassification = SystemMetadata`. The primary key is `Id` in every table; List Item and Drive Item additionally define secondary keys `(ListId, Id)` and `(DriveId, Id)`.

## 4. REST API vs Graph API — Side-by-Side

```mermaid
graph LR
    subgraph REST["SharePoint REST API (existing)"]
        direction TB
        R_EP["Endpoint: https://site/_api/web/..."]
        R_Auth["Auth: SharePoint Authorization<br/>(Auth Code + Client Creds)"]
        R_Facade["Facade: SharePointClient (9100)"]
        R_Impl["Impl: SharePointClientImpl (9101)"]
        R_Helpers["Helpers:<br/>UriBuilder (9110)<br/>RequestHelper (9109)<br/>HttpContent (9107)<br/>OperationResponse (9108)"]
        R_Models["Models:<br/>SharePoint List<br/>SharePoint List Item<br/>SharePoint File<br/>SharePoint Folder<br/>SharePoint List Item Atch"]
        R_Return["Returns: Boolean"]
        R_Caps["Capabilities:<br/>+ Lists and Items<br/>+ Files and Folders<br/>+ Attachments<br/>+ Integration events<br/>- No large file chunking<br/>- No OData query params<br/>- No Copy/Move<br/>- No conflict behavior"]

        R_EP --- R_Auth --- R_Facade --- R_Impl --- R_Helpers --- R_Models --- R_Return --- R_Caps
    end

    subgraph GRAPH["SharePoint Graph API (NEW)"]
        direction TB
        G_EP["Endpoint: https://graph.microsoft.com<br/>/v1.0/sites/id/..."]
        G_Auth["Auth: Graph Authorization<br/>(Client Secret / Certificate)"]
        G_Facade["Facade: SPGraphClient (9119)"]
        G_Impl["Impl: SPGraphClientImpl (9120)"]
        G_Helpers["Helpers:<br/>UriBuilder (9121)<br/>ReqHelper (9123)<br/>Parser (9122)"]
        G_Models["Models:<br/>SP Graph List (9130)<br/>SP Graph List Item (9131)<br/>SP Graph Drive Item (9132)<br/>SP Graph Drive (9133)"]
        G_Return["Returns: SPGraphResponse codeunit<br/>(success, error, callstack, diagnostics)"]
        G_Caps["Capabilities:<br/>+ Lists and Items<br/>+ Drives and Drive Items<br/>+ Item updates (list item fields,<br/>drive item properties, rename)<br/>+ Large file upload/download (100MB)<br/>+ OData: filter, select, expand, orderby<br/>+ Copy (async) / Move<br/>+ Conflict behavior (replace/rename/fail)<br/>+ Path-based and ID-based ops<br/>+ Auto-pagination<br/>+ Diagnostics interface"]

        G_EP --- G_Auth --- G_Facade --- G_Impl --- G_Helpers --- G_Models --- G_Return --- G_Caps
    end

    style GRAPH fill:#f0fdf4,stroke:#2d6a4f,color:#000
    style REST fill:#fafafa,stroke:#666,color:#000
```

## 5. Request Flow Sequence

How a typical Graph API call (e.g., `GetLists`) flows through the layers.

```mermaid
sequenceDiagram
    participant Consumer as Consumer Code
    participant Facade as SharePointGraphClient<br/>(9119 - Public)
    participant Impl as SPGraphClientImpl<br/>(9120 - Internal)
    participant Uri as UriBuilder<br/>(9121)
    participant Req as ReqHelper<br/>(9123)
    participant GC as Graph Client<br/>(9350 - MS Graph Module)
    participant Rest as Rest Client<br/>(HTTP)
    participant API as graph.microsoft.com
    participant Parser as SPGraphParser<br/>(9122)
    participant Resp as SPGraphResponse<br/>(9129)

    Consumer->>Facade: Initialize(SharePointUrl, GraphAuth)
    Facade->>Impl: Initialize(SharePointUrl, GraphAuth)
    Impl->>Impl: Store URL, set IsInitialized

    Consumer->>Facade: GetLists(var GraphLists)
    Facade->>Impl: GetLists(var GraphLists, OptParams)

    Note over Impl: EnsureInitialized()
    Note over Impl: EnsureSiteId() — lazy load

    alt SiteId not cached
        Impl->>Uri: GetSiteByHostAndPathEndpoint()
        Uri-->>Impl: /sites/{host}:{path}
        Impl->>Req: Get(endpoint)
        Req->>GC: Get(endpoint, response)
        GC->>Rest: HTTP GET
        Rest->>API: GET /v1.0/sites/{host}:{path}
        API-->>Rest: 200 OK + JSON
        Rest-->>GC: HttpResponseMessage
        GC-->>Req: JSON response
        Req-->>Impl: SiteId extracted & cached
    end

    Impl->>Uri: GetListsEndpoint()
    Uri-->>Impl: /sites/{siteId}/lists

    Impl->>Req: GetAllPages(endpoint, optParams, jsonArray)
    loop For each page
        Req->>GC: Get(endpoint, response)
        GC->>Rest: HTTP GET
        Rest->>API: GET /v1.0/sites/{siteId}/lists
        API-->>Rest: 200 OK + JSON (+ @odata.nextLink)
        Rest-->>GC: HttpResponseMessage
        GC-->>Req: JSON page
        Note over Req: Append to jsonArray<br/>Check @odata.nextLink
    end
    Req-->>Impl: Complete JsonArray

    Impl->>Parser: ParseListCollection(jsonArray, var GraphLists)
    Note over Parser: JSON ➜ Temp Records

    Impl->>Resp: SetSuccess()
    Impl-->>Facade: SPGraphResponse
    Facade-->>Consumer: SPGraphResponse + populated GraphLists

    Note over Consumer: Response.IsSuccessful()<br/>GraphLists.FindSet()
```

## 6. Object Registry

| ID | Object Name | Type | Access |
|----|------------|------|--------|
| **9119** | SharePoint Graph Client | Codeunit | **Public** — Entry point |
| 9120 | SharePoint Graph Client Impl. | Codeunit | Internal |
| 9121 | SharePoint Graph Uri Builder | Codeunit | Internal |
| 9122 | SharePoint Graph Parser | Codeunit | Internal |
| 9123 | SharePoint Graph Req. Helper | Codeunit | Internal |
| **9129** | SharePoint Graph Response | Codeunit | **Public** — Return type |
| **9130** | SharePoint Graph List | Table | **Public** — Model |
| **9131** | SharePoint Graph List Item | Table | **Public** — Model |
| **9132** | SharePoint Graph Drive Item | Table | **Public** — Model |
| **9133** | SharePoint Graph Drive | Table | **Public** — Model |

> All tables: `Temporary = true`, `Extensible = false`, `DataClassification = SystemMetadata`

## 7. Test Coverage

```mermaid
graph TD
    subgraph Tests["Test Suite (77 test procedures)"]
        subgraph Core["SharePoint Graph Client Test (132984) — 31 tests"]
            T1["Authorization invoked"]
            T2["Request URI format"]
            T3["GetLists / CreateList"]
            T4["GetListItems / CreateListItem"]
            T5["GetListItem / UpdateListItem<br/>+ validation + buffer collision"]
            T6["GetDrives / GetRootItems"]
            T7["CreateFolder"]
            T8["SharePoint URL validation"]
            T9["Path traversal / special char encoding"]
            T10["Error: 401 Unauthorized"]
        end

        subgraph Files["SharePoint Graph File Test (132983) — 7 tests"]
            T11["UploadFile + filename encoding"]
            T12["DownloadFile / DownloadFileByPath"]
            T13["GetDriveItemByPath"]
            T14["GetFolderItems"]
            T15["Untrusted upload URL rejected<br/>(large file session)"]
        end

        subgraph Advanced["SharePoint Graph Advanced Test (132985) — 39 tests"]
            T16["OData: $select, $filter, $orderby"]
            T17["OData: $expand"]
            T18["Pagination (first page)"]
            T19["ConflictBehavior (Replace)"]
            T20["GetDefaultDrive / GetDrive"]
            T21["GetItemsByPath"]
            T22["Delete (by ID, by path, 404)"]
            T23["ItemExists (by ID, by path)"]
            T24["CopyItem / CopyItemByPath"]
            T25["MoveItem / MoveItemByPath"]
            T26["UpdateDriveItem / RenameDriveItem<br/>(+ByPath variants + validation)"]
            T27["Multi-response mock: sequences,<br/>queue exhaustion, header replay,<br/>sticky mode"]
            T28["Errors: 400, 403, 429, 500"]
        end
    end

    Mock["Mocked HTTP via<br/>HttpClientHandler interface<br/>(sticky + queued responses,<br/>request recording)<br/>No real API calls"]

    Tests --> Mock

    style Core fill:#d4edda,stroke:#28a745
    style Files fill:#cce5ff,stroke:#0d6efd
    style Advanced fill:#fff3cd,stroke:#ffc107
```

## 8. Public API Surface Summary

```mermaid
mindmap
  root((SharePoint<br/>Graph Client))
    Initialization
      Initialize with URL + Auth
      Initialize with API Version
      Initialize with Base URL
      Initialize with HttpClientHandler
    Lists
      GetLists
      GetList by ID
      CreateList
    List Items
      GetListItems
      GetListItem by ID
      CreateListItem with JSON
      CreateListItem with Title
      UpdateListItem fields
    Drives
      GetDefaultDrive
      GetDrives
      GetDrive by ID
    Drive Items
      GetRootItems
      GetFolderItems
      GetItemsByPath
      GetDriveItem by ID
      GetDriveItemByPath
    File Upload
      UploadFile 4 overloads
      UploadLargeFile 4 overloads
    File Download
      DownloadFile
      DownloadFileByPath
      DownloadLargeFile
      DownloadLargeFileByPath
    Item Management
      DeleteItem / DeleteItemByPath
      ItemExists / ItemExistsByPath
      CopyItem / CopyItemByPath async
      MoveItem / MoveItemByPath
      UpdateDriveItem / UpdateDriveItemByPath
      RenameDriveItem / RenameDriveItemByPath
    Folder Creation
      CreateFolder 4 overloads
      ConflictBehavior support
    OData Helpers
      SetODataFilter
      SetODataSelect
      SetODataExpand
      SetODataOrderBy
    Diagnostics
      GetDiagnostics
```

## 9. Functional Comparison: REST API vs Graph API

High-level capability comparison from a **business functionality** perspective.

### Functional Area Coverage

```mermaid
graph TD
    subgraph BOTH["Shared Functional Areas"]
        direction TB
        B1["List Management<br/>Create and browse SharePoint lists"]
        B2["List Item Management<br/>Create and read items in lists"]
        B3["File Upload<br/>Upload documents to SharePoint"]
        B4["File Download<br/>Retrieve file content"]
        B5["Folder Management<br/>Create folders, browse contents"]
        B6["Delete Operations<br/>Remove files and folders"]
        B7["Diagnostics<br/>Inspect HTTP response details"]
        B8["List Item Field Updates<br/>Modify metadata fields<br/>on existing list items"]
    end

    subgraph REST_ONLY["REST API Only"]
        direction TB
        R1["List Item Attachments<br/>Full CRUD for files attached<br/>directly to list items"]
        R3["Integration Events<br/>Extensibility hooks for<br/>custom metadata processing"]
        R4["UI File Picker<br/>Built-in browser dialog for<br/>end-user file selection"]
        R5["Client-Side Download<br/>Trigger file download<br/>directly in user's browser"]
    end

    subgraph GRAPH_ONLY["Graph API Only"]
        direction TB
        G1["Drive Management<br/>Enumerate document libraries,<br/>inspect storage quotas"]
        G2["Large File Handling<br/>Chunked upload/download for<br/>files exceeding 150MB limit"]
        G3["Copy, Move and Rename<br/>Relocate or rename files/folders<br/>within SharePoint"]
        G4["Existence Checks<br/>Verify if a file or folder<br/>exists before operating on it"]
        G5["Data Querying<br/>Filter, sort, select fields,<br/>expand relations via OData"]
        G6["Conflict Resolution<br/>Control behavior when<br/>name collisions occur"]
        G7["Auto-Pagination<br/>Transparently retrieve all<br/>pages of large result sets"]
    end

    style BOTH fill:#e3f2fd,stroke:#1565c0
    style REST_ONLY fill:#fff3e0,stroke:#e65100
    style GRAPH_ONLY fill:#e8f5e9,stroke:#1b5e20
```

### Authentication and Connection

| Aspect | REST API | Graph API |
|--------|----------|-----------|
| **Protocol** | SharePoint REST endpoints (`/_api/web/`) | Microsoft Graph (`graph.microsoft.com`) |
| **Auth model** | SharePoint-specific authorization (Auth Code + Client Credentials with Request Digest) | OAuth 2.0 Client Credentials (Client Secret or Certificate) via Microsoft Graph |
| **Auth module** | SharePoint Authorization (dedicated module) | Microsoft Graph Authorization (shared across all Graph consumers) |
| **API versioning** | Fixed endpoint, no version control | Selectable: `v1.0` (stable) or `beta` (preview) |
| **Base URL** | Tied to SharePoint site URL | Configurable (defaults to `graph.microsoft.com`) |
| **Testability** | Relies on integration event subscribers | `HttpClientHandler` interface injection + test helpers |

### Resource Addressing

```mermaid
graph LR
    subgraph REST["REST API Addressing"]
        direction TB
        R1["Lists by Title or GUID"]
        R2["Items by integer ID within list"]
        R3["Files by ServerRelativeUrl<br/>/sites/Team/Shared Documents/report.pdf"]
        R4["Entities by OData.Id<br/>full URL returned in response metadata"]
    end

    subgraph GRAPH["Graph API Addressing"]
        direction TB
        G1["Lists by opaque Graph ID"]
        G2["Items by opaque Graph ID"]
        G3["Files by Graph ID<br/>01ABCDEF12345"]
        G4["Files by human-readable Path<br/>Documents/Reports/Q1.xlsx"]
        G5["Drives by Graph Drive ID"]
    end

    style REST fill:#fafafa,stroke:#666
    style GRAPH fill:#f0fdf4,stroke:#2d6a4f
```

> **Key difference:** REST API requires SharePoint-specific URLs (ServerRelativeUrl, OData.Id) that couple callers to site structure. Graph API offers both opaque IDs (stable across renames) and human-readable paths (intuitive for users).

### Error Handling Philosophy

| Aspect | REST API | Graph API |
|--------|----------|-----------|
| **Return type** | `Boolean` (true/false) | `Codeunit "SharePoint Graph Response"` |
| **Error message** | Must call `GetDiagnostics()` separately on the client | `Response.GetError()` — embedded in the response |
| **Error context** | HTTP status + reason phrase | Error message + AL call stack at failure point + HTTP diagnostics |
| **Checking pattern** | `if not Client.GetLists(List) then ...` | `Response := Client.GetLists(List);`<br/>`if not Response.IsSuccessful() then ...` |
| **Multiple calls** | Diagnostics overwritten by each call | Each response holds its own diagnostics independently |

### File Operations Depth

| Capability | REST API | Graph API |
|-----------|----------|-----------|
| **Small file upload** | Yes (+ UI file picker) | Yes (to default or specific drive) |
| **Large file upload** | No | Yes — chunked upload sessions |
| **Small file download** | Yes (to InStream, TempBlob, or browser) | Yes (to TempBlob) |
| **Large file download** | No | Yes — 100MB chunked download |
| **Name collision handling** | No control | Replace, Rename, or Fail |
| **Copy files** | No | Yes (asynchronous server-side) |
| **Move files** | No | Yes (synchronous) |
| **Rename / update item properties** | No | Yes (by ID or path) |
| **Check if file exists** | Only for folders (FolderExists) | Yes, for any item (by ID or path) |
| **Delete by path** | Only by ServerRelativeUrl or OData.Id | Yes, by ID or by path |

### Data Querying and Retrieval

| Capability | REST API | Graph API |
|-----------|----------|-----------|
| **Filter results** | No | Yes — `$filter` OData expressions |
| **Select specific fields** | No | Yes — `$select` to reduce payload |
| **Sort results** | No | Yes — `$orderby` with asc/desc |
| **Expand related data** | Limited (`$expand` via URL hacking) | Yes — `$expand` as first-class feature |
| **Pagination** | Manual (caller must handle) | Automatic — `GetAllPages` retrieves everything |
| **Single item retrieval** | Get by ServerRelativeUrl | Get by ID or by path |

### Feature Matrix Summary

| Functional Area | REST | Graph |
|----------------|:----:|:-----:|
| Browse lists | Yes | Yes |
| Create lists (with template) | Yes | Yes (with template choice) |
| Read list items | Yes | Yes + OData filtering + single item by ID |
| Create list items | Yes (needs EntityType) | Yes (simple JSON or title) |
| Update list item fields | Yes (single field) | Yes (multiple fields via JSON) |
| **List item attachments** | **Yes (full CRUD)** | No |
| Browse folders | Yes | Yes |
| Create folders | Yes | Yes + conflict behavior |
| Upload files | Yes + UI picker | Yes + large file + conflict |
| Download files | Yes (3 targets) | Yes + large file chunked |
| Delete files/folders | Yes | Yes + path-based |
| **Copy / Move files** | No | **Yes** |
| **Rename / update drive items** | No | **Yes (by ID or path)** |
| **Check item existence** | Folders only | **Yes (any item)** |
| **Drive/library management** | No | **Yes (enumerate, quotas)** |
| **OData query support** | No | **Yes (filter, select, sort, expand)** |
| **Auto-pagination** | No | **Yes** |
| **Large file support** | No | **Yes (100MB chunks)** |
| **Conflict resolution** | No | **Yes (replace/rename/fail)** |
| **Integration events** | **Yes** | No |
| **UI interactions** | **Yes (file picker, browser download)** | No (server-side only) |
| Rich error responses | Basic (boolean + diagnostics) | **Yes (message + callstack + HTTP)** |

## 10. Architecture and Design Patterns

Patterns identified in the SharePoint Graph API module, organized by category.

### Structural Patterns

```mermaid
graph TD
    subgraph FACADE["Facade Pattern"]
        direction LR
        F_Consumer["Consumer Code"]
        F_Facade["SharePointGraphClient<br/>(9119 — Public)"]
        F_Impl["SharePointGraphClientImpl<br/>(9120 — Internal)"]
        F_Consumer -->|"calls simple API"| F_Facade -->|"delegates"| F_Impl
    end

    subgraph SOC["Separation of Concerns"]
        direction LR
        S1["Facade<br/>9119<br/>Public API"]
        S2["Impl<br/>9120<br/>Business Logic"]
        S3["ReqHelper<br/>9123<br/>HTTP"]
        S4["UriBuilder<br/>9121<br/>Endpoints"]
        S5["Parser<br/>9122<br/>JSON Mapping"]
        S6["Response<br/>9129<br/>Result"]
        S1 --> S2 --> S3
        S2 --> S4
        S2 --> S5
        S2 --> S6
    end

    subgraph DI["Dependency Injection"]
        direction LR
        DI1["Graph Authorization<br/>(Interface)"]
        DI2["Http Client Handler<br/>(Interface)"]
        DI3["HTTP Diagnostics<br/>(Interface)"]
        DI_Impl["ClientImpl"]
        DI1 -->|"injected via Initialize()"| DI_Impl
        DI2 -->|"injected for testing"| DI_Impl
        DI3 -->|"exposed via Response"| DI_Impl
    end

    style FACADE fill:#e3f2fd,stroke:#1565c0
    style SOC fill:#f3e5f5,stroke:#7b1fa2
    style DI fill:#e8f5e9,stroke:#2e7d32
```

> **Facade** — `SharePointGraphClient` (9119) is a thin public shell. Every method delegates to `SharePointGraphClientImpl` (9120). Consumers never touch internal helpers directly.
>
> **Separation of Concerns** — Each codeunit has a single responsibility: facade exposes API, impl orchestrates logic, ReqHelper handles HTTP, UriBuilder constructs endpoints, Parser maps JSON, Response wraps results.
>
> **Dependency Injection** — Authorization and HTTP handling are injected as interfaces. This decouples the module from specific auth implementations and enables mock-based testing.

### Data and Response Patterns

```mermaid
graph TD
    subgraph RESPONSE["Response Object Pattern"]
        direction TB
        RO_Op["Any operation<br/>e.g. GetLists()"]
        RO_Resp["SharePointGraphResponse<br/>(Codeunit 9129)"]
        RO_Check["Consumer inspects:<br/>IsSuccessful()<br/>GetError()<br/>GetErrorCallStack()<br/>GetHttpDiagnostics()"]
        RO_Op -->|"returns"| RO_Resp -->|"queried by"| RO_Check
    end

    subgraph DTO["Temporary Record as DTO"]
        direction TB
        DTO_API["Graph API JSON Response"]
        DTO_Parser["Parser (9122)<br/>maps JSON fields"]
        DTO_Record["Temporary Table<br/>(in-memory only,<br/>never persisted)"]
        DTO_Consumer["Consumer reads<br/>strongly-typed fields"]
        DTO_API --> DTO_Parser --> DTO_Record --> DTO_Consumer
    end

    subgraph BLOB["Blob for Dynamic Data"]
        direction TB
        BL_Json["List item custom fields<br/>(vary per list)"]
        BL_Blob["FieldsJson: Blob<br/>(stored as UTF-8 JSON)"]
        BL_Access["GetFieldsJson()<br/>GetFieldValue(name)"]
        BL_Json --> BL_Blob --> BL_Access
    end

    style RESPONSE fill:#fff3e0,stroke:#e65100
    style DTO fill:#e8f5e9,stroke:#2e7d32
    style BLOB fill:#fce4ec,stroke:#c62828
```

> **Response Object** — Every operation returns a `SharePointGraphResponse` codeunit instead of a boolean. It bundles success/failure status, error message, AL call stack captured at error time, and HTTP diagnostics. Each response is independent — making multiple calls doesn't overwrite previous diagnostics.
>
> **Temporary Records as DTOs** — Tables 9130–9133 are all `TableType = Temporary`. They serve as in-memory data transfer objects, never written to the database. The parser maps JSON to typed fields; consumers get IntelliSense and compile-time safety.
>
> **Blob for Dynamic Data** — List item custom fields vary per SharePoint list. Instead of defining columns for every possible field, the module stores the raw JSON in a `Blob` field and provides `GetFieldValue(FieldName)` for on-demand access.

### Performance Patterns

```mermaid
graph TD
    subgraph LAZY["Lazy Loading + Caching"]
        direction TB
        L1["First call to any operation"]
        L2{"SiteId cached?"}
        L3["Call Graph API<br/>/sites/host:path<br/>to resolve SiteId"]
        L4["Use cached SiteId"]
        L5{"DriveId cached?"}
        L6["Call Graph API<br/>/sites/id/drive<br/>to resolve DriveId"]
        L7["Use cached DriveId"]
        L8["Proceed with<br/>actual operation"]

        L1 --> L2
        L2 -->|"No"| L3 --> L5
        L2 -->|"Yes"| L4 --> L5
        L5 -->|"No (if needed)"| L6 --> L8
        L5 -->|"Yes"| L7 --> L8
    end

    subgraph PAGINATION["Auto-Pagination"]
        direction TB
        P1["Client calls GetLists()"]
        P2["ReqHelper.GetAllPages()"]
        P3["GET /sites/id/lists"]
        P4{"@odata.nextLink?"}
        P5["GET next page"]
        P6["Return complete<br/>JsonArray"]

        P1 --> P2 --> P3 --> P4
        P4 -->|"Yes"| P5 --> P4
        P4 -->|"No"| P6
    end

    subgraph CHUNKED["Chunked File Transfer"]
        direction TB
        C1["Large file detected"]
        C2["Upload: Create session,<br/>split into 4MB chunks<br/>(aligned to 320KiB)"]
        C3["Download: Get file size,<br/>request 100MB chunks<br/>via HTTP Range header"]
        C4["Reassemble into<br/>complete TempBlob"]

        C1 --> C2
        C1 --> C3
        C2 --> C4
        C3 --> C4
    end

    style LAZY fill:#e3f2fd,stroke:#1565c0
    style PAGINATION fill:#f3e5f5,stroke:#7b1fa2
    style CHUNKED fill:#fff3e0,stroke:#e65100
```

> **Lazy Loading + Caching** — SiteId and DefaultDriveId are resolved from the Graph API only on first use, then cached in instance variables. Changing the SharePoint URL clears the cache, forcing re-resolution.
>
> **Auto-Pagination** — Collection endpoints (lists, items, drives) automatically follow `@odata.nextLink` to retrieve all pages. The consumer receives the complete result set without manual paging logic.
>
> **Chunked Transfer** — Large file uploads use Graph API upload sessions with 4MB chunks (aligned to 320KiB multiples per Microsoft requirements). Large downloads use HTTP `Range` headers with 100MB chunks, staying under Business Central's 150MB response limit.

### API Design Patterns

```mermaid
graph TD
    subgraph DUAL["Dual Access: ID + Path"]
        direction TB
        D_ID["GetDriveItem(ItemId)"]
        D_Path["GetDriveItemByPath(ItemPath)"]
        D_Delete_ID["DeleteItem(ItemId)"]
        D_Delete_Path["DeleteItemByPath(ItemPath)"]
        D_Note["Every item operation offers<br/>both addressing modes"]

        D_ID ~~~ D_Path
        D_Delete_ID ~~~ D_Delete_Path
    end

    subgraph OVERLOAD["Method Overloading"]
        direction TB
        O1["Initialize(URL, Auth)<br/>— simplest"]
        O2["Initialize(URL, Version, Auth)<br/>— with API version"]
        O3["Initialize(URL, Base, Auth)<br/>— custom base URL"]
        O4["Initialize(URL, Ver, Auth, Handler)<br/>— for testing"]
        O_Note["Progressive complexity:<br/>simple defaults → full control"]

        O1 ~~~ O2 ~~~ O3 ~~~ O4
    end

    subgraph ODATA["OData Query Builder"]
        direction TB
        OD1["SetODataFilter(params, '$filter expr')"]
        OD2["SetODataSelect(params, 'id,name')"]
        OD3["SetODataExpand(params, 'fields')"]
        OD4["SetODataOrderBy(params, 'name asc')"]
        OD5["Pass params to any<br/>collection operation"]

        OD1 ~~~ OD2 ~~~ OD3 ~~~ OD4 --> OD5
    end

    subgraph CONFLICT["Conflict Behavior"]
        direction TB
        CF1["CreateFolder(path, name)<br/>— defaults to Fail"]
        CF2["CreateFolder(path, name, Replace)<br/>— explicit behavior"]
        CF3["UploadFile(path, name, stream)<br/>— defaults to Replace"]
        CF4["UploadFile(path, name, stream, Rename)<br/>— explicit behavior"]

        CF1 ~~~ CF2
        CF3 ~~~ CF4
    end

    style DUAL fill:#e8f5e9,stroke:#2e7d32
    style OVERLOAD fill:#e3f2fd,stroke:#1565c0
    style ODATA fill:#f3e5f5,stroke:#7b1fa2
    style CONFLICT fill:#fff3e0,stroke:#e65100
```

> **Dual Access (ID + Path)** — Most item operations come in pairs: one by opaque Graph ID (stable across renames), one by human-readable path (intuitive). Path variants either address the resource directly via the path endpoint (get, delete, update, rename) or resolve the path to an ID first where Graph requires real IDs (move, copy target folders).
>
> **Method Overloading** — Operations offer progressively complex signatures. The simplest form uses sensible defaults; advanced forms expose API version, base URL, conflict behavior, or OData parameters.
>
> **OData Query Builder** — Filter, select, expand, and orderby are set via helper methods on `GraphOptionalParameters`, then passed to any collection operation. This separates query construction from execution.
>
> **Conflict Behavior** — File/folder creation accepts an optional `Graph ConflictBehavior` enum (`Replace`, `Rename`, `Fail`). Default differs by context: uploads default to `Replace`, folder creation defaults to `Fail`.

### Error Handling and Resilience Patterns

```mermaid
graph TD
    subgraph VALIDATION["Input Validation (Fail Early)"]
        direction TB
        V1["EnsureInitialized()<br/>— error if not initialized"]
        V2["EnsureSiteId() / EnsureDefaultDriveId()<br/>— lazily resolve if missing"]
        V3["Validate parameters<br/>— empty ListId, FileName, etc."]
        V4["Proceed to API call"]
        V1 --> V2 --> V3 --> V4
    end

    subgraph SEMANTIC["Semantic HTTP Status Handling"]
        direction TB
        SE1["DELETE returns 404"]
        SE2["→ Treat as success<br/>(item already gone)"]
        SE3["ItemExists returns 404"]
        SE4["→ Set Exists := false<br/>(not an error)"]
        SE5["Download returns 206"]
        SE6["→ Expected for Range requests<br/>(partial content)"]

        SE1 --> SE2
        SE3 --> SE4
        SE5 --> SE6
    end

    subgraph DIAG["Diagnostic Chain"]
        direction TB
        DC1["Operation fails"]
        DC2["Response captures:<br/>- Error message (text)<br/>- AL call stack (SessionInformation)<br/>- HTTP status, headers, body"]
        DC3["Consumer inspects any<br/>level of detail needed"]
        DC1 --> DC2 --> DC3
    end

    style VALIDATION fill:#e8f5e9,stroke:#2e7d32
    style SEMANTIC fill:#fff3e0,stroke:#e65100
    style DIAG fill:#e3f2fd,stroke:#1565c0
```

> **Input Validation** — Every operation checks initialization state and required parameters (ListId, FileName, etc.) before issuing its HTTP call, producing descriptive AL errors instead of cryptic HTTP 400s. Site and drive IDs are resolved lazily on first use — that resolution may itself issue a discovery request.
>
> **Semantic HTTP Handling** — Not all non-2xx status codes are errors. DELETE returning 404 means the item is already gone (success). ItemExists returning 404 means "doesn't exist" (not an error). Range requests returning 206 is expected behavior for partial content.
>
> **Diagnostic Chain** — On failure, the response captures the error message, the full AL call stack at the point of failure (via `SessionInformation`), and full HTTP diagnostics. Each response is self-contained — multiple concurrent operations don't interfere.

### Testability Patterns

```mermaid
graph TD
    subgraph TESTABILITY["Testing Architecture"]
        direction TB
        T1["Production code"]
        T2["Initialize(URL, Auth)"]
        T3["Real Graph Authorization<br/>Real HttpClientHandler"]
        T4["→ Calls graph.microsoft.com"]

        T5["Test code"]
        T6["Initialize(URL, Ver, Auth, MockHandler)"]
        T7["Mock HttpClientHandler<br/>returns canned JSON"]
        T8["→ No network calls"]

        T9["SetSiteIdForTesting(id)<br/>SetDefaultDriveIdForTesting(id)"]
        T10["→ Bypass URL resolution<br/>entirely"]

        T1 --> T2 --> T3 --> T4
        T5 --> T6 --> T7 --> T8
        T5 --> T9 --> T10
    end

    style TESTABILITY fill:#f3e5f5,stroke:#7b1fa2
```

> **Interface-Based Mocking** — The `HttpClientHandler` interface can be swapped with a mock that returns predefined JSON responses. Tests verify business logic without network calls.
>
> **Test Helpers** — Internal procedures `SetSiteIdForTesting()` and `SetDefaultDriveIdForTesting()` let tests bypass the Graph API resolution step entirely, eliminating a dependency on real SharePoint sites.

### Pattern Summary

| Category | Pattern | Where | Purpose |
|----------|---------|-------|---------|
| **Structural** | Facade | Client 9119 → Impl 9120 | Hide complexity behind simple public API |
| | Separation of Concerns | All 6 codeunits | Each codeunit has single responsibility |
| | Dependency Injection | Initialize() with interfaces | Decouple auth and HTTP from logic |
| | Interface Segregation | 3 interfaces used | Small, focused contracts |
| **Data** | Response Object | Response 9129 | Rich operation results with diagnostics |
| | Temporary Records as DTO | Tables 9130–9133 | Typed in-memory data containers |
| | Blob for Dynamic Fields | ListItem.FieldsJson | Handle varying list schemas |
| | JSON Parser/Mapper | Parser 9122 | Convert API responses to models |
| **Performance** | Lazy Loading | SiteId, DriveId | Resolve only when first needed |
| | Instance Caching | SiteId, DriveId variables | Avoid repeated API resolution calls |
| | Auto-Pagination | GetAllPages + nextLink | Transparent multi-page retrieval |
| | Chunked Upload | 4MB aligned chunks | Handle files beyond size limits |
| | Chunked Download | 100MB Range requests | Stay under BC 150MB response limit |
| **API Design** | Dual Access (ID + Path) | All item operations | Flexibility for callers |
| | Method Overloading | Initialize, Upload, Create | Simple defaults → full control |
| | OData Query Builder | Optional Parameters | Composable query construction |
| | Conflict Behavior | Upload, CreateFolder | Control name collision handling |
| | Endpoint Templates | UriBuilder label constants | Centralized, typo-proof URL patterns |
| **Resilience** | Input Validation | Impl before each call | Fail early with clear messages |
| | Semantic HTTP Handling | Delete→404=OK, Exists→404=false | Context-aware status interpretation |
| | Diagnostic Chain | Response carries full context | Error message + call stack + HTTP details |
| | Path Normalization | TrimStart('/') | Standardize user input |
| **Testability** | Interface Mocking | HttpClientHandler injection | Test without network |
| | Test Helpers | SetSiteIdForTesting() | Bypass resolution in tests |
