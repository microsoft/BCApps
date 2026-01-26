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

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        CreateMissingVATPostingSetup();
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
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Cr.Memo", REPORT::"Standard Sales - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Invoice", REPORT::"Service - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Credit Memo", REPORT::"Service - Credit Memo");
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
    begin
        exit;
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    begin
        exit;
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
    end;

    procedure UpdatePurchasesPayablesSetup()
    begin
        UpdatePostingDateCheckonPostingPurchase();
    end;

    procedure SetDiscountPostingInPurchasePayablesSetup()
    begin
        exit;
    end;

    procedure UpdateSalesReceivablesSetup()
    begin
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
        CreateMissingGeneralPostingSetup();
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
        RemoveVATCodesFromVATPostingSetup();
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
        UpdateSettledVATPeriod();
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
                if GenPostingSetup."Sales Line Disc. Account" = '' then
                    GenPostingSetup.Validate("Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account");
                if GenPostingSetup."Purch. Line Disc. Account" = '' then
                    GenPostingSetup.Validate("Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Line Disc. Account");
                if GenPostingSetup."Sales Inv. Disc. Account" = '' then
                    GenPostingSetup.Validate("Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account");
                if GenPostingSetup."Purch. Inv. Disc. Account" = '' then
                    GenPostingSetup.Validate("Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account");
                if GenPostingSetup."Direct Cost Applied Account" = '' then
                    GenPostingSetup.Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
                if GenPostingSetup."Overhead Applied Account" = '' then
                    GenPostingSetup.Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                if GenPostingSetup."Purchase Variance Account" = '' then
                    GenPostingSetup.Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
                GenPostingSetup.Modify(true);
            until GenPostingSetup.Next() = 0;
    end;

    local procedure CreateMissingGeneralPostingSetup()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        NormalGeneralPostingSetup: Record "General Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
    begin
        PrepareNormalGenPostingSetup(NormalGeneralPostingSetup);
        GenBusPostingGroup.FindSet();
        repeat
            GenProdPostingGroup.FindSet();
            repeat
                if not GenPostingSetup.Get(GenBusPostingGroup.Code, GenProdPostingGroup.Code) then begin
                    LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
                    GenPostingSetup.Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
                    GenPostingSetup.Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
                    GenPostingSetup.Validate("Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account");
                    GenPostingSetup.Validate("Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account");
                    GenPostingSetup.Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
                    GenPostingSetup.Validate("Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Line Disc. Account");
                    GenPostingSetup.Validate("Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account");
                    GenPostingSetup.Validate("Sales Credit Memo Account", NormalGeneralPostingSetup."Sales Credit Memo Account");
                    GenPostingSetup.Validate("Purch. Credit Memo Account", NormalGeneralPostingSetup."Purch. Credit Memo Account");
                    GenPostingSetup.Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
                    GenPostingSetup.Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                    GenPostingSetup.Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
                    GenPostingSetup.Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
                    GenPostingSetup.Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
                    GenPostingSetup.Validate("Sales Prepayments Account", NormalGeneralPostingSetup."Sales Prepayments Account");
                    GenPostingSetup.Validate("Purch. Prepayments Account", NormalGeneralPostingSetup."Purch. Prepayments Account");
                    GenPostingSetup.Modify(true);
                end;
            until GenProdPostingGroup.Next() = 0;
        until GenBusPostingGroup.Next() = 0;
    end;

    local procedure PrepareNormalGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    var
        SalesGenPostingSetup: Record "General Posting Setup";
        PurchGeneralPostingSetup: Record "General Posting Setup";
    begin
        SalesGenPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        SalesGenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        SalesGenPostingSetup.SetRange("Purch. Account", '');
        if SalesGenPostingSetup.FindFirst() then begin
            PurchGeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
            PurchGeneralPostingSetup.SetFilter("Purch. Credit Memo Account", '<>%1', '');
            PurchGeneralPostingSetup.SetFilter("Purch. Line Disc. Account", '<>%1', '');
            PurchGeneralPostingSetup.SetFilter("Purch. Inv. Disc. Account", '<>%1', '');
            LibraryERM.FindGeneralPostingSetup(PurchGeneralPostingSetup);
            SalesGenPostingSetup.Validate("Purch. Account", PurchGeneralPostingSetup."Purch. Account");
            SalesGenPostingSetup.Validate("Purch. Credit Memo Account", PurchGeneralPostingSetup."Purch. Credit Memo Account");
            SalesGenPostingSetup.Validate("Purch. Line Disc. Account", PurchGeneralPostingSetup."Purch. Line Disc. Account");
            SalesGenPostingSetup.Validate("Purch. Inv. Disc. Account", PurchGeneralPostingSetup."Purch. Inv. Disc. Account");
            SalesGenPostingSetup.Modify(true);
        end;
        LibraryERM.FindGeneralPostingSetupInvtFull(GenPostingSetup);
        SetupGLWithVATPostingSetup(GenPostingSetup."Sales Prepayments Account");
        SetupGLWithVATPostingSetup(GenPostingSetup."Purch. Prepayments Account");
    end;

    local procedure RemoveVATCodesFromVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Number", '<>%1', '');
        if VATPostingSetup.FindSet(true) then
            repeat
                VATPostingSetup.Validate("VAT Number", '');
                VATPostingSetup.Modify(true);
            until VATPostingSetup.Next() = 0;
    end;

    local procedure CreateMissingVATPostingSetup()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        VATBusPostingGroup.FindSet();
        repeat
            VATProdPostingGroup.FindSet();
            repeat
                CreateVATPostingSetup(VATBusPostingGroup.Code, VATProdPostingGroup.Code);
            until VATProdPostingGroup.Next() = 0;
        until VATBusPostingGroup.Next() = 0
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        NormalVATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        NormalVATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(NormalVATPostingSetup, NormalVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit;
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier",
            LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", 25);
        // Hardcoding to match W1.
        VATPostingSetup.Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
        VATPostingSetup.Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Modify(true);
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

    local procedure SetupGLWithVATPostingSetup(GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccNo);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UpdateSettledVATPeriod()
    var
        SettledVATPeriod: Record "Settled VAT Period";
    begin
        SettledVATPeriod.ModifyAll(Closed, false);
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

