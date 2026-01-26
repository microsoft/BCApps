/// <summary>
/// Provides procedures to create and initialize country-specific demo data for ERM scenarios that exists in W1 but may be missing in localized versions.
/// </summary>
codeunit 131305 "Library - ERM Country Data"
{
    Permissions = TableData Resource = rm;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        EU: Label 'EU';
        DOMESTICTok: Label 'DOMESTIC';
        VAT: Label 'VAT%1';
        TAX: Label 'TAX%1';

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        CreateVATSetup();
        UpdateGenBusPostingGroup();
        InitialSetupForGenProdPostingGroup();
    end;

    procedure GetVATCalculationType(): Enum "Tax Calculation Type"
    begin
        exit("Tax Calculation Type"::"Sales Tax");
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
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Invoice", Report::"Purchase - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Quote", Report::"Purchase - Quote");
    end;

    procedure UpdateAccountInCustomerPostingGroup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if CustomerPostingGroup.FindSet() then
            CustomerPostingGroup.ModifyAll("Invoice Rounding Account", CreateAndUpdateGLAccountWithNoVAT());
    end;

    procedure UpdateAccountInVendorPostingGroups()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if VendorPostingGroup.FindSet() then
            VendorPostingGroup.ModifyAll("Invoice Rounding Account", CreateAndUpdateGLAccountWithNoVAT());
    end;

    procedure UpdateAccountsInServiceContractAccountGroups()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        if ServiceContractAccountGroup.FindSet() then begin
            ServiceContractAccountGroup.ModifyAll("Non-Prepaid Contract Acc.", CreateAndUpdateGLAccountWithNoVAT());
            ServiceContractAccountGroup.ModifyAll("Prepaid Contract Acc.", CreateAndUpdateGLAccountWithNoVAT());
        end;
    end;

    procedure UpdateAccountInServiceCosts()
    var
        ServiceCost: Record "Service Cost";
    begin
        if ServiceCost.FindSet() then
            ServiceCost.ModifyAll(ServiceCost."Account No.", CreateAndUpdateGLAccountWithNoVAT());
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
        // disabled in CA
        exit;
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
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        PostedBankRecHeader.Insert();
        PostedBankRecLine.Insert();
        PostedDepositHeader.Insert();
        PostedDepositLine.Insert();
    end;

    local procedure CreateNormalVATPostingGroups()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRate: array[3] of Integer;
        I: Integer;
    begin
        VATBusPostingGroup.Init();
        VATBusPostingGroup.Code := EU;
        if VATBusPostingGroup.Insert(true) then;
        VATBusPostingGroup.Code := DOMESTICTok;
        if VATBusPostingGroup.Insert(true) then;

        VATRate[1] := 0;
        VATRate[2] := 10;
        VATRate[3] := 25;
        for I := 1 to 3 do begin
            VATProdPostingGroup.Init();
            VATProdPostingGroup.Code := StrSubstNo(VAT, VATRate[I]);
            if VATProdPostingGroup.Insert(true) then;

            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
            VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
            if VATPostingSetup.Insert() then;
        end;
    end;

    local procedure CreateVATSetup()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPerc: Integer;
        VATCalculationType: Enum "Tax Calculation Type";
    begin
        CreateNormalVATPostingGroups();

        // Check if VAT Posting Setup required for W1 is present.
        if not IsMissingVATPostingSetup() then
            exit;

        // Create VAT Posting Setup using existing VAT Business and VAT Product Groups.
        VATProdPostingGroup.FindSet();
        repeat
            VATPerc := GetVATPerc(VATProdPostingGroup.Code);
            VATBusPostingGroup.FindSet();
            repeat
                if (VATBusPostingGroup.Code = EU) and (VATPerc > 0) then
                    VATCalculationType := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" // Reverse Charge VAT is used for EU VAT Business Posting Group.
                else
                    VATCalculationType := VATPostingSetup."VAT Calculation Type"::"Normal VAT"; // Normal VAT is used for other VAT Business Posting Group and 0%.
                CreateVATPostingSetup(VATCalculationType, VATBusPostingGroup.Code, VATProdPostingGroup.Code, VATPerc);
            until VATBusPostingGroup.Next() = 0
        until VATProdPostingGroup.Next() = 0;
    end;

    local procedure CreateVATPostingSetup(VATCalculationType: Enum "Tax Calculation Type"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATRate: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit;
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT Identifier", VATProdPostingGroup);
        VATPostingSetup.Validate("VAT %", VATRate);

        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount());
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount());
        if VATCalculationType = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateGLAccount());

        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure IsMissingVATPostingSetup(): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT %", '>0');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if VATPostingSetup.Count > 1 then
            exit(true);
        if VATPostingSetup.Get('', '') and
           (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax")
        then begin
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            CreateVATPostingSetup(VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', VATProductPostingGroup.Code, 10);
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            CreateVATPostingSetup(VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', VATProductPostingGroup.Code, 25);
        end;

        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.Count < 2 then
            exit(true);

        exit(false);
    end;

    local procedure GetVATPerc(VATProdGroup: Code[20]): Integer
    var
        VATPerc: Integer;
        i: Integer;
        ValueFound: Boolean;
    begin
        i := 1;
        repeat
            ValueFound := Evaluate(VATPerc, CopyStr(VATProdGroup, i));
            i += 1;
        until (ValueFound and (VATPerc <= 100)) or (i > StrLen(VATProdGroup));
        exit(VATPerc);
    end;

    local procedure GetVATProdPostingGroup(VATPerc: Integer): Code[10]
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATProdPostingGroup.Get(StrSubstNo(TAX, VATPerc)) then
            exit(StrSubstNo(TAX, VATPerc));  // This line works for local build.
        if VATProdPostingGroup.Get(StrSubstNo(VAT, VATPerc)) then
            exit(StrSubstNo(VAT, VATPerc));  // This line works for GDL build.
    end;

    local procedure UpdateGenBusPostingGroup()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        DefVATBusPostingGroup: Code[20];
    begin
        // Assign Def. VAT Bus. Posting Group to a Gen. Bus. Posting Group if a match exists.
        GenBusPostingGroup.SetFilter("Def. VAT Bus. Posting Group", '');
        if GenBusPostingGroup.FindSet() then
            repeat
                if VATBusPostingGroup.Get(GenBusPostingGroup.Code) then
                    DefVATBusPostingGroup := GenBusPostingGroup.Code
                else
                    DefVATBusPostingGroup := DOMESTICTok;
                GenBusPostingGroup."Def. VAT Bus. Posting Group" := DefVATBusPostingGroup; // Skip OnValidate trigger which has UI confirmation dialog.
                GenBusPostingGroup.Modify(true);
                UpdateVATBusPostingGroup(GenBusPostingGroup.Code, DefVATBusPostingGroup);
            until GenBusPostingGroup.Next() = 0;
    end;

    local procedure UpdateVATBusPostingGroup(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        Customer: Record Customer;
    begin
        GLAccount.SetCurrentKey("Gen. Bus. Posting Group");
        GLAccount.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.SetFilter("VAT Bus. Posting Group", '<>%1', VATBusPostingGroup);
        if GLAccount.FindSet() then
            GLAccount.ModifyAll("VAT Bus. Posting Group", VATBusPostingGroup, false);

        Vendor.SetCurrentKey("Gen. Bus. Posting Group");
        Vendor.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.SetFilter("VAT Bus. Posting Group", '<>%1', VATBusPostingGroup);
        if Vendor.FindSet() then
            Vendor.ModifyAll("VAT Bus. Posting Group", VATBusPostingGroup, false);

        Customer.SetCurrentKey("Gen. Bus. Posting Group");
        Customer.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.SetFilter("VAT Bus. Posting Group", '<>%1', VATBusPostingGroup);
        if Customer.FindSet() then
            Customer.ModifyAll("VAT Bus. Posting Group", VATBusPostingGroup, false);
    end;

    local procedure InitialSetupForGenProdPostingGroup()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        DefVATProdPostingGroup: Code[20];
    begin
        // Assign Def. VAT Prod. Posting Group to a Gen. Prod. Posting Group based on W1.
        GenProdPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '');
        if GenProdPostingGroup.FindSet() then
            repeat
                DefVATProdPostingGroup := '';
                if VATProdPostingGroup.Get(GenProdPostingGroup.Code) then // This is for other groups.
                    DefVATProdPostingGroup := GenProdPostingGroup.Code
                else
                    case GenProdPostingGroup.Code of
                        'SERVICES': // Hardcoding to match W1.
                            DefVATProdPostingGroup := GetVATProdPostingGroup(10); // Hardcoding to match W1.
                        'NO VAT': // Hardcoding to match W1.
                            DefVATProdPostingGroup := GetVATProdPostingGroup(0); // Hardcoding to match W1.
                        else
                            DefVATProdPostingGroup := GetVATProdPostingGroup(25); // Hardcoding to match W1.
                    end;

                if DefVATProdPostingGroup <> '' then begin
                    GenProdPostingGroup."Def. VAT Prod. Posting Group" := DefVATProdPostingGroup; // Skip OnValidate trigger which has UI confirmation dialog.
                    UpdateVATProdPostingGroup(GenProdPostingGroup.Code, DefVATProdPostingGroup);
                    GenProdPostingGroup.Modify(true);
                end;
            until GenProdPostingGroup.Next() = 0;
    end;

    local procedure UpdateVATProdPostingGroup(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
    begin
        GLAccount.SetCurrentKey("Gen. Prod. Posting Group");
        GLAccount.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if GLAccount.FindSet() then
            GLAccount.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        Item.SetCurrentKey("Gen. Prod. Posting Group");
        Item.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if Item.FindSet() then
            Item.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        ItemCharge.SetCurrentKey("Gen. Prod. Posting Group");
        ItemCharge.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if ItemCharge.FindSet() then
            ItemCharge.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        Resource.SetCurrentKey("Gen. Prod. Posting Group");
        Resource.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        Resource.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if Resource.FindSet() then
            Resource.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);
    end;

    local procedure CreateAndUpdateGLAccountWithNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // Creating a GL Account with No VAT to ensure that no additional entry for VAT is created.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);  // Taking VAT % Zero will find Setup with NO VAT.
        VATPostingSetup.FindFirst();
        GLAccount.Get(CreateGLAccount());
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateMissingGeneralPostingSetup()
    var
        GeneralBusinessPostingGroup: Record "Gen. Business Posting Group";
        GeneralProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralBusinessPostingGroup.FindSet();
        repeat
            GeneralProductPostingGroup.FindSet();
            repeat
                GeneralPostingSetup.Reset();
                if not GeneralPostingSetup.Get(GeneralBusinessPostingGroup.Code, GeneralProductPostingGroup.Code) then begin
                    LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GeneralBusinessPostingGroup.Code, GeneralProductPostingGroup.Code);
                    GeneralPostingSetup.Validate("Sales Account", CreateGLAccount());
                    GeneralPostingSetup.Validate("Sales Line Disc. Account", GeneralPostingSetup."Sales Account");
                    GeneralPostingSetup.Validate("Sales Inv. Disc. Account", GeneralPostingSetup."Sales Account");
                    GeneralPostingSetup.Validate("Purch. Account", CreateGLAccount());
                    GeneralPostingSetup.Validate("Purch. Line Disc. Account", GeneralPostingSetup."Purch. Account");
                    GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GeneralPostingSetup."Purch. Account");
                    GeneralPostingSetup.Validate("Sales Credit Memo Account", GeneralPostingSetup."Sales Account");
                    GeneralPostingSetup.Validate("Purch. Credit Memo Account", GeneralPostingSetup."Purch. Account");
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CreateGLAccount());
                    GeneralPostingSetup.Validate("Overhead Applied Account", GeneralPostingSetup."Direct Cost Applied Account");
                    GeneralPostingSetup.Validate("Purchase Variance Account", GeneralPostingSetup."Purch. Account");
                    GeneralPostingSetup.Validate("COGS Account", GeneralPostingSetup."Overhead Applied Account");
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", GeneralPostingSetup."Overhead Applied Account");
                    GeneralPostingSetup.Modify(true);
                end;
            until GeneralProductPostingGroup.Next() = 0;
        until GeneralBusinessPostingGroup.Next() = 0;
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.FindSet() then
            repeat
                if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CreateGLAccount());
                if GeneralPostingSetup."Purchase Variance Account" = '' then
                    GeneralPostingSetup.Validate("Purchase Variance Account", CreateGLAccount());
                if GeneralPostingSetup."COGS Account" = '' then
                    GeneralPostingSetup.Validate("COGS Account", CreateGLAccount());
                GeneralPostingSetup.Modify(true);
            until GeneralPostingSetup.Next() = 0;
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

