# Business logic

## Core operation pattern

Every file operation in `ExtBlobStoConnectorImpl.Codeunit.al` follows the same structure: initialize the blob client, perform the Azure operation, validate the response. The initialization is the critical gate -- it enforces account existence, disabled-state checks, and secret retrieval before any network call happens.

```mermaid
flowchart TD
    A[Interface method called] --> B[InitBlobClient]
    B --> C{Account exists?}
    C -- No --> D[Error: not registered]
    C -- Yes --> E{Account disabled?}
    E -- Yes --> F[Error: account disabled]
    E -- No --> G[GetSecret from IsolatedStorage]
    G --> H{Auth type?}
    H -- SasToken --> I[UseReadySAS]
    H -- SharedKey --> J[CreateSharedKey]
    I --> K[Initialize ABS Blob Client]
    J --> K
    K --> L[Execute Azure operation]
    L --> M{Response successful?}
    M -- No --> N[Error with response message]
    M -- Yes --> O[Return result]
```

## Account registration

The registration flow is wizard-driven. The framework calls `RegisterAccount()`, which opens the wizard page modally. The page uses a temporary source table -- nothing is persisted until the user completes the wizard.

```mermaid
flowchart TD
    A[Framework calls RegisterAccount] --> B[Open wizard page modal]
    B --> C[User enters name, storage account, auth type, secret]
    C --> D[User enters or looks up container name]
    D --> E{Container lookup?}
    E -- Yes --> F[ABS Container Client.ListContainers]
    F --> G[Show container lookup page]
    G --> H[User selects container]
    E -- No --> H[User types container name]
    H --> I{IsAccountValid?}
    I -- No --> J[Next button disabled]
    I -- Yes --> K[User clicks Next]
    K --> L[CreateAccount: generate GUID, store secret, insert record]
    L --> M[Return File Account to framework]
```

The `IsAccountValid()` check requires all three fields -- Name, Storage Account Name, and Container Name -- to be non-empty. The secret is validated only implicitly when the user attempts a container lookup.

## Directory simulation

Azure Blob Storage has no directory concept. The connector fakes it using a marker file named `BusinessCentral.FileSystem.txt`. This is the most surprising part of the implementation.

```mermaid
flowchart TD
    A[CreateDirectory called] --> B{DirectoryExists?}
    B -- Yes --> C[Error: directory already exists]
    B -- No --> D[Create marker file at path/BusinessCentral.FileSystem.txt]
    D --> E[Upload via CreateFile with marker content]

    F[ListDirectories called] --> G[ListBlobs with prefix and delimiter]
    G --> H[Filter: Resource Type = Directory]
    H --> I[Return matching entries]

    J[DeleteDirectory called] --> K[ListFiles + ListDirectories at path]
    K --> L{Only marker file present?}
    L -- No --> M[Error: directory not empty]
    L -- Yes --> N[DeleteFile marker blob]
```

The marker file content is a human-readable message: "This is a directory marker file created by Business Central. It is safe to delete it." If someone deletes this marker outside of BC, the directory vanishes from BC's perspective even though files at that path still exist in blob storage.

Note that `DeleteDirectory` enforces emptiness by listing both files and subdirectories. The filter `TempFileAccountContent.SetFilter(Name, '<>%1', MarkerFileNameTok)` excludes the marker file itself from the emptiness check.

## Listing and pagination

File and directory listing operations page through results in batches of 500 (`MaxResults(500)` in `InitOptionalParameters`). The `FilePaginationData` codeunit carries the continuation token (`NextMarker`) between calls. After each batch, `ValidateListingResponse` updates the marker and sets `EndOfListing` when no more pages remain.

ListFiles uses the `/` delimiter to scope results to the current directory level and filters out entries with empty `Blob Type` (directory placeholders) and the marker file. ListDirectories omits the delimiter to get prefix-based grouping and filters for `Resource Type::Directory`.

## MoveFile

MoveFile deserves special attention because it is not atomic. The implementation calls `CopyBlob(target, source)` followed by `DeleteBlob(source)`. If the copy succeeds but the delete fails, the file ends up in both locations. The caller gets an error (from the failed delete), but the copy has already completed and will not be rolled back. There is no transaction boundary or compensation logic.
