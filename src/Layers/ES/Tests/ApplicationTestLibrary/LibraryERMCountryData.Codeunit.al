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
        exit;
    end;

    procedure SetupReportSelections()
    var
        DummyReportSelections: Record "Report Selections";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Quote", REPORT::"Standard Sales - Quote");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.");
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
        UpdateAccountsInInventoryPostingSetup();
    end;

    procedure UpdateGenJournalTemplate()
    begin
        UpdateForceDocBalGenJournalTemplate();
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
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Correct. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup.Modify();
	    UpdatePostingDateCheckonPostingPurchase();
    end;

    procedure SetDiscountPostingInPurchasePayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Post Line Discount" := true;
        PurchasesPayablesSetup."Post Invoice Discount" := true;
        PurchasesPayablesSetup.Modify();
    end;

    procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Correct. Doc. No. Mandatory" := false;
        SalesReceivablesSetup.Modify();
	    UpdatePostingDateCheckonPostingSales();
    end;

    procedure SetDiscountPostingInSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Post Line Discount" := true;
        SalesReceivablesSetup."Post Invoice Discount" := true;
        SalesReceivablesSetup.Modify();
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
        UpdateTransportMethod();
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

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.FindSet() then
            repeat
                if GeneralPostingSetup."Purch. Account" = '' then
                    GeneralPostingSetup.Validate("Purch. Account", CreateGLAccount());
                if GeneralPostingSetup."Purch. Credit Memo Account" = '' then
                    GeneralPostingSetup.Validate("Purch. Credit Memo Account", CreateGLAccount());
                if GeneralPostingSetup."Sales Account" = '' then
                    GeneralPostingSetup.Validate("Sales Account", CreateGLAccount());
                if GeneralPostingSetup."Sales Credit Memo Account" = '' then
                    GeneralPostingSetup.Validate("Sales Credit Memo Account", CreateGLAccount());
                if GeneralPostingSetup."COGS Account" = '' then
                    GeneralPostingSetup.Validate("COGS Account", CreateGLAccount());
                if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CreateGLAccount());
                if GeneralPostingSetup."Direct Cost Applied Account" = '' then
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CreateGLAccount());
                if GeneralPostingSetup."Overhead Applied Account" = '' then
                    GeneralPostingSetup.Validate("Overhead Applied Account", CreateGLAccount());
                if GeneralPostingSetup."Purchase Variance Account" = '' then
                    GeneralPostingSetup.Validate("Purchase Variance Account", CreateGLAccount());
                if GeneralPostingSetup."COGS Account (Interim)" = '' then
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CreateGLAccount());
                if GeneralPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CreateGLAccount());
                GeneralPostingSetup.Modify(true);
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure UpdateForceDocBalGenJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange("Force Doc. Balance", false);
        if GenJournalTemplate.FindSet() then
            GenJournalTemplate.ModifyAll("Force Doc. Balance", true);  // This field is FALSE by defualt in ES.
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

    local procedure UpdateAccountsInInventoryPostingSetup()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if InventoryPostingSetup.FindSet() then
            repeat
                if InventoryPostingSetup."Subcontracted Variance Account" = '' then
                    InventoryPostingSetup.Validate("Subcontracted Variance Account", CreateGLAccount());
                if InventoryPostingSetup."Inventory Account (Interim)" = '' then
                    InventoryPostingSetup.Validate("Inventory Account (Interim)", CreateGLAccount());
                InventoryPostingSetup.Modify(true);
            until InventoryPostingSetup.Next() = 0;
    end;

    local procedure UpdateTransportMethod()
    var
        TransportMethod: Record "Transport Method";
    begin
        // To avoid error related to Entry/Exit Point, updating Transport Method Table.
        if TransportMethod.FindSet() then
            repeat
                TransportMethod.Validate("Port/Airport", false);
                TransportMethod.Modify(true);
            until TransportMethod.Next() = 0;
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

