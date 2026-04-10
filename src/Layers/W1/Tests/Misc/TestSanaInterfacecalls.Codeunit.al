codeunit 139313 "Test Sana Interface calls"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesPostInterface()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        QtyType: Option General,Invoicing,Shipping;
        Text30: Text[30];
        Dec: Decimal;
    begin
        // Prepare
        Initialize();
        Text30 := CopyStr(Format(LibraryUtility.GenerateRandomText(30)), 1, MaxStrLen(Text30));
        // Verify
        SalesPost.SumSalesLinesTemp(SalesHeader, SalesLine, QtyType, SalesLine, SalesLine, Dec, Text30, Dec, Dec, Dec)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveManagementInterface()
    var
        SalesHeader: Record "Sales Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        Bool: Boolean;
    begin
        // Prepare
        Initialize();
        SalesHeader.Init();
        Bool := false;
        // Verify
        ArchiveManagement.StoreSalesDocument(SalesHeader, Bool);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesPostPrepaymentsInterface()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        Dec: Decimal;
        Text30: Text[30];
    begin
        // Prepare
        Initialize();
        Text30 := CopyStr(Format(LibraryUtility.GenerateRandomText(30)), 1, MaxStrLen(Text30));
        SalesHeader.Init();
        // Verify
        SalesPostPrepayments.SumPrepmt(SalesHeader, SalesLine, VATAmountLine, Dec, Dec, Text30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReservationInterfaces()
    var
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        Text50: Text[50];
        Dec: Decimal;
        Bool: Boolean;
    begin
        // Prepare
        Initialize();
        Text50 := CopyStr(Format(LibraryUtility.GenerateRandomText(50)), 1, MaxStrLen(Text50));
        SalesLine.Init();

        // Verify
        SalesLineReserve.ReservQuantity(SalesLine, Dec, Dec);
        ReservationManagement.SetReservSource(SalesLine);
        ReservationManagement.AutoReserve(Bool, Text50, WorkDate(), Dec, Dec);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuotetoOrderInterface()
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
    begin
        // Prepare
        Initialize();
        SalesHeader.Init();
        // Verify
        SalesQuoteToOrder.SetHideValidationDialog(true);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDatabaseTableTriggerSetupInterface()
    var
        ChangeLogManagement: Codeunit "Change Log Management";
        I: Integer;
        Bool: Boolean;
    begin
        // Prepare
        Initialize();
        I := 0;
        // Verify
        ChangeLogManagement.GetDatabaseTableTriggerSetup(I, Bool, Bool, Bool, Bool);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSelectionFilterInterface()
    var
        CustomerList: Page "Customer List";
        CustomerPriceGroups: Page "Customer Price Groups";
        ItemList: Page "Item List";
        Text: Text;
    begin
        // Verify
        Initialize();
        Text := CustomerList.GetSelectionFilter();
        Text := ItemList.GetSelectionFilter();
        Text := CustomerPriceGroups.GetSelectionFilter();
        if Text = '' then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcVATAmountLinesInterface()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify
        Initialize();
        SalesCrMemoLine.CalcVATAmountLines(SalesCrMemoHeader, VATAmountLine);
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
        SalesLine.CalcVATAmountLines(QtyType, SalesHeader, SalesLine, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrencyExchangeRateInterface()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Dec: Decimal;
        code10: Code[10];
    begin
        // Prepare
        Initialize();
        code10 := CopyStr(Format(LibraryUtility.GenerateRandomText(10)), 1, MaxStrLen(code10));
        // Verify
        asserterror Dec := CurrencyExchangeRate.ExchangeRate(WorkDate(), code10);
        asserterror Dec := CurrencyExchangeRate.ExchangeAmtLCYToFCY(WorkDate(), code10, Dec, Dec);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesLineInterfaces()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Prepare
        Initialize();
        SalesHeader.Init();
        // Verify
        SalesLine.SetSalesHeader(SalesHeader);
        SalesLine.UpdateVATOnLines(QtyType, SalesHeader, SalesLine, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATAmountLineInterfaces()
    var
        VATAmountLine: Record "VAT Amount Line";
        Code10: Code[10];
        Bool: Boolean;
        Dec: Decimal;
    begin
        // Prepare
        Initialize();
        Code10 := CopyStr(Format(LibraryUtility.GenerateRandomText(10)), 1, MaxStrLen(Code10));
        Bool := true;
        // Verify
        asserterror VATAmountLine.GetTotalInvDiscBaseAmount(Bool, Code10);
        asserterror Dec := VATAmountLine.GetTotalLineAmount(Bool, Code10);
        asserterror VATAmountLine.SetInvoiceDiscountPercent(Dec, Code10, Bool, Bool, Dec);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrencyInterface()
    var
        Currency: Record Currency;
    begin
        // Setup
        Initialize();

        // Verify
        Currency.InitRoundingPrecision();
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
    end;
}

