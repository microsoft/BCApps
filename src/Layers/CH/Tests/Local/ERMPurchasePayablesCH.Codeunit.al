codeunit 144049 "ERM Purchase Payables CH"
{
    // // [FEATURE] [Purchase]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATProdPostingGroupWhenUpdateShipmentDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExpectedVATPercent: Decimal;
        ExpectedAmountInclVAT: Decimal;
    begin
        // [SCENARIO 225589] Validate "VAT Prod Posting Group" when update "Expected Receipt Date" in Purchase Header

        // [GIVEN] Purchase Invoice with the following values in Purchase Line
        // [GIVEN] "VAT %" = 10
        // [GIVEN] "Amount Including VAT" = 110
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), PurchaseHeader."Document Type"::Invoice);
        ExpectedVATPercent := PurchaseLine."VAT %" + LibraryRandom.RandInt(5);
        ExpectedAmountInclVAT := Round(PurchaseLine.Amount / 100 * (100 + ExpectedVATPercent));

        // [GIVEN] "VAT %" was changed to 20 in "VAT Posting Setup"
        SetVATPercentInVATPostingSetup(
          PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", ExpectedVATPercent);

        // [WHEN] Validate "Expected Receipt Date" in Purchase Header
        PurchaseHeader.Validate("Expected Receipt Date");

        // [THEN] Purchase Line has the following values
        // [THEN] "VAT %" = 20
        // [THEN] "Amount Including VAT" = 120
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT %", ExpectedVATPercent);
        PurchaseLine.TestField("Amount Including VAT", ExpectedAmountInclVAT);
    end;

    [Test]
    procedure UpdatePurchaseOrderExpectedReceiptDateAfterPostingPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [Prepayment] [Receipt Date]
        // [SCENARIO 404747] Purchase Order "Expected Receipt Date" can be changed after posting prepayment invoice

        // [GIVEN] Purchase order with prepayment
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Expected Receipt Date", WorkDate());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(100));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Reopen the order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Modify "Expected Receipt Date"
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Expected Receipt Date", PurchaseHeader."Expected Receipt Date" + 1);
        PurchaseHeader.Modify(true);

        // [THEN] "Expected Receipt Date" has been updated
        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", PurchaseHeader."Expected Receipt Date");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    local procedure SetVATPercentInVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; NewVATPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("VAT %", NewVATPercent);
        VATPostingSetup.Modify(true);
    end;
}

