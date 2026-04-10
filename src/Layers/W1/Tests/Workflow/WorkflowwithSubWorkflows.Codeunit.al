codeunit 134308 "Workflow with Sub-Workflows"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Sub-Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Enabled: Boolean;
        AmountGreaterThanThousandParameterTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Workflow Event Simple Args" id="134300"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice),Status=FILTER(Released),Amount=FILTER(&gt;1.000))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        AmountLessThanThousandParameterTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Workflow Event Simple Args" id="134300"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice),Status=FILTER(Released),Amount=FILTER(&lt;=1.000))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        CannotReferToCurrentWorkflowErr: Label 'cannot refer to the current workflow';
        RecordFoundErr: Label '%1 was found using filters: %2.', Comment = '%1=TableCaption,%2=Filters';
        RecordNotFoundErr: Label '%1 was not found using filters: %2.', Comment = '%1=TableCaption,%2=Filters';
        StatusParameterTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Workflow Event Simple Args" id="134300"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice),Status=FILTER(Released))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        SubWorkflowNotEnabledErr: Label 'You must enable the sub-workflow %1 before you can enable the %2 workflow.';
        TypeGLAccountParameterTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Workflow Event Simple Args" id="134300"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.)</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(G/L Account))</DataItem></DataItems></ReportParameters>', Locked = true;
        TypeItemParameterTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Workflow Event Simple Args" id="134300"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.)</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item))</DataItem></DataItems></ReportParameters>', Locked = true;
        WorkflowStepInstanceLinkErr: Label 'The %1 workflow cannot start because all ending steps in the %2 sub-workflow have a value in the Next Workflow Step ID field.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CreateIncomingDocumentWorkflowInstanceWithoutSubWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreateIncomingDocumentWorkflow(Workflow);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceWorkflowInstanceWithoutSubWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoicePostingWorkflow(Workflow);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoideRejectionComplexWorkflowWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        SubWorkflowStepJumpForward: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionComplexWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, SubWorkflowStepJumpForward);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoideRejectionFullWorkflowWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionFullWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoideRejectionLeafLessWorkflowWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionLeafLessWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoideRejectionSimpleWorkflowWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionSimpleWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentJournalLinesWorkflowInstanceWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePaymentJournalLinesWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMultiEntryPaymentJournalLinesWorkflowInstanceWithoutSubWorkflow()
    var
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreateMultiEntryPaymentJournalLinesWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceStartsWithSubWorkflow()
    var
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreateIncomingDocumentWorkflow(SubWorkflow);
        EnableWorkflow(SubWorkflow);

        CreatePurchInvoicePostingWorkflowStartsWithSubWorklfow(Workflow, SubWorkflow.Code);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceEndsWithSubWorkflow()
    var
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoicePostingWorkflow(SubWorkflow);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentWorkflow(Workflow);
        AppendSubWorkflow(Workflow, SubWorkflow);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithItselfAsSubWorkflow()
    var
        Workflow: Record Workflow;
    begin
        Initialize();

        // Setup
        CreateIncomingDocumentWorkflow(Workflow);

        // Exercise
        asserterror AppendSubWorkflow(Workflow, Workflow);

        // Verify
        Assert.ExpectedError(CannotReferToCurrentWorkflowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithDisabledSubWorkflow()
    var
        SubWorkflow: Record Workflow;
        SubWorkflowStep: Record "Workflow Step";
        Workflow: Record Workflow;
    begin
        Initialize();

        // Setup
        CreatePurchInvoicePostingWorkflow(SubWorkflow);

        CreateIncomingDocumentWorkflow(Workflow);

        // Exercise
        AppendSubWorkflow(Workflow, SubWorkflow);

        // Verify
        SubWorkflowStep.SetRange("Workflow Code", Workflow.Code);
        Assert.IsFalse(SubWorkflowStep.IsEmpty, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableWorkflowInstanceWithDisabledSubWorkflow()
    var
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
    begin
        Initialize();

        // Setup
        CreatePurchInvoicePostingWorkflow(SubWorkflow);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentWorkflow(Workflow);
        AppendSubWorkflow(Workflow, SubWorkflow);

        DisableWorkflow(SubWorkflow);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(StrSubstNo(SubWorkflowNotEnabledErr, SubWorkflow.Code, Workflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithComplexSubWorkflowHasJumpForward()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        SubWorkflowStepJumpForward: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionComplexWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, SubWorkflowStepJumpForward);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);

        VerifyWorkflowBranchLinesComplexJumpForwardWorkflow(Workflow,
          SubWorkflowStepBranch1, SubWorkflowStepBranch2, SubWorkflowStepJumpForward, LastWorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithFullSubWorkflowHasLoopback()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionFullWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);

        VerifyWorkflowBranchLinesLoopbackWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, LastWorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithLeafLessSubWorkflowHasOrphanSteps()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionLeafLessWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        asserterror Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        Assert.ExpectedError(StrSubstNo(WorkflowStepInstanceLinkErr, Workflow.Code, SubWorkflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithSimpleSubWorkflowHasLoopback()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePurchInvoiceRejectionSimpleWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);

        VerifyWorkflowBranchLinesLoopbackWorkflow(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, LastWorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithSubWorkflowHasBranches()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreatePaymentJournalLinesWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);

        VerifyWorkflowBranchLines(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, LastWorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWorkflowInstanceWithSubWorkflowHasMultipleEntryPoints()
    var
        LastWorkflowStep: Record "Workflow Step";
        SubWorkflow: Record Workflow;
        SubWorkflowStepBranch1: Record "Workflow Step";
        SubWorkflowStepBranch2: Record "Workflow Step";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreateMultiEntryPaymentJournalLinesWorkflow(SubWorkflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentExtendedWorkflow(Workflow, LastWorkflowStep);
        AddSubWorkflow(Workflow, SubWorkflow, LastWorkflowStep);
        EnableWorkflow(Workflow);

        // Exercise
        Workflow.CreateInstance(WorkflowStepInstance);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);

        VerifyMultiEntryStepInstanceLinks(Workflow, SubWorkflowStepBranch1, SubWorkflowStepBranch2, LastWorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KickoffWorkflowStartsWithSubWorkflow()
    var
        IncomingDocument: Record "Incoming Document";
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Initialize();

        // Setup
        CreateIncomingDocumentWorkflow(SubWorkflow);
        EnableWorkflow(SubWorkflow);

        CreatePurchInvoicePostingWorkflowStartsWithSubWorklfow(Workflow, SubWorkflow.Code);
        EnableWorkflow(Workflow);

        // Exercise
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Verify
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);

        Assert.IsTrue(WorkflowStepInstance.IsEmpty,
          StrSubstNo(RecordFoundErr, WorkflowStepInstance.TableCaption(), WorkflowStepInstance.GetFilters));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KickoffWorkflowEndsWithSubWorkflow()
    var
        IncomingDocument: Record "Incoming Document";
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
    begin
        Initialize();

        // Setup
        CreatePurchInvoicePostingWorkflow(SubWorkflow);
        EnableWorkflow(SubWorkflow);

        CreateIncomingDocumentWorkflow(Workflow);
        AppendSubWorkflow(Workflow, SubWorkflow);
        EnableWorkflow(Workflow);

        // Exercise
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Verify
        VerifyWorkflowInstanceHasBranchesWithSubWorkflow(
          Workflow.Code, CountWorkflowSteps(Workflow.Code) + CountWorkflowSteps(SubWorkflow.Code) - 1);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
    begin
        Enabled := true;

        Workflow.SetRange(Template, false);
        Workflow.ModifyAll(Enabled, false, true);
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure CreateIncomingDocumentWorkflow(var Workflow: Record Workflow)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep, UserId, 0, '');
    end;

    local procedure CreateIncomingDocumentExtendedWorkflow(var Workflow: Record Workflow; var LastWorkflowStep: Record "Workflow Step")
    var
        PreviousWorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        ResponseStep: Integer;
    begin
        CreateIncomingDocumentWorkflow(Workflow);

        PreviousWorkflowStep.SetRange("Workflow Code", Workflow.Code);
        PreviousWorkflowStep.FindLast();

        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            PreviousWorkflowStep.ID);
        LastWorkflowStep.Get(Workflow.Code, ResponseStep);
    end;

    local procedure CreatePurchInvoicePostingWorkflow(var Workflow: Record Workflow)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, StatusParameterTxt);
    end;

    local procedure CreatePurchInvoicePostingWorkflowStartsWithSubWorklfow(var Workflow: Record Workflow; SubWorkflowCode: Code[20])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        EventStep: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertSubWorkflowStep(Workflow, SubWorkflowCode, 0);
        LibraryWorkflow.SetSubWorkflowStepAsEntryPoint(Workflow, EntryPointEventStep);

        EventStep :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), EntryPointEventStep);
        LibraryWorkflow.InsertEventArgument(EventStep, StatusParameterTxt);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EventStep);

        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventStep);
    end;

    local procedure CreatePurchInvoiceRejectionComplexWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step"; var SubWorkflowStepJumpForward: Record "Workflow Step")
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EventStep2: Integer;
        ResponseStep2: Integer;
        EventStep3: Integer;
        ResponseStep3: Integer;
        EventStep4: Integer;
        ResponseStep4: Integer;
        EventStep5: Integer;
        ResponseStep5: Integer;
    begin
        // ==========================================================================================
        // #                          [(E) OnPurchaseDocSentForApproval]
        // #                                          |
        // #                          [(R) CreateNotificationEntry]    <--------------------|
        // #                                         / \                                    |
        // #                                        /   \                                   |
        // #          [(E) OnPurchaseInvoiceApproved]   [(E) OnPurchaseInvoiceRejected]     |
        // #                         |                                 |                    |
        // #  |----- [(R) PostApprovedPurchaseInvoice]   [(R) CreateNotificationEntry] -----|
        // #  |                      |
        // #  |        [(E) OnPurchaseInvoicePosted]
        // #  |                      |
        // #  |---> [(R) CreatePmtLineForPostedInvoice]
        // #                         |
        // #         [(E) OnPaymentJournalLineCreated]
        // #                         |
        // #           [(R) CreateNotificationEntry]
        // ==========================================================================================

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep1, UserId, 0, '');

        EventStep2 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), ResponseStep1);
        ResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventStep2);

        SubWorkflowStepJumpForward.Get(Workflow.Code, ResponseStep2);

        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep2);
        ResponseStep3 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(),
            EventStep3);

        LibraryWorkflow.SetNextStep(Workflow, ResponseStep2, ResponseStep3);
        SubWorkflowStepJumpForward.Get(Workflow.Code, ResponseStep2);

        EventStep4 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(), ResponseStep3);
        ResponseStep4 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EventStep4);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep4, UserId, 0, '');

        EventStep5 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), ResponseStep1);
        ResponseStep5 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EventStep5);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep5, UserId, 0, '');
        LibraryWorkflow.SetNextStep(Workflow, ResponseStep5, ResponseStep1);

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep4);
        SubWorkflowStepBranch2.Get(Workflow.Code, ResponseStep5);
    end;

    local procedure CreatePurchInvoiceRejectionFullWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step")
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EventStep2: Integer;
        ResponseStep2: Integer;
        ResponseStep3: Integer;
        EventStep3: Integer;
        ResponseStep4: Integer;
    begin
        // =================================================================================
        // #                   [(E) OnPurchaseDocSentForApproval] <--------------|
        // #                                   |                                     |
        // #                   [(R) CreateNotificationEntry]                         |
        // #                                  / \                                    |
        // #                                 /   \                                   |
        // #   [(E) OnPurchaseInvoiceApproved]   [(E) OnPurchaseInvoiceRejected]     |
        // #                  |                                 |                    |
        // #  [(R) PostApprovedPurchaseInvoice]   [(R) CreateNotificationEntry] -----|
        // #                  |
        // #    [(R) CreateNotificationEntry]
        // =================================================================================

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep1, UserId, 0, '');

        EventStep2 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), ResponseStep1);
        ResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventStep2);
        ResponseStep3 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), ResponseStep2);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep3, UserId, 0, '');

        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), ResponseStep1);
        ResponseStep4 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EventStep3);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep4, UserId, 0, '');
        LibraryWorkflow.SetNextStep(Workflow, ResponseStep4, ResponseStep1);

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep3);
        SubWorkflowStepBranch2.Get(Workflow.Code, ResponseStep4);
    end;

    local procedure CreatePurchInvoiceRejectionSimpleWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step")
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        EventStep2: Integer;
        EventStep3: Integer;
        ResponseStep: Integer;
    begin
        // =================================================================================
        // #                   [(E) OnPurchaseDocSentForApproval] <--------------|
        // #                                   |                                     |
        // #                                   |                                     |
        // #                                  / \                                    |
        // #                                 /   \                                   |
        // #   [(E) OnPurchaseInvoiceApproved]   [(E) OnPurchaseInvoiceRejected] ----|
        // #                  |
        // #                  |
        // #  [(R) PostApprovedPurchaseInvoice]
        // =================================================================================

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            EntryPointEventStep);
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventStep2);
        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), EntryPointEventStep);

        LibraryWorkflow.SetNextStep(Workflow, EventStep3, EntryPointEventStep);

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep);
        SubWorkflowStepBranch2.Get(Workflow.Code, EventStep3);
    end;

    local procedure CreatePurchInvoiceRejectionLeafLessWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step")
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        EventStep2: Integer;
        EventStep3: Integer;
        ResponseStep: Integer;
    begin
        // ======================================================================================
        // #   |------------------> [(E) OnPurchaseDocSentForApproval] <--------------|
        // #   |                                    |                                     |
        // #   |                                    |                                     |
        // #   |                                   / \                                    |
        // #   |                                  /   \                                   |
        // #   |    [(E) OnPurchaseInvoiceApproved]   [(E) OnPurchaseInvoiceRejected] ----|
        // #   |                   |
        // #   |                   |
        // #   --- [(R) PostApprovedPurchaseInvoice]
        // ======================================================================================

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            EntryPointEventStep);
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventStep2);
        LibraryWorkflow.SetNextStep(Workflow, ResponseStep, EntryPointEventStep);

        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), ResponseStep);
        LibraryWorkflow.SetNextStep(Workflow, EventStep3, EntryPointEventStep);

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep);
        SubWorkflowStepBranch2.Get(Workflow.Code, EventStep3);
    end;

    local procedure CreatePaymentJournalLinesWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowTableRelation1: Record "Workflow - Table Relation";
        WorkflowTableRelation2: Record "Workflow - Table Relation";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EventStep2: Integer;
        ResponseStep2: Integer;
        EventStep3: Integer;
        ResponseStep3: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        if not WorkflowTableRelation1.Get(
             DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
             DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."))
        then
            LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation1,
              DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
              DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."));

        if not WorkflowTableRelation2.Get(
             DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
             DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."))
        then
            LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation2,
              DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
              DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."));

        // 1. Post a Pruchase Invoice
        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, StatusParameterTxt);

        // 2.a [Branch] If Type == Item, Then Create Payment Lines
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(),
            ResponseStep1);
        ResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(),
            EventStep2);

        LibraryWorkflow.InsertEventArgument(EventStep2, TypeItemParameterTxt);
        LibraryWorkflow.InsertPmtLineCreationArgument(ResponseStep2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        // 2.b [Branch] If Type == G/L Account, Then Send an Email
        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep1);
        ResponseStep3 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EventStep3);

        LibraryWorkflow.InsertEventArgument(EventStep3, TypeGLAccountParameterTxt);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep3, UserId, 0, '');

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep2);
        SubWorkflowStepBranch2.Get(Workflow.Code, ResponseStep3);
    end;

    local procedure CreateMultiEntryPaymentJournalLinesWorkflow(var Workflow: Record Workflow; var SubWorkflowStepBranch1: Record "Workflow Step"; var SubWorkflowStepBranch2: Record "Workflow Step")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowTableRelation1: Record "Workflow - Table Relation";
        WorkflowTableRelation2: Record "Workflow - Table Relation";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
        ResponseStep2: Integer;
        ResponseStep3: Integer;
        EventStep3: Integer;
        ResponseStep4: Integer;
        EventStep4: Integer;
        ResponseStep5: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        if not WorkflowTableRelation1.Get(
             DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
             DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."))
        then
            LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation1,
              DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
              DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."));

        if not WorkflowTableRelation2.Get(
             DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
             DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."))
        then
            LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation2,
              DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
              DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."));

        // 1. Post a Pruchase Invoice <= 1000
        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, AmountLessThanThousandParameterTxt);

        // 2. Post a Pruchase Invoice > 1000
        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            ResponseStep1);
        ResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(),
            EntryPointEventStep2);
        ResponseStep3 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            ResponseStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep2, AmountGreaterThanThousandParameterTxt);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep3, UserId, 0, '');

        // 2.a [Branch] If Type == Item, Then Create Payment Lines
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        EventStep3 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep3);
        ResponseStep4 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(),
            EventStep3);

        LibraryWorkflow.InsertEventArgument(EventStep3, TypeItemParameterTxt);
        LibraryWorkflow.InsertPmtLineCreationArgument(ResponseStep3, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        // 2.b [Branch] If Type == G/L Account, Then Send an Email
        EventStep4 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep4);
        ResponseStep5 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EventStep4);

        LibraryWorkflow.InsertEventArgument(EventStep4, TypeGLAccountParameterTxt);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep5, UserId, 0, '');

        SubWorkflowStepBranch1.Get(Workflow.Code, ResponseStep4);
        SubWorkflowStepBranch2.Get(Workflow.Code, ResponseStep5);
    end;

    local procedure AppendSubWorkflow(Workflow: Record Workflow; SubWorkflow: Record Workflow)
    var
        PreviousWorkflowStep: Record "Workflow Step";
    begin
        PreviousWorkflowStep.SetRange("Workflow Code", Workflow.Code);
        PreviousWorkflowStep.FindLast();

        LibraryWorkflow.InsertSubWorkflowStep(Workflow, SubWorkflow.Code, PreviousWorkflowStep.ID);
    end;

    local procedure AddSubWorkflow(Workflow: Record Workflow; SubWorkflow: Record Workflow; var LastWorkflowStep: Record "Workflow Step")
    var
        PreviousWorkflowStep: Record "Workflow Step";
        SubWorkflowID: Integer;
    begin
        PreviousWorkflowStep.Get(LastWorkflowStep."Workflow Code", LastWorkflowStep."Previous Workflow Step ID");

        SubWorkflowID := LibraryWorkflow.InsertSubWorkflowStep(Workflow, SubWorkflow.Code, PreviousWorkflowStep.ID);

        LastWorkflowStep.Validate("Previous Workflow Step ID", SubWorkflowID);
        LastWorkflowStep.Modify(true);
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    local procedure DisableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := false;
        Workflow.Modify(true);
    end;

    local procedure VerifyWorkflowInstanceWithoutSubWorkflow(WorkflowCode: Code[20])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        FindStepAndRelatedInstances(WorkflowStep, WorkflowStepInstance, WorkflowCode);
        Assert.AreEqual(WorkflowStep.Count, WorkflowStepInstance.Count, '');

        repeat
            CheckStepEqualsInstance(WorkflowStep, WorkflowStepInstance);
        until (WorkflowStep.Next() = 0) and (WorkflowStepInstance.Next() = 0);
    end;

    local procedure FindStepAndRelatedInstances(var WorkflowStep: Record "Workflow Step"; var WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowCode: Code[20])
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.FindSet();

        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        WorkflowStepInstance.FindSet();
    end;

    local procedure CheckStepEqualsInstance(WorkflowStep: Record "Workflow Step"; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
        WorkflowStepInstance.TestField("Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.TestField("Workflow Step ID", WorkflowStep.ID);

        CheckCommonPropertiesForStepAndInstance(WorkflowStep, WorkflowStepInstance);
    end;

    local procedure CheckCommonPropertiesForStepAndInstance(WorkflowStep: Record "Workflow Step"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        OtherWorkflowStepArgument: Record "Workflow Step Argument";
        ThisWorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowStepInstance.TestField(Description, WorkflowStep.Description);
        WorkflowStepInstance.TestField("Entry Point", WorkflowStep."Entry Point");
        WorkflowStepInstance.TestField("Previous Workflow Step ID", WorkflowStep."Previous Workflow Step ID");
        WorkflowStepInstance.TestField("Next Workflow Step ID", WorkflowStep."Next Workflow Step ID");
        WorkflowStepInstance.TestField(Type, WorkflowStep.Type);
        WorkflowStepInstance.TestField("Function Name", WorkflowStep."Function Name");
        WorkflowStepInstance.TestField("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.TestField("Original Workflow Step ID", WorkflowStep.ID);

        if ThisWorkflowStepArgument.Get(WorkflowStep.Argument) then begin
            OtherWorkflowStepArgument.Get(WorkflowStepInstance.Argument);
            OtherWorkflowStepArgument.Equals(ThisWorkflowStepArgument);
        end;
    end;

    local procedure CountWorkflowSteps(WorkflowCode: Code[20]): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        exit(WorkflowStep.Count);
    end;

    local procedure VerifyWorkflowInstanceHasBranchesWithoutSubWorkflow(WorkflowCode: Code[20])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        FindStepAndRelatedInstances(WorkflowStep, WorkflowStepInstance, WorkflowCode);
        Assert.AreEqual(WorkflowStep.Count, WorkflowStepInstance.Count, '');

        CheckWorkflowStepInstancesExist(WorkflowStep, WorkflowCode);
    end;

    local procedure VerifyWorkflowInstanceHasBranchesWithSubWorkflow(WorkflowCode: Code[20]; "Count": Integer)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        FindStepAndRelatedInstances(WorkflowStep, WorkflowStepInstance, WorkflowCode);
        Assert.AreEqual(Count, WorkflowStepInstance.Count, '');

        CheckWorkflowStepInstancesExist(WorkflowStep, WorkflowCode);
    end;

    local procedure CheckWorkflowStepInstancesExist(var WorkflowStep: Record "Workflow Step"; WorkflowCode: Code[20])
    var
        NextWorkflowStep: Record "Workflow Step";
        PreviousWorkflowStep: Record "Workflow Step";
    begin
        repeat
            if CheckWorkflowStepInstance(WorkflowStep) then begin
                if PreviousWorkflowStep.Get(WorkflowCode, WorkflowStep."Previous Workflow Step ID") then
                    CheckWorkflowStepInstance(PreviousWorkflowStep);

                if NextWorkflowStep.Get(WorkflowCode, WorkflowStep."Next Workflow Step ID") then
                    CheckWorkflowStepInstance(NextWorkflowStep);
            end;
        until WorkflowStep.Next() = 0;
    end;

    local procedure CheckWorkflowStepInstance(WorkflowStep: Record "Workflow Step"): Boolean
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep.ID);

        if WorkflowStep.Type = WorkflowStep.Type::"Sub-Workflow" then
            Assert.IsTrue(WorkflowStepInstance.IsEmpty,
              StrSubstNo(RecordFoundErr, WorkflowStepInstance.TableCaption(), WorkflowStepInstance.GetFilters))
        else
            Assert.IsFalse(WorkflowStepInstance.IsEmpty,
              StrSubstNo(RecordNotFoundErr, WorkflowStepInstance.TableCaption(), WorkflowStepInstance.GetFilters));

        exit(not WorkflowStepInstance.IsEmpty);
    end;

    local procedure VerifyWorkflowBranchLines(Workflow: Record Workflow; SubWorkflowStepBranch1: Record "Workflow Step"; SubWorkflowStepBranch2: Record "Workflow Step"; LastWorkflowStep: Record "Workflow Step")
    var
        LastWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch1: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch2: Record "Workflow Step Instance";
    begin
        FindWorkflowStepInstance(WorkflowStepInstanceBranch1, Workflow, SubWorkflowStepBranch1);
        FindWorkflowStepInstance(WorkflowStepInstanceBranch2, Workflow, SubWorkflowStepBranch2);
        FindWorkflowStepInstance(LastWorkflowStepInstance, Workflow, LastWorkflowStep);

        LastWorkflowStepInstance.TestField("Previous Workflow Step ID", WorkflowStepInstanceBranch1."Workflow Step ID");
        LastWorkflowStepInstance.TestField("Next Workflow Step ID", 0);

        WorkflowStepInstanceBranch1.TestField("Next Workflow Step ID", 0);
        WorkflowStepInstanceBranch2.TestField("Next Workflow Step ID", LastWorkflowStepInstance."Workflow Step ID");
    end;

    local procedure VerifyWorkflowBranchLinesComplexJumpForwardWorkflow(Workflow: Record Workflow; SubWorkflowStepBranch1: Record "Workflow Step"; SubWorkflowStepBranch2: Record "Workflow Step"; SubWorkflowStepJumpForward: Record "Workflow Step"; LastWorkflowStep: Record "Workflow Step")
    var
        LastWorkflowStepInstance: Record "Workflow Step Instance";
        NextWorkflowStepInstanceBranch2: Record "Workflow Step Instance";
        NextWorkflowStepInstanceJumpForward: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch1: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch2: Record "Workflow Step Instance";
        WorkflowStepInstanceJumpForward: Record "Workflow Step Instance";
    begin
        FindWorkflowStepInstance(WorkflowStepInstanceBranch1, Workflow, SubWorkflowStepBranch1);

        FindWorkflowStepInstance(WorkflowStepInstanceBranch2, Workflow, SubWorkflowStepBranch2);
        FindNextWorkflowStepInstance(NextWorkflowStepInstanceBranch2, Workflow, SubWorkflowStepBranch2);

        FindWorkflowStepInstance(WorkflowStepInstanceJumpForward, Workflow, SubWorkflowStepJumpForward);
        FindNextWorkflowStepInstance(NextWorkflowStepInstanceJumpForward, Workflow, SubWorkflowStepJumpForward);

        FindWorkflowStepInstance(LastWorkflowStepInstance, Workflow, LastWorkflowStep);

        LastWorkflowStepInstance.TestField("Previous Workflow Step ID", WorkflowStepInstanceBranch1."Workflow Step ID");
        LastWorkflowStepInstance.TestField("Next Workflow Step ID", 0);

        WorkflowStepInstanceBranch1.TestField("Next Workflow Step ID", 0);
        WorkflowStepInstanceBranch2.TestField("Next Workflow Step ID", NextWorkflowStepInstanceBranch2."Workflow Step ID");
        WorkflowStepInstanceJumpForward.TestField("Next Workflow Step ID", NextWorkflowStepInstanceJumpForward."Workflow Step ID");
    end;

    local procedure VerifyWorkflowBranchLinesLoopbackWorkflow(Workflow: Record Workflow; SubWorkflowStepBranch1: Record "Workflow Step"; SubWorkflowStepBranch2: Record "Workflow Step"; LastWorkflowStep: Record "Workflow Step")
    var
        LastWorkflowStepInstance: Record "Workflow Step Instance";
        NextWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch1: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch2: Record "Workflow Step Instance";
    begin
        FindWorkflowStepInstance(WorkflowStepInstanceBranch1, Workflow, SubWorkflowStepBranch1);

        FindWorkflowStepInstance(WorkflowStepInstanceBranch2, Workflow, SubWorkflowStepBranch2);
        FindNextWorkflowStepInstance(NextWorkflowStepInstance, Workflow, SubWorkflowStepBranch2);

        FindWorkflowStepInstance(LastWorkflowStepInstance, Workflow, LastWorkflowStep);

        LastWorkflowStepInstance.TestField("Previous Workflow Step ID", WorkflowStepInstanceBranch1."Workflow Step ID");
        LastWorkflowStepInstance.TestField("Next Workflow Step ID", 0);

        WorkflowStepInstanceBranch1.TestField("Next Workflow Step ID", 0);
        WorkflowStepInstanceBranch2.TestField("Next Workflow Step ID", NextWorkflowStepInstance."Workflow Step ID");
    end;

    local procedure VerifyMultiEntryStepInstanceLinks(Workflow: Record Workflow; SubWorkflowStepBranch1: Record "Workflow Step"; SubWorkflowStepBranch2: Record "Workflow Step"; LastWorkflowStep: Record "Workflow Step")
    var
        LastWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch1: Record "Workflow Step Instance";
        WorkflowStepInstanceBranch2: Record "Workflow Step Instance";
    begin
        FindWorkflowStepInstance(WorkflowStepInstanceBranch1, Workflow, SubWorkflowStepBranch1);
        FindWorkflowStepInstance(WorkflowStepInstanceBranch2, Workflow, SubWorkflowStepBranch2);
        FindWorkflowStepInstance(LastWorkflowStepInstance, Workflow, LastWorkflowStep);

        LastWorkflowStepInstance.TestField("Previous Workflow Step ID", WorkflowStepInstanceBranch2."Workflow Step ID");
        LastWorkflowStepInstance.TestField("Next Workflow Step ID", 0);

        WorkflowStepInstanceBranch1.TestField("Next Workflow Step ID", 0);
        WorkflowStepInstanceBranch2.TestField("Next Workflow Step ID", 0);
    end;

    local procedure FindWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; Workflow: Record Workflow; WorkflowStep: Record "Workflow Step")
    begin
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstance.SetRange(Type, WorkflowStep.Type);
        WorkflowStepInstance.FindFirst();
    end;

    local procedure FindNextWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; Workflow: Record Workflow; WorkflowStep: Record "Workflow Step")
    begin
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep."Next Workflow Step ID");
        WorkflowStepInstance.FindFirst();
    end;
}

