codeunit 144126 "ERM VATECCALC Sales Tax"
{
    // Test for feature VATECCALC: VAT Calculation for Sales Tax.
    // 1. Test to verify Purchase Order posted successfully with sales tax when Purchase Order Lines have different Dimension Values & total of Purchase Line Amount is less than the Maximum Amount on Tax Detailed Setup.
    // 2. Test to verify Purchase Order posted successfully with sales tax when Purchase Order Lines have different Dimension Values & total of Purchase Line Amount is greater than the Maximum Amount on Tax Detailed Setup.
    // 3. Test to verify Sales Order posted successfully with sales tax when Sales Order Lines have different Dimension Values & total of Sales Line Amount is less than the Maximum Amount on Tax Detailed Setup.
    // 4. Test to verify Sales Order posted successfully with sales tax when Sales Order Lines have different Dimension Values & total of Sales Line Amount is greater than the Maximum Amount on Tax Detailed Setup.
    // 
    //   Covers Test Cases for WI - 352280.
    //   --------------------------------------------------------------------------------------------
    //   Test Function Name                                                                    TFS ID
    //   --------------------------------------------------------------------------------------------
    //   PostedPurchOrderWithDiffDimAmountLessThanTaxDetail                                    239361
    //   PostedPurchOrderWithDiffDimAmountGreaterThanTaxDetail                                 239360
    //   PostedSalesOrderWithDiffDimAmountLessThanTaxDetail                                    239359
    //   PostedSalesOrderWithDiffDimAmountGreaterThanTaxDetail                                 239358

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustEqualMsg: Label 'Value must be equal';

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchOrderWithDiffDimAmountLessThanTaxDetail()
    begin
        // Test to verify Purchase Order posted successfully with sales tax when Purchase Order Lines have different Dimension Values & total of Purchase Line Amount is less than the Maximum Amount on Tax Detailed Setup.
        PostedPurchaseOrderWithDifferentDimensions(LibraryRandom.RandDec(10, 2));  // Using Direct unit Cost in range to take Amount less than Maximum Amount on Tax Detailed Setup.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchOrderWithDiffDimAmountGreaterThanTaxDetail()
    begin
        // Test to verify Purchase Order posted successfully with sales tax when Purchase Order Lines have different Dimension Values & total of Purchase Line Amount is greater than the Maximum Amount on Tax Detailed Setup.
        PostedPurchaseOrderWithDifferentDimensions(LibraryRandom.RandIntInRange(300, 400));  // Using Direct unit Cost in range to take Amount greater than Maximum Amount on Tax Detailed Setup.
    end;

    local procedure PostedPurchaseOrderWithDifferentDimensions(DirectUnitCost: Decimal)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        TaxAreaLine: Record "Tax Area Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        TaxGroupCode: Code[20];
    begin
        // Create Purchase Order with Tax Group on multiple Lines with different Dimensions.
        CreateVATPostingSetup(VATPostingSetup);
        TaxGroupCode := CreateTaxGroupAndDetail(TaxAreaLine);
        CreatePurchaseOrder(
          PurchaseLine, TaxAreaLine."Tax Area", CreateItemWithDimension(
            VATPostingSetup."VAT Prod. Posting Group"), TaxGroupCode, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, CreateItemWithDimension(VATPostingSetup."VAT Prod. Posting Group"), TaxGroupCode, DirectUnitCost);
        CreatePurchaseLine(
          PurchaseLine3, PurchaseHeader, CreateItemWithDimension(VATPostingSetup."VAT Prod. Posting Group"), '', DirectUnitCost);  // Tax Group Code - Blank.

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify G/L Entries created successfully when Items having Different Dimension Total Amounts is less than or greater than Maximum Amount/Qty on Tax Detail.
        Amount := PurchaseLine.Amount + PurchaseLine2.Amount + PurchaseLine3.Amount;
        VerifyGLEntry(DocumentNo, GLEntry."Gen. Posting Type"::Purchase, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithDiffDimAmountLessThanTaxDetail()
    begin
        // Test to verify Sales Order posted successfully with sales tax when Sales Order Lines have different Dimension Values & total of Sales Line Amount is less than the Maximum Amount on Tax Detailed Setup.
        PostedSalesOrderWithDifferentDimensions(LibraryRandom.RandDec(10, 2));  // Using Unit Price in range to take Amount less than Maximum Amount on Tax Detailed Setup.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithDiffDimAmountGreaterThanTaxDetail()
    begin
        // Test to verify Sales Order posted successfully with sales tax when Sales Order Lines have different Dimension Values & total of Sales Line Amount is greater than the Maximum Amount on Tax Detailed Setup.
        PostedSalesOrderWithDifferentDimensions(LibraryRandom.RandIntInRange(300, 400));  // Using Unit Price in range to take Amount greater than Maximum Amount on Tax Detailed Setup.
    end;

    local procedure PostedSalesOrderWithDifferentDimensions(UnitPrice: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        TaxAreaLine: Record "Tax Area Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TaxGroupCode: Code[20];
        Amount: Decimal;
    begin
        // Create Sales Order with Tax Group on multiple Lines with different Dimensions.
        CreateVATPostingSetup(VATPostingSetup);
        TaxGroupCode := CreateTaxGroupAndDetail(TaxAreaLine);
        CreateSalesOrder(
          SalesLine, TaxAreaLine."Tax Area", CreateItemWithDimension(
            VATPostingSetup."VAT Prod. Posting Group"), TaxGroupCode, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), UnitPrice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(
          SalesLine2, SalesHeader, CreateItemWithDimension(VATPostingSetup."VAT Prod. Posting Group"), TaxGroupCode, UnitPrice);
        CreateSalesLine(SalesLine3, SalesHeader, CreateItemWithDimension(VATPostingSetup."VAT Prod. Posting Group"), '', UnitPrice);  // Tax Group Code - Blank.

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify G/L Entries created successfully when Items having Different Dimension Total Amounts is less than or greater than Maximum Amount/Qty on Tax Detail.
        Amount := SalesLine.Amount + SalesLine2.Amount + SalesLine3.Amount;
        VerifyGLEntry(DocumentNo, GLEntry."Gen. Posting Type"::Sale, -Amount);
    end;

    local procedure CreateItemWithDimension(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, DimensionValue.Code);
        exit(Item."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; TaxArea: Code[20]; No: Code[20]; TaxGroupCode: Code[20]; VendorNo: Code[20]; DirectUniCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, TaxArea, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, No, TaxGroupCode, DirectUniCost);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; TaxArea: Code[20]; No: Code[20]; TaxGroupCode: Code[20]; CustomerNo: Code[20]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, TaxArea, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, No, TaxGroupCode, UnitPrice);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateTaxDetail(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales Tax", WorkDate());  // WORKDATE for Effective Date.
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDec(10, 2));
        TaxDetail.Validate("Maximum Amount/Qty.", LibraryRandom.RandDecInRange(500, 700, 2));  // Use Higher value to take Sum of Order Lines should be less than or greater than Maximum Amount/Qty.
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxAreaLine: Record "Tax Area Line")
    var
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", CreateGLAccount());
        TaxJurisdiction.Validate("Tax Account (Sales)", CreateGLAccount());
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure CreateTaxGroupAndDetail(TaxAreaLine: Record "Tax Area Line"): Code[20]
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroup.Code);
        exit(TaxGroup.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; No: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
        exit(VATBusinessPostingGroup.Code);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustEqualMsg);
    end;
}

