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
        SetPostingAccForMfgOverheadVarAcc();
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    var
        GLSetup: Record "General Ledger Setup";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
    begin
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        GLSetup.Get();
        GLSetup.Validate("Adjust for Payment Disc.", false);
        GLSetup.Validate("Prepayment Unrealized VAT", false);
        GLSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
        GLSetup.Modify(true);
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
        PurchSetup.Validate("Receipt on Invoice", true);
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
        SalesSetup.Validate("Stockout Warning", true);
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.Validate("Archive Orders", true);
        SalesSetup.Validate("Archive Return Orders", true);
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
        exit;
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
                    GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Purch. Pmt. Disc. Credit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Purch. Pmt. Tol. Debit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Purch. Pmt. Tol. Credit Acc." = '' then
                    GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Sales Pmt. Disc. Debit Acc." = '' then
                    GenPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Sales Pmt. Disc. Credit Acc." = '' then
                    GenPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Sales Pmt. Tol. Debit Acc." = '' then
                    GenPostingSetup."Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
                if GenPostingSetup."Sales Pmt. Tol. Credit Acc." = '' then
                    GenPostingSetup."Sales Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
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
                GenPostingSetup.Validate("Sales Line Disc. Account",
                  GetNotEmptyDiffAccount(GenPostingSetup."Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account", GenPostingSetup."Sales Account", GenPostingSetup."Purch. Line Disc. Account"));
                GenPostingSetup.Validate("Purch. Line Disc. Account",
                  GetNotEmptyDiffAccount(GenPostingSetup."Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Line Disc. Account", GenPostingSetup."Purch. Account", GenPostingSetup."Sales Line Disc. Account"));
                GenPostingSetup.Validate("Sales Inv. Disc. Account",
                  GetNotEmptyDiffAccount(GenPostingSetup."Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account", GenPostingSetup."Sales Account", GenPostingSetup."Purch. Inv. Disc. Account"));
                GenPostingSetup.Validate("Purch. Inv. Disc. Account",
                  GetNotEmptyDiffAccount(GenPostingSetup."Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account", GenPostingSetup."Purch. Account", GenPostingSetup."Sales Inv. Disc. Account"));
                GenPostingSetup.Modify(true);
            until GenPostingSetup.Next() = 0;
    end;

    local procedure PrepareNormalGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetup.Reset();
        GenPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("COGS Account", '<>%1', '');
        GenPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        GenPostingSetup.FindFirst();
        if GenPostingSetup."COGS Account (Interim)" = '' then
            GenPostingSetup.Validate("COGS Account (Interim)", GenPostingSetup."COGS Account");
        if GenPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
            GenPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GenPostingSetup."Inventory Adjmt. Account");
        GenPostingSetup.Modify(true);
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

    local procedure UpdateAccountsInVATPostingSetup()
    var
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindNormalVATPostingSetup(NormalVATPostingSetup);
        VATPostingSetup.FindSet();
        repeat
            VATPostingSetup.Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
            VATPostingSetup.Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;
    end;

    local procedure FindNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CreateMissingGeneralPostingSetup()
    var
        GenBusPostGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        NormalGeneralPostingSetup: Record "General Posting Setup";
    begin
        PrepareNormalGenPostingSetup(NormalGeneralPostingSetup);
        GenProdPostingGroup.FindSet();
        repeat
            GenBusPostGroup.FindSet();
            repeat
                CreateGeneralPostingSetup(GenBusPostGroup.Code, GenProdPostingGroup.Code, NormalGeneralPostingSetup);
            until GenBusPostGroup.Next() = 0;
            CreateGeneralPostingSetup('', GenProdPostingGroup.Code, NormalGeneralPostingSetup);
        until GenProdPostingGroup.Next() = 0;
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostGroupCode: Code[20]; GenProdPostGroupCode: Code[20]; NormalGeneralPostingSetup: Record "General Posting Setup")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        if not GenPostingSetup.Get(GenBusPostGroupCode, GenProdPostGroupCode) then begin
            LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostGroupCode, GenProdPostGroupCode);
            GenPostingSetup.Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
            GenPostingSetup.Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
            GenPostingSetup.Validate("Sales Credit Memo Account", NormalGeneralPostingSetup."Sales Credit Memo Account");
            GenPostingSetup.Validate("Purch. Credit Memo Account", NormalGeneralPostingSetup."Purch. Credit Memo Account");
            GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";
            GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
            GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.";
            GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.";
            GenPostingSetup."Sales Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Sales Pmt. Disc. Debit Acc.";
            GenPostingSetup."Sales Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Sales Pmt. Disc. Credit Acc.";
            GenPostingSetup."Sales Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Sales Pmt. Tol. Debit Acc.";
            GenPostingSetup."Sales Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Sales Pmt. Tol. Credit Acc.";
            GenPostingSetup.Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
            GenPostingSetup.Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
            GenPostingSetup.Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
            GenPostingSetup.Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
            GenPostingSetup.Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
            GenPostingSetup.Validate("COGS Account (Interim)", NormalGeneralPostingSetup."COGS Account (Interim)");
            GenPostingSetup.Validate("Invt. Accrual Acc. (Interim)", NormalGeneralPostingSetup."Invt. Accrual Acc. (Interim)");
            GenPostingSetup.Validate("Sales Line Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Account", NormalGeneralPostingSetup."Purch. Line Disc. Account"));
            GenPostingSetup.Validate("Sales Inv. Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account"));
            GenPostingSetup.Validate("Purch. Line Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Account", NormalGeneralPostingSetup."Sales Line Disc. Account"));
            GenPostingSetup.Validate("Purch. Inv. Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account"));
            GenPostingSetup.Modify(true);
        end;
    end;

    local procedure GetNotEmptyDiffAccount(BaseGLAccNo: Code[20]; NormalGLAccNo: Code[20]; RelatedGLAccNo: Code[20]; SubstGLAccNo: Code[20]) GLAccNo: Code[20]
    begin
        if BaseGLAccNo = '' then
            GLAccNo := NormalGLAccNo
        else
            GLAccNo := BaseGLAccNo;
        exit(GetDiffAccount(GLAccNo, RelatedGLAccNo, SubstGLAccNo));
    end;

    local procedure GetDiffAccount(GLAccNo: Code[20]; RelatedGLAccNo: Code[20]; SubstGLAccNo: Code[20]): Code[20]
    begin
        if GLAccNo = RelatedGLAccNo then
            exit(SubstGLAccNo);
        exit(GLAccNo);
    end;

    local procedure SetPostingAccForMfgOverheadVarAcc()
    var
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetFilter("Mfg. Overhead Variance Account", '<>%1', '');
        if InventoryPostingSetup.FindSet(true) then
            repeat
                GLAccount.Get(InventoryPostingSetup."Mfg. Overhead Variance Account");
                if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then begin
                    GLAccount.Get(InventoryPostingSetup."Cap. Overhead Variance Account");
                    GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
                    InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", GLAccount."No.");
                    InventoryPostingSetup.Modify(true);
                end;
            until InventoryPostingSetup.Next() = 0;
    end;

    local procedure CreateReverseChargeVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.IsEmpty() then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
            LibraryERM.FindGLAccount(GLAccount);
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
            VATPostingSetup.Modify(true);
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

