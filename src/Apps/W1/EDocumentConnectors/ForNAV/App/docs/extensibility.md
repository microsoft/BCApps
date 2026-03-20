# ForNAV Extensibility

## Interface implementation

The ForNAV connector implements five interfaces through the `ForNAVIntegrationImpl` codeunit (6418):

- **IDocumentSender** -- Handles outbound e-document transmission
- **IDocumentReceiver** -- Polls and retrieves incoming e-documents
- **IDocumentResponseHandler** -- Processes server responses for sent documents
- **ISentDocumentActions** -- Provides actions on sent documents (e.g., cancel, check status)
- **IConsentManager** -- Manages privacy consent flow for GDPR compliance

The implementation is registered via EnumExt 6410 on the Service Integration enum.

## Consent management

The `IConsentManager` interface is unique among e-document connectors. It handles the privacy consent flow required before publishing participant data to the SMP (Service Metadata Publisher) network. The consent dialog presents terms and conditions before allowing registration.

This pattern could be adopted by other connectors that require user agreement before external data publication.

## Extension points

### Event subscribers

- **OnBeforeOpenServiceIntegrationSetupPage** -- Intercepts setup page navigation to launch the ForNAV setup wizard instead of the standard setup card

### AAD application creation

The `ForNAVPeppolAadApp` codeunit (6411) handles automatic creation and configuration of Azure Active Directory applications for service-to-service authentication. This allows the connector to authenticate with the ForNAV service without storing user credentials.

The AAD app setup includes:
- Application registration in the customer's tenant
- Permission grants for ForNAV service access
- Secret generation and storage

## Extensibility surface

The ForNAV connector has a very closed extensibility surface:

- All codeunits and tables use `internal` access modifiers
- No custom events are published
- No subscriber patterns beyond the standard e-document framework events
- Business logic is encapsulated within the implementation codeunit

This design prioritizes security and stability over extensibility. Partners cannot modify behavior without forking the connector code.

## Integration with e-document framework

The ForNAV connector relies entirely on the standard e-document framework events and interfaces. It does not publish additional events or provide custom extension points beyond what the framework requires.

For extensibility needs, partners should:
1. Extend the e-document framework itself
2. Implement custom connectors for different routing requirements
3. Use the standard document send/receive events in the e-document core

## Architecture notes

The connector uses a service integration pattern where Business Central acts as a client to the ForNAV cloud service. The service handles:
- PEPPOL network registration and lookup
- Document routing via Access Point (AP) integration
- SMP participant publication
- Compliance with PEPPOL specifications

Business Central's role is limited to:
- Formatting documents for transmission
- Authenticating with the service
- Polling for incoming documents
- Storing received documents in the e-document framework

This division keeps PEPPOL complexity out of the AL layer and simplifies connector maintenance.
