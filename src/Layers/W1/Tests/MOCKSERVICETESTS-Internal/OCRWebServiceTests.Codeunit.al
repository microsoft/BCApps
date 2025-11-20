codeunit 135095 "OCR Web Service Tests"
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
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        VendorNameErr: Label 'Vendor Name must have a value in Incoming Document';
        ExternalDocumentReferenceLbl: Label '68f89f3f4eb7436daa20d960c311b01e';
        TestSupplierTxt: Label 'TestSupplier';

    local procedure Initialize()
    begin
        ResetOCRSetup();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure OCRSetupTestConnection()
    var
        OCRServiceDocTemplate: Record "OCR Service Document Template";
        OCRServiceSetupCard: TestPage "OCR Service Setup";
    begin
        Initialize();

        Assert.IsFalse(OCRServiceDocTemplate.FindFirst(), '');

        OCRServiceSetupCard.OpenEdit();

        Assert.AreEqual(OCRServiceSetupCard."Customer Name".Value, '', '');
        Assert.AreEqual(OCRServiceSetupCard."Customer ID".Value, '', '');
        Assert.AreEqual(OCRServiceSetupCard."Customer Status".Value, '', '');

        OCRServiceSetupCard.TestConnection.Invoke();

        Assert.AreNotEqual(OCRServiceSetupCard."Customer Name".Value, '', '');
        Assert.AreNotEqual(OCRServiceSetupCard."Customer ID".Value, '', '');
        Assert.AreNotEqual(OCRServiceSetupCard."Customer Status".Value, '', '');

        OCRServiceSetupCard.Close();

        Assert.IsTrue(OCRServiceDocTemplate.FindFirst(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetURLsToDefaultRSO()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceSetupCard: TestPage "OCR Service Setup";
    begin
        Initialize();

        OCRServiceSetup.Get();
        OCRServiceSetup.Delete();

        OCRServiceSetupCard.OpenEdit();
        OCRServiceSetupCard.SetURLsToDefault.Invoke();

        Assert.AreNotEqual(OCRServiceSetupCard."Sign-up URL".Value, '', '');
        Assert.AreNotEqual(OCRServiceSetupCard."Service URL".Value, '', '');
        Assert.AreNotEqual(OCRServiceSetupCard."Sign-in URL".Value, '', '');

        OCRServiceSetupCard.Trap();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure E2ECreditMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        // Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();

        // Create a Sales Credit Memo PDF that need to be OCR'ed
        CreateSalesCreditMemoAndAttachToIncomingDocAsPDF(SalesCrMemoHeader, IncomingDocument, 10004);

        // Open Incoming Documents with the attached Sales Credit Memo
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // Send the incoming doc to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10004);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01e');
        IncomingDocumentAttachment.Modify(true);

        // Receive document from OCR
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.ReceiveFromOCR.Invoke();

        // create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup."Credit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();

        // create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        CompanyInformation.Get();
        VendorBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        VendorBankAccount.Modify();

        // create a credit memo out of the downloaded file
        IncomingDocumentCard.CreateDocument.Invoke();

        // Verify
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        IncomingDocumentCard."Amount Excl. VAT".AssertEquals(SalesCrMemoHeader.Amount);
        IncomingDocumentCard."Amount Incl. VAT".AssertEquals(SalesCrMemoHeader."Amount Including VAT");
        IncomingDocumentCard.StatusField.AssertEquals(IncomingDocument.Status::Created);
        IncomingDocumentCard."Vendor Name".AssertEquals('TestSupplier');

        PurchaseCreditMemo.Trap();
        IncomingDocumentCard.Record.DrillDown();

        SalesCrMemoHeader.TestField(Amount, PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal());
        SalesCrMemoHeader.TestField("Amount Including VAT", PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal());

        // cleanup
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseCreditMemo."No.".Value);
        PurchaseHeader.Delete(true);
        Vendor.Get(VendorNo);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
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
        TextToAccountMapping: Record "Text-to-Account Mapping";
        Vendor: Record Vendor;
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        // Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument, 10001);
        IncomingDocument."Data Exchange Type" := 'OCRINVOICE';
        IncomingDocument.Modify();
        // Open Incoming Documents with the attached Sales Invoice
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // Send the incoming doc to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10001);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);
        // create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();
        // Receive document from OCR
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.ReceiveFromOCR.Invoke();

        // create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        CompanyInformation.Get();
        VendorBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        VendorBankAccount.Modify();

        // Create a mapping
        TextToAccountMapping.SetFilter("Mapping Text", 'TestSupplier');
        if TextToAccountMapping.Get() then
            TextToAccountMapping.Delete();

        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := 'TestSupplier';
        TextToAccountMapping."Debit Acc. No." := '1GU00000005';
        TextToAccountMapping."Credit Acc. No." := '1GU00000006';
        TextToAccountMapping."Bal. Source No." := '1GU00000007';
        TextToAccountMapping.Insert(true);

        // Create a Posting Group
        if VATPostingSetup.Get('GU00000002', '') then
            VATPostingSetup.Delete();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := 'GU00000002';
        VATPostingSetup."VAT Prod. Posting Group" := '';
        VATPostingSetup."VAT Identifier" := 'VAT25';
        VATPostingSetup."VAT %" := 25;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Insert(true);

        // Verify
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        IncomingDocumentCard."Amount Excl. VAT".AssertEquals(SalesInvoiceHeader.Amount);
        IncomingDocumentCard.StatusField.AssertEquals(IncomingDocument.Status::Released);
        IncomingDocumentCard."Vendor Name".AssertEquals('TestSupplier');

        // cleanup
        Vendor.Get(VendorNo);
        Vendor.Delete(true);
        IncomingDocument.Get(IncomingDocument."Entry No.");
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ReceiveDocumentsDocumentJobPendingWithPaging()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Initialize();
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument, 10002);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10002);
        IncomingDocumentAttachment.FindFirst();

        // set attachment ext doc id to a failed guid
        IncomingDocumentAttachment.Validate("External Document Reference", 'pend9f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);
        IncomingDocument.Validate("OCR Status", IncomingDocument."OCR Status"::Sent);
        IncomingDocument.Modify(true);

        CODEUNIT.Run(CODEUNIT::"OCR - Receive from Service"); // no errors - silent

        // Assert
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument."OCR Status"::Sent, IncomingDocument."OCR Status", '');
        Assert.AreEqual(SalesInvoiceHeader.Amount, IncomingDocument."Amount Incl. VAT", '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ReceiveSingleDocumentFailed()
    var
        IncomingDocument: Record "Incoming Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        Initialize();

        // create inc doc with attachment
        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument, 10003);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10003);
        IncomingDocumentAttachment.FindLast();

        // set attachment ext doc id to a failed guid
        IncomingDocumentAttachment.Validate("External Document Reference", 'fail8f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Validate("Use for OCR", true);
        IncomingDocumentAttachment.Modify(true);
        IncomingDocument.Validate("OCR Status", IncomingDocument."OCR Status"::Sent);
        IncomingDocument.Modify(true);

        // Exercise
        IncomingDocumentPage.OpenEdit();
        IncomingDocumentPage.GotoRecord(IncomingDocument);
        IncomingDocumentPage.ReceiveFromOCR.Invoke();

        // Assert
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument."OCR Status"::Error, IncomingDocument."OCR Status", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveDocumentsInvalidIdentifier()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        Initialize();

        OCRServiceSetup.Get();
        OCRServiceSetup.Validate("Service URL", OCRServiceSetup."Service URL" + '/invalidchar/');
        OCRServiceSetup.Modify();

        asserterror CODEUNIT.Run(CODEUNIT::"OCR - Receive from Service");
        Assert.ExpectedError('contains invalid characters');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ResetOriginalOCRData()
    var
        IncomingDocument: Record "Incoming Document";
        TempOriginalIncomingDocument: Record "Incoming Document" temporary;
    begin
        // Setup
        SetupTestForOCRCorrection(IncomingDocument);
        TempOriginalIncomingDocument := IncomingDocument;

        // Exercise
        ModifyOCRData(IncomingDocument);
        ResetOCRData(IncomingDocument);

        // Verify
        Assert.AreEqual(TempOriginalIncomingDocument."Vendor VAT Registration No.", IncomingDocument."Vendor VAT Registration No.", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Vendor IBAN", IncomingDocument."Vendor IBAN", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Vendor Bank Branch No.", IncomingDocument."Vendor Bank Branch No.", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Vendor Bank Account No.", IncomingDocument."Vendor Bank Account No.", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Order No.", IncomingDocument."Order No.", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Document Date", IncomingDocument."Document Date", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Due Date", IncomingDocument."Due Date", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Currency Code", IncomingDocument."Currency Code", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Amount Incl. VAT", IncomingDocument."Amount Incl. VAT", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Amount Excl. VAT", IncomingDocument."Amount Excl. VAT", '');
        Assert.AreEqual(TempOriginalIncomingDocument."VAT Amount", IncomingDocument."VAT Amount", '');
        Assert.AreEqual(TempOriginalIncomingDocument."Vendor Name", IncomingDocument."Vendor Name", '');

        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure CorrectOCRDataFile()
    var
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        XMLDOMManagement: Codeunit "XML DOM Management";
        CorrectedXMLRootNode: DotNet XmlNode;
        InStream: InStream;
        CorrectedXMLContent: Text;
    begin
        // Setup
        SetupTestForOCRCorrection(IncomingDocument);

        // Exercise
        ModifyOCRData(IncomingDocument);
        OCRServiceMgt.CorrectOCRFile(IncomingDocument, TempBlob);

        // Assert
        TempBlob.CreateInStream(InStream);
        InStream.Read(CorrectedXMLContent);
        XMLDOMManagement.LoadXMLNodeFromText(CorrectedXMLContent, CorrectedXMLRootNode);

        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor Name")), IncomingDocument."Vendor Name");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Order No.")), IncomingDocument."Order No.");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Document Date")),
          OCRServiceMgt.DateConvertXML2YYYYMMDD(Format(IncomingDocument."Document Date", 0, 9)));
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Due Date")),
          OCRServiceMgt.DateConvertXML2YYYYMMDD(Format(IncomingDocument."Due Date", 0, 9)));
        VerifyCorrectedXMLValue(
          CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Amount Excl. VAT")), DelChr(Format(IncomingDocument."Amount Excl. VAT", 0, 9), '>', '0'));
        VerifyCorrectedXMLValue(
          CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Amount Incl. VAT")), DelChr(Format(IncomingDocument."Amount Incl. VAT", 0, 9), '>', '0'));
        VerifyCorrectedXMLValue(
          CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("VAT Amount")), DelChr(Format(IncomingDocument."VAT Amount", 0, 9), '>', '0'));
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Currency Code")), IncomingDocument."Currency Code");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor VAT Registration No.")),
          IncomingDocument."Vendor VAT Registration No.");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor IBAN")), IncomingDocument."Vendor IBAN");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor Bank Branch No.")), IncomingDocument."Vendor Bank Branch No.");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor Bank Account No.")),
          IncomingDocument."Vendor Bank Account No.");
        VerifyCorrectedXMLValue(CorrectedXMLRootNode, IncomingDocument.GetDataExchangePath(IncomingDocument.FieldNo("Vendor Phone No.")), IncomingDocument."Vendor Phone No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure CorrectOCRDataFileNoVendorName()
    var
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        // Setup
        SetupTestForOCRCorrection(IncomingDocument);

        // Exercise
        ModifyOCRDataModifyOCRDataSpecifyVendorName(IncomingDocument, '');
        asserterror OCRServiceMgt.CorrectOCRFile(IncomingDocument, TempBlob);

        // Assert
        Assert.ExpectedError(VendorNameErr);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure UndoSetReadyForOCRNewDocument()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        UndoSetReadyForOCR(IncomingDocument.Status::New)
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure UndoSetReadyForOCRApprovedDocument()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        UndoSetReadyForOCR(IncomingDocument.Status::Released)
    end;

    local procedure UndoSetReadyForOCR(InitialDocumentStatus: Option)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
        OutStream: OutStream;
        InStream: InStream;
        FileContent: BigText;
    begin
        Initialize();

        // Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();

        // Add an attachment
        FileContent.AddText('abc');
        TempBlob.CreateOutStream(OutStream);
        FileContent.Write(OutStream);
        TempBlob.CreateInStream(InStream);
        IncomingDocument.CreateIncomingDocument(LibraryUtility.GenerateGUID(), '');
        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, 'abc', 'pdf', InStream);

        // Open Incoming Document Card with the attached Sales Invoice
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        if InitialDocumentStatus = IncomingDocument.Status::Released then
            IncomingDocumentCard.Release.Invoke();
        IncomingDocumentCard.SendToJobQueue.Invoke();

        // undo set ready for ocr
        IncomingDocumentCard.RemoveFromJobQueue.Invoke();

        // Verify
        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
    end;

    local procedure CreateIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; FileName: Text; LineNo: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        ExportFile: File;
        InStream: InStream;
        OutStream: OutStream;
    begin
        ExportFile.Open(FileName);

        ExportFile.CreateInStream(InStream);

        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
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

    local procedure CreateSalesInvoiceAndAttachToIncomingDocAsPDF(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IncomingDocument: Record "Incoming Document"; LineNo: Integer)
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
        CreateIncomingDocAttachment(IncomingDocument, ServerAttachmentFilePath, LineNo);
    end;

    local procedure CreateSalesCreditMemoAndAttachToIncomingDocAsPDF(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IncomingDocument: Record "Incoming Document"; LineNo: Integer)
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

        // Create a Sales Credit Memo and Post
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // Save Posted Sales Credit Memo as PDF
        ServerAttachmentFilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, 250);
        SalesCrMemoHeader.SetRecFilter();
        REPORT.SaveAsPdf(REPORT::"Standard Sales - Credit Memo", ServerAttachmentFilePath, SalesCrMemoHeader);

        // Create Incoming Document and attach Sales Credit Memo
        IncomingDocument.CreateIncomingDocument(LibraryUtility.GenerateGUID(), '');
        CreateIncomingDocAttachment(IncomingDocument, ServerAttachmentFilePath, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAuthenticateSuccessful()
    var
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        Initialize();

        Assert.IsTrue(OCRServiceMgt.Authenticate(), 'Authentication should be successful.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetStatusUrl()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        LineNo: Integer;
        Link: Text;
    begin
        Initialize();
        // Clean up
        LineNo := 12300;
        IncomingDocument.SetRange("Entry No.", LineNo);
        IncomingDocumentAttachment.SetRange("Line No.", LineNo);
        IncomingDocumentAttachment.DeleteAll();
        IncomingDocument.DeleteAll();
        // Setup
        IncomingDocument.Init();
        IncomingDocument."Entry No." := LineNo;
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::"Awaiting Verification";
        IncomingDocument.Insert();

        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment."Incoming Document Entry No." := LineNo;
        IncomingDocumentAttachment."Use for OCR" := true;
        IncomingDocumentAttachment.Default := true;
        IncomingDocumentAttachment."Main Attachment" := true;

        IncomingDocumentAttachment."External Document Reference" := '569ef6855e144b58bf1b8acc0a022031';
        IncomingDocumentAttachment.Insert();
        // Excersise
        Link := OCRServiceMgt.GetStatusHyperLink(IncomingDocument);

        OCRServiceSetup.Get();
        Assert.AreEqual(OCRServiceSetup."Sign-in URL" +
          '/documents/6466164a15414f34aafa0fcd4e1143ee', Link, 'Expected that links are equal');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure SendOCRDataWithFeedBackAndCreateDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 535769] No error Messagege if you try to Create Document from Incoming Document after Send OCR Feedback is executed.
        Initialize();

        // [GIVEN] Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();

        // [GIVEN] Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument, 10001);
        IncomingDocument."Data Exchange Type" := 'OCRINVOICE';
        IncomingDocument.Modify();

        // [GIVEN] Open Incoming Documents with the attached Sales Invoice
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // [GIVEN] Send the incoming doc to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // [GIVEN] Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10001);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", ExternalDocumentReferenceLbl);
        IncomingDocumentAttachment.Modify(true);

        // [GIVEN] Create a default GLAccount for non-item lines
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccountNo;
        PurchasesPayablesSetup.Modify();

        // [WHEN] Receive document from OCR
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.ReceiveFromOCR.Invoke();

        // [GIVEN] Create a vendor with the IBAN equal to company information IBAN (this is the supplier in the OCRed file)
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        CompanyInformation.Get();
        VendorBankAccount.IBAN := DelChr(CompanyInformation.IBAN, '=', ' ');
        VendorBankAccount.Modify();

        // [GIVEN] Create a mapping
        CreateTextToAccountMapping();

        // [GIVEN] Create a Posting Group
        CreateVATPostingSetupForBlankVATProdPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [THEN] Verify the Incoming Document 
        SalesInvoiceHeader.CalcFields(Amount);
        IncomingDocumentCard."Amount Excl. VAT".AssertEquals(SalesInvoiceHeader.Amount);
        IncomingDocumentCard.StatusField.AssertEquals(IncomingDocument.Status::Released);
        IncomingDocumentCard."Vendor Name".AssertEquals(TestSupplierTxt);

        // [GIVEN] Clean the variables
        Vendor.Get(VendorNo);
        Vendor.Delete(true);
        IncomingDocument.Get(IncomingDocument."Entry No.");
        IncomingDocument.Delete(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Text: Text)
    begin
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

    [Scope('OnPrem')]
    procedure ModifyOCRData(var IncomingDocument: Record "Incoming Document")
    begin
        ModifyOCRDataModifyOCRDataSpecifyVendorName(IncomingDocument, LibraryUtility.GenerateGUID());
    end;

    local procedure ModifyOCRDataModifyOCRDataSpecifyVendorName(var IncomingDocument: Record "Incoming Document"; VendorName: Text)
    var
        Currency: Record Currency;
        OCRDataCorrection: TestPage "OCR Data Correction";
    begin
        OCRDataCorrection.OpenEdit();
        OCRDataCorrection.GotoRecord(IncomingDocument);
        OCRDataCorrection."Vendor Name".SetValue(VendorName);
        OCRDataCorrection."Vendor IBAN".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Bank Branch No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Bank Account No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor VAT Registration No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Phone No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Order No.".SetValue(LibraryUtility.GenerateGUID());
        LibraryERM.CreateCurrency(Currency);
        OCRDataCorrection."Document Date".SetValue(LibraryRandom.RandDateFrom(Today, 10));
        OCRDataCorrection."Due Date".SetValue(LibraryRandom.RandDateFrom(Today + 10, 20));
        OCRDataCorrection."Currency Code".SetValue(Currency.Code);
        OCRDataCorrection."Amount Incl. VAT".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection."Amount Excl. VAT".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection."VAT Amount".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection.OK().Invoke();
        IncomingDocument.Get(IncomingDocument."Entry No.");
    end;

    local procedure ResetOCRData(var IncomingDocument: Record "Incoming Document")
    var
        OCRDataCorrection: TestPage "OCR Data Correction";
    begin
        OCRDataCorrection.OpenEdit();
        OCRDataCorrection.GotoRecord(IncomingDocument);
        OCRDataCorrection."Reset OCR Data".Invoke();
        OCRDataCorrection.OK().Invoke();
        IncomingDocument.Get(IncomingDocument."Entry No.");
    end;

    local procedure VerifyCorrectedXMLValue(CorrectedXMLRootNode: DotNet XmlNode; XPath: Text; ExpectedValue: Text)
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := CorrectedXMLRootNode.SelectSingleNode(XPath);
        Assert.AreEqual(ExpectedValue, XMLNode.InnerText, StrSubstNo('Unexpected value of node: %1', XPath));
    end;

    local procedure SetupTestForOCRCorrection(var IncomingDocument: Record "Incoming Document")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SendIncomingDocumentToOcr: Codeunit "Send Incoming Document to OCR";
        OCRServiceSetupPage: TestPage "OCR Service Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        // Create OCR Setup
        OCRServiceSetupPage.OpenEdit();
        OCRServiceSetupPage.TestConnection.Invoke();

        // Create a Sales Invoice PDF that need to be OCR'ed
        CreateSalesInvoiceAndAttachToIncomingDocAsPDF(SalesInvoiceHeader, IncomingDocument, 10005);
        Assert.AreEqual(SalesInvoiceHeader.Amount, IncomingDocument."Amount Incl. VAT", '');
        // Send the incoming doc to OCR
        SendIncomingDocumentToOcr.SetShowMessages(false);
        SendIncomingDocumentToOcr.SendDocToOCR(IncomingDocument);

        // Mark attachment with Mock Service Batch Filter Id
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Line No.", 10005);
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.Validate("External Document Reference", '68f89f3f4eb7436daa20d960c311b01d');
        IncomingDocumentAttachment.Modify(true);

        // Receive document from OCR
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.ReceiveFromOCR.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
    end;

    local procedure CreateVATPostingSetupForBlankVATProdPostingGroup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATBusPostingGroup, '') then
            VATPostingSetup.Delete();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := '';
        VATPostingSetup."VAT Identifier" := 'VAT25';
        VATPostingSetup."VAT %" := 25;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Insert(true);
    end;

    local procedure CreateTextToAccountMapping()
    var
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccountMapping.SetFilter("Mapping Text", TestSupplierTxt);
        if TextToAccountMapping.Get() then
            TextToAccountMapping.Delete();

        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := TestSupplierTxt;
        TextToAccountMapping."Debit Acc. No." := LibraryERM.CreateGLAccountNo();
        TextToAccountMapping."Credit Acc. No." := LibraryERM.CreateGLAccountNo();
        TextToAccountMapping."Bal. Source No." := LibraryERM.CreateGLAccountNo();
        TextToAccountMapping.Insert(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := false;
    end;
}

