codeunit 147546 "SII New Sending Experience"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        JobType: Option HandlePending,HandleCommError,InitialUpload;
        PendingStatusTxt: Label 'Pending';
        ResetSendingQst: Label 'Do you want to reset sending state?';

    [Test]
    procedure NoChangesToSIISendingStateWhenNewSendingExperienceIsDisabled()
    var
        SalesHeader: Record "Sales Header";
        SIISendingState: Record "SII Sending State";
    begin
        // [SCENARIO 493063] SII Sending state table is not affected when "New Sending Experience" is disabled in the SII Setup

        Initialize();
        // [GIVEN] New Sending Experience is disabled
        SetNewSendingExperience(false);
        // [WHEN] Post invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [THEN] SII Sending State is not created
        Assert.RecordCount(SIISendingState, 0);
    end;

    [Test]
    procedure SendingInformationGroupIsVisibleInSIIHistoryPageWhenNewSendingExperience()
    var
        SIIHistoryPage: TestPage "SII History";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 493063] Sending Information group is visible in the SII History page when "New Sending Experience" is enabled in the SII Setup

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [WHEN] Open SII History page
        SIIHistoryPage.OpenView();
        // [THEN] Sending Information group is visible
        Assert.IsTrue(SIIHistoryPage.RefreshSendingStateControl.Visible(), 'Refresh sending state is not visible');
        Assert.IsTrue(SIIHistoryPage.SendingStatus.Visible(), 'Sending status is not visible');
        Assert.IsTrue(SIIHistoryPage.ResetSendingStatus.Visible(), 'Reset Sending status is not visible');
    end;

    [Test]
    procedure NewSendingExperienceAffectsHandlePending()
    var
        SIISendingState: Record "SII Sending State";
        SIIJobManagement: Codeunit "SII Job Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 493063] New Sending Experience affects Handle Pending job queue entry

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [WHEN] Renew Handle Pending job queue entry
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
        // [THEN] SII Sending State is created
        Assert.IsTrue(SIISendingState.Get(), 'Sii sending state does not exist');
    end;

    [Test]
    procedure NewSendingExperienceDoesNotAffectHandleCommError()
    var
        SIISendingState: Record "SII Sending State";
        SIIJobManagement: Codeunit "SII Job Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 493063] New Sending Experience does not affect Handle Comm Error job queue entry

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [WHEN] Renew Handle Comm Error job queue entry
        SIIJobManagement.RenewJobQueueEntry(JobType::HandleCommError);
        // [THEN] SII Sending State is not created
        Assert.IsFalse(SIISendingState.Get(), 'Sii sending state exists');
    end;

    [Test]
    procedure NewSendingExperienceDoesNotAffectInitialUpload()
    var
        SIISendingState: Record "SII Sending State";
        SIIJobManagement: Codeunit "SII Job Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 493063] New Sending Experience does not affect Initial Upload job queue entry

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [WHEN] Renew Initial Upload job queue entry
        SIIJobManagement.RenewJobQueueEntry(JobType::InitialUpload);
        // [THEN] SII Sending State is not created
        Assert.IsFalse(SIISendingState.Get(), 'Sii sending state exists');
    end;

    [Test]
    procedure SIISendingStateWhenNewSendingExperienceSunshine()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] SII Sending State is created when "New Sending Experience" is enabled in the SII Setup

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [WHEN] Post invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        FindJobQueueEntry(JobQueueEntry);
        // [THEN] Job queue entry is created
        Assert.RecordCount(JobQueueEntry, 1);
        // [THEN] SII Sending State is created
        SIISendingState.Get();
        // [THEN] SII Sending State points to the job queue entry
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    procedure MultipleJobQueueEntriesFirstFinishedNewSendingExperience()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] New sending experience with multiple job queue entries triggered and first is finished

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [GIVEN] Post 1 invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [GIVEN] Finish the job queue entry
        FindJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Status := JobQueueEntry.Status::Finished;
        JobQueueEntry.Modify();
        // [WHEN] Post 1 more invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [THEN] In total two job queue entries have been created after posting the second invoice
        FilterJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 2);
        // [THEN] SII Sending State is created
        SIISendingState.Get();
        // [THEN] SII Sending State points to the second job queue entry
        JobQueueEntry.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntry.FindFirst();
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    procedure MultipleJobQueueEntriesFirstHasErrorNewSendingExperience()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] New sending experience with multiple job queue entries triggered and first has error

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [GIVEN] Post 1 invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [GIVEN] Set error on the job queue entry
        FindJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.Modify();
        // [WHEN] Post 1 more invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [THEN] In total two job queue entries have been created after posting the second invoice
        FilterJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 2);
        // [THEN] SII Sending State is created
        SIISendingState.Get();
        // [THEN] SII Sending State points to the second job queue entry
        JobQueueEntry.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntry.FindFirst();
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    procedure MultipleJobQueueEntriesFirstHasGoneNewSendingExperience()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] New sending experience with multiple job queue entries triggered and first has gone

        Initialize();
        SetNewSendingExperience(true);
        // [GIVEN] Post 1 invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [GIVEN] Delete the job queue entry
        FindJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Delete();
        // [WHEN] Post 1 more invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [THEN] In total one job queue entry have been created after posting the second invoice
        FindJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 1);
        SIISendingState.Get();
        // [THEN] SII Sending State points to the only job queue entry
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    procedure MultipleJobQueueEntriesFirstInProcessNewSendingExperience()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] New sending experience with multiple job queue entries triggered and first is in process

        Initialize();
        SetNewSendingExperience(true);
        // [GIVEN] Post 1 invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [GIVEN] Job queue entry for this invoice is in process
        FindJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Modify();
        // [WHEN] Post 1 more invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        // [THEN] In total one job queue entry have been created after posting the second invoice
        FindJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 1);
        // [THEN] SII Sending State is created
        SIISendingState.Get();
        // [THEN] SII Sending State points to the only job queue entry
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to true
        SIISendingState.TestField("Schedule One More When Finish", true);
    end;

    [Test]
    procedure SIISendingStateRefreshSunshine()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] Stan can refresh the SII Sending State

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        FindJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 1);
        // [GIVEN] Set Job Queue Entry to "On Hold"
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Modify();
        SIISendingState.Get();
        // [WHEN] Refresh SII Sending State
        SIISendingState.Refresh();
        // [THEN] SII Sending State points to the only job queue entry
        SIISendingState.TestField("Job Queue Entry Id", JobQueueEntry.ID);
        // [THEN] SII Sending State has "On Hold" status
        SIISendingState.TestField(Status, Format(JobQueueEntry.Status));
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    procedure SIISendingStateRefreshJobQueueEntryHasGone()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] Stan can refresh the SII Sending State when the job queue entry has gone

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [GIVEN] Post invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        FindJobQueueEntry(JobQueueEntry);
        // [GIVEN] Delete the job queue entry
        JobQueueEntry.Delete();
        SIISendingState.Get();
        // [WHEN] Refresh SII Sending State
        SIISendingState.Refresh();
        // [THEN] SII Sending State contains no job queue entry
        Assert.IsTrue(IsNullGuid(SIISendingState."Job Queue Entry Id"), 'Job Queue Entry Id is not empty');
        // [THEN] SII Sending State has pending status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMessage')]
    procedure SIISendingStateResetSunshine()
    var
        SIISendingState: Record "SII Sending State";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 493063] Stan can reset the SII Sending State

        Initialize();
        // [GIVEN] New Sending Experience is enabled
        SetNewSendingExperience(true);
        // [GIVEN] Post invoice
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        FindJobQueueEntry(JobQueueEntry);
        Assert.RecordCount(JobQueueEntry, 1);
        SIISendingState.Get();
        LibraryVariableStorage.Enqueue(ResetSendingQst);
        LibraryVariableStorage.Enqueue(true);
        // [WHEN] Reset SII Sending State
        SIISendingState.ResetSending();
        // [THEN] SII Sending State contains no job queue entry
        Assert.IsTrue(IsNullGuid(SIISendingState."Job Queue Entry Id"), 'Job Queue Entry Id is not empty');
        // [THEN] SII Sending State has "On Hold" status
        SIISendingState.TestField(Status, PendingStatusTxt);
        // [THEN] "Schedule One More When Finish" is set to false
        SIISendingState.TestField("Schedule One More When Finish", false);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        SIISendingState: Record "SII Sending State";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibrarySetupStorage.Restore();
        SIISendingState.DeleteAll();
        JobQueueEntry.DeleteAll();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SII New Sending Experience");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SII New Sending Experience");

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"SII Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SII New Sending Experience");
    end;

    local procedure SetNewSendingExperience(NewSendingExperience: Boolean)
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("New Automatic Sending Exp.", NewSendingExperience);
        SIISetup.Modify(true);
    end;

    local procedure PostSalesDocument(DocType: Enum "Sales Document Type"; ShipReceive: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocType,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, ShipReceive, Invoice);
    end;

    local procedure FilterJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
    end;

    local procedure FindJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        FilterJobQueueEntry(JobQueueEntry);
        JobQueueEntry.FindFirst();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerVerifyMessage(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}