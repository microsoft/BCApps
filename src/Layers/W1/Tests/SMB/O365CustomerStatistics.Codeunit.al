codeunit 138009 "O365 Customer Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [SMB] [Sales]
    end;

    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        DrillDownNoRecordsErr: Label 'Drilldown on the document type yielded no records.';
        ExpectedAnotherErr: Label 'Expected another record in the list.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckAvrgDaysToPay_OnInvoiceOnly()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        CreateCustomer(Customer);
        ValidateAvgDaysToPay(0, Customer);

        CreateBasicCustLedgerEntry(CustLedgEntry, Customer."No.");
        ValidateAvgDaysToPay(0, Customer);

        CustLedgEntry."Document Type" := CustLedgEntry."Document Type"::Invoice;
        CustLedgEntry.Modify();
        ValidateAvgDaysToPay(0, Customer);

        CustLedgEntry.Open := false;
        CustLedgEntry.Modify();
        ValidateAvgDaysToPay(0, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAvrgDaysToPay_PartiallyPaid()
    var
        Customer: Record Customer;
        i: Integer;
    begin
        Initialize();

        CreateCustomer(Customer);

        for i := 1 to 2 do
            CreateInvoiceAndPayItPartially(Customer);

        ValidateAvgDaysToPay(0, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAvrgDaysToPay_CloseInvByPayment()
    var
        Customer: Record Customer;
        Day1: Integer;
        i: Integer;
    begin
        Initialize();

        CreateCustomer(Customer);
        CreateInvoiceAndPayItPartially(Customer);
        Day1 := LibraryRandom.RandIntInRange(1, 50);

        for i := 1 to 2 do
            CreateInvoiceAndPayIt(Customer, Day1);

        ValidateAvgDaysToPay(Day1, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAvrgDaysToPay_ClosePaymentByInv()
    var
        Customer: Record Customer;
        Day1: Integer;
        i: Integer;
    begin
        Initialize();

        CreateCustomer(Customer);
        CreateInvoiceAndPayItPartially(Customer);
        Day1 := LibraryRandom.RandIntInRange(1, 50);

        for i := 1 to 2 do
            CreateClosePmntByInv(Customer, Day1);

        ValidateAvgDaysToPay(Day1, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAvrgDaysToPay_PaidBySetClosedAtDate()
    var
        Customer: Record Customer;
        CustLedgEntryInv: Record "Cust. Ledger Entry";
        Day1: Integer;
        i: Integer;
    begin
        Initialize();

        CreateCustomer(Customer);
        CreateInvoiceAndPayItPartially(Customer);
        Day1 := LibraryRandom.RandIntInRange(1, 50);

        for i := 1 to 2 do begin
            CreateBasicCustLedgerEntryWithNoise(CustLedgEntryInv, Customer."No.");
            CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::Invoice;
            CustLedgEntryInv.Open := false;

            CustLedgEntryInv."Closed at Date" := WorkDate() + Day1;
            CustLedgEntryInv.Modify();
        end;

        ValidateAvgDaysToPay(Day1, Customer);
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Customer Statistics");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Customer Statistics");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryApplicationArea.EnableFoundationSetup();

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        if SalesSetup."Blanket Order Nos." = '' then
            SalesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesSetup."Return Order Nos." = '' then
            SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesSetup."Order Nos." = '' then
            SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesSetup."Quote Nos." = '' then
            SalesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Customer Statistics");
    end;

    local procedure CreateBasicCustLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    begin
        CustLedgEntry.Init();
        if CustLedgEntry.FindLast() then
            CustLedgEntry."Entry No." += 1
        else
            CustLedgEntry."Entry No." := 1;

        CustLedgEntry."Customer No." := CustNo;
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry.Open := true;
        CustLedgEntry.Insert();
    end;

    local procedure CreateBasicCustLedgerEntryWithNoise(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    var
        CustLedgEntryNoise: Record "Cust. Ledger Entry";
    begin
        CreateBasicCustLedgerEntry(CustLedgEntryNoise, CustNo);
        CustLedgEntryNoise."Document Type" := CustLedgEntryNoise."Document Type"::Invoice;
        CustLedgEntryNoise.Open := false;
        CustLedgEntryNoise.Modify();

        CreateBasicCustLedgerEntry(CustLedgEntry, CustNo);

        CreateBasicCustLedgerEntry(CustLedgEntryNoise, CustNo);
        CustLedgEntryNoise."Document Type" := CustLedgEntryNoise."Document Type"::Payment;
        CustLedgEntryNoise.Open := false;
        CustLedgEntryNoise.Modify();
    end;

    local procedure CreateCustomer(var Customer: Record Customer): Code[20]
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateClosePmntByInv(Customer: Record Customer; PaiInDays: Integer)
    var
        CustLedgEntryInv: Record "Cust. Ledger Entry";
        CustLedgEntryPmnt: Record "Cust. Ledger Entry";
    begin
        CreateBasicCustLedgerEntryWithNoise(CustLedgEntryInv, Customer."No.");
        CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::Invoice;
        CustLedgEntryInv.Open := false;

        CustLedgEntryInv.Modify();

        CreateBasicCustLedgerEntryWithNoise(CustLedgEntryPmnt, Customer."No.");
        CustLedgEntryPmnt."Document Type" := CustLedgEntryPmnt."Document Type"::Payment;
        CustLedgEntryPmnt.Open := false;

        CustLedgEntryPmnt."Posting Date" += PaiInDays;
        CustLedgEntryPmnt."Closed by Entry No." := CustLedgEntryInv."Entry No.";
        CustLedgEntryPmnt.Modify();
    end;

    local procedure CreateInvoiceAndPayIt(Customer: Record Customer; PaiInDays: Integer)
    var
        CustLedgEntryInv: Record "Cust. Ledger Entry";
        CustLedgEntryPmnt: Record "Cust. Ledger Entry";
    begin
        CreateBasicCustLedgerEntryWithNoise(CustLedgEntryPmnt, Customer."No.");
        CustLedgEntryPmnt."Document Type" := CustLedgEntryPmnt."Document Type"::Payment;
        CustLedgEntryPmnt.Open := false;

        CustLedgEntryPmnt."Posting Date" += PaiInDays;
        CustLedgEntryPmnt.Modify();

        CreateBasicCustLedgerEntryWithNoise(CustLedgEntryInv, Customer."No.");
        CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::Invoice;
        CustLedgEntryInv.Open := false;

        CustLedgEntryInv."Closed by Entry No." := CustLedgEntryPmnt."Entry No.";
        CustLedgEntryInv.Modify();
    end;

    local procedure CreateInvoiceAndPayItPartially(Customer: Record Customer)
    var
        CustLedgEntryInv: Record "Cust. Ledger Entry";
        CustLedgEntryPmnt: Record "Cust. Ledger Entry";
    begin
        CreateBasicCustLedgerEntry(CustLedgEntryInv, Customer."No.");
        CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::Invoice;

        CustLedgEntryInv.Modify();

        CreateBasicCustLedgerEntryWithNoise(CustLedgEntryPmnt, Customer."No.");
        CustLedgEntryPmnt."Document Type" := CustLedgEntryPmnt."Document Type"::Payment;
        CustLedgEntryPmnt.Open := false;

        CustLedgEntryPmnt."Closed by Entry No." := CustLedgEntryInv."Entry No.";
        CustLedgEntryPmnt.Modify();
    end;

    local procedure CreatePostedInvoiceWithAmount(CustNo: Code[20]; InvAmount: Decimal)
    var
        CustLedgEntryInv: Record "Cust. Ledger Entry";
    begin
        CreateBasicCustLedgerEntry(CustLedgEntryInv, CustNo);
        CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::Invoice;
        CustLedgEntryInv."Sales (LCY)" := InvAmount;
        CustLedgEntryInv.Modify();
    end;

    local procedure CreatePostedCrMemoWithAmount(CustNo: Code[20]; var InvAmount: Decimal)
    var
        CustLedgEntryInv: Record "Cust. Ledger Entry";
    begin
        InvAmount := -Abs(InvAmount);
        CreateBasicCustLedgerEntry(CustLedgEntryInv, CustNo);
        CustLedgEntryInv."Document Type" := CustLedgEntryInv."Document Type"::"Credit Memo";
        CustLedgEntryInv."Sales (LCY)" := InvAmount;
        CustLedgEntryInv.Modify();
    end;

    local procedure CreateSalesHeaderWithAmount(var SalesHeader: Record "Sales Header"; CustNo: Code[20]; DocType: Enum "Sales Document Type"; InvAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := InvAmount;
        Item.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure ValidateAvgDaysToPay(ExpectedAvgDaysToPay: Decimal; Customer: Record Customer)
    var
        CustomerMgt: Codeunit "Customer Mgt.";
        Stats: Dictionary of [Text, Text];
        AvgDaysToPay: Decimal;
        AverageDaysToPayText: Text;
    begin
        CustomerMgt.CalculatePaymentStats(Customer."No.", Stats);
        if Stats.Get(LibrarySmallBusiness.GetAvgDaysToPayLabel(), AverageDaysToPayText) then
            if Evaluate(AvgDaysToPay, AverageDaysToPayText, 0) then
                Assert.AreEqual(ExpectedAvgDaysToPay, AvgDaysToPay, 'Incorrect CustomerMgt.AvgDaysToPay')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrentYearFilter()
    var
        CustomerMgt: Codeunit "Customer Mgt.";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        DateFilterExpected: Text[30];
        DateFilterActual: Text[30];
        CustDateName: Text[30];
    begin
        Initialize();

        DateFilterCalc.CreateFiscalYearFilter(DateFilterExpected, CustDateName, WorkDate(), 0);
        DateFilterActual := CustomerMgt.GetCurrentYearFilter();
        Assert.AreEqual(DateFilterExpected, DateFilterActual, 'Wrong fiscal year calculation.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnPostedInvoices()
    var
        Customer: Record Customer;
        CustNo: Code[20];
        InvAmount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnPostedInvoices(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            InvAmount := LibraryRandom.RandDec(10, 2);
            CreatePostedInvoiceWithAmount(CustNo, InvAmount);

            ExpectedAmount += InvAmount;
            ValidateAmountOnPostedInvoices(CustNo, ExpectedAmount, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnPostedCrMemos()
    var
        Customer: Record Customer;
        CustNo: Code[20];
        InvAmount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnPostedCrMemos(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            InvAmount := LibraryRandom.RandDec(10, 2);
            CreatePostedCrMemoWithAmount(CustNo, InvAmount);

            ExpectedAmount += InvAmount;
            ValidateAmountOnPostedCrMemos(CustNo, ExpectedAmount, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnOrders()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnOrders(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Order, Amount);

            ExpectedAmount += Amount;
            ValidateAmountOnOrders(CustNo, ExpectedAmount, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnQuotes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnQuotes(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Quote, Amount);

            ExpectedAmount += Amount;
            ValidateAmountOnQuotes(CustNo, ExpectedAmount, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnUnpostedInvoices()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnUnpostedInvoices(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Invoice, Amount);

            ExpectedAmount += Amount;
            ValidateAmountOnUnpostedInvoices(CustNo, ExpectedAmount, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountOnUnpostedCrMemos()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedAmount: Decimal;
        ExpectedCount: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnUnpostedCrMemos(CustNo, 0, 0);

        for ExpectedCount := 1 to 2 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::"Credit Memo", Amount);

            ExpectedAmount += Amount;
            ValidateAmountOnUnpostedCrMemos(CustNo, ExpectedAmount * -1, ExpectedCount);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnQuotes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesQuotes: TestPage "Sales Quotes";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedCount: Integer;
        i: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnQuotes(CustNo, 0, 0);

        for ExpectedCount := 1 to 3 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Quote, Amount);

            SalesQuotes.Trap();
            CustomerMgt.DrillDownOnQuotes(CustNo);
            if not SalesQuotes.First() then
                Error(DrillDownNoRecordsErr);

            for i := 2 to ExpectedCount do
                if not SalesQuotes.Next() then
                    Error(ExpectedAnotherErr);

            SalesQuotes.Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnOrders()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesOrderList: TestPage "Sales Order List";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedCount: Integer;
        i: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnOrders(CustNo, 0, 0);

        for ExpectedCount := 1 to 3 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Order, Amount);

            SalesOrderList.Trap();
            CustomerMgt.DrillDownOnOrders(CustNo);
            if not SalesOrderList.First() then
                Error(DrillDownNoRecordsErr);

            for i := 2 to ExpectedCount do
                if not SalesOrderList.Next() then
                    Error(ExpectedAnotherErr);

            SalesOrderList.Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnUnpostedInvoices()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesInvoiceList: TestPage "Sales Invoice List";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedCount: Integer;
        i: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnUnpostedInvoices(CustNo, 0, 0);

        for ExpectedCount := 1 to 3 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::Invoice, Amount);

            SalesInvoiceList.Trap();
            CustomerMgt.DrillDownOnUnpostedInvoices(CustNo);
            if not SalesInvoiceList.First() then
                Error(DrillDownNoRecordsErr);

            for i := 2 to ExpectedCount do
                if not SalesInvoiceList.Next() then
                    Error(ExpectedAnotherErr);

            SalesInvoiceList.Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnUnpostedCrMemos()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        CustNo: Code[20];
        Amount: Decimal;
        ExpectedCount: Integer;
        i: Integer;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnOrders(CustNo, 0, 0);

        for ExpectedCount := 1 to 3 do begin
            Amount := LibraryRandom.RandDec(10, 2);
            CreateSalesHeaderWithAmount(SalesHeader, CustNo, SalesHeader."Document Type"::"Credit Memo", Amount);

            SalesCreditMemos.Trap();
            CustomerMgt.DrillDownOnUnpostedCrMemos(CustNo);
            if not SalesCreditMemos.First() then
                Error(DrillDownNoRecordsErr);

            for i := 2 to ExpectedCount do
                if not SalesCreditMemos.Next() then
                    Error(ExpectedAnotherErr);

            SalesCreditMemos.Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnMoneyOwedCurrent()
    var
        Customer: Record Customer;
        InvoiceSalesHeader: Record "Sales Header";
        CreditMemoSalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesList: TestPage "Sales List";
        CustNo: Code[20];
        InvoiceAmount: Decimal;
        CreditMemoAmount: Decimal;
    begin
        Initialize();

        CustNo := CreateCustomer(Customer);
        ValidateAmountOnUnpostedInvoices(CustNo, 0, 0);

        InvoiceAmount := LibraryRandom.RandDec(10, 2);
        CreateSalesHeaderWithAmount(InvoiceSalesHeader, CustNo, InvoiceSalesHeader."Document Type"::Invoice, InvoiceAmount);
        CreditMemoAmount := LibraryRandom.RandDec(10, 2);
        CreateSalesHeaderWithAmount(CreditMemoSalesHeader, CustNo, CreditMemoSalesHeader."Document Type"::"Credit Memo", CreditMemoAmount);

        SalesList.Trap();
        CustomerMgt.DrillDownMoneyOwedExpected(CustNo);
        if not SalesList.First() then
            Error(DrillDownNoRecordsErr);

        repeat
            if not (SalesList."No.".Value in [InvoiceSalesHeader."No.", CreditMemoSalesHeader."No."]) then
                Error(ExpectedAnotherErr);
        until SalesList.Next();

        SalesList.Close();
    end;

    local procedure ValidateAmountOnPostedInvoices(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ValidateAmountOnPostedDocs(CustLedgerEntry."Document Type"::Invoice, CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnPostedCrMemos(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ValidateAmountOnPostedDocs(CustLedgerEntry."Document Type"::"Credit Memo", CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnOrders(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        ValidateAmountOnUnpostedDocs(SalesHeader."Document Type"::Order, CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnQuotes(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        ValidateAmountOnUnpostedDocs(SalesHeader."Document Type"::Quote, CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnUnpostedInvoices(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        ValidateAmountOnUnpostedDocs(SalesHeader."Document Type"::Invoice, CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnUnpostedCrMemos(CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        ValidateAmountOnUnpostedDocs(SalesHeader."Document Type"::"Credit Memo", CustNo, ExpectedAmount, ExpectedCount)
    end;

    local procedure ValidateAmountOnPostedDocs(DocType: Enum "Gen. Journal Document Type"; CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerMgt: Codeunit "Customer Mgt.";
        ActualAmount: Decimal;
        ActualCount: Integer;
        DocTypeName: Text;
    begin
        if DocType = CustLedgerEntry."Document Type"::Invoice then begin
            ActualAmount := CustomerMgt.CalcAmountsOnPostedInvoices(CustNo, ActualCount);
            DocTypeName := 'Invoices';
        end else begin
            ActualAmount := CustomerMgt.CalcAmountsOnPostedCrMemos(CustNo, ActualCount);
            DocTypeName := 'Credit Memos';
        end;

        Assert.AreEqual(ExpectedAmount, ActualAmount, StrSubstNo('Wrong Amounts on Posted %1.', DocTypeName));
        Assert.AreEqual(ExpectedCount, ActualCount, StrSubstNo('Wrong Counts on Posted %1.', DocTypeName));
    end;

    local procedure ValidateAmountOnUnpostedDocs(DocType: Enum "Sales Document Type"; CustNo: Code[20]; ExpectedAmount: Decimal; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        ActualAmount: Decimal;
        ActualCount: Integer;
        DocTypeName: Text;
    begin
        case DocType of
            SalesHeader."Document Type"::Quote:
                begin
                    ActualAmount := CustomerMgt.CalcAmountsOnQuotes(CustNo, ActualCount);
                    DocTypeName := 'Quotes';
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    ActualAmount := CustomerMgt.CalculateAmountsOnUnpostedInvoices(CustNo, ActualCount);
                    DocTypeName := 'Unposted Invoices';
                end;
            SalesHeader."Document Type"::Order:
                begin
                    ActualAmount := CustomerMgt.CalcAmountsOnOrders(CustNo, ActualCount);
                    DocTypeName := 'Orders';
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    ActualAmount := CustomerMgt.CalculateAmountsOnUnpostedCrMemos(CustNo, ActualCount);
                    DocTypeName := 'Unposted Credit Memos';
                end;
        end;

        Assert.AreEqual(ExpectedAmount, ActualAmount, StrSubstNo('Wrong Amounts on %1.', DocTypeName));
        Assert.AreEqual(ExpectedCount, ActualCount, StrSubstNo('Wrong Counts on %1.', DocTypeName));
    end;
}
