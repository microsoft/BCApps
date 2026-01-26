codeunit 142001 "Sales Tax Deferrals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Deferrals]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreateDeferralScheduleWithSalesTax()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        TaxRate: Decimal;
        AmountWithTax: Decimal;
        DeferralNoOfPeriods: Integer;
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 381309] System involves "Expense / Capitailize" only tax details when calculating "Amount To Defer" for purchases deferral schedule
        Initialize();

        // [GIVEN] "Use Vendor's Tax Area Code" = TRUE in "Purchases & Payables Setup"
        UpdateUseVendorTaxPurchaseSetup(true);

        // [GIVEN] Deferral Template "T" with 2 periods
        // [GIVEN] "G/L Account" "A" and Vendor "V" are set to use Sales Tax
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 2%  and "Expense / Capitalize" = FALSE
        // [GIVEN] "Tax Detail"[2] where "Tax Rate" = 3%  and "Expense / Capitalize" = TRUE
        // [GIVEN] Purhase order for "V" with the line for "A" where "Line Amount" = 100
        InitializeSalesTaxScenarioForVendor(Vendor, GLAccount, TaxRate);
        DeferralNoOfPeriods := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", DeferralNoOfPeriods);

        CreatePurchaseOrderWithLine(PurchaseLine, Vendor."No.", GLAccount."No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Validate "Deferral Code" = "T"
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");

        // [THEN] 2 Deferral lines created with balance = 103 => (100 * 3%)
        AmountWithTax := Round(PurchaseLine."Line Amount" * (100 + TaxRate / 3) / 100);

        VerifyDeferralSchedule(
          DeferralHeader."Deferral Doc. Type"::Purchase,
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
          AmountWithTax, DeferralNoOfPeriods);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreateDeferralScheduleWithSalesTax()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        TaxRate: Decimal;
        AmountWithTax: Decimal;
        DeferralNoOfPeriods: Integer;
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 201769] System ignores tax details when calculating "Amount To Defer" for sales deferral schedule
        Initialize();

        // [GIVEN] Deferral Template "T" with 2 periods
        // [GIVEN] "G/L Account" "A" and Customer "C" are set to use Sales Tax
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 2%  and "Expense / Capitalize" = FALSE
        // [GIVEN] "Tax Detail"[2] where "Tax Rate" = 3%  and "Expense / Capitalize" = TRUE
        // [GIVEN] Sales order for "C" with the line for "A" where "Line Amount" = 100
        InitializeSalesTaxScenarioForCustomer(Customer, GLAccount, TaxRate);
        DeferralNoOfPeriods := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", DeferralNoOfPeriods);

        CreateSalesOrderWithLine(SalesLine, Customer."No.", GLAccount."No.");
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Validate "Deferral Code" = "T"
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");

        // [THEN] 2 Deferral lines created with balance = 100 (not including Tax)
        AmountWithTax := SalesLine."Line Amount";

        VerifyDeferralSchedule(
          DeferralHeader."Deferral Doc. Type"::Sales,
          SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          AmountWithTax, DeferralNoOfPeriods);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurhcasePostedDeferralGLEntriesWithSalesTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
        TaxRate: Decimal;
        AmountWithTax: Decimal;
        DeferralNoOfPeriods: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 381309] Posted Purchase Order with Sales Tax and Deferrals setup generates G/L entries with tax in amounts.
        Initialize();

        // [GIVEN] "Use Vendor's Tax Area Code" = TRUE in "Purchases & Payables Setup"
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 2%  and "Expense / Capitalize" = FALSE
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 3%  and "Expense / Capitalize" = TRUE
        UpdateUseVendorTaxPurchaseSetup(true);

        // [GIVEN] Deferral Template "T" with 2 periods and "Deferral Account" = "D"
        // [GIVEN] "G/L Account" "A" and Vendor "V" are set to use Sales Tax
        // [GIVEN] Purhase order for "V" with the line for "A" where "Line Amount" = 100 and "Deferral Code" = "T"
        InitializeSalesTaxScenarioForVendor(Vendor, GLAccount, TaxRate);
        DeferralNoOfPeriods := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", DeferralNoOfPeriods);

        CreatePurchaseOrderWithLine(PurchaseLine, Vendor."No.", GLAccount."No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify(true);

        // [WHEN] Post purchase order
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Balance for "A" = 103 => (100 * 3%)
        AmountWithTax := Round(PurchaseLine."Line Amount" * (100 + TaxRate / 3) / 100);
        VerifyGLEntryBalance(GLAccount."No.", AmountWithTax, DeferralNoOfPeriods + 2);

        // [THEN] Balance for "D" = 0
        VerifyGLEntryBalance(DeferralTemplate."Deferral Account", 0, DeferralNoOfPeriods + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostedDeferralGLEntriesWithSalesTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
        TaxRate: Decimal;
        DeferralNoOfPeriods: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380817] Posted Sales Order with Sales Tax and Deferrals setup generates G/L entries with tax in amounts.
        Initialize();

        // [GIVEN] Deferral Template "T" with 2 periods and "Deferral Account" = "D"
        // [GIVEN] "G/L Account" "A" and Custoemr "C" are set to use Sales Tax
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 2%  and "Expense / Capitalize" = FALSE
        // [GIVEN] "Tax Detail"[1] where "Tax Rate" = 3%  and "Expense / Capitalize" = TRUE
        // [GIVEN] Sales order for "C" with the line for "A" where "Line Amount" = 100 and "Deferral Code" = "T"
        InitializeSalesTaxScenarioForCustomer(Customer, GLAccount, TaxRate);
        DeferralNoOfPeriods := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", DeferralNoOfPeriods);

        CreateSalesOrderWithLine(SalesLine, Customer."No.", GLAccount."No.");
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        SalesLine.Modify(true);

        // [WHEN] Post sales order
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Balance for "A" = 100 (The tax is posted into Jurisdiction Tax Account);
        // "Sales & Receivables Setup" does not have similar setup to "Use Vendor's Tax Area Code"
        // Deferral Line[1] for "A" = -102.5
        // Deferral Line[2] for "A" = -102.5
        // Tax balancing line for "A" = 5
        // Tax Account = -5
        VerifyGLEntryBalance(GLAccount."No.", -SalesLine."Line Amount", DeferralNoOfPeriods + 2);

        // [THEN] Balance for "D" = 0
        VerifyGLEntryBalance(DeferralTemplate."Deferral Account", 0, DeferralNoOfPeriods + 1);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure InitializeSalesTaxScenarioForCustomer(var Customer: Record Customer; var GLAccount: Record "G/L Account"; var TaxRate: Decimal)
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        TaxRate := LibraryRandom.RandIntInRange(5, 10) * 3;
        CreateTaxSetup(TaxArea, TaxGroup, TaxRate);
        CreateGLAccountWithTaxGroupCode(GLAccount, TaxGroup.Code);
        CreateCustomerWithTaxAreaCode(Customer, TaxArea.Code);
    end;

    local procedure InitializeSalesTaxScenarioForVendor(var Vendor: Record Vendor; var GLAccount: Record "G/L Account"; var TaxRate: Decimal)
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        TaxRate := LibraryRandom.RandIntInRange(5, 10) * 3;
        CreateTaxSetup(TaxArea, TaxGroup, TaxRate);
        CreateGLAccountWithTaxGroupCode(GLAccount, TaxGroup.Code);
        CreateVendorWithTaxAreaCode(Vendor, TaxArea.Code);
    end;

    local procedure CreateGLAccountWithTaxGroupCode(var GLAccount: Record "G/L Account"; TaxGroupCode: Code[20])
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", '');
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithLine(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
    end;

    local procedure CreateSalesOrderWithLine(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
    end;

    local procedure CreateTaxSetup(var TaxArea: Record "Tax Area"; var TaxGroup: Record "Tax Group"; TaxRate: Decimal)
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);

        CreateTaxDetail(TaxArea.Code, TaxGroup.Code, TaxRate / 3, true);
        CreateTaxDetail(TaxArea.Code, TaxGroup.Code, 2 * TaxRate / 3, false);
    end;

    local procedure CreateTaxDetail(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxRate: Decimal; ExpenseCapitalzie: Boolean)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Tax Account (Sales)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);

        LibraryERM.CreateTaxDetail(
          TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxRate);
        TaxDetail.Validate("Expense/Capitalize", ExpenseCapitalzie);
        TaxDetail.Modify(true);

        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure CreateCustomerWithTaxAreaCode(var Customer: Record Customer; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithTaxAreaCode(var Vendor: Record Vendor; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Modify(true);
    end;

    local procedure UpdateUseVendorTaxPurchaseSetup(UseVendorTaxAreaCode: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", UseVendorTaxAreaCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyDeferralSchedule(DeferralDocumentType: Enum "Deferral Document Type"; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; ExpectedAmount: Decimal; ExpectedDeferralLinesCount: Integer)
    var
        DeferralLine: Record "Deferral Line";
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocumentType);
        DeferralLine.SetRange("Document Type", DocumentType);
        DeferralLine.SetRange("Document No.", DocumentNo);
        DeferralLine.SetRange("Line No.", LineNo);
        DeferralLine.CalcSums(Amount);
        DeferralLine.TestField(Amount, ExpectedAmount);
        Assert.RecordCount(DeferralLine, ExpectedDeferralLinesCount);

        DeferralHeader.SetRange("Deferral Doc. Type", DeferralDocumentType);
        DeferralHeader.SetRange("Document Type", DocumentType);
        DeferralHeader.SetRange("Document No.", DocumentNo);
        DeferralHeader.FindFirst();
        DeferralHeader.TestField("Amount to Defer", ExpectedAmount);
    end;

    local procedure VerifyGLEntryBalance(GLAccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedEntriesCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount);
        Assert.RecordCount(GLEntry, ExpectedEntriesCount);
    end;
}

