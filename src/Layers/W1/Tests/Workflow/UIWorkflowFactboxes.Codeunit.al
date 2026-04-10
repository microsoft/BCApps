codeunit 134339 "UI Workflow Factboxes"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = im;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [UI] [Factbox]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        BatchWorkflowNotHiddenErr: Label 'Batch workflow Status factbox is not hidden';
        BatchWorkflowHiddenErr: Label 'Batch workflow Status factbox is hidden';
        LineWorkflowNotHiddenErr: Label 'Line workflow Status factbox is not hidden';
        LineWorkflowHiddenErr: Label 'Line workflow Status factbox is hidden';

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowFactboxesNotVisibleWhenOpenCashRcptJnlPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 209184] Batch workflow status factboxes are not visible when Cash Receipt Journal Page opens

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        CreateGeneralJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal");

        Commit();
        CashReceiptJournal.OpenView();

        // [WHEN] Open Cash Receipt Journal Page
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Batch and line workflow factboxes are not visible on Cash Receipt Journal Page
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusLine.WorkflowDescription.Visible(), LineWorkflowNotHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchWorkflowFactboxIsVisibleOnCashRcptJnlPageWhenSentOnApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 209184] Batch workflow status factbox is visible on Cash Receipt Journal Page when the batch is sent for approval

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode(),
          GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal");

        Commit();
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] Click the Send Approval Request action on Cash Receipt Journal Page
        CashReceiptJournal.SendApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox becomes visible on Cash Receipt Journal Page
        Assert.IsTrue(CashReceiptJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowHiddenErr);
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusLine.WorkflowDescription.Visible(), LineWorkflowNotHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchWorkflowFactboxIsNotVisibleOnCashRcptJnlPageWhenCancelApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 209184] Batch workflow status factbox is not visible on Cash Receipt Journal Page when the approval is cancelled

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode(),
          GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal");

        // [GIVEN] Approval request sent
        Commit();
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.SendApprovalRequestJournalBatch.Invoke();

        // [WHEN] Click the Cancel Approval Request action on Cash Receipt Journal Page
        CashReceiptJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox is not visible on Cash Receipt Journal Page
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusLine.WorkflowDescription.Visible(), LineWorkflowNotHiddenErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxIsVisibleOnCashRcptJnlPageWhenSentOnApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 209184] Line workflow status factbox is visible on Cash Receipt Journal Page when the line is sent for approval

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode(),
          GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal");

        Commit();
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] Click the Send Approval Request action on Cash Receipt Journal Page
        CashReceiptJournal.SendApprovalRequestJournalLine.Invoke();

        // [THEN] Line workflow status factbox is visible on Cash Receipt Journal Page
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
        Assert.IsTrue(CashReceiptJournal.WorkflowStatusLine.WorkflowDescription.Visible(), LineWorkflowHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxIsNotVisibleOnCashRcptJnlPageWhenCancelApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 209184] Line workflow status factbox is not visible on Cash Receipt Journal Page when the approval is cancelled

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode(),
          GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal");

        // [GIVEN] Approval request sent
        Commit();
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.SendApprovalRequestJournalLine.Invoke();

        // [WHEN] Click the Cancel Approval Request action on Cash Receipt Journal Page
        CashReceiptJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Line workflow status factbox is not visible on Cash Receipt Journal Page
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
        Assert.IsFalse(CashReceiptJournal.WorkflowStatusLine.WorkflowDescription.Visible(), LineWorkflowNotHiddenErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowFactboxesNotVisibleWhenOpenPmtJnlPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 209184] Batch workflow status factboxes are not visible when Payment Journal Page opens

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        CreateGeneralJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine, GenJournalTemplate.Type::Payments, PAGE::"Payment Journal");

        Commit();
        PaymentJournal.OpenEdit();

        // [WHEN] Open Payment Journal Page
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Batch and line workflow factboxes are not visible on Payment Journal Page
        Assert.IsFalse(PaymentJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchWorkflowFactboxIsVisibleOnPmtJnlPageWhenSentOnApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 209184] Batch workflow status factbox is visible on Payment Journal Page when the batch is sent for approval

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode(),
          GenJournalTemplate.Type::Payments, PAGE::"Payment Journal");

        Commit();
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] Click the Send Approval Request action on Payment Journal Page
        PaymentJournal.SendApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox becomes visible on Payment Journal Page
        Assert.IsTrue(PaymentJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchWorkflowFactboxIsNotVisibleOnPmtJnlPageWhenCancelApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 209184] Batch workflow status factbox is not visible on Payment Journal Page when the approval is cancelled

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode(),
          GenJournalTemplate.Type::Payments, PAGE::"Payment Journal");

        // [GIVEN] Approval request sent
        Commit();
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.SendApprovalRequestJournalBatch.Invoke();

        // [WHEN] Click the Cancel Approval Request action on Payment Journal Page
        PaymentJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox is not visible on Payment Journal Page
        Assert.IsFalse(PaymentJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxIsVisibleOnPmtJnlPageWhenSentOnApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 209184] Line workflow status factbox is visible on Payment Journal Page when the line is sent for approval

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode(),
          GenJournalTemplate.Type::Payments, PAGE::"Payment Journal");

        Commit();
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] Click the Send Approval Request action on Payment Journal Page
        PaymentJournal.SendApprovalRequestJournalLine.Invoke();

        // [THEN] Line workflow status factbox is visible on Payment Journal Page
        Assert.IsFalse(PaymentJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxIsNotVisibleOnPmtJnlPageWhenCancelApproval()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 209184] Line workflow status factbox is not visible on Payment Journal Page when the approval is cancelled

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        SetupGenJnlBatchAndWorkflow(
          GenJournalBatch, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode(),
          GenJournalTemplate.Type::Payments, PAGE::"Payment Journal");

        // [GIVEN] Approval request sent
        Commit();
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.SendApprovalRequestJournalLine.Invoke();

        // [WHEN] Click the Cancel Approval Request action on Payment Journal Page
        PaymentJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Line workflow status factbox is not visible on Payment Journal Page
        Assert.IsFalse(PaymentJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowNotHiddenErr);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UI Workflow Factboxes");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();

        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UI Workflow Factboxes");

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UI Workflow Factboxes");
    end;

    local procedure SetupGenJnlBatchAndWorkflow(var GenJournalBatch: Record "Gen. Journal Batch"; WorkflowCode: Code[17]; GenJnlType: Enum "Gen. Journal Template Type"; PageID: Integer)
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow, WorkflowCode);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine, GenJnlType, PageID);
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow; WorkflowCode: Code[17])
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowCode);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; GenJnlType: Enum "Gen. Journal Template Type"; PageID: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalBatch(
          GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJnlType, PageID));

        // Make sure the only template exists with a certain Type and Page id to avoid unhandled ModalPage issue. Required for RU
        GenJournalTemplate.SetRange(Type, GenJnlType);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange("Page ID", PageID);
        GenJournalTemplate.SetFilter(Name, '<>%1', GenJournalBatch."Journal Template Name");
        GenJournalTemplate.DeleteAll();

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

