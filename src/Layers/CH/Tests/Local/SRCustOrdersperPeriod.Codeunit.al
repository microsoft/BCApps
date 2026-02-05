codeunit 144025 "SR Cust. Orders per Period"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NumberOfSalesQuotes: Integer;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        NumberOfSalesQuotes := 5;
    end;

    [Test]
    [HandlerFunctions('CustOrdersPerPeriodReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustOrdersPerPeriodReportStartDatePeriod()
    begin
        CustOrdersPerPeriodReportTest(false);
    end;

    [Test]
    [HandlerFunctions('CustOrdersPerPeriodReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustOrdersPerPeriodReportStartDatePeriodShowLCY()
    begin
        CustOrdersPerPeriodReportTest(true);
    end;

    [Test]
    [HandlerFunctions('CustOrdersPerPeriodReqPageHandler')]
    procedure CustOrdersPerPeriodNoArrayCarryover()
    var
        Customer: Record Customer;
        Item: Record Item;
        PeriodLength: DateFormula;
        PeriodLengthText: Text;
        ShipmentDate, ShipmentDate2 : Date;
        ExpectedAmount, ExpectedAmount2 : Decimal;
        SaleAmtInOrderLCY: array[5] of Decimal;
    begin
        // [SCENARIO 617629] Report SR Cust. Orders Per Period should not carry over array values from previous sales lines when customer have more than sales order.
        Initialize();
        WorkDate := Today();

        // [GIVEN] Create a new customer and item
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set the shipment date for the first sales order
        PeriodLengthText := '<1M>';
        Evaluate(PeriodLength, PeriodLengthText);
        ShipmentDate := WorkDate();

        // [GIVEN] Create First Sales Order
        ExpectedAmount := CreateSalesOrder(Customer."No.", Item."No.", ShipmentDate);

        // [GIVEN] Set new shipment date for second sales order
        ShipmentDate2 := CalcDate(PeriodLength, ShipmentDate);

        // [GIVEN] Create second Sales Order
        ExpectedAmount2 := CreateSalesOrder(Customer."No.", Item."No.", ShipmentDate2);

        // [WHEN] Run the Customer Orders Per Period report
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(true); // ShowAmtInLCY
        Commit();
        Customer.SetRange("No.", Customer."No.");
        Report.Run(Report::"SR Cust. Orders per Period", true, false, Customer);

        // [THEN] First order should show amount only in Period 1
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        SaleAmtInOrderLCY[1] := ExpectedAmount;

        LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY2', SaleAmtInOrderLCY[1]);

        // [THEN] Second order should show amount only in Period 2, Not Period 1 (no carryover)
        LibraryReportDataset.GetNextRow();
        SaleAmtInOrderLCY[2] := ExpectedAmount2;

        LibraryReportDataset.AssertCurrentRowValueNotEquals('SaleAmtInOrderLCY2', SaleAmtInOrderLCY[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY3', SaleAmtInOrderLCY[2]);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustOrdersPerPeriodReportReqPageHandler(var ReqPage: TestRequestPage "SR Cust. Orders per Period")
    var
        PeriodLength: Variant;
        ShowLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(ShowLCY);
        ReqPage."Period Length".SetValue(PeriodLength);
        ReqPage.ShowAmtInLCY.SetValue(ShowLCY);
        ReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure CustOrdersPerPeriodReqPageHandler(var CustOrdersperPeriod: TestRequestPage "SR Cust. Orders per Period")
    var
        PeriodLength: Variant;
        ShowLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(ShowLCY);
        CustOrdersperPeriod."Period Length".SetValue(PeriodLength);
        CustOrdersperPeriod.ShowAmtInLCY.SetValue(ShowLCY);
        CustOrdersperPeriod."Start Date".SetValue(Today());
        CustOrdersperPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CustOrdersPerPeriodReportTest(ShowAmtInLCY: Boolean)
    var
        Customer: Record Customer;
        ExpectedSaleAmtInOrderLCY: array[5] of Decimal;
        PeriodLength: DateFormula;
        PeriodLengthText: Text;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        PeriodLengthText := '<1M>';
        CreateSalesOrders(Customer, PeriodLengthText, ExpectedSaleAmtInOrderLCY);

        // Exercise.
        Evaluate(PeriodLength, PeriodLengthText);
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(ShowAmtInLCY);
        WorkDate := CalcDate(PeriodLength, WorkDate());
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. Orders per Period", true, false, Customer);

        // Verify.
        VerifyReportData(Customer, ShowAmtInLCY, ExpectedSaleAmtInOrderLCY);
    end;

    local procedure CreateSalesOrder(Customer: Record Customer; ShipmentDate: Date; var Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Shipment Date" := ShipmentDate;
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        Amount := SalesLine."Line Amount";
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrders(Customer: Record Customer; PeriodLength: Text; var ExpectedSaleAmtInOrderLCY: array[5] of Decimal)
    var
        ShipmentDate: Date;
        PeriodLengthDateFormula: DateFormula;
        Index: Integer;
    begin
        Evaluate(PeriodLengthDateFormula, PeriodLength);
        ShipmentDate := WorkDate();
        for Index := 1 to NumberOfSalesQuotes do begin
            CreateSalesOrder(Customer, ShipmentDate, ExpectedSaleAmtInOrderLCY[Index]);
            ShipmentDate := CalcDate(PeriodLengthDateFormula, ShipmentDate);
        end;
    end;

    local procedure VerifyReportData(Customer: Record Customer; ShowAmtInLCY: Boolean; ExpectedSaleAmtInOrderLCY: array[5] of Decimal)
    var
        Index: Integer;
        SaleAmtInOrderLCY: array[5] of Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(NumberOfSalesQuotes, LibraryReportDataset.RowCount(), 'Wrong number of customer lines in the report.');

        for Index := 1 to NumberOfSalesQuotes do begin
            LibraryReportDataset.GetNextRow();

            Clear(SaleAmtInOrderLCY);
            SaleAmtInOrderLCY[Index] := ExpectedSaleAmtInOrderLCY[Index];

            LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY1', SaleAmtInOrderLCY[1]);
            LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY2', SaleAmtInOrderLCY[2]);
            LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY3', SaleAmtInOrderLCY[3]);
            LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY4', SaleAmtInOrderLCY[4]);
            LibraryReportDataset.AssertCurrentRowValueEquals('SaleAmtInOrderLCY5', SaleAmtInOrderLCY[5]);
            LibraryReportDataset.AssertCurrentRowValueEquals('OrderAmtLCY', SaleAmtInOrderLCY[Index]);
            LibraryReportDataset.AssertCurrentRowValueEquals('No_Customer', Customer."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('ShowAmtInLCY', ShowAmtInLCY);
        end;
    end;

    local procedure CreateSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; ShipmentDate: Date): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader."Shipment Date" := ShipmentDate;
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 2000));
        SalesLine.Modify(true);

        exit(SalesLine."Line Amount");
    end;

}

