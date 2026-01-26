codeunit 147502 "Cartera Paym. Exported Formats"
{
    // Cartera scenarios having as setup open payment orders.
    // The scenarios exercise formats for exported payment orders.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryPOExportN341: Codeunit "Library - PO - Export N34.1";
        LibraryPOExportN34: Codeunit "Library - PO - Export N34";
        DatasetContentErr: Label 'Data could not be found in the report dataset.';
        UnexpectedValueErr: Label 'Unexpecte Value For Field %1 in exported file.';
        UnexpectedAmountOnPaymentOrderErr: Label 'The exported file contains unexpected amount.';
        ExpectedPaymentNotPrinterErr: Label 'The payment order has not been printed.';
        ExpectedErrorTypeTxt: Label 'Warning!';
        LocalCurrencyCode: Code[10];

    [Test]
    [HandlerFunctions('PaymentOrderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentOrderAndRunPaymentOrderTestReport()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        PaymentOrdersTestPage: TestPage "Payment Orders";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Setup
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");
        Commit();

        // Pre-Exercise
        PaymentOrdersTestPage.OpenView();
        PaymentOrdersTestPage.GotoRecord(PaymentOrder);
        PaymentOrdersTestPage."Test Report".Invoke();

        // Verify
        ValidatePaymentOrderTestReport(
          BankAccount, CarteraDoc, PaymentOrder, Vendor, ExpectedPaymentNotPrinterErr, ExpectedErrorTypeTxt);
    end;

    [Test]
    [HandlerFunctions('PaymentOrderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentOrderAndRunPaymentOrderTestReportFromList()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        PaymentOrdersListTestPage: TestPage "Payment Orders List";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Setup
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");
        Commit();

        // Pre-Exercise
        PaymentOrdersListTestPage.OpenView();
        PaymentOrdersListTestPage.GotoRecord(PaymentOrder);
        PaymentOrdersListTestPage.TestReport.Invoke();

        // Verify
        ValidatePaymentOrderTestReport(
          BankAccount, CarteraDoc, PaymentOrder, Vendor, ExpectedPaymentNotPrinterErr, ExpectedErrorTypeTxt);
    end;

    [Test]
    [HandlerFunctions('POExportN341RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportN341PaymentOrderToFile()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ElectPmtsManagement: Codeunit "Elect. Pmts Management";
        DocumentNo: Code[20];
        FileName: Text[1024];
        DocType: Text;
        ExportedAmountFormat: Text[12];
    begin
        Initialize();

        // Pre-Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Setup
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        // Exercise
        FileName := LibraryPOExportN341.RunPOExportN341Report(PaymentOrder."No.");

        DocType := '57';

        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.FindFirst();

        ExportedAmountFormat := ElectPmtsManagement.EuroAmount(CarteraDoc."Remaining Amount");

        // Verify
        ValidateExportedPaymentOrderN341File(
          FileName, BankAccount, DocType, Vendor, VendorBankAccount, ExportedAmountFormat, ExportedAmountFormat, ExportedAmountFormat);
    end;

    [Test]
    [HandlerFunctions('POExportN341RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportN341PaymentOrderToDataset()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        ExpectedNumberOfPaymentOrders: Integer;
    begin
        Initialize();

        // Pre-Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Setup
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        // Pre-Exercise
        LibraryPOExportN341.RunPOExportN341Report(PaymentOrder."No.");

        ExpectedNumberOfPaymentOrders := 1;

        // Verify
        ValidateExportedPaymentOrderN341Dataset(ExpectedNumberOfPaymentOrders, PaymentOrder."No.", CarteraDoc, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('POExportN34RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportN34PaymentOrderToFile()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        DocumentNo: Code[20];
        FileName: Text[1024];
        ExpectedDocAmount: Text[12];
    begin
        Initialize();

        // Pre-Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Setup
        LibraryCarteraPayables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraPayables.UpdateBankAccountWithFormatN34(BankAccount);
        LibraryCarteraPayables.CreatePaymentOrder(PaymentOrder, LocalCurrencyCode, BankAccount."No.");

        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        // Exercise
        FileName := LibraryPOExportN34.RunPOExportN34Report(PaymentOrder."No.");

        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.FindFirst();

        ExpectedDocAmount := LibraryPOExportN34.GetEuroAmountN34Report(CarteraDoc."Remaining Amount");

        ValidateExportedPaymentOrderN34File(FileName, BankAccount, Vendor, VendorBankAccount, ExpectedDocAmount);
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentOrderTestRequestPageHandler(var TestReportRequestPage: TestRequestPage "Payment Order - Test")
    begin
        TestReportRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure POExportN341RequestPageHandler(var POExportN341: TestRequestPage "PO - Export N34.1")
    begin
        POExportN341.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure POExportN34RequestPageHandler(var POExportN34: TestRequestPage "Payment order - Export N34")
    begin
        POExportN34.OK().Invoke();
    end;

    local procedure PrepareVendorRelatedRecords(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
    end;

    local procedure ValidateExportedPaymentOrderN341File(FileName: Text[1024]; BankAccount: Record "Bank Account"; DocType: Text; Vendor: Record Vendor; VendorBankAccount: Record "Vendor Bank Account"; ExportedPartialAmount: Text[12]; ExportedInterimAmount: Text[12]; ExportedTotalAmount: Text[12])
    var
        LibraryPOExportN341: Codeunit "Library - PO - Export N34.1";
        ActualVendorBankAccountNo: Text[4];
        ActualVendorNo: Code[10];
        ActualBankAccountNo: Text[4];
        ActualDocType: Text;
        ActualExportedAmount: Text;
        ActualTotalAmount: Text;
        ActualInterimAmount: Text;
    begin
        ActualBankAccountNo := LibraryPOExportN341.GetBankAccNo(FileName);
        Assert.AreEqual(
          BankAccount."CCC Bank No.", ActualBankAccountNo, StrSubstNo(UnexpectedValueErr, BankAccount.FieldCaption("CCC Bank No.")));

        ActualDocType := LibraryPOExportN341.GetDocType(FileName);
        Assert.AreEqual(DocType, ActualDocType, StrSubstNo(UnexpectedValueErr, 'Transfer Type : Domestic'));

        ActualVendorBankAccountNo := LibraryPOExportN341.GetVendorBankAccNo(FileName);
        Assert.AreEqual(
          VendorBankAccount."CCC Bank No.", ActualVendorBankAccountNo,
          StrSubstNo(UnexpectedValueErr, VendorBankAccount.FieldCaption("CCC Bank No.")));

        ActualVendorNo := LibraryPOExportN341.GetVendorNo(FileName);
        Assert.AreEqual(CopyStr(Vendor."No.", 1, 6), ActualVendorNo, StrSubstNo(UnexpectedValueErr, Vendor.FieldCaption("No.")));

        ActualExportedAmount := LibraryPOExportN341.GetPartialExportedAmount(FileName);
        Assert.AreEqual(ExportedPartialAmount, ActualExportedAmount, UnexpectedAmountOnPaymentOrderErr);

        ActualInterimAmount := LibraryPOExportN341.GetExportedInterimAmount(FileName);
        Assert.AreEqual(ExportedInterimAmount, ActualInterimAmount, UnexpectedAmountOnPaymentOrderErr);

        ActualTotalAmount := LibraryPOExportN341.GetExportedTotalAmount(FileName);
        Assert.AreEqual(ExportedTotalAmount, ActualTotalAmount, UnexpectedAmountOnPaymentOrderErr);
    end;

    local procedure ValidateExportedPaymentOrderN341Dataset(NumberOfPaymentOrders: Integer; PaymentOrderNo: Code[20]; CarteraDoc: Record "Cartera Doc."; VendorNo: Code[20])
    var
        ReportPaymentOrderNo: Variant;
        ReportVendorNo: Variant;
        ReportCarteraDocType: Variant;
        ReportLedgerEntryNo: Variant;
        ReportExportAmount: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();

        Assert.AreEqual(NumberOfPaymentOrders, LibraryReportDataset.RowCount(), DatasetContentErr);

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('Payment_Order_No_', ReportPaymentOrderNo);
        Assert.AreEqual(PaymentOrderNo, ReportPaymentOrderNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('PayeeAddress_1_', ReportVendorNo);
        Assert.AreEqual(VendorNo, ReportVendorNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('Cartera_Doc__Type', ReportCarteraDocType);
        Assert.AreEqual(Format(CarteraDoc.Type), ReportCarteraDocType, '');

        LibraryReportDataset.GetElementValueInCurrentRow('Cartera_Doc__Entry_No_', ReportLedgerEntryNo);
        Assert.AreEqual(CarteraDoc."Entry No.", ReportLedgerEntryNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('Cartera_Doc__Account_No_', ReportVendorNo);
        Assert.AreEqual(VendorNo, ReportVendorNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('Cartera_Doc__Bill_Gr__Pmt__Order_No_', ReportPaymentOrderNo);
        Assert.AreEqual(PaymentOrderNo, ReportPaymentOrderNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('ExportAmount', ReportExportAmount);
        Assert.AreEqual(CarteraDoc."Remaining Amount", ReportExportAmount, '');
    end;

    local procedure ValidateExportedPaymentOrderN34File(FileName: Text[1024]; BankAccount: Record "Bank Account"; Vendor: Record Vendor; VendorBankAccount: Record "Vendor Bank Account"; ExpectedDocAmount: Text[12])
    var
        ActualBankAccountNo: Text[10];
        ActualBankNo: Text[4];
        ActualBankControlDigits: Text[2];
        ActualVendorNo: Code[10];
        ActualVendorBankAccNo: Text[10];
        ActualVendorBankNo: Text[4];
        ActualDocAmount: Text[12];
    begin
        ActualBankAccountNo := LibraryPOExportN34.GetBankAccNo(FileName);
        Assert.AreEqual(BankAccount."CCC Bank Account No.", ActualBankAccountNo,
          StrSubstNo(UnexpectedValueErr, BankAccount.FieldCaption("CCC Bank Account No.")));

        ActualBankNo := LibraryPOExportN34.GetBankNo(FileName);
        Assert.AreEqual(BankAccount."CCC Bank No.", ActualBankNo,
          StrSubstNo(UnexpectedValueErr, BankAccount.FieldCaption("CCC Bank No.")));

        ActualBankControlDigits := LibraryPOExportN34.GetBankControlDigits(FileName);
        Assert.AreEqual(BankAccount."CCC Control Digits", ActualBankControlDigits,
          StrSubstNo(UnexpectedValueErr, BankAccount.FieldCaption("CCC Control Digits")));

        ActualVendorNo := LibraryPOExportN34.GetVendorNo(FileName);
        Assert.AreEqual(Vendor."No.", ActualVendorNo, StrSubstNo(UnexpectedValueErr, Vendor.FieldCaption("No.")));

        ActualVendorBankAccNo := LibraryPOExportN34.GetVendorBankAccNo(FileName);
        Assert.AreEqual(VendorBankAccount."CCC Bank Account No.", ActualVendorBankAccNo,
          StrSubstNo(UnexpectedValueErr, VendorBankAccount.FieldCaption("CCC Bank Account No.")));

        ActualVendorBankNo := LibraryPOExportN34.GetVendorBankNo(FileName);
        Assert.AreEqual(VendorBankAccount."CCC Bank No.", ActualVendorBankNo,
          StrSubstNo(UnexpectedValueErr, VendorBankAccount.FieldCaption("CCC Bank No.")));

        ActualDocAmount := LibraryPOExportN34.GetTotalDocAmount(FileName);
        Assert.AreEqual(ExpectedDocAmount, ActualDocAmount, UnexpectedAmountOnPaymentOrderErr);
    end;

    local procedure ValidatePaymentOrderTestReport(BankAccount: Record "Bank Account"; CarteraDoc: Record "Cartera Doc."; PaymentOrder: Record "Payment Order"; Vendor: Record Vendor; ExpectedErrorText: Text; ExpectedErrorType: Text)
    var
        ExpectedNumberOfRecords: Variant;
        ReportPaymentOrderNo: Variant;
        ReportBankAccountNo: Variant;
        ReportCompanyName: Variant;
        ReportErrorText: Variant;
        ReportErrorType: Variant;
        ReportRemainingAmount: Variant;
        ReportVendorNo: Variant;
        ReportDocumentNo: Variant;
        ReportAmount: Variant;
        ReportBillGroupBankAccountNo: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();

        ExpectedNumberOfRecords := 4;
        Assert.AreEqual(ExpectedNumberOfRecords, LibraryReportDataset.RowCount(), DatasetContentErr);

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('PmtOrd_No_', ReportPaymentOrderNo);
        Assert.AreEqual(ReportPaymentOrderNo, PaymentOrder."No.", '');

        LibraryReportDataset.GetElementValueInCurrentRow('PmtOrd_Bank_Account_No_', ReportBankAccountNo);
        Assert.AreEqual(ReportBankAccountNo, BankAccount."No.", '');

        LibraryReportDataset.GetElementValueInCurrentRow('COMPANYNAME', ReportCompanyName);
        Assert.AreEqual(ReportCompanyName, COMPANYPROPERTY.DisplayName(), '');

        LibraryReportDataset.GetElementValueInCurrentRow('ErrorText_Number_', ReportErrorText);
        Assert.AreEqual(ReportErrorText, ExpectedErrorText, '');

        LibraryReportDataset.GetElementValueInCurrentRow('ErrorText_Number_Caption', ReportErrorType);
        Assert.AreEqual(ReportErrorType, ExpectedErrorType, '');

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('Doc__Account_No__', ReportVendorNo);
        Assert.AreEqual(ReportVendorNo, Vendor."No.", '');

        LibraryReportDataset.GetElementValueInCurrentRow('Doc__Remaining_Amount_', ReportRemainingAmount);
        Assert.AreEqual(ReportRemainingAmount, CarteraDoc."Remaining Amount", '');

        LibraryReportDataset.GetElementValueInCurrentRow('Doc__Document_No__', ReportDocumentNo);
        Assert.AreEqual(ReportDocumentNo, CarteraDoc."Document No.", '');

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('PmtOrd_Amount', ReportAmount);
        Assert.AreEqual(ReportAmount, CarteraDoc."Original Amount", '');

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('BillGrBankAcc__No__', ReportBillGroupBankAccountNo);
        Assert.AreEqual(ReportBillGroupBankAccountNo, BankAccount."No.", '');
    end;
}

