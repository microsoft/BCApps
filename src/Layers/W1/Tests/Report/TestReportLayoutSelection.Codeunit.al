codeunit 134605 "Test Report Layout Selection"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySmtpMailHandler: Codeunit "Library - SMTP Mail Handler";

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationBankInfoWhenPageOpens()
    var
        CustomReportLayouts: TestPage "Custom Report Layouts";
    begin
        CustomReportLayouts.OpenView();
        CustomReportLayouts.Close();
    end;

    [Test]
    [HandlerFunctions('JobQueueEntriesHandler,ReportIsEmptyMsgHandler')]
    [Scope('OnPrem')]
    procedure TestReportInbox()
    var
        ReportInbox: Record "Report Inbox";
        OrderProcessorRoleCenter: TestPage "Order Processor Role Center";
    begin
        // Init
        ReportInbox.DeleteAll();
        ReportInbox."User ID" := UserId;
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := 134600;
        ReportInbox.Description := '134600';
        ReportInbox.Insert(true);

        // Execute
        OrderProcessorRoleCenter.OpenView();
        OrderProcessorRoleCenter.Control21.First();
        // Pre-validation
        Assert.AreEqual('134600', OrderProcessorRoleCenter.Control21.Description.Value, '');
        ReportInbox.Read := true;
        ReportInbox.Modify();

        // Read/Unread
        OrderProcessorRoleCenter.Control21.Unread.Invoke();
        Assert.IsFalse(OrderProcessorRoleCenter.Control21.First(), '');
        OrderProcessorRoleCenter.Control21.All.Invoke();
        Assert.IsTrue(OrderProcessorRoleCenter.Control21.First(), '');

        OrderProcessorRoleCenter.Control21.ShowQueue.Invoke(); // Verify that it opens Job Queue Entries page.

        OrderProcessorRoleCenter.Control21.Show.Invoke();
        OrderProcessorRoleCenter.Control21.Description.DrillDown(); // Save as Show

        OrderProcessorRoleCenter.Control21.Delete.Invoke();
        Assert.IsFalse(OrderProcessorRoleCenter.Control21.First(), '');
    end;

    [Test]
    [HandlerFunctions('ReportIsEmptyMsgHandler')]
    [Scope('OnPrem')]
    procedure TestReportInboxTestPage()
    var
        ReportInbox: Record "Report Inbox";
        ReportInboxTestPage: TestPage "Report Inbox";
    begin
        // [FEATURE] [Report Inbox] [UI]
        // [SCENARIO 314312] Stan can download report from Report Inbox list page
        ReportInbox.DeleteAll();
        ReportInbox."User ID" := UserId;
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := 134600;
        ReportInbox.Insert(true);

        ReportInboxTestPage.OpenView();

        Assert.AreEqual('Test Report - Default=Word', ReportInboxTestPage."Report Name".Value, '');

        ReportInboxTestPage."Report Name".DrillDown(); // Save as Show
        ReportInboxTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('Report134600ReportHandler,CustomLayoutHandler')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageOpen()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        ReportLayoutSelectionPage.OpenView();
        ReportLayoutSelectionPage.First();
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger(), '');

        ReportLayoutSelection."Report ID" := 134602;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        asserterror ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        ReportLayoutSelectionPage.Customizations.Invoke();
        ReportLayoutSelectionPage.RunReport.Invoke();

        ReportLayoutSelectionPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CustomLayoutHandlerModal,NewLayoutHandlerModal')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageLineActions()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        ReportLayoutSelectionPage.OpenView();
        ReportLayoutSelectionPage.First();
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger(), '');

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        // Execute. Opens modal pages.
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Custom Layout")); // Opens lookup
        ReportLayoutSelectionPage.CustomLayoutDescription.SetValue('Test');
        Assert.AreEqual('Test', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');

        ReportLayoutSelectionPage.CustomLayoutDescription.Lookup(); // lookup from description
        ReportLayoutSelectionPage.CustomLayoutDescription.SetValue('Test');
        Assert.AreEqual('Test', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');

        ReportLayoutSelectionPage.CustomLayoutDescription.SetValue('built'); // finds closest match
        Assert.AreEqual('Copy of built-in', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');
    end;

    [Test]
    [HandlerFunctions('ReportayoutsHandlerModal')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageSelectLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        ReportMetadata: Record "Report Metadata";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        PublishedApplication: Record "Published Application";
        TestReportLayoutSelection: Codeunit "Test Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        // [GIVEN] No existing built-in layout selected for test report
        TenantReportLayoutSelection.SetRange("Report ID", 134600);
        TenantReportLayoutSelection.DeleteAll();
        BindSubscription(TestReportLayoutSelection);

        // [WHEN] Invoking the description lookup for the built-in word layout on the test report
        ReportLayoutSelectionPage.OpenView();
        ReportLayoutSelectionPage.First();
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger(), '');
        ReportLayoutSelectionPage.GoToKey(134600, '');
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Word (built-in)"));
        ReportLayoutSelectionPage.SelectLayout.Invoke();

        ReportLayoutList.SetRange("Report ID", 134600);
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.FindFirst();
        PublishedApplication.Get(ReportLayoutList."Runtime Package ID");

        // [THEN] The layout selection list shows the name of the built-in layout
        Assert.AreEqual(ReportLayoutList.Name, ReportLayoutSelectionPage.CustomLayoutDescription.Value, 'Correct layout should be set');

        // [THEN] A tenant layout selection record is inserted for the report
        TenantReportLayoutSelection.FindFirst();
        Assert.AreEqual(ReportLayoutList.Name, TenantReportLayoutSelection."Layout Name", 'Layout should be selected in tenant report layout selection');
        Assert.AreEqual(ReportLayoutSelectionPage.SelectedCompany.Value, TenantReportLayoutSelection."Company Name", 'Layout should be inserted for correct company');
        Assert.AreEqual(PublishedApplication.ID, TenantReportLayoutSelection."App ID", 'Layout should be inserted for correct app id');

        // [WHEN] The report layout description is cleared
        ReportLayoutSelectionPage.CustomLayoutDescription.SetValue('');

        ReportMetadata.Get(134600);
        // [THEN] The layout goes back to default
        Assert.AreEqual(ReportMetadata.DefaultLayoutName, ReportLayoutSelectionPage.CustomLayoutDescription.Value, 'Correct layout should be set');
        // [THEN] The tenant layout selection is deleted
        Assert.RecordIsEmpty(TenantReportLayoutSelection);
    end;

    [Test]
    [HandlerFunctions('CustomLayoutHandlerModal,NewLayoutHandlerModal')]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectCustomLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // [GIVEN] Custom Layouts page will contain 2 custom layouts for report 134600
        ReportLayoutSelectionPage.OpenView();
        ReportLayoutSelectionPage.First();
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger(), '');

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        // [When] Lookup page opens and the 'Test' layout is selected
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Custom Layout")); // Opens lookup

        // [Expected] The test layout actually runs
        Assert.AreEqual('Test', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReportayoutsHandlerModal')]
    procedure TestReportLayoutRestoreDefaultLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        ReportMetadata: Record "Report Metadata";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        PublishedApplication: Record "Published Application";
        TestReportLayoutSelection: Codeunit "Test Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        // [GIVEN] No existing built-in layout selected for test report
        TenantReportLayoutSelection.SetRange("Report ID", 134600);
        TenantReportLayoutSelection.DeleteAll();
        BindSubscription(TestReportLayoutSelection);

        // [WHEN] Invoking the description lookup for the built-in word layout on the test report
        // and then invoking ResetDefaultLayout
        ReportLayoutSelectionPage.OpenView();
        ReportLayoutSelectionPage.First();
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger(), '');
        ReportLayoutSelectionPage.GoToKey(134600, '');
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Word (built-in)"));
        ReportLayoutSelectionPage.SelectLayout.Invoke();

        ReportLayoutList.SetRange("Report ID", 134600);
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.FindFirst();
        PublishedApplication.Get(ReportLayoutList."Runtime Package ID");

        Assert.AreEqual(ReportLayoutList.Name, ReportLayoutSelectionPage.CustomLayoutDescription.Value, 'Correct layout should be set');

        ReportLayoutSelectionPage.RestoreDefaultLayout.Invoke();

        Assert.IsTrue(ReportMetadata.Get(134600), 'Report should exist.');
        // [THEN] The layout selection should be set to default
        Assert.AreEqual(ReportMetadata.DefaultLayoutName, ReportLayoutSelectionPage.CustomLayoutDescription.Value, 'The default layout should have been restored.');
    end;

    [Test]
    [HandlerFunctions('ServerPrinterPageHandler')]
    [Scope('OnPrem')]
    procedure TestPageServerPrinters()
    var
        ServerPrinters: Page "Server Printers";
    begin
        ServerPrinters.SetSelectedPrinterName('X');
        if ServerPrinters.RunModal() = ACTION::OK then
            if ServerPrinters.GetSelectedPrinterName() = '' then; // non-predictable in test environment
    end;

    [Test]
    [HandlerFunctions('DateTimeDialogHandler')]
    [Scope('OnPrem')]
    procedure TestDateTimeDialogFromJobQECard()
    var
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // Init
        JobQueueEntryCard.OpenNew();
        JobQueueEntryCard."Earliest Start Date/Time".Value := Format(CreateDateTime(22221212D, 121200T));

        // Execute
        JobQueueEntryCard."Earliest Start Date/Time".Lookup();

        // Validate
        Assert.AreEqual(
          Format(CreateDateTime(20110101D, 010100T)),
          Format(JobQueueEntryCard."Earliest Start Date/Time".AsDateTime()),
          'Earlies start date/time');
    end;

    [Test]
    [HandlerFunctions('DateTimeDialogHandler')]
    [Scope('OnPrem')]
    procedure TestDateTimeDialogFromJobQECard2()
    var
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // Init
        JobQueueEntryCard.OpenNew();
        JobQueueEntryCard."Expiration Date/Time".Value := Format(CreateDateTime(22221212D, 121200T));

        // Execute
        JobQueueEntryCard."Expiration Date/Time".Lookup();

        // Validate
        Assert.AreEqual(
          Format(CreateDateTime(20110101D, 010100T)),
          Format(JobQueueEntryCard."Expiration Date/Time".AsDateTime()),
          'Expiration date/time');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStartAndExpirationFromJobQE()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        BindSubscription(LibraryJobQueue);

        // Init();
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20121212D, 121200T));

        // Execute + Validate
        JobQueueEntry.Validate("Earliest Start Date/Time", CreateDateTime(20110101D, 010100T));
        JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20120101D, 000000T));
        asserterror JobQueueEntry.Validate("Earliest Start Date/Time", CreateDateTime(20121212D, 121200T));
        asserterror JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20100101D, 000000T));

        UnbindSubscription(LibraryJobQueue);
    end;

    [HandlerFunctions('SelectSendingOptionModalPageHandler')]
    [Test]
    [Scope('OnPrem')]
    procedure SendTwoSalesInvoicesInJobQueue()
    begin
        SendTwoSalesInvoicesInJobQueueInternal();
    end;

    procedure SendTwoSalesInvoicesInJobQueueInternal()
    var
        Customer: Record "Customer";
        SalesInvoiceHeader: array[2] of Record "Sales Invoice Header";
        SalesInvoiceHeaderToSend: Record "Sales Invoice Header";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentSendingProfile: Record "Document Sending Profile";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryEmail: Codeunit "Library - Email";
    begin
        // [FEATURE] [Email] [Document Sending Profile] [Sales]
        // [SCENARIO 334364] Stan can "Send" to email posted sales invoice and "print" them via job queue.
        LibraryEmail.SetUpEmailAccount();
        LibrarySmtpMailHandler.SetDisableSending(true);
        FilterJobQueueEntryDocumentMailing(JobQueueEntry);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Customer "C" with two posted sales invoices.
        CreateCustomerWithDocumentSendingSetup(Customer, DocumentSendingProfile);

        MockSalesInvoiceHeaderWithEmailAddress(SalesInvoiceHeader[1], Customer);
        MockSalesInvoiceHeaderWithEmailAddress(SalesInvoiceHeader[2], Customer);

        // [WHEN] When call "Send..." on selected posted sales invoices
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        SalesInvoiceHeaderToSend.SetFilter("No.", '%1|%2', SalesInvoiceHeader[1]."No.", SalesInvoiceHeader[2]."No.");
        SalesInvoiceHeaderToSend.FindLast();
        SalesInvoiceHeaderToSend.SendRecords();

        // [THEN] Two job queue entries created for each invoice with "Job Queue Category Code" = SENDINV
        Assert.RecordCount(JobQueueEntry, 2);
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader[1].RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader[2].RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [HandlerFunctions('SelectSendingOptionModalPageHandler')]
    [Test]
    [Scope('OnPrem')]
    procedure SendTwoPurchaseInvoicesInJobQueue()
    begin
        SendTwoPurchaseInvoicesInJobQueueInternal();
    end;

    procedure SendTwoPurchaseInvoicesInJobQueueInternal()
    var
        Vendor: Record "Vendor";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseHeaderToSend: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentSendingProfile: Record "Document Sending Profile";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryEmail: Codeunit "Library - Email";
    begin
        // [FEATURE] [Email] [Document Sending Profile] [Sales]
        // [SCENARIO 334364] Stan can "Send" to email posted sales invoice and "print" them via job queue.
        LibraryEmail.SetUpEmailAccount();
        LibrarySmtpMailHandler.SetDisableSending(true);
        FilterJobQueueEntryDocumentMailing(JobQueueEntry);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Customer "C" with two posted sales invoices.
        CreateVendorWithDocumentSendingSetup(Vendor, DocumentSendingProfile);

        MockPurchaseHeaderWithEmailAddress(PurchaseHeader[1], Vendor);
        MockPurchaseHeaderWithEmailAddress(PurchaseHeader[2], Vendor);

        // [WHEN] When call "Send..." on selected posted sales invoices
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        PurchaseHeaderToSend.SetFilter("No.", '%1|%2', PurchaseHeader[1]."No.", PurchaseHeader[2]."No.");
        PurchaseHeaderToSend.FindLast();
        PurchaseHeaderToSend.SendRecords();

        // [THEN] Two job queue entries created for each invoice with "Job Queue Category Code" = SENDINV
        Assert.RecordCount(JobQueueEntry, 2);
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader[1].RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader[2].RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    local procedure CreateCustomerWithDocumentSendingSetup(var Customer: Record Customer; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        CreateDefaultDocumentSendingProfile(DocumentSendingProfile);
        CreateCustomerWithEMailAndSendingProfile(Customer, DocumentSendingProfile.Code);
    end;

    local procedure CreateVendorWithDocumentSendingSetup(var Vendor: Record Vendor; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        CreateDefaultDocumentSendingProfile(DocumentSendingProfile);
        CreateVendorWithEMailAndSendingProfile(Vendor, DocumentSendingProfile.Code);
    end;

    local procedure CreateCustomerWithEMailAndSendingProfile(var Customer: Record Customer; DocSendingProfileCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Validate("Document Sending Profile", DocSendingProfileCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithEMailAndSendingProfile(var Vendor: Record Vendor; DocSendingProfileCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Vendor.Validate("Document Sending Profile", DocSendingProfileCode);
        Vendor.Modify(true);
    end;

    local procedure CreateDefaultDocumentSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        DocumentSendingProfile.Validate(Code, LibraryUtility.GenerateGUID());
        DocumentSendingProfile.Validate(Printer, DocumentSendingProfile.Printer::No);
        DocumentSendingProfile.Validate("E-Mail", DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)");
        DocumentSendingProfile.Validate("E-Mail Attachment", DocumentSendingProfile."E-Mail Attachment"::PDF);
        DocumentSendingProfile.Insert(true);
    end;

    local procedure FilterJobQueueEntryDocumentMailing(var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportSelections: Record "Report Selections";
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", ReportSelections.GetMailingJobCategory());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Document-Mailing");
    end;

    local procedure MockSalesInvoiceHeaderWithEmailAddress(var SalesInvoiceHeader: Record "Sales Invoice Header"; Customer: Record Customer)
    begin
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Bill-to Customer No." := Customer."No.";
        SalesInvoiceHeader.Insert();
    end;

    local procedure MockPurchaseHeaderWithEmailAddress(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader."No." := LibraryUtility.GenerateGUID();
        PurchaseHeader."Buy-from Vendor No." := Vendor."No.";
        PurchaseHeader."Pay-to Vendor No." := Vendor."No.";
        PurchaseHeader.Insert();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntriesHandler(var JobQueueEntries: TestPage "Job Queue Entries")
    begin
        JobQueueEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReportIsEmptyMsgHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, 'empty') > 1, '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomLayoutHandler(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomLayoutHandlerModal(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.NewLayout.Invoke();
        CustomReportLayouts.Description.SetValue('Copy of built-in');
        CustomReportLayouts.CopyRec.Invoke();
        CustomReportLayouts.Description.SetValue('Test');
        CustomReportLayouts.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewLayoutHandlerModal(var ReportLayoutLookup: TestPage "Report Layout Lookup")
    begin
        ReportLayoutLookup.AddRDLC.SetValue(true);
        ReportLayoutLookup.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure Report134600ReportHandler(var TestReportDefaultWord: Report "Test Report - Default=Word")
    begin
        Clear(TestReportDefaultWord);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServerPrinterPageHandler(var ServerPrinters: TestPage "Server Printers")
    begin
        ServerPrinters.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DateTimeDialogHandler(var DateTimeDialog: TestPage "Date-Time Dialog")
    begin
        // Validate initial values
        Assert.AreEqual(22221212D, DateTimeDialog.Date.AsDate(), '');
        Assert.AreEqual(121200T, DateTimeDialog.Time.AsTime(), '');

        // Execute new values
        DateTimeDialog.Date.Value := Format(20110101D);
        DateTimeDialog.Time.Value := Format(010100T);

        DateTimeDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportayoutsHandlerModal(var ReportLayouts: TestPage "Report Layouts")
    begin
        ReportLayouts.Cancel().Invoke();
    end;


    [EventSubscriber(ObjectType::Page, Page::"Report Layout Selection", 'OnSelectReportLayout', '', false, false)]
    local procedure SelectReportLayout(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
        ReportLayoutList.FindFirst();
        Handled := true;
    end;
}
