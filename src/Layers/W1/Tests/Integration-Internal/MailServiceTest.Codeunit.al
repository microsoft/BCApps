codeunit 139111 "Mail Service Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Email]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryJob: Codeunit "Library - Job";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        EmailSubjectCapMsg: Label '%1 - %2 %3';
        AttachmentNameTok: Label '%1 %2.pdf';
        SalesInvoiceTxt: Label 'Sales Invoice';
        SalesQuoteTxt: Label 'Sales Quote';
        SalesShipmentTxt: Label 'Sales Shipment';
        SalesReceiptTxt: Label 'Sales Receipt';
        PurchaseQuoteTxt: Label 'Purchase Quote';
        PurchaseOrderTxt: Label 'Purchase Order';
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCrMemoTxt: Label 'Service Credit Memo';
        JobQuoteTxt: Label 'Project Quote';
        IncorrectSubjectErr: Label 'Subject is not correct';
        IncorrectAttachNameErr: Label 'Attachment Name is not correct';

    [Test]
    [HandlerFunctions('StrMenuHandler,ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAndSendEmail()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ExpectedSubjectCap: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Shipment] [Invoice] [Sales]
        // [SCENARIO] Sales Shipment report created from "Post and Email" on Sales Order should be send in email with the subject "%CompanyName% Shipment %Shipment_No%"
        // [SCENARIO] Sales Invoice report created from "Post and Email" on Sales Order should be send in email with the subject "%CompanyName% Invoice %Invoice_No%"
        Initialize();

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        // [WHEN] Post Sales Order with Shipment and Invoice and send Email - No recipient on email throws an error
        LibrarySales.PostSalesDocumentAndEmail(SalesHeader, true, true);

        // [THEN] Sales Shipment "SH1" was created.
        // [THEN] Email dialog opened, Subject = "%CompanyName% - Sales Shipment SH1", Attachment Name = "Sales Shipment SH1.pdf".
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindLast();
        ExpectedSubjectCap := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), SalesShipmentTxt, SalesShipmentHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, SalesShipmentTxt, SalesShipmentHeader."No.");

        VerifySubjectAndAttachmentName(ExpectedSubjectCap, ExpectedAttachName);

        // [THEN] Sales Invoice "SI1" was created.
        // [THEN] Email dialog opened, Subject = "%CompanyName% - Sales Invoice SI1", Attachment Name = "Sales Invoice SI1.pdf".
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindLast();
        ExpectedSubjectCap := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), SalesInvoiceTxt, SalesInvoiceHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, SalesInvoiceTxt, SalesInvoiceHeader."No.");

        VerifySubjectAndAttachmentName(ExpectedSubjectCap, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure FinChargeMemoAndSendEmail()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinanceChargeMemoPage: Page "Issued Finance Charge Memo";
        ExpectedSubjectCap: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Finance Charge Memo] [UT]
        // [SCENARIO] Run PrintRecords function with SendAsEmail = true for Issued Finance Charge Memo.
        Initialize();

        // [GIVEN] Issued Finance Charge Memo with No. = "IFCM1".
        MockIssuedFinChargeMemo(IssuedFinChargeMemoHeader);
        ExpectedSubjectCap :=
            StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), IssuedFinanceChargeMemoPage.Caption, IssuedFinChargeMemoHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, IssuedFinanceChargeMemoPage.Caption, IssuedFinChargeMemoHeader."No.");

        // [WHEN] Run PrintRecords function with SendAsEmail = true for Issued Finance Charge Memo.
        IssuedFinChargeMemoHeader.SetRecFilter();
        IssuedFinChargeMemoHeader.PrintRecords(false, true, false);

        // [THEN] Email dialog opened, Subject = "<CompanyName> - Issued Finance Charge Memo IFCM1".
        // [THEN] Attachment Name = "Issued Finance Charge Memo IFCM1.pdf".
        VerifySubjectAndAttachmentName(ExpectedSubjectCap, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure RemindersAndSendEmail()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderPage: Page "Issued Reminder";
        ExpectedSubjectCap: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Reminder] [UT]
        // [SCENARIO] Run PrintRecords function with SendAsEmail = true for Issued Reminder.
        Initialize();

        // [GIVEN] Issued Reminder "IR1".
        MockIssuedReminder(IssuedReminderHeader);
        ExpectedSubjectCap :=
            StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), IssuedReminderPage.Caption, IssuedReminderHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, IssuedReminderPage.Caption, IssuedReminderHeader."No.");

        // [WHEN] Run PrintRecords function with SendAsEmail = true for Issued Reminder.
        IssuedReminderHeader.SetRecFilter();
        IssuedReminderHeader.PrintRecords(false, true, false);

        // [THEN] Email dialog opened, Subject = "<CompanyName> - Issued Reminder IR1", Attachment Name = "Issued Reminder IR1.pdf".
        VerifySubjectAndAttachmentName(ExpectedSubjectCap, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SendIssuedRemindersWithDialog()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Reminder] [UT]
        // [SCENARIO 377411] Send multiple Issued Reminders with prompt dialog on each reminder
        Initialize();

        // [GIVEN] Two Issued Reminders
        MockIssuedReminder(IssuedReminderHeader);
        MockIssuedReminder(IssuedReminderHeader);
        Commit();

        // [GIVEN] Reminders sent to email
        IssuedReminderHeader.PrintRecords(false, true, false);

        // [WHEN] Reply "No" on confirmation to suppress send dialog
        // [THEN] Send dialog appeared (handler has been invoked)
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSendEmail()
    var
        SalesHeader: Record "Sales Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ReportSelectionUsage: Enum "Report Selection Usage";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 359726] Run EmailRecords function for Sales Invoice.
        Initialize();
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Sales Invoice with No. = "SI1".
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateCustomReportSelectionForCustomer(
            SalesHeader."Sell-to Customer No.", ReportSelectionUsage::"S.Invoice Draft", Report::"Standard Sales - Draft Invoice");
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), SalesInvoiceTxt, SalesHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, SalesInvoiceTxt, SalesHeader."No.");

        // [WHEN] Run EmailRecords function for Sales Invoice.
        SalesHeader.SetRecFilter();
        SalesHeader.EmailRecords(true);

        // [THEN] Email dialog opened, Subject = "<Company Name> - Sales Invoice SI1", Attachment Name = "Sales Invoice SI1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure SalesQuoteSendEmail()
    var
        SalesHeader: Record "Sales Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ReportSelectionUsage: Enum "Report Selection Usage";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Sales] [Quote] [UT]
        // [SCENARIO 359726] Run EmailRecords function for Sales Quote.
        Initialize();
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Sales Quote with No. = "SQ1".
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        CreateCustomReportSelectionForCustomer(
            SalesHeader."Sell-to Customer No.", ReportSelectionUsage::"S.Quote", Report::"Standard Sales - Quote");
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), SalesQuoteTxt, SalesHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, SalesQuoteTxt, SalesHeader."No.");

        // [WHEN] Run EmailRecords function for Sales Quote.
        SalesHeader.SetRecFilter();
        SalesHeader.EmailRecords(true);

        // [THEN] Email dialog opened, Subject = "<Company Name> - Sales Quote SQ1", Attachment Name = "Sales Quote SQ1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure ReturnReceiptSendEmail()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Sales] [Return Receipt] [UT]
        // [SCENARIO 359726] Run EmailRecords function for Posted Return Receipt.
        Initialize();

        // [GIVEN] Posted Return Receipt with No. = "RR1".
        ReturnReceiptHeader.Get(CreateAndPostSalesReturnOrder());
        ExpectedSubject :=
            StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), SalesReceiptTxt, ReturnReceiptHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, SalesReceiptTxt, ReturnReceiptHeader."No.");

        // [WHEN] Run EmailRecords function for Posted Return Receipt.
        ReturnReceiptHeader.SetRecFilter();
        ReturnReceiptHeader.EmailRecords(true);

        // [THEN] Email dialog opened, Subject = "<Company Name> - Sales Receipt RR1", Attachment Name = "Sales Receipt RR1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure JobSendEmail()
    var
        Job: Record Job;
        ReportSelectionUsage: Enum "Report Selection Usage";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Job] [UT]
        // [SCENARIO 359726] Run EmailRecords function for Job.
        Initialize();

        // [GIVEN] Job "J1".
        LibraryJob.CreateJob(Job);
        CreateCustomReportSelectionForCustomer(Job."Bill-to Customer No.", ReportSelectionUsage::JQ, Report::"Job Quote");
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), JobQuoteTxt, Job."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, JobQuoteTxt, Job."No.");

        // [WHEN] Run EmailRecords for Job.
        Job.SetRecFilter();
        Job.EmailRecords(true);

        // [THEN] Email dialog opened, Subject = "<Company Name> - Job Quote J1", Attachment Name = "Job Quote J1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteSendEmail()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Purchase] [Quote] [UT]
        // [SCENARIO 359726] Send Email for Purchase Quote.
        Initialize();
        CreateEmailPdfDefaultDocumentSendingProfile();

        // [GIVEN] Purchase Quote "PQ1".
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), PurchaseQuoteTxt, PurchaseHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, PurchaseQuoteTxt, PurchaseHeader."No.");

        // [WHEN] Run Send for Purchase Quote. Email with PDF attachment is selected by default.
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] Email dialog opened, Subject = "<Company Name> - Purchase Quote PQ1", Attachment Name = "Purchase Quote PQ1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure PurchaseOrderSendEmail()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Purchase] [Order] [UT]
        // [SCENARIO 359726] Send Email for Purchase Order.
        Initialize();
        CreateEmailPdfDefaultDocumentSendingProfile();

        // [GIVEN] Purchase Order "PO1".
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), PurchaseOrderTxt, PurchaseHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, PurchaseOrderTxt, PurchaseHeader."No.");

        // [WHEN] Run Send for Purchase Order. Email with PDF attachment is selected by default.
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] Email dialog opened, Subject = "<Company Name> - Purchase Order PO1", Attachment Name = "Purchase Order PO1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,ConfirmHandlerYes,ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceSendEmail()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Service] [Invoice] [UT]
        // [SCENARIO 359726] Send Email for Posted Service Invoice.
        Initialize();
        CreateEmailPdfDefaultDocumentSendingProfile();

        // [GIVEN] Posted Service Invoice "SI1".
        ServiceInvoiceHeader.Get(CreateAndPostServiceInvoice());
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), ServiceInvoiceTxt, ServiceInvoiceHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, ServiceInvoiceTxt, ServiceInvoiceHeader."No.");

        // [WHEN] Run Send for Posted Service Invoice. Email with PDF attachment is selected by default.
        ServiceInvoiceHeader.SetRecFilter();
        ServiceInvoiceHeader.SendRecords();

        // [THEN] Email dialog opened, Subject = "<Company Name> - Service Invoice SI1", Attachment Name = "Service Invoice SI1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,ConfirmHandlerYes,ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoSendEmail()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ExpectedSubject: Text;
        ExpectedAttachName: Text;
    begin
        // [FEATURE] [Service] [Credit Memo] [UT]
        // [SCENARIO 359726] Send Email for Posted Service Credit Memo.
        Initialize();
        CreateEmailPdfDefaultDocumentSendingProfile();

        // [GIVEN] Posted Service Credit Memo "SCM1".
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemo());
        ExpectedSubject := StrSubstNo(EmailSubjectCapMsg, GetCompanyName(), ServiceCrMemoTxt, ServiceCrMemoHeader."No.");
        ExpectedAttachName := StrSubstNo(AttachmentNameTok, ServiceCrMemoTxt, ServiceCrMemoHeader."No.");

        // [WHEN] Run Send for Posted Service Credit Memo. Email with PDF attachment is selected by default.
        ServiceCrMemoHeader.SetRecFilter();
        ServiceCrMemoHeader.SendRecords();

        // [THEN] Email dialog opened, Subject = "<Company Name> - Service Credit Memo SCM1", Attachment Name = "Service Credit Memo SCM1.pdf"
        VerifySubjectAndAttachmentName(ExpectedSubject, ExpectedAttachName);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryEmail: Codeunit "Library - Email";
    begin
        LibraryEmail.SetUpEmailAccount();
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        if not IsInitialized then begin
            IsInitialized := true;

            CompanyInformation.Get();
            CompanyInformation."Bank Account No." := 'A';
            CompanyInformation.Modify();
        end;
    end;

    local procedure CreateCustomReportSelectionForCustomer(CustomerNo: Code[20]; ReportSelectionUsage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustomReportSelection.Init();
        CustomReportSelection.Validate("Source Type", Database::Customer);
        CustomReportSelection.Validate("Source No.", CustomerNo);
        CustomReportSelection.Validate(Usage, ReportSelectionUsage);
        CustomReportSelection.Validate(Sequence, 1);
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Use for Email Body", true);
        CustomReportSelection.Validate(
            "Email Body Layout Code", CustomReportLayout.InitBuiltInLayout(CustomReportSelection."Report ID", CustomReportLayout.Type::Word.AsInteger()));
        CustomReportSelection.Insert(true);
    end;

    local procedure CreateEmailPdfDefaultDocumentSendingProfile();
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::PDF;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert();
    end;

    local procedure CreateAndPostSalesReturnOrder() PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostServiceInvoice() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        PostedDocNo := ServiceInvoiceHeader."No.";
    end;

    local procedure CreateAndPostServiceCrMemo() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        PostedDocNo := ServiceCrMemoHeader."No.";
    end;

    local procedure FindCustomerPostingGroup(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.FindLast();
        exit(CustomerPostingGroup.Code);
    end;

    local procedure GetCompanyName(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation.Name)
    end;

    local procedure MockIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        Customer: Record Customer;
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        IssuedFinChargeMemoHeader.Init();
        IssuedFinChargeMemoHeader.Validate("No.", LibraryUtility.GenerateGUID());
        IssuedFinChargeMemoHeader.Validate("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader."Posting Date" := WorkDate();
        IssuedFinChargeMemoHeader."Document Date" := WorkDate();
        IssuedFinChargeMemoHeader."Due Date" := WorkDate();
        IssuedFinChargeMemoHeader."Customer Posting Group" := FindCustomerPostingGroup();
        IssuedFinChargeMemoHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedFinChargeMemoHeader.Insert(false);

        IssuedFinChargeMemoLine.Init();
        IssuedFinChargeMemoLine."Finance Charge Memo No." := IssuedFinChargeMemoHeader."No.";
        IssuedFinChargeMemoLine."Line No." := LibraryUtility.GetNewRecNo(IssuedFinChargeMemoLine, IssuedFinChargeMemoLine.FieldNo(IssuedFinChargeMemoLine."Line No."));
        IssuedFinChargeMemoLine.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        IssuedFinChargeMemoLine.Type := IssuedFinChargeMemoLine.Type::"Customer Ledger Entry";
        IssuedFinChargeMemoLine.Insert(false);
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        if Customer."E-Mail" = '' then begin
            Customer."E-Mail" := 'a@b.c';
            Customer.Modify();
        end;
        IssuedReminderHeader.Init();
        IssuedReminderHeader.Validate("No.", LibraryUtility.GenerateGUID());
        IssuedReminderHeader.Validate("Customer No.", Customer."No.");
        IssuedReminderHeader."Posting Date" := Today;
        IssuedReminderHeader."Document Date" := Today;
        IssuedReminderHeader."Due Date" := Today;
        IssuedReminderHeader."Customer Posting Group" := FindCustomerPostingGroup();
        IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedReminderHeader.Insert(false);

        IssuedReminderLine.Init();
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Line No." := 1;
        IssuedReminderLine.Amount := 17;
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine.Insert(false);
    end;

    local procedure VerifySubjectAndAttachmentName(ExpectedSubject: Text; ExpectedAttachmentName: Text)
    var
        DialogSubject: Variant;
        AttachmentName: Variant;
    begin
        LibraryVariableStorage.Dequeue(DialogSubject);
        LibraryVariableStorage.Dequeue(AttachmentName);
        Assert.AreEqual(ExpectedSubject, DialogSubject, IncorrectSubjectErr);
        Assert.AreEqual(ExpectedAttachmentName, AttachmentName, IncorrectAttachNameErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ValidateMailDialog(var TestEmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(TestEmailEditor.SubjectField.Value);
        LibraryVariableStorage.Enqueue(TestEmailEditor.Attachments.FileName.Value);
        TestEmailEditor.ToField.Value('recipient@recipient.com');
        TestEmailEditor.Send.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

