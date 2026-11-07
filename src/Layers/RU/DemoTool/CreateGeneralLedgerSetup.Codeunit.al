codeunit 101098 "Create General Ledger Setup"
{

    trigger OnRun()
    var
        ExcelTemplate: Record "Excel Template";
    begin
        DemoDataSetup.Get();
        Currency.Get(DemoDataSetup."Currency Code");
        "General Ledger Setup".Get();
        UpdateFromCurrency();

        "General Ledger Setup".Validate("Allow Posting From", 0D);
        "General Ledger Setup".Validate("Allow Posting To", 0D);
        "General Ledger Setup".Validate("Global Dimension 1 Code", XDEPARTMENT);
        "General Ledger Setup".Validate("Global Dimension 2 Code", XINCEXP);
        "General Ledger Setup".Validate("Shortcut Dimension 3 Code", XPROJECT);
        "General Ledger Setup".Validate("Shortcut Dimension 4 Code", XCUSTOMERGROUP);
        "General Ledger Setup".Validate("Shortcut Dimension 5 Code", XAREA);
        "General Ledger Setup".Validate("Shortcut Dimension 6 Code", XBUSINESSGROUP);
        "General Ledger Setup".Validate("Shortcut Dimension 7 Code", XTAXKIND);
        "General Ledger Setup".Validate("Shortcut Dimension 8 Code", XTAXOBJ);

        if DemoDataSetup."Additional Currency Code" <> '' then
            "General Ledger Setup"."Additional Reporting Currency" := DemoDataSetup."Additional Currency Code";

        "General Ledger Setup"."Enable Data Check" := true;
        "General Ledger Setup"."Tax Invoice Renaming Threshold" := 0;
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Bank Account Nos.", XBANK, XBankAccounts, XBANK + '1', XBANK + '990', '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Bank Account Nos.", XCASH, XCashAccounts, XCASH + '1', XCASH + '990', '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."VAT Purch. Ledger No. Series",
          XVATPURLEDG, XVATPurchLedger, XPB000001, XPB999999, XPB000001, '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."VAT Sales Ledger No. Series",
          XVATSALLEDG, XVATSalesLedger, XSB000001, XSB999999, XSB000001, '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Contractor Invent. Act Nos.", XINVACT, XInventoryAct, XINV170001, XINV179999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "General Ledger Setup"."LCY Code" := XRUR;
        "General Ledger Setup".Validate("Unrealized VAT", true);
        "General Ledger Setup".Validate("Currency Adjmt with Correction", false);
        "General Ledger Setup".Validate("Enable Russian Accounting", true);
        "General Ledger Setup".Validate("Mark Cr. Memos as Corrections", true);
        Evaluate("General Ledger Setup"."Short-Term Due Period", '<+1Y>');
        "General Ledger Setup"."EMU Currency" := DemoDataSetup."LCY an EMU Currency";
        "General Ledger Setup".Validate("Check G/L Account Usage", true);
        "General Ledger Setup".Validate("Max. VAT Difference Allowed", 2);
        "General Ledger Setup".Validate("Summarize Gains/Losses", true);
        "General Ledger Setup".Validate("Automatic G/L Correspondence", true);
        "General Ledger Setup".Validate("Cancel Curr. Prepmt. Adjmt.", true);

        if DemoDataSetup."Import Electronic Reporting" and
           (not DemoDataSetup."Skip sequence of actions") and
           (not DemoDataSetup."Skip creation of master data")
        then
            "General Ledger Setup"."Shared Account Schedule" := Translate.ReportCode('GENREPORT');

        "General Ledger Setup"."Analytic Acc. Card Code" := XANALYTCARD;
        ExcelTemplate.InsertTemplate(XANALYTCARD, XAnalyticAccountCard, 'LocalFiles\Analytic_Account_Card.xlsx');
        "General Ledger Setup"."Bank Payment Order Tmpl. Code" := XBANKPO;
        ExcelTemplate.InsertTemplate(
          XBANKPO, XBankPaymentOrder, 'LocalFiles\BankPaymentOrder.xlsx');
        "General Ledger Setup"."Cash Order KO3 Template Code" := XCO3;
        ExcelTemplate.InsertTemplate(XCO3, XCashOrder3, 'LocalFiles\KO_3.xlsx');
        "General Ledger Setup"."Cash Order KO4 Template Code" := XCO4;
        ExcelTemplate.InsertTemplate(XCO4, XCashOrder4, 'LocalFiles\KO_4.xlsx');
        "General Ledger Setup"."Cash Ingoing Order Tmpl. Code" := XCIN;
        ExcelTemplate.InsertTemplate(XCIN, XCashOrderIngoing, 'LocalFiles\KO_Ingoing.xlsx');
        "General Ledger Setup"."Cash Outgoin Order Tmpl. Code" := XCOUT;
        ExcelTemplate.InsertTemplate(XCOUT, XCashOrderOutgoing, 'LocalFiles\KO_Outgoing.xlsx');
        "General Ledger Setup"."C/V Recon. Act Template Code" := XRECONACT;
        ExcelTemplate.InsertTemplate(XRECONACT, XReconciliationAct, 'LocalFiles\Reconciliation Act.xlsx');
        "General Ledger Setup"."Show Amounts" := "General Ledger Setup"."Show Amounts"::"All Amounts";
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        VATRegistrationLogMgt.InitServiceSetup();
    end;

    var
        "General Ledger Setup": Record "General Ledger Setup";
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        GLAccountCategory: Record "G/L Account Category";
        "Create No. Series": Codeunit "Create No. Series";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        XDEPARTMENT: Label 'DEPARTMENT';
        XPROJECT: Label 'PROJECT';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XAREA: Label 'AREA';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XBANK: Label 'BANK';
        XB10: Label 'B10';
        XPB000001: Label 'PB000001';
        XPB999999: Label 'PB999999';
        XSB000001: Label 'SB000001';
        XSB999999: Label 'SB999999';
        XINVACT: Label 'INV17';
        XInventoryAct: Label 'Contractors Inventory Act';
        XINV170001: Label 'INV170001';
        XINV179999: Label 'INV179999';
        XRUR: Label 'RUR';
        XINCEXP: Label 'INCEXP';
        XTAXKIND: Label 'TAXKIND';
        XTAXOBJ: Label 'TAXOBJ';
        XBankAccounts: Label 'Bank Accounts';
        XCashAccounts: Label 'Cash Accounts';
        XCASH: Label 'CASH';
        XVATPURLEDG: Label 'VATPURLEDG';
        XVATSALLEDG: Label 'VATSALLEDG';
        XVATPurchLedger: Label 'VAT Purchase Ledger';
        XVATSalesLedger: Label 'VAT Sales Ledger';
        XANALYTCARD: Label 'ANALYTCARD';
        XAnalyticAccountCard: Label 'Analytic Account Card';
        Translate: Codeunit "Translate Accounting";
        XBANKPO: Label 'BANK-PO';
        XBankPaymentOrder: Label 'Bank Payment Order';
        XCO3: Label 'CASH-CO3';
        XCashOrder3: Label 'Cash Order CO-3';
        XCO4: Label 'CASH-CO4';
        XCashOrder4: Label 'Cash Order CO-4';
        XCIN: Label 'CASH-IN';
        XCashOrderIngoing: Label 'Cash Order Ingoing';
        XCOUT: Label 'CASH-OUT';
        XCashOrderOutgoing: Label 'Cash Order Outgoing';
        XRECONACT: Label 'RECONACT';
        XReconciliationAct: Label 'Reconciliation Act';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        Currency.Get(DemoDataSetup."Currency Code");
        "General Ledger Setup".Get();
        UpdateFromCurrency();

        "General Ledger Setup".Validate("Allow Posting From", 0D);
        "General Ledger Setup".Validate("Allow Posting To", 0D);
        "General Ledger Setup".Validate("Unrealized VAT", false);
        "General Ledger Setup".Validate("Adjust for Payment Disc.", false);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Bank Account Nos.", XBANK, XBANK, XB10, 'B990', '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "General Ledger Setup"."EMU Currency" := DemoDataSetup."LCY an EMU Currency";
        "General Ledger Setup"."Local Cont. Addr. Format" := "General Ledger Setup"."Local Cont. Addr. Format"::"After Company Name";
        "General Ledger Setup"."Show Amounts" := "General Ledger Setup"."Show Amounts"::"All Amounts";
        "General Ledger Setup"."Enable Data Check" := true;
        "General Ledger Setup".Validate("Unrealized VAT", true);
        "General Ledger Setup".Validate("Currency Adjmt with Correction", false);
        "General Ledger Setup".Validate("Enable Russian Accounting", true);
        "General Ledger Setup".Validate("Mark Cr. Memos as Corrections", true);
        Evaluate("General Ledger Setup"."Short-Term Due Period", '<+1Y>');
        "General Ledger Setup".Validate("Check G/L Account Usage", true);
        "General Ledger Setup".Validate("Max. VAT Difference Allowed", 2);
        "General Ledger Setup".Validate("Summarize Gains/Losses", true);
        "General Ledger Setup".Validate("Automatic G/L Correspondence", true);
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        VATRegistrationLogMgt.InitServiceSetup();
    end;

    procedure InsertEvaluationData()
    begin
        "General Ledger Setup".Get();
        "General Ledger Setup".Validate("Global Dimension 1 Code", XDEPARTMENT);
        "General Ledger Setup".Validate("Global Dimension 2 Code", XCUSTOMERGROUP);
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
    end;

    local procedure UpdateFromCurrency()
    begin
        "General Ledger Setup".Validate("Inv. Rounding Precision (LCY)", Currency."Invoice Rounding Precision");
        "General Ledger Setup"."Amount Rounding Precision" := Currency."Amount Rounding Precision";
        "General Ledger Setup"."Unit-Amount Rounding Precision" := Currency."Unit-Amount Rounding Precision";
        "General Ledger Setup"."Amount Decimal Places" := Currency."Amount Decimal Places";
        "General Ledger Setup"."Unit-Amount Decimal Places" := Currency."Unit-Amount Decimal Places";
        "General Ledger Setup".Validate("LCY Code", Currency.Code);
    end;
}

