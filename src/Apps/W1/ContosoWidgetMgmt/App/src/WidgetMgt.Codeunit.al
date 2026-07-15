codeunit 50020 "CWM Widget Mgt"
{
    procedure NormalizeWidgetDescriptions()
    var
        Widget: Record "CWM Widget";
    begin
        if Widget.FindSet(true) then
            repeat
                Widget.Description := UpperCase(Widget.Description);
                Widget.Modify();
                Commit();
            until Widget.Next() = 0;
    end;

    procedure HasLogEntries(WidgetNo: Code[20]): Boolean
    var
        WidgetLogEntry: Record "CWM Widget Log Entry";
    begin
        WidgetLogEntry.SetRange("Widget No.", WidgetNo);
        if WidgetLogEntry.Count() > 0 then
            exit(true);
        if WidgetLogEntry.FindFirst() then
            exit(true);
        exit(false);
    end;

    procedure ProcessWidgets(var Widget: Record "CWM Widget")
    begin
        if Widget.FindSet() then
            repeat
                OnProcessWidget(Widget);
                Widget.Description := UpperCase(Widget.Description);
                Widget.Modify(true);
            until Widget.Next() = 0;
    end;

    procedure PostWidget(var Widget: Record "CWM Widget")
    begin
        Widget.FieldError("Contact Email", 'must be filled in');

        if Widget."Linked Customer No." = '' then
            Error('Linked customer is required.');
    end;

    procedure CheckWidgetExists(WidgetNo: Code[20])
    var
        Widget: Record "CWM Widget";
    begin
        if not Widget.Get(WidgetNo) then
            Error('Widget ' + WidgetNo + ' does not exist.');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessWidget(var Widget: Record "CWM Widget")
    begin
    end;
}
