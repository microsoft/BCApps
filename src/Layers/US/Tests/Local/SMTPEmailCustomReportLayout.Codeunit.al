codeunit 144055 "SMTPEMail Custom Report Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EMail] [Custom Layout] [Report Selection]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryvariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TestClientTypeMgtSubscriber: Codeunit "Test Client Type Subscriber";
        IsInitialized: Boolean;
        TargetEmailAddressErr: Label 'The target email address has not been specified';
        NoDataOutputErr: Label 'No data exists for the specified report filters.';
        LessErrorsOnErrorMessagesPageErr: Label '%1 contains less errors than expected.';
        MoreErrorsOnErrorMessagesPageErr: Label '%1 contains more errors than expected.';

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        ErrorMessages.Trap();
        BindSubscription(LibraryTempNVBufferHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_NoEmail_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        ErrorMessages.Trap();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_Email_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        ErrorMessages.Trap();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_Email_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = true.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_NoEmail_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = true.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_Email_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = true.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPayments_A_Email_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Export Electronic Payments" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = true.
        Initialize();

        ReportID := GetExportElectronicPaymentsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        ErrorMessages.Trap();
        BindSubscription(LibraryTempNVBufferHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_NoEmail_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        ErrorMessages.Trap();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_Email_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        ErrorMessages.Trap();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_Email_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, false);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_NoEmail_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, '');
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_Email_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, '');

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_A_Email_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: array[2] of Record "Vendor";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "ExportElecPayments - Word" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetExportElecPaymentsWordReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"V.Remittance");

        CreateVendorWithDocumentLayout(
          Vendor[1], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateVendorWithDocumentLayout(
          Vendor[2], CustomReportSelection.Usage::"V.Remittance", ReportID, LibraryUtility.GenerateRandomEmail());

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        CreateAndExportPaymentJournal(Vendor, true);

        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Vendor[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, '');
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, '');

        PostSalesInvoices(Customer);

        BindSubscription(LibraryTempNVBufferHandler);

        ErrorMessages.Trap();
        RunCustomerStatementsWithError(Customer, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_NoEmail_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, '');
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());

        PostSalesInvoices(Customer);

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        ErrorMessages.Trap();
        RunCustomerStatementsWithError(Customer, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_Email_B_NoEmail_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        TempErrorMessage: Record "Error Message" temporary;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, '');

        PostSalesInvoices(Customer);

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        ErrorMessages.Trap();
        RunCustomerStatementsWithError(Customer, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);

        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_Email_B_Email_PrintIfEmailIsMissing_FALSE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());

        PostSalesInvoices(Customer);

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        RunCustomerStatements(Customer, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_NoEmail_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" without email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, '');
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, '');

        PostSalesInvoices(Customer);

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);

        RunCustomerStatements(Customer, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_NoEmail_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" without email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, '');
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());

        PostSalesInvoices(Customer);

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        RunCustomerStatements(Customer, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_Email_B_NoEmail_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" with email, "B" without email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, '');

        PostSalesInvoices(Customer);

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        RunCustomerStatements(Customer, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatements_A_Email_B_Email_PrintIfEmailIsMissing_TRUE();
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: array[2] of Record "Customer";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ReportID: Integer;
    begin
        // [SCENARIO 325097] Email "Customer - Statements" For two vendors: "A" with email, "B" with email. "PrintIfEmailIsMissing" = false;.
        Initialize();

        ReportID := GetCustomerStatementsReportID();

        InsertReportSelections(ReportSelections, ReportID, false, false, ReportSelections.Usage::"C.Statement");

        CreateCustomerWithDocumentLayout(
          Customer[1], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());
        CreateCustomerWithDocumentLayout(
          Customer[2], CustomReportSelection.Usage::"C.Statement", ReportID, LibraryUtility.GenerateRandomEmail());

        PostSalesInvoices(Customer);

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        RunCustomerStatements(Customer, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[1]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertEntry(Customer[2]."No.");
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    local procedure Initialize();
    var
        LibraryEmail: Codeunit "Library - Email";
    begin
        LibrarySetupStorage.Restore();
        LibraryEmail.SetUpEmailAccount();

        if IsInitialized then
            exit;

        IsInitialized := true;

        SetFederalIdInCompanyInFormation(LibraryUtility.GenerateGUID());

        TestClientTypeMgtSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeMgtSubscriber);

        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        LibrarySetupStorage.Save(DATABASE::"Company InFormation");
    end;

    local procedure AddExpectedErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ErrorMessage: Text);
    begin
        Assert.IsTrue(TempErrorMessage.ISTEMPORARY, 'Error message record must be temporary');
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, ErrorMessage);
    end;

    local procedure CreateAndExportPaymentJournal(var Vendor: array[2] of Record "Vendor"; PrintIfEMailIsMissing: Boolean);
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentJournal: TestPage "Payment Journal";
        Index: Integer;
        DocAmount: Integer;
        DocumentNo: Code[20];
    begin
        CreateGeneralJournalBatch(GenJournalBatch, CreateAndModifyBankAccount());

        for Index := 1 to ARRAYLEN(Vendor) do begin
            LibraryERM.CreateBankAccount(BankAccount);
            LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor[Index]."No.");

            VendorBankAccount.Validate("Bank Account No.", BankAccount."No.");
            VendorBankAccount.Validate("Use For Electronic Payments", true);
            VendorBankAccount.Modify(true);

            DocAmount := LibraryRandom.RandIntInRange(100, 200);

            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor[Index]."No.");
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
            PurchaseLine.Validate("Direct Unit Cost", DocAmount);
            PurchaseLine.Modify(true);

            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            CreatePaymentJournal(
              GenJournalLine, GenJournalBatch, DocumentNo,
              GenJournalLine."Account Type"::Vendor, Vendor[Index]."No.",
              DocAmount, VendorBankAccount.Code);

            GenJournalLine.Validate("Transaction Type Code", GenJournalLine."Transaction Type Code"::BUS);
            GenJournalLine.Validate("Transaction Code", COPYSTR(LibraryUtility.GenerateGUID(), 1, 3));
            GenJournalLine.Validate("Company Entry Description", LibraryUtility.GenerateGUID());
            GenJournalLine.Modify(true);
        end;

        Commit();

        LibraryvariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryvariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryvariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryvariableStorage.Enqueue('Email');
        LibraryvariableStorage.Enqueue(PrintIfEMailIsMissing);

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        LibraryvariableStorage.AssertEmpty();
    end;

    local procedure CreateAndModifyBankAccount(): Code[20];
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, LibraryUtility.GenerateGUID(), BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Input Qualifier", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; TransitNo: Code[20]; ExportFormat: Option);
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Export Format", ExportFormat);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Remittance Advice No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("E-Pay Export File Path", TEMPORARYPATH);
        BankAccount.Validate("E-Pay Trans. Program Path", '.\\');
        BankAccount.Validate("Last E-Pay Export File Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Transit No.", TransitNo);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20]);
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FIELDNO(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-EFT";
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();

        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
    end;

    local procedure CreateCustomerWithDocumentLayout(var Customer: Record "Customer"; ReportUsage: Enum "Report Selection Usage"; ReportID: Integer; Email: Text[200]);
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        LibrarySales.CreateCustomer(Customer);
        InsertCustomReportSelectionCustomer(CustomReportSelection, Customer, ReportID, false, false, Email, ReportUsage);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20]);
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        GenJournalBatch.Modify();
    end;

    local procedure CreatePaymentJournal(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AppliesToDocNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; RecipientBankAccoutCode: Code[20]);
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);

        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");

        GenJournalLine.Validate("Recipient Bank Account", RecipientBankAccoutCode);

        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendorWithDocumentLayout(var Vendor: Record "Vendor"; ReportUsage: Enum "Report Selection Usage"; ReportID: Integer; Email: Text[200]);
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        InsertCustomReportSelectionVendor(CustomReportSelection, Vendor, ReportID, false, false, Email, ReportUsage);
    end;

    local procedure PostSalesInvoices(var Customer: array[2] of Record "Customer");
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Index: Integer;
    begin
        for Index := 1 to ARRAYLEN(Customer) do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer[Index]."No.");
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        Commit();
    end;

    local procedure ExportPaymentJournal(var PaymentJournal: TestPage "Payment Journal"; var GenJournalLine: Record 81);
    begin
        Commit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ExportPaymentsToFile.Invoke();
    end;

    local procedure GetCustomerStatementsReportID(): Integer;
    begin
        exit(REPORT::"Customer Statements");
    end;

    local procedure GetExportElectronicPaymentsReportID(): Integer;
    begin
        exit(REPORT::"Export Electronic Payments");
    end;

    local procedure GetExportElecPaymentsWordReportID(): Integer;
    begin
        exit(REPORT::"ExportElecPayments - Word");
    end;

    local procedure GetBuiltInLayoutCode(ReportID: Integer): Code[20];
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutType: Enum "Custom Report Layout Type";
    begin
        case ReportID of
            GetExportElecPaymentsWordReportID():
                CustomReportLayoutType := CustomReportLayout.Type::Word;
            else
                CustomReportLayoutType := CustomReportLayout.Type::RDLC;
        end;

        CustomReportLayout.SetRange("Built-In", true);
        CustomReportLayout.SetRange(Type, CustomReportLayoutType);
        CustomReportLayout.SetRange("Report ID", ReportID);
        if NOT CustomReportLayout.FindFirst() then
            CustomReportLayout.GET(CustomReportLayout.InitBuiltInLayout(ReportID, CustomReportLayoutType.AsInteger()));

        exit(CustomReportLayout.Code);
    end;

    local procedure InsertCustomReportSelectionVendor(var CustomReportSelection: Record "Custom Report Selection"; Vendor: Record "Vendor"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage");
    begin
        CustomReportSelection.SetRange("Source No.", Vendor."No.");
        CustomReportSelection.SetRange("Report ID", ReportID);
        CustomReportSelection.SetRange(Usage, ReportUsage);
        CustomReportSelection.DeleteAll();

        CustomReportSelection.Init();
        CustomReportSelection.Validate("Source Type", DATABASE::Vendor);
        CustomReportSelection.Validate("Source No.", Vendor."No.");
        CustomReportSelection.Validate(Usage, ReportUsage);
        CustomReportSelection.Validate(Sequence, CustomReportSelection.COUNT + 1);
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Use For Email Attachment", UseForEmailAttachment);
        if CustomReportSelection."Use For Email Attachment" then
            CustomReportSelection.Validate("Custom Report Layout Code", GetBuiltInLayoutCode(ReportID));
        CustomReportSelection.Validate("Use For Email Body", UseForEmailBody);
        if CustomReportSelection."Use For Email Body" then
            CustomReportSelection.Validate("Email Body Layout Code", GetBuiltInLayoutCode(ReportID));
        CustomReportSelection.Validate("Send To Email", SendToAddress);
        CustomReportSelection.Insert(true);
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; Customer: Record "Customer"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage");
    begin
        CustomReportSelection.SetRange("Source No.", Customer."No.");
        CustomReportSelection.SetRange("Report ID", ReportID);
        CustomReportSelection.SetRange(Usage, ReportUsage);
        CustomReportSelection.DeleteAll();

        CustomReportSelection.Init();
        CustomReportSelection.Validate("Source Type", DATABASE::Customer);
        CustomReportSelection.Validate("Source No.", Customer."No.");
        CustomReportSelection.Validate(Usage, ReportUsage);
        CustomReportSelection.Validate(Sequence, CustomReportSelection.COUNT + 1);
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Use For Email Attachment", UseForEmailAttachment);
        if CustomReportSelection."Use For Email Attachment" then
            CustomReportSelection.Validate("Custom Report Layout Code", GetBuiltInLayoutCode(ReportID));
        CustomReportSelection.Validate("Use For Email Body", UseForEmailBody);
        if CustomReportSelection."Use For Email Body" then
            CustomReportSelection.Validate("Email Body Layout Code", GetBuiltInLayoutCode(ReportID));
        CustomReportSelection.Validate("Send To Email", SendToAddress);
        CustomReportSelection.Insert(true);
    end;

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; ReportUsage: Enum "Report Selection Usage");
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportUsage);
        ReportSelections.Validate(Sequence, '1');
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Validate("Use For Email Attachment", UseForEmailAttachment);
        if ReportSelections."Use For Email Attachment" then
            ReportSelections.Validate("Custom Report Layout Code", GetBuiltInLayoutCode(ReportID));
        ReportSelections.Validate("Use For Email Body", UseForEmailBody);
        if ReportSelections."Use For Email Body" then
            ReportSelections.Validate("Email Body Layout Code", GetBuiltInLayoutCode(ReportID));
        ReportSelections.Insert(true);
    end;

    local procedure RunCustomerStatements(var Customer: array[2] of Record "Customer"; PrintIfEmailIsMissing: Boolean);
    var
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
    begin
        LibraryvariableStorage.Enqueue(STRSUBSTNO('%1|%2', Customer[1]."No.", Customer[2]."No."));
        LibraryvariableStorage.Enqueue(3); // Email
        LibraryvariableStorage.Enqueue(PrintIfEmailIsMissing);

        CustomerLayoutStatement.RunReport();

        LibraryvariableStorage.AssertEmpty();
    end;

    local procedure RunCustomerStatementsWithError(var Customer: array[2] of Record "Customer"; PrintIfEmailIsMissing: Boolean);
    var
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
    begin
        LibraryvariableStorage.Enqueue(STRSUBSTNO('%1|%2', Customer[1]."No.", Customer[2]."No."));
        LibraryvariableStorage.Enqueue(3); // Email
        LibraryvariableStorage.Enqueue(PrintIfEmailIsMissing);

        ASSERTERROR CustomerLayoutStatement.RunReport();

        LibraryvariableStorage.AssertEmpty();
    end;

    local procedure SetFederalIdInCompanyInFormation(FederalId: Text[30]);
    var
        CompanyInFormation: Record "Company Information";
    begin
        CompanyInFormation.Get();
        CompanyInFormation.Validate("Federal ID No.", FederalId);
        CompanyInFormation.Modify(true);
    end;

    local procedure AssertErrorsOnErrorMessagesPage(ErrorMessages: TestPage "Error Messages"; var TempErrorMessage: Record "Error Message" temporary);
    var
        Stop: Boolean;
    begin
        TempErrorMessage.FindSet();
        repeat
            Assert.ExpectedMessage(TempErrorMessage."Message", ErrorMessages.Description.Value);
            ErrorMessages."Message Type".AssertEquals(TempErrorMessage."Message Type");
            Stop := TempErrorMessage.Next() = 0;
            if NOT Stop then
                Assert.IsTrue(ErrorMessages.Next(), STRSUBSTNO(LessErrorsOnErrorMessagesPageErr, ErrorMessages.CAPTION));
        until Stop;

        Assert.IsFalse(ErrorMessages.Next(), STRSUBSTNO(MoreErrorsOnErrorMessagesPageErr, ErrorMessages.CAPTION));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments");
    begin
        ExportElectronicPayments.BankAccountNo.SetValue(LibraryvariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryvariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryvariableStorage.DequeueText());
        ExportElectronicPayments.OutputMethod.SetValue(LibraryvariableStorage.DequeueText());
        ExportElectronicPayments.PrintMissingAddresses.SetValue(LibraryvariableStorage.DequeueBoolean());
        ExportElectronicPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWordRequestPageHandler(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word");
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryvariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryvariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryvariableStorage.DequeueText());
        ExportElecPaymentsWord.OutputMethod.SetValue(LibraryvariableStorage.DequeueText());
        ExportElecPaymentsWord.PrintMissingAddresses.SetValue(LibraryvariableStorage.DequeueBoolean());
        ExportElecPaymentsWord.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerStatementsRequestPageHandler(var CustomerStatements: TestRequestPage "Customer Statements");
    begin
        CustomerStatements.Customer.SetFilter("Date Filter", ForMAT(WorkDate()));
        CustomerStatements.Customer.SetFilter("No.", LibraryvariableStorage.DequeueText());
        CustomerStatements.ReportOutput.SetValue(LibraryvariableStorage.DequeueInteger());
        CustomerStatements.PrintMissingAddresses.SetValue(LibraryvariableStorage.DequeueBoolean());
        CustomerStatements.OK().Invoke();
    end;
}

