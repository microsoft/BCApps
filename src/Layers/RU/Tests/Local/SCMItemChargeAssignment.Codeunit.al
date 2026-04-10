codeunit 147110 "SCM Item Charge Assignment"
{
    //    TEST FUNCTION NAME                     TFS ID
    // 1. PurchItemAssAfterPreview               343707
    // 2. PurchItemAssWithModifyAndPreview       343709
    // 3. SalesItemAssAfterPreview               343708
    // 4. SalesItemAssWithModifyAndPreview       343710

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchItemAssAfterPreview()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeLineNo: Integer;
    begin
        // Verify Item Charge Assignment (Purch) table after
        // item charge suggestion with Amount option
        Initialize();

        ReproPurchScenario1(PurchHeader);
        ItemChargeLineNo := FindChargeItemPurchLine(PurchLine, PurchHeader."No.", PurchHeader."Buy-from Vendor No.");
        PreviewPurchDoc(PurchHeader);

        VerifyItemChargeAssPurchScenario1(PurchHeader."No.", ItemChargeLineNo);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchItemAssWithModifyAndPreview()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeLineNo: Integer;
    begin
        // Verify Item Charge Assignment (Purch) table after
        // item charge suggestion with Amount option and modification
        Initialize();

        ReproPurchScenario2(PurchHeader);
        ItemChargeLineNo := FindChargeItemPurchLine(PurchLine, PurchHeader."No.", PurchHeader."Buy-from Vendor No.");
        ModifyItemChargeAssPurch(PurchHeader."No.");
        PreviewPurchDoc(PurchHeader);

        VerifyItemChargeAssPurchScenario2(PurchHeader."No.", ItemChargeLineNo);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesItemAssAfterPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeLineNo: Integer;
    begin
        // Verify Item Charge Assignment (Sales) table after
        // item charge suggestion with Amount option
        Initialize();

        ReproSalesScenario1(SalesHeader);
        ItemChargeLineNo := FindChargeItemSalesLine(SalesLine, SalesHeader."No.", SalesHeader."Sell-to Customer No.");
        PreviewSalesDoc(SalesHeader);

        VerifyItemChargeAssSalesScenario1(SalesHeader."No.", ItemChargeLineNo);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesItemAssWithModifyAndPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeLineNo: Integer;
    begin
        // Verify Item Charge Assignment (Sales) table after
        // item charge suggestion with Amount option and modification
        Initialize();

        ReproSalesScenario2(SalesHeader);
        ItemChargeLineNo := FindChargeItemSalesLine(SalesLine, SalesHeader."No.", SalesHeader."Sell-to Customer No.");
        ModifyItemChargeAssSales(SalesHeader."No.");
        PreviewSalesDoc(SalesHeader);

        VerifyItemChargeAssSalesScenario2(SalesHeader."No.", ItemChargeLineNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;
        ModifyUserSetup();

        LibraryERMCountryData.UpdateGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    local procedure ModifyUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Init();
        UserSetup."User ID" := UserId;
        UserSetup.Insert(true);
    end;

    local procedure ReproPurchScenario1(var PurchHeader: Record "Purchase Header")
    var
        ItemQty: array[8] of Decimal;
        ItemAmt: array[8] of Decimal;
        ItemLineAmt: array[8] of Decimal;
        ChargeItemQty: Decimal;
        ChargeItemAmt: Decimal;
        ChargeItemLineAmt: Decimal;
    begin
        PurchSaleDocLinesData1(ItemQty, ItemAmt, ItemLineAmt, ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        ReproPurchScenario2Charge(
          PurchHeader,
          ItemQty, ItemAmt, ItemLineAmt,
          ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
    end;

    local procedure ReproPurchScenario2(var PurchHeader: Record "Purchase Header")
    var
        ItemQty: array[3] of Decimal;
        ItemAmt: array[3] of Decimal;
        ItemLineAmt: array[3] of Decimal;
        ChargeItemQty: Decimal;
        ChargeItemAmt: Decimal;
        ChargeItemLineAmt: Decimal;
    begin
        PurchSaleDocLinesData2(ItemQty, ItemAmt, ItemLineAmt, ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        ReproPurchScenario1Charge(
          PurchHeader,
          ItemQty, ItemAmt, ItemLineAmt,
          ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
    end;

    local procedure ReproPurchScenario2Charge(var PurchHeader: Record "Purchase Header"; ItemQty: array[8] of Decimal; ItemAmt: array[8] of Decimal; ItemLineAmt: array[8] of Decimal; ChargeItemQty: Decimal; ChargeItemAmt: Decimal; ChargeItemLineAmt: Decimal)
    var
        ItemCharge: Record "Item Charge";
        Vendor: Record Vendor;
        Items: array[8] of Code[20];
        i: Integer;
    begin
        CreateVendorItemCharge(Vendor, ItemCharge, Items, ArrayLen(ItemQty));

        CreatePurchDocHeader(PurchHeader, Vendor."No.");
        CreatePurchDocItemLine(PurchHeader, Items[1], ItemQty[1], ItemAmt[1], ItemLineAmt[1]);
        CreatePurchDocItemChargeLine(PurchHeader, ItemCharge."No.", 1, ChargeItemAmt, ChargeItemAmt);
        for i := 2 to ArrayLen(ItemQty) do
            CreatePurchDocItemLine(PurchHeader, Items[i], ItemQty[i], ItemAmt[i], ItemLineAmt[i]);
        FindSuggestPurchItemCharge(PurchHeader, ItemCharge, 1, ChargeItemAmt);

        CreatePurchDocItemChargeLine(PurchHeader, ItemCharge."No.", ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        FindSuggestPurchItemCharge(PurchHeader, ItemCharge, ChargeItemQty, ChargeItemLineAmt);
    end;

    local procedure ReproPurchScenario1Charge(var PurchHeader: Record "Purchase Header"; ItemQty: array[8] of Decimal; ItemAmt: array[8] of Decimal; ItemLineAmt: array[8] of Decimal; ChargeItemQty: Decimal; ChargeItemAmt: Decimal; ChargeItemLineAmt: Decimal)
    var
        ItemCharge: Record "Item Charge";
        Vendor: Record Vendor;
        Items: array[8] of Code[20];
        i: Integer;
    begin
        CreateVendorItemCharge(Vendor, ItemCharge, Items, ArrayLen(ItemQty));

        CreatePurchDocHeader(PurchHeader, Vendor."No.");
        for i := 1 to ArrayLen(ItemQty) do
            CreatePurchDocItemLine(PurchHeader, Items[i], ItemQty[i], ItemAmt[i], ItemLineAmt[i]);

        CreatePurchDocItemChargeLine(PurchHeader, ItemCharge."No.", ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        FindSuggestPurchItemCharge(PurchHeader, ItemCharge, 1, ChargeItemAmt);
    end;

    local procedure ReproSalesScenario1(var SalesHeader: Record "Sales Header")
    var
        ItemQty: array[8] of Decimal;
        ItemAmt: array[8] of Decimal;
        ItemLineAmt: array[8] of Decimal;
        ChargeItemQty: Decimal;
        ChargeItemAmt: Decimal;
        ChargeItemLineAmt: Decimal;
    begin
        PurchSaleDocLinesData1(ItemQty, ItemAmt, ItemLineAmt, ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        ReproSalesScenario2Charge(
          SalesHeader,
          ItemQty, ItemAmt, ItemLineAmt,
          ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
    end;

    local procedure ReproSalesScenario2(var SalesHeader: Record "Sales Header")
    var
        ItemQty: array[3] of Decimal;
        ItemAmt: array[3] of Decimal;
        ItemLineAmt: array[3] of Decimal;
        ChargeItemQty: Decimal;
        ChargeItemAmt: Decimal;
        ChargeItemLineAmt: Decimal;
    begin
        PurchSaleDocLinesData2(ItemQty, ItemAmt, ItemLineAmt, ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        ReproSalesScenario1Charge(
          SalesHeader,
          ItemQty, ItemAmt, ItemLineAmt,
          ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
    end;

    local procedure ReproSalesScenario2Charge(var SalesHeader: Record "Sales Header"; ItemQty: array[8] of Decimal; ItemAmt: array[8] of Decimal; ItemLineAmt: array[8] of Decimal; ChargeItemQty: Decimal; ChargeItemAmt: Decimal; ChargeItemLineAmt: Decimal)
    var
        Customer: Record Customer;
        ItemCharge: Record "Item Charge";
        Items: array[8] of Code[20];
        i: Integer;
    begin
        CreateCustomerItemCharge(Customer, ItemCharge, Items, ArrayLen(ItemQty));

        CreateSalesDocHeader(SalesHeader, Customer."No.");
        CreateSalesDocItemLine(SalesHeader, Items[1], ItemQty[1], ItemAmt[1], ItemLineAmt[1]);
        CreateSalesDocItemChargeLine(SalesHeader, ItemCharge."No.", 1, ChargeItemAmt, ChargeItemAmt);
        for i := 2 to ArrayLen(ItemQty) do
            CreateSalesDocItemLine(SalesHeader, Items[i], ItemQty[i], ItemAmt[i], ItemLineAmt[i]);

        FindSuggestSalesItemCharge(SalesHeader, ItemCharge, 1, ChargeItemAmt);

        CreateSalesDocItemChargeLine(SalesHeader, ItemCharge."No.", ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        FindSuggestSalesItemCharge(SalesHeader, ItemCharge, ChargeItemQty, ChargeItemLineAmt);
    end;

    local procedure ReproSalesScenario1Charge(var SalesHeader: Record "Sales Header"; ItemQty: array[8] of Decimal; ItemAmt: array[8] of Decimal; ItemLineAmt: array[8] of Decimal; ChargeItemQty: Decimal; ChargeItemAmt: Decimal; ChargeItemLineAmt: Decimal)
    var
        Customer: Record Customer;
        ItemCharge: Record "Item Charge";
        Items: array[8] of Code[20];
        i: Integer;
    begin
        CreateCustomerItemCharge(Customer, ItemCharge, Items, ArrayLen(ItemQty));

        CreateSalesDocHeader(SalesHeader, Customer."No.");
        for i := 1 to ArrayLen(ItemQty) do
            CreateSalesDocItemLine(SalesHeader, Items[i], ItemQty[i], ItemAmt[i], ItemLineAmt[i]);

        CreateSalesDocItemChargeLine(SalesHeader, ItemCharge."No.", ChargeItemQty, ChargeItemAmt, ChargeItemLineAmt);
        FindSuggestSalesItemCharge(SalesHeader, ItemCharge, ChargeItemQty, ChargeItemLineAmt);
    end;

    local procedure PreviewPurchDoc(PurchHeader: Record "Purchase Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Post (Yes/No)", PurchHeader);
    end;

    local procedure PreviewSalesDoc(SalesHeader: Record "Sales Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);
    end;

    local procedure CreatePurchDocHeader(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        PurchHeader.SetHideValidationDialog(true);
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchDocItemLine(PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocLine(PurchHeader, PurchLine.Type::Item, ItemNo, Qty, UnitCost, LineAmt);
    end;

    local procedure CreatePurchDocItemChargeLine(PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocLine(PurchHeader, PurchLine.Type::"Charge (Item)", ItemNo, Qty, UnitCost, LineAmt);
    end;

    local procedure CreatePurchDocLine(PurchHeader: Record "Purchase Header"; ItemType: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, ItemType, ItemNo, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Line Amount", LineAmt);
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDocHeader(var SalesHeader: Record "Sales Header"; CustNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
    end;

    local procedure CreateSalesDocItemLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocLine(SalesHeader, SalesLine.Type::Item, ItemNo, Qty, UnitCost, LineAmt);
    end;

    local procedure CreateSalesDocItemChargeLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocLine(SalesHeader, SalesLine.Type::"Charge (Item)", ItemNo, Qty, UnitCost, LineAmt);
    end;

    local procedure CreateSalesDocLine(var SalesHeader: Record "Sales Header"; ItemType: Enum "Sales Line Type"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, ItemType, ItemNo, Qty);
        SalesLine.Validate("Unit Price", UnitCost);
        SalesLine.Validate("Line Amount", LineAmt);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCust(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSeveralItems(var Items: array[8] of Code[20]; Qty: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Qty do
            Items[i] := LibraryInventory.CreateItemNo();
    end;

    local procedure FindChargeItemPurchLine(var PurchLine: Record "Purchase Line"; DocumentNo: Code[20]; VendorNo: Code[20]): Integer
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", DocumentNo);
        PurchLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchLine.SetRange(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.FindLast();
        exit(PurchLine."Line No.");
    end;

    local procedure FindChargeItemSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; CustNo: Code[20]): Integer
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Sell-to Customer No.", CustNo);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindLast();
        exit(SalesLine."Line No.");
    end;

    local procedure ModifyItemChargeAssPurch(DocumentNo: Code[20])
    var
        ItemChargeAssPurch: Record "Item Charge Assignment (Purch)";
        QtyToAssign: array[3] of Decimal;
        AmtToAssign: array[3] of Decimal;
    begin
        PurchSaleCheckData2(QtyToAssign, AmtToAssign);
        ItemChargeAssPurch.SetRange("Document Type", ItemChargeAssPurch."Document Type"::Invoice);
        ItemChargeAssPurch.SetRange("Document No.", DocumentNo);
        if ItemChargeAssPurch.FindSet() then begin
            ItemChargeAssPurch.FindFirst();
            ModifyItemChargeAssPurchLine(ItemChargeAssPurch, QtyToAssign[1], AmtToAssign[1]);
            ItemChargeAssPurch.Next();
            ModifyItemChargeAssPurchLine(ItemChargeAssPurch, QtyToAssign[2], AmtToAssign[2]);
        end;
    end;

    local procedure ModifyItemChargeAssPurchLine(var ItemChargeAssPurch: Record "Item Charge Assignment (Purch)"; QtyToAssign: Decimal; AmtToAssign: Decimal)
    begin
        ItemChargeAssPurch.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssPurch.Validate("Amount to Assign", AmtToAssign);
        ItemChargeAssPurch.Modify(true);
    end;

    local procedure ModifyItemChargeAssSales(DocumentNo: Code[20])
    var
        ItemChargeAssSales: Record "Item Charge Assignment (Sales)";
        QtyToAssign: array[3] of Decimal;
        AmtToAssign: array[3] of Decimal;
    begin
        PurchSaleCheckData2(QtyToAssign, AmtToAssign);
        ItemChargeAssSales.SetRange("Document Type", ItemChargeAssSales."Document Type"::Invoice);
        ItemChargeAssSales.SetRange("Document No.", DocumentNo);
        if ItemChargeAssSales.FindSet() then begin
            ItemChargeAssSales.FindFirst();
            ModifyItemChargeAssSalesLine(ItemChargeAssSales, QtyToAssign[1], AmtToAssign[1]);
            ItemChargeAssSales.Next();
            ModifyItemChargeAssSalesLine(ItemChargeAssSales, QtyToAssign[2], AmtToAssign[2]);
        end;
    end;

    local procedure ModifyItemChargeAssSalesLine(var ItemChargeAssSales: Record "Item Charge Assignment (Sales)"; QtyToAssign: Decimal; AmtToAssign: Decimal)
    begin
        ItemChargeAssSales.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssSales.Validate("Amount to Assign", AmtToAssign);
        ItemChargeAssSales.Modify(true);
    end;

    local procedure PurchSaleDocLinesData1(var ItemQty: array[8] of Decimal; var ItemAmt: array[8] of Decimal; var LineAmt: array[8] of Decimal; var ChargeItemQty: Decimal; var ChargeItemAmt: Decimal; var ChargeLineAmt: Decimal)
    begin
        FillDocLineArray(ItemQty[1], 2, ItemAmt[1], 354.24, LineAmt[1], 708.47);
        FillDocLineArray(ItemQty[2], 2, ItemAmt[2], 2583.9, LineAmt[2], 5167.8);
        FillDocLineArray(ItemQty[3], 2, ItemAmt[3], 424.58, LineAmt[3], 849.15);
        FillDocLineArray(ItemQty[4], 2, ItemAmt[4], 53.39, LineAmt[4], 106.78);
        FillDocLineArray(ItemQty[5], 2, ItemAmt[5], 59.32, LineAmt[5], 118.64);
        FillDocLineArray(ItemQty[6], 2, ItemAmt[6], 1168.65, LineAmt[6], 2337.29);
        FillDocLineArray(ItemQty[7], 30, ItemAmt[7], 31.36, LineAmt[7], 940.68);
        FillDocLineArray(ItemQty[8], 2, ItemAmt[8], 338.99, LineAmt[8], 677.97);
        ChargeItemQty := 6.4;
        ChargeItemAmt := 1610.17;
        ChargeLineAmt := 10305.08;
    end;

    local procedure PurchSaleCheckData1(var QtyToAssign: array[8] of Decimal; var AmtToAssign: array[8] of Decimal)
    begin
        FillCheckDataArray(QtyToAssign[1], 0.41572, AmtToAssign[1], 669.38);
        FillCheckDataArray(QtyToAssign[2], 3.03242, AmtToAssign[2], 4882.71);
        FillCheckDataArray(QtyToAssign[3], 0.49827, AmtToAssign[3], 802.3);
        FillCheckDataArray(QtyToAssign[4], 0.06266, AmtToAssign[4], 100.89);
        FillCheckDataArray(QtyToAssign[5], 0.06962, AmtToAssign[5], 112.1);
        FillCheckDataArray(QtyToAssign[6], 1.3715, AmtToAssign[6], 2208.35);
        FillCheckDataArray(QtyToAssign[7], 0.55198, AmtToAssign[7], 888.78);
        FillCheckDataArray(QtyToAssign[8], 0.39783, AmtToAssign[8], 640.57);
    end;

    local procedure PurchSaleDocLinesData2(var ItemQty: array[3] of Decimal; var ItemAmt: array[3] of Decimal; var LineAmt: array[3] of Decimal; var ChargeItemQty: Decimal; var ChargeItemAmt: Decimal; var ChargeLineAmt: Decimal)
    begin
        FillDocLineArray(ItemQty[1], 2, ItemAmt[1], 354.24, LineAmt[1], 708.47);
        FillDocLineArray(ItemQty[2], 3, ItemAmt[2], 2583.9, LineAmt[2], 7751.7);
        FillDocLineArray(ItemQty[3], 3, ItemAmt[3], 424.58, LineAmt[3], 1273.73);
        ChargeItemQty := 7.3;
        ChargeItemAmt := 1610.17;
        ChargeLineAmt := 11754.23;
    end;

    local procedure PurchSaleCheckData2(var QtyToAssign: array[3] of Decimal; var AmtToAssign: array[3] of Decimal)
    begin
        FillCheckDataArray(QtyToAssign[1], 0.53133, AmtToAssign[1], 855.53);
        FillCheckDataArray(QtyToAssign[2], 5.81343, AmtToAssign[2], 9360.6);
        FillCheckDataArray(QtyToAssign[3], 0.95524, AmtToAssign[3], 1538.1);
    end;

    local procedure VerifyItemChargeAssPurchScenario1(DocumentNo: Code[20]; ItemChargeLineNo: Integer)
    var
        QtyToAssign: array[8] of Decimal;
        AmtToAssign: array[8] of Decimal;
    begin
        PurchSaleCheckData1(QtyToAssign, AmtToAssign);
        VerifyItemChargeAssPurchScenario(DocumentNo, QtyToAssign, AmtToAssign, ItemChargeLineNo);
    end;

    local procedure VerifyItemChargeAssPurchScenario2(DocumentNo: Code[20]; ItemChargeLineNo: Integer)
    var
        QtyToAssign: array[3] of Decimal;
        AmtToAssign: array[3] of Decimal;
    begin
        PurchSaleCheckData2(QtyToAssign, AmtToAssign);
        VerifyItemChargeAssPurchScenario(DocumentNo, QtyToAssign, AmtToAssign, ItemChargeLineNo);
    end;

    local procedure VerifyItemChargeAssPurchScenario(DocumentNo: Code[20]; QtyToAssign: array[8] of Decimal; AmtToAssign: array[8] of Decimal; ItemChargeLineNo: Integer)
    var
        ItemChargeAssPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
    begin
        ItemChargeAssPurch.SetRange("Document Type", ItemChargeAssPurch."Document Type"::Invoice);
        ItemChargeAssPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssPurch.SetRange("Document Line No.", ItemChargeLineNo);
        ItemChargeAssPurch.FindSet();
        i := 1;
        repeat
            Assert.AreNearlyEqual(QtyToAssign[i], ItemChargeAssPurch."Qty. to Assign", 0.01, '');
            Assert.AreNearlyEqual(AmtToAssign[i], ItemChargeAssPurch."Amount to Assign", 0.01, '');
            i += 1;
        until ItemChargeAssPurch.Next() = 0;
    end;

    local procedure VerifyItemChargeAssSalesScenario1(DocumentNo: Code[20]; ItemChargeLineNo: Integer)
    var
        QtyToAssign: array[8] of Decimal;
        AmtToAssign: array[8] of Decimal;
    begin
        PurchSaleCheckData1(QtyToAssign, AmtToAssign);
        VerifyItemChargeAssSalesScenario(DocumentNo, QtyToAssign, AmtToAssign, ItemChargeLineNo);
    end;

    local procedure VerifyItemChargeAssSalesScenario2(DocumentNo: Code[20]; ItemChargeLineNo: Integer)
    var
        QtyToAssign: array[3] of Decimal;
        AmtToAssign: array[3] of Decimal;
    begin
        PurchSaleCheckData2(QtyToAssign, AmtToAssign);
        VerifyItemChargeAssSalesScenario(DocumentNo, QtyToAssign, AmtToAssign, ItemChargeLineNo);
    end;

    local procedure VerifyItemChargeAssSalesScenario(DocumentNo: Code[20]; QtyToAssign: array[8] of Decimal; AmtToAssign: array[8] of Decimal; ItemChargeLineNo: Integer)
    var
        ItemChargeAssSales: Record "Item Charge Assignment (Sales)";
        i: Integer;
    begin
        ItemChargeAssSales.SetRange("Document Type", ItemChargeAssSales."Document Type"::Invoice);
        ItemChargeAssSales.SetRange("Document No.", DocumentNo);
        ItemChargeAssSales.SetRange("Document Line No.", ItemChargeLineNo);
        ItemChargeAssSales.FindSet();
        i := 1;
        repeat
            Assert.AreEqual(QtyToAssign[i], ItemChargeAssSales."Qty. to Assign", '');
            Assert.AreEqual(AmtToAssign[i], ItemChargeAssSales."Amount to Assign", '');
            i += 1;
        until ItemChargeAssSales.Next() = 0;
    end;

    local procedure SuggestItemChargeAssgntPurch(PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemAmt: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchLine."Document No.", PurchLine."Line No.",
          PurchLine."No.", ChargeItemQty, ChargeItemAmt);
        ItemChargeAssgntPurch.CreateDocChargeAssgnt(ItemChargeAssignmentPurch, PurchLine."Receipt No.");
        ItemChargeAssgntPurch.SuggestAssgnt(PurchLine, PurchLine.Quantity, PurchLine."Line Amount");
    end;

    local procedure SuggestItemChargeAssgntSales(SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemAmt: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Invoice,
          SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."No.", ChargeItemQty, ChargeItemAmt);
        ItemChargeAssgntSales.CreateDocChargeAssgn(ItemChargeAssignmentSales, SalesLine."Shipment No.");
        ItemChargeAssgntSales.SuggestAssignment(SalesLine, SalesLine.Quantity, SalesLine."Line Amount");
    end;

    local procedure CreateVendorItemCharge(var Vendor: Record Vendor; var ItemCharge: Record "Item Charge"; var Items: array[8] of Code[20]; "Count": Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        Vendor.Get(CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));

        CreateSeveralItems(Items, Count);
    end;

    local procedure CreateCustomerItemCharge(var Customer: Record Customer; var ItemCharge: Record "Item Charge"; var Items: array[8] of Code[20]; "Count": Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        Customer.Get(CreateCust(VATPostingSetup."VAT Bus. Posting Group"));

        CreateSeveralItems(Items, Count);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSelection(Options: Text[1024]; var Choice: Integer; Instuction: Text[1024])
    begin
        Choice := 2;
    end;

    local procedure FillDocLineArray(var ItemQty: Decimal; ItemQtyValue: Decimal; var ItemAmt: Decimal; ItemAmtValue: Decimal; var LineAmt: Decimal; LineAmtValue: Decimal)
    begin
        ItemQty := ItemQtyValue;
        ItemAmt := ItemAmtValue;
        LineAmt := LineAmtValue;
    end;

    local procedure FillCheckDataArray(var QtyToAssign: Decimal; QtyToAssignValue: Decimal; var AmtToAssign: Decimal; AmtToAssignValue: Decimal)
    begin
        QtyToAssign := QtyToAssignValue;
        AmtToAssign := AmtToAssignValue;
    end;

    local procedure FindSuggestSalesItemCharge(SalesHeader: Record "Sales Header"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemLineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindChargeItemSalesLine(SalesLine, SalesHeader."No.", SalesHeader."Sell-to Customer No.");
        SuggestItemChargeAssgntSales(SalesLine, ItemCharge, ChargeItemQty, ChargeItemLineAmt);
    end;

    local procedure FindSuggestPurchItemCharge(PurchaseHeader: Record "Purchase Header"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemLineAmt: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindChargeItemPurchLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestItemChargeAssgntPurch(PurchaseLine, ItemCharge, ChargeItemQty, ChargeItemLineAmt);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(ConfirmMessage: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

