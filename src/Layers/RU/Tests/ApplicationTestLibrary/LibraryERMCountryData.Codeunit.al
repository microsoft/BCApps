/// <summary>
/// Provides procedures to create and initialize country-specific demo data for ERM scenarios that exists in W1 but may be missing in localized versions.
/// </summary>
codeunit 131305 "Library - ERM Country Data"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        CreateReverseChargeVATSetup();
    end;

    procedure GetVATCalculationType(): Enum "Tax Calculation Type"
    begin
        exit("Tax Calculation Type"::"Normal VAT");
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsagePurchaseQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"P.Quote".AsInteger());
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsageSalesQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"S.Quote".AsInteger());
    end;

    procedure SetupCostAccounting()
    begin
        exit;
    end;

    procedure SetupReportSelections()
    var
        DummyReportSelections: Record "Report Selections";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Quote", REPORT::"Standard Sales - Quote");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice Draft", REPORT::"Standard Sales - Draft Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::USI, Report::"Standard Sales - Draft Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Cr.Memo", REPORT::"Standard Sales - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Invoice", REPORT::"Service - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Credit Memo", REPORT::"Service - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Invoice", Report::"Purchase - Invoice");
    end;

    procedure UpdateAccountInCustomerPostingGroup()
    begin
        exit;
    end;

    procedure UpdateAccountInVendorPostingGroups()
    begin
        exit;
    end;

    procedure UpdateAccountsInServiceContractAccountGroups()
    begin
        exit;
    end;

    procedure UpdateAccountInServiceCosts()
    begin
        exit;
    end;

    procedure UpdateCalendarSetup()
    begin
        exit;
    end;

    procedure UpdateGeneralPostingSetup()
    begin
        UpdateAccountsInGeneralPostingSetup();
    end;

    procedure UpdateInventoryPostingSetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Posted Direct Trans. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup.Modify();
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Russian Accounting", false);
        ClearUnrealTypeInVATPostingSetup();
        GLSetup.Validate("Unrealized VAT", false);
        GLSetup.Validate("Mark Cr. Memos as Corrections", false);
        GLSetup.Validate("Void Payment as Correction", false);
        GLSetup.Modify();
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
    end;

    procedure UpdatePurchasesPayablesSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"All Discounts";
        PurchSetup.Validate("Use Prepayment Account", false);
        PurchSetup.Validate("Allow VAT Difference", false);
        PurchSetup.Validate("Transfer Posting Description", false);
        PurchSetup.Validate("Allow Alter Posting Groups", false);
        PurchSetup.Modify(true);
	    UpdatePostingDateCheckonPostingPurchase();
    end;

    procedure SetDiscountPostingInPurchasePayablesSetup()
    begin
        exit;
    end;

    procedure UpdateSalesReceivablesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.Validate("Use Prepayment Account", false);
        SalesSetup.Validate("Create Prepayment Invoice");
        SalesSetup.Validate("Calc. Inv. Discount", false);
        SalesSetup.Validate("Return Receipt on Credit Memo", false);
        SalesSetup.Validate("Allow VAT Difference", false);
        SalesSetup.Validate("Transfer Posting Description", false);
        SalesSetup.Validate("Calc. VAT per Line", false);
        SalesSetup.Validate("Allow Alter Posting Groups", false);
        SalesSetup.Modify(true);
	    UpdatePostingDateCheckonPostingSales();
    end;

    procedure SetDiscountPostingInSalesReceivablesSetup()
    begin
        exit;
    end;

    procedure UpdateGenProdPostingGroup()
    begin
        exit;
    end;

    procedure CreateGeneralPostingSetupData()
    begin
        exit;
    end;

    procedure CreateUnitsOfMeasure()
    begin
        exit;
    end;

    procedure CreateTransportMethodTableData()
    begin
        exit;
    end;

    procedure UpdateFAPostingGroup()
    begin
        exit;
    end;

    procedure UpdateFAPostingType()
    begin
        exit;
    end;

    procedure UpdateFAJnlTemplateName()
    begin
        exit;
    end;

    procedure UpdateJournalTemplMandatory(Mandatory: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Journal Templ. Name Mandatory", Mandatory);
        GeneralLedgerSetup.Modify(true);
    end;

    procedure CreateNewFiscalYear()
    begin
        exit;
    end;

    procedure UpdateVATPostingSetup()
    begin
        UpdateAccountsInVATPostingSetup();
    end;

    procedure DisableActivateChequeNoOnGeneralLedgerSetup()
    begin
        exit;
    end;

    procedure RemoveBlankGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateLocalPostingSetup()
    begin
        exit;
    end;

    procedure UpdateLocalData()
    begin
        ClearStartingDateInNoSeries();
    end;

    local procedure UpdateGenProdPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure UpdateVATPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
    end;

    procedure CompanyInfoSetVATRegistrationNo()
    var
        CompanyInformation: Record "Company Information";
        LibraryERM: Codeunit "Library - ERM";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CompanyInformation.Modify();
    end;

    procedure AmountOnBankAccountLedgerEntriesPage(var BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries"): Decimal
    var
        EntryRemainingAmount: Decimal;
    begin
        if BankAccountLedgerEntries.Amount.Visible() then
            EntryRemainingAmount := BankAccountLedgerEntries.Amount.AsDecimal()
        else
            if BankAccountLedgerEntries."Credit Amount".AsDecimal() <> 0 then
                EntryRemainingAmount := -BankAccountLedgerEntries."Credit Amount".AsDecimal()
            else
                EntryRemainingAmount := BankAccountLedgerEntries."Debit Amount".AsDecimal();
        exit(EntryRemainingAmount);
    end;

    procedure InsertRecordsToProtectedTables()
    begin
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        NormalGeneralPostingSetup: Record "General Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
    begin
        PrepareNormalGenPostingSetup(NormalGeneralPostingSetup);
        if GenPostingSetup.FindSet(true) then
            repeat
                if GenPostingSetup."Sales Account" = '' then
                    GenPostingSetup.Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
                if GenPostingSetup."Purch. Account" = '' then
                    GenPostingSetup.Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
                if GenPostingSetup."Sales Credit Memo Account" = '' then
                    GenPostingSetup.Validate("Sales Credit Memo Account", NormalGeneralPostingSetup."Sales Credit Memo Account");
                if GenPostingSetup."Purch. Credit Memo Account" = '' then
                    GenPostingSetup.Validate("Purch. Credit Memo Account", NormalGeneralPostingSetup."Purch. Credit Memo Account");
                if GenPostingSetup."Sales Prepayments Account" = '' then
                    GenPostingSetup.Validate("Sales Prepayments Account", NormalGeneralPostingSetup."Sales Prepayments Account");
                if GenPostingSetup."Purch. Prepayments Account" = '' then
                    GenPostingSetup.Validate("Purch. Prepayments Account", NormalGeneralPostingSetup."Purch. Prepayments Account");
                if GenPostingSetup."Purch. Pmt. Disc. Debit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                if GenPostingSetup."Purch. Pmt. Disc. Credit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                if GenPostingSetup."Purch. Pmt. Tol. Debit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                if GenPostingSetup."Purch. Pmt. Tol. Credit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                if GenPostingSetup."Direct Cost Applied Account" = '' then
                    GenPostingSetup.Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
                if GenPostingSetup."Overhead Applied Account" = '' then
                    GenPostingSetup.Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                if GenPostingSetup."Purchase Variance Account" = '' then
                    GenPostingSetup.Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
                if GenPostingSetup."COGS Account" = '' then
                    GenPostingSetup.Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
                if GenPostingSetup."COGS Account (Interim)" = '' then
                    GenPostingSetup.Validate("COGS Account (Interim)", NormalGeneralPostingSetup."COGS Account (Interim)");
                if GenPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
                    GenPostingSetup.Validate("Invt. Accrual Acc. (Interim)", NormalGeneralPostingSetup."Invt. Accrual Acc. (Interim)");
                if GenPostingSetup."Inventory Adjmt. Account" = '' then
                    GenPostingSetup.Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
                if GenPostingSetup."Sales Line Disc. Account" = '' then
                    GenPostingSetup.Validate("Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account");
                GenPostingSetup."Sales Inv. Disc. Account" := GenPostingSetup."Purch. Account";
                if GenPostingSetup."Purch. Line Disc. Account" = '' then
                    GenPostingSetup."Purch. Line Disc. Account" := GenPostingSetup."Sales Line Disc. Account";
                if GenPostingSetup."Purch. Inv. Disc. Account" = '' then
                    GenPostingSetup."Purch. Inv. Disc. Account" := GenPostingSetup."Sales Inv. Disc. Account";
                GenPostingSetup.Modify(true);
            until GenPostingSetup.Next() = 0;
    end;

    local procedure PrepareNormalGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetup.Reset();
        GenPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Inv. Disc. Account", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Line Disc. Account", '<>%1', '');
        GenPostingSetup.SetFilter("COGS Account", '<>%1', '');
        GenPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        GenPostingSetup.FindFirst();
        GenPostingSetup."Sales Inv. Disc. Account" := GenPostingSetup."Purch. Account";
        if GenPostingSetup."Purch. Line Disc. Account" = '' then
            GenPostingSetup."Purch. Line Disc. Account" := GenPostingSetup."Sales Line Disc. Account";
        if GenPostingSetup."Purch. Inv. Disc. Account" = '' then
            GenPostingSetup."Purch. Inv. Disc. Account" := GenPostingSetup."Sales Inv. Disc. Account";
        if GenPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
            GenPostingSetup."Invt. Accrual Acc. (Interim)" := GenPostingSetup."Inventory Adjmt. Account";
        if GenPostingSetup."Sales Pmt. Disc. Debit Acc." = '' then
            GenPostingSetup."Sales Pmt. Disc. Debit Acc." := GenPostingSetup."Sales Inv. Disc. Account";
        if GenPostingSetup."Sales Pmt. Disc. Credit Acc." = '' then
            GenPostingSetup."Sales Pmt. Disc. Credit Acc." := GenPostingSetup."Sales Line Disc. Account";
        if GenPostingSetup."COGS Account (Interim)" = '' then
            GenPostingSetup."COGS Account (Interim)" := GenPostingSetup."COGS Account";
        if GenPostingSetup."Direct Cost Applied Account" = '' then
            GenPostingSetup.Validate("Direct Cost Applied Account", GenPostingSetup."COGS Account");
        if GenPostingSetup."Overhead Applied Account" = '' then
            GenPostingSetup.Validate("Overhead Applied Account", GenPostingSetup."COGS Account (Interim)");
        if GenPostingSetup."Purchase Variance Account" = '' then
            GenPostingSetup.Validate("Purchase Variance Account", GenPostingSetup."Invt. Accrual Acc. (Interim)");
        if GenPostingSetup."Sales Prepayments Account" = '' then
            GenPostingSetup.Validate("Sales Prepayments Account", GenPostingSetup."Purch. Account");
        if GenPostingSetup."Purch. Prepayments Account" = '' then
            GenPostingSetup.Validate("Purch. Prepayments Account", GenPostingSetup."Sales Account");
        GenPostingSetup.Modify(true);
    end;

    local procedure ClearUnrealTypeInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.FindSet(true) then
            repeat
                VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
                VATPostingSetup.Modify(true);
            until VATPostingSetup.Next() = 0;
    end;

    local procedure UpdateAccountsInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
    begin
        PrepareNormalVATPostingSetup(NormalVATPostingSetup);
        if VATPostingSetup.FindSet(true) then
            repeat
                VATPostingSetup.Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
                VATPostingSetup.Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
                VATPostingSetup.Modify(true);
            until VATPostingSetup.Next() = 0;
    end;

    local procedure PrepareNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", VATPostingSetup."Sales VAT Account");
        VATPostingSetup.Modify(true);
    end;

    local procedure ClearStartingDateInNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.ModifyAll("Starting Date", 0D);
    end;

    procedure CreateReverseChargeVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.IsEmpty() then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATProductPostingGroup.Code := VATPostingSetup."VAT Prod. Posting Group" + 'R';
            VATProductPostingGroup.Insert();
            VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
            VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Identifier" + 'R';
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
            VATPostingSetup.Insert(true);
        end;
    end;
    
    local procedure UpdatePostingDateCheckonPostingSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posting Date Check on Posting", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePostingDateCheckonPostingPurchase()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posting Date Check on Posting", false);
        PurchasesPayablesSetup.Modify(true);
    end;
}

