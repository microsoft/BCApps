codeunit 144025 "SR Cust. Orders per Period"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
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
}

