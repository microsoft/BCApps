codeunit 144001 "Tax Document Report Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Report Caption] [Tax Invoice Threshold]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        InvoiceTxt: Label 'Invoice';
        TaxInvoiceTxt: Label 'Tax Invoice';
        PrepmtTaxInvoiceTxt: Label 'Prepayment Tax Invoice';
        ServiceInvoiceTxt: Label 'Service - Invoice %1';
        ServiceTaxInvoiceTxt: Label 'Service - Tax Invoice %1';
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T020_ThresholdIsEditableOnGLSetupPage()
    var
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        GeneralLedgerSetupPage.OpenEdit();
        Assert.IsTrue(GeneralLedgerSetupPage."Tax Invoice Renaming Threshold".Visible(), 'Tax Invoice Renaming Threshold is not visible');
        Assert.IsTrue(GeneralLedgerSetupPage."Tax Invoice Renaming Threshold".Editable(), 'Tax Invoice Renaming Threshold is not editable');
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T110_CaptionStdSalesInvoiceIfAmountIs1000()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Sales] [Invoice]
        // [SCENARIO] Report caption is 'Invoice' if document's total amount is equal to "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.00
        SetTaxInvoiceThreshold(1000.0);
        // [GIVEN] Posted Sales Invoice, where "Amount Incl. VAT" is 1000.00.
        SalesInvoiceHeader.Get(PostSalesInvoiceLCY(1000));

        // [WHEN] Print report "Standard Sales - Invoice"
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Invoice'
        VerifyReportCaption('DocumentTitle_Lbl', InvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T111_CaptionStdSalesTaxInvoiceIfAmountMoreThan1000()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Sales] [Invoice]
        // [SCENARIO] Report caption is 'Tax Invoice' if document's total amount is above "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.00
        SetTaxInvoiceThreshold(1000.0);
        // [GIVEN] Posted Sales Invoice, where "Amount Incl. VAT" is 1000.01.
        SalesInvoiceHeader.Get(PostSalesInvoiceLCY(1000.01));

        // [WHEN] Print report "Standard Sales - Invoice"
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Tax Invoice'
        VerifyReportCaption('DocumentTitle_Lbl', TaxInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T112_CaptionStdSalesPrepmtTaxInvoiceIfAmountMoreThan1000()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Sales] [Invoice] [Prepayment]
        // [SCENARIO] Report caption is 'Prepayment Tax Invoice' if prepayment total amount is above "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.00
        SetTaxInvoiceThreshold(1000.0);
        // [GIVEN] Posted Sales Prepayment Invoice, where "Amount Incl. VAT" is 1000.01.
        SalesInvoiceHeader.Get(PostSalesInvoiceLCY(1000.01));
        SalesInvoiceHeader."Prepayment Invoice" := true;
        SalesInvoiceHeader.Modify();
        Commit();

        // [WHEN] Print report "Standard Sales - Invoice"
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Tax Invoice'
        VerifyReportCaption('DocumentTitle_Lbl', PrepmtTaxInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T113_CaptionStdSalesTaxInvoiceInFCYIfLCYAmountMoreThan1000()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Sales] [Invoice] [FCY]
        // [SCENARIO] Report caption is 'Tax Invoice' if FCY document's total amount in LCY is above "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.01
        SetTaxInvoiceThreshold(1000.01);
        // [GIVEN] Posted Sales Invoice in FCY, where "Amount Incl. VAT" is 500.01 (= NZD1000.02).
        SalesInvoiceHeader.Get(PostSalesInvoice(0.5, 500.01));

        // [WHEN] Print report "Standard Sales - Invoice"
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Tax Invoice'
        VerifyReportCaption('DocumentTitle_Lbl', TaxInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T200_CaptionServiceInvoiceIfAmountIs1000()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO] Report caption is 'Service - Invoice' if document's total amount is equal to "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.00
        SetTaxInvoiceThreshold(1000.0);
        // [GIVEN] Posted Service Invoice, where "Amount Incl. VAT" is 1000.00.
        ServiceInvoiceHeader.Get(PostServiceInvoice(1000));

        // [WHEN] Print report "Service - Invoice"
        ServiceInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] Report title is 'Service - Invoice'
        VerifyReportCaption('ReportTitleCopyText', StrSubstNo(ServiceInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure T201_CaptionServiceTaxInvoiceIfAmountMoreThan1000()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO] Report caption is 'Service - Tax Invoice' if document's total amount is above "Tax Invoice Threshold Amount".
        Initialize();
        // [GIVEN] "Tax Invoice Threshold Amount" is 1000.00
        SetTaxInvoiceThreshold(1000.0);
        // [GIVEN] Posted Service Invoice, where "Amount Incl. VAT" is 1000.01.
        ServiceInvoiceHeader.Get(PostServiceInvoice(1000.01));

        // [WHEN] Print report "Service - Invoice"
        ServiceInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] Report title is 'Service - Tax Invoice'
        VerifyReportCaption('ReportTitleCopyText', StrSubstNo(ServiceTaxInvoiceTxt, ''));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure PostSalesInvoice(CurrencyFactor: Decimal; TotalAmount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        if CurrencyFactor <> 1 then
            SalesHeader.Validate(
              "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor));
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", TotalAmount);
        SalesLine.Modify();

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostSalesInvoiceLCY(TotalAmount: Decimal): Code[20]
    begin
        exit(PostSalesInvoice(1, TotalAmount));
    end;

    local procedure PostServiceInvoice(TotalAmount: Decimal): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify();
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        ServiceLine.Validate("Unit Price", TotalAmount);
        ServiceLine.Modify();

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindLast();
        ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure SetTaxInvoiceThreshold(ThresholdAmont: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Tax Invoice Renaming Threshold", ThresholdAmont);
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyReportCaption(CaptionName: Text; ExpectedValue: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals(CaptionName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

