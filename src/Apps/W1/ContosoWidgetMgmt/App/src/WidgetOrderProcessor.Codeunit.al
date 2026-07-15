codeunit 50026 "CWM Widget Order Processor"
{
    // Anti-pattern: every helper is public by default, exposing implementation
    // detail as a de-facto API. Each becomes a contract that cannot be changed
    // without risking breakage for consumers that bound to it.
    procedure ProcessOrder(WidgetNo: Code[20])
    begin
        ValidateOrder(WidgetNo);
        PostOrder(WidgetNo);
    end;

    procedure ValidateOrder(WidgetNo: Code[20])
    begin
        if WidgetNo = '' then
            Error('Widget number is required.');
    end;

    procedure PostOrder(WidgetNo: Code[20])
    begin
    end;

    procedure CalculateInternalScore(WidgetNo: Code[20]): Decimal
    begin
        exit(0);
    end;
}
