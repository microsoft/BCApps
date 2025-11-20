codeunit 135060 "Document Mailing Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Email] [Stream] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryEmail: Codeunit "Library - Email";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized, HideEmailDialog : Boolean;
        IsMailManagementOnBeforeIsEnabledActive: Boolean;
        MailingJobCategoryCodeTok: Label 'SENDINV', Comment = 'Must be max. 10 chars and no spacing. (Send Invoice)';
        CannotSendEmailErr: Label 'You cannot send the email.\Verify that the email settings are correct.', Locked = true;
        JobQueueEntryParameterString: Label '%1|%2|%3|%4|', Comment = '%1 - ReportUsage, %2 - DocNo, %3 - DocName, %4 - CustNo';
        KeepDraftOrDiscardPageQst: Label 'The email has not been sent.';
        VendorLbl: Label 'Vendor';
        PeppolFormatNameTxt: Label 'PEPPOL', Locked = true;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] A File can be attached to an email using a Stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] The function EmailFileFromStream is called
        Clear(DocumentMailing);
        DocumentMailing.EmailFileFromStream(InStream, 'new file.pdf', 'a nice body', 'a nice subject', 'someone@somewhere.com', true, 0);

        // [THEN] A temp file with the stream content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('Some content', Content, 'Content was expected to be Some content');
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('a nice body', TempEmailItem.GetBodyText(), 'Body was expected to be a nice body');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');

        // [THEN] The right values are set
        VerifyValues();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileWithBodyStreamAndPostedDocNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempEmailItem: Record "Email Item" temporary;
        HtmlBodyTempBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        RelatedRecord: RecordRef;
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        HtmlBodyInStream: InStream;
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] An email can be sent where the email body is given as a stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] 2 streams with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);
        InitializeStream('Some content', HtmlBodyTempBlob);
        HtmlBodyTempBlob.CreateInStream(HtmlBodyInStream);

        // [AND] A Related record and a receiver record
        RelatedRecord.Open(Database::"Sales Invoice Header");
        MockSalesInvoiceHeader(SalesInvoiceHeader);
        RelatedRecord.GetTable(SalesInvoiceHeader);
        SourceTables.Add(Database::"Sales Invoice Header");
        SourceIDs.Add(RelatedRecord.Field(RelatedRecord.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        // [WHEN] The EmailFile is called with an Instream as the body of the email
        Clear(DocumentMailing);
        DocumentMailing.EmailFile(Instream, 'new file.pdf', HtmlBodyInStream, '', 'someone@somewhere.com', 'EmailDocName', true, -1, SourceTables, SourceIDs, SourceRelationTypes);

        // [THEN] A temp file with the content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] A Body File exists
        Assert.IsTrue(TempEmailItem.Body.HasValue(), 'Body file does not exist.');

        // [And] The other values are set correctly
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(-1, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be -1');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileWithBodyStream()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempEmailItem: Record "Email Item" temporary;
        HtmlBodyTempBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        RelatedRecord: RecordRef;
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        HtmlBodyInStream: InStream;
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] An email can be sent where the email body is given as a stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] 2 streams with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);
        InitializeStream('Some content', HtmlBodyTempBlob);
        HtmlBodyTempBlob.CreateInStream(HtmlBodyInStream);

        // [AND] A Related record and a receiver record
        RelatedRecord.Open(Database::"Sales Invoice Header");
        MockSalesInvoiceHeader(SalesInvoiceHeader);
        RelatedRecord.GetTable(SalesInvoiceHeader);
        SourceTables.Add(Database::"Sales Invoice Header");
        SourceIDs.Add(RelatedRecord.Field(RelatedRecord.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        // [WHEN] The EmailFile is called with an Instream as the body of the email
        Clear(DocumentMailing);
        DocumentMailing.EmailFile(InStream, 'new file.pdf', HtmlBodyInStream, 'subject', 'someone@somewhere.com', true, Enum::"Email Scenario"::Default, SourceTables, SourceIDs, SourceRelationTypes);

        // [THEN] A temp file with the content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] A Body File exists
        Assert.IsTrue(TempEmailItem.Body.HasValue(), 'Body file does not exist.');

        // [And] The other values are set correctly
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(-1, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be -1');
        LibraryVariableStorage.AssertEmpty();
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestEmailHtmlFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] A HTML File can be attached to an email using a Stream
        BindSubscription(DocumentMailingTests);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] The function EmailFileFromStream is called
        Clear(DocumentMailing);
        asserterror DocumentMailing.EmailHtmlFromStream(InStream, 'someone@somewhere.com', 'a nice subject', true, 0);
        Assert.AreEqual(CannotSendEmailErr, GetLastErrorText(), 'Error was expected.');

        // [THEN] A temp file with the stream content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');

        // [THEN] The right values are set
        VerifyValues();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure DocumentSendingProfile_MultiInvoices_Email_Background()
    begin
        DocumentSendingProfile_MultiInvoices_Email_Background_Internal();
    end;

    procedure DocumentSendingProfile_MultiInvoices_Email_Background_Internal()
    var
        Customer: array[2] of Record Customer;
        SalesHeader: array[2, 2] of Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        TestClientTypeMgtSubscriber: Codeunit "Test Client Type Subscriber";
        ConnectorMock: Codeunit "Connector Mock";
        IndexCustomer: Integer;
        IndexSalesInvoice: Integer;
    begin
        // [SCENARIO 340331] Job Queue sending posted sales invoices by email must log errors happened in SMTP mail codeunit
        Initialize();
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);
        JobQueueEntry.SetRange("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.DeleteAll();

        for IndexCustomer := 1 to ArrayLen(Customer) do begin
            LibrarySales.CreateCustomer(Customer[IndexCustomer]);
            Customer[IndexCustomer].Validate("Document Sending Profile", DocumentSendingProfile.Code);
            Customer[IndexCustomer].Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
            Customer[IndexCustomer].Modify(true);

            for IndexSalesInvoice := 1 to ArrayLen(SalesHeader[IndexCustomer]) do begin
                LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[IndexCustomer] [IndexSalesInvoice], Customer[IndexCustomer]."No.");
                LibrarySales.PostSalesDocument(SalesHeader[IndexCustomer] [IndexSalesInvoice], true, true);
            end;
        end;

        LibraryVariableStorage.Enqueue(3); // Use Default Document Sending Profile
        SalesInvoiceHeader.SetFilter("Sell-to Customer No.", StrSubstNo('%1|%2', Customer[1]."No.", Customer[2]."No."));
        SalesInvoiceHeader.FindSet();

        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);
        SalesInvoiceHeader.SendRecords();

        TestClientTypeMgtSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeMgtSubscriber);

        Assert.RecordCount(JobQueueEntry, ArrayLen(SalesHeader));
        JobQueueEntry.FindSet();
        repeat
            asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
            Assert.IsFalse(IsNullGuid(JobQueueEntry."Error Message Register Id"), 'Email error must be registered');
        until JobQueueEntry.Next() = 0;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShouldSendToCustDirectlyUTWhenDocumentLayoutHasEmail()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        PostedInvoiceNo: Code[20];
        SendEmailManually: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 421871] Run ShouldSendToCustDirectly() procedure of Report Selections table on Posted Sales Invoice when Customer's email is blank and email from Document Layout is not blank.
        Initialize();

        // [GIVEN] Customer with blank Email. Document Layout with Usage "Invoice" and Email "abc@abc.com" for this Customer.
        LibrarySales.CreateCustomer(Customer);
        UpdateEmailOnCustomer(Customer, '');
        LibrarySales.CreateCustomerDocumentLayout(
            Customer."No.", "Report Selection Usage"::"S.Invoice", Report::"Standard Sales - Invoice", '', LibraryUtility.GenerateRandomEmail());

        // [GIVEN] Posted Sales Invoice for this Customer.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Run ShouldSendToCustDirectly() procedure of Report Selections table on Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SendEmailManually := ReportSelections.ShouldSendToCustDirectly("Report Selection Usage"::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
        UnbindSubscription(DocumentMailingTests);

        // [THEN] ShouldSendToCustDirectly() procedure returned false, because email address returned by GetEmailAddress() was not blank.
        Assert.IsFalse(SendEmailManually, 'ShouldSendToCustDirectly() must return false');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler')]
    procedure SendPostedSalesInvoiceWhenDocumentLayoutHasEmailAndEmailUseDefaultSettings()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 421871] Send Posted Sales Invoice when Customer's email is blank, email from Document Layout is not blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        JobQueueEntry.SetRange("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Customer with blank Email. Document Layout with Usage "Invoice" and Email "abc@abc.com" for this Customer.
        LibrarySales.CreateCustomer(Customer);
        UpdateEmailOnCustomer(Customer, '');
        LibrarySales.CreateCustomerDocumentLayout(
            Customer."No.", "Report Selection Usage"::"S.Invoice", Report::"Standard Sales - Invoice", '', LibraryUtility.GenerateRandomEmail());

        // [GIVEN] Posted Sales Invoice for this Customer.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Send Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SalesInvoiceHeader.SetRecFilter();
        SalesInvoiceHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is not shown and email is sent silently using Job Queue Entry.
        VerifyMailingJobQueueEntrySalesInvoice(SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAndDiscardModalPageHandler,ConfirmHandlerFalse,KeepDraftOrDiscardStrMenuHandler')]
    procedure SendPostedSalesInvoiceWhenBlankEmailInDocumentLayoutAndEmailUseDefaultSettings()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        ConnectorMock: Codeunit "Connector Mock";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 421871] Send Posted Sales Invoice when Customer's email and email from Document Layout are blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        HideEmailDialog := false;
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Customer with blank Email. Document Layout with Usage "Invoice" and with blank Email for this Customer.
        LibrarySales.CreateCustomer(Customer);
        UpdateEmailOnCustomer(Customer, '');
        LibrarySales.CreateCustomerDocumentLayout(
            Customer."No.", "Report Selection Usage"::"S.Invoice", Report::"Standard Sales - Invoice", '', '');

        // [GIVEN] Posted Sales Invoice "103032" for this Customer.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Send Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SalesInvoiceHeader.SetRecFilter();
        SalesInvoiceHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is shown, it has Subject "Cronus - Sales Invoice 103032" and blank To field (recipient).
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Recipient must be blank');
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText()); // subject must contain Posted Invoice No.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler')]
    procedure SendPurchaseOrderWhenDocumentLayoutHasEmailAndEmailUseDefaultSettings()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
    begin
        // [SCENARIO 421871] Send Purchase Order when Vendor's email is blank, email from Document Layout is not blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        JobQueueEntry.SetRange("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Vendor with blank Email. Document Layout with Usage "P.Order" and Email "abc@abc.com" for this Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        UpdateEmailOnVendor(Vendor, '');
        LibraryPurchase.CreateVendorDocumentLayout(
            Vendor."No.", "Report Selection Usage"::"P.Order", Report::"Standard Purchase - Order", '', LibraryUtility.GenerateRandomEmail());

        // [GIVEN] Purchase Order for this Vendor.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 100, 10);

        // [WHEN] Send Purchase Order.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is not shown and email is sent silently using Job Queue Entry.
        VerifyMailingJobQueueEntryPurchaseOrder(PurchaseHeader, "Report Selection Usage"::"P.Order");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAndDiscardModalPageHandler,ConfirmHandlerFalse,KeepDraftOrDiscardStrMenuHandler')]
    procedure SendPurchaseOrderWhenBlankEmailInDocumentLayoutAndEmailUseDefaultSettings()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [SCENARIO 421871] Send Purchase Order when Vendor's email and email from Document Layout are blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Vendor with blank Email. Document Layout with Usage "P.Order" and with blank Email for this Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        UpdateEmailOnVendor(Vendor, '');
        LibraryPurchase.CreateVendorDocumentLayout(
            Vendor."No.", "Report Selection Usage"::"P.Order", Report::"Standard Purchase - Order", '', '');

        // [GIVEN] Purchase Order "103032" for this Vendor.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 100, 10);

        // [WHEN] Send Purchase Order.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is shown, it has Subject "Cronus - Purchase Order 103032" and blank To field (recipient).
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Recipient must be blank');
        Assert.ExpectedMessage(PurchaseHeader."No.", LibraryVariableStorage.DequeueText()); // subject must contain Purchase Order No.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAttachmentNameModalPageHandler,ConfirmHandlerFalse,KeepDraftOrDiscardStrMenuHandler')]
    procedure SendPostedSalesInvoiceWhenPdfAndElectronicDocAndCombineEmailsYes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        ConnectorMock: Codeunit "Connector Mock";
        PostedInvoiceNo: Code[20];
        FileName: Text[250];
    begin
        // [SCENARIO 426569] Send Posted Sales Invoice when Document Sending Profile has E-Mail Attachment = "PDF & Electronic Document" and Combine Email Documents = true.
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] PEPPOL electronic format.
        InsertPeppolElectronicFormat();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF & Electronic Document", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::"PDF & Electronic Document", PeppolFormatNameTxt, true);

        // [GIVEN] Posted Sales Invoice "103032" for Customer with VAT Registration No and Address.
        LibrarySales.CreateCustomerWithAddress(Customer);
        SetVatRegistrationNoToCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SetYourReferenceToSalesHeader(SalesHeader);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Send Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SalesInvoiceHeader.SetRecFilter();
        SalesInvoiceHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is shown, it has Attachment file name "Cronus - Invoice 103032.zip".
        FileName := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", FileName); // file name must contain Posted Invoice No.
        Assert.ExpectedMessage('.zip', FileName);                   // extension must be zip

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAttachmentNameModalPageHandler,ConfirmHandlerFalse,KeepDraftOrDiscardStrMenuHandler')]
    procedure SendPostedSalesInvoiceWhenPdfAndElectronicDocAndCombineEmailsNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        ConnectorMock: Codeunit "Connector Mock";
        PostedInvoiceNo: Code[20];
        FileName: Text[250];
    begin
        // [SCENARIO 426569] Send Posted Sales Invoice when Document Sending Profile has E-Mail Attachment = "PDF & Electronic Document" and Combine Email Documents = false.
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] PEPPOL electronic format.
        InsertPeppolElectronicFormat();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF & Electronic Document", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::"PDF & Electronic Document", PeppolFormatNameTxt, false);

        // [GIVEN] Posted Sales Invoice "103032" for Customer with VAT Registration No and Address.
        LibrarySales.CreateCustomerWithAddress(Customer);
        SetVatRegistrationNoToCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SetYourReferenceToSalesHeader(SalesHeader);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Send Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SalesInvoiceHeader.SetRecFilter();
        SalesInvoiceHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is shown, it has Attachment file name "Cronus - Invoice 103032.zip".
        FileName := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", FileName); // file name must contain Posted Invoice No.
        Assert.ExpectedMessage('.zip', FileName);                   // extension must be zip

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        HideEmailDialog := true;
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Document Mailing Tests");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");

        SetAllowBlankPaymentInfo();
        SetupBankInfoOnCompany();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");
    end;

    procedure GetLibraryVariableStorage(var LibraryVariableStorageResult: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorageResult := LibraryVariableStorage;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; IsFromPostedDoc: Boolean; PostedDocNo: Code[20]; HideDialog: Boolean; ReportUsage: Integer)
    var
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachemntNames: List of [Text];
        InStream: InStream;
        AttachmentContent: Text;
        AttachmentName: Text;
    begin
        LibraryVariableStorage.Enqueue(TempEmailItem);
        TempEmailItem.GetAttachments(Attachments, AttachemntNames);
        if Attachments.Count() > 0 then begin
            AttachmentName := AttachemntNames.Get(1);
            Attachments.Get(1, Attachment);
            Attachment.CreateInStream(InStream);
            InStream.Read(AttachmentContent);
        end;
        LibraryVariableStorage.Enqueue(AttachmentContent);
        LibraryVariableStorage.Enqueue(AttachmentName);
        LibraryVariableStorage.Enqueue(IsFromPostedDoc);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        LibraryVariableStorage.Enqueue(HideDialog);
        LibraryVariableStorage.Enqueue(ReportUsage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeIsEnabled', '', false, false)]
    local procedure SetEmailingEnabledOnBeforeIsEnabled(OutlookSupported: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
        if not IsMailManagementOnBeforeIsEnabledActive then
            exit;

        OutlookSupported := false;
        Result := true;
        IsHandled := true;
    end;

    procedure SetMailManagementOnBeforeIsEnabledActive(IsActive: Boolean)
    begin
        IsMailManagementOnBeforeIsEnabledActive := IsActive;
    end;

    local procedure InitializeStream(Content: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(Content);
    end;

    local procedure InsertPeppolElectronicFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CountryRegion: Record "Country/Region";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        ElectronicDocumentFormat.DeleteAll();
        ElectronicDocumentFormat.InsertElectronicFormat(
            PeppolFormatNameTxt, PeppolFormatNameTxt, Codeunit::"Exp. Sales Inv. PEPPOL BIS3.0", 0,
            ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());

        CountryRegion.SetRange("VAT Scheme", '');
        CountryRegion.ModifyAll("VAT Scheme", CountryRegion.Code);

        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure SetupDefaultEmailSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        DocumentSendingProfile.DeleteAll();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::No;
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert();
    end;

    local procedure SetupDefaultEmailSendingProfile(EmailType: Option; EmailAttachment: Enum "Document Sending Profile Attachment Type"; EmailFormatCode: Code[20]; CombineEmails: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.DeleteAll();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::No;
        DocumentSendingProfile."E-Mail" := EmailType;
        DocumentSendingProfile."E-Mail Attachment" := EmailAttachment;
        DocumentSendingProfile."E-Mail Format" := EmailFormatCode;
        DocumentSendingProfile."Combine Email Documents" := CombineEmails;
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert();
    end;

    local procedure SetAllowBlankPaymentInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Allow Blank Payment Info." := true;
        CompanyInformation.Modify();
    end;

    local procedure SetVatRegistrationNoToCustomer(var Customer: Record Customer)
    begin
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Modify(true);
    end;

    local procedure SetYourReferenceToSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
    end;

    local procedure SetupBankInfoOnCompany()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate(Name, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInfo.Validate("Bank Branch No.", '1234');
        CompanyInfo.Validate(GLN, '1234567890128');
        CompanyInfo.Modify(true);
    end;

    local procedure UpdateEmailOnCustomer(var Customer: Record Customer; EmailAddress: Text[80])
    begin
        Customer.Validate("E-Mail", EmailAddress);
        Customer.Modify(true);
    end;

    local procedure UpdateEmailOnVendor(var Vendor: Record Vendor; EmailAddress: Text[80])
    begin
        Vendor.Validate("E-Mail", EmailAddress);
        Vendor.Modify(true);
    end;

    local procedure VerifyValues()
    begin
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be 0');
    end;

    local procedure VerifyMailingJobQueueEntrySalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; ReportSelectionUsage: Enum "Report Selection Usage")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ParameterString: Text;
        DocName: Text[150];
    begin
        DocName := ReportDistributionMgt.GetFullDocumentTypeText(SalesInvoiceHeader);
        ParameterString := StrSubstNo(JobQueueEntryParameterString, ReportSelectionUsage.AsInteger(), SalesInvoiceHeader."No.", DocName, SalesInvoiceHeader."Sell-to Customer No.");
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId());
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", Codeunit::"Document-Mailing");
        JobQueueEntry.TestField("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.TestField("Parameter String", ParameterString);
    end;

    local procedure VerifyMailingJobQueueEntryPurchaseOrder(PurchaseHeader: Record "Purchase Header"; ReportSelectionUsage: Enum "Report Selection Usage")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ParameterString: Text;
        DocName: Text[150];
    begin
        DocName := ReportDistributionMgt.GetFullDocumentTypeText(PurchaseHeader);
        ParameterString := StrSubstNo(JobQueueEntryParameterString, ReportSelectionUsage.AsInteger(), PurchaseHeader."No.", DocName, PurchaseHeader."Buy-from Vendor No.");
        ParameterString += VendorLbl;
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader.RecordId());
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", Codeunit::"Document-Mailing");
        JobQueueEntry.TestField("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.TestField("Parameter String", ParameterString);
    end;


    local procedure MockSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsStrMenuHandler(MenuOptions: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmailEditorCheckAndDiscardModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.ToField.Value);
        LibraryVariableStorage.Enqueue(EmailEditor.SubjectField.Value);
        EmailEditor.Discard.Invoke();
    end;

    [ModalPageHandler]
    procedure EmailEditorCheckAttachmentNameModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.Attachments.FileName.Value);
        EmailEditor.Discard.Invoke();
    end;

    [StrMenuHandler]
    procedure KeepDraftOrDiscardStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.AreEqual(KeepDraftOrDiscardPageQst, Instruction, '');
        Choice := 2;    // discard email
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnSendViaEmailModuleOnBeforeOpenInEditorModally', '', false, false)]
    local procedure OnSendViaEmailModuleOnBeforeOpenInEditorModally(EmailScenario: Enum "Email Scenario"; var TempEmailAccount: Record "Email Account" temporary; var Message: Codeunit "Email Message"; var HideMailDialog: Boolean)
    begin
        HideMailDialog := HideEmailDialog;
    end;
}

