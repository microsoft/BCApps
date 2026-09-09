namespace Microsoft.FabricExport;

#if not PTE
codeunit 150008 "Fabric Platform Telemetry"
#else
codeunit 50108 "Fabric Platform Telemetry"
#endif
{
    Access = Internal;

    var
        CategoryTok: Label 'BC2Fabric', Locked = true;

    /// <summary>Emits a diagnostic trace to Application Insights (publisher telemetry).</summary>
    procedure LogEvent(EventId: Text; Message: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', CategoryTok);
        Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    /// <summary>Emits a diagnostic trace with custom dimensions to Application Insights.</summary>
    procedure LogEvent(EventId: Text; Message: Text; Dimensions: Dictionary of [Text, Text])
    begin
        Dimensions.Add('Category', CategoryTok);
        Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    /// <summary>
    /// Emits an audit event describing a configuration change made by the current user.
    /// Session.LogAuditMessage is OnPrem-only, so on the Cloud target these events are
    /// recorded as publisher telemetry tagged with an AuditEvent dimension.
    /// </summary>
    procedure LogAudit(EventId: Text; Message: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('AuditEvent', 'true');
        Dimensions.Add('UserSecurityId', Format(UserSecurityId(), 0, 4));
        Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, Dimensions);
    end;
}
