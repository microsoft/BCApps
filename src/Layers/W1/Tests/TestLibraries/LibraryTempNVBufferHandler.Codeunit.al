codeunit 131104 "Library - TempNVBufferHandler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SkipDefaultSubscriber: Boolean;
        RunBackgroundCaseSubscriber: Boolean;

    [Scope('OnPrem')]
    procedure AssertQueueEmpty()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [Scope('OnPrem')]
    procedure AssertEntry(ExpecteValue: Text)
    begin
        Assert.ExpectedMessage(ExpecteValue, LibraryVariableStorage.DequeueText());
    end;

    [Scope('OnPrem')]
    procedure ActivateBackgroundCaseSubscriber()
    begin
        RunBackgroundCaseSubscriber := true;
    end;

    [Scope('OnPrem')]
    procedure DeactivateBackgroundCaseSubscriber()
    begin
        RunBackgroundCaseSubscriber := false;
    end;

    [Scope('OnPrem')]
    procedure ActivateDefaultSubscriber()
    begin
        SkipDefaultSubscriber := false;
    end;

    [Scope('OnPrem')]
    procedure DeactivateDefaultSubscriber()
    begin
        SkipDefaultSubscriber := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Name/Value Buffer", 'OnAfterInsertEvent', '', false, false)]
    local procedure TrackTempNameValueBufferOnAfterInsertEvent(var Rec: Record "Name/Value Buffer"; RunTrigger: Boolean)
    begin
        // it is default subscriber. So Skip - is FALSE by default
        if SkipDefaultSubscriber then
            exit;

        if not Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        if Exists(Rec.Name) and (Rec.Value <> '') then
            LibraryVariableStorage.Enqueue(Rec.Value);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Name/Value Buffer", 'OnAfterInsertEvent', '', false, false)]
    local procedure BackgroundCaseTrackTempNameValueBufferOnAfterInsertEvent(var Rec: Record "Name/Value Buffer"; RunTrigger: Boolean)
    begin
        // it is not default subscriber. So Run - is FALSE by default
        if not RunBackgroundCaseSubscriber then
            exit;

        if not Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        if (Rec.Name <> '') and Exists(Rec.Value) then
            LibraryVariableStorage.Enqueue(Rec.Name);
    end;
}

