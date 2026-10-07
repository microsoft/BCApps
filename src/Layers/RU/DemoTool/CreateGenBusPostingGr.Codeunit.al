codeunit 101250 "Create Gen. Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XBUSINESS, XCustsAndVends, '');
        InsertData(XSTARTBAL, XBeginningBalance, '');
        InsertData(XINTERCOMP, XIntercompPosting, '');
        InsertData(XINCOME_91, XExcessAmtOfGoods, '');
        InsertData(XEXP + '_08_31', StrSubstNo(XInCostOfAccount, '08-3100'), '');
        InsertData(XEXP + '_08_32', StrSubstNo(XInCostOfAccount, '08-3200'), '');
        InsertData(XEXP + '_08_33', StrSubstNo(XInCostOfAccount, '08-3300'), '');
        InsertData(XEXP + '_08_80', StrSubstNo(XInCostOfAccount, '08-8000'), '');
        InsertData(XEXP + '_08_90', StrSubstNo(XInCostOfAccount, '08-9000'), '');
        InsertData(XEXP + '_20', StrSubstNo(XInCostOfAccount, '20'), '');
        InsertData(XEXP + '_21', StrSubstNo(XInCostOfAccount, '21'), '');
        InsertData(XEXP + '_23', StrSubstNo(XInCostOfAccount, '23'), '');
        InsertData(XEXP + '_25', StrSubstNo(XInCostOfAccount, '25'), '');
        InsertData(XEXP + '_26', StrSubstNo(XInCostOfAccount, '26'), '');
        InsertData(XEXP + '_29', StrSubstNo(XInCostOfAccount, '29'), '');
        InsertData(XEXP + '_44', StrSubstNo(XInCostOfAccount, '44'), '');
        InsertData(XEXP + '_91', StrSubstNo(XInCostOfAccount, '91'), '');
        InsertData(XEXP + '_94', StrSubstNo(XInCostOfAccount, '94'), '');

        InsertData(XEXP + '_20' + XN, StrSubstNo(XInCostOfAccountExclTax, '20'), '');
        InsertData(XEXP + '_26' + XN, StrSubstNo(XInCostOfAccountExclTax, '26'), '');
        InsertData(XEXP + '_44' + XN, StrSubstNo(XInCostOfAccountExclTax, '44'), '');
        InsertData(XEXP + '_91' + XN, StrSubstNo(XInCostOfAccountExclTax, '91'), '');
        InsertData(XPAYROLL, XPayrollDesc, '');
        InsertData(XTEST, XTestAutomation, XTEST);
    end;

    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XBUSINESS: Label 'BUSINESS';
        XSTARTBAL: Label 'STARTBAL';
        XINTERCOMP: Label 'INTERCOMP';
        XINCOME_91: Label 'INCOME_91';
        XEXP: Label 'EXP';
        XN: Label 'N';
        XPAYROLL: Label 'PAYROLL';
        XPayrollDesc: Label 'Payroll';
        XCustsAndVends: Label 'Customers, vendors';
        XBeginningBalance: Label 'Beginning balance';
        XIntercompPosting: Label 'Intercompany posting';
        XExcessAmtOfGoods: Label 'Exc. amt. of goods after physical inven.';
        XInCostOfAccount: Label 'In cost of acc. %1';
        XInCostOfAccountExclTax: Label 'In cost of acc. %1 excluding tax liabilities';
        XTEST: Label '_TEST';
        XTestAutomation: Label 'Test Automation';

    procedure InsertData("Code": Code[20]; Description: Text[50]; DefVATBusPostingGroup: Code[20])
    begin
        GenBusinessPostingGroup.Init();
        GenBusinessPostingGroup.Validate(Code, Code);
        GenBusinessPostingGroup.Validate(Description, Description);
        GenBusinessPostingGroup."Def. VAT Bus. Posting Group" := DefVATBusPostingGroup;
        if DefVATBusPostingGroup <> '' then
            GenBusinessPostingGroup."Auto Insert Default" := true;
        GenBusinessPostingGroup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XBUSINESS, XCustsAndVends, '');
        InsertData(XINTERCOMP, XIntercompPosting, '');
        InsertData(XTEST, XTestAutomation, XTEST);
    end;

    procedure GetBusinessCode(): Code[10]
    begin
        exit(XBUSINESS);
    end;
}

