codeunit 144511 "ERM Allocation Charge"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ItemChargeAssgntDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Receipt,"Transfer Receipt","Return Shipment","Sales Shipment","Return Receipt";
        QtyToAssignIncorrectErr: Label 'Incorrect Qty. to Assign value';
        AmtToAssignIncorrectErr: Label 'Incorrect Amount to Assign value';

    [Test]
    [Scope('OnPrem')]
    procedure CheckUnitVolumeEmptyPurchErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight filled, Unit Volume Empty. Check Error Message on Purch Inv. Post
        CheckGrossUnitVolumeEmptyPurchErr(10, 0, Item.FieldCaption("Unit Volume"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGrossWeighEmptyPurchErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight Empty, Unit Volume filled. Check Error Message on Purch Inv. Post
        CheckGrossUnitVolumeEmptyPurchErr(0, 10, Item.FieldCaption("Gross Weight"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUnitVolumeEmptySalesErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight filled, Unit Volume Empty. Check Error Message on Sales Inv. Post
        CheckGrossUnitVolumeEmptySalesErr(10, 0, Item.FieldCaption("Unit Volume"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGrossWeighEmptySalesErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight Empty, Unit Volume filled. Check Error Message on Sales Inv. Post
        CheckGrossUnitVolumeEmptySalesErr(0, 10, Item.FieldCaption("Gross Weight"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUnitVolumeEmptyTransferErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight Empty, Unit Volume filled. Check Error Message on Transfer Order post
        CheckGrossUnitVolumeEmptyTransferErr(10, 0, Item.FieldCaption("Unit Volume"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGrossWeighEmptyTransferErr()
    var
        Item: Record Item;
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = TRUE
        // Gross Weight Empty, Unit Volume filled. Check Error Message on Transfer Order post
        CheckGrossUnitVolumeEmptyTransferErr(0, 10, Item.FieldCaption("Gross Weight"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GrossWeightAllocation1Item()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = FALSE
        // Verify correction of Suggest Item Charge Assignment for 1 item
        VerifySuggestItemChargeAssgnt(
          LibraryRandom.RandDec(100, 2), true, 0, false, ItemChargeAssgntPurch.AssignByWeightMenuText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VolumeAmountAllocation1Item()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Gross Weight Mandartory = FALSE, Unit Volume Mandatory = TRUE
        // Verify correction of Suggest Item Charge Assignment for 1 item
        VerifySuggestItemChargeAssgnt(
          0, false, LibraryRandom.RandDec(100, 2), true, ItemChargeAssgntPurch.AssignByVolumeMenuText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GrossWeightAllocation2Item()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = FALSE
        // Verify correction of Suggest Item Charge Assignment for 2 items
        VerifySuggestItemChargeAssgnt2(
          LibraryRandom.RandDec(100, 2), true, 0, false, ItemChargeAssgntPurch.AssignByWeightMenuText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VolumeAmountAllocation2Item()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Gross Weight Mandartory = TRUE, Unit Volume Mandatory = FALSE
        // Verify correction of Suggest Item Charge Assignment for 2 items
        VerifySuggestItemChargeAssgnt2(
          0, false, LibraryRandom.RandDec(100, 2), true, ItemChargeAssgntPurch.AssignByVolumeMenuText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GrossWeightAllocationPostedDocs()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Check Suggest Item Charge Assignment by Weight
        // for Posted Documents
        ItemChargeAssgntGetPostedDocs(ItemChargeAssgntPurch.AssignByWeightMenuText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VolumeAmountAllocationPostedDocs()
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // Check Suggest Item Charge Assignment by Volume
        // for Posted Documents
        ItemChargeAssgntGetPostedDocs(ItemChargeAssgntPurch.AssignByVolumeMenuText());
    end;

    local procedure CreateItem(GrossWeight: Decimal; GrossWeightMandatory: Boolean; UnitVolume: Decimal; UnitVolumeMandatory: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gross Weight", GrossWeight);
        Item.Validate("Gross Weight Mandatory", GrossWeightMandatory);
        Item.Validate("Unit Volume", UnitVolume);
        Item.Validate("Unit Volume Mandatory", UnitVolumeMandatory);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostPurchDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; Post: Boolean) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        if Post then
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostSalesDoc(DocType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; Post: Boolean) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if Post then
            DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostTransferOrder(FromLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal; Post: Boolean) DocumentNo: Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location2: Record Location;
        LocationInTransit: Record Location;
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation, Location2.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        if Post then begin
            LibraryInventory.PostTransferHeader(TransferHeader, true, true);
            TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
            TransferReceiptHeader.FindFirst();
            DocumentNo := TransferReceiptHeader."No.";
        end;
    end;

    local procedure CheckGrossUnitVolumeEmptyPurchErr(GrossWeight: Decimal; UnitVolume: Decimal; FieldCaption: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
    begin
        Initialize();
        ItemNo := CreateItem(GrossWeight, true, UnitVolume, true);
        asserterror CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ItemNo, 1, false);
        VerifyMustHaveAValueErr(FieldCaption);
    end;

    local procedure CheckGrossUnitVolumeEmptySalesErr(GrossWeight: Decimal; UnitVolume: Decimal; FieldCaption: Text)
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        Initialize();
        ItemNo := CreateItem(GrossWeight, true, UnitVolume, true);
        asserterror CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, ItemNo, 1, false);
        VerifyMustHaveAValueErr(FieldCaption);
    end;

    local procedure CheckGrossUnitVolumeEmptyTransferErr(GrossWeight: Decimal; UnitVolume: Decimal; FieldCaption: Text)
    var
        Location: Record Location;
        ItemNo: Code[20];
    begin
        Initialize();
        ItemNo := CreateItem(GrossWeight, true, UnitVolume, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        asserterror CreatePostTransferOrder(Location.Code, ItemNo, 1, false);
        VerifyMustHaveAValueErr(FieldCaption);
    end;

    local procedure VerifyMustHaveAValueErr(FieldCaption: Text)
    begin
        Assert.ExpectedTestFieldError(FieldCaption, '');
    end;

    local procedure CreatePurchDocItemChargeLine(PurchHeader: Record "Purchase Header"; ChargeNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocLine(PurchHeader, PurchLine.Type::"Charge (Item)", ChargeNo, Qty, UnitCost);
    end;

    local procedure SuggestItemChargeAssgntPurch(PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; SuggestSelectionTxt: Text)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchLine."Document No.", PurchLine."Line No.",
          PurchLine."No.", PurchLine.Quantity, PurchLine.Amount);
        ItemChargeAssgntPurch.CreateDocChargeAssgnt(ItemChargeAssignmentPurch, PurchLine."Receipt No.");
        ItemChargeAssgntPurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine.Amount, SuggestSelectionTxt);
    end;

    local procedure SuggestItemChargeFromDiffDocs(PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; SuggestSelectionTxt: Text; DocNos: array[5] of Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchLine."Document No.", PurchLine."Line No.",
          PurchLine."No.", PurchLine.Quantity, PurchLine.Amount);
        ItemChargeAssgntPurch.CreateDocChargeAssgnt(ItemChargeAssignmentPurch, PurchLine."Receipt No.");

        // Posted Receipt
        CreateItemChargeAssgntPurchInv(DocNos[1], ItemChargeAssignmentPurch, PurchLine);
        // Posted Shipment
        CreateItemChargeAssgntSalesInv(DocNos[2], ItemChargeAssignmentPurch, PurchLine);
        // Posted Purchase Return Order
        CreateItemChargeAssgntPurchCrM(DocNos[3], ItemChargeAssignmentPurch, PurchLine);
        // Posted Sales Return Order
        CreateItemChargeAssgntSalesCrM(DocNos[4], ItemChargeAssignmentPurch, PurchLine);
        // Posted Transfer Order
        CreateItemChargeAssgntTransferOrder(DocNos[5], ItemChargeAssignmentPurch, PurchLine);

        ItemChargeAssgntPurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", SuggestSelectionTxt);
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

    local procedure CreatePurchDocLine(PurchHeader: Record "Purchase Header"; ItemType: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, ItemType, ItemNo, Qty);
        PurchLine.Validate(Quantity, PurchLine.Quantity);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Modify(true);
    end;

    local procedure VerifySuggestItemChargeAssgnt(GrossWeight: Decimal; GrossWeightMandatory: Boolean; UnitVolume: Decimal; UnitVolumeMandatory: Boolean; SuggestSelectionTxt: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ChargeAmount: Decimal;
        ItemNo: Code[20];
    begin
        Initialize();
        ItemNo := CreateItem(
            GrossWeight, GrossWeightMandatory, UnitVolume, UnitVolumeMandatory);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ItemNo, 1, false);
        ChargeAmount := LibraryRandom.RandDec(100, 2);
        CreatePurchDocItemChargeLine(PurchaseHeader, ItemCharge."No.", 1, ChargeAmount);
        FindChargeItemPurchLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestItemChargeAssgntPurch(PurchaseLine, ItemCharge, SuggestSelectionTxt);
        VerifyPurchItemChargeAssgnt(ItemNo, 1, ChargeAmount);
    end;

    local procedure VerifySuggestItemChargeAssgnt2(GrossWeight: Decimal; GrossWeightMandatory: Boolean; UnitVolume: Decimal; UnitVolumeMandatory: Boolean; SuggestSelectionTxt: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ChargeAmount: Decimal;
        ItemNo1: Code[20];
        ItemNo2: Code[20];
        WeightVolumeMultiplier: Decimal;
        QtyToAssign: Decimal;
        QtyToAssignPrecision: Decimal;
        AmtToAssign: Decimal;
    begin
        Initialize();
        QtyToAssignPrecision := 0.00001;

        ItemNo1 := CreateItem(
            GrossWeight, GrossWeightMandatory, UnitVolume, UnitVolumeMandatory);
        WeightVolumeMultiplier := LibraryRandom.RandInt(10);
        ItemNo2 := CreateItem(
            GrossWeight * WeightVolumeMultiplier, GrossWeightMandatory,
            UnitVolume * WeightVolumeMultiplier, UnitVolumeMandatory);

        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ItemNo1, 1, false);
        CreatePurchDocLine(PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, 1, LibraryRandom.RandDec(100, 2));

        ChargeAmount := LibraryRandom.RandDec(100, 2);
        CreatePurchDocItemChargeLine(PurchaseHeader, ItemCharge."No.", 1, ChargeAmount);

        FindChargeItemPurchLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestItemChargeAssgntPurch(PurchaseLine, ItemCharge, SuggestSelectionTxt);

        QtyToAssign := Round(PurchaseLine.Quantity / (WeightVolumeMultiplier + 1), QtyToAssignPrecision);
        AmtToAssign := Round(ChargeAmount / (WeightVolumeMultiplier + 1), LibraryERM.GetAmountRoundingPrecision());

        VerifyPurchItemChargeAssgnt(ItemNo1,
          QtyToAssign, AmtToAssign);
        VerifyPurchItemChargeAssgnt(ItemNo2,
          Round(PurchaseLine.Quantity - QtyToAssign, QtyToAssignPrecision),
          Round(ChargeAmount - AmtToAssign, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure VerifyPurchItemChargeAssgnt(ItemNo: Code[20]; QtyToAssign: Decimal; AmtToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Item No.", ItemNo);
        ItemChargeAssignmentPurch.FindFirst();
        Assert.AreEqual(QtyToAssign, ItemChargeAssignmentPurch."Qty. to Assign", QtyToAssignIncorrectErr);
        Assert.AreEqual(AmtToAssign, ItemChargeAssignmentPurch."Amount to Assign", AmtToAssignIncorrectErr);
    end;

    local procedure ItemChargeAssgntGetPostedDocs(SuggestTypeTxt: Text)
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        DocumentNos: array[5] of Code[20];
        ItemNo: Code[20];
        ChargeAmount: Decimal;
        QtyToAssign: array[6] of Decimal;
        AmtToAssign: array[6] of Decimal;
        AppliesToDocType: array[6] of Option;
    begin
        Initialize();
        PreparePostedDocs(DocumentNos);
        ItemNo := CreateItem(
            10, true, 10, true);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ItemNo, 1, false);
        ChargeAmount := 100;
        CreatePurchDocItemChargeLine(PurchaseHeader, ItemCharge."No.", 1, ChargeAmount);
        FindChargeItemPurchLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestItemChargeFromDiffDocs(PurchaseLine, ItemCharge, SuggestTypeTxt, DocumentNos, ItemChargeAssignmentPurch);
        AssignVerifyValue(QtyToAssign, AmtToAssign, AppliesToDocType);
        VerifyItemChargeAssgntPurchValues(
          PurchaseHeader."Document Type"::Invoice, PurchaseHeader."No.",
          ItemChargeAssignmentPurch, QtyToAssign, AmtToAssign, AppliesToDocType);
    end;

    local procedure PreparePostedDocs(var DocumentNOs: array[5] of Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        ItemNo := CreateItem(10, true, 10, true);
        DocumentNOs[1] := CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, 1, true);
        DocumentNOs[2] := CreatePostSalesDoc(SalesHeader."Document Type"::Order, ItemNo, 1, true);
        DocumentNOs[3] := CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, 1, true);
        DocumentNOs[4] := CreatePostSalesDoc(SalesHeader."Document Type"::"Return Order", ItemNo, 1, true);
        CreatePostPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ItemNo, 1, true);
        DocumentNOs[5] := CreatePostTransferOrder(PurchaseHeader."Location Code", ItemNo, 1, true);
    end;

    local procedure FindPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", DocNo);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindSalesShipmentLines(var SalesShipmentLine: Record "Sales Shipment Line"; DocNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", DocNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindPurchRetShptLine(var ReturnShptLine: Record "Return Shipment Line"; DocNo: Code[20])
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        ReturnShptHeader.SetRange("Return Order No.", DocNo);
        ReturnShptHeader.FindFirst();
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.SetRange(Type, ReturnShptLine.Type::Item);
        ReturnShptLine.FindFirst();
    end;

    local procedure FindSalesRetRcptLine(var ReturnRcptLine: Record "Return Receipt Line"; DocNo: Code[20])
    var
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        ReturnRcptHeader.SetRange("Return Order No.", DocNo);
        ReturnRcptHeader.FindFirst();
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.SetRange(Type, ReturnRcptLine.Type::Item);
        ReturnRcptLine.FindFirst();
    end;

    local procedure FindTransferRcptLine(var TransferRcptLine: Record "Transfer Receipt Line"; DocNo: Code[20])
    var
        TransferRcptHeader: Record "Transfer Receipt Header";
    begin
        TransferRcptHeader.SetRange("Transfer Order No.", DocNo);

        TransferRcptHeader.FindFirst();
        TransferRcptLine.SetRange("Document No.", TransferRcptHeader."No.");
        TransferRcptLine.FindFirst();
    end;

    local procedure CreateItemChargeAssgntPurchInv(DocumentNo: Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        FindPurchReceiptLine(PurchRcptLine, PurchInvHeader."Order No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure CreateItemChargeAssgntSalesInv(DocumentNo: Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesInvHeader.Get(DocumentNo);
        FindSalesShipmentLines(SalesShipmentLine, SalesInvHeader."Order No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
    end;

    local procedure CreateItemChargeAssgntPurchCrM(DocumentNo: Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShptLine: Record "Return Shipment Line";
    begin
        PurchCrMemoHdr.Get(DocumentNo);
        FindPurchRetShptLine(ReturnShptLine, PurchCrMemoHdr."Return Order No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment",
          ReturnShptLine."Document No.", ReturnShptLine."Line No.", ReturnShptLine."No.");
    end;

    local procedure CreateItemChargeAssgntSalesCrM(DocumentNo: Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        FindSalesRetRcptLine(ReturnRcptLine, SalesCrMemoHeader."Return Order No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Receipt",
          ReturnRcptLine."Document No.", ReturnRcptLine."Line No.", ReturnRcptLine."No.");
    end;

    local procedure CreateItemChargeAssgntTransferOrder(DocumentNo: Code[20]; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    var
        TransferRcptHeader: Record "Transfer Receipt Header";
        TransferRcptLine: Record "Transfer Receipt Line";
    begin
        TransferRcptHeader.Get(DocumentNo);
        FindTransferRcptLine(TransferRcptLine, TransferRcptHeader."Transfer Order No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Transfer Receipt",
          TransferRcptLine."Document No.", TransferRcptLine."Line No.", TransferRcptLine."Item No.");
    end;

    local procedure AssignVerifyValue(var QtyToAssign: array[6] of Decimal; var AmtToAssign: array[6] of Decimal; var AppliesToDocType: array[6] of Option)
    begin
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 1, 0.16667, 16.67, ItemChargeAssgntDocType::Invoice);
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 2, 0.16666, 16.66, ItemChargeAssgntDocType::Receipt);
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 3, 0.16667, 16.67, ItemChargeAssgntDocType::"Sales Shipment");
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 4, 0.16667, 16.67, ItemChargeAssgntDocType::"Return Shipment");
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 5, 0.16666, 16.66, ItemChargeAssgntDocType::"Return Receipt");
        SetVerifyValues(QtyToAssign, AmtToAssign, AppliesToDocType, 6, 0.16667, 16.67, ItemChargeAssgntDocType::"Transfer Receipt");
    end;

    local procedure SetVerifyValues(var QtyToAssign: array[6] of Decimal; var AmtToAssign: array[6] of Decimal; var AppliesToDocType: array[6] of Option; id: Integer; QtyToAssignValue: Decimal; AmtToAssignValue: Decimal; DocType: Option)
    begin
        QtyToAssign[id] := QtyToAssignValue;
        AmtToAssign[id] := AmtToAssignValue;
        AppliesToDocType[id] := DocType;
    end;

    local procedure VerifyItemChargeAssgntPurchValues(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; QtyToAssign: array[5] of Decimal; AmtToAssign: array[5] of Decimal; AppliesToDocType: array[6] of Option)
    var
        Counter: Integer;
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", DocType);
        ItemChargeAssignmentPurch.SetRange("Document No.", DocNo);
        for Counter := 1 to ArrayLen(QtyToAssign) do begin
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", AppliesToDocType[Counter]);
            ItemChargeAssignmentPurch.FindFirst();
            Assert.AreNearlyEqual(QtyToAssign[Counter], ItemChargeAssignmentPurch."Qty. to Assign", 0.01, QtyToAssignIncorrectErr);
            Assert.AreNearlyEqual(AmtToAssign[Counter], ItemChargeAssignmentPurch."Amount to Assign", 0.01, AmtToAssignIncorrectErr);
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;
}

