codeunit 144512 "ERM Calculate VAT per Lines"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        IsInitialized: Boolean;
        IncorrectFieldValueErr: Label 'Field %1 has incorrect value';

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesDocCalcVATPerLineStatLCY()
    begin
        CheckSalesStatistics('');
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesDocCalcVATPerLineStatFCY()
    begin
        CheckSalesStatistics(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocCalcVATPerLineFacturaLCY()
    begin
        SalesDocCalcVATPerLineFactura('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocCalcVATPerLineFacturaFCY()
    begin
        SalesDocCalcVATPerLineFactura(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesDocCalcVATPerLineStatLCY()
    begin
        PostAndCheckSalesStatistics('');
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesDocCalcVATPerLineStatFCY()
    begin
        PostAndCheckSalesStatistics(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesDocCalcVATPerLineFacturaLCY()
    begin
        PostedSalesDocCalcVATPerLineFactura('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesDocCalcVATPerLineFacturaFCY()
    begin
        PostedSalesDocCalcVATPerLineFactura(CreateCurrencyWithExchangeRate());
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateSalesLineWUnitPrice(SalesHeader: Record "Sales Header"; UnitPrice: Decimal; Qty: Decimal; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PricesInclVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
    end;

    local procedure SetupSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. VAT per Line", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PrepareVerificationAmounts()
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(52.43);
        LibraryVariableStorage.Enqueue(343.75);
        LibraryVariableStorage.Enqueue(52.43);
    end;

    local procedure RestoreVerificationAmounts(var VATAmount: Variant; var TotalInclVAT: Variant)
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalInclVAT);
    end;

    local procedure CreateReleaseSalesDocument(CurrencyCode: Code[10]; var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        UnitPrices: array[3] of Decimal;
        Counter: Integer;
    begin
        Initialize();
        SetupSalesReceivablesSetup();

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2018());
        ItemNo := LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesHeader(SalesHeader, CustomerNo, false);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        SetUnitPriceValues(UnitPrices);
        for Counter := 1 to ArrayLen(UnitPrices) do
            CreateSalesLineWUnitPrice(SalesHeader, UnitPrices[Counter], 1, ItemNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        PrepareVerificationAmounts();
    end;

    local procedure CheckSalesStatistics(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LCYFieldValues: array[6] of Decimal;
        Counter: Integer;
    begin
        CreateReleaseSalesDocument(CurrencyCode, SalesHeader);
        Counter := 1;
        PAGE.RunModal(PAGE::"Sales Statistics", SalesHeader);

        if CurrencyCode <> '' then begin
            SetLCYFieldValues(LCYFieldValues);
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.FindSet();
            repeat
                Assert.AreEqual(LCYFieldValues[Counter], SalesLine."Amount (LCY)",
                  StrSubstNo(IncorrectFieldValueErr, SalesLine.FieldCaption("Amount (LCY)")));
                Assert.AreEqual(LCYFieldValues[Counter + 1], SalesLine."Amount Including VAT (LCY)",
                  StrSubstNo(IncorrectFieldValueErr, SalesLine.FieldCaption("Amount Including VAT (LCY)")));
                Counter += 2;
            until SalesLine.Next() = 0;
        end;
    end;

    local procedure PostAndCheckSalesStatistics(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        LCYFieldValues: array[6] of Decimal;
        Counter: Integer;
    begin
        CreateReleaseSalesDocument(CurrencyCode, SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(DocumentNo);
        PAGE.RunModal(PAGE::"Sales Invoice Statistics", SalesInvoiceHeader);

        Counter := 1;
        if CurrencyCode <> '' then begin
            SetLCYFieldValues(LCYFieldValues);
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            SalesInvoiceLine.FindSet();
            repeat
                Assert.AreEqual(LCYFieldValues[Counter], SalesInvoiceLine."Amount (LCY)",
                  StrSubstNo(IncorrectFieldValueErr, SalesInvoiceLine.FieldCaption("Amount (LCY)")));
                Assert.AreEqual(LCYFieldValues[Counter + 1], SalesInvoiceLine."Amount Including VAT (LCY)",
                  StrSubstNo(IncorrectFieldValueErr, SalesInvoiceLine.FieldCaption("Amount Including VAT (LCY)")));
                Counter += 2;
            until SalesInvoiceLine.Next() = 0;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATAmount: Variant;
        TotalInclVAT: Variant;
    begin
        RestoreVerificationAmounts(VATAmount, TotalInclVAT);

        SalesStatistics.VATAmount.AssertEquals(VATAmount);
        SalesStatistics.TotalAmount2.AssertEquals(TotalInclVAT);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsHandler(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics")
    var
        VATAmount: Variant;
        AmountInclVAT: Variant;
    begin
        RestoreVerificationAmounts(VATAmount, AmountInclVAT);

        SalesInvoiceStatistics.VATAmount.AssertEquals(VATAmount);
        SalesInvoiceStatistics.AmountInclVAT.AssertEquals(AmountInclVAT);
    end;

    local procedure SetUnitPriceValues(var UnitPrices: array[3] of Decimal)
    begin
        // Values below give a difference when Calc. VAT Per Line is TRUE/FALSE
        // along with non-trivial multiline calculations case and allow to bypass
        // programming calculation of correct values
        UnitPrices[1] := 124.85;
        UnitPrices[2] := 41.62;
        UnitPrices[3] := 124.85;
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        CreateExchangeRate(Currency.Code, WorkDate());
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);

        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", 34.31);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 34.31);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure SetLCYFieldValues(var LCYFieldValues: array[6] of Decimal)
    begin
        LCYFieldValues[1] := 4283.6;
        LCYFieldValues[2] := 5054.55;
        LCYFieldValues[3] := 1427.99;
        LCYFieldValues[4] := 1684.96;
        LCYFieldValues[5] := 4283.6;
        LCYFieldValues[6] := 5054.55;
    end;

    local procedure FacturaInvoiceExcelExport(SalesHeader: Record "Sales Header")
    var
        OrderFacturaInvoice: Report "Order Factura-Invoice (A)";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(SalesHeader."No.");
        FileName := LibraryReportValidation.GetFileName();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        OrderFacturaInvoice.SetTableView(SalesHeader);
        OrderFacturaInvoice.InitializeRequest(1, 1, false, false, false);
        OrderFacturaInvoice.SetFileNameSilent(FileName);
        OrderFacturaInvoice.UseRequestPage(false);
        OrderFacturaInvoice.Run();
    end;

    local procedure PostedFacturaInvoiceExcelExport(DocumentNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PostedFacturaInvoice: Report "Posted Factura-Invoice (A)";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName();
        SalesInvHeader.SetRange("No.", DocumentNo);
        PostedFacturaInvoice.SetTableView(SalesInvHeader);
        PostedFacturaInvoice.InitializeRequest(1, 1, false, false);
        PostedFacturaInvoice.SetFileNameSilent(FileName);
        PostedFacturaInvoice.UseRequestPage(false);
        PostedFacturaInvoice.Run();
    end;

    local procedure VerifyFacturaTotals(CurrencyCode: Code[10])
    var
        VATAmount: Decimal;
        TotalInclVAT: Decimal;
        FileName: Text;
    begin
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        TotalInclVAT := LibraryVariableStorage.DequeueDecimal();
        CalcCurrencyVATAmount(VATAmount, TotalInclVAT, CurrencyCode);
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_VATAmount(FileName, Format(VATAmount), 7);
        LibraryRUReports.VerifyFactura_AmountInclVAT(FileName, Format(TotalInclVAT), 7);
    end;

    local procedure SalesDocCalcVATPerLineFactura(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateReleaseSalesDocument(CurrencyCode, SalesHeader);
        FacturaInvoiceExcelExport(SalesHeader);
        VerifyFacturaTotals(CurrencyCode);
    end;

    local procedure PostedSalesDocCalcVATPerLineFactura(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateReleaseSalesDocument(CurrencyCode, SalesHeader);
        PostedFacturaInvoiceExcelExport(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        VerifyFacturaTotals(CurrencyCode);
    end;

    local procedure CalcCurrencyVATAmount(var VATAmount: Decimal; var TotalInclVAT: Decimal; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit;
        Currency.Get(CurrencyCode);
        CurrencyExchangeRate.Get(CurrencyCode, WorkDate());
        VATAmount :=
          Round(VATAmount * CurrencyExchangeRate."Relational Exch. Rate Amount", Currency."Amount Rounding Precision");
        TotalInclVAT :=
          Round(TotalInclVAT * CurrencyExchangeRate."Relational Exch. Rate Amount", Currency."Amount Rounding Precision");
    end;
}

