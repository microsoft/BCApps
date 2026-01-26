codeunit 101333 "Create Column Layout Name"
{

    trigger OnRun()
    begin
        InsertEvaluationData();
        InsertData(XBUDGANALYS, XBudgetAnalysis);
        InsertData(XDEFAULT, XStandardColumnLayout);
        InsertData(XACTBUD, XActBudComparision);
        // Modif Demo Finance (CM) : ajout d'une présentation pour le compte de résultat
        InsertData(XPROFITANDLOSS, XProfAndLossAcc);
    end;

    var
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of the Column Layout.';
        XBALONLY: Label 'BAL ONLY', Comment = 'BAL ONLY is a name of the Column Layout.';
        XBalanceOnly: Label 'Balance Only';
        XComparisonMonthYear: Label 'Comparison month - year';
        XDEGREE: Label 'DEGREE';
        XKeyCashFlowRatioTxt: Label 'Key Cash Flow Ratio';
        XBUDGANALYS: Label 'BUDGANALYS';
        XBudgetAnalysis: Label 'Budget Analysis';
        XDEFAULT: Label 'DEFAULT', Comment = 'Default is a name of Column Layout.';
        XStandardColumnLayout: Label 'Standard Column Layout';
        XACTBUD: Label 'Act/Bud';
        XActBudComparision: Label 'Actual / Budget Comparision';
        XPROFITANDLOSS: Label 'PROFIT';
        XProfAndLossAcc: Label 'Prof. & Loss Acc.';
        XBSTRENDTxt: Label 'BSTREND', Comment = 'Max 10 characters - abbreviation of Balance Sheet Trend';
        XISTRENDTxt: Label 'ISTREND', Comment = 'Max 10 characters - abbreviation of Income Statement Trend';
        XBBDRCREBTxt: Label 'BBDRCREB', Comment = 'Max 10 characters - abbreviation of Beginning Balance Debits Credits Ending Balance';
        XBBDRCREBDescTxt: Label 'TB Beginning Balance Debits Credits Ending Balance', Comment = 'TB - abbreviation of Trial Balance';
        XISTRENDDescTxt: Label 'IS 12 Months Net Change Trending Current Fiscal Year', Comment = 'IS - abbreviation of Income Statement';
        XBSTRENDDescTxt: Label 'BS 12 Months Balance Trending Current Fiscal Year', Comment = 'BS - abbreviation of Balance Sheet';
        XCBTxt: Label 'CB', Locked = true;
        XCBVPBTxt: Label 'CB V PB', Locked = true;
        XCBVSPYBTxt: Label 'CB V SPYB', Locked = true;
        XCNCTxt: Label 'CNC', Locked = true;
        XCNCBUDTxt: Label 'CNC BUD', Locked = true;
        XCNCVPNCTxt: Label 'CNC V PNC', Locked = true;
        XCNCVSPYNCTxt: Label 'CNC VSPYNC', Locked = true;
        XCNCVPNCYOYTxt: Label 'CNCVPNCYOY', Locked = true;
        XCVCYTDBUDTxt: Label 'CVC YTDBUD', Locked = true;
        XCBDescTxt: Label 'BS Current Month Balance', Comment = 'BS - abbreviation of Balance Sheet';
        XCBVPBDescTxt: Label 'BS Current Month Balance v Prior Month Balance', Comment = 'BS - abbreviation of Balance Sheet';
        XCBVSPYBDescTxt: Label 'BS Current Month Balance v Same Month Prior Year Balance', Comment = 'BS - abbreviation of Balance Sheet';
        XCNCDescTxt: Label 'IS Current Month Net Change', Comment = 'IS - abbreviation of Income Statement';
        XCNCBUDDescTxt: Label 'IS 12 Months Net Change Budget Only', Comment = 'IS - abbreviation of Income Statement';
        XCNCVPNCDescTxt: Label 'IS Current Month Net Change v Prior Month Net Change', Comment = 'IS - abbreviation of Income Statement';
        XCNCVSPYNCDescTxt: Label 'IS Current Month Net Change v Same Month Prior Year Net Change', Comment = 'IS - abbreviation of Income Statement';
        XCNCVPNCYOYDescTxt: Label 'IS Current Month v Prior Month for CY and Current Month v Prior Month for PY', Comment = 'IS - abbreviation of Income Statement';
        XCVCYTDBUDDescTxt: Label 'IS Current Month v Budget Year to Date v Budget and Bud Total and Bud Remaining ', Comment = 'IS - abbreviation of Income Statement';

    procedure InsertEvaluationData();
    begin
        InsertData(XCASHFLOW, XComparisonMonthYear);
        InsertData(XDEGREE, XKeyCashFlowRatioTxt);
        InsertData(XBALONLY, XBalanceOnly);

        InsertData(XBSTRENDTxt, CopyStr(XBSTRENDDescTxt, 1, 80));
        InsertData(XISTRENDTxt, CopyStr(XISTRENDDescTxt, 1, 80));
        InsertData(XBBDRCREBTxt, CopyStr(XBBDRCREBDescTxt, 1, 80));
        InsertData(XCBTxt, CopyStr(XCBDescTxt, 1, 80));
        InsertData(XCBVPBTxt, CopyStr(XCBVPBDescTxt, 1, 80));
        InsertData(XCBVSPYBTxt, CopyStr(XCBVSPYBDescTxt, 1, 80));
        InsertData(XCNCTxt, CopyStr(XCNCDescTxt, 1, 80));
        InsertData(XCNCBUDTxt, CopyStr(XCNCBUDDescTxt, 1, 80));
        InsertData(XCNCVPNCTxt, CopyStr(XCNCVPNCDescTxt, 1, 80));
        InsertData(XCNCVSPYNCTxt, CopyStr(XCNCVSPYNCDescTxt, 1, 80));
        InsertData(XCNCVPNCYOYTxt, CopyStr(XCNCVPNCYOYDescTxt, 1, 80));
        InsertData(XCVCYTDBUDTxt, CopyStr(XCVCYTDBUDDescTxt, 1, 80));
    end;

    procedure InsertData(Name: Code[10]; Description: Text[80])
    var
        "Column Layout Name": Record "Column Layout Name";
    begin
        "Column Layout Name".Init();
        "Column Layout Name".Validate(Name, Name);
        "Column Layout Name".Validate(Description, Description);
        "Column Layout Name".Insert();
    end;

    internal procedure GetISTrendColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XISTRENDTxt, 1, 10));
    end;

    internal procedure GetBSTrendColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XBSTRENDTxt, 1, 10));
    end;

    internal procedure GetBBDRCREBColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XBBDRCREBTxt, 1, 10));
    end;

    internal procedure GetCBColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCBTxt, 1, 10));
    end;

    internal procedure GetCBVPBColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCBVPBTxt, 1, 10));
    end;

    internal procedure GetCBVSPYBColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCBVSPYBTxt, 1, 10));
    end;

    internal procedure GetCNCColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCNCTxt, 1, 10));
    end;

    internal procedure GetCNCBUDColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCNCBUDTxt, 1, 10));
    end;

    internal procedure GetCNCVPNCColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCNCVPNCTxt, 1, 10));
    end;

    internal procedure GetCNCVSPYNCColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCNCVSPYNCTxt, 1, 10));
    end;

    internal procedure GetCNCVPNCYOYColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCNCVPNCYOYTxt, 1, 10));
    end;

    internal procedure GetCVCYTDBUDColumnLayoutName(): Code[10]
    begin
        exit(CopyStr(XCVCYTDBUDTxt, 1, 10));
    end;
}

