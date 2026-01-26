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
        PCS: Label 'PCS';
        BOX: Label 'BOX';

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        exit;
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
        SetupCostTypeLinks();
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
        UpdateCustomerPostingGroup();
    end;

    procedure UpdateAccountInVendorPostingGroups()
    begin
        UpdateVendorPostingGroup();
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
        UpdateGLSetup();
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
        exit;
    end;

    procedure CreateUnitsOfMeasure()
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        if not UnitofMeasure.Get(PCS) then
            CreateUnitOfMeasure(PCS);
        if not UnitofMeasure.Get(BOX) then
            CreateUnitOfMeasure(BOX);
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
        exit;
    end;

    procedure DisableActivateChequeNoOnGeneralLedgerSetup()
    begin
        exit;
    end;

    procedure RemoveBlankGenJournalTemplate()
    begin
        exit;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; No: Code[20]): Boolean
    begin
        if GLAccount.Get(No) then
            if (GLAccount."Income/Balance" = GLAccount."Income/Balance"::"Income Statement") and (GLAccount."Account Type" = GLAccount."Account Type"::Posting) then
                exit(true);
        exit(false);
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

    local procedure SetupCostTypeLinks()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Copy of LinkCostTypesToGLAccounts function from COD1100.
        CostType.SetRange(Type, CostType.Type::"Cost Type");
        CostType.SetFilter(CostType."G/L Account Range", '');
        if CostType.FindSet() then
            repeat
                if FindGLAccount(GLAccount, CostType."No.") then begin
                    CostType."G/L Account Range" := CostType."No.";
                    CostType.Modify();
                    GLAccount."Cost Type No." := CostType."No.";
                    GLAccount.Modify();
                end;
            until CostType.Next() = 0;
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.FindSet() then
            repeat
                // Use assignment to avoid error
                if GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." = '' then
                    GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." = '' then
                    GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc." = '' then
                    GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc." = '' then
                    GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Sales Pmt. Tol. Debit Acc." = '' then
                    GeneralPostingSetup."Sales Pmt. Tol. Debit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." = '' then
                    GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Purch. Credit Memo Account" = '' then
                    GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := CreateGLAccount();
                if GeneralPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
                    GeneralPostingSetup."Invt. Accrual Acc. (Interim)" := CreateGLAccount();
                if GeneralPostingSetup."COGS Account" = '' then
                    GeneralPostingSetup.Validate("COGS Account", CreateGLAccount());
                if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CreateGLAccount());
                GeneralPostingSetup.Modify(true);
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure UpdateCustomerPostingGroup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if CustomerPostingGroup.FindSet() then
            repeat
                if CustomerPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", CreateGLAccount());
                    CustomerPostingGroup.Modify(true);
                end;
                if CustomerPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", CreateGLAccount());
                    CustomerPostingGroup.Modify(true);
                end;
            until CustomerPostingGroup.Next() = 0;
    end;

    local procedure UpdateGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();  // Need to set value to match field value with W1 Demo Data.
        GeneralLedgerSetup."Adjust for Payment Disc." := false;  // Using VALIDATE cause an error message,hence using Assignment.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVendorPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if VendorPostingGroup.FindSet() then
            repeat
                if VendorPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    VendorPostingGroup.Validate("Payment Disc. Debit Acc.", CreateGLAccount());
                    VendorPostingGroup.Modify(true);
                end;
                if VendorPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    VendorPostingGroup.Validate("Payment Disc. Credit Acc.", CreateGLAccount());
                    VendorPostingGroup.Modify(true);
                end;
            until VendorPostingGroup.Next() = 0;
    end;

    local procedure CreateUnitOfMeasure("Code": Text)
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        UnitofMeasure.Init();
        UnitofMeasure.Code := Code;
        UnitofMeasure.Description := Code;
        UnitofMeasure.Insert();
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

