codeunit 135096 "OCR Web Service Tests with WF"
{
    // PRECONDITION: Most tests will require Mock services to be started using the following enlistment command
    //   Start-AMCMockService -Configuration release -Secure

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [OCR]
    end;

    var
        Workflow: Record Workflow;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IsInitialized: Boolean;
        NoOfMessages: Integer;
        DocSentMsg: Label 'The document was successfully sent to the OCR service.';
        DocumentHasBeenScheduledTxt: Label 'The document has been scheduled for sending to the OCR service.';
        DocumentCreatedMsg: Label 'A document was created.';

    local procedure Initialize()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        ResetOCRSetup();

        // Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();
        OCRServiceSetupPage.Close();

        LibraryWorkflow.DisableAllWorkflows();

        // Clean up
        IncomingDocument.Reset();
        IncomingDocument.DeleteAll();

        IncomingDocumentAttachment.Reset();
        IncomingDocumentAttachment.DeleteAll();

        if IsInitialized then
            exit;

        LibraryIncomingDocuments.InitIncomingDocuments();
        IsInitialized := true;
    end;

    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure E2E()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        TextToAccountMapping: Record "Text-to-Account Mapping";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        IncomingDocumentCard: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Incoming Document] [Workflow]
        // [SCENARIO] Using a Workflow, enable a process that tracks an image for OCR to creation of the document (purchase invoice)
        // [GIVEN] An enabled OCR workflow for Incoming Documents
        // [GIVEN] A new incoming document that contains an invoice in pdf format which is marked for OCR.
        // [WHEN] The incoming document is released.
        // [THEN] Verify that the workflow will send the image to OCR, receive the result and create a purchase invoice for it.
        Initialize();
        EnableOCRWorkflow(WorkflowSetup.IncomingDocumentOCRWorkflowCode());

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);

        // create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Assert.IsFalse(VATPostingSetup.IsEmpty, '');
        Assert.IsFalse(GLAccount.IsEmpty, '');
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();

        // create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        CompanyInformation.Get();
        VendorBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        VendorBankAccount.Modify();

        Vendor.Get(VendorNo);

        // Create a mapping
        TextToAccountMapping.SetFilter("Mapping Text", 'TestSupplier');
        if TextToAccountMapping.Get() then
            TextToAccountMapping.Delete();

        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := 'TestSupplier';
        TextToAccountMapping."Debit Acc. No." := GLAccountNo;
        TextToAccountMapping."Credit Acc. No." := GLAccountNo;
        TextToAccountMapping."Bal. Source No." := GLAccountNo;
        TextToAccountMapping.Insert(true);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10000);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);

        // Send the incoming doc to OCR
        SendIncomingDocumentToOCR.SetShowMessages(false);
        SendIncomingDocumentToOCR.SendDocToOCR(IncomingDocument);

        // Open Incoming Documents with the attached Sales Invoice
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // Exercise
        IncomingDocuments.ReceiveFromOCR.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument."OCR Status"::Success, IncomingDocument."OCR Status", 'Wrong OCR Status');
        Assert.AreEqual(IncomingDocument.Status::Created, IncomingDocument.Status, 'Wrong status');

        // Verify
        IncomingDocument.Find();
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        IncomingDocumentCard."Amount Excl. VAT".AssertEquals(SalesInvoiceHeader.Amount);
        IncomingDocumentCard."Amount Incl. VAT".AssertEquals(SalesInvoiceHeader."Amount Including VAT");
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');

        PurchaseCreditMemo.Trap();
        IncomingDocumentCard.Record.DrillDown();

        PurchaseCreditMemo."Buy-from Vendor Name".AssertEquals('TestSupplier');
        Assert.AreEqual(SalesInvoiceHeader.Amount, PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(), '');
        Assert.AreEqual(SalesInvoiceHeader."Amount Including VAT", PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(), '');

        // cleanup
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseCreditMemo."No.".Value);
        PurchaseHeader.Delete(true);
        Vendor.Get(VendorNo);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure E2EGenJnlLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        TextToAccountMapping: Record "Text-to-Account Mapping";
        GenJournalLine: Record "Gen. Journal Line";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        IncomingDocumentCard: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Incoming Document] [Workflow]
        // [SCENARIO] Using a Workflow, enable a process that tracks an image for OCR to creation of a general journal line
        // [GIVEN] An enabled OCR workflow for Incoming Documents to General Journal Line
        // [GIVEN] A new incoming document that contains an invoice in pdf format which is marked for OCR.
        // [WHEN] The incoming document is released.
        // [THEN] Verify that the workflow will send the image to OCR, receive the result and create
        // a General Journal Line for it.
        Initialize();
        EnableOCRWorkflow(WorkflowSetup.IncomingDocumentToGenJnlLineOCRWorkflowCode());

        // Create a Sales Invoice PDF that needs to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);

        // create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);

        Vendor.Get(VendorNo);

        // create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Assert.IsFalse(VATPostingSetup.IsEmpty, 'VAT Posting Setup is empty.');
        Assert.IsFalse(GLAccount.IsEmpty, 'GL Account is empty.');
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10000);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);

        // Create a mapping
        TextToAccountMapping.SetFilter("Mapping Text", 'TestSupplier');
        if TextToAccountMapping.Get() then
            TextToAccountMapping.Delete();

        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := 'TestSupplier';
        TextToAccountMapping."Bal. Source No." := GLAccountNo;
        TextToAccountMapping.Insert(true);

        // Send the incoming doc to OCR
        SendIncomingDocumentToOCR.SetShowMessages(false);
        SendIncomingDocumentToOCR.SendDocToOCR(IncomingDocument);

        // Open Incoming Documents with the attached Sales Invoice
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // Exercise
        IncomingDocuments.ReceiveFromOCR.Invoke();

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument."OCR Status"::Success, IncomingDocument."OCR Status", 'Wrong OCR Status');
        Assert.AreEqual(IncomingDocument.Status::Created, IncomingDocument.Status, 'Wrong status');

        // Verify
        IncomingDocument.Find();
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        IncomingDocumentCard."Amount Excl. VAT".AssertEquals(SalesInvoiceHeader.Amount);
        IncomingDocumentCard."Amount Incl. VAT".AssertEquals(SalesInvoiceHeader."Amount Including VAT");
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');

        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsFalse(GenJournalLine.IsEmpty, 'There is no journal line within the range.');

        VerifyWorkflowStepInstanceArchive(Workflow, IncomingDocument);

        // cleanup
        Vendor.Get(VendorNo);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestWorkflowAssignment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        SecondIncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [FEATURE] [Incoming Document] [Workflow]
        // [SCENARIO] Using a Workflow, enable a process that tracks an image for OCR to creation of the document (purchase invoice)
        // [GIVEN] An enabled OCR workflow for Incoming Documents
        // [GIVEN] A new incoming document that contains an invoice in pdf format which is marked for OCR.
        // [WHEN] The incoming document is sent to the OCR service and then the user requests the processed document.
        // [THEN] Verify that the workflow is assigned to the given incoming document

        Initialize();
        EnableOCRWorkflow(WorkflowSetup.IncomingDocumentOCRWorkflowCode());

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10000);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);

        // Send the Document to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // Open Incoming Documents with the attached Sales Invoice
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.ReceiveFromOCR.Invoke();
        IncomingDocuments.Close();

        // Verify
        VerifyWorkflowStepInstanceArchive(Workflow, IncomingDocument);

        // delete the incomig document and create a new one
        IncomingDocument.Find();
        IncomingDocument.Delete(true);
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, SecondIncomingDocument);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", SecondIncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10000);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);

        // Send the Document to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(SecondIncomingDocument);

        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(SecondIncomingDocument);
        IncomingDocuments.ReceiveFromOCR.Invoke();
        IncomingDocuments.Close();

        // Verify
        VerifyWorkflowStepInstanceArchive(Workflow, SecondIncomingDocument);
    end;

    [Test]
    [HandlerFunctions('CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure TestCheckMessagesWhenSendingToJobQueue()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        // [SCENARIO 1] When the users sends a document to the job queue, they will only see one message, that the doc was scheduled to be sent to the OCR service.
        // [GIVEN] An enabled OCR workflow for Incoming Documents
        // [GIVEN] A new incoming document that contains an invoice in pdf format which is marked for OCR.
        // [WHEN] The incoming document is sent to the job queue.
        // [THEN] Verify that the user will only see one message.

        // Setup
        Initialize();
        NoOfMessages := 0;

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);

        // Open Incoming Documents with the attached Sales Invoice
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.SendToJobQueue.Invoke();

        // Verify
        // The verification is done in the CountingMessageHandler
    end;

    [Test]
    [HandlerFunctions('CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure TestCheckMessagesWhenSendingToOCRService()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
    begin
        // [SCENARIO 1] When the users sends a document to the OCR service, they will only see one message, that the doc was sent to the OCR service.
        // [GIVEN] An enabled OCR workflow for Incoming Documents
        // [GIVEN] A new incoming document that contains an invoice in pdf format which is marked for OCR.
        // [WHEN] The incoming document is sent to the OCR service.
        // [THEN] Verify that the user will only see one message.

        // Setup
        Initialize();
        NoOfMessages := 0;

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument);

        // Open Incoming Documents with the attached Sales Invoice
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // Verify
        // The verification is done in the CountingMessageHandler
    end;

    local procedure CreateIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; FileName: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        ExportFile: File;
        InStream: InStream;
        OutStream: OutStream;
    begin
        ExportFile.Open(FileName);

        // Copy current file contents to TempBlob
        ExportFile.CreateInStream(InStream);

        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := 10000;
        IncomingDocumentAttachment.Content.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        IncomingDocumentAttachment."File Extension" := LowerCase(CopyStr(FileMgt.GetExtension(FileName), 1, MaxStrLen(IncomingDocumentAttachment."File Extension")));
        IncomingDocumentAttachment.Name := Format(IncomingDocument."Entry No.");
        case LowerCase(IncomingDocumentAttachment."File Extension") of
            'jpg', 'jpeg', 'bmp', 'png', 'tiff', 'tif', 'gif':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Image;
            'pdf':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::PDF;
            'docx', 'doc':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Word;
            'xlsx', 'xls':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Excel;
            'pptx', 'ppt':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::PowerPoint;
            'msg':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Email;
            'xml':
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::XML;
            else
                IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Other;
        end;
        IncomingDocumentAttachment.Insert(true);
    end;

    local procedure CreateSalesInvoiceAndAttachToIncomingDocAsPDF(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IncomingDocument: Record "Incoming Document")
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        FileManagement: Codeunit "File Management";
        ServerAttachmentFilePath: Text;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := 10;
        Item.Modify(true);

        // Create a Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // Save Posted Sales Invoice as PDF
        ServerAttachmentFilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, 250);
        SalesInvoiceHeader.SetRecFilter();
        REPORT.SaveAsPdf(REPORT::"Standard Sales - Invoice", ServerAttachmentFilePath, SalesInvoiceHeader);

        // Create Incoming Document and attach Sales Invoice
        IncomingDocument.CreateIncomingDocument(LibraryUtility.GenerateGUID(), '');
        CreateIncomingDocAttachment(IncomingDocument, ServerAttachmentFilePath);
    end;

    local procedure VerifyWorkflowStepInstanceArchive(Workflow: Record Workflow; IncomingDocument: Record "Incoming Document")
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstanceArchive.SetFilter(Status,
          StrSubstNo('%1', Format(WorkflowStepInstanceArchive.Status::Completed)));
        WorkflowStepInstanceArchive.SetRange("Record ID", IncomingDocument.RecordId);
        Assert.AreEqual(4, WorkflowStepInstanceArchive.Count,
          StrSubstNo('Unexpected number of workflow step instances assigned to %1', IncomingDocument.RecordId));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Text: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CountingMessageHandler(Text: Text)
    begin
        if (Text = DocSentMsg) or (Text = DocumentHasBeenScheduledTxt) then begin
            NoOfMessages += 1;
            Assert.AreEqual(1, NoOfMessages, 'Too many messages showed');
        end;
    end;

    local procedure ResetOCRSetup()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DummySecret: Text;
    begin
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);

        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        OCRServiceSetup."User Name" := 'cronus.admin';
        DummySecret := '#Ey^VDI$B$53.8';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Password Key", DummySecret);
        DummySecret := '2e9dfdaf60ee4569a2444a1fc3d16685';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Authorization Key", DummySecret);
        OCRServiceSetup.Enabled := true;

        OCRServiceSetup."Service URL" := 'https://localhost:8080/OCR';
        OCRServiceSetup."Default OCR Doc. Template" := 'BLANK';
        OCRServiceSetup.Modify();

        Commit();
    end;

    [Normal]
    local procedure EnableOCRWorkflow(WorkflowFunctionName: Code[17])
    var
        WorkflowStep: Record "Workflow Step";
        NewWorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowFunctionName);

        // Replace notification with a message
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.FindFirst();

        NewWorkflowStep.TransferFields(WorkflowStep);
        WorkflowStep.Delete();

        NewWorkflowStep."Function Name" := WorkflowResponseHandling.ShowMessageCode();
        NewWorkflowStep.Insert();

        LibraryWorkflow.InsertMessageArgument(NewWorkflowStep.ID, DocumentCreatedMsg);

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;
}

