codeunit 135099 "OCR Master Data Sync Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsValidationEnabled: Boolean;
        GivenPortionSize: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure DisableTaskOnBeforeJobQueueScheduleTask(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ReadSoft OCR Master Data Sync", 'OnBeforeSendRequest', '', false, false)]
    local procedure HandleOnBeforeSendRequest(Body: Text)
    var
        "Part": Text;
    begin
        if not IsValidationEnabled then
            exit;

        Part := LibraryVariableStorage.DequeueText();
        if Part <> '' then
            Assert.IsSubstring(Body, Part);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ReadSoft OCR Master Data Sync", 'OnGetPortionSize', '', false, false)]
    local procedure HandleOnGetPortionSize(var PortionSize: Integer; var Handled: Boolean)
    begin
        if Handled then
            exit;

        if GivenPortionSize <= 0 then
            exit;

        PortionSize := GivenPortionSize;
        Handled := true;
    end;

    [Scope('OnPrem')]
    procedure SetPortionSize(PortionSize: Integer)
    begin
        GivenPortionSize := PortionSize;
    end;

    [Scope('OnPrem')]
    procedure EnableValidation()
    begin
        IsValidationEnabled := true;
    end;

    [Scope('OnPrem')]
    procedure DisableValidation()
    begin
        IsValidationEnabled := false;
    end;

    [Scope('OnPrem')]
    procedure AssertEmptyQueue()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [Scope('OnPrem')]
    procedure EnqueueVariable(Variable: Variant)
    begin
        LibraryVariableStorage.Enqueue(Variable);
    end;

    [Scope('OnPrem')]
    procedure ClearQueue()
    begin
        LibraryVariableStorage.Clear();
    end;
}

