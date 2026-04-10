codeunit 138022 "O365 Charts Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Chart]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        InventoryValueMeasureNameTxt: Label 'Inventory Value';
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        SalesLCYYCaptionTxt: Label 'Sales (LCY)';
        UnexpectedCustomerTxt: Label 'Unexpected customer.';
        UnexpectedSalesLCYTxt: Label 'Unexpected Sales (LCY) value.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AgedInventoryChartDataTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        AgedInventoryChartMgt: Codeunit "Aged Inventory Chart Mgt.";
        InventoryValueVariant: Variant;
        InventoryValue: Decimal;
        InventoryValueBeforeTestEntries: array[5] of Decimal;
        ExpectedInventoryValueIncrease: array[5] of Decimal;
        Delta: Decimal;
        ColumnIndex: Integer;
    begin
        Initialize();
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Month;

        // get the aged inventory values before putting the test data
        // after purchasing test items, we will test that the delta is correct
        AgedInventoryChartMgt.UpdateChart(BusinessChartBuffer);
        for ColumnIndex := 0 to 4 do begin
            BusinessChartBuffer.GetValue(InventoryValueMeasureNameTxt, ColumnIndex, InventoryValueVariant);
            Evaluate(InventoryValueBeforeTestEntries[ColumnIndex + 1], Format(InventoryValueVariant));
        end;

        CreateTestItemLedgerEntriesForDataTest(ExpectedInventoryValueIncrease);

        // verify that the inventory values have increased for the expected amount
        AgedInventoryChartMgt.UpdateChart(BusinessChartBuffer);
        for ColumnIndex := 0 to 4 do begin
            BusinessChartBuffer.GetValue(InventoryValueMeasureNameTxt, ColumnIndex, InventoryValueVariant);
            Evaluate(InventoryValue, Format(InventoryValueVariant));
            Delta := InventoryValue - InventoryValueBeforeTestEntries[ColumnIndex + 1];
            Assert.AreEqual(ExpectedInventoryValueIncrease[ColumnIndex + 1], Delta, 'Unexpected inventory value calculated.');
        end;
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AgedInventoryChartDrilldownTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        AgedInventoryChartMgt: Codeunit "Aged Inventory Chart Mgt.";
        ColumnIndex: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;
        CreateTestItemLedgerEntriesForDrilldownTest();

        AgedInventoryChartMgt.UpdateChart(BusinessChartBuffer);
        for ColumnIndex := 0 to 4 do begin
            // since period length is 7 days, drilldown list should show item ledger entries between following dates
            if ColumnIndex = 4 then
                StartDate := 0D
            else
                StartDate := CalcDate('<-' + Format((ColumnIndex + 1) * 7) + 'D>', WorkDate());
            if ColumnIndex = 0 then
                EndDate := WorkDate()
            else
                EndDate := CalcDate('<-' + Format(ColumnIndex * 7) + 'D>', WorkDate());
            LibraryVariableStorage.Enqueue(StartDate);
            LibraryVariableStorage.Enqueue(EndDate);
            BusinessChartBuffer."Drill-Down X Index" := ColumnIndex;
            AgedInventoryChartMgt.DrillDown(BusinessChartBuffer);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TopFiveCustomerChartDataTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TopFiveCustomersChartMgt: Codeunit "Top Five Customers Chart Mgt.";
        TestCustomerNames: array[12] of Text;
        TestCustomerSalesLCYs: array[12] of Decimal;
    begin
        Initialize();
        CreateTestCustomersForTopChart(TestCustomerNames, TestCustomerSalesLCYs, 12);
        TopFiveCustomersChartMgt.UpdateChart(BusinessChartBuffer);
        VerifyTopCustomerSalesMatch(BusinessChartBuffer, TestCustomerNames, TestCustomerSalesLCYs, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TopFiveCustomerChartDataTestOnlyTwoCustomersExists()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TopFiveCustomersChartMgt: Codeunit "Top Five Customers Chart Mgt.";
        TestCustomerNames: array[12] of Text;
        TestCustomerSalesLCYs: array[12] of Decimal;
    begin
        Initialize();
        CreateTestCustomersForTopChart(TestCustomerNames, TestCustomerSalesLCYs, 2);
        TopFiveCustomersChartMgt.UpdateChart(BusinessChartBuffer);
        VerifyTopCustomerSalesMatch(BusinessChartBuffer, TestCustomerNames, TestCustomerSalesLCYs, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TopTenCustomerChartDataTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TopTenCustomersChartMgt: Codeunit "Top Ten Customers Chart Mgt.";
        TestCustomerNames: array[12] of Text;
        TestCustomerSalesLCYs: array[12] of Decimal;
    begin
        Initialize();
        CreateTestCustomersForTopChart(TestCustomerNames, TestCustomerSalesLCYs, 12);
        TopTenCustomersChartMgt.UpdateChart(BusinessChartBuffer);
        VerifyTopCustomerSalesMatch(BusinessChartBuffer, TestCustomerNames, TestCustomerSalesLCYs, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TopTenCustomerChartDataTestOnlyTwoCustomersExists()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TopTenCustomersChartMgt: Codeunit "Top Ten Customers Chart Mgt.";
        TestCustomerNames: array[12] of Text;
        TestCustomerSalesLCYs: array[12] of Decimal;
    begin
        Initialize();
        CreateTestCustomersForTopChart(TestCustomerNames, TestCustomerSalesLCYs, 2);
        TopTenCustomersChartMgt.UpdateChart(BusinessChartBuffer);
        VerifyTopCustomerSalesMatch(BusinessChartBuffer, TestCustomerNames, TestCustomerSalesLCYs, 2);
    end;

    [Test]
    [HandlerFunctions('CustomerCardPageHandler,CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure TopTenCustomerChartDrillDownTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TopTenCustomersChartMgt: Codeunit "Top Ten Customers Chart Mgt.";
        CustomerName: Variant;
        ColumnIndex: Integer;
        TestCustomerNames: array[12] of Text;
        TestCustomerSalesLCYs: array[12] of Decimal;
    begin
        Initialize();
        CreateTestCustomersForTopChart(TestCustomerNames, TestCustomerSalesLCYs, 12);
        TopTenCustomersChartMgt.UpdateChart(BusinessChartBuffer);

        // test that when you click on a top 10 customer column - appropriate customer card opens
        BusinessChartBuffer."Drill-Down Measure Index" := 0;
        for ColumnIndex := 0 to 9 do begin
            BusinessChartBuffer.GetXValue(ColumnIndex, CustomerName);
            LibraryVariableStorage.Enqueue(TestCustomerNames[ColumnIndex + 1]);
            BusinessChartBuffer."Drill-Down X Index" := ColumnIndex;
            TopTenCustomersChartMgt.DrillDown(BusinessChartBuffer);
        end;
        // test drill-down the 11th column - all other customers
        // a list with customer 11 and 12 should open - because they are outside the top 10
        LibraryVariableStorage.Enqueue(TestCustomerNames[11]);
        LibraryVariableStorage.Enqueue(TestCustomerNames[12]);
        BusinessChartBuffer."Drill-Down X Index" := 10;
        TopTenCustomersChartMgt.DrillDown(BusinessChartBuffer);
    end;

    [Scope('OnPrem')]
    procedure VerifyTopCustomerSalesMatch(var BusinessChartBuffer: Record "Business Chart Buffer"; var TestCustomerNames: array[12] of Text; TestCustomerSalesLCYs: array[12] of Decimal; TopCostumerCount: Integer)
    var
        CustomerName: Variant;
        CustomerSalesLCY: Variant;
        ColumnIndex: Integer;
        ExpectedTotalSalesForOthers: Decimal;
    begin
        // Test that the top x customer names and sales values are represented correctly
        for ColumnIndex := 0 to (TopCostumerCount - 1) do begin
            BusinessChartBuffer.GetXValue(ColumnIndex, CustomerName);
            BusinessChartBuffer.GetValue(SalesLCYYCaptionTxt, ColumnIndex, CustomerSalesLCY);
            Assert.AreEqual(
                StrSubstNo('%1 - %1', TestCustomerNames[ColumnIndex + 1]), Format(CustomerName), UnexpectedCustomerTxt);
            Assert.AreEqual(Format(TestCustomerSalesLCYs[ColumnIndex + 1]), Format(CustomerSalesLCY), UnexpectedSalesLCYTxt);
        end;

        // Calculate the total for all other customers
        for ColumnIndex := TopCostumerCount + 1 to 12 do
            ExpectedTotalSalesForOthers := ExpectedTotalSalesForOthers + TestCustomerSalesLCYs[ColumnIndex];

        // Get the last column and test that it matches the total for all other customers. Only if other customers have sales.
        if ExpectedTotalSalesForOthers = 0 then
            asserterror BusinessChartBuffer.GetValue(SalesLCYYCaptionTxt, TopCostumerCount, CustomerSalesLCY)
        else begin
            BusinessChartBuffer.GetValue(SalesLCYYCaptionTxt, TopCostumerCount, CustomerSalesLCY);
            Assert.AreEqual(Format(ExpectedTotalSalesForOthers), Format(CustomerSalesLCY), UnexpectedSalesLCYTxt);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesByCustPostingGroups()
    var
        Cust: Record Customer;
        Cust2: Record Customer;
        Item: Record Item;
        BusChartBuf: Record "Business Chart Buffer";
        SalesByCustGrpChartSetup: Record "Sales by Cust. Grp.Chart Setup";
        SalesByCustGrpChartMgt: Codeunit "Sales by Cust. Grp. Chart Mgt.";
        NewCustPostGroup1: Code[20];
        NewCustPostGroup2: Code[20];
        RefDate: Date;
        NewDate: Date;
    begin
        Initialize();
        RefDate := WorkDate();

        CreateTwoCustPostingGroups(NewCustPostGroup1, NewCustPostGroup2);
        CreateCustWithPostingGroup(Cust, NewCustPostGroup1);
        CreateCustWithPostingGroup(Cust2, NewCustPostGroup2);
        LibrarySmallBusiness.CreateItem(Item);

        WorkDate := CalcDate('<CY - 10D>', RefDate);
        for NewDate := WorkDate() to CalcDate('<20D>', WorkDate()) do begin
            WorkDate := NewDate;
            InvoiceCust(Cust, Item);
            ChangePrice(Item);
            InvoiceCust(Cust2, Item);
        end;

        SalesByCustGrpChartSetup.DeleteAll();
        SalesByCustGrpChartMgt.OnInitPage();
        for SalesByCustGrpChartSetup."Period Length" := SalesByCustGrpChartSetup."Period Length"::Day to SalesByCustGrpChartSetup."Period Length"::Year do begin
            SalesByCustGrpChartSetup.SetPeriodLength(SalesByCustGrpChartSetup."Period Length");
            SalesByCustGrpChartSetup."Start Date" := CalcDate('<CY - 10D>', RefDate);
            SalesByCustGrpChartSetup.Modify();
            // Exercise on period length with previous
            SalesByCustGrpChartSetup.SetPeriod(1);
            SalesByCustGrpChartMgt.UpdateChart(BusChartBuf);
            // Verify
            VerifyCustPostingGroups(BusChartBuf, SalesByCustGrpChartSetup."Period Length", Cust, Cust2);
            // Exercise on period length with next
            SalesByCustGrpChartMgt.UpdateChart(BusChartBuf);
            SalesByCustGrpChartSetup.SetPeriod(2);
            // Verify
            VerifyCustPostingGroups(BusChartBuf, SalesByCustGrpChartSetup."Period Length", Cust, Cust2);
        end;
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SalesByCustGrpChartDrilldownTest()
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPostingGroup: Record "Customer Posting Group";
        BusChartBuf: Record "Business Chart Buffer";
        SalesByCustGrpChartSetup: Record "Sales by Cust. Grp.Chart Setup";
        SalesByCustGrpChartMgt: Codeunit "Sales by Cust. Grp. Chart Mgt.";
    begin
        // [SCENARIO 206660] A Customer List is opened on Drilldown in not modal mode.
        Initialize();

        // [GIVEN] A customer with a posting group, new item and one posted invoice.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CreateCustWithPostingGroup(Customer, CustomerPostingGroup.Code);
        LibrarySmallBusiness.CreateItem(Item);
        InvoiceCust(Customer, Item);

        // [GIVEN] "Sales Trends by Customer Groups" chart is opened.
        SalesByCustGrpChartSetup.DeleteAll();
        SalesByCustGrpChartMgt.OnInitPage();
        SalesByCustGrpChartMgt.UpdateChart(BusChartBuf);

        // [WHEN] OnDrillDown is called in the "Sales Trends by Customer Groups" chart.
        LibraryVariableStorage.Enqueue(Customer."No.");
        SalesByCustGrpChartMgt.DrillDown(BusChartBuf);

        // [THEN] A non-modal Customer List Page is opened.
        // Page is opened by CustomerListPageHandlerSimple.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AgedAccReceivablesTest()
    var
        Cust: Record Customer;
        Cust2: Record Customer;
        Item: Record Item;
        BusChartBuf: Record "Business Chart Buffer";
        TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        NewCustPostGroup1: Code[20];
        NewCustPostGroup2: Code[20];
        RefDate: Date;
        NewDate: Date;
    begin
        Initialize();
        RefDate := WorkDate();

        CreateTwoCustPostingGroups(NewCustPostGroup1, NewCustPostGroup2);
        CreateCustWithPostingGroup(Cust, NewCustPostGroup1);
        CreateCustWithPostingGroup(Cust2, NewCustPostGroup2);
        LibrarySmallBusiness.CreateItem(Item);

        WorkDate := CalcDate('<CY - 10D>', RefDate);
        for NewDate := WorkDate() to CalcDate('<20D>', WorkDate()) do begin
            WorkDate := NewDate;
            InvoiceCust(Cust, Item);
            ChangePrice(Item);
            InvoiceCust(Cust2, Item);
        end;

        for BusChartBuf."Period Length" := BusChartBuf."Period Length"::Day to BusChartBuf."Period Length"::Year do begin
            BusChartBuf."Period Filter Start Date" := NewDate;

            Assert.IsTrue(StrPos(AgedAccReceivable.UpdateStatusText(BusChartBuf), Format(BusChartBuf."Period Length")) > 0, '');
            // Exercise on period length with previous
            BusChartBuf."Period Filter Start Date" := CalcDate('<-1' + BusChartBuf.GetPeriodLength() + '>', BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date"));
            WorkDate := BusChartBuf."Period Filter Start Date";
            AgedAccReceivable.UpdateDataPerGroup(BusChartBuf, TempEntryNoAmountBuf);
            // Verify
            VerifyCustPostingGroups2(BusChartBuf, BusChartBuf."Period Length", Cust, Cust2);
            // Exercise on period length with next
            BusChartBuf."Period Filter Start Date" := CalcDate('<+1' + BusChartBuf.GetPeriodLength() + '>', BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date"));
            WorkDate := BusChartBuf."Period Filter Start Date";
            AgedAccReceivable.UpdateDataPerGroup(BusChartBuf, TempEntryNoAmountBuf);
            // Verify
            VerifyCustPostingGroups2(BusChartBuf, BusChartBuf."Period Length", Cust, Cust2);
        end;
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Charts Tests");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        ClearTable(DATABASE::Resource);
        ClearTable(DATABASE::"Res. Ledger Entry");
        ClearTable(DATABASE::Customer);
        ClearTable(DATABASE::"Cust. Ledger Entry");

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Charts Tests");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Charts Tests");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        Resource: Record Resource;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::Customer:
                Customer.DeleteAll();
            DATABASE::"Cust. Ledger Entry":
                CustLedgerEntry.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateTwoCustPostingGroups(var CustPostingGroup1: Code[20]; var CustPostingGroup2: Code[20])
    var
        CustPostGroup: Record "Customer Posting Group";
        NewCustPostGroup1: Record "Customer Posting Group";
        NewCustPostGroup2: Record "Customer Posting Group";
    begin
        CustPostGroup.FindSet();
        NewCustPostGroup1 := CustPostGroup;
        CustPostGroup.Next(-1);
        NewCustPostGroup2 := CustPostGroup;

        NewCustPostGroup1.Code := 'A' + Format(Time, 0, '<H>:<M>:<S>');
        while not NewCustPostGroup1.Insert(true) do
            NewCustPostGroup1.Code := IncStr(NewCustPostGroup1.Code);

        NewCustPostGroup2.Code := 'B' + Format(Time, 0, '<H>:<M>:<S>');
        while not NewCustPostGroup2.Insert(true) do
            NewCustPostGroup2.Code := IncStr(NewCustPostGroup2.Code);

        CustPostingGroup1 := NewCustPostGroup1.Code;
        CustPostingGroup2 := NewCustPostGroup2.Code;
    end;

    local procedure CreateCustWithPostingGroup(var Cust: Record Customer; CustPostGroup: Code[20])
    begin
        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Validate("Customer Posting Group", CustPostGroup);
        Cust.Modify(true);
    end;

    local procedure CreateTestCustomersForTopChart(var TestCustomerNames: array[12] of Text; var TestCustomerSalesLCYs: array[12] of Decimal; CustomerCount: Integer)
    var
        TestItem: Record Item;
        TestCustomer: Record Customer;
        TestSalesHeader: Record "Sales Header";
        TestSalesLine: Record "Sales Line";
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TopCustomersBySalesJob: Codeunit "Top Customers By Sales Job";
        I: Integer;
    begin
        LibrarySmallBusiness.CreateItem(TestItem);

        // create 'CustomerCount' customers with salesLCY ranging from high to low.
        for I := 1 to CustomerCount do begin
            LibrarySmallBusiness.CreateCustomer(TestCustomer);
            LibrarySmallBusiness.CreateSalesInvoiceHeader(TestSalesHeader, TestCustomer);
            LibrarySmallBusiness.CreateSalesLine(TestSalesLine, TestSalesHeader, TestItem, 13 - I);
            LibrarySmallBusiness.PostSalesInvoice(TestSalesHeader);
            TestCustomerNames[I] := TestCustomer.Name;
            TestCustomerSalesLCYs[I] := (13 - I) * TestItem."Unit Price";
        end;

        // update top customers buffer table, in order to include current Sales LCY numbers instantly
        TopCustomersBySalesBuffer.DeleteAll();
        TopCustomersBySalesJob.UpdateCustomerTopList();
    end;

    local procedure CreateTestItemLedgerEntriesForDataTest(var ExpectedInventoryValueIncrease: array[12] of Decimal)
    var
        TestItem: Record Item;
        TestVendor: Record Vendor;
        TestPurchaseHeader: Record "Purchase Header";
        TestPurchaseLine: Record "Purchase Line";
        I: Integer;
        OriginalWorkDate: Date;
    begin
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreateVendor(TestVendor);
        OriginalWorkDate := WorkDate();

        // post test purchase invoices with backdated posting date in order to increase inventory value
        WorkDate(CalcDate('<-10D>', WorkDate()));
        for I := 1 to 5 do begin
            PostPurchaseInvoice(TestPurchaseHeader, TestPurchaseLine, TestVendor, TestItem, I, Format(I));
            ExpectedInventoryValueIncrease[I] := TestPurchaseLine.Quantity * TestPurchaseLine."Direct Unit Cost";
            WorkDate(CalcDate('<-1M>', WorkDate()));
        end;
        WorkDate(OriginalWorkDate);
    end;

    local procedure CreateTestItemLedgerEntriesForDrilldownTest()
    var
        TestItem: Record Item;
        TestVendor: Record Vendor;
        TestPurchaseHeader: Record "Purchase Header";
        TestPurchaseLine: Record "Purchase Line";
        I: Integer;
        OriginalWorkDate: Date;
    begin
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreateVendor(TestVendor);
        OriginalWorkDate := WorkDate();

        // post test purchase invoices with backdated posting date in order to create some item ledger entries to drill down to
        for I := 1 to 20 do begin
            PostPurchaseInvoice(TestPurchaseHeader, TestPurchaseLine, TestVendor, TestItem, I, Format(I));
            WorkDate(CalcDate('<-2D>', WorkDate()));
        end;
        WorkDate(OriginalWorkDate);
    end;

    local procedure ChangePrice(var Item: Record Item)
    begin
        Item.Find();
        Item.Validate("Unit Price", Item."Unit Price" + 1);
        Item.Modify(true);
    end;

    local procedure InvoiceCust(Cust: Record Customer; Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Cust);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
    end;

    local procedure VerifyCustPostingGroups(var BusChartBuf: Record "Business Chart Buffer"; PeriodLength: Integer; Cust1: Record Customer; Cust2: Record Customer)
    var
        Result: Variant;
        FromDate: Date;
        ToDate: Date;
    begin
        BusChartBuf."Period Length" := PeriodLength;
        for BusChartBuf."Drill-Down X Index" := 0 to 4 do begin
            ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
            FromDate := BusChartBuf.CalcFromDate(ToDate);

            BusChartBuf.GetValue(Cust1."Customer Posting Group", BusChartBuf."Drill-Down X Index", Result);
            Cust1.SetRange("Date Filter", FromDate, ToDate);
            Cust1.CalcFields("Sales (LCY)");
            Assert.AreEqual(Result, Cust1."Sales (LCY)", '');

            BusChartBuf.GetValue(Cust2."Customer Posting Group", BusChartBuf."Drill-Down X Index", Result);
            Cust2.SetRange("Date Filter", FromDate, ToDate);
            Cust2.CalcFields("Sales (LCY)");
            Assert.AreEqual(Result, Cust2."Sales (LCY)", '');
        end;
    end;

    local procedure VerifyCustPostingGroups2(var BusChartBuf: Record "Business Chart Buffer"; PeriodLength: Integer; Cust1: Record Customer; Cust2: Record Customer)
    var
        Result: Variant;
        PeriodDFVariant: Variant;
        FromDate: Date;
        ToDate: Date;
        PeriodDF: Text;
    begin
        BusChartBuf."Period Length" := PeriodLength;
        for BusChartBuf."Drill-Down X Index" := 1 to 4 do begin
            BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", PeriodDFVariant);
            PeriodDF := PeriodDFVariant;

            ToDate := BusChartBuf.CalcToDate(CalcDate('<-' + PeriodDF + '>', WorkDate()));
            FromDate := BusChartBuf.CalcFromDate(ToDate);

            BusChartBuf.GetValue(Cust1."Customer Posting Group", BusChartBuf."Drill-Down X Index", Result);
            Cust1.SetRange("Date Filter", FromDate, ToDate);
            Cust1.CalcFields("Net Change (LCY)");
            Assert.AreEqual(Result, Cust1."Net Change (LCY)", '');

            BusChartBuf.GetValue(Cust2."Customer Posting Group", BusChartBuf."Drill-Down X Index", Result);
            Cust2.SetRange("Date Filter", FromDate, ToDate);
            Cust2.CalcFields("Net Change (LCY)");
            Assert.AreEqual(Result, Cust2."Net Change (LCY)", '');
        end;
    end;

    local procedure PostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor; Item: Record Item; Quantity: Integer; VendorInvoiceNo: Code[10])
    begin
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardPageHandler(var CustomerCard: TestPage "Customer Card")
    var
        CustomerName: Variant;
        CustomerNameOnCard: Text[40];
    begin
        LibraryVariableStorage.Dequeue(CustomerName);
        CustomerNameOnCard := CustomerCard.Name.Value();
        CustomerCard.Close();
        Assert.AreEqual(Format(CustomerName), CustomerNameOnCard, 'Unexpected customer card opened.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: TestPage "Customer List")
    var
        Customer1Name: Variant;
        Customer2Name: Variant;
    begin
        LibraryVariableStorage.Dequeue(Customer1Name);
        LibraryVariableStorage.Dequeue(Customer2Name);
        CustomerList.First();
        Assert.AreEqual(Format(Customer1Name), CustomerList.Name.Value, 'Unexpected customer in customer list that opened.');
        CustomerList.Next();
        Assert.AreEqual(Format(Customer2Name), CustomerList.Name.Value, 'Unexpected customer in customer list that opened.');
        Assert.IsFalse(CustomerList.Next(), 'Unexpected number of customers in customer list that opened.');
        CustomerList.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandlerSimple(var CustomerList: TestPage "Customer List")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CustomerList."No.".Value, 'Unexpected Customer No.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    var
        StartDateVariant: Variant;
        EndDateVariant: Variant;
        StartDate: Date;
        EndDate: Date;
        PostingDate: Date;
        RemainingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(StartDateVariant);
        LibraryVariableStorage.Dequeue(EndDateVariant);
        Evaluate(StartDate, Format(StartDateVariant));
        Evaluate(EndDate, Format(EndDateVariant));
        ItemLedgerEntries.First();
        repeat
            PostingDate := ItemLedgerEntries."Posting Date".AsDate();
            RemainingQuantity := ItemLedgerEntries."Remaining Quantity".AsDecimal();
            Assert.IsTrue((PostingDate <= EndDate) and (PostingDate > StartDate) and (RemainingQuantity <> 0), 'Wrong item ledger entry');
        until not ItemLedgerEntries.Next();
    end;
}

