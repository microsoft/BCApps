namespace Microsoft.Finance.ExcelReports.Test;

codeunit 135401 "Mock Performant Feature Events"
{
    SingleInstance = true;

    var
        FeatureActive: Boolean;
        EventCalled: Boolean;

    procedure SetFeatureActive(Active: Boolean)
    begin
        FeatureActive := Active;
        EventCalled := false;
    end;

    procedure WasEventCalled(): Boolean
    begin
        exit(EventCalled);
    end;

    procedure ResetState()
    begin
        FeatureActive := false;
        EventCalled := false;
    end;
}