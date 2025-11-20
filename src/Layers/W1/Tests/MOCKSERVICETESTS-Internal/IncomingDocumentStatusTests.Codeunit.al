codeunit 135097 "Incoming Document Status Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Document] [Status] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure NewCreateDocCreated()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        SetupPEPPOLVendor();
        Commit();

        // Exercise
        IncomingDocumentCard.CreateDocument.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Created, IncomingDocument.Status, '');

        Commit();
        asserterror IncomingDocumentCard.Release.Invoke();
        Assert.ExpectedError('only possible to release');
        asserterror IncomingDocumentCard.CreateDocument.Invoke();
        Assert.ExpectedError('already been created');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure NewCreateDocFailed()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Verify
        IncomingDocumentCard.CreateDocument.Invoke();

        // Exercise
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Failed, IncomingDocument.Status, '');

        Commit();
        asserterror IncomingDocumentCard.SendApprovalRequest.Invoke();

        asserterror CreateDummyIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Exercise
        IncomingDocumentCard.Reopen.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure NewRequestApprovalPendingApproval()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, FinalApproverUserSetup);

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.SendApprovalRequest.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::"Pending Approval", IncomingDocument.Status, '');

        Commit();
        asserterror IncomingDocumentCard.Reopen.Invoke();
        // ASSERTERROR IncomingDocumentCard.Release.Invoke();
        asserterror IncomingDocumentCard.CreateDocument.Invoke();
        asserterror IncomingDocumentCard.SendToOcr.Invoke();
        // ASSERTERROR IncomingDocumentCard.ReceiveFromOCR.Invoke();
        // ASSERTERROR IncomingDocumentCard.Reject.Invoke();

        // ASSERTERROR IncomingDocumentCard.SendApprovalRequest.Invoke();
        asserterror CreateDummyIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Tear down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewReleaseReleased()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.Release.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Released, IncomingDocument.Status, '');

        Commit();
        asserterror IncomingDocumentCard.SendApprovalRequest.Invoke();

        // Exercise
        IncomingDocumentCard.Reopen.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewRejectRejected()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.Reject.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Rejected, IncomingDocument.Status, '');

        Commit();

        // Exercise
        IncomingDocumentCard.Reopen.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure PApprovalApproveReleased()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, FinalApproverUserSetup);

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.SendApprovalRequest.Invoke();
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);
        IncomingDocumentCard.Approve.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Released, IncomingDocument.Status, '');

        // Tear down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure PApprovalCancelApprovalNew()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, FinalApproverUserSetup);

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.SendApprovalRequest.Invoke();
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);
        IncomingDocumentCard.RejectApproval.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Tear down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRejectRejected()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exercise
        IncomingDocumentCard.Release.Invoke();
        IncomingDocumentCard.Reject.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Rejected, IncomingDocument.Status, '');

        asserterror IncomingDocumentCard.RejectApproval.Invoke();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ReleasedCreateDocCreated()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        SetupPEPPOLVendor();
        Commit();

        // Exercise
        IncomingDocumentCard.Release.Invoke();
        IncomingDocumentCard.CreateDocument.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Created, IncomingDocument.Status, '');

        asserterror IncomingDocumentCard.RejectApproval.Invoke();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ReleasedCreateDocFailed()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Commit();

        // Exerise
        IncomingDocumentCard.Release.Invoke();
        IncomingDocumentCard.CreateDocument.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Failed, IncomingDocument.Status, '');

        asserterror IncomingDocumentCard.RejectApproval.Invoke();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure CreatedPostPosted()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        SetupPEPPOLVendor();
        Commit();

        // Exerise
        IncomingDocumentCard.CreateDocument.Invoke();
        IncomingDocument.Find();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, IncomingDocument."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::Posted, IncomingDocument.Status, '');

        Commit();
        asserterror IncomingDocumentCard.Release.Invoke();
        asserterror IncomingDocumentCard.CreateDocument.Invoke();
        asserterror IncomingDocumentCard.Reject.Invoke();
    end;

    local procedure CreateIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; FileName: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
    end;

    local procedure CreateDummyIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; AttachmentType: Text[10])
    var
        FileMgt: Codeunit "File Management";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        FileName := FileMgt.ServerTempFileName(AttachmentType);

        SystemIOFile.WriteAllText(FileName, AttachmentType);
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
    end;

    local procedure CreateSalesInvoiceAndAttachToIncomingDocAsPDF(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IncomingDocument: Record "Incoming Document")
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        CustomerBankAccount: Record "Customer Bank Account";
        FileManagement: Codeunit "File Management";
        ExpSalesInvPEPPOLBIS30: Codeunit "Exp. Sales Inv. PEPPOL BIS3.0";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        ServerAttachmentFilePath: Text;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := 10;
        Item.Modify(true);

        // Create a Sales Invoice and Post
        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := '1';
        CompanyInformation.Modify();
        LibrarySales.CreateCustomer(Cust);

        // Peppol require fields
        Cust.Address := 'a';
        Cust.City := 'b';
        Cust."Post Code" := 'c';
        Cust."Country/Region Code" := CompanyInformation."Country/Region Code";
        Cust."VAT Registration No." := CompanyInformation."VAT Registration No.";
        // Cust.gln := '131313131313';
        Cust.Modify();

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Cust."No.");
        CompanyInformation.Get();
        CustomerBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        CustomerBankAccount.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempBlob.CreateOutStream(OutStr);
        ExpSalesInvPEPPOLBIS30.GenerateXMLFile(SalesInvoiceHeader, OutStr);
        ServerAttachmentFilePath := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, ServerAttachmentFilePath);

        // Create Incoming Document and attach Sales Invoice
        IncomingDocument.CreateIncomingDocument(LibraryUtility.GenerateGUID(), '');
        CreateIncomingDocAttachment(IncomingDocument, ServerAttachmentFilePath);
    end;

    local procedure CreateIncomingDocApprovalWorkflow(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        CurrentUserSetup.DeleteAll();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.IncomingDocumentApprovalWorkflowCode());
        CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    var
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 2);

        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; IncomingDocument: Record "Incoming Document")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, IncomingDocument.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text)
    begin
    end;

    local procedure SetupPEPPOLVendor()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GLAccount: Record "G/L Account";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();

        // create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        CompanyInformation.Get();
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Get(VendorNo);
        Vendor."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Vendor.Modify();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        VendorBankAccount.Modify();
    end;

    local procedure Initialize()
    var
        Vend: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryWorkflow.DisableAllWorkflows();
        Vend.DeleteAll();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;
}

