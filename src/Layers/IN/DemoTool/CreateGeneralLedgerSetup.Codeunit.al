codeunit 101098 "Create General Ledger Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        Currency.Get(DemoDataSetup."Currency Code");
        "General Ledger Setup".Get();
        UpdateFromCurrency();

        "General Ledger Setup".Validate("Allow Posting From", 0D);
        "General Ledger Setup".Validate("Allow Posting To", 0D);
        if DemoDataSetup."Advanced Setup" then begin
            "General Ledger Setup".Validate("Unrealized VAT", true);
            if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
                "General Ledger Setup".Validate("Summarize G/L Entries", true);
        end;
        "General Ledger Setup".Validate("Adjust for Payment Disc.", DemoDataSetup."Adjust for Payment Discount");
        "General Ledger Setup".Validate("Global Dimension 1 Code", XDEPARTMENT);
        "General Ledger Setup".Validate("Global Dimension 2 Code", XPROJECT);
        "General Ledger Setup".Validate("Shortcut Dimension 3 Code", XCUSTOMERGROUP);
        "General Ledger Setup".Validate("Shortcut Dimension 4 Code", XAREA);
        "General Ledger Setup".Validate("Shortcut Dimension 5 Code", XBUSINESSGROUP);
        "General Ledger Setup".Validate("Shortcut Dimension 6 Code", XSALESCAMPAIGN);

        if DemoDataSetup."Additional Currency Code" <> '' then
            "General Ledger Setup"."Additional Reporting Currency" := DemoDataSetup."Additional Currency Code";

        "General Ledger Setup"."Enable Data Check" := true;
        "General Ledger Setup"."Tax Invoice Renaming Threshold" := 0;
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Bank Account Nos.", XBANK, XBANK, XB10, 'B990', '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "General Ledger Setup"."EMU Currency" := DemoDataSetup."LCY an EMU Currency";
        "General Ledger Setup"."Local Address Format" := "General Ledger Setup"."Local Address Format"::"Post Code+City";
        "General Ledger Setup"."Show Amounts" := "General Ledger Setup"."Show Amounts"::"Amount Only";
        "General Ledger Setup".Validate("LCY Code", XLCY);
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        UpdateGeneralLedgerSetup(
            XGSTDist, XGSTCreditAdjJnlNos, XGSTSettlementNos, 0);
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
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XBANK: Label 'BANK';
        XB10: Label 'B10', Locked = true;
        XLCY: Label 'INR', Locked = true;
        XGSTDist: Label 'P-D-INV', Locked = true;
        XGSTCreditAdjJnlNos: Label 'GST-CR-JNL', Locked = true;
        XGSTSettlementNos: Label 'GST-SETTLE', Locked = true;
        XLCYSymbol: Label '₹', Locked = true;
        XLCYCurrencyDescription: Label 'Indian Rupees';
        XTCSIH: Label 'TCS-IH', Locked = true;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        Currency.Get(DemoDataSetup."Currency Code");
        "General Ledger Setup".Get();
        UpdateFromCurrency();

        "General Ledger Setup".Validate("Allow Posting From", 0D);
        "General Ledger Setup".Validate("Allow Posting To", 0D);
        "General Ledger Setup".Validate("Unrealized VAT", DemoDataSetup."Advanced Setup");
        "General Ledger Setup".Validate("Adjust for Payment Disc.", false);
        "Create No. Series".InitBaseSeries("General Ledger Setup"."Bank Account Nos.", XBANK, XBANK, XB10, 'B990', '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "General Ledger Setup"."EMU Currency" := DemoDataSetup."LCY an EMU Currency";
        "General Ledger Setup"."Local Cont. Addr. Format" := "General Ledger Setup"."Local Cont. Addr. Format"::"After Company Name";
        "General Ledger Setup"."Local Address Format" := "General Ledger Setup"."Local Address Format"::"Post Code+City";
        "General Ledger Setup"."Show Amounts" := "General Ledger Setup"."Show Amounts"::"Amount Only";
        "General Ledger Setup".Validate("LCY Code", XLCY);
        "General Ledger Setup"."Enable Data Check" := true;
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        UpdateGeneralLedgerSetup(
            XGSTDist, XGSTCreditAdjJnlNos, XGSTSettlementNos, 0);
        VATRegistrationLogMgt.InitServiceSetup();
    end;

    procedure InsertEvaluationData()
    begin
        "General Ledger Setup".Get();
        "General Ledger Setup".Validate("Global Dimension 1 Code", XDEPARTMENT);
        "General Ledger Setup".Validate("Global Dimension 2 Code", XCUSTOMERGROUP);
        "General Ledger Setup".Validate("LCY Code", XLCY);
        "General Ledger Setup"."Local Currency Symbol" := XLCYSymbol;
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        UpdateGeneralLedgerSetup(
            XGSTDist, XGSTCreditAdjJnlNos, XGSTSettlementNos, 0);
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

    procedure UpdateGeneralLedgerSetup(GSTDistribution: Code[10]; GSTCreditAdj: code[10]; GSTSettlement: Code[10]; GSTReconTol: Decimal);
    var
        GenLedgerSetup: Record "General Ledger Setup";
        "Create No. Series": Codeunit "Create No. Series";
    begin
        if GenLedgerSetup.Get() then begin
            GenLedgerSetup."GST Distribution Nos." := GSTDistribution;
            GenLedgerSetup."GST Credit Adj. Jnl Nos." := GSTCreditAdj;
            GenLedgerSetup."GST Settlement Nos." := GSTSettlement;
            GenLedgerSetup."GST Recon. Tolerance" := GSTReconTol;
            GenLedgerSetup."Local Currency Symbol" := XLCYSymbol;
            GenLedgerSetup."Local Currency Description" := XLCYCurrencyDescription;
            if GenLedgerSetup."TCS Debit Note No." = '' then
                "Create No. Series".InsertSeries(GenLedgerSetup."TCS Debit Note No.", XTCSIH, XTCSIH, 'XTCSI00001', '', '', '', 1, true);
            GenLedgerSetup.Modify();
        end;
    end;
}

