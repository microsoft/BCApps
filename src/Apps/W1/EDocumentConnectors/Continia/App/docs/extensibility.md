# Extensibility Guide

The Continia E-Document Connector provides limited extensibility through integration events and interface implementations. Most implementation details are internal and sealed.

## Interface Implementation

The connector implements five E-Document framework interfaces via a single adapter codeunit:

**ContiniaIntegrationImpl** (93 lines)
- `IDocumentSender` -- sends documents via CDN API
- `IDocumentReceiver` -- fetches received documents
- `IDocumentResponseHandler` -- processes CDN responses
- `ISentDocumentActions` -- retry and cancel operations
- `IReceivedDocumentMarker` -- marks documents as downloaded

The implementation is registered via enum extension on `Service Integration` (enum 6390).

## Integration Events

### URL Customization

ContiniaApiUrl codeunit publishes three events for URL override scenarios:

**OnGetCOBaseUrl**
```al
[IntegrationEvent(false, false)]
local procedure OnGetCOBaseUrl(var ContiniaOnlineBaseUrl: Text)
```
Override the authentication endpoint URL. Default: `https://businesscentral.continia.com`

**OnGetCdnBaseUrl**
```al
[IntegrationEvent(false, false)]
local procedure OnGetCdnBaseUrl(var CdnBaseUrl: Text)
```
Override the CDN API endpoint URL. Default: `https://cdn.continia.com/bc/v2.0`

**OnBeforeGetBaseUrlForLocalization**
```al
[IntegrationEvent(false, false)]
local procedure OnBeforeGetBaseUrlForLocalization(LocalizationCode: Text; var Handled: Boolean; var BaseUrl: Text)
```
Provide region-specific URLs. Fires before default handling for AU/NZ and NL localizations.

**Use case:** Partners hosting regional Continia deployments can redirect API traffic to dedicated endpoints without forking the connector code.

### Service Integration Validation

**OnAfterValidateServiceIntegration**
```al
[IntegrationEvent(false, false)]
local procedure OnAfterValidateServiceIntegration(EDocumentService: Record "E-Document Service")
```
Fires after service integration validation. Subscriber in ContiniaInstall codeunit.

**OnAfterValidateDocumentFormat**
```al
[IntegrationEvent(false, false)]
local procedure OnAfterValidateDocumentFormat(EDocService: Record "E-Document Service"; EDocFormat: Record "E-Document Format")
```
Fires after document format validation. Used for page-level validation logic.

### Setup Page Override

**OnBeforeOpenServiceIntegrationSetupPage**
```al
[IntegrationEvent(false, false)]
local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocumentService: Record "E-Document Service"; var Handled: Boolean)
```
Intercepts the default setup page open action. The Continia subscriber opens the Continia-specific setup wizard instead.

### SaaS Lifecycle

**CleanupCompanyConfiguration**
```al
[IntegrationEvent(false, false)]
local procedure CleanupCompanyConfiguration()
```
Fires during company deletion in SaaS environments. The subscriber unregisters the company from the CDN API.

## Extensibility Constraints

All tables and codeunits are marked:
- `Access = Internal`
- `Extensible = false`

This prevents:
- Table extensions
- Procedure overrides
- Direct codeunit inheritance

The URL override events represent the primary extensibility surface. For other customization needs, partners must implement a separate service integration rather than extending the Continia connector.

## Integration Event Visibility

Event subscribers are implemented in:
- ContiniaInstall.Codeunit.al -- service/format validation, setup page override
- ContiniaSessionManager.Codeunit.al -- SaaS cleanup

All event publishers are in ContiniaApiUrl.Codeunit.al except the validation and setup page events which are published from page extension code.
