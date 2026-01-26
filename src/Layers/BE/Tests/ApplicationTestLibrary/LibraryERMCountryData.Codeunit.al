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
        SetZeroVATSetupForSalesInvRoundingAccounts();
    end;

    procedure UpdateAccountInVendorPostingGroups()
    begin
        SetZeroVATSetupForPurchInvRoundingAccounts();
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
        CreateGenJnlTemplate();
    end;

    procedure UpdateGeneralLedgerSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Use Workdate for Appl./Unappl.", false);
        GLSetup.Validate("VAT Tolerance %", 0);
        GLSetup.Validate("Pmt. Disc. Excl. VAT", false);
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
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Customer Nos.", LibraryERM.CreateNoSeriesCode());
        SalesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.FindFirst();
        SalesSetup.Validate("S. Invoice Template Name", GenJournalTemplate.Name);
        SalesSetup.Validate("S. Cr. Memo Template Name", GenJournalTemplate.Name);
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
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
        exit;
    end;

    procedure DisableActivateChequeNoOnGeneralLedgerSetup()
    begin
        exit;
    end;

    procedure RemoveBlankGenJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        DeleteExtraGeneralJournalTemplate(PAGE::"General Journal", GenJournalTemplate.Type::General);
        DeleteExtraGeneralJournalTemplate(PAGE::"Sales Journal", GenJournalTemplate.Type::Sales);
        DeleteExtraGeneralJournalTemplate(PAGE::"Purchase Journal", GenJournalTemplate.Type::Purchases);
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
        LibraryBEHelper: Codeunit "Library - BE Helper";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Enterprise No.", LibraryBEHelper.CreateMOD97CompliantCode());
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

    local procedure CreateGenJnlTemplate()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::Payments);
        GenJnlTemplate.Modify(true);
    end;

    local procedure DeleteExtraGeneralJournalTemplate(PageID: Integer; TemplType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
    begin
        GenJournalTemplate.SetRange("Page ID", PageID);
        GenJournalTemplate.SetRange(Type, TemplType);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();
        GenJournalTemplate.SetFilter(Name, '<>%1', GenJournalTemplate.Name);
        GenJournalTemplate.DeleteAll(true);
        case TemplType of
            GenJournalTemplate.Type::Sales:
                begin
                    SalesSetup.Get();
                    SalesSetup."S. Invoice Template Name" := GenJournalTemplate.Name;
                    SalesSetup."S. Cr. Memo Template Name" := GenJournalTemplate.Name;
                    SalesSetup."S. Prep. Inv. Template Name" := GenJournalTemplate.Name;
                    SalesSetup."S. Prep. Cr.Memo Template Name" := GenJournalTemplate.Name;
                    SalesSetup.Modify();
                    ServiceMgtSetup.Get();
                    ServiceMgtSetup."Serv. Inv. Template Name" := GenJournalTemplate.Name;
                    ServiceMgtSetup."Serv. Cr. Memo Templ. Name" := GenJournalTemplate.Name;
                    ServiceMgtSetup.Modify();
                end;
            GenJournalTemplate.Type::Purchases:
                begin
                    PurchaseSetup.Get();
                    PurchaseSetup."P. Invoice Template Name" := GenJournalTemplate.Name;
                    PurchaseSetup."P. Cr. Memo Template Name" := GenJournalTemplate.Name;
                    PurchaseSetup."P. Prep. Inv. Template Name" := GenJournalTemplate.Name;
                    PurchaseSetup."P. Prep. Cr.Memo Template Name" := GenJournalTemplate.Name;
                    PurchaseSetup.Modify();
                end;
        end;
    end;

    local procedure SetZeroVATSetupForSalesInvRoundingAccounts()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        NewVATPostingSetup: Record "VAT Posting Setup";
    begin
        if CustomerPostingGroup.FindSet() then
            repeat
                GLAccount.Get(CustomerPostingGroup."Invoice Rounding Account");
                if VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then
                    if VATPostingSetup."VAT %" <> 0 then begin
                        FindZeroVATPostingSetup(NewVATPostingSetup);
                        GLAccount.Validate("VAT Bus. Posting Group", NewVATPostingSetup."VAT Bus. Posting Group");
                        GLAccount.Validate("VAT Prod. Posting Group", NewVATPostingSetup."VAT Prod. Posting Group");
                        GLAccount.Modify(true);
                    end;
            until CustomerPostingGroup.Next() = 0;
    end;

    procedure SetZeroVATSetupForPurchInvRoundingAccounts()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        NewVATPostingSetup: Record "VAT Posting Setup";
    begin
        if VendorPostingGroup.FindSet() then
            repeat
                GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
                if VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then
                    if VATPostingSetup."VAT %" <> 0 then begin
                        FindZeroVATPostingSetup(NewVATPostingSetup);
                        GLAccount.Validate("VAT Bus. Posting Group", NewVATPostingSetup."VAT Bus. Posting Group");
                        GLAccount.Validate("VAT Prod. Posting Group", NewVATPostingSetup."VAT Prod. Posting Group");
                        GLAccount.Modify(true);
                    end;
            until VendorPostingGroup.Next() = 0;
    end;

    local procedure FindZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralPostingSetup.FindSet(true) then
            repeat
                if GeneralLedgerSetup."Adjust for Payment Disc." then begin
                    if GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." = '' then
                        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CreateGLAccount());
                    if GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." = '' then
                        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CreateGLAccount());
                    if GeneralPostingSetup."Purch. Credit Memo Account" = '' then
                        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", CreateGLAccount());
                end;
                if GeneralPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CreateGLAccount());
                if GeneralPostingSetup."COGS Account" = '' then
                    GeneralPostingSetup.Validate("COGS Account", CreateGLAccount());
                if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CreateGLAccount());
                if GeneralPostingSetup."Purch. Account" = '' then
                    GeneralPostingSetup.Validate("Purch. Account", CreateGLAccount());
                if GeneralPostingSetup."Purch. Credit Memo Account" = '' then
                    GeneralPostingSetup.Validate("Purch. Credit Memo Account", CreateGLAccount());
                GeneralPostingSetup.Modify(true);
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
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

