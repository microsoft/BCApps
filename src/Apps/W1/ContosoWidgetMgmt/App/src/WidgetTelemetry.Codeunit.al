codeunit 50023 "CWM Widget Telemetry"
{
    procedure LogWidgetProcessed(WidgetNo: Code[20])
    begin
        Session.LogMessage(
            '0000',
            'Widget record processed',
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            'Category', 'ContosoWidget');
    end;

    procedure LogWidgetPosted(WidgetNo: Code[20])
    begin
        Session.LogMessage(
            '0000',
            'Widget posted',
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            'Category', 'ContosoWidget');
    end;
}
