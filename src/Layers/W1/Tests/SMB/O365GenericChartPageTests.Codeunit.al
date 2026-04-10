codeunit 138023 "O365 Generic Chart Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Chart] [SMB]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TopTenCustomerChartNameTxt: Label 'Top Ten Customers by Sales Value';
        TopfiveCustomerChartNameTxt: Label 'Top Five Customers by Sales Value';
        TopTenCustomerChartXCaptionTxt: Label 'Customer Name';
        XIncomeAndExpenseChartNameTxt: Label 'Income & Expense';
        XCashFlowChartNameTxt: Label 'Cash Flow';
        XCashCycleChartNameTxt: Label 'Cash Cycle';
        TopTenCustomerChartDescriptionTxt: Label 'This chart shows the ten customers with the highest total sales value. The last column shows the sum of sales values of all other customers.';
        TopFiveCustomerChartDescriptionTxt: Label 'This Pie chart shows the five customers with the highest total sales value.';
        WrongChartMsg: Label 'Unexpected chart selected.';
        AgedAccReceivableNameTxt: Label 'Aged Accounts Receivable';
        AgedAccPayableNameTxt: Label 'Aged Accounts Payable';
        AgedAccReceivableDescriptionTxt: Label 'Shows customers'' pending payment amounts summed for a period that you select.';
        AgedAccPayableDescriptionTxt: Label 'Shows pending payment amounts to vendors summed for a period that you select.';
        OverdueTxt: Label 'Overdue';
        SalesByCustomerGroupNameTxt: Label 'Sales Trends by Customer Groups';
        ViewByTxt: Label 'View by';
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        UnexpectedPeriodLengthMsg: Label 'Unexpected period length set.';
        StatusShouldContainTxt: Label 'Status text should contain: ';
        StatusShouldNotContainTxt: Label 'Status text should not contain: ';
        SelectedCustomerExpectedMsg: Label 'Customer Card with a selected customer expected.';
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PopulateChartTest()
    var
        ChartDefinition: Record "Chart Definition";
        ChartMgt: Codeunit "Chart Management";
    begin
        ChartDefinition.DeleteAll();
        ChartMgt.PopulateChartDefinitionTable();
        Assert.RecordCount(ChartDefinition, 8);
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure SelectChartTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        BusChartUserSetup: Record "Business Chart User Setup";
        CustPostingGroup: Record "Customer Posting Group";
        ChartMgt: Codeunit "Chart Management";
    begin
        Initialize();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);

        ChartDefinition.Get(CODEUNIT::"Top Ten Customers Chart Mgt.", TopTenCustomerChartNameTxt);
        LibraryVariableStorage.Enqueue(TopTenCustomerChartNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        Assert.AreEqual(TopTenCustomerChartXCaptionTxt, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
        Assert.AreEqual(TopTenCustomerChartDescriptionTxt, ChartMgt.ChartDescription(ChartDefinition), WrongChartMsg);

        ChartDefinition.Get(CODEUNIT::"Top Five Customers Chart Mgt.", TopfiveCustomerChartNameTxt);
        LibraryVariableStorage.Enqueue(TopfiveCustomerChartNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        Assert.AreEqual(TopTenCustomerChartXCaptionTxt, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
        Assert.AreEqual(TopFiveCustomerChartDescriptionTxt, ChartMgt.ChartDescription(ChartDefinition), WrongChartMsg);

        ChartDefinition.Get(CODEUNIT::"Aged Acc. Receivable", AgedAccReceivableNameTxt);
        LibraryVariableStorage.Enqueue(AgedAccReceivableNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        Assert.AreEqual(OverdueTxt, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
        Assert.AreEqual(
          1, StrPos(ChartMgt.ChartDescription(ChartDefinition), AgedAccReceivableDescriptionTxt), WrongChartMsg);
        Assert.IsTrue(
          BusChartUserSetup.Get(UserId, BusChartUserSetup."Object Type"::Codeunit, CODEUNIT::"Aged Acc. Receivable"),
          'Chart Setup is not initialized');
        Assert.AreEqual(
          BusChartUserSetup."Period Length"::Week, BusChartUserSetup."Period Length", 'Wrong default period length');
        if CustPostingGroup.FindFirst() then
            CustPostingGroup.TestField(Code, BusinessChartBuffer.GetMeasureName(0));

        ChartDefinition.Get(CODEUNIT::"Aged Acc. Payable", AgedAccPayableNameTxt);
        LibraryVariableStorage.Enqueue(AgedAccPayableNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        Assert.AreEqual(OverdueTxt, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
        Assert.AreEqual(
          1, StrPos(ChartMgt.ChartDescription(ChartDefinition), AgedAccPayableDescriptionTxt), WrongChartMsg);
        Assert.IsTrue(
          BusChartUserSetup.Get(UserId, BusChartUserSetup."Object Type"::Codeunit, CODEUNIT::"Aged Acc. Payable"),
          'Chart Setup is not initialized');
        BusChartUserSetup.TestField("Period Length", BusChartUserSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPeriodLengthTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        SalesByCustGrpChartMgt: Codeunit "Sales by Cust. Grp. Chart Mgt.";
        ChartMgt: Codeunit "Chart Management";
        PeriodLength: Option;
    begin
        Initialize();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);

        ChartDefinition.Get(CODEUNIT::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        ChartMgt.SetPeriodLength(ChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length"::Day, true);
        PeriodLength := BusinessChartBuffer."Period Length";
        Assert.AreEqual(BusinessChartBuffer."Period Length"::Day, PeriodLength, UnexpectedPeriodLengthMsg);

        ChartDefinition.Get(CODEUNIT::"Aged Acc. Payable", AgedAccPayableNameTxt);
        ChartMgt.SetPeriodLength(ChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length"::Month, true);
        PeriodLength := BusinessChartBuffer."Period Length";
        Assert.AreEqual(BusinessChartBuffer."Period Length"::Month, PeriodLength, UnexpectedPeriodLengthMsg);

        SalesByCustGrpChartMgt.OnInitPage();
        ChartDefinition.Get(CODEUNIT::"Sales by Cust. Grp. Chart Mgt.", SalesByCustomerGroupNameTxt);
        ChartMgt.SetPeriodLength(ChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length"::Year, true);
        PeriodLength := BusinessChartBuffer."Period Length";
        Assert.AreEqual(BusinessChartBuffer."Period Length"::Month, PeriodLength, UnexpectedPeriodLengthMsg);
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure SetPeriodLengthAccSchedChartTest()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        Initialize();
        // Look back
        AccountSchedulesChartSetup.Get('', XIncomeAndExpenseChartNameTxt);
        if AccountSchedulesChartSetup."Look Ahead" then begin
            AccountSchedulesChartSetup."Look Ahead" := false;
            AccountSchedulesChartSetup.Modify();
        end;
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Day, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Week, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Month, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Quarter, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Year, false);

        // Look Ahead
        AccountSchedulesChartSetup.Get('', XIncomeAndExpenseChartNameTxt);
        AccountSchedulesChartSetup."Look Ahead" := true;
        AccountSchedulesChartSetup.Modify();
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Day, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Week, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Month, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Quarter, false);
        VerifyPeriodLengthAccSchedChart(BusinessChartBuffer."Period Length"::Year, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusTextTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartMgt: Codeunit "Chart Management";
        StatusText: Text;
        StartDate: Text;
    begin
        Initialize();
        // Acc Schedule Chart. X-Axis Period - status text = chart name + view by
        ChartDefinition.Get(CODEUNIT::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        ChartMgt.UpdateStatusText(ChartDefinition, BusinessChartBuffer, StatusText);
        Assert.AreNotEqual(
          0, StrPos(StatusText, XIncomeAndExpenseChartNameTxt), StatusShouldContainTxt + XIncomeAndExpenseChartNameTxt);
        Assert.AreNotEqual(0, StrPos(StatusText, ViewByTxt), StatusShouldContainTxt + ViewByTxt);

        // Acc Schedule Chart. X-Axis Column/Line - status text = chart name + start date
        AccountSchedulesChartSetup.Get('', XIncomeAndExpenseChartNameTxt);
        AccountSchedulesChartSetup."Base X-Axis on" := AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column";
        AccountSchedulesChartSetup.Modify();
        ChartDefinition.Get(CODEUNIT::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        ChartMgt.SetPeriodLength(ChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length", true);
        BusinessChartBuffer."Period Filter Start Date" := WorkDate();
        StartDate := Format(BusinessChartBuffer."Period Filter Start Date");
        ChartMgt.UpdateStatusText(ChartDefinition, BusinessChartBuffer, StatusText);
        Assert.IsTrue(
          StrPos(StatusText, XIncomeAndExpenseChartNameTxt) > 0, StatusShouldContainTxt + XIncomeAndExpenseChartNameTxt);
        Assert.AreEqual(0, StrPos(StatusText, ViewByTxt), StatusShouldNotContainTxt + ViewByTxt);
        Assert.AreNotEqual(0, StrPos(StatusText, StartDate), StatusShouldContainTxt + StartDate);

        // Top 10 Customers - status text = chart name
        ChartDefinition.Get(CODEUNIT::"Top Ten Customers Chart Mgt.", TopTenCustomerChartNameTxt);
        ChartMgt.UpdateStatusText(ChartDefinition, BusinessChartBuffer, StatusText);
        Assert.AreNotEqual(
          0, StrPos(StatusText, TopTenCustomerChartNameTxt), StatusShouldContainTxt + TopTenCustomerChartNameTxt);
        Assert.AreEqual(0, StrPos(StatusText, ViewByTxt), StatusShouldNotContainTxt + ViewByTxt);
    end;

    [Test]
    [HandlerFunctions('SelectDisabledChartPageHandler')]
    [Scope('OnPrem')]
    procedure SelectDisabledChartTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        XCaptionPriorToSelectingDisabledChart: Text;
    begin
        Initialize();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        XCaptionPriorToSelectingDisabledChart := BusinessChartBuffer.GetXCaption();

        ChartDefinition.Get(CODEUNIT::"Top Ten Customers Chart Mgt.", TopTenCustomerChartNameTxt);
        LibraryVariableStorage.Enqueue(TopTenCustomerChartNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        // no change should happen, because we selected a disabled chart and clicked Cancel
        Assert.AreEqual(XCaptionPriorToSelectingDisabledChart, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastUsedChartTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        XCaptionAfterChange: Text;
    begin
        Initialize();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);

        // Verify that when you reopen the Generic Chart page, you get the chart that was used last time
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        XCaptionAfterChange := BusinessChartBuffer.GetXCaption();
        Assert.AreEqual(TopTenCustomerChartXCaptionTxt, XCaptionAfterChange, WrongChartMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastUsedChartGotDisabledTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
    begin
        Initialize();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);

        // disable the last used chart
        ChartDefinition.Get(CODEUNIT::"Top Five Customers Chart Mgt.", TopfiveCustomerChartNameTxt);
        ChartDefinition.Enabled := false;
        ChartDefinition.Modify(true);

        // Verify that when you reopen the Generic Chart page, you get some other chart, because the last used chart is disabled
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        Assert.AreNotEqual(TopTenCustomerChartXCaptionTxt, BusinessChartBuffer.GetXCaption(), WrongChartMsg);
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure Top10CustPointClickedTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        CreateCustomer();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        CustomerCard.Trap();
        DatapointClicked(
          CODEUNIT::"Top Ten Customers Chart Mgt.", TopTenCustomerChartNameTxt, BusinessChartBuffer);
        Assert.AreNotEqual('', CustomerCard."No.".Value, SelectedCustomerExpectedMsg);
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure Top5CustPointClickedTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        CreateCustomer();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        CustomerCard.Trap();
        DatapointClicked(
          CODEUNIT::"Top Five Customers Chart Mgt.", TopfiveCustomerChartNameTxt, BusinessChartBuffer);
        Assert.AreNotEqual('', CustomerCard."No.".Value, SelectedCustomerExpectedMsg);
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure AgedRecePointClickedTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        CustLedgEntries: TestPage "Customer Ledger Entries";
    begin
        Initialize();
        CreateCustLedgEntry();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        CustLedgEntries.Trap();
        DatapointClicked(
          CODEUNIT::"Aged Acc. Receivable", AgedAccReceivableNameTxt, BusinessChartBuffer);
        Assert.AreNotEqual(
          0, StrPos(CustLedgEntries.FILTER.GetFilter("Due Date"), Format(WorkDate())),
          'Working Date should be part of the filter on Due Date for Cust. Ledger Entries.');
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler')]
    [Scope('OnPrem')]
    procedure AgedPayaPointClickedTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
        VendLedgEntries: TestPage "Vendor Ledger Entries";
    begin
        Initialize();
        CreateVendLedgEntry();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        VendLedgEntries.Trap();
        DatapointClicked(
          CODEUNIT::"Aged Acc. Payable", AgedAccPayableNameTxt, BusinessChartBuffer);
        Assert.AreNotEqual(
          0, StrPos(VendLedgEntries.FILTER.GetFilter("Due Date"), Format(WorkDate())),
          'Working Date should be part of the filter on Due Date for Vend. Ledger Entries.');
    end;

    [Test]
    [HandlerFunctions('ChartListPageHandler,CustListPageHndl')]
    [Scope('OnPrem')]
    procedure SalesByGrpPointClickedTest()
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
    begin
        Initialize();
        CreateCustomer();
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        DatapointClicked(
          CODEUNIT::"Sales by Cust. Grp. Chart Mgt.", SalesByCustomerGroupNameTxt, BusinessChartBuffer);
        // Verification in Modal PageHandler for  Cust. List
    end;

    [Test]
    [HandlerFunctions('ChartListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BusinessManagerRCRestoreSelectedChart()
    var
        LastUsedChart: Record "Last Used Chart";
        SavedLastUsedChart: Record "Last Used Chart";
        RestoreLastUsedChart: Record "Last Used Chart";
        BusinessManagerRoleCenter: TestPage "Business Manager Role Center";
        Restore: Boolean;
    begin
        // [FEATURE] [UI] [Business Manager] [Role Center]
        // [SCENARIO] System must restore selected chart when chart is reopened / reinitialized by the same user

        Initialize();
        LibraryVariableStorage.AssertEmpty();

        if LastUsedChart.Get(UserId) then begin
            RestoreLastUsedChart := LastUsedChart;
            Restore := true;
            LastUsedChart.Delete();
        end;

        // [GIVEN] Cassie selected chart type "Cash Flow" on Business Assistance part of "Business Manager" role center
        BusinessManagerRoleCenter.OpenView();
        BusinessManagerRoleCenter.Control55."Select Chart".Invoke();
        BusinessManagerRoleCenter.Close();

        // [GIVEN] "Last Used Chart" entry for "UID" = "Cassie" has "Chart Name" = "Cash Flow" and "Code Unit ID" = 762
        SavedLastUsedChart.Get(UserId);
        SavedLastUsedChart.TestField("Chart Name", LibraryVariableStorage.DequeueText());
        SavedLastUsedChart.TestField("Code Unit ID", LibraryVariableStorage.DequeueInteger());

        // [WHEN] When Cassie reopens role center
        BusinessManagerRoleCenter.OpenView();

        // [THEN] "Last Used Chart" entry for "UID" = "Cassie" remains unchanged and has "Chart Name" = "Cash Flow" and "Code Unit ID" = 762
        LastUsedChart.Get(UserId);
        LastUsedChart.TestField("Chart Name", SavedLastUsedChart."Chart Name");
        LastUsedChart.TestField("Code Unit ID", SavedLastUsedChart."Code Unit ID");

        LastUsedChart.Delete();
        if Restore then
            RestoreLastUsedChart.Insert();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        ChartDefinition: Record "Chart Definition";
        LastUsedChart: Record "Last Used Chart";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Generic Chart Page Tests");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        if ChartDefinition.FindSet(true) then
            repeat
                ChartDefinition.Enabled := true;
                ChartDefinition.Modify();
            until ChartDefinition.Next() = 0;

        LastUsedChart.DeleteAll();

        CreateAccScheduleChart(XIncomeAndExpenseChartNameTxt);
        CreateAccScheduleChart(XCashFlowChartNameTxt);
        CreateAccScheduleChart(XCashCycleChartNameTxt);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Generic Chart Page Tests");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Generic Chart Page Tests");
    end;

    local procedure CreateAccScheduleChart(Name: Text[30])
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        if AccountSchedulesChartSetup.Get('', Name) then
            exit;
        AccountSchedulesChartSetup.Name := Name;
        AccountSchedulesChartSetup.Insert();
    end;

    local procedure CreateCustomer()
    var
        Customer: Record Customer;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
    end;

    local procedure CreateCustLedgEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustPostingGroup: Record "Customer Posting Group";
        EntryNo: Integer;
    begin
        EntryNo := 1;
        if CustLedgEntry.FindLast() then
            EntryNo := CustLedgEntry."Entry No." + 1;

        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := EntryNo;
        CustLedgEntry."Due Date" := WorkDate();
        CustLedgEntry."Amount (LCY)" := 100;
        CustLedgEntry.Open := true;
        if CustPostingGroup.FindFirst() then
            CustLedgEntry."Customer Posting Group" := CustPostingGroup.Code;
        CustLedgEntry.Insert();
    end;

    local procedure CreateVendLedgEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := 1;
        if VendLedgEntry.FindLast() then
            EntryNo := VendLedgEntry."Entry No." + 1;

        VendLedgEntry.Init();
        VendLedgEntry."Entry No." := EntryNo;
        VendLedgEntry."Due Date" := WorkDate();
        VendLedgEntry."Amount (LCY)" := 100;
        VendLedgEntry.Open := true;
        VendLedgEntry.Insert();
    end;

    local procedure DatapointClicked(CUId: Integer; Name: Text; BusinessChartBuffer: Record "Business Chart Buffer")
    var
        ChartDefinition: Record "Chart Definition";
        ChartMgt: Codeunit "Chart Management";
    begin
        ChartDefinition.Get(CUId, Name);
        LibraryVariableStorage.Enqueue(Name);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);
        ChartMgt.DataPointClicked(BusinessChartBuffer, ChartDefinition);
    end;

    local procedure VerifyPeriodLengthAccSchedChart(Period: Option; InitState: Boolean)
    var
        ChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartMgt: Codeunit "Chart Management";
    begin
        ChartMgt.AddinReady(ChartDefinition, BusinessChartBuffer);
        ChartDefinition.Get(CODEUNIT::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        LibraryVariableStorage.Enqueue(XIncomeAndExpenseChartNameTxt);
        ChartMgt.SelectChart(BusinessChartBuffer, ChartDefinition);

        BusinessChartBuffer."Period Length" := Period;
        ChartMgt.SetPeriodLength(
          ChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length", InitState);

        Assert.AreEqual(Period, BusinessChartBuffer."Period Length", UnexpectedPeriodLengthMsg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChartListPageHandler(var ChartList: TestPage "Chart List")
    begin
        ChartList.FindFirstField(ChartList."Chart Name", LibraryVariableStorage.DequeueText());
        ChartList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectDisabledChartPageHandler(var ChartList: TestPage "Chart List")
    begin
        ChartList.FindFirstField(ChartList."Chart Name", LibraryVariableStorage.DequeueText());
        ChartList.Enabled.SetValue(false);
        ChartList.Cancel().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustListPageHndl(var CustomerList: TestPage "Customer List")
    begin
        Assert.AreNotEqual(
          0, StrPos(CustomerList.FILTER.GetFilter("Date Filter"), Format(WorkDate())),
          'Working Date should be part of the filter on Date Filter in Customer List.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChartListModalPageHandler(var ChartList: TestPage "Chart List")
    var
        ChartDefinition: Record "Chart Definition";
    begin
        ChartDefinition.FindSet();
        ChartDefinition.Next(LibraryRandom.RandInt(ChartDefinition.Count));

        LibraryVariableStorage.Enqueue(ChartDefinition."Chart Name");
        LibraryVariableStorage.Enqueue(ChartDefinition."Code Unit ID");

        ChartList.GotoRecord(ChartDefinition);
        ChartList.OK().Invoke();
    end;
}

