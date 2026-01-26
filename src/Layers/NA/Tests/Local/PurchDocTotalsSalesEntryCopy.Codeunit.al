codeunit 142086 PurchDocTotalsSalesEntryCopy
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Document Totals]
        isInitialized := false;
    end;

    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedDocToInvoiceDisplaysDocTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchDocNo: Code[20];
        VendorNo: Code[20];
        TaxAreaCode: Code[20];
        PurchPostedAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy posted Inv to Invoice without recalculate will keep document totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;

        // [GIVEN] User has created and posted purchase document with purchase line with default Tax Group Code
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage);
        VendorNo := PurchaseHeader."Pay-to Vendor No.";
        TaxAreaCode := PurchaseHeader."Tax Area Code";
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.

        // Cache the values from the posted document for comparison
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchInvHeader."Invoice Discount Amount",
          PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT",
          0,
          PurchPostedAmounts);

        // [WHEN] User creates new header and copies the posted document where "Recalculate Lines" is No
        CreatePurchaseDocumentHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, TaxAreaCode);
        PurchCopyDocument(PurchaseHeader, PostedPurchDocNo, "Purchase Document Type From"::"Posted Invoice", false);
        CollectDataFromPurchaseInvoicePage(PurchaseHeader, PurchaseInvoice, PostAmounts, TotalTax);

        // [THEN] Verify Taxes are calculated and totals updated on page
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AssertEquals(0);
        VerifyFieldValuesEqual(PurchaseHeader, PurchPostedAmounts, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedDocToInvoiceDisplaysDocTotalsOnRecalculate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchDocNo: Code[20];
        VendorNo: Code[20];
        TaxAreaCode: Code[20];
        PurchasePostedAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy posted Inv to Invoice with recalculate will update taxes and totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;

        // [GIVEN] User has created and posted purchase document with purchase line with default Tax Group Code
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage);
        VendorNo := PurchaseHeader."Pay-to Vendor No.";
        TaxAreaCode := PurchaseHeader."Tax Area Code";
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.

        // Cache the values from the posted document for comparison
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchInvHeader."Invoice Discount Amount",
          PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT",
          0,
          PurchasePostedAmounts);

        // [WHEN] User creates new header and copies the posted document where "Recalculate Lines" is Yes
        CreatePurchaseDocumentHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, TaxAreaCode);
        PurchCopyDocument(PurchaseHeader, PostedPurchDocNo, "Purchase Document Type From"::"Posted Invoice", true);
        CollectDataFromPurchaseInvoicePage(PurchaseHeader, PurchaseInvoice, PostAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AssertEquals(0);
        VerifyFieldValuesEqual(PurchaseHeader, PurchasePostedAmounts, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderDisplaysDocTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseOrder: TestPage "Purchase Order";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987]  Copy unposted Inv to order without recalculate will keep document totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;

        // [GIVEN] User has created purchase document with purchase line with default Tax Group Code
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalPurchLine."Inv. Discount Amount",
          TotalPurchLine.Amount,
          VATAmount,
          TotalPurchLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the Invoice where "Recalculate Lines" is No
        CreatePurchaseDocumentHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order,
          PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Tax Area Code");
        PurchCopyDocument(PurchaseHeader2, PurchaseHeader."No.", "Purchase Document Type From"::Invoice, false);
        CollectDataFromPurchaseOrderPage(PurchaseHeader2, PurchaseOrder, OrderAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(PurchaseHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderDisplaysDocTotalsOnRecalculate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseOrder: TestPage "Purchase Order";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy Invoice to Order with recalculate will update taxes and totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;

        // [GIVEN] User has created purchase document with purchase line with default Tax Group Code
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalPurchaseLine."Inv. Discount Amount",
          TotalPurchaseLine.Amount,
          VATAmount,
          TotalPurchaseLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the invoice where "Recalculate Lines" is Yes
        CreatePurchaseDocumentHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order,
          PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Tax Area Code");
        PurchCopyDocument(PurchaseHeader2, PurchaseHeader."No.", "Purchase Document Type From"::Invoice, true);
        CollectDataFromPurchaseOrderPage(PurchaseHeader2, PurchaseOrder, OrderAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(PurchaseHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderWithInvDiscDisplaysDocTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentTotals: Codeunit "Document Totals";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        DiscountPercent: Decimal;
        TaxPercentage: Integer;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Copy] [Invoice Discount Amount]
        // [SCENARIO 136987] Purchase Invoice Doc Totals, Tax and Inv Discount are calculated on copy when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);
        RoundingPrecision := 0.01;

        // [GIVEN] User has created purchase document with purchase line with default Tax Group Code
        CreatePurchaseDocumentWithInvDisc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalPurchaseLine."Inv. Discount Amount",
          TotalPurchaseLine.Amount,
          VATAmount,
          TotalPurchaseLine."Amount Including VAT",
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine),
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the invoice where "Recalculate Lines" is Yes
        CreatePurchaseDocumentHeaderWithInvDisc(PurchaseHeader2, PurchaseHeader2."Document Type"::Order,
          PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Tax Area Code");
        PurchCopyDocument(PurchaseHeader2, PurchaseHeader."No.", "Purchase Document Type From"::Invoice, true);
        FindPurchaseLine(PurchaseHeader2, PurchaseLine2);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine2, VATAmount, TotalPurchaseLine);
        DiscountPercent := PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine2);

        SetCompareAmounts(TotalPurchaseLine."Inv. Discount Amount",
          TotalPurchaseLine.Amount,
          VATAmount,
          TotalPurchaseLine."Amount Including VAT",
          DiscountPercent,
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader2.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader2."Amount Including VAT" - PurchaseHeader2.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(PurchaseHeader2."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyFieldValuesEqual(PurchaseHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          DiscountPercent, RoundingPrecision);
    end;

    [Test]
    [HandlerFunctions('PurchaseCodePageHandler')]
    [Scope('OnPrem')]
    procedure TestGetStdVendPurchCodesDisplaysDocTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentTotals: Codeunit "Document Totals";
        VendorNo: Code[20];
        TaxAreaCode: Code[20];
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
    begin
        // [FEATURE] [Standard Purchase Code]
        // [SCENARIO 136987] Applying Standard Purchase Codes will update document totals
        // Setup
        Initialize();
        RoundingPrecision := 0.01;

        // [GIVEN] User has set up standard purchase codes and vendor
        CreateVendorWithPurchaseCodes(VendorNo, TaxAreaCode);

        // [WHEN] User creates new header and applies the standard codes
        CreatePurchaseDocumentHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, TaxAreaCode);
        StandardVendorPurchaseCode.InsertPurchLines(PurchaseHeader);
        FindPurchaseLine(PurchaseHeader, PurchaseLine);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        SetCompareAmounts(TotalPurchaseLine."Inv. Discount Amount",
          TotalPurchaseLine.Amount,
          VATAmount,
          TotalPurchaseLine."Amount Including VAT",
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyTotals(PurchaseHeader, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [HandlerFunctions('PurchaseCodePageHandler')]
    [Scope('OnPrem')]
    procedure TestGetStdVendPurchCodesWithInvDiscDisplaysDocTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        VendorNo: Code[20];
        TaxAreaCode: Code[20];
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Standard Purchase Code] [Invoice Discount Amount]
        // [SCENARIO 136987] Applying Standard Purchase Codes will update totals and inv disc when setup option marked
        // Setup
        Initialize();
        RoundingPrecision := 0.01;
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has set up standard purchase codes and customer
        CreateVendorWithPurchaseCodesAndInvDisc(VendorNo, TaxAreaCode);

        // [GIVEN] User creates new header and applies the standard codes
        CreatePurchaseDocumentHeaderWithInvDisc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          VendorNo, TaxAreaCode);
        StandardVendorPurchaseCode.InsertPurchLines(PurchaseHeader);
        FindPurchaseLine(PurchaseHeader, PurchaseLine);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        SetCompareAmounts(TotalPurchaseLine."Inv. Discount Amount",
          TotalPurchaseLine.Amount,
          VATAmount,
          TotalPurchaseLine."Amount Including VAT",
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;
        FindPurchaseLine(PurchaseHeader, PurchaseLine);

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(PurchaseHeader."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyTotals(PurchaseHeader, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision);
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorTaxAreaCode(Vendor, TaxAreaCode);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; TaxAreaCode: Code[20]; DiscPct: Decimal; MinimumAmount: Decimal)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorTaxAreaCode(Vendor, TaxAreaCode);
        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct, MinimumAmount, '');
    end;

    local procedure UpdateVendorTaxAreaCode(Vendor: Record Vendor; TaxAreaCode: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Identification Type", Vendor."Tax Identification Type"::"Legal Entity");
        Vendor.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("RFC No.")) - 1));  // Taken Length less than RFC No. Length as Tax Identification Type is Legal Entity.
        Vendor.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("CURP No."))));
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        VATEntry: Record "VAT Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        VATEntry.DeleteAll();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        CreateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, LibraryRandom.RandDec(10, 2));
        exit(Item."No.");
    end;

    local procedure CreateItemSpecifyUnitPrice(TaxGroupCode: Code[20]; UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, UnitPrice);
        exit(Item."No.");
    end;

    local procedure UpdateItem(var Item: Record Item; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Last Direct Cost", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxPercentage);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxPercentage: Integer)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        CreatePurchaseDocumentWithCertainTax(PurchaseHeader, PurchaseLine, DocumentType, TaxAreaCode, TaxDetail."Tax Group Code");
    end;

    local procedure CreatePurchaseDocumentWithCertainTax(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(TaxAreaCode));
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::None);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Quantity.
    end;

    local procedure CreatePurchaseDocumentWithInvDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxPercentage: Integer)
    var
        TaxDetail: Record "Tax Detail";
        Vendor: Record Vendor;
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        SetupDataForDiscountTypePct(Vendor, DiscPct, TaxAreaCode, ItemNo, ItemQuantity, TaxDetail."Tax Group Code");
        CreatePurchaseDocumentWithCertainTaxAndDisc(PurchaseHeader, PurchaseLine, DocumentType, Vendor."No.", ItemNo, TaxAreaCode);
    end;

    local procedure CreatePurchaseDocumentWithCertainTaxAndDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          ItemNo,
          LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Quantity.
    end;

    local procedure CreatePurchaseDocumentHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::None);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();
    end;

    local procedure CreatePurchaseDocumentHeaderWithInvDisc(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[20]
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += Format(LibraryRandom.RandInt(9));  // Generating any Random integer value.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure OpenPurchaseOrderPageEdit(var PurchaseOrder: TestPage "Purchase Order"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseInvoicePageEdit(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
    end;

    local procedure SetCompareAmounts(InvoiceDiscountAmount: Decimal; TotalAmountExcTax: Decimal; TaxAmount: Decimal; TotalAmountIncTax: Decimal; CustDiscountPercent: Decimal; var Amounts: array[5] of Decimal)
    var
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Amounts[FieldType::InvoiceDiscountAmount] := InvoiceDiscountAmount;
        Amounts[FieldType::TotalAmountExcTax] := TotalAmountExcTax;
        Amounts[FieldType::TaxAmount] := TaxAmount;
        Amounts[FieldType::TotalAmountIncTax] := TotalAmountIncTax;
        Amounts[FieldType::DiscountPercent] := CustDiscountPercent;
    end;

    local procedure VerifyFieldValuesEqual(PurchaseHeader: Record "Purchase Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreEqual(
          PreAmounts[FieldType::TotalAmountExcTax],
          PostAmounts[FieldType::TotalAmountExcTax],
          'Before and after amounts for Total Amount Excluding Tax should be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not equal');

        VerifyTotals(PurchaseHeader, PostAmounts, TotalTax, TotalDiscountPercent, RoundingPrecision);
    end;

    local procedure VerifyFieldValuesNotZero(PostAmounts: array[5] of Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNotEqual(
          PostAmounts[FieldType::TotalAmountExcTax], 0,
          'Total Amount Excluding Tax should not be zero');
        Assert.AreNotEqual(
          PostAmounts[FieldType::TotalAmountIncTax], 0,
          'Total Amount Including Tax should not be zero');
        Assert.AreNotEqual(
          PostAmounts[FieldType::TaxAmount], 0,
          'Tax Amount should not be zero');
    end;

    local procedure VerifyTotals(PurchaseHeader: Record "Purchase Header"; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::InvoiceDiscountAmount],
          PurchaseHeader."Invoice Discount Amount",
          RoundingPrecision,
          'An incorrect Invoice Discount Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountExcTax],
          PurchaseHeader.Amount,
          RoundingPrecision,
          'An incorrect Total Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountIncTax],
          PurchaseHeader."Amount Including VAT",
          RoundingPrecision,
          'An incorrect Total Amount Including Tax was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TaxAmount],
          TotalTax,
          RoundingPrecision,
          'An incorrect Tax Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::DiscountPercent],
          TotalDiscountPercent,
          RoundingPrecision,
          'Customer Discount Percent value is incorrect');
        VerifyFieldValuesNotZero(PostAmounts);
    end;

    local procedure SetupCalcInvoiceDisc(var Option: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        OriginalOption: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        OriginalOption := PurchasesPayablesSetup."Calc. Inv. Discount";
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount");
        PurchasesPayablesSetup.Modify(true);
        Option := OriginalOption;
    end;

    local procedure SetupDataForDiscountTypePct(var Vendor: Record Vendor; var DiscPct: Decimal; TaxAreaCode: Code[20]; var ItemNo: Code[20]; var ItemQuantity: Decimal; TaxGroupCode: Code[20])
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        ItemNo := CreateItemSpecifyUnitPrice(TaxGroupCode, ItemUnitPrice);
        CreateVendorWithDiscount(Vendor, TaxAreaCode, DiscPct, MinAmt);
    end;

    local procedure PurchCopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type From"; ReCalculateLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, DocumentNo, false, ReCalculateLines);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.RunModal();
    end;

    local procedure CreateItemWithDimension(DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type"; TaxGroupCode: Code[20]) ItemNo: Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.CreateItem(Item);
        // Use Random because value is not important.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2) + LibraryUtility.GenerateRandomFraction());
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2) + LibraryUtility.GenerateRandomFraction());
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        ItemNo := Item."No.";
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item; DimensionCode: Code[20]; TaxGroupCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItemWithDimension(DimensionCode, DefaultDimension."Value Posting"::" ", TaxGroupCode));
        Item.Validate("Automatic Ext. Texts", true);
        Item.Validate("VAT Prod. Posting Group", '');

        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; StandardPurchaseCode: Code[10]; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode);
        StandardPurchaseLine.Validate(Type, Type);
        StandardPurchaseLine.Validate("No.", No);

        // Use Random because value is not important.
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        StandardPurchaseLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCodePageHandler(var StandardVendorPurchaseCodes: Page "Standard Vendor Purchase Codes"; var Response: Action)
    begin
        // Modal Page Handler.
        StandardVendorPurchaseCodes.SetRecord(StandardVendorPurchaseCode);
        Response := ACTION::LookupOK;
    end;

    [Scope('OnPrem')]
    procedure CreateVendorWithPurchaseCodes(var VendorNo: Code[20]; var TaxAreaCode: Code[20])
    var
        Dimension: Record Dimension;
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        TaxDetail: Record "Tax Detail";
        Item: Record Item;
        TaxPercentage: Decimal;
    begin
        TaxPercentage := LibraryRandom.RandInt(9);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        VendorNo := CreateVendor(TaxAreaCode);
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code, TaxDetail."Tax Group Code");
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::Item, Item."No.");
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, VendorNo, StandardPurchaseLine."Standard Purchase Code");
    end;

    [Scope('OnPrem')]
    procedure CreateVendorWithPurchaseCodesAndInvDisc(var VendorNo: Code[20]; var TaxAreaCode: Code[20])
    var
        Dimension: Record Dimension;
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        Vendor: Record Vendor;
        TaxDetail: Record "Tax Detail";
        Item: Record Item;
        TaxPercentage: Decimal;
        MinAmt: Decimal;
        DiscPct: Decimal;
        ItemUnitPrice: Decimal;
    begin
        TaxPercentage := LibraryRandom.RandInt(9);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        CreateVendorWithDiscount(Vendor, TaxAreaCode, DiscPct, MinAmt);

        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code, TaxDetail."Tax Group Code");
        Item.Validate("Unit Price", ItemUnitPrice);
        Item.Validate("Last Direct Cost", ItemUnitPrice);
        Item.Modify(true);

        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::Item, Item."No.");
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseLine."Standard Purchase Code");
        UpdateVendorTaxAreaCode(Vendor, TaxAreaCode);
        VendorNo := Vendor."No.";
    end;

    local procedure FindPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Find('-');
    end;

    local procedure CreateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Blank VAT Posting Setup with VAT Calculation Type - Sales Tax to fix MX,CA Country failure.
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CollectDataFromPurchaseInvoicePage(var PurchaseHeader: Record "Purchase Header"; PurchaseInvoice: TestPage "Purchase Invoice"; var PostAmounts: array[5] of Decimal; var TotalTax: Decimal)
    begin
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;
    end;

    [Scope('OnPrem')]
    procedure CollectDataFromPurchaseOrderPage(var PurchaseHeader: Record "Purchase Header"; PurchaseOrder: TestPage "Purchase Order"; var OrderAmounts: array[5] of Decimal; var TotalTax: Decimal)
    begin
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;
    end;
}

