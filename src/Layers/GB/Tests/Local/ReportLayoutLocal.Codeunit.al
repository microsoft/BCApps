codeunit 144303 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        isInitialized: Boolean;

#if not CLEAN27
    [Test]
    [HandlerFunctions('RHVATEntryExceptionReport')]
    [Scope('OnPrem')]
    procedure TestVATEntryExceptionReport()
    begin
        Initialize();
        REPORT.Run(REPORT::"VAT Entry Exception Report");
    end;
#endif

    [Test]
    [HandlerFunctions('StandardSalesDraftInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NonZeroReverseChargeVATPctInStandardSalesDraftInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        StandardSalesDraftInvoice: Report "Standard Sales - Draft Invoice";
    begin
        // [SCENARIO 441027] A non-zero VAT percent prints in the "Standard Sales Draft Invoice" report when using Reverse Charge VAT

        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDec(10, 2));
        CreateSalesDocWithVATPostingSetup(SalesHeader, SalesHeader."Document Type"::Invoice, VATPostingSetup);
        SalesHeader.SetRecFilter();
        Commit();
        StandardSalesDraftInvoice.SetTableView(SalesHeader);
        StandardSalesDraftInvoice.Run();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATPct_Line', Format(VATPostingSetup."VAT %"));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NonZeroReverseChargeVATPctInStandardSalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        StandardSalesInvoice: Report "Standard Sales - Invoice";
    begin
        // [SCENARIO 441027] A non-zero VAT percent prints in the "Standard Sales Invoice" report when using Reverse Charge VAT

        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDec(10, 2));
        CreateSalesDocWithVATPostingSetup(SalesHeader, SalesHeader."Document Type"::Invoice, VATPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();
        Commit();
        StandardSalesInvoice.SetTableView(SalesInvoiceHeader);
        StandardSalesInvoice.Run();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATPct_Line', Format(VATPostingSetup."VAT %"));
    end;

    [Test]
    [HandlerFunctions('StandardSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NonZeroReverseChargeVATPctInStandardSalesCrMemoReport()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        VATPostingSetup: Record "VAT Posting Setup";
        StandardSalesCreditMemo: Report "Standard Sales - Credit Memo";
    begin
        // [SCENARIO 441027] A non-zero VAT percent prints in the "Standard Sales Credit Memo" report when using Reverse Charge VAT

        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDec(10, 2));
        CreateSalesDocWithVATPostingSetup(SalesHeader, SalesHeader."Document Type"::"Credit Memo", VATPostingSetup);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();
        Commit();
        StandardSalesCreditMemo.SetTableView(SalesCrMemoHeader);
        StandardSalesCreditMemo.Run();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATPct_Line', Format(VATPostingSetup."VAT %"));
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Get();
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

#if not CLEAN27
    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;
#endif
    local procedure CreateSalesDocWithVATPostingSetup(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATEntryExceptionReport(var VATEntryExceptionReport: TestRequestPage "VAT Entry Exception Report")
    begin
        VATEntryExceptionReport.VATBaseDiscount.SetValue(true);
        VATEntryExceptionReport.ManualVATDifference.SetValue(true);
        VATEntryExceptionReport.VATCalculationTypes.SetValue(true);
        VATEntryExceptionReport.VATRate.SetValue(true);
        VATEntryExceptionReport.SaveAsPdf(FormatFileName(VATEntryExceptionReport.Caption));
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
