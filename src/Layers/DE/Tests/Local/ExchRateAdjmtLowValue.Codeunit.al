codeunit 142069 "Exch. Rate Adjmt. Low Value"
{
    // // FEATURE [Adjust Exchange Rates]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FieldMustEnabledMsg: Label 'Field must be enabled';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RefValuationMethod: Option Standard,"Lowest Value","BilMoG (Germany)";

    [Test]
    [HandlerFunctions('AdjustExchangeRatesDueDateLimitRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateDueDateLimitAdjustExchangeRatesError()
    begin
        // Purpose of the test is to validate DueDateLimit - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run report Exchange Rate Adjustment to verify Error Code, Actual error message: Short term liabilities until must not be before Valuation Reference Date.
        Initialize();
        AdjustExchangeRatesReportErrors(WorkDate(), false, 'TestValidation');  // Posting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    local procedure AdjustExchangeRatesReportErrors(PostingDate: Date; AdjGLAcc: Boolean; Expected: Text[1024])
    begin
        // Enqueue Required inside AdjustExchangeRatesRequestPageHandler and AdjustExchangeRatesDueDateLimitRequestPageHandler.
        LibraryVariableStorage.Enqueue(AdjGLAcc);
        LibraryVariableStorage.Enqueue(PostingDate);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Exch. Rate Adjustment");

        // Verify: Verify Error Code.
        Assert.ExpectedErrorCode(Expected);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesPostingDescRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnOpenPageAdjExchRatesPostingDescriptionBlank()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Posting Description is updated automatically on Report Adjust Exchange Rates inside AdjustExchangeRatesPostingDescRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValPerEndRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateEndingDateAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate EndingDate - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Valuation Reference Date is automatically updated as last day of the month of Ending Date on Report Adjust Exchange Rates inside AdjustExchangeRatesValPerEndRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValuationMethodRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateValPerEndAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate ValPerEnd - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify DueDateLimit is automatically updated as next year of same date of Valuation Reference Date on Report Adjust Exchange Rates inside AdjustExchangeRatesValuationMethodRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValuationMethodRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateValnMethodAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate ValuationMethod - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Valuation Reference Date and Short term liabilities until is enabled when Valuation Method Type is BilMoG (Germany) on Report Adjust Exchange Rates inside AdjustExchangeRatesValuationMethodRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    local procedure AdjustExchangeRatesReport()
    begin
        // Exercise.
        REPORT.Run(REPORT::"Exch. Rate Adjustment");

        // Verify: Verify various Fields in AdjustExchangeRatesPostingDescRequestPageHandler, AdjustExchangeRatesValPerEndRequestPageHandler and  AdjustExchangeRatesValuationMethodRequestPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    var
        AdjGLAcc: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(AdjGLAcc);
        LibraryVariableStorage.Dequeue(PostingDate);
        ExchRateAdjustment.AdjGLAccount.SetValue(AdjGLAcc);
        ExchRateAdjustment.StartingDate.SetValue(WorkDate());
        ExchRateAdjustment.EndingDate.SetValue(WorkDate());
        ExchRateAdjustment.PostingDateReq.SetValue(PostingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesDueDateLimitRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.ValPerEnd.SetValue(CalcDate('<+CM>', WorkDate()));
        ExchRateAdjustment.DueDateLimit.SetValue(WorkDate());  // Less than ValPerEnd.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesPostingDescRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.PostingDescriptionReq.AssertEquals('Adjmt. of %1 %2, Ex.Rate Adjust.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValPerEndRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.EndingDate.SetValue(WorkDate());
        ExchRateAdjustment.PostingDateReq.AssertEquals(WorkDate());
        ExchRateAdjustment.ValPerEnd.AssertEquals(CalcDate('<+CM>', WorkDate()));  // ValPerEnd is equal to Last day of month of Posting Date.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValuationMethodRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.ValPerEnd.SetValue(WorkDate());
        ExchRateAdjustment.DueDateLimit.AssertEquals(CalcDate('<+1Y>', WorkDate()));  // DueDateLimit is equal to same day of next year of ValPerEnd.
        Assert.IsTrue(ExchRateAdjustment.DueDateLimit.Enabled(), FieldMustEnabledMsg);
        Assert.IsTrue(ExchRateAdjustment.ValPerEnd.Enabled(), FieldMustEnabledMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToAdjustMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure AdjustedMessageHandler(Message: Text[1024])
    begin
    end;
}
