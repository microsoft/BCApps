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
        // NAVCZ
        "General Ledger Setup"."Closed Per. Entry Pos.Date CZL" := CA.AdjustDate(19020101D);
        "Create No. Series".InitBaseSeries2("General Ledger Setup"."Cash Desk Nos. CZP", XCD, XCashDesk, 'POK01', 'POK99', '', '', 1);
        "Create No. Series".InitBaseSeries2(
            "General Ledger Setup"."Acc. Schedule Results Nos. CZL", XASRESULTS, XResultsOfAccountingSchedules, 'USV00001', 'USV99999', '', '', 1);
        "General Ledger Setup"."Mark Cr. Memos as Corrections" := true;
        "General Ledger Setup"."Mark Neg. Qty as Correct. CZL" := true;
        "General Ledger Setup"."Check G/L Account Usage" := true;
        "General Ledger Setup"."Check Posting Debit/Credit CZL" := true;
        "General Ledger Setup"."Print VAT specification in LCY" := true;
        "General Ledger Setup"."Max. VAT Difference Allowed" := 0.5;
        "General Ledger Setup"."VAT Reporting Date Usage" := "General Ledger Setup"."VAT Reporting Date Usage"::"Enabled (Prevent modification)";
        "General Ledger Setup"."Def. Orig. Doc. VAT Date CZL" := "General Ledger Setup"."Def. Orig. Doc. VAT Date CZL"::"Posting Date";
        // NAVCZ
        "General Ledger Setup"."EMU Currency" := DemoDataSetup."LCY an EMU Currency";
        "General Ledger Setup"."Local Address Format" := "General Ledger Setup"."Local Address Format"::"Post Code+City";
        "General Ledger Setup"."Show Amounts" := "General Ledger Setup"."Show Amounts"::"Amount Only";
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        VATRegistrationLogMgt.InitServiceSetup();
        RegistrationLogMgtCZL.InitServiceSetup(); // NAVCZ
    end;

    var
        "General Ledger Setup": Record "General Ledger Setup";
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        GLAccountCategory: Record "G/L Account Category";
        "Create No. Series": Codeunit "Create No. Series";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        XDEPARTMENT: Label 'DEPARTMENT';
        XPROJECT: Label 'PROJECT';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XAREA: Label 'AREA';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XBANK: Label 'BANK';
        XB10: Label 'B10';
        XCD: Label 'CD';
        XCashDesk: Label 'Cash Desk';
        XASRESULTS: Label 'AS-RES';
        XResultsOfAccountingSchedules: Label 'Results of Acc. Schedules';
        CA: Codeunit "Make Adjustments";

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
        "General Ledger Setup"."Enable Data Check" := true;
        // NAVCZ
        "General Ledger Setup"."Mark Cr. Memos as Corrections" := true;
        "General Ledger Setup"."Mark Neg. Qty as Correct. CZL" := true;
        "General Ledger Setup"."Max. VAT Difference Allowed" := 0.5;
        "General Ledger Setup"."Check G/L Account Usage" := true;
        "General Ledger Setup"."Print VAT specification in LCY" := true;
        "Create No. Series".InitBaseSeries2("General Ledger Setup"."Cash Desk Nos. CZP", XCD, XCashDesk, 'POK01', 'POK99', '', '', 1);
        "General Ledger Setup"."Closed Per. Entry Pos.Date CZL" := CA.AdjustDate(19020101D);
        "Create No. Series".InitBaseSeries2(
            "General Ledger Setup"."Acc. Schedule Results Nos. CZL", XASRESULTS, XResultsOfAccountingSchedules, 'USV00001', 'USV99999', '', '', 1);
        "General Ledger Setup"."VAT Reporting Date Usage" := "General Ledger Setup"."VAT Reporting Date Usage"::"Enabled (Prevent modification)";
        "General Ledger Setup"."Def. Orig. Doc. VAT Date CZL" := "General Ledger Setup"."Def. Orig. Doc. VAT Date CZL"::"Posting Date";
        "General Ledger Setup"."Check Posting Debit/Credit CZL" := true;
        "General Ledger Setup"."Do Not Check Dimensions CZL" := true;
        // NAVCZ
        GLAccountCategory.SetRange(Description, GLAccountCategoryMgt.GetAR());
        if GLAccountCategory.FindFirst() then
            "General Ledger Setup"."Acc. Receivables Category" := GLAccountCategory."Entry No.";
        "General Ledger Setup".Modify();
        VATRegistrationLogMgt.InitServiceSetup();
        RegistrationLogMgtCZL.InitServiceSetup(); // NAVCZ
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

