# Extensibility

## Overview

The Avalara E-Document Connector implements the E-Document Core interfaces (IDocumentSender, IDocumentReceiver, IDocumentResponseHandler) and registers itself as a service integration option through enum extension. This connector is primarily an API bridge between Business Central and Avalara's e-invoicing service, with a deliberately narrow extension surface.

Most customization happens outside the connector by extending pages or tables, not by subscribing to connector events. The connector itself publishes no integration events -- this is appropriate for its role as a thin protocol adapter. Extension points exist for UI customization and field additions, but business logic transformation should happen in E-Document Core or app-level code.

## Adding custom fields to the connection setup

**Tables**: Extend table 6370 "Connection Setup" to add fields. The table is designed to store connection parameters (API endpoint, authentication, defaults).

**Pages**: Extend page 6371 "Connection Setup Card" to surface your fields. The page uses conditional visibility based on connection type -- your fields should follow the same pattern if they're connection-type-specific.

**Example**: Add a custom timeout field.
```al
tableextension 50100 "Custom Connection Setup" extends "Connection Setup"
{
    fields
    {
        field(50100; "Custom Timeout"; Integer)
        {
            Caption = 'Custom Timeout (seconds)';
            MinValue = 1;
        }
    }
}

pageextension 50100 "Custom Setup Card" extends "Connection Setup Card"
{
    layout
    {
        addafter("Avalara Send Mode")
        {
            field("Custom Timeout"; Rec."Custom Timeout")
            {
                ApplicationArea = All;
            }
        }
    }
}
```

## Adding metadata to submitted documents

**Interface**: The IDocumentSender.Send() implementation builds metadata using the Metadata.Codeunit.al fluent API. This metadata is included in the multipart form submission to Avalara.

**Extension approach**: Extend table 6103 "E-Document" to add tracking fields, then subscribe to E-Document Core events (not Avalara events) to populate metadata before the connector's Send() is called.

**Example**: The connector adds "Avalara Document Id" as a field on E-Document. Similar pattern for custom tracking fields.
```al
tableextension 6370 "E-Document" extends "E-Document"
{
    fields
    {
        field(6370; "Avalara Document Id"; Guid)
        {
            Caption = 'Avalara Document Id';
            Editable = false;
        }
    }
}
```

## Intercepting setup page navigation

**Event**: IntegrationImpl.Codeunit.al publishes OnBeforeOpenServiceIntegrationSetupPage, subscribed by the connector to open ConnectionSetupCard when the user clicks Setup on an Avalara service.

**Custom behavior**: If you need alternate setup flows (wizard, validation, pre-checks), subscribe to this event with a higher execution order and set Handled := true.

**Example**: From IntegrationImpl.Codeunit.al.
```al
[EventSubscriber(ObjectType::Page, Page::"E-Document Service", 'OnBeforeOpenServiceIntegrationSetupPage', '', false, false)]
local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocServiceRec: Record "E-Document Service"; var IsServiceIntegrationSetupRun: Boolean)
begin
    if EDocServiceRec."Service Integration V2" <> EDocServiceRec."Service Integration V2"::Avalara then
        exit;

    ConnectionSetup.OpenSetupPage(EDocServiceRec."Service Integration V2".AsInteger());
    IsServiceIntegrationSetupRun := true;
end;
```

## Why this connector is relatively closed

Connectors translate protocol-level details (HTTP requests, OAuth tokens, multipart encoding) into interface calls that E-Document Core understands. Business logic like validation, transformation, approval routing, and error handling belong in Core or app code, not in the connector.

This design keeps connectors maintainable and prevents divergent connector-specific workflows. If you need to customize send logic (retry policies, pre-send validation, custom status mappings), do so by extending E-Document Core event subscribers, not by forking connector code.
