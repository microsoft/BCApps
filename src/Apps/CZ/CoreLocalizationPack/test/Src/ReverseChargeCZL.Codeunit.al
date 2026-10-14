codeunit 148057 "Reverse Charge CZL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Core] [Reverse Charge]
        isInitialized := false;
    end;

    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        CommodityCZL: Record "Commodity CZL";
        CommoditySetupCZL: Record "Commodity Setup CZL";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryTaxCZL: Codeunit "Library - Tax CZL";
        Assert: Codeunit Assert;
        SalesDocumentType: Enum "Sales Document Type";
        SalesLineType: Enum "Sales Line Type";
        TaxCalculationType: Enum "Tax Calculation Type";
        ReverseChargeCheckCZL: Enum "Reverse Charge Check CZL";
        VATPostingSetupPostMismatchErr: Label 'For commodity %1 and limit %2 not allowed VAT type %3 posting.\\Item List:\%4.', Comment = '%1 = Commodity Code, %2 = Commodity Limit Amount LCY, %3 = VAT Calculation Type, %4 = Item No.';
        isInitialized: Boolean;

    local procedure Initialize();
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Location: Record Location;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Reverse Charge CZL");
        LibraryRandom.Init();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Reverse Charge CZL");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", false);
        SalesReceivablesSetup.Modify();

        CommodityCZL.Init();
        CommodityCZL.Code := CopyStr(LibraryRandom.RandText(2), 1, MaxStrLen(CommodityCZL.Code));
        CommodityCZL.Insert();

        CommoditySetupCZL.Init();
        CommoditySetupCZL."Commodity Code" := CommodityCZL.Code;
        CommoditySetupCZL."Valid From" := WorkDate();
        CommoditySetupCZL."Commodity Limit Amount LCY" := 100000;
        CommoditySetupCZL.Insert();

        LibrarySales.SetPostedNoSeriesInSetup();
        LibraryPatterns.SETNoSeries();

        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify();

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, TaxCalculationType::"Normal VAT", 21);
        VATPostingSetup."Reverse Charge Check CZL" := ReverseChargeCheckCZL::"Limit Check";
        VATPostingSetup.Modify();

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, '', InventoryPostingGroup.Code);
        LibraryInventory.UpdateInventoryPostingSetup(Location, InventoryPostingGroup.Code);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Reverse Charge CZL");
    end;

    [Test]
    procedure ValidateSalesLineWithTariffNo()
    var
        TariffNumber: Record "Tariff Number";
    begin
        // [SCENARIO] Validate Item with Tariff No. in Sales Line
        Initialize();

        // [GIVEN] New Customer has been created
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        // [GIVEN] New Item has been created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] New Tariff Number has been created
        CreateTariffNo(TariffNumber, CommodityCZL.Code, Item."Base Unit of Measure");

        // [GIVEN] Item has been updated with Tariff No. and VAT Prod. Posting Group
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify();

        // [GIVEN] New Sales Invoice has been created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify();

        // [WHEN] Create Sales Line with Item No. with filled Tariff No. value
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item."No.", 1000);
        SalesLine.Modify();

        // [THEN] Sales Line Tariff No. will have Item Tariff No.
        Assert.AreEqual(SalesLine."Tariff No. CZL", Item."Tariff No.", SalesLine.FieldCaption(SalesLine."Tariff No. CZL"));
    end;

    [Test]
    procedure PostSalesWithCommodityUnderLimit()
    var
        TariffNumber: Record "Tariff Number";
    begin
        // [SCENARIO] Post Sales Invoice with Commodity under limit
        Initialize();

        // [GIVEN] New Customer has been created
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        // [GIVEN] New Item has been created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] New Tariff Number has been created
        CreateTariffNo(TariffNumber, CommodityCZL.Code, Item."Base Unit of Measure");

        // [GIVEN] Item has been updated with Tariff No. and VAT Prod. Posting Group
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify();

        // [GIVEN] New Sales Invoice has been created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify();

        // [GIVEN] Sales Line with Item No. with Unit Price bas been created
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item."No.", 1000);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        // [WHEN] Post Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error VAT Posting Setup Post Mismatch will occurs
        Assert.ExpectedError(StrSubstNo(VATPostingSetupPostMismatchErr, CommoditySetupCZL."Commodity Code", CommoditySetupCZL."Commodity Limit Amount LCY",
                             SalesLine."VAT Calculation Type"::"Normal VAT", Item."No."));
    end;

    [Test]
    procedure PostSalesWithCommodityAboveLimitBeforeDiscountBelowAfter()
    var
        TariffNumber: Record "Tariff Number";
        SalesInvHeader: Record "Sales Invoice Header";
        PostedDocNo: Code[20];
    begin
        // [SCENARIO] Post Sales Invoice where amount before discount exceeds limit but amount after discount is below limit.
        // The limit check must use the amount after discount (VAT base), so posting with Normal VAT should succeed.
        Initialize();

        // [GIVEN] New Customer has been created
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        // [GIVEN] New Item has been created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] New Tariff Number has been created
        CreateTariffNo(TariffNumber, CommodityCZL.Code, Item."Base Unit of Measure");

        // [GIVEN] Item has been updated with Tariff No. and VAT Prod. Posting Group
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify();

        // [GIVEN] New Sales Invoice has been created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify();

        // [GIVEN] Sales Line: Unit Price 200 * Qty 1000 = 200,000 (above limit 100,000)
        // Line Discount 60% => Amount after discount = 80,000 (below limit 100,000)
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item."No.", 1000);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Validate("Line Discount %", 60);
        SalesLine.Modify(true);

        // [WHEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Invoice is posted successfully (amount after discount is below limit, Normal VAT is correct)
        SalesInvHeader.Get(PostedDocNo);
    end;

    [Test]
    procedure PostSalesWithCommodityAboveLimitAfterDiscount()
    var
        TariffNumber: Record "Tariff Number";
    begin
        // [SCENARIO] Post Sales Invoice where amount after discount still exceeds limit.
        // Normal VAT should not be allowed - error expected.
        Initialize();

        // [GIVEN] New Customer has been created
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        // [GIVEN] New Item has been created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] New Tariff Number has been created
        CreateTariffNo(TariffNumber, CommodityCZL.Code, Item."Base Unit of Measure");

        // [GIVEN] Item has been updated with Tariff No. and VAT Prod. Posting Group
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify();

        // [GIVEN] New Sales Invoice has been created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify();

        // [GIVEN] Sales Line: Unit Price 200 * Qty 1000 = 200,000 (above limit 100,000)
        // Line Discount 20% => Amount after discount = 160,000 (still above limit 100,000)
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item."No.", 1000);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Validate("Line Discount %", 20);
        SalesLine.Modify(true);

        // [WHEN] Post Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error VAT Posting Setup Post Mismatch will occur (amount after discount still exceeds limit)
        Assert.ExpectedError(StrSubstNo(VATPostingSetupPostMismatchErr, CommoditySetupCZL."Commodity Code", CommoditySetupCZL."Commodity Limit Amount LCY",
                             SalesLine."VAT Calculation Type"::"Normal VAT", Item."No."));
    end;

    local procedure CreateTariffNo(var TariffNumber: Record "Tariff Number"; CommodityCode: Code[10]; UoMCode: Code[10])
    begin
        LibraryTaxCZL.CreateTariffNumber(TariffNumber);
        TariffNumber."Statement Code CZL" := CommodityCode;
        TariffNumber."Statement Limit Code CZL" := CommodityCode;
        TariffNumber."VAT Stat. UoM Code CZL" := UoMCode;
        TariffNumber."Allow Empty UoM Code CZL" := false;
        TariffNumber.Modify();
    end;
}
