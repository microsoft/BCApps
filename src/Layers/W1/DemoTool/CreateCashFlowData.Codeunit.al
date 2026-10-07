codeunit 101029 "Create Cash Flow Data"
{

    trigger OnRun()
    begin
        if not CFSetup.FindFirst() then begin
            CFSetup.Init();
            CFSetup.Insert();
        end;

        DemonstrationData();
    end;

    var
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of Cash Flow Forecast No. Series.';
        XxCashFlow: Label 'CashFlow';
        XCashFlowJanuary: Label 'CashFlow January 2008';
        XSurplus: Label 'Surplus';
        XCashReceipts: Label 'Cash receipts';
        XOpenSalesOrders: Label 'Open Sales Orders';
        XRentals: Label 'Rentals';
        XFinancialAssets: Label 'Financial Assets';
        XFixedAssetsDisposals: Label 'Fixed Assets Disposals';
        XPrivateInvestments: Label 'Private Investments';
        XMiscellaneousReceipts: Label 'Miscellaneous receipts';
        XOpenServiceOrders: Label 'Open service orders';
        XCashDisbursement: Label 'Cash disbursement';
        XPayables: Label 'Payables';
        XPersonnelCosts: Label 'Personnel costs';
        XRunningCosts: Label 'Running costs';
        XFinanceCosts: Label 'Finance Costs';
        XBuildingOccupancyCosts: Label 'Building Occupancy Costs';
        XInvestments: Label 'Investments';
        XEncashmentOfBills: Label 'Encashment of Bills';
        XPrivateConsumptions: Label 'Private Consumptions';
        XVATDue: Label 'VAT Due';
        XOtherExpenses: Label 'Other expenses';
        XTotalOfCashDisbursements: Label 'Total of Cash Disbursements';
        XTotalOfSurplus: Label 'Total of Surplus';
        XCashFlowFunds: Label 'CashFlow Funds';
        XTotalCashFlow: Label 'Total Cash Flow';
        XReceivables: Label 'Receivables';
        XTotalofCashReceipts: Label 'Total of Cash Receipts';
        XOpenPurchaseOrders: Label 'Open Purchase Orders';
        XCashFlowDateListTxt: Label 'Cash Flow Date List';
        CFSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFReportSelection: Record "Cash Flow Report Selection";
        MakeAdjustments: Codeunit "Make Adjustments";
        xME: Label 'ME';
        xMR: Label 'MR';
        XDefaultCFCardNo: Label 'CF100001', Comment = 'CF stands for Cash Flow.';

    procedure DemonstrationData()
    begin
        CreateCFSetup(XCASHFLOW, XDefaultCFCardNo, true);

        // CashFlow
        CreateCFForecast(XDefaultCFCardNo, XCashFlowJanuary, XCASHFLOW);

        CreateCFAccounts();

        // CF Manual Revenue/Payments
        CreateRevenue(xMR + '01', '0030', XRentals, 2900);
        CreateRevenue(xMR + '02', '0040', XFinancialAssets, 6200);
        CreateRevenue(xMR + '03', '0060', XPrivateInvestments, 300000);
        CreateExpens(xME + '01', '1030', XPersonnelCosts, 130000);
        CreateExpens(xME + '02', '1040', XRunningCosts, 75000);
        CreateExpens(xME + '03', '1050', XFinanceCosts, 15000);

        CreateCFReportSelection();
    end;

    local procedure CreateCFAccounts()
    var
        CFAccount: Record "Cash Flow Account";
    begin
        CreateCFAccount(
          '0001', XxCashFlow, CFAccount."Account Type"::"Begin-Total", 0, '', CFAccount."Source Type"::" ",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0002', XSurplus, CFAccount."Account Type"::"Begin-Total", 1, '', CFAccount."Source Type"::" ",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0009', XCashReceipts, CFAccount."Account Type"::"Begin-Total", 2, '', CFAccount."Source Type"::" ",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0010', XReceivables, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::Receivables,
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0020', XOpenSalesOrders, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Sales Orders",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0030', XRentals, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Revenue",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0040', XFinancialAssets, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Revenue",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0050', XFixedAssetsDisposals, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Fixed Assets Disposal",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0060', XPrivateInvestments, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Revenue",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0070', XMiscellaneousReceipts, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Revenue",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0080', XOpenServiceOrders, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Service Orders",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '0999', XTotalofCashReceipts, CFAccount."Account Type"::"End-Total", 2, '0009..0999', CFAccount."Source Type"::" ",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1000', XCashDisbursement, CFAccount."Account Type"::"Begin-Total", 2, '', CFAccount."Source Type"::" ",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1010', XPayables, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::Payables,
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1020', XOpenPurchaseOrders, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Purchase Orders",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1030', XPersonnelCosts, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Expense",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1040', XRunningCosts, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Expense",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1050', XFinanceCosts, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Cash Flow Manual Expense",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount_andGL(
          '1060', XBuildingOccupancyCosts, CFAccount."Account Type"::Entry, 3, '',
          CFAccount."Source Type"::"G/L Budget", CFAccount."G/L Integration"::Budget,
          CreateGLAccFilter('998110', '998130'));
        CreateCFAccount(
          '1070', XInvestments, CFAccount."Account Type"::Entry, 3, '', CFAccount."Source Type"::"Fixed Assets Budget",
          CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1080', XEncashmentOfBills, CFAccount."Account Type"::Entry, 3, '',
          CFAccount."Source Type"::"Cash Flow Manual Expense", CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1090', XPrivateConsumptions, CFAccount."Account Type"::Entry, 3, '',
          CFAccount."Source Type"::"Cash Flow Manual Expense", CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '1100', XVATDue, CFAccount."Account Type"::Entry, 3, '',
          CFAccount."Source Type"::"Cash Flow Manual Expense", CFAccount."G/L Integration"::" ");
        CreateCFAccount_andGL(
          '1110', XOtherExpenses, CFAccount."Account Type"::Entry, 3, '',
          CFAccount."Source Type"::"G/L Budget", CFAccount."G/L Integration"::Budget,
          StrSubstNo('%1|%2', CreateGLAccFilter('998410', '998430'), MakeAdjustments.Convert('998450')));
        CreateCFAccount(
          '1999', XTotalOfCashDisbursements, CFAccount."Account Type"::"End-Total", 2, '1000..1999',
          CFAccount."Source Type"::" ", CFAccount."G/L Integration"::" ");
        CreateCFAccount(
          '2000', XTotalOfSurplus, CFAccount."Account Type"::"End-Total", 1, '0002..2000',
          CFAccount."Source Type"::" ", CFAccount."G/L Integration"::" ");
        CreateCFAccount_andGL(
          '2100', XCashFlowFunds, CFAccount."Account Type"::Entry, 1, '',
          CFAccount."Source Type"::"Liquid Funds", CFAccount."G/L Integration"::Balance,
          CreateGLAccFilter('992940', '992910'));
        CreateCFAccount(
          '9999', XTotalCashFlow, CFAccount."Account Type"::"End-Total", 0, '0001..9999',
          CFAccount."Source Type"::" ", CFAccount."G/L Integration"::" ");
    end;

    procedure CreateCFAccount(No: Code[20]; Name: Text[30]; AccountType: Enum "Cash Flow Account Type"; Indentation: Integer; Totaling: Text[250]; SourceType: Enum "Cash Flow Source Type"; GLIntegration: Integer)
    begin
        CreateCFAccount_andGL(
          No,
          Name,
          AccountType,
          Indentation,
          Totaling,
          SourceType,
          GLIntegration,
          '')
    end;

    local procedure CreateCFAccount_andGL(No: Code[20]; Name: Text[30]; AccountType: Enum "Cash Flow Account Type"; Indentation: Integer; Totaling: Text[250]; SourceType: Enum "Cash Flow Source Type"; GLIntegration: Integer; GLAccount: Code[250])
    var
        CFAccount: Record "Cash Flow Account";
    begin
        if not CFAccount.Get(No) then
            CFAccount.Init();

        CFAccount."No." := No;
        CFAccount.Name := Name;
        CFAccount."Search Name" := Name;
        CFAccount."Account Type" := AccountType;
        CFAccount.Indentation := Indentation;
        CFAccount.Totaling := Totaling;
        CFAccount."Source Type" := SourceType;
        CFAccount."G/L Integration" := GLIntegration;

        CFAccount.Blocked := false;
        CFAccount."New Page" := false;
        CFAccount."No. of Blank Lines" := 0;
        CFAccount."Last Date Modified" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CFAccount.Comment := false;

        CFAccount."G/L Account Filter" := GLAccount;

        if not CFAccount.Modify() then
            CFAccount.Insert();
    end;

    local procedure CreateRevenue("Code": Code[10]; CashFlowAccountNo: Code[20]; Description: Text[30]; Amount: Decimal)
    var
        CFManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        CFManualRevenue.Init();
        CFManualRevenue.Code := Code;
        CFManualRevenue."Cash Flow Account No." := CashFlowAccountNo;
        CFManualRevenue.Description := Description;
        CFManualRevenue.Amount := Amount;

        CFManualRevenue."Starting Date" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CFManualRevenue."Ending Date" := MakeAdjustments.AdjustDate(DMY2Date(31, 12, 1903));
        Evaluate(CFManualRevenue."Recurring Frequency", '<1M>');
        if not CFManualRevenue.Modify() then
            CFManualRevenue.Insert();
    end;

    local procedure CreateExpens("Code": Code[10]; CashFlowAccountNo: Code[20]; Description: Text[30]; Amount: Decimal)
    var
        CFManualExpense: Record "Cash Flow Manual Expense";
    begin
        CFManualExpense.Init();
        CFManualExpense.Code := Code;
        CFManualExpense."Cash Flow Account No." := CashFlowAccountNo;
        CFManualExpense.Description := Description;
        CFManualExpense.Amount := Amount;

        CFManualExpense."Starting Date" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CFManualExpense."Ending Date" := MakeAdjustments.AdjustDate(DMY2Date(31, 12, 1903));
        Evaluate(CFManualExpense."Recurring Frequency", '<1M>');
        if not CFManualExpense.Modify() then
            CFManualExpense.Insert();
    end;

    local procedure CreateGLAccFilter(GLAccFromCode: Code[20]; GLAccToCode: Code[20]): Text[50]
    var
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        GLAccount.SetFilter(
          "No.", '%1|%2', MakeAdjustments.Convert(GLAccFromCode), MakeAdjustments.Convert(GLAccToCode));
        GLAccount.FindSet();
        GLAccNo := GLAccount."No.";
        GLAccount.Next();
        exit(StrSubstNo('%1..%2', GLAccNo, GLAccount."No."));
    end;

    local procedure CreateCFForecast(No: Code[20]; Description: Text[50]; NoSeriesCode: Code[20])
    begin
        CashFlowForecast.Init();
        CashFlowForecast."No." := No;
        CashFlowForecast."Search Name" := Description;
        CashFlowForecast.Description := Description;
        CashFlowForecast."Description 2" := '';
        CashFlowForecast."Consider Discount" := false;
        CashFlowForecast."Creation Date" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CashFlowForecast."Created By" := '';
        CashFlowForecast."Manual Payments To" := MakeAdjustments.AdjustDate(DMY2Date(31, 12, 1903));
        CashFlowForecast."No. Series" := NoSeriesCode;
        CashFlowForecast."Manual Payments From" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CashFlowForecast.Comment := false;
        CashFlowForecast."G/L Budget From" := MakeAdjustments.AdjustDate(DMY2Date(1, 1, 1903));
        CashFlowForecast."G/L Budget To" := MakeAdjustments.AdjustDate(DMY2Date(31, 12, 1903));
        CashFlowForecast.Insert();
    end;

    local procedure CreateCFSetup(CFForecastNoSeries: Code[20]; CFNoChartInRC: Code[20]; IncludeOrderFields: Boolean)
    begin
        if CFSetup.Get() then
            CFSetup.Delete();

        CFSetup.Init();
        CFSetup."Cash Flow Forecast No. Series" := CFForecastNoSeries;
        CFSetup."Receivables CF Account No." := '0010';
        CFSetup."Payables CF Account No." := '1010';
        if IncludeOrderFields then begin
            CFSetup."Sales Order CF Account No." := '0020';
            CFSetup."Purch. Order CF Account No." := '1020';
            CFSetup."Service CF Account No." := '0080';
            CFSetup."Job CF Account No." := '0080';
        end;
        CFSetup."FA Budget CF Account No." := '1070';
        CFSetup."FA Disposal CF Account No." := '0050';
        CFSetup."CF No. on Chart in Role Center" := CFNoChartInRC;
        CFSetup."Tax CF Account No." := '1100';
        CFSetup."Taxable Period" := CFSetup."Taxable Period"::Quarterly;
        CFSetup.Insert();
    end;

    local procedure CreateCFReportSelection()
    begin
        CFReportSelection.Init();
        CFReportSelection.Sequence := '2';
        CFReportSelection."Report ID" := 846;
        CFReportSelection."Report Caption" := XCashFlowDateListTxt;
        CFReportSelection.Insert();
    end;

    procedure InsertMiniAppData()
    var
        CreateNoSeries: Codeunit "Create No. Series";
        CFForecastNoSeries: Code[20];
        StartingNo: Code[20];
        LastNoUsed: Code[20];
    begin
        StartingNo := XDefaultCFCardNo;
        LastNoUsed := StartingNo; // First number used to create a Cash Flow Forecast
        CreateNoSeries.InitBaseSeries(CFForecastNoSeries, XCASHFLOW, XxCashFlow, StartingNo, '', LastNoUsed, '', 1);

        CreateCFForecast(LastNoUsed, XxCashFlow, CFForecastNoSeries);
        CreateCFSetup(CFForecastNoSeries, LastNoUsed, false);
        CreateCFAccounts();
        CreateCFReportSelection();
    end;
}

