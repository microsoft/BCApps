# Integration Root

The Integration root directory orchestrates external service communication for E-Document Core. It provides the central management layer that coordinates interface dispatch, HTTP message handling, error tracking, and status transitions for both sending documents to services and receiving documents from services. This layer implements the V2 integration architecture that replaced the monolithic V1 interface with granular, purpose-specific contracts.

## Quick reference

- **Files:** 5 (1 codeunit, 2 interfaces, 2 enums)
- **Key codeunit:** E-Doc. Integration Management (6134)
- **Primary interface:** E-Document Integration (obsolete, V1 legacy)
- **Current interface:** Service Integration enum (V2 architecture)

## What it does

E-Doc. Integration Management is the central dispatcher for all service integration operations. It receives requests from the processing layer (export, import, workflow), selects the appropriate interface implementation from the service configuration, invokes the interface method within an error-handling boundary, and updates document status based on results. The codeunit never calls service APIs directly -- it always delegates to interface implementations.

The V2 architecture split the monolithic E-Document Integration interface into seven focused interfaces: IDocumentSender (send), IDocumentReceiver (receive), IDocumentResponseHandler (async response), ISentDocumentActions (approval/cancellation), IReceivedDocumentMarker (mark-fetched), IDocumentAction (custom actions), and IConsentManager (privacy consent). Each service registers implementations via the Service Integration enum.

Integration Management handles three operation types: Send (synchronous or async document transmission), Receive (polling for inbound documents with optional mark-fetched), and Actions (post-send operations like approval status checks). Each operation follows a consistent pattern: commit transaction for error isolation, invoke interface within Run() wrapper, capture errors to E-Document Error Helper, update Service Status, log HTTP communication.

For async sends, the system checks if the sender implements IDocumentResponseHandler. If yes, it transitions to Pending Response status and schedules a background job to poll GetResponse. When the response arrives, it transitions to Sent or Sending Error based on the result. This decouples send latency from user interaction.

Batch sending groups multiple documents by Document Type, exports them with a shared blob, calls SendBatch on the interface, and applies status updates individually. The recurrent batch send job processes documents in Pending Batch status, exporting and sending each type group sequentially.

## Key files

**EDocIntegrationManagement.Codeunit.al** (34KB, 652 lines) -- Central dispatcher for Send, SendBatch, ReceiveDocuments, InvokeAction operations. Implements error isolation via Commit+Run pattern, logs HTTP request/response via SendContext/ReceiveContext, updates E-Document Service Status based on success/failure. Handles status transitions: Exported→Sent, Exported→Pending Response, Sent→Approved/Rejected, Sent→Cancelled. The V1→V2 migration is managed here with conditional compilation directives.

**EDocumentIntegration.Interface.al** (8KB, 110 lines) -- Obsolete V1 interface marked for removal in CLEAN26. Combined all operations (Send, SendBatch, GetResponse, GetApproval, Cancel, ReceiveDocument) into a single contract. Replaced by granular V2 interfaces. Legacy implementations remain for backward compatibility during migration window.

**ServiceIntegration.Enum.al** (987 bytes, 22 lines) -- V2 integration enum that services extend to register implementations of IDocumentSender, IDocumentReceiver, IConsentManager. Default value is "No Integration" which provides no-op implementations. Services add enum values with Implementation assignments to wire up custom service logic.

**EDocumentIntegration.Enum.al** (1KB, 35 lines) -- Obsolete V1 enum marked for removal in CLEANSCHEMA29. Single implementation value "No Integration" provided null behavior. Superseded by Service Integration enum which supports multiple interface assignments per enum value.

**EDocumentNoIntegration.Codeunit.al** (4KB, 121 lines) -- Default no-op implementation for all service integration interfaces. Returns false/empty for all operations. ISentDocumentActions methods show user messages explaining no action is available. Used as the default implementation when Service Integration is not configured.

## How it connects

Integration Management is called by E-Document Processing during outbound send, E-Document Background Jobs during async response polling, and E-Document Workflow Processing during action execution. It calls interface implementations selected from E-Document Service."Service Integration V2" field. Context codeunits (SendContext, ReceiveContext, ActionContext) flow through the call chain, accumulating HTTP messages and status updates.

The Interfaces/ subdirectory defines the seven interface contracts. The Send/ subdirectory provides SendRunner (interface dispatcher), SendContext (operation state), and batch send logic. The Actions/ subdirectory provides ActionContext and action execution infrastructure. Integration Management coordinates all these components but doesn't implement service logic itself.

Service implementations live outside E-Document Core -- typically in localization apps or partner extensions. They extend the Service Integration enum, implement required interfaces, and register via enum Implementation assignments. Integration Management discovers implementations dynamically at runtime via interface casting.

## Things to know

- **V2 migration in progress** -- Code contains parallel V1 and V2 paths controlled by CLEAN26 directive. V1 code will be removed when all localizations migrate to V2 interfaces.
- **Commit+Run error isolation** -- Each interface call is preceded by Commit() and wrapped in if/Run() pattern. Errors inside interface implementations don't rollback the E-Document record state.
- **Status calculation is composite** -- E-Document header status (In Progress, Sent, Error) is calculated from all E-Document Service Status records, not stored. One document can have multiple statuses (one per service).
- **HTTP logging is automatic** -- If SendContext/ReceiveContext contains HttpRequestMessage and HttpResponseMessage, Integration Management logs them to E-Document Integration Log automatically. Interface implementations don't need to log.
- **Async detection is interface-based** -- After calling Send, Integration Management checks if sender implements IDocumentResponseHandler via interface cast. If true, document transitions to Pending Response rather than Sent.
- **Mark-fetched is optional** -- After downloading a received document, Integration Management checks if receiver implements IReceivedDocumentMarker. If true, it calls MarkFetched to notify the service. If false or if MarkFetched fails, the document is still imported but service isn't notified.
- **Action return value controls status** -- IDocumentAction.InvokeAction returns Boolean indicating if the action should update Service Status. Some actions (like querying approval status) don't change state, so they return false to skip status update.
- **Telemetry wraps all operations** -- Every Send/SendBatch/Receive/Action operation emits start/end telemetry messages with service and document dimensions for monitoring.

## Extensibility

See app-level extensibility.md for full interface documentation. Key extension points at this layer:

**OnBeforeSendDocument** / **OnAfterSendDocument** events fire before/after Send interface call, allowing modification of SendContext or capturing service responses.

**OnBeforeIsEDocumentInStateToSend** allows customization of send eligibility checks beyond the default "Exported or Sending Error" status rule.

To implement a custom service integration, extend Service Integration enum with Implementation assignments:

```al
enumextension 50100 "My Service" extends "Service Integration"
{
    value(50100; "My Service")
    {
        Implementation = IDocumentSender = "My Sender",
                        IDocumentReceiver = "My Receiver",
                        IConsentManager = "My Consent";
    }
}
```

Then implement the assigned interfaces in separate codeunits. Integration Management will discover and invoke them automatically when the service is selected.
