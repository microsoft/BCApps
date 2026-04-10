codeunit 137031 "SCM Costing Purchase Returns I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Return Order] [Purchase] [SCM]
        isInitialized := false;
    end;

    var
        Item: Record Item;
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        ErrAmountsMustBeSame: Label 'Purchase Amounts must be same.';
        CostingMethod: array[2] of Enum "Costing Method";
        MsgCorrectedInvoiceNo: Label 'have a Corrected Invoice No. Do you want to continue?';

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnItemAndCharge()
    begin
        // One Charge Line and one Item Line in Purchase Return Order.
        CostingMethod[1] := "Costing Method"::FIFO;
        PurchReturnItem(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnSameItemTwice()
    begin
        // No Charge Line and two Item Lines in Purchase Return Order of the same item.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchReturnItem(0, 1, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnDiffItems()
    begin
        // No Charge Line and two Item Lines in Purchase Return Order with different items.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        PurchReturnItem(0, 2, false);
    end;

    [Normal]
    local procedure PurchReturnItem(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        NoSeries: Codeunit "No. Series";
        PostedReturnShipmentNo: Code[20];
        PurchaseItemQty: Decimal;
        PurchaseOrderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Purchase Return Order.
        Initialize();
        UpdatePurchasePayableSetup();
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateAndPostPurchaseOrder(TempItem, PurchaseHeader, PurchaseItemQty);
        PurchaseOrderNo := PurchaseHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);

        // Create Purchase Return Order with Lines containing: Item, Charge or additional Item (Same or Different).
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        SetReasonCode(PurchaseHeader);
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader, TempItem, TempItemCharge, SameItemTwice, PurchaseItemQty - 1);

        // Update Purchase Return Lines with required Direct Cost and required Quantity.
        SelectPurchaseLines(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type"::"Return Order");
        TempItem.FindFirst();
        UpdatePurchaseLine(PurchaseLine, TempItem."Last Direct Cost", 1);  // Quantity Sign Factor value important for Test.
        PurchaseLine.Next();
        if NoOfCharges > 0 then begin
            UpdatePurchaseLine(PurchaseLine, -LibraryRandom.RandDec(10, 2), 1);  // Quantity Sign Factor value important for Test.
            CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo);
        end
        else
            if (NoOfItems > 0) and (NoOfCharges = 0) then begin
                TempItem.FindLast();
                UpdatePurchaseLine(PurchaseLine, -TempItem."Last Direct Cost", -1);  // Quantity Sign Factor value important for Test.
            end;
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseLine);
        PostedReturnShipmentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");

        // Exercise: Post Purchase Return Order and Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Vendor Ledger Entry.
        VerifyPurchaseAmounts(TempPurchaseLine, PurchaseHeader, PostedReturnShipmentNo, PurchaseOrderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnChargeMoveLineFIFO()
    begin
        // One Charge Line and one Item Line (Costing Method:FIFO) in Purchase Return Order. Move negative line to new Purchase Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchReturnItemMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnChargeMoveLineAvg()
    begin
        // One Charge Line and one Item Line (Costing Method:Avg) in Purchase Return Order. Move negative line to new Purchase Order.
        CostingMethod[1] := Item."Costing Method"::Average;
        PurchReturnItemMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnItemMoveLineFIFO()
    begin
        // No Charge Line and two Item Lines in Purchase Return Order of the same item. Move negative line to new Purchase Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchReturnItemMoveLine(0, 1, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnDiffItemsMoveLine()
    begin
        // No Charge Line and two Item Lines in Purchase Return Order with different items. Move negative line to new Purchase Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        PurchReturnItemMoveLine(0, 2, false);
    end;

    [Normal]
    local procedure PurchReturnItemMoveLine(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        NoSeries: Codeunit "No. Series";
        PostedReturnShipmentNo: Code[20];
        PurchaseItemQty: Decimal;
        PurchaseOrderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Purchase Return Order.
        Initialize();
        UpdatePurchasePayableSetup();
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateAndPostPurchaseOrder(TempItem, PurchaseHeader, PurchaseItemQty);
        PurchaseOrderNo := PurchaseHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);

        // Create Purchase Return Order with Lines containing: Item, Charge or additional Item (Same or Different).
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        SetReasonCode(PurchaseHeader);
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader, TempItem, TempItemCharge, SameItemTwice, PurchaseItemQty - 1);

        // Update Purchase Return Lines with required Last Direct Cost and required Quantity.
        SelectPurchaseLines(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type"::"Return Order");
        TempItem.FindFirst();
        UpdatePurchaseLine(PurchaseLine, TempItem."Last Direct Cost", -1);  // Quantity Sign Factor value important for Test.
        if NoOfCharges > 0 then begin
            PurchaseLine.Next();
            UpdatePurchaseLine(PurchaseLine, LibraryRandom.RandDec(10, 2), 1);  // Quantity Sign Factor value important for Test.
            CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo);
        end;

        // Move Negative Lines to a new Purchase Order.
        MoveNegativeLine(PurchaseHeader, PurchaseHeader2, "Purchase Document Type From"::"Return Order", "Purchase Document Type From"::Order);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseLine);
        PostedReturnShipmentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");

        // Exercise: Post Purchase Return Order and Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Vendor Ledger Entry.
        VerifyPurchaseAmounts(TempPurchaseLine, PurchaseHeader, PostedReturnShipmentNo, PurchaseOrderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoChargeAvg()
    begin
        // One Charge Line in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        PurchCrMemo(1, 0, false, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoChargeFIFO()
    begin
        // One Charge Line in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemo(1, 0, false, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoItemAvg()
    begin
        // One Item Line in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        PurchCrMemo(0, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoItemAvgAndCharge()
    begin
        // One Charge Line and one Item Line (Item Costing Method: Average) in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        PurchCrMemo(1, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoItemFIFOAndCharge()
    begin
        // One Charge Line and one Item Line (Item Costing Method: FIFO) in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemo(1, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoItemNegativeCharge()
    begin
        // One negative Charge Line and one Item Line (Item Costing Method: FIFO) in Purchase Credit Memo.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemo(1, 1, false, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoSameItemTwice()
    begin
        // No Charge Line and two Item Lines in Purchase Credit Memo of the same Item.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemo(0, 1, true, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoDiffItems()
    begin
        // No Charge Line and two Item Lines in Purchase Credit Memo with different items.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        PurchCrMemo(0, 2, false, -1);
    end;

    [Normal]
    local procedure PurchCrMemo(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean; SignFactor: Integer)
    var
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        NoSeries: Codeunit "No. Series";
        PostedReturnShipmentNo: Code[20];
        PurchaseItemQty: Decimal;
        PurchaseOrderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Credit Memo.
        Initialize();
        UpdatePurchasePayableSetup();
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateAndPostPurchaseOrder(TempItem, PurchaseHeader, PurchaseItemQty);
        PurchaseOrderNo := PurchaseHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);
        if NoOfItems = 0 then
            TempItem.Delete();

        // Make a Credit Memo for Item, Charge or both as required.
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        SetReasonCode(PurchaseHeader);
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader, TempItem, TempItemCharge, SameItemTwice, PurchaseItemQty - 1);

        // Update Credit Memo Lines with required Direct Cost and required Quantity.
        SelectPurchaseLines(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type"::"Credit Memo");
        if SameItemTwice then
            UpdatePurchaseLine(PurchaseLine, TempItem."Last Direct Cost", SignFactor)
        else
            if NoOfItems > 0 then begin
                TempItem.FindFirst();
                UpdatePurchaseLine(PurchaseLine, SignFactor * TempItem."Last Direct Cost", SignFactor);
                PurchaseLine.Next();
            end;

        if NoOfCharges > 0 then begin
            UpdatePurchaseLine(PurchaseLine, -SignFactor * LibraryRandom.RandDec(10, 2), 1);  // Sign Factor value important for Test.
            CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo);
        end;
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseLine);
        PostedReturnShipmentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        if TempItem.FindSet() then
            AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Vendor Ledger Entry.
        VerifyPurchaseAmounts(TempPurchaseLine, PurchaseHeader, PostedReturnShipmentNo, PurchaseOrderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoChargeMoveLineAvg()
    begin
        // One Charge Line and one Item Line (Item Costing method: Average) in Purchase Credit Memo.
        // Move negative line to new Purchase Invoice.
        CostingMethod[1] := Item."Costing Method"::Average;
        PurchCrMemoMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoChargeMoveLineFIFO()
    begin
        // One Charge Line and one Item Line (Item Costing method: FIFO) in Purchase Credit Memo.
        // Move negative line to new Purchase Invoice.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemoMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoItemMoveLineFIFO()
    begin
        // No Charge Line and two Item Lines in Purchase Credit Memo of the same item.
        // Move negative line to new Purchase Invoice.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        PurchCrMemoMoveLine(0, 1, true);
    end;

    [Normal]
    local procedure PurchCrMemoMoveLine(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        NoSeries: Codeunit "No. Series";
        PostedReturnShipmentNo: Code[20];
        PurchaseItemQty: Decimal;
        PurchaseOrderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Credit Memo.
        Initialize();
        UpdatePurchasePayableSetup();
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateAndPostPurchaseOrder(TempItem, PurchaseHeader, PurchaseItemQty);
        PurchaseOrderNo := PurchaseHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);

        // Make a Credit Memo for Item, Charge or both as required.
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        SetReasonCode(PurchaseHeader);
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader, TempItem, TempItemCharge, SameItemTwice, PurchaseItemQty - 1);

        // Update Credit Memo Lines with required Direct Cost and required Quantity.
        SelectPurchaseLines(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type"::"Credit Memo");
        UpdatePurchaseLine(PurchaseLine, TempItem."Last Direct Cost", -1);  // Quantity Sign Factor value important for Test.
        if NoOfCharges > 0 then begin
            PurchaseLine.Next();
            UpdatePurchaseLine(PurchaseLine, LibraryRandom.RandDec(10, 2), 1);  // Quantity Sign Factor value important for Test.
            CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo);
        end;

        // Move Negative Lines to a new Purchase Invoice.
        MoveNegativeLine(PurchaseHeader, PurchaseHeader2, "Purchase Document Type From"::"Credit Memo", "Purchase Document Type From"::Invoice);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseLine);
        PostedReturnShipmentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Vendor Ledger Entry.
        VerifyPurchaseAmounts(TempPurchaseLine, PurchaseHeader, PostedReturnShipmentNo, PurchaseOrderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoCopyReceiptDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempItem: Record Item temporary;
        NoSeries: Codeunit "No. Series";
        PurchaseItemQty: Decimal;
        PostedReturnShipmentNo: Code[20];
        PurchaseOrderNo: Code[20];
    begin
        // Setup: Create required Setups with only Item.
        Initialize();
        UpdatePurchasePayableSetup();
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CreateItemsAndCopyToTemp(TempItem, 1);  // No of Item = 1
        CreateAndPostPurchaseOrder(TempItem, PurchaseHeader, PurchaseItemQty);
        PurchaseOrderNo := PurchaseHeader."No.";

        // Create Credit Memo using Copy Document of Posted Purchase Receipt.
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        CreateCrMemo(PurchaseHeader);
        PurchaseHeaderCopyPurchDoc(PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.");

        // Copy Purchase Line to a temporary Purchase Line record.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No.");
        SelectPurchaseLines(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type"::"Credit Memo");
        UpdatePurchaseHeader(PurchaseHeader);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseLine);
        PostedReturnShipmentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");

        SetReasonCode(PurchaseHeader);
        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Vendor Ledger Entry.
        VerifyPurchaseAmounts(TempPurchaseLine, PurchaseHeader, PostedReturnShipmentNo, PurchaseOrderNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Purchase Returns I");
        ExecuteConfirmHandler();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Purchase Returns I");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        NoSeriesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Purchase Returns I");
    end;

    [Normal]
    local procedure UpdatePurchasePayableSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Shipment on Credit Memo", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateItemsAndCopyToTemp(var TempItem: Record Item temporary; NoOfItems: Integer)
    var
        Item: Record Item;
        Counter: Integer;
    begin
        if NoOfItems = 0 then
            NoOfItems += 1;
        for Counter := 1 to NoOfItems do begin
            Clear(Item);
            CreateItemWithInventory(Item, CostingMethod[Counter]);
            TempItem := Item;
            TempItem.Insert();
        end;
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; ItemCostingMethod: Enum "Costing Method")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Costing Method", ItemCostingMethod);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        UpdateItemInventory(Item."No.", LibraryRandom.RandInt(10) + 50);
    end;

    [Normal]
    local procedure UpdateItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure CreateAndPostPurchaseOrder(var TempItem: Record Item temporary; var PurchaseHeader: Record "Purchase Header"; var ItemQty: Decimal)
    var
        TempItemCharge: Record "Item Charge" temporary;
    begin
        // Create and Post Purchase Order.
        TempItem.CalcFields(Inventory);
        ItemQty := TempItem.Inventory - LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader, TempItem, TempItemCharge, false, ItemQty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateItemChargeAndCopyToTemp(var TempItemCharge: Record "Item Charge" temporary; NoOfCharges: Integer)
    var
        ItemCharge: Record "Item Charge";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfCharges do begin
            LibraryInventory.CreateItemCharge(ItemCharge);
            TempItemCharge := ItemCharge;
            TempItemCharge.Insert();
        end;
    end;

    [Normal]
    local procedure CreatePurchaseLines(var PurchaseHeader: Record "Purchase Header"; var TempItem: Record Item temporary; var TempItemCharge: Record "Item Charge" temporary; SameItemTwice: Boolean; ItemQty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if TempItem.FindSet() then
            repeat
                LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, TempItem."No.", ItemQty);
                if SameItemTwice then
                    LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, TempItem."No.", ItemQty);
            until TempItem.Next() = 0;

        if TempItemCharge.FindSet() then
            repeat
                LibraryPurchase.CreatePurchaseLine(
                  PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", TempItemCharge."No.", LibraryRandom.RandInt(1));
            until TempItemCharge.Next() = 0;
    end;

    [Normal]
    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal; SignFactor: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PurchaseLine.Validate(Quantity, SignFactor * PurchaseLine.Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        if (PurchaseLine.Type = PurchaseLine.Type::Item) and (PurchaseLine.Quantity > 0) then begin
            ItemLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
            ItemLedgerEntry.FindFirst();
            PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        end;
        PurchaseLine.Validate("Qty. to Receive", 0);  // Value important for Test.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemChargeAssignment(PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch.Validate("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.Validate("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.Validate("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.Validate("Item Charge No.", PurchaseLine."No.");
        ItemChargeAssignmentPurch.Validate("Unit Cost", PurchaseLine."Direct Unit Cost");
        AssignItemChargeToReceipt(ItemChargeAssignmentPurch, PurchaseOrderNo);
        UpdateItemChargeQtyToAssign(PurchaseLine, ItemChargeAssignmentPurch."Document No.");
    end;

    local procedure AssignItemChargeToReceipt(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseOrderNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.FindFirst();
        ItemChargeAssgntPurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssignmentPurch);
    end;

    local procedure UpdateItemChargeQtyToAssign(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo" then
            ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", PurchaseLine.Quantity);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    [Normal]
    local procedure SelectPurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeaderNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.FindSet();
    end;

    [Normal]
    local procedure MoveNegativeLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; ToDocType: Enum "Purchase Document Type From")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, true, true, true, false, false);
        PurchaseHeader2."Document Type" := CopyDocumentMgt.GetPurchaseDocumentType(ToDocType);
        CopyDocumentMgt.CopyPurchDoc(FromDocType, PurchaseHeader."No.", PurchaseHeader2);
    end;

    local procedure PurchaseHeaderCopyPurchDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocType, DocNo, true, true);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.RunModal();
    end;

    [Normal]
    local procedure CopyPurchaseLinesToTemp(var TempPurchaseLine: Record "Purchase Line" temporary; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.FindSet();
        repeat
            TempPurchaseLine := PurchaseLine;
            TempPurchaseLine.Insert();
        until PurchaseLine.Next() = 0;
    end;

    [Normal]
    local procedure CreateCrMemo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);
    end;

    [Normal]
    local procedure AdjustCostItemEntries(var TempItem: Record Item temporary)
    var
        Counter: Integer;
    begin
        TempItem.FindSet();
        for Counter := 1 to TempItem.Count do begin
            LibraryCosting.AdjustCostItemEntries(TempItem."No.", '');
            TempItem.Next();
        end;
    end;

    [Normal]
    local procedure VerifyPurchaseAmounts(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; PostedReturnShipmentNo: Code[20]; PurchaseOrderNo: Code[20])
    begin
        VerifyVendorLedgerEntry(TempPurchaseLine, PurchaseHeader."Vendor Cr. Memo No.");

        TempPurchaseLine.SetRange(Type, TempPurchaseLine.Type::Item);
        if TempPurchaseLine.FindFirst() then
            VerifyItemLedgerReturnShipment(PostedReturnShipmentNo);

        TempPurchaseLine.SetRange(Type, TempPurchaseLine.Type::"Charge (Item)");
        if TempPurchaseLine.FindFirst() then
            VerifyItemLedgerReceipt(TempPurchaseLine, PurchaseOrderNo);
    end;

    [Normal]
    local procedure VerifyVendorLedgerEntry(var TempPurchaseLine: Record "Purchase Line" temporary; PostedExternalDocNo: Code[35])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TotalAmountIncVAT: Decimal;
    begin
        // Verify Amount from Vendor Ledger Entry.
        TempPurchaseLine.FindSet();
        repeat
            TotalAmountIncVAT +=
              TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost" +
              (TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost" * (TempPurchaseLine."VAT %" / 100));
        until TempPurchaseLine.Next() = 0;

        VendorLedgerEntry.SetRange("External Document No.", PostedExternalDocNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);

        Assert.AreNearlyEqual(TotalAmountIncVAT, VendorLedgerEntry.Amount, 0.1, ErrAmountsMustBeSame);
    end;

    [Normal]
    local procedure VerifyItemLedgerReturnShipment(PostedReturnShipmentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnShipmentLine: Record "Return Shipment Line";
        CalcPurchaseAmount: Decimal;
        ActualPurchaseAmount: Decimal;
    begin
        // Verify Purchase Amount (Actual).
        ReturnShipmentLine.SetRange("Document No.", PostedReturnShipmentNo);
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::Item);
        ReturnShipmentLine.FindSet();
        repeat
            CalcPurchaseAmount += ReturnShipmentLine.Quantity * ReturnShipmentLine."Direct Unit Cost";
        until ReturnShipmentLine.Next() = 0;

        ItemLedgerEntry.SetRange("Document No.", PostedReturnShipmentNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Purchase Amount (Actual)");
            ActualPurchaseAmount += ItemLedgerEntry."Purchase Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;

        Assert.AreNearlyEqual(-CalcPurchaseAmount, ActualPurchaseAmount, 0.1, ErrAmountsMustBeSame);
    end;

    [Normal]
    local procedure VerifyItemLedgerReceipt(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseOrderNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CalcPurchaseAmountWithCharge: Decimal;
    begin
        // Verify Purchase Amount (Actual) from Purchase Receipt line after Item Charge has been applied to it.
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.FindFirst();
        TempPurchaseLine.SetRange(Type, TempPurchaseLine.Type::"Charge (Item)");
        TempPurchaseLine.FindSet();
        repeat
            CalcPurchaseAmountWithCharge +=
              PurchRcptLine.Quantity * PurchRcptLine."Direct Unit Cost" - TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost";
        until TempPurchaseLine.Next() = 0;

        ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Purchase Amount (Actual)");

        Assert.AreNearlyEqual(CalcPurchaseAmountWithCharge, ItemLedgerEntry."Purchase Amount (Actual)", 0.1, ErrAmountsMustBeSame);
    end;

    local procedure SetReasonCode(var PurchaseHeader: Record "Purchase Header")
    var
        ReasonCode: Record "Reason Code";
        PurchInvHeader: Record "Purch. Inv. Header";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if ReasonCode.Count = 0 then
            exit;

        ReasonCode.Next(LibraryRandom.RandInt(ReasonCode.Count));
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);

        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");

        if PurchInvHeader.FindFirst() and
           LibraryUtility.CheckFieldExistenceInTable(DATABASE::"Purchase Header", 'Adjustment Applies-to')
        then begin
            RecRef.GetTable(PurchaseHeader);
            FieldRef := RecRef.Field(LibraryUtility.FindFieldNoInTable(DATABASE::"Purchase Header", 'Adjustment Applies-to'));
            FieldRef.Validate(PurchInvHeader."No.");
            RecRef.SetTable(PurchaseHeader);

            PurchaseHeader.Modify(true);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MsgCorrectedInvoiceNo) > 0, Question);
        Reply := true;
    end;

    local procedure ExecuteConfirmHandler()
    begin
        if Confirm(MsgCorrectedInvoiceNo) then;
    end;
}

