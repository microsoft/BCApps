codeunit 139197 DocumentSendingPostTests
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Sending Profile]
    end;

    var
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        DefaultSendingProfileContentErr: Label 'The created document sending profile should have a Sending Profile Send as PDF.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        UnexpectedSendngMethodsShownErr: Label 'Unexpected sending profiles shown in Post and Send Confirm page.';
        DocumentSendingProfileChangedErr: Label 'Document Sending Profile unexpectedly changed.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.';
        PromtsForAdditionalSettingsTxt: Label 'Dialogs will appear because sending options require user input.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJob: Codeunit "Library - Job";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        ReportNoSalesInvCrMemoHdrTxt: Label 'DocumentNo';
        ReportNoServiceInvHdrTxt: Label 'No_ServiceInvHeader';
        ReportNoServiceCrMemoHdrTxt: Label 'No1_ServiceCrMemoHeader';
        ES_ReportNoServiceCrMemoHdrTxt: Label 'No1_ServCrMemoHdr';
        IT_ReportNoServiceCrMemoHdrTxt: Label 'No_ServiceCrMemoHeader';
        NA_ReportNoServiceCrMemoHdrTxt: Label 'No_ServCrMemoHdr';
        ReportNoPurchaseOrderHdrTxt: Label 'No_PurchHeader';
        PeppolFormatNameTxt: Label 'PEPPOL', Locked = true;
        ElectronicDocFormatNotFoundErr: Label 'The electronic document format PEPPOL does not exist for the document type Sales Invoice.';
        DocExchServiceNotEnabledErr: Label 'The document exchange service is not enabled.';
        ElementNameErr: Label 'Element with name ''%1'' was not found', Comment = '%1 = Element Name';
        EmailSubjectCapTxt: Label '%1 - %2 %3', Comment = '%1 = Customer Name. %2 = Document Type %3 = Invoice No.';
        ReportAsPdfFileNameMsg: Label '%1 %2.pdf', Comment = '%1 = Document Type %2 = Invoice No.';
        SalesInvoiceTxt: Label 'Sales Invoice';
        SalesCrMemoTxt: Label 'Sales Credit Memo';
        SalesShipmentTxt: Label 'Sales Shipment';
        SalesReceiptTxt: Label 'Sales Receipt';
        YesUseDefaultSettingsTxt: Label 'Yes (Use Default Settings)';
        PdfTxt: Label 'PDF';
        ProfileSelectionQst: Label 'Confirm the first profile and use it for all selected documents.,Confirm the profile for each document.,Use the default profile for all selected documents without confirmation.';
        CustomerProfileSelectionInstrTxt: Label 'Customers on the selected documents might use different document sending profiles. Choose one of the following options: ';
        VendorProfileSelectionInstrTxt: Label 'Vendors on the selected documents might use different document sending profiles. Choose one of the following options: ';
        InterruptedByEventSubscriberErr: Label 'Interrupted by an event subscriber';
        ReportNo_SalesShptHeaderTxt: Label 'No_SalesShptHeader';
        IT_ReportNo_SalesShptHeaderTxt: Label 'No_SalesShipHdr';
        ReportNo_ReturnRcptHeaderTxt: Label 'No_ReturnRcptHeader';

    [Test]
    [HandlerFunctions('PostAndSendHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDocumentSendingProfileOnTheFly()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [WHEN] the default document sending profile list is empty and Annie tries to post and send a sales document
        // [THEN] a default document sending profile will be created and used - it will have the name Default and have "Send as PDF" as sending profile
        Initialize();

        DocumentSendingProfile.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.PostAndSend.Invoke();
        Assert.IsTrue(DocumentSendingProfile.FindFirst(), 'Document sending profile not created on the fly.');
        Assert.IsTrue(DocumentSendingProfile.Default, 'The first and only document sending profile is not marked as default.');
        Assert.AreEqual(
          DocumentSendingProfile."E-Mail", DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)",
          DefaultSendingProfileContentErr);
        Assert.AreEqual(
          DocumentSendingProfile."E-Mail Attachment", DocumentSendingProfile."E-Mail Attachment"::PDF,
          DefaultSendingProfileContentErr);
        Assert.AreEqual(DocumentSendingProfile.Printer, DocumentSendingProfile.Printer::No, DefaultSendingProfileContentErr);
        Assert.AreEqual(DocumentSendingProfile.Disk, DocumentSendingProfile.Disk::No, DefaultSendingProfileContentErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document", DocumentSendingProfile."Electronic Document"::No,
          DefaultSendingProfileContentErr);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerNoWithSendingProfileValidation')]
    [Scope('OnPrem')]
    procedure TestDefaultSendingProfileUsedForSalesInvoice()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [WHEN] Annie posts a sales invoice for a customer that doesn?t have the Sending Profile specified
        // [THEN] the default rule should be used.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryVariableStorage.Enqueue(DefaultDocumentSendingProfile);
        // verification of expected document sending profile is in the handler method
        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.PostAndSend.Invoke();

        // Test that after the handler clicked "No", Sales Header is not posted
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.")
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerNoWithSendingProfileValidation')]
    [Scope('OnPrem')]
    procedure TestDefaultSendingProfileUsedForSalesCreditMemo()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [WHEN] Annie posts a sales credit memo for a customer that doesn?t have the Sending Profile specified
        // [THEN] the default rule should be used.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryVariableStorage.Enqueue(DefaultDocumentSendingProfile);

        // Verification of expected document sending profile is in the handler method
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.PostAndSend.Invoke();

        // Test that after the handler clicked "No", Sales Header is not posted
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.")
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerNoWithSendingProfileValidation,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerSendingProfileUsedForSalesInvoice()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] Annie posts a sales invoice for a customer with specified rule on the customer card
        // [THEN] this rule is suggested to her when posting. Bill-to Customer should be used.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(BillToCustomer);
        BillToCustomer.Validate("Document Sending Profile", NonDefaultDocumentSendingProfile.Code);
        BillToCustomer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);

        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);

        // Verification of expected document Sending Profile is in the handler method
        CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);

        // Test that after the handler clicked "No", Sales Header is not posted
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.")
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerNoWithSendingProfileValidation,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerSendingProfileUsedForSalesCreditMemo()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [WHEN] Annie posts a sales credit memo for a customer with specified rule on the customer card
        // [THEN] this rule is suggested to her when posting.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(BillToCustomer);

        BillToCustomer.Validate("Document Sending Profile", NonDefaultDocumentSendingProfile.Code);
        BillToCustomer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);

        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.PostAndSend.Invoke();

        // Test that after the handler clicked "No", Sales Header is not posted
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.")
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerWithOverrideAndSendingProfileValidation,SelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSendingProfileOverrideForSalesInvoice()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        TempDefaultDocumentSendingProfileBeforeOverride: Record "Document Sending Profile" temporary;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] Annie selects post or send action
        // [THEN] she can override the system proposed document sending profile. The system will show the available options. Specifying the custom document sending profile should not update the existing document sending profile.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        TempDefaultDocumentSendingProfileBeforeOverride.Copy(DefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);
        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);
        // overriding the proposed document sending profile, and verification are in the handler method
        CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);
        // Test that after the handler clicked "No", Sales Header is not posted and default sending rule is unchanged
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        VerifySetupUnchanged(TempDefaultDocumentSendingProfileBeforeOverride, DefaultDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerWithOverrideAndSendingProfileValidation,SelectSendingOptionHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSendingProfileOverrideForSalesCreditMemo()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        TempDefaultDocumentSendingProfileBeforeOverride: Record "Document Sending Profile" temporary;
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] When Annie selects post or send action
        // [THEN] she can override the system proposed document sending profile. The system will show the available options. Specifying the custom document sending profile should not update the existing document sending profile.
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        TempDefaultDocumentSendingProfileBeforeOverride.Copy(DefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(BillToCustomer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");

        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);
        LibraryVariableStorage.Enqueue(NonDefaultDocumentSendingProfile);

        // overriding the proposed document sending profile, and verification are in the handler method
        CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);

        // Test that after the handler clicked "No", Sales Header is not posted and default sending rule is unchanged
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        VerifySetupUnchanged(TempDefaultDocumentSendingProfileBeforeOverride, DefaultDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales invoice
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create an email document sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::No, DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // create a sales invoice
        CreateCustomerWithEmail(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date", true));

        // invoke Post and Send action
        // verification is in the handler method
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();
        // Test that after the handler clicked "Yes", Sales Header is posted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Invoice not posted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,SalesShipmentRequestPageHandler,PostAndSendHandlerYes,CloseEmailEditorHandler')]
    procedure ConsiderLastUsedReportSettingsOnSendingEmail()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Item: Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentSendingPostTests: Codeunit DocumentSendingPostTests;
        LotNo: Code[50];
    begin
        // [FEATURE] [Sales] [Shipment] [Item Tracking] [Report Settings]
        // [SCENARIO 403394] Last used report settings are taken when a report is generated as an email attachment via "Post and Send".
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Settings for "Post and Send" - send by email, attach report as PDF.
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No, DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Select "Sales - Shipment" (208) report in report selections for sales shipment.
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Shipment", Report::"Sales - Shipment");

        // [GIVEN] Run the report for the first time, set "Show Lot/Serial" on the request page.
        // [GIVEN] Last used report settings are now saved.
        Commit();
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.SetRecFilter();
        Report.Run(Report::"Sales - Shipment", true, false, SalesShipmentHeader);

        // [GIVEN] Post 10 pcs of an item to inventory, assign lot no. = "L".
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 10);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 1 pc, select lot no. "L".
        CreateCustomerWithEmail(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();

        Commit();

        // [GIVEN] Subscribe to an event in "Item Tracking Doc. Management" codeunit to make sure the "Sales - Shipment" report will be run with "Show Lot/Serial" option.
        BindSubscription(DocumentSendingPostTests);

        // [WHEN] "Post and Send" the sales order.
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);
        UnbindSubscription(DocumentSendingPostTests);

        // [THEN] The event subscriber caught the event while "Sales - Shipment" report was gathering lots according to "Show Lot/Serial" setting.
        Assert.ExpectedError(InterruptedByEventSubscriberErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailPostedInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to email
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create a sales invoice and post it
        CreateCustomerWithEmail(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.SendCustom.Invoke();
        PostedSalesInvoice.Close();
        // Invoke Send action again, this time from the list. verification is in the handler method
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.SendCustom.Invoke();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler,PrintInvoiceHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintPostedInvoiceByUsingDefaultRule()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesPost: Codeunit "Sales-Post";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // create a sales invoice and post it
        if not CountryRegion.Get('AB') then begin
            CountryRegion.Validate(Code, 'AB');
            CountryRegion."ISO Code" := Format(LibraryRandom.RandIntInRange(10, 99));
            CountryRegion.Insert(true);
        end;

        CreateElectronicDocumentCustomer(Customer);
        CreateCustomerWithEmail(BillToCustomer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, '123457890');

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesPost.GetPostedDocumentRecord(SalesHeader, PostedDocumentVariant);
        SalesInvoiceHeader := PostedDocumentVariant;

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email

        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(BillToCustomer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.SendCustom.Invoke();

        // verify that the print request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYesWithOverride,EmailDialogHandlerNo,PrintInvoiceHandler,SelectSendingOptionHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintInvoiceByUsingDefaultRule()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerSpecificDocumentSendingProfile: Record "Document Sending Profile";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile,
        // and Annie clicks Post and Send on a sales invoice, and chooses to select a custom sending profile
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeTwoDocumentSendingProfilesForCustomer(CustomerSpecificDocumentSendingProfile);

        // create a sales invoice
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := CustomerSpecificDocumentSendingProfile.Code;
        Customer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date", true));

        // Invoke Send action. verification is in the handler method
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // verify that the print request page contains the correct invoice number
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindLast();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,PrintInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TestPrintInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales invoice
        // [THEN] the print preview launches
        Initialize();

        // create print with prompt sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);

        // create a sales invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Sales Header is posted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Invoice not posted.');
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindLast();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TestPrintPostedInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches
        Initialize();

        // create a sales invoice and post it
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Invoke Send action.
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.SendCustom.Invoke();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TestPrintMultiplePostedInvoices()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        PostedDocumentVariant: Variant;
        PostedDocumentVariant2: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches and multiple invoices are exported to file
        Initialize();

        // create a sales invoice and post it
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader := PostedDocumentVariant;

        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant2, Customer, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader2 := PostedDocumentVariant2;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Send multipe.
        SalesInvoiceHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesInvoiceHeader."No.", SalesInvoiceHeader2."No."));
        SalesInvoiceHeader.FindFirst();

        SalesInvoiceHeader.SendRecords();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesInvoiceHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,PrintCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure TestPrintCreditMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales credit memo
        // [THEN] the print preview launches
        Initialize();

        // create print with prompt sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);

        // create a sales invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Sales Header is posted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Credit memo not posted.');
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindLast();

        // verify that the request page contains the correct credit memo number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure TestPrintPostedCreditMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches
        // create a sales invoice and post it
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Invoke Send action.
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        PostedSalesCreditMemo.SendCustom.Invoke();

        // verify that the request page contains the correct credit memo number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure TestPrintMultiplePostedCreditMemos()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        PostedDocumentVariant: Variant;
        PostedDocumentVariant2: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches and multiple credit memos are exported to the file
        Initialize();

        // create a sales invoice and post it
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader := PostedDocumentVariant;

        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant2, Customer, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader2 := PostedDocumentVariant2;

        // for SelectSendingOptionHandler
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::"Yes (Prompt for Settings)";
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Send multipe.
        SalesCrMemoHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesCrMemoHeader."No.", SalesCrMemoHeader2."No."));
        SalesCrMemoHeader.FindFirst();

        SalesCrMemoHeader.SendRecords();

        // verify that the request page contains the correct credit memo number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailCreditMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales credit memo
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create an email document sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // create a sales credit memo
        CreateCustomerWithEmail(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date", true));
        // invoke Post and Send action
        // verification is in the handler method
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Sales Header is posted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Credit Memo not posted.');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailPostedCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create a sales credit memo and post it
        CreateCustomerWithEmail(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");

        // invoke Send action. verification is in the handler method
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        PostedSalesCreditMemo.SendCustom.Invoke();
        PostedSalesCreditMemo.Close();

        // invoke Send action again, this time from the list. verification is in the handler method
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");

        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.GotoRecord(SalesCrMemoHeader);
        PostedSalesCreditMemos.SendCustom.Invoke();
        PostedSalesCreditMemos.Close();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler,PrintCreditMemoHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintPostedCreditMemoByUsingDefaultRule()
    var
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesPost: Codeunit "Sales-Post";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted sales credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // for SelectSendingOptionHandler, insert a default rule with print and email
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // create a sales credit memo and post it
        CreateCustomerWithEmail(Customer);

        CreateCustomerWithEmail(BillToCustomer);
        BillToCustomer."Document Sending Profile" := DocumentSendingProfile.Code;
        BillToCustomer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesPost.GetPostedDocumentRecord(SalesHeader, PostedDocumentVariant);

        SalesCrMemoHeader := PostedDocumentVariant;

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Sell-to E-Mail");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.GotoRecord(SalesCrMemoHeader);
        PostedSalesCreditMemos.SendCustom.Invoke();
        PostedSalesCreditMemos.Close();

        // verify that the print request page contains the correct credit memo number
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYesWithOverride,EmailDialogHandlerNo,CloseEmailEditorHandler,PrintCreditMemoHandler,SelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintCreditMemoByUsingDefaultRule()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustomerSpecificDocumentSendingProfile: Record "Document Sending Profile";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales credit memo, and chooses to select a custom sending profile
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeTwoDocumentSendingProfilesForCustomer(CustomerSpecificDocumentSendingProfile);
        CustomerSpecificDocumentSendingProfile."E-Mail Attachment" := CustomerSpecificDocumentSendingProfile."E-Mail Attachment"::PDF;
        CustomerSpecificDocumentSendingProfile."E-Mail Format" := '';
        CustomerSpecificDocumentSendingProfile.Modify();

        // create a sales credit memo
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := CustomerSpecificDocumentSendingProfile.Code;
        Customer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader."Bill-to Address" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to City" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to Post Code" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to Country/Region Code" := 'US';
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // for SelectSendingOptionHandler, insert a default rule with print and email
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date", true));

        // Invoke Send action. verification is in the handler method
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.PostAndSend.Invoke();

        // verify that the print request page contains the correct credit memo number
        SalesCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindLast();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, SalesCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure TestDiskInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [WHEN] Disk (PDF & Electronic Doc) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales invoice
        // [THEN] the files are saved to disk
        Initialize();

        // create disk with pdf & electronic document sending profile default rule
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::"PDF & Electronic Document";
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile."Disk Format" := ElectronicDocumentFormat.Code;
        DocumentSendingProfile.Insert(true);

        // create a sales invoice
        CreateElectronicDocumentCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Sales Header is posted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Invoice not posted.');
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindLast();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure TestElectronicServiceInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesInvoice: TestPage "Sales Invoice";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [WHEN] Electronic Document (Through Document Exchange Service) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a sales invoice
        // [THEN] the posting will fail as the document exchange service is not enabled
        Initialize();

        // create sending profile configured for sending through document exch service as default rule
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile."Electronic Document" :=
          DocumentSendingProfile."Electronic Document"::"Through Document Exchange Service";
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile."Electronic Format" := ElectronicDocumentFormat.Code;
        DocumentSendingProfile.Insert(true);

        // create a sales invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        ErrorMessagesPage.Trap();
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        ErrorMessagesPage.Description.AssertEquals(DocExchServiceNotEnabledErr);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader.RecordId));

        // Test that after the error, Sales Header is not posted
        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Invoice posted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnsupportedDocumentType()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] Annie tries to invoke Post and Send for a sales order
        // [THEN] she gets the error that this document type is unsupported
        Initialize();

        UnsupportedDocumentType(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('SelectElectronicDocumentSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure TestSendingMultipleCreditMemosElectronicExportSupported()
    var
        Customer: Record Customer;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader1: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Annie tries to Send on multiple posted sales credit memos and chooses to send them electronically
        Initialize();
        ElectronicDocumentFormat.SetRange(Usage, ElectronicDocumentFormat.Usage::"Sales Credit Memo");
        ElectronicDocumentFormat.FindFirst();

        // create two sales credit memos and post them
        CreateElectronicDocumentCustomer(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader1."Document Type"::"Credit Memo");
        SalesCrMemoHeader1 := PostedDocumentVariant;
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader2."Document Type"::"Credit Memo");
        SalesCrMemoHeader2 := PostedDocumentVariant;

        // try to send both posted sales credit memos electronically
        SalesCrMemoHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesCrMemoHeader1."No.", SalesCrMemoHeader2."No."));
        SalesCrMemoHeader.FindFirst();

        // in the handler, electronic document format will be chosen
        SalesCrMemoHeader.SendRecords();
    end;

    [Test]
    [HandlerFunctions('SelectElectronicDocumentSendingOptionHandler,ConfirmDefaultProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestSendingMultipleInvoicesElectronicExportSupported()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Annie tries to Send on multiple posted sales invoices and chooses to send them electronically
        Initialize();
        ElectronicDocumentFormat.SetRange(Usage, ElectronicDocumentFormat.Usage::"Sales Invoice");
        ElectronicDocumentFormat.FindFirst();

        // create two sales invoices and post them
        CreateElectronicDocumentCustomer(Customer1);
        CreateElectronicDocumentCustomer(Customer2);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer1, SalesHeader1."Document Type"::Invoice);
        SalesInvoiceHeader1 := PostedDocumentVariant;
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer2, SalesHeader2."Document Type"::Invoice);
        SalesInvoiceHeader2 := PostedDocumentVariant;

        // try to send both posted sales invoices electronically
        SalesInvoiceHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesInvoiceHeader1."No.", SalesInvoiceHeader2."No."));
        SalesInvoiceHeader.FindFirst();

        // in the handler, electronic document format will be chosen
        SalesInvoiceHeader.SendRecords();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintCreditMemoHandler,EmailDialogHandlerNo,ConfirmDefaultProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestSendingMultipleCreditMemosToDifferentCustomers()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader1: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedDocumentVariant: Variant;
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 256223] Mutiple posted sales credit memos for different customers printed in a single document when customer report selection is not defined.
        Initialize();
        LibraryVariableStorage.AssertEmpty();

        // Create document sending profile
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // Create two sales credit memos and post them
        // [GIVEN] "Credit Memo" "CM[1]" for Customer "C[1]"
        CreateCustomerWithEmail(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader1."Document Type"::"Credit Memo");
        SalesCrMemoHeader1 := PostedDocumentVariant;

        // [GIVEN] "Credit Memo" "CM[2]" for Customer "C[2]"
        CreateCustomerWithEmail(Customer2);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer2, SalesHeader2."Document Type"::"Credit Memo");
        SalesCrMemoHeader2 := PostedDocumentVariant;

        // [WHEN] When send "CM[1]" and "CM[2]" simultaneously
        // Try to send both posted sales credit memos electronically
        SalesCrMemoHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesCrMemoHeader1."No.", SalesCrMemoHeader2."No."));
        SalesCrMemoHeader.FindFirst();

        // In the handler, electronic document format will be chosen
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader1."No.");
        LibraryVariableStorage.Enqueue(Customer2."E-Mail");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader2."No.");

        SalesCrMemoHeader.SendRecords();

        // [THEN] Both invoices printed in a single document
        FileName := LibraryVariableStorage.DequeueText();
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesCrMemoHeader1."No.", FileName);
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesCrMemoHeader2."No.", FileName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandler,EmailDialogHandlerNo,ConfirmDefaultProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestSendingMultipleInvoicesToDifferentCustomers()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedDocumentVariant: Variant;
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 256223] Mutiple posted sales invoices for different customers printed in a single document when customer report selection is not defined.
        Initialize();
        LibraryVariableStorage.AssertEmpty();

        // Create document sending profile
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // Create two sales invoices and post them
        // Create two sales credit memos and post them
        // [GIVEN] Invoice "Invoice[1]" for Customer "C[1]"
        CreateCustomerWithEmail(Customer);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader1."Document Type"::Invoice);
        SalesInvoiceHeader1 := PostedDocumentVariant;

        // [GIVEN] Invoice "Invoice[2]" for Customer "C[2]"
        CreateCustomerWithEmail(Customer2);
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer2, SalesHeader2."Document Type"::Invoice);
        SalesInvoiceHeader2 := PostedDocumentVariant;

        // [WHEN] When send "Invoice[1]" and "Invoice[2]" simultaneously
        // Try to send both posted sales invoices electronically
        SalesInvoiceHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesInvoiceHeader1."No.", SalesInvoiceHeader2."No."));
        SalesInvoiceHeader.FindFirst();

        // In the handler, electronic document format will be chosen
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader1."No.");
        LibraryVariableStorage.Enqueue(Customer2."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader2."No.");

        SalesInvoiceHeader.SendRecords();

        // [THEN] Both invoices printed in a single document
        FileName := LibraryVariableStorage.DequeueText();
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesInvoiceHeader1."No.", FileName);
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesInvoiceHeader2."No.", FileName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSendingFailsIfElectronicFormatCannotBeFound()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesInvoice: TestPage "Sales Invoice";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [GIVEN] Send Electronically is selected as a sending profile in a default document sending profile, and the specified Electronic Format is deleted or renamed
        // [WHEN] Annie clicks Post and Send on a sales invoice
        // [THEN] she gets an error that the specified Electronic Document Format cannot be found
        Initialize();

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::"Electronic Document";
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile."Disk Format" := ElectronicDocumentFormat.Code;
        DocumentSendingProfile.Insert(true);

        // create a sales invoice
        CreateElectronicDocumentCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // Invoke Post & Send action. verification is in the handler method
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        ElectronicDocumentFormat.FindFirst();
        ElectronicDocumentFormat.Delete();
        ErrorMessagesPage.Trap();
        SalesInvoice.PostAndSend.Invoke();

        ErrorMessagesPage.Description.AssertEquals(ElectronicDocFormatNotFoundErr);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader.RecordId));
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,EmailDialogHandlerNoService,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailServiceInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service invoice
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create an email document sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"Electronic Document",
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // create a Service invoice
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := DocumentSendingProfile.Code;
        Customer.Modify();
        CreateServiceHeaderWithCustomer(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        ServiceHeader."Bill-to Address" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(12, 1), 1, 12);
        ServiceHeader."Bill-to City" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(12, 1), 1, 12);
        ServiceHeader."Bill-to Post Code" := LibraryUtility.GenerateGUID();
        ServiceHeader."Bill-to Country/Region Code" := 'US';
        ServiceHeader."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(ServiceHeader."Bill-to Country/Region Code");
        ServiceHeader."Ship-to Address" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(12, 1), 1, 12);
        ServiceHeader."Ship-to City" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(12, 1), 1, 12);
        ServiceHeader."Ship-to Post Code" := LibraryUtility.GenerateGUID();
        ServiceHeader."Ship-to Country/Region Code" := 'US';

        ServiceHeader.Modify();

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(ServiceHeader."Posting No. Series", ServiceHeader."Posting Date", true));

        // invoke Post and Send action
        // verification is in the handler method
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Invoice not posted.');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNoService,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailPostedServiceInvoice()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ServicePost: Codeunit "Service-Post";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedServiceInvoices: TestPage "Posted Service Invoices";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to email
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create a service invoice and post it
        CreateCustomerWithEmail(Customer);
        CreateServiceHeaderWithCustomer(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceInvoiceHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoice.SendCustom.Invoke();
        PostedServiceInvoice.Close();
        // Invoke Send action again, this time from the list. verification is in the handler method
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");
        PostedServiceInvoices.OpenView();
        PostedServiceInvoices.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoices.SendCustom.Invoke();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNoService,CloseEmailEditorHandler,PrintInvoiceHandlerService,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintPostedServiceInvoiceByUsingDefaultRule()
    var
        CountryRegion: Record "Country/Region";
        DocumentSendingProfile: Record "Document Sending Profile";
        BillToCustomer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServicePost: Codeunit "Service-Post";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // create a Service invoice and post it
        if not CountryRegion.Get('AB') then begin
            CountryRegion.Validate(Code, 'AB');
            CountryRegion."ISO Code" := Format(LibraryRandom.RandIntInRange(10, 99));
            CountryRegion.Insert(true);
        end;

        CreateCustomerWithEmail(BillToCustomer);

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        ServiceHeader.Validate("Your Reference", '123457890');
        ServiceHeader.Validate("Due Date", WorkDate());
        ServiceHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceInvoiceHeader := PostedDocumentVariant;

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(BillToCustomer."No.");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoice.SendCustom.Invoke();

        // verify that the print request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYesWithOverride,EmailDialogHandlerNoService,PrintInvoiceHandlerService,SelectSendingOptionHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintServiceInvoiceByUsingDefaultRule()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustomerSpecificDocumentSendingProfile: Record "Document Sending Profile";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service invoice, and chooses to select a custom sending profile
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeTwoDocumentSendingProfilesForCustomer(CustomerSpecificDocumentSendingProfile);

        // create a service invoice
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := CustomerSpecificDocumentSendingProfile.Code;
        Customer.Modify();
        CreateServiceHeaderWithCustomer(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(ServiceHeader."Posting No. Series", ServiceHeader."Posting Date", true));

        // Invoke Send action. verification is in the handler method
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.PostAndSend.Invoke();

        // verify that the print request page contains the correct invoice number
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindLast();
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,PrintInvoiceHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintServiceInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a Service invoice
        // [THEN] the print preview launches
        Initialize();

        // create print with prompt sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);

        // create a Service invoice
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Invoice not posted.');
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindLast();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintPostedServiceInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServicePost: Codeunit "Service-Post";
        PostedServiceInvoices: TestPage "Posted Service Invoices";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches
        Initialize();

        // create a Service invoice and post it
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceInvoiceHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Invoke Send action.
        PostedServiceInvoices.OpenView();
        PostedServiceInvoices.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoices.SendCustom.Invoke();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintMultiplePostedServiceInvoices()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader2: Record "Service Header";
        ServiceLine2: Record "Service Line";
        ServiceInvoiceHeader2: Record "Service Invoice Header";
        ServicePost: Codeunit "Service-Post";
        PostedDocumentVariant: Variant;
        PostedDocumentVariant2: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service invoice
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches and multiple invoices are exported to file
        Initialize();

        // create a Service invoice and post it
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceInvoiceHeader := PostedDocumentVariant;

        LibraryService.CreateServiceHeader(ServiceHeader2, ServiceHeader2."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine2, ServiceHeader2, ServiceLine2.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader2);
        ServicePost.GetPostedDocumentRecord(ServiceHeader2, PostedDocumentVariant2);
        ServiceInvoiceHeader2 := PostedDocumentVariant2;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Send multipe.
        ServiceInvoiceHeader.SetFilter("No.", StrSubstNo('%1|%2', ServiceInvoiceHeader."No.", ServiceInvoiceHeader2."No."));
        ServiceInvoiceHeader.FindFirst();

        ServiceInvoiceHeader.SendRecords();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader."No.");
        AssertValidServiceInvoiceHeaderNo(ServiceInvoiceHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure TestDiskServiceInvoice()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [WHEN] Disk (PDF & Electronic Doc) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service invoice
        // [THEN] the files are saved to disk
        Initialize();

        // create disk with pdf & electronic document sending profile default rule
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::"PDF & Electronic Document";
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile."Disk Format" := ElectronicDocumentFormat.Code;
        DocumentSendingProfile.Insert(true);

        // create a Service invoice
        CreateElectronicDocumentCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader."Due Date" := WorkDate();
        ServiceHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Invoice not posted.');
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindLast();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,EmailDialogHandlerNoService,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailServiceCrMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service credit memo
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create an email document sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"Electronic Document",
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // create a service credit memo
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := DocumentSendingProfile.Code;
        Customer.Modify();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader.Validate("Due Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(ServiceHeader."Posting No. Series", ServiceHeader."Posting Date", true));

        // invoke Post and Send action
        // verification is in the handler method
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.PostAndSend.Invoke();
        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Credit Memo not posted.');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNoService,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailPostedServiceCrMemo()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ServicePost: Codeunit "Service-Post";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to email
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        Initialize();

        // create a service credit memo and post it
        CreateCustomerWithEmail(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader.Validate("Due Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceCrMemoHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No,
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.SendCustom.Invoke();
        PostedServiceCreditMemo.Close();
        // Invoke Send action again, this time from the list. verification is in the handler method
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemos.SendCustom.Invoke();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNoService,CloseEmailEditorHandler,PrintCreditMemoHandlerService,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintPostedServiceCrMemoByUsingDefaultRule()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        BillToCustomer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // create a service credit memo and post it
        if not CountryRegion.Get('AB') then begin
            CountryRegion.Validate(Code, 'AB');
            CountryRegion."ISO Code" := Format(LibraryRandom.RandIntInRange(10, 99));
            CountryRegion.Insert(true);
        end;

        CreateElectronicDocumentCustomer(Customer);

        CreateCustomerWithEmail(BillToCustomer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        ServiceHeader.Validate("Due Date", WorkDate());
        ServiceHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceCrMemoHeader := PostedDocumentVariant;

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(BillToCustomer."No.");
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");

        // Invoke Send action. verification is in the handler method
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.SendCustom.Invoke();

        // verify that the print request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceHeaderNo(ServiceCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYesWithOverride,EmailDialogHandlerNoService,PrintCreditMemoHandlerService,SelectSendingOptionHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAndPrintServiceCrMemoByUsingDefaultRule()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustomerSpecificDocumentSendingProfile: Record "Document Sending Profile";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [WHEN] Email is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service credit memo, and chooses to select a custom sending profile
        // [THEN] a dialog for selecting a sending profile launches, where she choses the default sending rule, which is to email and print
        // [THEN] the Email Editor launches, in which Annie can compile the message to the customer
        // [THEN] the print dialog launches, in which Annie can choose where to print the document
        Initialize();

        // for SelectDefaultSendingOptionHandler, insert a default rule with print and email
        InitializeTwoDocumentSendingProfilesForCustomer(CustomerSpecificDocumentSendingProfile);

        // create a service credit memo
        CreateCustomerWithEmail(Customer);
        Customer."Document Sending Profile" := CustomerSpecificDocumentSendingProfile.Code;
        Customer.Modify();
        CreateServiceHeaderWithCustomer(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");

        // For SelectDocumentSendingDialog
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(NoSeriesBatch.GetNextNo(ServiceHeader."Posting No. Series", ServiceHeader."Posting Date", true));

        // Invoke Send action. verification is in the handler method
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.PostAndSend.Invoke();

        // verify that the print request page contains the correct invoice number
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindLast();
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceHeaderNo(ServiceCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,PrintCreditMemoHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintServiceCrMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile,
        // and Annie clicks Post and Send on a service credit memo
        // [THEN] the print preview launches
        Initialize();

        // create print with prompt sending profile default rule
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);

        // create a service credit memo
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Credit Memo not posted.');
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindLast();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceHeaderNo(ServiceCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintCreditMemoHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintPostedServiceCrMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
        PostedDocumentVariant: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches
        Initialize();

        // create a service credit memo and post it
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceCrMemoHeader := PostedDocumentVariant;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Invoke Send action.
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemos.SendCustom.Invoke();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceHeaderNo(ServiceCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintCreditMemoHandlerService')]
    [Scope('OnPrem')]
    procedure TestPrintMultiplePostedServiceCrMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader2: Record "Service Header";
        ServiceLine2: Record "Service Line";
        ServiceCrMemoHeader2: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        PostedDocumentVariant: Variant;
        PostedDocumentVariant2: Variant;
    begin
        // [WHEN] Print (prompt) is selected as a sending profile in a default document sending profile, and Annie clicks Send on a posted service credit memo
        // [THEN] a dialog for selecting a sending profile launches, where she choses to print
        // [THEN] the print preview launches and multiple invoices are exported to file
        Initialize();

        // create a service credit memo and post it
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceCrMemoHeader := PostedDocumentVariant;

        LibraryService.CreateServiceHeader(ServiceHeader2, ServiceHeader2."Document Type"::"Credit Memo", Customer."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine2, ServiceHeader2, ServiceLine2.Type::Item, Item."No.", 1);
        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader2);
        ServicePost.GetPostedDocumentRecord(ServiceHeader2, PostedDocumentVariant2);
        ServiceCrMemoHeader2 := PostedDocumentVariant2;

        // for SelectSendingOptionHandler
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // Send multipe.
        ServiceCrMemoHeader.SetFilter("No.", StrSubstNo('%1|%2', ServiceCrMemoHeader."No.", ServiceCrMemoHeader2."No."));
        ServiceCrMemoHeader.FindFirst();

        ServiceCrMemoHeader.SendRecords();

        // verify that the request page contains the correct invoice number
        LibraryReportDataset.LoadDataSetFile();
        AssertValidServiceHeaderNo(ServiceCrMemoHeader."No.");
        AssertValidServiceHeaderNo(ServiceCrMemoHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure TestDiskServiceCrMemo()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [WHEN] Disk (PDF & Electronic Doc) is selected as a sending profile in a default document sending profile, and Annie clicks Post and Send on a service credit memo
        // [THEN] the files are saved to disk
        Initialize();

        // create disk with pdf & electronic document sending profile default rule
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::"PDF & Electronic Document";
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile."Disk Format" := ElectronicDocumentFormat.Code;
        DocumentSendingProfile.Insert(true);

        // create a service credit memo
        CreateElectronicDocumentCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader."Due Date" := WorkDate();
        ServiceHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);

        // invoke Post and Send action
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.PostAndSend.Invoke();

        // Test that after the handler clicked "Yes", Service Header is posted
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), 'Invoice not posted.');
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindLast();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerNoWithPromptWarningValidation')]
    [Scope('OnPrem')]
    procedure TestWarningAboutBeingPrompted()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] Annie tries to post and send a sales document and one of the chosen sending profile includes showing a dialog
        // [THEN] a warning will be displayed to Annie that there will be additional dialogs that require completing the task
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryVariableStorage.Enqueue(PromtsForAdditionalSettingsTxt);
        // verification of expected warning message is in the handler method
        CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerWithOverrideAndPromptWarningValidation,SelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure TestWarningAboutBeingPromptedNotShown()
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        NonDefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [WHEN] Annie tries to post and send a sales document and all of the chosen sending profiles are silent
        // [THEN] no warning will be displayed to Annie that there will be additional dialogs that require completing the task
        Initialize();

        CreateTwoDocumentSendingProfiles(DefaultDocumentSendingProfile, NonDefaultDocumentSendingProfile);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // pass the expected warning text to the handler
        LibraryVariableStorage.Enqueue('');
        // change the default document sending profile to have only silent sending profiles
        DefaultDocumentSendingProfile.Validate("E-Mail", DefaultDocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)");
        // pass the modified document sending profile to the handler that will customize the rule
        LibraryVariableStorage.Enqueue(DefaultDocumentSendingProfile);

        // verification of expected warning message is in the handler method
        CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerForAssistEditTest,SelectSendingOptionHandlerAllTrue')]
    [Scope('OnPrem')]
    procedure TestDocumentSendingProfileSelectionsAfterChangesInAssistEdit()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [WHEN] Annie tries to post and send an invoice, she can modify the "Send Document to" options using AssistEdit.
        // [THEN] She can click AssistEdit and change her preferences multiple times and her preferences will be preserved until
        // [THEN] she closes the modal page 365
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.PostAndSend.Invoke();
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSingleSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Email] [Sales] [Invoice]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select posted Sales Invoice "A"
        CreatePostSevSalesInvoices(SalesInvoiceHeader, 1);

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesInvoiceTxt, SalesInvoiceHeader."No.");
        SalesInvoiceHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Sales Invoice "A"
        // [THEN] "Attachment Name" = Sales Invoice "A".pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSeveralSalesInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SecondSalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Email] [Sales] [Invoice]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select several posted Invoices
        CreatePostSevSalesInvoices(SalesInvoiceHeader, 2);
        SecondSalesInvoiceHeader := SalesInvoiceHeader;
        SalesInvoiceHeader.FindFirst();

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesInvoiceTxt, SalesInvoiceHeader."No.");
        EnqueueValuesForEmailDialog(SalesInvoiceTxt, SecondSalesInvoiceHeader."No.");
        SalesInvoiceHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Invoices
        // [THEN] "Attachment Name" = Sales Invoices.pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSingleSalesCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Email] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select posted Sales Credit Memo "A"
        CreatePostSevSalesCrMemos(SalesCrMemoHeader, 1);

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesCrMemoTxt, SalesCrMemoHeader."No.");
        SalesCrMemoHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Sales Credit Memo "A"
        // [THEN] "Attachment Name" = Sales Credit Memo "A".pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSeveralSalesCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SecondSalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Email] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select several posted Credit Memos
        CreatePostSevSalesCrMemos(SalesCrMemoHeader, 2);
        SecondSalesCrMemoHeader := SalesCrMemoHeader;
        SalesCrMemoHeader.FindFirst();

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesCrMemoTxt, SalesCrMemoHeader."No.");
        EnqueueValuesForEmailDialog(SalesCrMemoTxt, SecondSalesCrMemoHeader."No.");
        SalesCrMemoHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Credit Memos
        // [THEN] "Attachment Name" = Sales Credit Memos.pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSingleSalesShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Email] [Sales] [Shipment]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select posted Sales Shipment "A"
        CreatePostSevSalesShipments(SalesShipmentHeader, 1);

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesShipmentTxt, SalesShipmentHeader."No.");
        SalesShipmentHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Sales Shipment "A"
        // [THEN] "Attachment Name" = Sales Shipment "A".pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSeveralSalesShipments()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SecondSalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Email] [Sales] [Shipment]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select several posted Shipments
        CreatePostSevSalesShipments(SalesShipmentHeader, 2);
        SecondSalesShipmentHeader := SalesShipmentHeader;
        SalesShipmentHeader.FindFirst();

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesShipmentTxt, SalesShipmentHeader."No.");
        EnqueueValuesForEmailDialog(SalesShipmentTxt, SecondSalesShipmentHeader."No.");
        SalesShipmentHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Shipments
        // [THEN] "Attachment Name" = Sales Shipments.pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSingleReturnReceipt()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [Email] [Sales] [Return Receipt]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select posted Return Receipt "A"
        CreatePostSevReturnReceipts(ReturnReceiptHeader, 1);

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesReceiptTxt, ReturnReceiptHeader."No.");
        ReturnReceiptHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Sales Receipt "A"
        // [THEN] "Attachment Name" = Sales Receipt "A".pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [HandlerFunctions('EmailDialogVerifySubjectAndAttahcmentNamesMPH,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailSubjectAndAttachmentNamesForSeveralReturnReceipts()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        SecondReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [Email] [Sales] [Return Receipt]
        Initialize();

        // [GIVEN] Company Name = "C"
        // [GIVEN] Select several posted Return Receipts
        CreatePostSevReturnReceipts(ReturnReceiptHeader, 2);
        SecondReturnReceiptHeader := ReturnReceiptHeader;
        ReturnReceiptHeader.FindFirst();

        // [WHEN] Run "Email" action
        EnqueueValuesForEmailDialog(SalesReceiptTxt, ReturnReceiptHeader."No.");
        EnqueueValuesForEmailDialog(SalesReceiptTxt, SecondReturnReceiptHeader."No.");
        ReturnReceiptHeader.EmailRecords(true);

        // [THEN] Page "Email Editor" is opened with following values:
        // [THEN] "Subject" = "C" - Receipts
        // [THEN] "Attachment Name" = Sales Receipts.pdf
        // Verify is done in EmailDialogVerifySubjectAndAttahcmentNamesMPH()
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentExchangeIfSalesInvoiceIsAlreadyChanged()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocExchLinks: Codeunit "Doc. Exch. Links";
        DocRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 380826] Run UpdateDocument function with old RecRef if Sales Inv. Header record is modified

        // [GIVEN] Sales Invoice Header "SIH"
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        DocRecRef.GetTable(SalesInvoiceHeader);

        // [GIVEN] "SIH"."Your Reference" = "YR"
        SalesInvoiceHeader."Your Reference" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Modify();
        Commit();

        // [WHEN] Run UpdateDocumentRecord function for old "SIH" RecordRef
        DocExchLinks.UpdateDocumentRecord(
          DocRecRef, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [THEN] "SIH"."Document Exchange Status" set to "Sent to Document Exchange Service"
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField(
          "Document Exchange Status", SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentExchangeIfSalesCrMemoIsAlreadyChanged()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocExchLinks: Codeunit "Doc. Exch. Links";
        DocRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 380826] Run UpdateDocument function with old RecRef if Sales Cr. Memo Header record is modified

        // [GIVEN] Sales Cr. Memo Header "SCNH"
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
        DocRecRef.GetTable(SalesCrMemoHeader);

        // [GIVEN] "SCNH"."Your Reference" = "YR"
        SalesCrMemoHeader."Your Reference" := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Modify();
        Commit();

        // [WHEN] Run UpdateDocumentRecord function for old "SCNH" RecordRef
        DocExchLinks.UpdateDocumentRecord(
          DocRecRef, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [THEN] "SCNH"."Document Exchange Status" set to "Sent to Document Exchange Service"
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.TestField(
          "Document Exchange Status", SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentExchangeIfServiceInvoiceIsAlreadyChanged()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocExchLinks: Codeunit "Doc. Exch. Links";
        DocRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 380826] Run UpdateDocument function with old RecRef if Service Inv. Header record is modified

        // [GIVEN] Service Invoice Header "SIH"
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Insert();
        DocRecRef.GetTable(ServiceInvoiceHeader);

        // [GIVEN] "SIH"."Your Reference" = "YR"
        ServiceInvoiceHeader."Your Reference" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Modify();
        Commit();

        // [WHEN] Run UpdateDocumentRecord function for old "SIH" RecordRef
        DocExchLinks.UpdateDocumentRecord(
          DocRecRef, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [THEN] "SIH"."Document Exchange Status" set to "Sent to Document Exchange Service"
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader.TestField(
          "Document Exchange Status", ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentExchangeIfServiceCrMemoIsAlreadyChanged()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocExchLinks: Codeunit "Doc. Exch. Links";
        DocRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 380826] Run UpdateDocument function with old RecRef if Service Cr. Memo Header record is modified

        // [GIVEN] Service Cr. Memo Header "SCNH"
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        ServiceCrMemoHeader.Insert();
        DocRecRef.GetTable(ServiceCrMemoHeader);

        // [GIVEN] "SCNH"."Your Reference" = "YR"
        ServiceCrMemoHeader."Your Reference" := LibraryUtility.GenerateGUID();
        ServiceCrMemoHeader.Modify();
        Commit();

        // [WHEN] Run UpdateDocumentRecord function for old "SCNH" RecordRef
        DocExchLinks.UpdateDocumentRecord(
          DocRecRef, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [THEN] "SCNH"."Document Exchange Status" set to "Sent to Document Exchange Service"
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.TestField(
          "Document Exchange Status", ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
    end;

    [Test]
    [HandlerFunctions('EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SendEmailPostedSalesInvoiceForCustomerWithSeveralDocumentLayouts()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummySalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        ReportID: Integer;
        CustomReportLayoutCode: Code[20];
        ReportUsage: Enum "Report Selection Usage";
        EmailAddress: array[2] of Text;
    begin
        // [FEATURE] [Email] [Customer] [Sales] [Invoice]
        // [SCENARIO 382296] Several "Send Email" dialogs, one per each customer document layout with different email addresses
        Initialize();
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::No, DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        ReportID := REPORT::"Standard Sales - Invoice";
        ReportUsage := ReportUsage::"S.Invoice";
        EmailAddress[1] := GenerateRandomEmailAddress();
        EmailAddress[2] := GenerateRandomEmailAddress();

        // [GIVEN] Custom report layout "X" with "Report ID" = 1306
        CustomReportLayoutCode := FindCustomReportLayout(ReportID);
        // [GIVEN] Customer with "E-Mail" = "sharik@microsoft.com" and four document layouts:
        CreateCustomerWithEmail(Customer);
        // [GIVEN] Document layout 1: "Usage" = "Invoice", "Report ID" = 1306, "Custom Layout" = "X", "Send To Email" = ""
        LibrarySales.CreateCustomerDocumentLayout(Customer."No.", ReportUsage, ReportID, CustomReportLayoutCode, '');
        // [GIVEN] Document layout 2: "Usage" = "Invoice", "Report ID" = 1306, "Custom Layout" = "X", "Send To Email" = "cheburashka@microsoft.com"
        LibrarySales.CreateCustomerDocumentLayout(Customer."No.", ReportUsage, ReportID, CustomReportLayoutCode, EmailAddress[1]);
        // [GIVEN] Document layout 3: "Usage" = "Invoice", "Report ID" = 1306, "Custom Layout" = "X", "Send To Email" = ""
        LibrarySales.CreateCustomerDocumentLayout(Customer."No.", ReportUsage, ReportID, CustomReportLayoutCode, '');
        // [GIVEN] Document layout 4: "Usage" = "Invoice", "Report ID" = 1306, "Custom Layout" = "X", "Send To Email" = "krokodil@microsoft.com"
        LibrarySales.CreateCustomerDocumentLayout(Customer."No.", ReportUsage, ReportID, CustomReportLayoutCode, EmailAddress[2]);

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreatePostSalesDoc(DummySalesHeader."Document Type"::Invoice, true, true, Customer."No."));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Email posted sales invoice
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        LibraryVariableStorage.Enqueue(EmailAddress[1]);
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        LibraryVariableStorage.Enqueue(EmailAddress[2]);
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        SalesInvoiceHeader.EmailRecords(true);

        // [THEN] There are four "Send Email" dialogs have been shown:
        // [THEN] The first one is with "To" = "sharik@microsoft.com"
        // [THEN] The second one is with "To" = "cheburashka@microsoft.com"
        // [THEN] The third one is with "To" = "sharik@microsoft.com"
        // [THEN] The fourth one is with "To" = "krokodil@microsoft.com"
        // Verify email address in EmailDialogHandlerNo
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForPostedSalesInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [UI] [Customer] [Sales] [Invoice]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected posted sales invoices for distinct customers
        Initialize();

        // [GIVEN] Select several posted sales invoices for distinct customers
        CreatePostSevSalesInvoicesDistinctCustomers(SalesInvoiceHeader);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        SalesInvoiceHeader.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForPostedSalesCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [UI] [Customer] [Sales] [Credit Memo]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected posted sales credit memos for distinct customers
        Initialize();

        // [GIVEN] Select several posted sales credit memos for distinct customers
        CreatePostSevSalesCrMemosDistinctCustomers(SalesCrMemoHeader);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        SalesCrMemoHeader.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForPostedServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [UI] [Customer] [Service] [Invoice]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected posted service invoices for distinct customers
        Initialize();

        // [GIVEN] Select several posted service invoices for distinct customers
        CreatePostSevServiceInvoicesDistinctCustomers(ServiceInvoiceHeader);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        ServiceInvoiceHeader.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForPostedServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [UI] [Customer] [Service] [Credit Memo]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected posted service credit memos for distinct customers
        Initialize();

        // [GIVEN] Select several posted service credit memos for distinct customers
        CreatePostSevServiceCrMemosDistinctCustomers(ServiceCrMemoHeader);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        ServiceCrMemoHeader.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForJobs()
    var
        Job: Record Job;
    begin
        // [FEATURE] [UI] [Customer] [Job]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected jobs for distinct customers
        Initialize();

        // [GIVEN] Select several jobs for distinct customers
        CreateSevJobsDistinctCustomers(Job);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        Job.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyAndCancelVendorProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ProfileSelectionMethodForPurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UI] [Vendor] [Purchase] [Order]
        // [SCENARIO 201308] Profile selection method dialog is shown for selected purchase orders for distinct vendors
        Initialize();

        // [GIVEN] Select several purchase orders for distinct vendors
        CreateSevPurchaseOrdersDistinctVendors(PurchaseHeader);

        // [WHEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(1); // dummy enqueue to test handler's calls count (dequeue in VerifyAndCancelProfileSelectionMethodStrMenuHandler)
        PurchaseHeader.SendRecords();

        // [THEN] Profile selection method dialog is shown once with 3 options:
        // [THEN] 1 - Confirm profile and use it for all selected documents
        // [THEN] 2 - Confirm profile per each document
        // [THEN] 3 (default) - Use default profile per each document without confimation
        // Verify in VerifyAndCancelProfileSelectionMethodStrMenuHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupProfileCustomerNotMultiselectionNotShowDialog()
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfile() returns customer's document profile wthout confirmation dialog in case of "Multiselection" = FALSE, "ShowDialog" = FALSE
        Initialize();

        // [GIVEN] Customer with document sending profile
        CreateFullDocumentSendingProfile(CustomerDocumentSendingProfile);
        CustomerNo := CreateCustomerWithDocumentProfile(CustomerDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookupProfile() with "Multiselection" = FALSE, "ShowDialog" = FALSE
        LookupDocumentSendingProfile.LookupProfile(CustomerNo, false, false);

        // [THEN] Customer's document sending profile has been returned without confirmation dialog
        VerifyDocumentProfilesAreIdentical(CustomerDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupProfileCustomerMultiselectionNotShowDialog()
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfile() returns customer's document profile wthout confirmation dialog in case of "Multiselection" = TRUE, "ShowDialog" = FALSE
        Initialize();

        // [GIVEN] Customer with document sending profile
        CreateFullDocumentSendingProfile(CustomerDocumentSendingProfile);
        CustomerNo := CreateCustomerWithDocumentProfile(CustomerDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookupProfile() with "Multiselection" = TRUE, "ShowDialog" = FALSE
        LookupDocumentSendingProfile.LookupProfile(CustomerNo, true, false);

        // [THEN] Customer's document sending profile has been returned without confirmation dialog
        VerifyDocumentProfilesAreIdentical(CustomerDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('VerifySelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure LookupProfileCustomerNotMultiselectionShowDialog()
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfile() shows "Select Sending Options" dialog with customer's document profile in case of "Multiselection" = FALSE, "ShowDialog" = TRUE
        Initialize();

        // [GIVEN] Customer with document sending profile
        CreateFullDocumentSendingProfile(CustomerDocumentSendingProfile);
        CustomerNo := CreateCustomerWithDocumentProfile(CustomerDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookupProfile() with "Multiselection" = FALSE, "ShowDialog" = TRUE
        LibraryVariableStorage.Enqueue(CustomerDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(false); // for VerifySelectSendingOptionHandler
        LookupDocumentSendingProfile.LookupProfile(CustomerNo, false, true);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's document profile and hidden electronic document field
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        VerifyDocumentProfilesAreIdentical(CustomerDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('VerifySelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure LookupProfileCustomerMultiselectionShowDialog()
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfile() shows "Select Sending Options" dialog with customer's document profile in case of "Multiselection" = TRUE, "ShowDialog" = TRUE
        Initialize();

        // [GIVEN] Customer with document sending profile
        CreateFullDocumentSendingProfile(CustomerDocumentSendingProfile);
        CustomerNo := CreateCustomerWithDocumentProfile(CustomerDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookupProfile() with "Multiselection" = TRUE, "ShowDialog" = TRUE
        LibraryVariableStorage.Enqueue(CustomerDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LookupDocumentSendingProfile.LookupProfile(CustomerNo, true, true);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's document profile and visible electronic document field
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        VerifyDocumentProfilesAreIdentical(CustomerDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupProfileVendorNotMultiselectionNotShowDialog()
    var
        VendorDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfileVendor() returns vendor's document profile wthout confirmation dialog in case of "Multiselection" = FALSE, "ShowDialog" = FALSE
        Initialize();

        // [GIVEN] Vendor with document sending profile
        CreateFullDocumentSendingProfile(VendorDocumentSendingProfile);
        VendorNo := CreateVendorWithDocumentProfile(VendorDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookUpProfileVendor() with "Multiselection" = FALSE, "ShowDialog" = FALSE
        LookupDocumentSendingProfile.LookUpProfileVendor(VendorNo, false, false);

        // [THEN] Vendor's document sending profile has been returned without confirmation dialog
        VerifyDocumentProfilesAreIdentical(VendorDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupProfileVendorMultiselectionNotShowDialog()
    var
        VendorDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfileVendor() returns vendor's document profile wthout confirmation dialog in case of "Multiselection" = TRUE, "ShowDialog" = FALSE
        Initialize();

        // [GIVEN] Vendor with document sending profile
        CreateFullDocumentSendingProfile(VendorDocumentSendingProfile);
        VendorNo := CreateVendorWithDocumentProfile(VendorDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookUpProfileVendor() with "Multiselection" = TRUE "ShowDialog" = FALSE
        LookupDocumentSendingProfile.LookUpProfileVendor(VendorNo, true, false);

        // [THEN] Vendor's document sending profile has been returned without confirmation dialog
        VerifyDocumentProfilesAreIdentical(VendorDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('VerifySelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure LookupProfileVendorNotMultiselectionShowDialog()
    var
        VendorDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfileVendor() shows "Select Sending Options" dialog with vendor's document profile in case of "Multiselection" = FALSE, "ShowDialog" = TRUE
        Initialize();

        // [GIVEN] Vendor with document sending profile
        CreateFullDocumentSendingProfile(VendorDocumentSendingProfile);
        VendorNo := CreateVendorWithDocumentProfile(VendorDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookUpProfileVendor() with "Multiselection" = FALSE, "ShowDialog" = TRUE
        LibraryVariableStorage.Enqueue(VendorDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(false); // for VerifySelectSendingOptionHandler
        LookupDocumentSendingProfile.LookUpProfileVendor(VendorNo, false, true);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's document profile and hidden electronic document field
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        VerifyDocumentProfilesAreIdentical(VendorDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('VerifySelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure LookupProfileVendorMultiselectionShowDialog()
    var
        VendorDocumentSendingProfile: Record "Document Sending Profile";
        LookupDocumentSendingProfile: Record "Document Sending Profile";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 201308] TAB 60 "Document Sending Profile".LookupProfileVendor() shows "Select Sending Options" dialog with vendor's document profile in case of "Multiselection" = TRUE, "ShowDialog" = TRUE
        Initialize();

        // [GIVEN] Vendor with document sending profile
        CreateFullDocumentSendingProfile(VendorDocumentSendingProfile);
        VendorNo := CreateVendorWithDocumentProfile(VendorDocumentSendingProfile.Code);

        // [WHEN] Perform TAB 60 "Document Sending Profile".LookUpProfileVendor() with "Multiselection" = FALSE, "ShowDialog" = TRUE
        LibraryVariableStorage.Enqueue(VendorDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LookupDocumentSendingProfile.LookUpProfileVendor(VendorNo, true, true);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's document profile and visible electronic document field
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        VerifyDocumentProfilesAreIdentical(VendorDocumentSendingProfile, LookupDocumentSendingProfile);
    end;

    [Test]
    [HandlerFunctions('ConfirmPerDocProfileSelectionMethodStrMenuHandler,VerifyAndCancelSelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure CustomerConfirmProfilePerDocAndCancelSending()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: array[2] of Record Customer;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Customer] [Sales] [Invoice]
        // [SCENARIO 201308] Profile selection method "Confirm profile per each document" with canceled sending for selected posted sales invoices for distinct customers
        Initialize();

        // [GIVEN] Customer "C1" with document seding profile "P1" (only print)
        // [GIVEN] Customer "C2" with document seding profile "P2" (only email)
        // [GIVEN] Select posted sales invoices for customers "C1", "C2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreatePostTwoSalesInvoicesDistinctCustomers(
          SalesInvoiceHeader, Customer, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(4); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(PrintDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(EmailDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        SalesInvoiceHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the second one option ("Confirm profile per each document")
        // Perform selection in ConfirmPerDocProfileSelectionMethodStrMenuHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's "C1" document profile "P1". Cancel sending.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's "C2" document profile "P2". Cancel sending.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmPerDocProfileSelectionMethodAndCloseEmailStrMenuHandler,VerifySelectSendingOptionHandler,PrintInvoiceHandler,EmailDialogHandlerNo')]
    [Scope('OnPrem')]
    procedure CustomerConfirmProfilePerDocAndSend()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: array[2] of Record Customer;
        DocumentSendingPostTests: Codeunit DocumentSendingPostTests;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Customer] [Sales] [Invoice]
        // [SCENARIO 201308] Profile selection method "Confirm profile per each document" for selected posted sales invoices for distinct customers
        Initialize();
        BindSubscription(DocumentSendingPostTests);

        // [GIVEN] Customer "C1" with email "petrushka@microsoft.com" and document seding profile "P1" (only print)
        // [GIVEN] Customer "C2" with email "gorbushka@microsoft.com" and document seding profile "P2" (only email)
        // [GIVEN] Select posted sales invoices: "D1" for customer "C1", "D2" for customer "C2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreatePostTwoSalesInvoicesDistinctCustomers(
          SalesInvoiceHeader, Customer, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(6); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(PrintDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(EmailDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(Customer[2]."E-Mail"); // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(DocumentNo[2]); // for EmailDialogHandlerNo
        SalesInvoiceHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the second one option ("Confirm profile per each document")
        // Perform selection in ConfirmPerDocProfileSelectionMethodStrMenuHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's "C1" document profile "P1". Confirm send.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] Sales invoice print report is shown and there is only "D1" document has been printed
        VerifyDocumentNosSalesInvoiceCreditMemoReportSingleCustomer(DocumentNo[1], DocumentNo[2]);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with customer's "C2" document profile "P2". Confirm send.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] Send Email Editor is shown for only "C2" customer with document "D2" and "Sent To" = "gorbushka@microsoft.com"
        // Verify in EmailDialogHandlerNo
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UseDefaultProfileSelectionMethodStrMenuAndCloseEmailHandler,PrintInvoiceHandler,EmailDialogHandlerNo')]
    [Scope('OnPrem')]
    procedure CustomerUseDefaultProfilePerDocAndSend()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: array[2] of Record Customer;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Customer] [Sales] [Invoice]
        // [SCENARIO 201308] Profile selection method "Use default profile per each document without confimation" for selected posted sales invoices for distinct customers
        Initialize();

        // [GIVEN] Customer "C1" with email "petrushka@microsoft.com" and document seding profile "P1" (only print)
        // [GIVEN] Customer "C2" with email "gorbushka@microsoft.com" and document seding profile "P2" (only email)
        // [GIVEN] Select posted sales invoices: "D1" for customer "C1", "D2" for customer "C2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreatePostTwoSalesInvoicesDistinctCustomers(
          SalesInvoiceHeader, Customer, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(2); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(Customer[2]."E-Mail"); // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(DocumentNo[2]); // for EmailDialogHandlerNo
        SalesInvoiceHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the third one option ("Use default profile per each document without confimation")
        // Perform selection in UseDefaultProfileSelectionMethodStrMenuHandler handler

        // [THEN] Sales invoice print report is shown and there is only "D1" document has been printed
        VerifyDocumentNosSalesInvoiceCreditMemoReportSingleCustomer(DocumentNo[1], DocumentNo[2]);

        // [THEN] Send Email Editor is shown for only "C2" customer with document "D2" and "Sent To" = "gorbushka@microsoft.com"
        // Verify in EmailDialogHandlerNo
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmPerDocProfileSelectionMethodStrMenuHandler,VerifyAndCancelSelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure VendorConfirmProfilePerDocAndCancelSending()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        PurchaseHeader: Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Vendor] [Purchase] [Order]
        // [SCENARIO 201308] Profile selection method "Confirm profile per each document" with canceled sending for selected purchase orders for distinct vendors
        Initialize();

        // [GIVEN] Vendor "V1" with document seding profile "P1" (only print)
        // [GIVEN] Vendor "V2" with document seding profile "P2" (only email)
        // [GIVEN] Select purchase orders for vendors "V1", "V2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreateTwoPurchaseOrdersDistinctVendors(PurchaseHeader, Vendor, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(4); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(PrintDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(EmailDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        PurchaseHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the second one option ("Confirm profile per each document")
        // Perform selection in ConfirmPerDocProfileSelectionMethodStrMenuHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's "V1" document profile "P1". Cancel sending.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's "V2" document profile "P2". Cancel sending.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmPerDocProfileSelectionMethodAndCloseEmailStrMenuHandler,VerifySelectSendingOptionHandler,PurchasePrintInvoiceHandler,EmailDialogHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorConfirmProfilePerDocAndSend()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        PurchaseHeader: Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Vendor] [Purchase] [Order]
        // [SCENARIO 201308] Profile selection method "Confirm profile per each document" for selected purchase orders for distinct vendors
        Initialize();

        // [GIVEN] Vendor "C1" with email "petrushka@microsoft.com" and document seding profile "P1" (only print)
        // [GIVEN] Vendor "C2" with email "gorbushka@microsoft.com" and document seding profile "P2" (only email)
        // [GIVEN] Select purchase orders: "D1" for vendor "V1", "D2" for vendor "V2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreateTwoPurchaseOrdersDistinctVendors(PurchaseHeader, Vendor, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(6); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(PrintDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(EmailDocumentSendingProfile); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(true); // for VerifySelectSendingOptionHandler
        LibraryVariableStorage.Enqueue(Vendor[2]."E-Mail"); // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(DocumentNo[2]); // for EmailDialogHandlerNo
        PurchaseHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the second one option ("Confirm profile per each document")
        // Perform selection in ConfirmPerDocProfileSelectionMethodStrMenuHandler handler

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's "V1" document profile "P1". Confirm send.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] Purchase invoice print report is shown and there is only "D1" document has been printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoPurchaseOrderHdrTxt, DocumentNo[1]);
        LibraryReportDataset.AssertElementWithValueNotExist(ReportNoPurchaseOrderHdrTxt, DocumentNo[2]);

        // [THEN] PAGE 364 "Select Sending Options" dialog is shown with vendor's "V2" document profile "P2". Confirm send.
        // Verify "Select Sending Options" dialog in VerifySelectSendingOptionHandler handler

        // [THEN] Send Email Editor is shown for only "V2" vendor with document "D2" and "Sent To" = "gorbushka@microsoft.com"
        // Verify in EmailDialogHandlerNo
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UseDefaultProfileSelectionMethodStrMenuAndCloseEmailHandler,PurchasePrintInvoiceHandler,EmailDialogHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorUseDefaultProfilePerDocAndSend()
    var
        PrintDocumentSendingProfile: Record "Document Sending Profile";
        EmailDocumentSendingProfile: Record "Document Sending Profile";
        PurchaseHeader: Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Vendor] [Purchase] [Order]
        // [SCENARIO 201308] Profile selection method "Use default profile per each document without confimation" for selected purchase orders for distinct vendors
        Initialize();

        // [GIVEN] Vendor "C1" with email "petrushka@microsoft.com" and document seding profile "P1" (only print)
        // [GIVEN] Vendor "C2" with email "gorbushka@microsoft.com" and document seding profile "P2" (only email)
        // [GIVEN] Select purchase orders: "D1" for vendor "V1", "D2" for vendor "V2"
        CreatePrintAndEmailDocumentSendingProfiles(PrintDocumentSendingProfile, EmailDocumentSendingProfile);
        CreateTwoPurchaseOrdersDistinctVendors(PurchaseHeader, Vendor, DocumentNo, PrintDocumentSendingProfile, EmailDocumentSendingProfile);

        // [GIVEN] Invoke "Send" action
        LibraryVariableStorage.Enqueue(2); // for assert calls count in UseDefaultProfileSelectionMethodStrMenuHandler
        LibraryVariableStorage.Enqueue(Vendor[2]."E-Mail"); // for EmailDialogHandlerNo
        LibraryVariableStorage.Enqueue(DocumentNo[2]); // for EmailDialogHandlerNo
        Commit();
        PurchaseHeader.SendRecords();

        // [GIVEN] Profile selection method dialog is shown
        // [WHEN] Choose the second one option ("Use default profile per each document without confimation")
        // Perform selection in UseDefaultProfileSelectionMethodStrMenuHandler handler

        // [THEN] Purchase order print report is shown and there is only "D1" document has been printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoPurchaseOrderHdrTxt, DocumentNo[1]);
        LibraryReportDataset.AssertElementWithValueNotExist(ReportNoPurchaseOrderHdrTxt, DocumentNo[2]);

        // [THEN] Send Email Editor is shown for only "V2" vendor with document "D2" and "Sent To" = "gorbushka@microsoft.com"
        // Verify in EmailDialogHandlerNo
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElectronicFormatUT()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FormatCode: Code[20];
        UsageOption: Option;
    begin
        // [FEATURE] [Electronic Document] [UT]
        // [SCENARIO] TAB 61 ElectronicDocumentFormat.InsertElectronicFormat() with different Usage options

        FormatCode := LibraryUtility.GenerateGUID();
        for UsageOption := ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger() to ElectronicDocumentFormat.Usage::"Job Quote".AsInteger() do begin
            ElectronicDocumentFormat.InsertElectronicFormat(FormatCode, '', 0, 0, UsageOption);
            ElectronicDocumentFormat.Get(FormatCode, UsageOption);
        end;

        ElectronicDocumentFormat.SetRange(Code, FormatCode);
        ElectronicDocumentFormat.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PurchaseQuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuote_PrintedWithSendActionButton()
    var
        PurchaseHeader: Record "Purchase Header";
        DummyReportSelections: Record "Report Selections";
    begin
        // [FEATURES] [UI] [Purchase] [Quote]
        // [SCENARIO 274511] Purchase Quote can be printed with Send button.
        Initialize();

        // [GIVEN] Report Selections for Purchase Quote and Report 404 "Purchase - Quote"
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Quote", REPORT::"Purchase - Quote");

        // [GIVEN] Vendor with Document Sending Profile for printer only version.
        // [GIVEN] Purchase Quote with assigned Vendor
        CreatePurchaseQuoteWithDocumentSendingProfile(PurchaseHeader);

        // [WHEN] Purchase Quote is send for printing with "Send" ActionButton with default profile options.
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] Purchase Quote is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchHeadNo', PurchaseHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintInvoiceHandler,EmailDialogHandlerNo,ConfirmDefaultProfileSelectionMethodStrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendingMultipleInvoicesToDifferentCustomersWithSpecialSymbols()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedDocumentVariant: Variant;
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 290802] Mutiple posted sales invoices for different customers with special symbols in "No." printed in a single document when customer report selection is not defined.
        Initialize();
        LibraryVariableStorage.AssertEmpty();

        // [GIVEN] Document sending profile
        InitializeDocumentSendingProfile(DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Invoice "Invoice[1]" for Customer "C[1]" with special symbol in "No." was created and posted
        CreateCustomerWithEmailWithCustomNo(Customer, GenerateGUIDWithSpecialSymbol());
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer, SalesHeader1."Document Type"::Invoice);
        SalesInvoiceHeader1 := PostedDocumentVariant;

        // [GIVEN] Invoice "Invoice[2]" for Customer "C[2]" with special symbol in "No." was created and posted
        CreateCustomerWithEmailWithCustomNo(Customer2, GenerateGUIDWithSpecialSymbol());
        CreateAndPostSalesHeaderAndLine(PostedDocumentVariant, Customer2, SalesHeader2."Document Type"::Invoice);
        SalesInvoiceHeader2 := PostedDocumentVariant;

        // Enqueue data for handlers to chose electronic document format
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader1."No.");
        LibraryVariableStorage.Enqueue(Customer2."E-Mail");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader2."No.");

        // [WHEN] When send posted "Invoice[1]" and "Invoice[2]" simultaneously
        SalesInvoiceHeader.SetFilter("No.", StrSubstNo('%1|%2', SalesInvoiceHeader1."No.", SalesInvoiceHeader2."No."));
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.SendRecords();

        // [THEN] Both invoices printed in a single document
        FileName := LibraryVariableStorage.DequeueText();
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesInvoiceHeader1."No.", FileName);
        VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(SalesInvoiceHeader2."No.", FileName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentSendingProfileDoesNotRunCheckForDiskPDF()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 358975] Post sales invoice with Document Sending Profile = Disk::PDF
        Initialize();

        // [GIVEN] Document Sending Profile for Disk::PDF has 'Disk Format' = PEPPOL
        CreateDocumentSendingProfileWithAllTrue(DocumentSendingProfile);
        DocumentSendingProfile.Validate("Disk Format", PeppolFormatNameTxt);
        DocumentSendingProfile.Modify(true);

        // [GIVEN] Sales Invoice for customer with the Document Sending Profile created above and no specific field filled in for PEPPOL
        LibrarySales.CreateSalesInvoice(SalesHeader);
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.Validate("Document Sending Profile", DocumentSendingProfile.Code);
        Customer.Modify(true);

        // [WHEN] Post the Sales Invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Sales Invoice is successfuly posted
        SalesInvoiceHeader.Get(InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0101()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = "b@b.com"
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = "d@d.com"
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = “e@e.com”
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "d@d.com" // system gets from Document Layout of Bill-to Customer

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[2]));

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[2]));

        SellToEmail := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(SellToEmail));

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, '', PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, DocumentLayoutEmail[2], AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0102()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = "b@b.com"
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = “e@e.com”
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "e@e.com" // system gets Sales Document."Sell-to E-Mail"

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[2]));

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := '';

        SellToEmail := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(SellToEmail));

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, SellToEmail, AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0103()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = “e@e.com”
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "e@e.com" // system gets Sales Document."Sell-to E-Mail"

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := '';

        SellToEmail := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(SellToEmail));

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, SellToEmail, AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0104()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = “e@e.com”
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "e@e.com" // system gets Sales Document."Sell-to E-Mail"

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := '';
        DocumentLayoutEmail[2] := '';

        SellToEmail := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(SellToEmail));

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, SellToEmail, AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0105()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = <blank>
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = “e@e.com”
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "e@e.com" // system gets Sales Document."Sell-to E-Mail"

        Initialize();

        EmailAddressCustomer[1] := '';
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := '';
        DocumentLayoutEmail[2] := '';

        SellToEmail := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(SellToEmail));

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, SellToEmail, AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0106()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = <blank>
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = <blank>
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = <blank> // system gets Sales Document."Sell-to E-Mail"

        Initialize();

        EmailAddressCustomer[1] := '';
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := '';
        DocumentLayoutEmail[2] := '';

        SellToEmail := '';

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, SellToEmail, AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0201()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = "b@b.com"
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = "d@d.com"
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = <blank>
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "d@d.com"

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[2]));

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[2]));

        SellToEmail := '';

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, '', PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, DocumentLayoutEmail[2], AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0202()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = "b@b.com"
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = <blank>
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = "b@b.com"

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[2]));

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := '';

        SellToEmail := '';

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, EmailAddressCustomer[2], AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0203()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = "c@c.com"
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = <blank>
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = <blank>

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(DocumentLayoutEmail[1]));
        DocumentLayoutEmail[2] := '';

        SellToEmail := '';

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, '', AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VerifySelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesPostedInvoiceSendToEmailSellToBillToDifferentCustomer_0204()
    var
        EmailAddressCustomer: array[2] of Text[80];
        DocumentLayoutEmail: array[2] of Text[80];
        PostedInvoiceNo: Code[20];
        DocumentSendingProfileEmail: Record "Document Sending Profile";
        AttachmentName: Text;
        SellToEmail: Text[80];
    begin
        // [SCENARIO 423995] Send email for sales document with different Sell-to and Bill-to customers.

        // [GIVEN] Customer[1]."E-Mail" = "a@a.com"
        // [GIVEN] Customer[2]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-1]."E-Mail" = <blank>
        // [GIVEN] "Document Layout"[Customer-2]."E-Mail" = <blank>
        // [GIVEN] Posted Sales Order where "Sell-to Customer" = Customer[1], "Bill-to Customer" = Customer[2]
        // [GIVEN] “Sell-to Email” = <blank>
        // [WHEN] Send Email for posted sales invoice
        // [THEN] Target Email Address = <blank>

        Initialize();

        EmailAddressCustomer[1] := CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(EmailAddressCustomer[1]));
        EmailAddressCustomer[2] := '';

        DocumentLayoutEmail[1] := '';
        DocumentLayoutEmail[2] := '';

        SellToEmail := '';

        Scenario_423995(EmailAddressCustomer, DocumentLayoutEmail, SellToEmail, PostedInvoiceNo, DocumentSendingProfileEmail, AttachmentName);

        Scenario_423995_Verify(PostedInvoiceNo, DocumentSendingProfileEmail, '', AttachmentName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestCustomEmailForPostedSalesShipments()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesShipments: TestPage "Posted Sales Shipments";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify custom email must be sent for Posted Sales Shipments.
        Initialize();

        // [GIVEN] Create Customer with email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Sales Order.
        CreateAndPostSalesOrderWithShipment(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Order);
        SalesShipmentHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipment.
        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        PostedSalesShipment.SendCustom.Invoke();
        PostedSalesShipment.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipments list.
        PostedSalesShipments.OpenView();
        PostedSalesShipments.GotoRecord(SalesShipmentHeader);
        PostedSalesShipments.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintSalesShipmentHandler')]
    procedure TestPrintPostedSalesShipments()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipments: TestPage "Posted Sales Shipments";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify Posted Sales Shipment can be printed with Send action button.
        Initialize();

        // [GIVEN] Create Customer with email.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create and Post Sales Order.
        CreateAndPostSalesOrderWithShipment(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Order);
        SalesShipmentHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Printer with PDF & Electronic Document.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
            DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
            DocumentSendingProfile."E-Mail"::No);

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [WHEN] Invoke Send action on Posted Sales Shipments list.
        PostedSalesShipments.OpenView();
        PostedSalesShipments.GotoRecord(SalesShipmentHeader);
        PostedSalesShipments.SendCustom.Invoke();

        // [THEN] Verify Posted Sales Shipment is printed.
        LibraryReportDataset.LoadDataSetFile();
        AssertValidSalesShipmentNo(SalesShipmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestEmailPostedSalesShipments()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesShipments: TestPage "Posted Sales Shipments";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify Posted Sales Shipment can be printed with Send action button.
        Initialize();

        // [GIVEN] Create Customer with email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Sales Order.
        CreateAndPostSalesOrderWithShipment(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Order);
        SalesShipmentHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipment.
        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        PostedSalesShipment.SendCustom.Invoke();
        PostedSalesShipment.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipments list.
        PostedSalesShipments.OpenView();
        PostedSalesShipments.GotoRecord(SalesShipmentHeader);
        PostedSalesShipments.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestCustomEmailPostedSalesShipment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesShipments: TestPage "Posted Sales Shipments";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify custom email must be sent for Posted Sales Shipment.
        Initialize();

        // [GIVEN] Create Customer with Email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Sales Order.
        CreateAndPostSalesOrderWithShipment(PostedDocumentVariant, Customer, SalesHeader."Document Type"::Order);
        SalesShipmentHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipment.
        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        PostedSalesShipment.SendCustom.Invoke();
        PostedSalesShipment.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Sales Shipment No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");

        // [WHEN] Invoke Send action on Posted Sales Shipments list.
        PostedSalesShipments.OpenView();
        PostedSalesShipments.GotoRecord(SalesShipmentHeader);
        PostedSalesShipments.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Sales Shipment No.
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestCustomEmailForPostedReturnReceipt()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        PostedReturnReceipts: TestPage "Posted Return Receipts";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify custom email must be sent for Posted Return Receipts.
        Initialize();

        // [GIVEN] Create Customer with email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Return Order.
        CreateAndPostReturnOrderWithReceiving(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Return Order");
        ReturnReceiptHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipt.
        PostedReturnReceipt.OpenEdit();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipt.SendCustom.Invoke();
        PostedReturnReceipt.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipts list.
        PostedReturnReceipts.OpenView();
        PostedReturnReceipts.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipts.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,PrintSalesReturnReceiptHandler')]
    procedure TestPrintPostedReturnReceipts()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipts: TestPage "Posted Return Receipts";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify Posted Return Receipt can be printed with Send action button.
        Initialize();

        // [GIVEN] Select "Sales - Return Receipt" report in report selections for Sales Return Receipt.
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Ret.Rcpt.", Report::"Sales - Return Receipt");

        // [GIVEN] Create Customer with email.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create and Post Return Order.
        CreateAndPostReturnOrderWithReceiving(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Return Order");
        ReturnReceiptHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Printer with PDF & Electronic Document.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::"PDF & Electronic Document",
            DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
            DocumentSendingProfile."E-Mail"::No);

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [WHEN] Invoke Send action on Posted Return Receipts list.
        PostedReturnReceipts.OpenView();
        PostedReturnReceipts.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipts.SendCustom.Invoke();

        // [THEN] Verify Posted Return Receipt is printed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNo_ReturnRcptHeaderTxt, ReturnReceiptHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestEmailPostedReturnReceipts()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        PostedReturnReceipts: TestPage "Posted Return Receipts";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify Posted Return Receipt can be printed with Send action button.
        Initialize();

        // [GIVEN] Create Customer with email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Return Order.
        CreateAndPostReturnOrderWithReceiving(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Return Order");
        ReturnReceiptHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipt.
        PostedReturnReceipt.OpenEdit();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipt.SendCustom.Invoke();
        PostedReturnReceipt.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipts list.
        PostedReturnReceipts.OpenView();
        PostedReturnReceipts.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipts.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailDialogHandlerNo,CloseEmailEditorHandler')]
    procedure TestCustomEmailPostedReturnReceipt()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        PostedReturnReceipts: TestPage "Posted Return Receipts";
        PostedDocumentVariant: Variant;
    begin
        // [SCENARIO 425426] Verify custom email must be sent for Posted Return Receipt.
        Initialize();

        // [GIVEN] Create Customer with Email.
        CreateCustomerWithEmail(Customer);

        // [GIVEN] Create and Post Return Order.
        CreateAndPostReturnOrderWithReceiving(PostedDocumentVariant, Customer, SalesHeader."Document Type"::"Return Order");
        ReturnReceiptHeader := PostedDocumentVariant;

        // [GIVEN] Initialize Document Sending Profile for Email with PDF attachment.
        InitializeDocumentSendingProfile(
            DocumentSendingProfile,
            DocumentSendingProfile."E-Mail Attachment"::PDF,
            DocumentSendingProfile.Printer::No,
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipt.
        PostedReturnReceipt.OpenEdit();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipt.SendCustom.Invoke();
        PostedReturnReceipt.Close();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.

        // [GIVEN] Enqueue Document Sending Profile for SelectSendingOptionHandler.
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        // [GIVEN] Enqueue Customer email and Return Receipt No. for EmailDialogHandlerNo.
        LibraryVariableStorage.Enqueue(Customer."E-Mail");
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");

        // [WHEN] Invoke Send action on Posted Return Receipts list.
        PostedReturnReceipts.OpenView();
        PostedReturnReceipts.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipts.SendCustom.Invoke();

        // [THEN] Verify Email Editor is opened with correct email address and Return Receipt No.
    end;

    local procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
        SalesHeader: Record "Sales Header";
        LibraryEmail: Codeunit "Library - Email";
    begin
        LibraryEmail.SetUpEmailAccount();
        LibraryTestInitialize.OnTestInitialize(Codeunit::DocumentSendingPostTests);

        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::DocumentSendingPostTests);

        SetupInvoiceReportLayoutSelection();

        LibraryERMCountryData.SetupReportSelections();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryApplicationArea.EnableEssentialSetup();
        InsertElectronicFormat();

        CompanyInfo.Get();
        CompanyInfo.Validate(Name, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInfo.Validate("Bank Branch No.", '1234');
        CompanyInfo.Validate(GLN, '1234567890128');
        CompanyInfo.Modify(true);

        LibraryERMCountryData.CompanyInfoSetVATRegistrationNo();

        ConfigureVATPostingSetup();

        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Rename(LibraryUtility.GenerateRandomText(2));
        CountryRegion."ISO Code" := Format(LibraryRandom.RandIntInRange(10, 99));
        CountryRegion.Modify();

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::DocumentSendingPostTests);
    end;

    local procedure Scenario_423995(EmailAddressCustomer: array[2] of Text[80]; DocumentLayoutEmail: array[2] of Text[80]; SellToEmail: Text[80]; var PostedInvoiceNo: Code[20]; var DocumentSendingProfileEmail: Record "Document Sending Profile"; var AttachmentName: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: array[2] of Record Customer;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ReportSelectionUsage: Enum "Report Selection Usage";
        CustomReportLayoutCode: Code[20];
        ReportID: Integer;
        Index: Integer;
    begin
        InitializeDocumentSendingProfile(DocumentSendingProfileEmail, DocumentSendingProfileEmail."E-Mail Attachment"::PDF,
            DocumentSendingProfileEmail.Printer::No, DocumentSendingProfileEmail."E-Mail"::"Yes (Prompt for Settings)");

        ReportID := REPORT::"Standard Sales - Invoice";
        ReportSelectionUsage := ReportSelectionUsage::"S.Invoice";
        CustomReportLayoutCode := FindCustomReportLayout(ReportID);

        for Index := 1 to ArrayLen(Customer) do begin
            LibrarySales.CreateCustomer(Customer[Index]);
            Customer[Index].Validate("E-Mail", EmailAddressCustomer[Index]);
            Customer[Index].Modify(true);
        end;

        LibrarySales.CreateCustomerDocumentLayout(
            Customer[1]."No.", ReportSelectionUsage, ReportID, CustomReportLayoutCode, DocumentLayoutEmail[1]);
        LibrarySales.CreateCustomerDocumentLayout(
            Customer[2]."No.", ReportSelectionUsage, ReportID, CustomReportLayoutCode, DocumentLayoutEmail[2]);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer[1]."No.");
        SalesHeader.Validate("Bill-to Customer No.", Customer[2]."No.");
        SalesHeader.Validate("Sell-to E-Mail", SellToEmail);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);

        AttachmentName := NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date", true);

        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure Scenario_423995_Verify(PostedInvoiceNo: Code[20]; DocumentSendingProfileEmail: Record "Document Sending Profile"; ExpectedTargetEmail: Text[80]; ExpectedAttachmentName: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();

        LibraryVariableStorage.Enqueue(DocumentSendingProfileEmail);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(ExpectedTargetEmail);
        LibraryVariableStorage.Enqueue(ExpectedAttachmentName);

        SalesInvoiceHeader.SendRecords();
    end;

    local procedure SetupInvoiceReportLayoutSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.DeleteAll();
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Sales - Invoice";
        ReportLayoutSelection.Insert();

        ReportLayoutSelection."Report ID" := REPORT::"Standard Sales - Credit Memo";
        ReportLayoutSelection.Insert();
    end;

    local procedure InitializeDocumentSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile"; EmailAttachmentType: Enum "Document Sending Profile Attachment Type"; Printer: Option; Email: Option)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        DeleteDefaultDocumentSendingProfile(DocumentSendingProfile);
        DocumentSendingProfile.Validate(Printer, Printer);
        DocumentSendingProfile.Validate("E-Mail", Email);
        DocumentSendingProfile.Validate("E-Mail Attachment", EmailAttachmentType);
        ElectronicDocumentFormat.FindFirst();
        DocumentSendingProfile.Validate("E-Mail Format", ElectronicDocumentFormat.Code);
        DocumentSendingProfile.Insert(true);
    end;

    local procedure InitializeTwoDocumentSendingProfilesForCustomer(var CustomerSpecificDocumentSendingProfile: Record "Document Sending Profile")
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        InitializeDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile."E-Mail Attachment"::PDF,
          DefaultDocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DefaultDocumentSendingProfile."E-Mail"::No);

        CustomerSpecificDocumentSendingProfile.Init();
        CustomerSpecificDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        CustomerSpecificDocumentSendingProfile.Printer := CustomerSpecificDocumentSendingProfile.Printer::"Yes (Prompt for Settings)";
        CustomerSpecificDocumentSendingProfile."E-Mail" := CustomerSpecificDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)";
        CustomerSpecificDocumentSendingProfile."E-Mail Attachment" :=
          CustomerSpecificDocumentSendingProfile."E-Mail Attachment"::"Electronic Document";
        ElectronicDocumentFormat.FindFirst();
        CustomerSpecificDocumentSendingProfile."E-Mail Format" := ElectronicDocumentFormat.Code;
        CustomerSpecificDocumentSendingProfile.Default := false;
        CustomerSpecificDocumentSendingProfile.Insert(true);
    end;

    local procedure CreatePrintAndEmailDocumentSendingProfiles(var PrintDocumentSendingProfile: Record "Document Sending Profile"; var EmailDocumentSendingProfile: Record "Document Sending Profile")
    begin
        PrintDocumentSendingProfile.DeleteAll();
        PrintDocumentSendingProfile.Init();
        PrintDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        PrintDocumentSendingProfile.Default := true;
        PrintDocumentSendingProfile.Validate(Printer, PrintDocumentSendingProfile.Printer::"Yes (Prompt for Settings)");
        PrintDocumentSendingProfile.Insert(true);

        EmailDocumentSendingProfile.Init();
        EmailDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        EmailDocumentSendingProfile.Default := true;
        EmailDocumentSendingProfile.Validate("E-Mail", EmailDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        EmailDocumentSendingProfile.Insert(true);
    end;

    local procedure CreateTwoDocumentSendingProfiles(var DefaultDocumentSendingProfile: Record "Document Sending Profile"; var NonDefaultDocumentSendingProfile: Record "Document Sending Profile")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        DefaultDocumentSendingProfile.DeleteAll();
        DefaultDocumentSendingProfile.Init();
        DefaultDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DefaultDocumentSendingProfile.Default := true;
        DefaultDocumentSendingProfile.Validate(Printer, DefaultDocumentSendingProfile.Printer::"Yes (Use Default Settings)");
        DefaultDocumentSendingProfile.Validate("E-Mail", DefaultDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        DefaultDocumentSendingProfile.Validate("E-Mail Attachment", DefaultDocumentSendingProfile."E-Mail Attachment"::PDF);
        DefaultDocumentSendingProfile.Insert(true);

        NonDefaultDocumentSendingProfile.Init();
        NonDefaultDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        NonDefaultDocumentSendingProfile.Default := false;
        ElectronicDocumentFormat.FindLast();
        NonDefaultDocumentSendingProfile.Validate(
          "Electronic Document", NonDefaultDocumentSendingProfile."Electronic Document"::"Through Document Exchange Service");
        NonDefaultDocumentSendingProfile.Validate("Electronic Format", ElectronicDocumentFormat.Code);
        NonDefaultDocumentSendingProfile.Validate(Disk, NonDefaultDocumentSendingProfile.Disk::PDF);
        NonDefaultDocumentSendingProfile.Insert(true);
    end;

    local procedure CreateDocumentSendingProfileWithAllTrue(var DefaultDocumentSendingProfile: Record "Document Sending Profile")
    begin
        DefaultDocumentSendingProfile.DeleteAll();
        DefaultDocumentSendingProfile.Init();
        DefaultDocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DefaultDocumentSendingProfile.Default := true;
        DefaultDocumentSendingProfile.Validate(Printer, DefaultDocumentSendingProfile.Printer::"Yes (Use Default Settings)");
        DefaultDocumentSendingProfile.Validate("E-Mail", DefaultDocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)");
        DefaultDocumentSendingProfile.Validate("E-Mail Attachment", DefaultDocumentSendingProfile."E-Mail Attachment"::PDF);
        DefaultDocumentSendingProfile.Validate(Disk, DefaultDocumentSendingProfile.Disk::PDF);
        DefaultDocumentSendingProfile.Insert(true);
    end;

    local procedure CreateFullDocumentSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        InitializeDocumentSendingProfile(
              DocumentSendingProfile, DocumentSendingProfile."E-Mail Attachment"::"Electronic Document",
              DocumentSendingProfile.Printer::"Yes (Prompt for Settings)", DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
    end;

    local procedure CreateElectronicDocumentCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        SetupCustomerForElectronicDocument(Customer);
    end;

    local procedure CreateCustomerWithEmail(var Customer: Record Customer)
    begin
        CreateElectronicDocumentCustomer(Customer);
        Customer.Validate("E-Mail", CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(Customer."E-Mail")));
        Customer.Modify();
    end;

    local procedure CreateCustomerWithEmailWithCustomNo(var Customer: Record Customer; CustomerNo: Code[20])
    begin
        CreateCustomerWithEmail(Customer);
        Customer.Delete();
        Customer."No." := CustomerNo;
        Customer.Insert(true);
    end;

    local procedure CreateCustomerWithDocumentProfile(DocumentSendingProfileCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(Customer."E-Mail")));
        Customer.Validate("Document Sending Profile", DocumentSendingProfileCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithDocumentProfile(DocumentSendingProfileCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("E-Mail", CopyStr(GenerateRandomEmailAddress(), 1, MaxStrLen(Vendor."E-Mail")));
        Vendor.Validate("Document Sending Profile", DocumentSendingProfileCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostSalesHeaderAndLine(var PostedDocumentVariant: Variant; var Customer: Record Customer; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesPost.GetPostedDocumentRecord(SalesHeader, PostedDocumentVariant);
    end;

    local procedure CreatePurchaseQuoteWithDocumentSendingProfile(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        InitializeDocumentSendingProfile(
          DocumentSendingProfile,
          DocumentSendingProfile."E-Mail Attachment"::PDF,
          DocumentSendingProfile.Printer::"Yes (Prompt for Settings)",
          DocumentSendingProfile."E-Mail"::No);
        LibraryVariableStorage.Enqueue(DocumentSendingProfile);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote,
          LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), '', 0D);
        PurchaseHeader.SetRecFilter();
    end;

    local procedure CreatePostSalesDoc(DocumentType: Enum "Sales Document Type"; Ship: Boolean; Invoice: Boolean; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure CreatePostSevSalesInvoices(var SalesInvoiceHeader: Record "Sales Invoice Header"; "Count": Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to Count do begin
            SalesInvoiceHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, true, true, CustomerNo));
            SalesInvoiceHeader.Mark(true);
        end;
        SalesInvoiceHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevSalesInvoicesDistinctCustomers(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            SalesInvoiceHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, true, true, LibrarySales.CreateCustomerNo()));
            SalesInvoiceHeader.Mark(true);
        end;
        SalesInvoiceHeader.MarkedOnly(true);
    end;

    local procedure CreatePostTwoSalesInvoicesDistinctCustomers(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Customer: array[2] of Record Customer; var DocumentNo: array[2] of Code[20]; FirstDocumentSendingProfile: Record "Document Sending Profile"; SecondDocumentSendingProfile: Record "Document Sending Profile")
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        Customer[1].Get(CreateCustomerWithDocumentProfile(FirstDocumentSendingProfile.Code));
        Customer[2].Get(CreateCustomerWithDocumentProfile(SecondDocumentSendingProfile.Code));
        for i := 1 to ArrayLen(Customer) do begin
            DocumentNo[i] := CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, true, true, Customer[i]."No.");
            SalesInvoiceHeader.Get(DocumentNo[i]);
            SalesInvoiceHeader.Mark(true);
        end;
        SalesInvoiceHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevSalesCrMemos(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; "Count": Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to Count do begin
            SalesCrMemoHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::"Credit Memo", true, true, CustomerNo));
            SalesCrMemoHeader.Mark(true);
        end;
        SalesCrMemoHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevSalesCrMemosDistinctCustomers(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            SalesCrMemoHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::"Credit Memo", true, true, LibrarySales.CreateCustomerNo()));
            SalesCrMemoHeader.Mark(true);
        end;
        SalesCrMemoHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevSalesShipments(var SalesShipmentHeader: Record "Sales Shipment Header"; "Count": Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to Count do begin
            SalesShipmentHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::Order, true, false, CustomerNo));
            SalesShipmentHeader.Mark(true);
        end;
        SalesShipmentHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevReturnReceipts(var ReturnReceiptHeader: Record "Return Receipt Header"; "Count": Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to Count do begin
            ReturnReceiptHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::"Return Order", true, false, CustomerNo));
            ReturnReceiptHeader.Mark(true);
        end;
        ReturnReceiptHeader.MarkedOnly(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
    begin
        CreateCustomerWithEmail(Customer);
        CreateServiceHeaderWithCustomer(ServiceHeader, DocumentType, Customer."No.");
    end;

    local procedure CreateServiceHeaderWithCustomer(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader."Due Date" := WorkDate();
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
    end;

    local procedure CreatePostServiceDoc(DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreatePostServiceInvoice(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", CreatePostServiceDoc(ServiceHeader."Document Type"::Invoice, CustomerNo));
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreatePostServiceCrMemo(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", CreatePostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", CustomerNo));
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure CreatePostSevServiceInvoicesDistinctCustomers(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            ServiceInvoiceHeader.Get(CreatePostServiceInvoice(LibrarySales.CreateCustomerNo()));
            ServiceInvoiceHeader.Mark(true);
        end;
        ServiceInvoiceHeader.MarkedOnly(true);
    end;

    local procedure CreatePostSevServiceCrMemosDistinctCustomers(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            ServiceCrMemoHeader.Get(CreatePostServiceCrMemo(LibrarySales.CreateCustomerNo()));
            ServiceCrMemoHeader.Mark(true);
        end;
        ServiceCrMemoHeader.MarkedOnly(true);
    end;

    local procedure CreateSevJobsDistinctCustomers(var SelectedJob: Record Job)
    var
        Job: Record Job;
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryJob.CreateJob(Job);
            SelectedJob.Get(Job.RecordId);
            SelectedJob.Mark(true);
        end;
        SelectedJob.MarkedOnly(true);
    end;

    local procedure CreateSevPurchaseOrdersDistinctVendors(var SelectedPurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
            SelectedPurchaseHeader.Get(PurchaseHeader.RecordId);
            SelectedPurchaseHeader.Mark(true);
        end;
        SelectedPurchaseHeader.MarkedOnly(true);
    end;

    local procedure CreateTwoPurchaseOrdersDistinctVendors(var SelectedPurchaseHeader: Record "Purchase Header"; var Vendor: array[2] of Record Vendor; var DocumentNo: array[2] of Code[20]; FirstDocumentSendingProfile: Record "Document Sending Profile"; SecondDocumentSendingProfile: Record "Document Sending Profile")
    var
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
    begin
        Vendor[1].Get(CreateVendorWithDocumentProfile(FirstDocumentSendingProfile.Code));
        Vendor[2].Get(CreateVendorWithDocumentProfile(SecondDocumentSendingProfile.Code));
        for i := 1 to ArrayLen(Vendor) do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor[i]."No.");
            DocumentNo[i] := PurchaseHeader."No.";
            SelectedPurchaseHeader.Get(PurchaseHeader.RecordId);
            SelectedPurchaseHeader.Mark(true);
        end;
        SelectedPurchaseHeader.MarkedOnly(true);
    end;

    local procedure GenerateRandomEmailAddress(): Text
    begin
        exit(LibraryUtility.GenerateGUID() + '@microsoft.com');
    end;

    local procedure FindCustomReportLayout(ReportID: Integer): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        CustomReportLayout.SetRange("Report ID", ReportID);
        if not CustomReportLayout.FindFirst() then begin
            ReportLayoutList.SetRange("Report ID", ReportID);
            ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
            ReportLayoutList.FindFirst();

            TempBlob.CreateOutStream(OutStr);
            ReportLayoutList.Layout.ExportStream(OutStr);
            TempBlob.CreateInStream(InStr);

            CustomReportLayout.Init();
            CustomReportLayout."Report ID" := ReportID;
            CustomReportLayout.Code := CopyStr(StrSubstNo('MS-X%1', Random(9999)), 1, 10);
            CustomReportLayout."File Extension" := 'docx';
            CustomReportLayout.Description := 'Test report layout';
            CustomReportLayout.Type := CustomReportLayout.Type::Word;
            CustomReportLayout.Layout.CreateOutStream(OutStr);

            CopyStream(OutStr, InStr);

            CustomReportLayout.Insert();
        end;
        exit(CustomReportLayout.Code);
    end;

    local procedure UnsupportedDocumentType(DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post and Send", SalesHeader);
        Assert.ExpectedError(StrSubstNo(NotSupportedDocumentTypeErr, SalesHeader."Document Type"));
    end;

    local procedure EnqueueValuesForEmailDialog(DocName: Text; DocNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(StrSubstNo(EmailSubjectCapTxt, CompanyInformation.Name, DocName, DocNo));
        LibraryVariableStorage.Enqueue(StrSubstNo(ReportAsPdfFileNameMsg, DocName, DocNo));
    end;

    local procedure GenerateGUIDWithSpecialSymbol(): Code[20]
    begin
        exit(LibraryUtility.GenerateGUID() + '&');
    end;

    local procedure SetupCustomerForElectronicDocument(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.FindFirst();

        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Post Code"), DATABASE::Customer));
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Customer.Validate(GLN, '1234567890128');
        Customer.Modify(true);
    end;

    local procedure VerifySetupUnchanged(var DocumentSendingProfileBefore: Record "Document Sending Profile"; DocumentSendingProfileAfter: Record "Document Sending Profile")
    begin
        Assert.AreEqual(DocumentSendingProfileBefore.Default, DocumentSendingProfileAfter.Default, DocumentSendingProfileChangedErr);
        Assert.AreEqual(DocumentSendingProfileBefore.Printer, DocumentSendingProfileAfter.Printer, DocumentSendingProfileChangedErr);
        Assert.AreEqual(DocumentSendingProfileBefore."E-Mail", DocumentSendingProfileAfter."E-Mail", DocumentSendingProfileChangedErr);
        Assert.AreEqual(
          DocumentSendingProfileBefore."E-Mail Attachment", DocumentSendingProfileAfter."E-Mail Attachment",
          DocumentSendingProfileChangedErr);
        Assert.AreEqual(
          DocumentSendingProfileBefore.Disk, DocumentSendingProfileAfter.Disk,
          DocumentSendingProfileChangedErr);
        Assert.AreEqual(
          DocumentSendingProfileBefore."Disk Format", DocumentSendingProfileAfter."Disk Format",
          DocumentSendingProfileChangedErr);
        Assert.AreEqual(
          DocumentSendingProfileBefore."Electronic Document",
          DocumentSendingProfileAfter."Electronic Document",
          DocumentSendingProfileChangedErr);
        Assert.AreEqual(
          DocumentSendingProfileBefore."Electronic Format",
          DocumentSendingProfileAfter."Electronic Format",
          DocumentSendingProfileChangedErr);
    end;

    local procedure InsertElectronicFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CountryRegion: Record "Country/Region";
    begin
        ElectronicDocumentFormat.DeleteAll();
        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0", 0,
          ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0", 0,
          ElectronicDocumentFormat.Usage::"Sales Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"Exp. Serv.Inv. PEPPOL BIS3.0", 0,
          ElectronicDocumentFormat.Usage::"Service Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"Exp. Serv.CrM. PEPPOL BIS3.0", 0,
          ElectronicDocumentFormat.Usage::"Service Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"PEPPOL Validation", 0,
          ElectronicDocumentFormat.Usage::"Sales Validation".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PeppolFormatNameTxt, PeppolFormatNameTxt, CODEUNIT::"PEPPOL Service Validation", 0,
          ElectronicDocumentFormat.Usage::"Service Validation".AsInteger());

        CountryRegion.SetRange("VAT Scheme", '');
        if CountryRegion.FindSet() then
            repeat
                CountryRegion."VAT Scheme" := CountryRegion.Code;
                CountryRegion.Modify();
            until CountryRegion.Next() = 0;
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure AssertValidServiceHeaderNo(ExpectedValue: Text)
    begin
        case true of
            LibraryReportDataset.SearchForElementByValue(ReportNoServiceCrMemoHdrTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            LibraryReportDataset.SearchForElementByValue(ES_ReportNoServiceCrMemoHdrTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            LibraryReportDataset.SearchForElementByValue(IT_ReportNoServiceCrMemoHdrTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            LibraryReportDataset.SearchForElementByValue(NA_ReportNoServiceCrMemoHdrTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            else
                Assert.IsTrue(false, StrSubstNo(ElementNameErr, ExpectedValue));
        end;
    end;

    local procedure AssertValidServiceInvoiceHeaderNo(ExpectedValue: Text)
    begin
        LibraryReportDataset.AssertElementWithValueExists(ReportNoServiceInvHdrTxt, ExpectedValue);
    end;

    local procedure DeleteDefaultDocumentSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        DocumentSendingProfile.SetRange(Default, true);
        if DocumentSendingProfile.FindFirst() then begin
            DocumentSendingProfile.Delete();
            Clear(DocumentSendingProfile);
        end else
            DocumentSendingProfile.Init();

        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Default := true;
    end;

    local procedure UpdateYourReferenceSalesHeader(var SalesHeader: Record "Sales Header"; YourReference: Text[35])
    begin
        SalesHeader."Your Reference" := YourReference;
        SalesHeader.Modify();
    end;

    local procedure VerifyDocumentProfilesAreIdentical(ExpectedDocumentSendingProfile: Record "Document Sending Profile"; ActualDocumentSendingProfile: Record "Document Sending Profile")
    begin
        Assert.AreEqual(ExpectedDocumentSendingProfile.Printer, ActualDocumentSendingProfile.Printer, ExpectedDocumentSendingProfile.FieldCaption(Printer));
        Assert.AreEqual(ExpectedDocumentSendingProfile.Disk, ActualDocumentSendingProfile.Disk, ExpectedDocumentSendingProfile.FieldCaption(Disk));
        Assert.AreEqual(ExpectedDocumentSendingProfile."Disk Format", ActualDocumentSendingProfile."Disk Format", ExpectedDocumentSendingProfile.FieldCaption("Disk Format"));
        Assert.AreEqual(ExpectedDocumentSendingProfile."E-Mail", ActualDocumentSendingProfile."E-Mail", ExpectedDocumentSendingProfile.FieldCaption("E-Mail"));
        Assert.AreEqual(ExpectedDocumentSendingProfile."E-Mail Format", ActualDocumentSendingProfile."E-Mail Format", ExpectedDocumentSendingProfile.FieldCaption("E-Mail Format"));
        Assert.AreEqual(ExpectedDocumentSendingProfile."E-Mail Attachment", ActualDocumentSendingProfile."E-Mail Attachment", ExpectedDocumentSendingProfile.FieldCaption("E-Mail Attachment"));
        Assert.AreEqual(ExpectedDocumentSendingProfile."Electronic Format", ActualDocumentSendingProfile."Electronic Format", ExpectedDocumentSendingProfile.FieldCaption("Electronic Format"));
        Assert.AreEqual(ExpectedDocumentSendingProfile."Electronic Document", ActualDocumentSendingProfile."Electronic Document", ExpectedDocumentSendingProfile.FieldCaption("Electronic Document"));
    end;

    local procedure VerifyDocumentProfilesAreIdenticalOnPage(var SelectSendingOptions: TestPage "Select Sending Options"; DocumentSendingProfile: Record "Document Sending Profile"; ElectronicDocumentVisible: Boolean)
    begin
        SelectSendingOptions.Printer.AssertEquals(DocumentSendingProfile.Printer);
        SelectSendingOptions.Disk.AssertEquals(DocumentSendingProfile.Disk);
        SelectSendingOptions."Disk Format".AssertEquals(DocumentSendingProfile."Disk Format");
        SelectSendingOptions."E-Mail".AssertEquals(DocumentSendingProfile."E-Mail");
        SelectSendingOptions."E-Mail Format".AssertEquals(DocumentSendingProfile."E-Mail Format");
        SelectSendingOptions."E-Mail Attachment".AssertEquals(DocumentSendingProfile."E-Mail Attachment");
        SelectSendingOptions."Electronic Format".AssertEquals(DocumentSendingProfile."Electronic Format");
        SelectSendingOptions."Electronic Document".AssertEquals(DocumentSendingProfile."Electronic Document");
        Assert.AreEqual(ElectronicDocumentVisible, SelectSendingOptions."Electronic Document".Visible(), '');
    end;

    local procedure CreateAndPostSalesOrderWithShipment(var PostedDocumentVariant: Variant; var Customer: Record Customer; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesPost.GetPostedDocumentRecord(SalesHeader, PostedDocumentVariant);
    end;

    local procedure CreateAndPostReturnOrderWithReceiving(var PostedDocumentVariant: Variant; var Customer: Record Customer; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        UpdateYourReferenceSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesPost.GetPostedDocumentRecord(SalesHeader, PostedDocumentVariant);
    end;

    local procedure AssertValidSalesShipmentNo(ExpectedValue: Text)
    begin
        case true of
            LibraryReportDataset.SearchForElementByValue(ReportNo_SalesShptHeaderTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            LibraryReportDataset.SearchForElementByValue(IT_ReportNo_SalesShptHeaderTxt, ExpectedValue):
                Assert.IsTrue(true, '');
            else
                Assert.IsTrue(false, StrSubstNo(ElementNameErr, ExpectedValue));
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerYes(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirm.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerNo(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirm.No().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogHandlerNo(var EmailEditor: TestPage "Email Editor")
    var
        DocumentNo: Text;
    begin
        EmailEditor.ToField.AssertEquals(LibraryVariableStorage.DequeueText());
        DocumentNo := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(
          StrPos(EmailEditor.SubjectField.Value, DocumentNo) > 0,
          'Wrong email subject - it doesnt contain the posted sales document number.');
        Assert.IsTrue(
          StrPos(EmailEditor.Attachments.FileName.Value, DocumentNo) > 0,
          'Wrong attachment name - it doesnt contain the posted sales document number.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogHandlerNoService(var EmailEditor: TestPage "Email Editor")
    var
        Customer: Record Customer;
        CustomerNo: Variant;
        DocumentNo: Code[20];
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);

        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);

        Assert.IsTrue(
          StrPos(EmailEditor.ToField.Value, Customer."E-Mail") = 1, 'Wrong email address in the To: field.');
        Assert.IsTrue(
          StrPos(EmailEditor.SubjectField.Value, DocumentNo) > 0,
          'Wrong email subject - it doesnt contain the posted sales document number.');
        Assert.IsTrue(
          StrPos(EmailEditor.Attachments.FileName.Value, DocumentNo) > 0,
          'Wrong attachment name - it doesnt contain the posted sales document number.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintInvoiceHandler(var StandardSalesInvoiceRequestPage: TestRequestPage "Standard Sales - Invoice")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        StandardSalesInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrintInvoiceHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintInvoiceHandlerService(var ServiceInvoiceRequestPage: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCreditMemoHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCreditMemoHandlerService(var ServiceCreditMemoRequestPage: TestRequestPage "Service - Credit Memo")
    begin
        ServiceCreditMemoRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.ShowLotSN.SetValue(true);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionHandler(var SelectSendingOption: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        DocumentSendingProfile := DocumentSendingProfileVar;
        SelectSendingOption.Printer.SetValue(DocumentSendingProfile.Printer);
        SelectSendingOption."E-Mail".SetValue(DocumentSendingProfile."E-Mail");
        SelectSendingOption.Disk.SetValue(DocumentSendingProfile.Disk);
        SelectSendingOption."E-Mail Attachment".SetValue(DocumentSendingProfile."E-Mail Attachment");
        SelectSendingOption."E-Mail Format".SetValue(DocumentSendingProfile."E-Mail Format");
        SelectSendingOption."Electronic Document".SetValue(DocumentSendingProfile."Electronic Document");
        SelectSendingOption."Electronic Format".SetValue(DocumentSendingProfile."Electronic Format");
        SelectSendingOption.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionHandlerAllTrue(var SelectSendingOption: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        CountVar: Variant;
        "Count": Integer;
    begin
        LibraryVariableStorage.Dequeue(CountVar);
        Count := CountVar;

        if Count = 1 then begin
            CreateDocumentSendingProfileWithAllTrue(DocumentSendingProfile);
            LibraryVariableStorage.Enqueue(DocumentSendingProfile);
            SelectSendingOption.Printer.SetValue(DocumentSendingProfile.Printer);
            SelectSendingOption."E-Mail".SetValue(DocumentSendingProfile."E-Mail");
            SelectSendingOption."E-Mail Attachment".SetValue(DocumentSendingProfile."E-Mail Attachment");
            SelectSendingOption.Disk.SetValue(DocumentSendingProfile.Disk);
            SelectSendingOption.OK().Invoke();
        end else begin
            Assert.IsTrue(StrPos(SelectSendingOption.Printer.Value, YesUseDefaultSettingsTxt) > 0, DocumentSendingProfileChangedErr);
            Assert.IsTrue(StrPos(SelectSendingOption."E-Mail".Value, YesUseDefaultSettingsTxt) > 0, DocumentSendingProfileChangedErr);
            Assert.IsTrue(StrPos(SelectSendingOption."E-Mail Attachment".Value, PdfTxt) > 0, DocumentSendingProfileChangedErr);
            Assert.IsTrue(StrPos(SelectSendingOption.Disk.Value, PdfTxt) > 0, DocumentSendingProfileChangedErr);
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectElectronicDocumentSendingOptionHandler(var SelectSendingOption: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOption.Printer.SetValue(DocumentSendingProfile.Printer::No);
        SelectSendingOption."E-Mail".SetValue(DocumentSendingProfile."E-Mail"::No);
        SelectSendingOption.Disk.SetValue(DocumentSendingProfile.Disk::"Electronic Document");
        SelectSendingOption."Electronic Document".SetValue(DocumentSendingProfile."Electronic Document"::No);
        SelectSendingOption.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerNoWithSendingProfileValidation(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
        SelectedSendingProfilesText: Text;
    begin
        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        DocumentSendingProfile := DocumentSendingProfileVar;
        SelectedSendingProfilesText := PostandSendConfirm.SelectedSendingProfiles.Value();
        PostandSendConfirm.No().Invoke();
        Assert.AreEqual(
          DocumentSendingProfile.Printer <> DocumentSendingProfile.Printer::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Printer)) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("E-Mail")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("Electronic Document")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No,
          StrPos(SelectedSendingProfilesText, Format(DocumentSendingProfile."Electronic Document")) > 0,
          UnexpectedSendngMethodsShownErr);

        Assert.AreEqual(
          DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Disk)) > 0,
          UnexpectedSendngMethodsShownErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerNoWithPromptWarningValidation(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    var
        ExpectedWarningMessageVar: Variant;
        ActualWarningMessage: Text;
        ExpectedWarningMessage: Text;
    begin
        LibraryVariableStorage.Dequeue(ExpectedWarningMessageVar);
        ExpectedWarningMessage := ExpectedWarningMessageVar;
        ActualWarningMessage := PostandSendConfirm.ChoicesForSendingTxt.Value();
        PostandSendConfirm.No().Invoke();
        Assert.AreEqual(
          ExpectedWarningMessage, ActualWarningMessage, 'Unexpected warning message about additional dialogs that will be shown.');
    end;

    [ModalPageHandler]
    [HandlerFunctions('SelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerWithOverrideAndSendingProfileValidation(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
        SelectedSendingProfilesText: Text;
    begin
        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        DocumentSendingProfile := DocumentSendingProfileVar;
        PostandSendConfirm.SelectedSendingProfiles.AssistEdit();
        SelectedSendingProfilesText := PostandSendConfirm.SelectedSendingProfiles.Value();
        PostandSendConfirm.No().Invoke();
        Assert.AreEqual(
          DocumentSendingProfile.Printer <> DocumentSendingProfile.Printer::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Printer)) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("E-Mail")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("Electronic Document")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No,
          StrPos(SelectedSendingProfilesText, Format(DocumentSendingProfile."Electronic Document")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Disk)) > 0,
          UnexpectedSendngMethodsShownErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerWithOverrideAndPromptWarningValidation(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    var
        ExpectedWarningMessageVar: Variant;
        ActualWarningMessage: Text;
        ExpectedWarningMessage: Text;
    begin
        LibraryVariableStorage.Dequeue(ExpectedWarningMessageVar);
        ExpectedWarningMessage := ExpectedWarningMessageVar;
        PostandSendConfirm.SelectedSendingProfiles.AssistEdit();
        ActualWarningMessage := PostandSendConfirm.ChoicesForSendingTxt.Value();
        PostandSendConfirm.No().Invoke();
        Assert.AreEqual(
          ExpectedWarningMessage, ActualWarningMessage, 'Unexpected warning message about additional dialogs that will be shown.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerYesWithOverride(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirm.SelectedSendingProfiles.AssistEdit();
        PostandSendConfirm.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerForAssistEditTest(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
        SelectedSendingProfilesText: Text;
        "Count": Integer;
    begin
        Count := 1;
        LibraryVariableStorage.Enqueue(Count);

        PostandSendConfirm.SelectedSendingProfiles.AssistEdit();

        SelectedSendingProfilesText := PostandSendConfirm.SelectedSendingProfiles.Value();

        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        DocumentSendingProfile := DocumentSendingProfileVar;
        Assert.AreEqual(
          DocumentSendingProfile.Printer = DocumentSendingProfile.Printer::"Yes (Use Default Settings)",
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Printer)) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."E-Mail" = DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)",
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("E-Mail")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile."Electronic Document" =
          DocumentSendingProfile."Electronic Document"::"Through Document Exchange Service",
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption("Electronic Document")) > 0,
          UnexpectedSendngMethodsShownErr);
        Assert.AreEqual(
          DocumentSendingProfile.Disk = DocumentSendingProfile.Disk::PDF,
          StrPos(SelectedSendingProfilesText, DocumentSendingProfile.FieldCaption(Disk)) > 0,
          UnexpectedSendngMethodsShownErr);

        Count := Count + 1;
        LibraryVariableStorage.Enqueue(Count);
        PostandSendConfirm.SelectedSendingProfiles.AssistEdit();

        PostandSendConfirm.No().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogVerifySubjectAndAttahcmentNamesMPH(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.SubjectField.AssertEquals(LibraryVariableStorage.DequeueText());
        EmailEditor.Attachments.FileName.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure VerifyAndCancelCustomerProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        LibraryVariableStorage.DequeueInteger(); // dummy dequeue to test calls count
        Assert.ExpectedMessage(ProfileSelectionQst, Options);
        Assert.ExpectedMessage(CustomerProfileSelectionInstrTxt, Instruction);
        Assert.AreEqual(3, Choice, 'Wrong default profile method selection option.');
        Choice := 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure VerifyAndCancelVendorProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        LibraryVariableStorage.DequeueInteger(); // dummy dequeue to test calls count
        Assert.ExpectedMessage(ProfileSelectionQst, Options);
        Assert.ExpectedMessage(VendorProfileSelectionInstrTxt, Instruction);
        Assert.AreEqual(3, Choice, 'Wrong default profile method selection option.');
        Choice := 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifySelectSendingOptionHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
        ElectronicDocumentVisible: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        CustomerDocumentSendingProfile := DocumentSendingProfileVar;
        ElectronicDocumentVisible := LibraryVariableStorage.DequeueBoolean();
        VerifyDocumentProfilesAreIdenticalOnPage(SelectSendingOptions, CustomerDocumentSendingProfile, ElectronicDocumentVisible);
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyAndCancelSelectSendingOptionHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    var
        CustomerDocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileVar: Variant;
        ElectronicDocumentVisible: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentSendingProfileVar);
        CustomerDocumentSendingProfile := DocumentSendingProfileVar;
        ElectronicDocumentVisible := LibraryVariableStorage.DequeueBoolean();
        VerifyDocumentProfilesAreIdenticalOnPage(SelectSendingOptions, CustomerDocumentSendingProfile, ElectronicDocumentVisible);
        SelectSendingOptions.Cancel().Invoke();
    end;

    local procedure VerifyDocumentNosSalesInvoiceCreditMemoReportDifferentCustomer(DocumentNo: Code[20]; FileName: Text)
    begin
        Clear(LibraryReportDataset);
        LibraryReportDataset.SetFileName(FileName);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, DocumentNo);
    end;

    local procedure VerifyDocumentNosSalesInvoiceCreditMemoReportSingleCustomer(DocumentNo1: Code[20]; DocumentNo2: Code[20])
    begin
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReportNoSalesInvCrMemoHdrTxt, DocumentNo1);
        LibraryReportDataset.AssertElementWithValueNotExist(ReportNoSalesInvCrMemoHdrTxt, DocumentNo2);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ConfirmDefaultProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure UseDefaultProfileSelectionMethodStrMenuAndCloseEmailHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        ExpectedQueueLength: Integer;
    begin
        if Options = 'Keep as draft in Email Outbox,Discard email' then
            Choice := 1
        else begin
            ExpectedQueueLength := LibraryVariableStorage.DequeueInteger();
            Assert.AreEqual(ExpectedQueueLength, LibraryVariableStorage.Length(), '');
            Choice := 3;
        end;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ConfirmPerDocProfileSelectionMethodAndCloseEmailStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        ExpectedQueueLength: Integer;
    begin
        if Options = 'Keep as draft in Email Outbox,Discard email' then
            Choice := 1
        else begin
            ExpectedQueueLength := LibraryVariableStorage.DequeueInteger();
            Assert.AreEqual(ExpectedQueueLength, LibraryVariableStorage.Length(), '');
            Choice := 2;
        end;
    end;


    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ConfirmPerDocProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        ExpectedQueueLength: Integer;
    begin
        ExpectedQueueLength := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(ExpectedQueueLength, LibraryVariableStorage.Length(), '');
        Choice := 2;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure UseDefaultProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        ExpectedQueueLength: Integer;
    begin
        ExpectedQueueLength := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(ExpectedQueueLength, LibraryVariableStorage.Length(), '');
        Choice := 3;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReportRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    begin
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure PrintSalesShipmentHandler(var SalesShipmentRequestPage: TestRequestPage "Sales - Shipment")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        SalesShipmentRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    procedure PrintSalesReturnReceiptHandler(var SalesReturnReceiptRequestPage: TestRequestPage "Sales - Return Receipt")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        SalesReturnReceiptRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnBeforeRetrieveDocumentItemTracking', '', false, false)]
    local procedure InvokeErrorOnRetrieveDocumentItemTracking()
    begin
        Error(InterruptedByEventSubscriberErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnIsTestMode(var TestMode: Boolean)
    begin
        TestMode := true
    end;
}

