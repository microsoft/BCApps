codeunit 50080 "CWM Widget Test"
{
    Subtype = Test;

    [Test]
    procedure BlankContactEmailIsRejected()
    var
        Widget: Record "CWM Widget";
        WidgetMgt: Codeunit "CWM Widget Mgt";
    begin
        Widget.Init();
        Widget."No." := 'W-001';
        Widget."Contact Email" := '';

        // Bare asserterror: passes if ANY error is raised, so it never proves
        // the blank contact-email guard is the thing that fired.
        asserterror WidgetMgt.PostWidget(Widget);
    end;
}
