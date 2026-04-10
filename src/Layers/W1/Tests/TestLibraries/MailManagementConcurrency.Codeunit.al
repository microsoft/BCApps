codeunit 139029 "Mail Management Concurrency"
{

    trigger OnRun()
    begin
        PrintingFunction();
    end;

    [Scope('OnPrem')]
    procedure PrintingFunction()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        MailManagement: Codeunit "Mail Management";
    begin
        BindSubscription(MailManagement);

        Sleep(GetSleepDuration());
        InsertNameValueBuffer(NameValueBuffer);

        UnbindSubscription(MailManagement);
    end;

    [Scope('OnPrem')]
    procedure GetSleepDuration(): Integer
    begin
        exit(10000);
    end;

    [Scope('OnPrem')]
    procedure InsertNameValueBuffer(var NameValueBuffer: Record "Name/Value Buffer")
    begin
        if NameValueBuffer.FindLast() then;
        NameValueBuffer.ID += 1;
        NameValueBuffer.Name := Format(NameValueBuffer.Count);
        NameValueBuffer.Insert();
        Commit();
    end;
}

