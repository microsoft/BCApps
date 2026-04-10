codeunit 139163 "Int. Table Synch. Subscriber"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FindDestinationRecordID: RecordID;
        FindDestinationRecordFound: Boolean;
        FindDestinationRecordDeleted: Boolean;
        FindDestinationRecordShouldError: Boolean;
        HandleFindRecord: Boolean;
        GlobalCounter: Integer;
        CallbackCounterBeforeTransferFields: Integer;
        CallbackCounterAfterTransferFields: Integer;
        CallbackCounterBeforeInsert: Integer;
        CallbackCounterAfterInsert: Integer;
        CallbackCounterBeforeModify: Integer;
        CallbackCounterAfterModify: Integer;
        ModifyOnFieldTransfer: Boolean;
        UpdateModifiedOnTimeOnIntegrationRecord: Boolean;
        CRMTimeDiffSeconds: Integer;
        ExpectedFailureErr: Label 'Expected Failure.';

    [Scope('OnPrem')]
    procedure Reset()
    begin
        CallbackCounterBeforeTransferFields := 0;
        CallbackCounterAfterTransferFields := 0;

        CallbackCounterBeforeInsert := 0;
        CallbackCounterAfterInsert := 0;

        CallbackCounterBeforeModify := 0;
        CallbackCounterAfterModify := 0;

        ModifyOnFieldTransfer := false;
        UpdateModifiedOnTimeOnIntegrationRecord := false;
        CRMTimeDiffSeconds := 0;

        ClearFindRecordResults();
    end;

    [Scope('OnPrem')]
    procedure SetFlags(DoModifyOnFieldTransfer: Boolean)
    begin
        ModifyOnFieldTransfer := DoModifyOnFieldTransfer;
    end;

    [Scope('OnPrem')]
    procedure SetFindRecordResults(RecordID: RecordID; FoundRecord: Boolean; RecordWasDeleted: Boolean)
    begin
        FindDestinationRecordID := RecordID;
        FindDestinationRecordFound := FoundRecord;
        FindDestinationRecordDeleted := RecordWasDeleted;
        HandleFindRecord := true;
    end;

    [Scope('OnPrem')]
    procedure SetFindRecordResultsShouldError()
    begin
        FindDestinationRecordShouldError := true;
    end;

    [Scope('OnPrem')]
    procedure ClearFindRecordResults()
    begin
        HandleFindRecord := false;
        FindDestinationRecordShouldError := false;
    end;

    [Scope('OnPrem')]
    procedure SetUpdateModifiedOn(DoUpdateModifiedOnTimeOnIntegrationRecord: Boolean)
    begin
        SetUpdateModifiedOn(DoUpdateModifiedOnTimeOnIntegrationRecord, 0);
    end;

    [Scope('OnPrem')]
    procedure SetUpdateModifiedOn(DoUpdateModifiedOnTimeOnIntegrationRecord: Boolean; TimeDiffSeconds: Integer)
    begin
        UpdateModifiedOnTimeOnIntegrationRecord := DoUpdateModifiedOnTimeOnIntegrationRecord;
        CRMTimeDiffSeconds := TimeDiffSeconds;
    end;

    local procedure CurrentCRMDateTime(): DateTime
    begin
        exit(CurrentDateTime() + (CRMTimeDiffSeconds * 1000));
    end;

    [Scope('OnPrem')]
    procedure VerifyCallbackCounters(ExpectedBeforeFieldTransfer: Integer; ExpectedAfterFieldTransfer: Integer; ExpectedBeforeInsert: Integer; ExpectedAfterInsert: Integer; ExpectedBeforeModify: Integer; ExpectedAfterModify: Integer)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        LastErrorMessage: Text;
        ErrorCount: Text;
    begin
        IntegrationSynchJobErrors.SetCurrentKey("Date/Time", "Integration Synch. Job ID");
        IntegrationSynchJobErrors.SetAscending("Date/Time", false);
        ErrorCount := Format(IntegrationSynchJobErrors.Count);
        LastErrorMessage := 'No last error';
        if IntegrationSynchJobErrors.FindFirst() then
            LastErrorMessage := IntegrationSynchJobErrors.Message;

        if ExpectedBeforeFieldTransfer > -1 then
            Assert.AreEqual(ExpectedBeforeFieldTransfer, CallbackCounterBeforeTransferFields,
              'Unexpected calls to BeforeTransferFields.\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);
        if ExpectedAfterFieldTransfer > -1 then
            Assert.AreEqual(ExpectedAfterFieldTransfer, CallbackCounterAfterTransferFields,
              'Unexpected calls to AfterTransferFields\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);

        if ExpectedBeforeInsert > -1 then
            Assert.AreEqual(ExpectedBeforeInsert, CallbackCounterBeforeInsert,
              'Unexpected calls to BeforeInsert\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);
        if ExpectedAfterInsert > -1 then
            Assert.AreEqual(ExpectedAfterInsert, CallbackCounterAfterInsert,
              'Unexpected calls to AfterInsert\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);

        if ExpectedBeforeModify > -1 then
            Assert.AreEqual(ExpectedBeforeModify, CallbackCounterBeforeModify,
              'Unexpected calls to BeforeModify\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);
        if ExpectedAfterModify > -1 then
            Assert.AreEqual(ExpectedAfterModify, CallbackCounterAfterModify,
              'Unexpected calls to AfterModify\Errors: ' + ErrorCount + '\Last Error Message: ' + LastErrorMessage);
    end;

    local procedure IncrementCounter(var Counter: Integer)
    begin
        Counter := Counter + 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeTransferRecordFields', '', false, false)]
    local procedure HandleBeforeTransferFields()
    begin
        IncrementCounter(CallbackCounterBeforeTransferFields);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterTransferRecordFields', '', false, false)]
    local procedure HandleAfterTransferFields(var AdditionalFieldsWereModified: Boolean)
    begin
        IncrementCounter(CallbackCounterAfterTransferFields);
        if ModifyOnFieldTransfer then
            AdditionalFieldsWereModified := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeInsertRecord', '', false, false)]
    local procedure HandleBeforeInsert(var DestinationRecordRef: RecordRef)
    var
        IdFieldRef: FieldRef;
    begin
        IncrementCounter(CallbackCounterBeforeInsert);

        // The Id on the test tables are not autogenerated so we set it here.
        if DestinationRecordRef.Number = DATABASE::"Test Integration Table" then begin
            IdFieldRef := DestinationRecordRef.Field(10);
            IdFieldRef.Value := CreateGuid();
        end else
            if DestinationRecordRef.Number = DATABASE::"Unit of Measure" then begin
                GlobalCounter := GlobalCounter + 1;
                IdFieldRef := DestinationRecordRef.Field(1);
                IdFieldRef.Value := 'UOM-ID|' + Format(GlobalCounter);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    local procedure HandleAfterInsert()
    begin
        IncrementCounter(CallbackCounterAfterInsert);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    local procedure HandleBeforeModify()
    begin
        IncrementCounter(CallbackCounterBeforeModify);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    local procedure HandleAfterModify()
    begin
        IncrementCounter(CallbackCounterAfterModify);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Account", 'OnBeforeInsertEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeInsertCRMAccount(var Rec: Record "CRM Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Account", 'OnBeforeModifyEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeModifyCRMAccount(var Rec: Record "CRM Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Contact", 'OnBeforeInsertEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeInsertCRMContact(var Rec: Record "CRM Contact"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Contact", 'OnBeforeModifyEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeModifyCRMContact(var Rec: Record "CRM Contact"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Systemuser", 'OnBeforeInsertEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeInsertCRMSystemuser(var Rec: Record "CRM Systemuser"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Systemuser", 'OnBeforeModifyEvent', '', false, false)]
    procedure UpdateModifiedOnTimeOnBeforeModifyCRMSystemuser(var Rec: Record "CRM Systemuser"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if UpdateModifiedOnTimeOnIntegrationRecord then
                Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnFindUncoupledDestinationRecord', '', false, false)]
    local procedure HandleFindUncoupledDestinationRecord(var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    begin
        if FindDestinationRecordShouldError then
            Error(ExpectedFailureErr);

        if HandleFindRecord then begin
            if FindDestinationRecordFound then begin
                DestinationFound := true;
                DestinationRecordRef.Close();
                DestinationRecordRef.Open(FindDestinationRecordID.TableNo);
                DestinationRecordRef.Get(FindDestinationRecordID);
            end;

            if FindDestinationRecordDeleted then
                DestinationIsDeleted := true;
        end;
    end;
}

