codeunit 101334 "Create Column Layout"
{

    trigger OnRun()
    begin
        InsertEvaluationData();
        InsertData(XACTBUD, 'A', XNetChange, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XACTBUD, 'B', XBudget, 1, 1, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XACTBUD, 'C', XVariance, 0, 0, "Account Schedule Amount Type"::"Net Amount", XAB, '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XACTBUD, 'D', XAB, 0, 0, "Account Schedule Amount Type"::"Net Amount", XAB100, '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        SetHideCurrencySymbol(XACTBUD, 40000);

        InsertData(XBUDGANALYS, XN, XNetChange, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XBUDGANALYS, XB, XBudget, 1, 1, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        VarPercentCalcFormula := '100*(%1/%2-1)';
        VarPercentCalcFormula := StrSubstNo(VarPercentCalcFormula, XN, XB);
        InsertData(XBUDGANALYS, '', XVariancePERCENT, 0, 0, "Account Schedule Amount Type"::"Net Amount", VarPercentCalcFormula, '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        SetHideCurrencySymbol(XBUDGANALYS, 30000);
        // InsertData(XBUDGANALYS,'',XNetChangeLastYear,1,0,0,'','<-1Y>',FALSE,0,0);
        InsertData(XBALANCE, '', XCurrentFiscalYear, 2, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XBALANCE, '', XLastFiscalYear, 2, 0, "Account Schedule Amount Type"::"Net Amount", '', '<-1Y>', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XPYG, '', XCurrentFiscalYear, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
        InsertData(XPYG, '', XLastFiscalYear, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '<-1Y>', false, "Column Layout Show"::Always, "Analysis Rounding Factor"::None);
    end;

    var
        "Line No.": Integer;
        "Previous Column Layout Name": Code[10];
        VarPercentCalcFormula: Code[80];
        XDEFAULT: Label 'DEFAULT';
        XNetChangeDebit: Label 'Net Change Debit';
        XNetChangeCredit: Label 'Net Change Credit';
        XBalanceatDateDebit: Label 'Balance at Date Debit';
        XBalanceatDateCredit: Label 'Balance at Date Credit';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of Column Layout.';
        XAmount: Label 'Amount';
        XAmountUntilDate: Label 'Amount until date';
        XEntireFiscalYear: Label 'Entire Fiscal Year';
        XDEGREE: Label 'DEGREE', Comment = 'Degree is a name of Column Layout.';
        XKeyFigure: Label 'Key Figure';
        XBUDGANALYS: Label 'BUDGANALYS';
        XN: Label 'N';
        XNetChange: Label 'Net Change';
        XB: Label 'B';
        XBudget: Label 'Budget';
        XVariancePERCENT: Label 'Variance%';
        XACTBUD: Label 'Act/Bud';
        XVariance: Label 'Variance';
        XAB: Label 'A-B';
        XAB100: Label 'A / B * 100';
        XBALANCE: Label 'BALANCE';
        XPYG: Label 'PYG';
        XCurrentFiscalYear: Label 'Current Fiscal Year';
        XLastFiscalYear: Label 'Last Fiscal Year';
        XBeginningBalanceTxt: Label 'Beginning Balance';
        XEndingBalanceTxt: Label 'Ending Balance';
        XDebitsTxt: Label 'Debits';
        XCreditsTxt: Label 'Credits';
        XJanuaryTxt: Label 'January';
        XFebruaryTxt: Label 'February';
        XMarchTxt: Label 'March';
        XAprilTxt: Label 'April';
        XMayTxt: Label 'May';
        XJuneTxt: Label 'June';
        XJulyTxt: Label 'July';
        XAugustTxt: Label 'August';
        XSeptemberTxt: Label 'September';
        XOctoberTxt: Label 'October';
        XNovemberTxt: Label 'November';
        XDecemberTxt: Label 'December';
        XCurrentMonthBalanceTxt: Label 'Current Month Balance';
        XPriorMonthBalanceTxt: Label 'Prior Month Balance';
        XDifferenceTxt: Label 'Difference';
        XSameMonthPriorYearBalanceTxt: Label 'Same Month Prior Year Balance';
        XCurrentMonthNetChangeTxt: Label 'Current Month Net Change';
        XPriorMonthNetChangeTxt: Label 'Prior Month Net Change';
        XTotalTxt: Label 'Total';
        XSameMonthPriorYearNetChangeTxt: Label 'Same Month Prior Year Net Change';
        XCurrentMonthActualTxt: Label 'Current Month Actual';
        XCurrentMonthBudgetTxt: Label 'Current Month Budget';
        XYearToDateActualTxt: Label 'Year to Date Actual';
        XYearToDateBudgetTxt: Label 'Year to Date Budget';
        XTotalBudgetPlannedTxt: Label 'Total Budget Planned';
        XTotalBudgetRemainingTxt: Label 'Total Budget Remaining';

    procedure InsertEvaluationData();
    var
        ColumnLayout: Record "Column Layout";
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
    begin
        InsertDataLight(XCASHFLOW, 'S10', XAmount, ColumnLayout."Column Type"::"Net Change".AsInteger());
        InsertDataLight(XCASHFLOW, 'S20', XAmountUntilDate, ColumnLayout."Column Type"::"Balance at Date".AsInteger());
        InsertDataLight(XCASHFLOW, 'S30', XEntireFiscalYear, ColumnLayout."Column Type"::"Entire Fiscal Year".AsInteger());
        InsertDataLight(XDEGREE, 'S10', XKeyFigure, ColumnLayout."Column Type"::"Balance at Date".AsInteger());
        InsertData(XDEFAULT, '', XNetChangeDebit, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::"When Positive", "Analysis Rounding Factor"::None);
        InsertData(XDEFAULT, '', XNetChangeCredit, 1, 0, "Account Schedule Amount Type"::"Net Amount", '', '', true, "Column Layout Show"::"When Negative", "Analysis Rounding Factor"::None);
        InsertData(XDEFAULT, '', XBalanceatDateDebit, 2, 0, "Account Schedule Amount Type"::"Net Amount", '', '', false, "Column Layout Show"::"When Positive", "Analysis Rounding Factor"::None);
        InsertData(XDEFAULT, '', XBalanceatDateCredit, 2, 0, "Account Schedule Amount Type"::"Net Amount", '', '', true, "Column Layout Show"::"When Negative", "Analysis Rounding Factor"::None);

        // Trial Balance
        InsertData(CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '1', CopyStr(XBeginningBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Beginning Balance".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '2', CopyStr(XDebitsTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Debit Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '3', CopyStr(XCreditsTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Credit Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '4', CopyStr(XEndingBalanceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1+2-3', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);

        // Balance Sheet trend
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '1', CopyStr(XJanuaryTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '2', CopyStr(XFebruaryTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[2]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '3', CopyStr(XMarchTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[3]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '4', CopyStr(XAprilTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[4]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '5', CopyStr(XMayTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[5]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '6', CopyStr(XJuneTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[6]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '7', CopyStr(XJulyTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[7]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '8', CopyStr(XAugustTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[8]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '9', CopyStr(XSeptemberTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[9]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '10', CopyStr(XOctoberTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[10]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '11', CopyStr(XNovemberTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[11]', 1033);
        InsertData(CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '12', CopyStr(XDecemberTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[12]', 1033);

        // Current Month Balance
        InsertData(CreateColumnLayoutName.GetCBColumnLayoutName(), '1', CopyStr(XCurrentMonthBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCBVPBColumnLayoutName(), '1', CopyStr(XCurrentMonthBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCBVPBColumnLayoutName(), '2', CopyStr(XPriorMonthBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1P', 1033);
        InsertData(CreateColumnLayoutName.GetCBVPBColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCBVSPYBColumnLayoutName(), '1', CopyStr(XCurrentMonthBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCBVSPYBColumnLayoutName(), '2', CopyStr(XSameMonthPriorYearBalanceTxt, 1, 30), ColumnLayout."Column Type"::"Balance at Date".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1FY', 1033);
        InsertData(CreateColumnLayoutName.GetCBVSPYBColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);

        // Current Month Net Change
        InsertData(CreateColumnLayoutName.GetCNCColumnLayoutName(), '1', CopyStr(XCurrentMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '1', CopyStr(XJanuaryTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '2', CopyStr(XFebruaryTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[2]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '3', CopyStr(XMarchTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[3]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '4', CopyStr(XAprilTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[4]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '5', CopyStr(XMayTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[5]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '6', CopyStr(XJuneTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[6]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '7', CopyStr(XJulyTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[7]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '8', CopyStr(XAugustTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[8]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '9', CopyStr(XSeptemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[9]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '10', CopyStr(XOctoberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[10]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '11', CopyStr(XNovemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[11]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '12', CopyStr(XDecemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[12]', 1033);
        InsertData(CreateColumnLayoutName.GetCNCBUDColumnLayoutName(), '13', CopyStr(XTotalTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1..12', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCNCVPNCColumnLayoutName(), '1', CopyStr(XCurrentMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCColumnLayoutName(), '2', CopyStr(XPriorMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCNCVSPYNCColumnLayoutName(), '1', CopyStr(XCurrentMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVSPYNCColumnLayoutName(), '2', CopyStr(XSameMonthPriorYearNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1FY', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVSPYNCColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '1', CopyStr(XCurrentMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '2', CopyStr(XPriorMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '4', '', ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '5', CopyStr(XCurrentMonthNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '6', CopyStr(XSameMonthPriorYearNetChangeTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, '-1FY', 1033);
        InsertData(CreateColumnLayoutName.GetCNCVPNCYOYColumnLayoutName(), '7', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '5-6', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);

        // Current Month Budget
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '1', CopyStr(XCurrentMonthActualTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '2', CopyStr(XCurrentMonthBudgetTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'P', 1033);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '3', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '1-2', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '4', '', ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '5', CopyStr(XYearToDateActualTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1..CP]', 1033);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '6', CopyStr(XYearToDateBudgetTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1..CP]', 1033);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '7', CopyStr(XDifferenceTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '5-6', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '8', '', ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '9', CopyStr(XTotalBudgetPlannedTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1..12]', 1033);
        InsertData(CreateColumnLayoutName.GetCVCYTDBUDColumnLayoutName(), '10', CopyStr(XTotalBudgetRemainingTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::"Budget Entries".AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '9-5', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);

        // Income Statement Trend 
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XJanuaryTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[1]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XFebruaryTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[2]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XMarchTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[3]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XAprilTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[4]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XMayTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[5]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XJuneTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[6]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XJulyTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[7]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XAugustTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[8]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XSeptemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[9]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XOctoberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[10]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XNovemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[11]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), 'A', CopyStr(XDecemberTxt, 1, 30), ColumnLayout."Column Type"::"Net Change".AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", '', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None, 'FY[12]', 1033);
        InsertData(CreateColumnLayoutName.GetISTrendColumnLayoutName(), '', CopyStr(XTotalTxt, 1, 30), ColumnLayout."Column Type"::Formula.AsInteger(), ColumnLayout."Ledger Entry Type"::Entries.AsInteger(), ColumnLayout."Amount Type"::"Net Amount", 'A', '', false, ColumnLayout.Show::Always, ColumnLayout."Rounding Factor"::None);
    end;

    procedure InsertData(ColumnLayoutName: Code[10]; "Column No.": Code[10]; "Column Header": Text[30]; "Column Type": Option Formula,"Net Change","Balance at Date","Beginning Balance","Year to Date"," Rest of Fiscal Year","Entire Fiscal Year"; "Ledger Entry Type": Option Entries,"Budget Entries"; "Amount Type": Enum "Account Schedule Amount Type"; Formula: Code[80]; "Comparison Date Formula": Code[10]; "Show Opposite Sign": Boolean; Show: Enum "Column Layout Show"; "Rounding Factor": Enum "Analysis Rounding Factor")
    begin
        InsertData(ColumnLayoutName, "Column No.", "Column Header", "Column Type", "Ledger Entry Type", "Amount Type", Formula, "Comparison Date Formula", "Show Opposite Sign", Show, "Rounding Factor", '', 0);
    end;

    procedure InsertData(ColumnLayoutName: Code[10]; "Column No.": Code[10]; "Column Header": Text[30]; "Column Type": Option Formula,"Net Change","Balance at Date","Beginning Balance","Year to Date"," Rest of Fiscal Year","Entire Fiscal Year"; "Ledger Entry Type": Option Entries,"Budget Entries"; "Amount Type": Enum "Account Schedule Amount Type"; Formula: Code[80]; "Comparison Date Formula": Code[10]; "Show Opposite Sign": Boolean; Show: Enum "Column Layout Show"; "Rounding Factor": Enum "Analysis Rounding Factor"; ComparisonPeriodFormula: Code[20]; ComparisonPeriodFormulaLCID: Integer)
    var
        "Column Layout": Record "Column Layout";
    begin
        "Column Layout".Init();
        "Column Layout".Validate("Column Layout Name", ColumnLayoutName);
        if "Previous Column Layout Name" <> ColumnLayoutName then begin
            "Line No." := 10000;
            "Previous Column Layout Name" := ColumnLayoutName;
        end else
            "Line No." := "Line No." + 10000;
        "Column Layout".Validate("Line No.", "Line No.");
        "Column Layout".Validate("Column No.", "Column No.");
        "Column Layout".Validate("Column Header", "Column Header");
        "Column Layout".Validate("Column Type", "Column Type");
        "Column Layout".Validate("Ledger Entry Type", "Ledger Entry Type");
        "Column Layout".Validate("Amount Type", "Amount Type");
        "Column Layout".Validate(Formula, Formula);
        Evaluate("Column Layout"."Comparison Date Formula", "Comparison Date Formula");
        "Column Layout".Validate("Comparison Date Formula");
        "Column Layout".Validate("Show Opposite Sign", "Show Opposite Sign");
        "Column Layout".Validate(Show, Show);
        "Column Layout".Validate("Rounding Factor", "Rounding Factor");
        "Column Layout".Validate("Comparison Period Formula LCID", ComparisonPeriodFormulaLCID);
        "Column Layout"."Comparison Period Formula" := ComparisonPeriodFormula;
        "Column Layout".Insert();
    end;

    local procedure InsertDataLight(ColumnLayoutName: Code[10]; ColumnNo: Code[10]; ColumnHeader: Text[30]; ColumnType: Option Formula,"Net Change","Balance at Date","Beginning Balance","Year to Date"," Rest of Fiscal Year","Entire Fiscal Year")
    var
        ColumnLayout: Record "Column Layout";
    begin
        InsertData(
          ColumnLayoutName, ColumnNo, ColumnHeader, ColumnType,
          ColumnLayout."Ledger Entry Type"::Entries.AsInteger(),
          ColumnLayout."Amount Type"::"Net Amount",
          '',
          '',
          false,
          ColumnLayout.Show::Always,
          ColumnLayout."Rounding Factor"::None);
    end;

    procedure InsertMiniAppData(ColumnLayoutName: Code[10]; ColumnNo: Code[10]; ColumnHeader: Code[30]; LineNo: Integer; ComparisonPeriodFormula: Text[10])
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        ColumnLayout.Validate("Column Layout Name", ColumnLayoutName);
        ColumnLayout.Validate("Line No.", LineNo);
        ColumnLayout.Validate("Column No.", ColumnNo);
        ColumnLayout.Validate("Column Header", ColumnHeader);
        ColumnLayout.Validate("Comparison Period Formula", ComparisonPeriodFormula);
        ColumnLayout.Insert();

        // Insert "empty" line for applying Acc. Sched. Chart Setup Line throug Rapid Start
        if ColumnLayout.Get('', LineNo) then
            exit;
        ColumnLayout.Init();
        ColumnLayout.Validate("Column Layout Name", '');
        ColumnLayout.Validate("Line No.", LineNo);
        ColumnLayout.Insert();
    end;

    procedure SetHideCurrencySymbol(ColumnLayoutName: Code[10]; LineNo: Integer)
    var
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayout.Get(ColumnLayoutName, LineNo) then begin
            ColumnLayout.Validate("Hide Currency Symbol", true);
            ColumnLayout.Modify();
        end;
    end;
}
