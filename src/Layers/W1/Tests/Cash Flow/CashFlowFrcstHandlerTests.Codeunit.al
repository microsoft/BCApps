codeunit 135201 "Cash Flow Frcst. Handler Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Time series]
    end;

    var
        Assert: Codeunit Assert;
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        TimeSeriesManagement: Codeunit "Time Series Management";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        XPAYABLESTxt: Label 'PAYABLES', Locked = true;
        XRECEIVABLESTxt: Label 'RECEIVABLES', Locked = true;
        XTAXPAYABLESTxt: Label 'TAX TO RETURN', Locked = true;
        XTAXRECEIVABLESTxt: Label 'TAX TO PAY', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPredictStandardForecast()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
    begin
        // [SCENARIO] Normal prediction of item with history
        LibraryLowerPermissions.SetOutsideO365Scope();

        CreateCashFlowSetup();
        CashFlowForecastHandler.Initialize();

        // [GIVEN] There are 6 historical periods
        CreateTestData(WorkDate(), true);
        CreateVATTestData(WorkDate(), true);

        // [THEN] Forecast is prepared and there are 12 Forecast entries 6 for payables and 6 for receivables
        LibraryLowerPermissions.SetAccountReceivables();
        Assert.IsTrue(CashFlowForecastHandler.PrepareForecast(TempTimeSeriesBuffer), 'Forecast failed');

        // [THEN] There are 12 Forecast entries 6 for payables and 6 for receivables
        Assert.RecordCount(TempTimeSeriesBuffer, 24);
        TempTimeSeriesBuffer.SetRange("Group ID", XPAYABLESTxt);
        Assert.RecordCount(TempTimeSeriesBuffer, 6);
        TempTimeSeriesBuffer.SetRange("Group ID", XRECEIVABLESTxt);
        Assert.RecordCount(TempTimeSeriesBuffer, 6);
        TempTimeSeriesBuffer.SetRange("Group ID", XTAXPAYABLESTxt);
        Assert.RecordCount(TempTimeSeriesBuffer, 6);
        TempTimeSeriesBuffer.SetRange("Group ID", XTAXRECEIVABLESTxt);
        Assert.RecordCount(TempTimeSeriesBuffer, 6);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestMaximumHistoricalPeriords()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        oldWorkDate: Date;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] MaximumHistoricalPeriods limits the historical periods
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] There are 6 historical periods the last 20 years and another 6 before that
        oldWorkDate := WorkDate();
        WorkDate := CalcDate('<+20Y>', WorkDate());
        CreateTestData(WorkDate(), true);
        WorkDate := CalcDate('<+20Y>', WorkDate());
        CreateTestData(WorkDate(), false);

        LibraryLowerPermissions.SetAccountReceivables();
        ApiUrl := 'https://ussouthcentral.services.azureml.net';
        ApiKey := 'dummykey';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 120, false);

        // [GIVEN] Maximum historical periods is 24 (default value)
        CustLedgerEntry.Init();
        PrepareData(TempTimeSeriesBuffer, CustLedgerEntry);

        // [THEN] There should be 24 Forecast entries
        Assert.RecordCount(TempTimeSeriesBuffer, 24);

        TempTimeSeriesBuffer.DeleteAll();

        // [GIVEN] Maximum historical periods is 19
        TimeSeriesManagement.SetMaximumHistoricalPeriods(19);
        PrepareData(TempTimeSeriesBuffer, CustLedgerEntry);

        // [THEN] There are 6 Forecast entries
        Assert.RecordCount(TempTimeSeriesBuffer, 6);

        WorkDate := oldWorkDate;
    end;

    local procedure CreateTestData(Date: Date; CleanUp: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if CleanUp then
            CustLedgerEntry.DeleteAll();
        CreateCustomerLedgerEntry(CalcDate('<-6Y+1D>', Date));
        CreateCustomerLedgerEntry(CalcDate('<-5Y+1D>', Date));
        CreateCustomerLedgerEntry(CalcDate('<-4Y+1D>', Date));
        CreateCustomerLedgerEntry(CalcDate('<-3Y+1D>', Date));
        CreateCustomerLedgerEntry(CalcDate('<-2Y+1D>', Date));
        CreateCustomerLedgerEntry(CalcDate('<-1Y+1D>', Date));

        if CleanUp then
            VendorLedgerEntry.DeleteAll();
        CreateVendorLedgerEntry(CalcDate('<-6Y+1D>', Date));
        CreateVendorLedgerEntry(CalcDate('<-5Y+1D>', Date));
        CreateVendorLedgerEntry(CalcDate('<-4Y+1D>', Date));
        CreateVendorLedgerEntry(CalcDate('<-3Y+1D>', Date));
        CreateVendorLedgerEntry(CalcDate('<-2Y+1D>', Date));
        CreateVendorLedgerEntry(CalcDate('<-1Y+1D>', Date));
    end;

    local procedure CreateVATTestData(Date: Date; CleanUp: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        if CleanUp then
            VATEntry.DeleteAll();
        CreateVATEntry(CalcDate('<-6Y+1D>', Date), true);
        CreateVATEntry(CalcDate('<-5Y+1D>', Date), true);
        CreateVATEntry(CalcDate('<-4Y+1D>', Date), true);
        CreateVATEntry(CalcDate('<-3Y+1D>', Date), true);
        CreateVATEntry(CalcDate('<-2Y+1D>', Date), true);
        CreateVATEntry(CalcDate('<-1Y+1D>', Date), true);

        CreateVATEntry(CalcDate('<-6Y+1D>', Date), false);
        CreateVATEntry(CalcDate('<-5Y+1D>', Date), false);
        CreateVATEntry(CalcDate('<-4Y+1D>', Date), false);
        CreateVATEntry(CalcDate('<-3Y+1D>', Date), false);
        CreateVATEntry(CalcDate('<-2Y+1D>', Date), false);
        CreateVATEntry(CalcDate('<-1Y+1D>', Date), false);
    end;

    local procedure CreateVATEntry(DocumentDate: Date; IsSales: Boolean)
    var
        VATEntry: Record "VAT Entry";
        EntryNo: Integer;
    begin
        if VATEntry.FindLast() then;
        EntryNo := VATEntry."Entry No." + 1;
        VATEntry.Init();
        if IsSales then
            VATEntry.Type := VATEntry.Type::Sale
        else
            VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Document Date" := DocumentDate;

        VATEntry."Entry No." := EntryNo;
        VATEntry.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(DueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then;
        EntryNo := CustLedgerEntry."Entry No." + 1;
        CustLedgerEntry.Init();
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(DueDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
        if VendorLedgerEntry.FindLast() then;
        EntryNo := VendorLedgerEntry."Entry No." + 1;
        VendorLedgerEntry.Init();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry.Insert();
    end;

    [Normal]
    local procedure CreateCashFlowSetup()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ApiKey: Text;
    begin
        CashFlowSetup.Get();
        ApiKey := 'dummykey';
        CashFlowSetup.SaveUserDefinedAPIKey(ApiKey);
        CashFlowSetup.Validate("API URL", 'https://ussouthcentral.services.azureml.net');
        CashFlowSetup.Validate("Period Type", CashFlowSetup."Period Type"::Year);
        CashFlowSetup.Validate("Historical Periods", 18);
        CashFlowSetup.Validate("Azure AI Enabled", true);
        CashFlowSetup.Validate("Taxable Period", CashFlowSetup."Taxable Period"::Monthly);
        CashFlowSetup.Modify(true);
    end;

    local procedure PrepareData(var TempTimeSeriesBuffer: Record "Time Series Buffer" temporary; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Date: Record Date;
        NumberOfPeriodsWithHistory: Integer;
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);

        // There should be enough historical periods
        Assert.IsTrue(TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            CustLedgerEntry,
            CustLedgerEntry.FieldNo("Due Date"),
            Date."Period Type"::Year,
            WorkDate()),
          'There should be at least 5 periods with history');

        TimeSeriesManagement.PrepareData(
          CustLedgerEntry,
          CustLedgerEntry.FieldNo("Document Type"),
          CustLedgerEntry.FieldNo("Due Date"),
          CustLedgerEntry.FieldNo("Amount (LCY)"),
          Date."Period Type"::Year,
          WorkDate(),
          NumberOfPeriodsWithHistory);

        TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);
    end;
}

