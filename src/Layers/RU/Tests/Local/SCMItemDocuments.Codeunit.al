codeunit 147111 "SCM Item Documents"
{
    // // [FEATURE] [SCM]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRUReports: Codeunit "Library RU Reports";
        isInitialized: Boolean;
        WrongQuantityErr: Label 'Wrong quantity in "Item G/L Turnover"';
        WrongAmountErr: Label 'Wrong amount in "Item G/L Turnover"';
        ItemTrackingAction: Option AssignSerialNo,SelectEntries,ManualSN;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverCostBlank()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] Inbound item entries without cost are included in "Debit Qty." in "Item G/L Turnover", outbound entries - in credit qty.

        Initialize();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post inbound item entry with quantity = "X", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity * 2, 0);
        // [GIVEN] Post outbound item entry with quantity = "Y", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity, 0);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X", credit quantity = "Y"
        Assert.AreEqual(Quantity * 2, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Quantity, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Integer;
        UnitCost: Integer;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] "Item G/L Turnover" should show invoiced inbound item entries' Quantity and Amount in Debit columns, Outbound - in Credit columns

        Initialize();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);
        UnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Post inbound item entry with quantity = "X", actual cost amount = "Y"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity * 2, UnitCost);
        // [GIVEN] Post outbound item entry with quantity = "Z", actual cost amount = "W"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity, UnitCost);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X", debit amount = "Y", credit quantity = "Z", credit amount = "W"
        Assert.AreEqual(Quantity * 2, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Quantity, CreditQty, WrongQuantityErr);
        Assert.AreEqual(UnitCost * Quantity * 2, DebitCost, WrongAmountErr);
        Assert.AreEqual(UnitCost * Quantity, CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverExpectedCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] Item entries with expected cost not invoiced are not included in Inventory G/L Turnover

        Initialize();

        // [GIVEN] Post inbound item entry with quantity <> 0, expected cost amount <> 0
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post outbound item entry with quantity <> 0, expected cost amount <> 0
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = 0, debit amount = 0, credit quantity = 0, credit amount = 0
        Assert.AreEqual(0, DebitCost, WrongAmountErr);
        Assert.AreEqual(0, CreditCost, WrongAmountErr);
        Assert.AreEqual(0, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCostRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Amount: array[2] of Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation]
        // [SCENARIO 376914] Calculate "Item G/L Turnover" for positive item entry with negative revaluation

        Initialize();

        LibraryInventory.CreateItem(Item);
        Amount[1] := LibraryRandom.RandDecInRange(101, 200, 2);
        Amount[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post positive item entry for item "I", amount = "X"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1, Amount[1]);
        // [GIVEN] Revaluate item "I", new value = "Y" < "X" (revaluation amount is negative)
        PostItemRevaluation(Item."No.", Amount[2]);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit amount = "X", Credit amount = "X" - "Y"
        Assert.AreEqual(Amount[1], DebitCost, WrongAmountErr);
        Assert.AreEqual(Amount[1] - Amount[2], CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverRedStornoCostBlank()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Red Storno]
        // [SCENARIO 376914] Outbound item entry posted with "Red Storno" and cost amount = 0 is tallied in debit amount in "Item G/L Turnover"

        Initialize();
        EnableRedStorno();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Post inbound item entry: quantity = "X", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity * 2, 0);
        // [GIVEN] Post reversal item entry: quantity = -"X" / 2, "Red Storno" = TRUE, cost amount = 0
        PostItemJournalLineRedStorno(ItemJournalLine."Entry Type"::Purchase, Item."No.", -Quantity, 0);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X" / 2, credit quantity = 0
        Assert.AreEqual(Quantity, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCostRedStorno()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UnitCost: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Red Storno]
        // [SCENARIO 376914] Outbound item entry posted with "Red Storno" and positive cost amount is tallied in debit amount in "Item G/L Turnover"

        Initialize();
        EnableRedStorno();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post inbound item entry: quantity = "X", unit cost = "Y"
        PostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity * 2, UnitCost);
        // [GIVEN] Post reversal item entry: quantity = -"X" / 2, unit cost = "Y", "Red Storno" = TRUE
        PostItemJournalLineRedStorno(ItemJournalLine."Entry Type"::Purchase, Item."No.", -Quantity, UnitCost);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit Quantity = "X" / 2, credit quantity = 0
        Assert.AreEqual(Quantity, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemShipmentWithFA()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        FixedAssetNo: Code[20];
        DepreciationBookCode: Code[10];
        AcquisitionCostAccountNo: Code[20];
    begin
        // [FEATURE] [Item Shipment] [Fixed Asset]
        // [SCENARIO 379130] Write-off of items in the value of the fixed asset fills source info on acquisition cost G/L Entry
        Initialize();

        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fixed Asset "FA" and FA Depreciation Book with FA Posting Group where "Acquisition Cost Account" = "A"
        CreateFixedAsset(FixedAssetNo, DepreciationBookCode, AcquisitionCostAccountNo);

        // [GIVEN] Item Shipment with fixed asset "FA"
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);
        UpdateInvtDocumentLineFA(InvtDocumentHeader, FixedAssetNo, DepreciationBookCode);

        // [WHEN] Post Item Shipment
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Verify "Source Type" = "Fixed Asset", "Source No." = "FA" on generated G/L Entry with "G/L Account No." = "A"
        VerifyGLEntrySource(Location.Code, AcquisitionCostAccountNo, FixedAssetNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverWithNegativeRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        UnitCost: Decimal;
        NewAmount: Decimal;
        RevaluationAmount: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation]
        // [SCENARIO 379097] Debit and credit amounts on "Item G/L Turnover" page for revalued item. "Red Storno" is disabled.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDecInRange(50, 100, 2);
        NewAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        RevaluationAmount := Qty * UnitCost - NewAmount;

        // [GIVEN] Post 5 pcs, each per 150 LCY.
        // [GIVEN] Post -5 pcs. Run the cost adjustment.
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, UnitCost);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, 0);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Post the revaluation of the positive inventory adjustment. Old amount = 750 LCY, revalued amount = 700 LCY. Red Storno = FALSE.
        PostItemRevaluationPerItemLedgerEntry(Item."No.", NewAmount, false);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Open "Item G/L Turnover" page.
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = credit quantity = 5.
        // [THEN] Debit amount = 800 LCY (750 original + 50 adjusted cost of the negative adjustment entry posted as debit).
        // [THEN] Debit amount = 800 LCY (750 original + 50 revaluation of the original entry posted as credit).
        Assert.AreEqual(Qty, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Qty, CreditQty, WrongQuantityErr);
        Assert.AreEqual(Qty * UnitCost + RevaluationAmount, DebitCost, WrongAmountErr);
        Assert.AreEqual(Qty * UnitCost + RevaluationAmount, CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverWithNegativeRevaluationRedStorno()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        UnitCost: Decimal;
        NewAmount: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation] [Red Storno]
        // [SCENARIO 379097] Debit and credit amounts on "Item G/L Turnover" page for revalued item. "Red Storno" is enabled.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDecInRange(50, 100, 2);
        NewAmount := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Enable Red Storno.
        EnableRedStorno();

        // [GIVEN] Post 5 pcs, each per 150 LCY.
        // [GIVEN] Post -5 pcs. Run the cost adjustment.
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, UnitCost);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, 0);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Post the revaluation of the positive inventory adjustment. Old amount = 750 LCY, revalued amount = 700 LCY. Red Storno = TRUE.
        PostItemRevaluationPerItemLedgerEntry(Item."No.", NewAmount, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Open "Item G/L Turnover" page.
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = credit quantity = 5.
        // [THEN] Debit amount = 700 LCY (750 original - 50 revaluation of the original entry posted as debit with minus sign).
        // [THEN] Debit amount = 700 LCY (750 original - 50 adjusted cost of the negative adjustment entry posted as credit with minus sign).
        Assert.AreEqual(Qty, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Qty, CreditQty, WrongQuantityErr);
        Assert.AreEqual(NewAmount, DebitCost, WrongAmountErr);
        Assert.AreEqual(NewAmount, CreditCost, WrongAmountErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesRedStornoModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    procedure OutboundItemTrackingForInvtReceiptWithRedStorno()
    var
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ApplyToEntryNo: Integer;
    begin
        // [FEATURE] [Item Tracking] [Inventory Receipt] [Red Storno]
        // [SCENARIO 415530] Item Tracking Lines page works in outbound mode when opened for inventory receipt with red storno.
        Initialize();

        // [GIVEN] Enable Red Storno.
        EnableRedStorno();

        // [GIVEN] Serial no.-tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Inventory receipt for 1 pc, assign serial no., post.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Note item entry no. for the posted receipt.
        ApplyToEntryNo := FindLastPositiveItemLedgEntry(Item."No.");

        // [GIVEN] Inventory receipt with red storno.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader.Validate(Correction, true);
        InvtDocumentHeader.Modify(true);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);

        // [WHEN] Open item tracking lines for the inventory receipt line.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::SelectEntries);
        LibraryVariableStorage.Enqueue(ApplyToEntryNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [THEN] Item Tracking Lines page is opened in an outbound mode.
        // [THEN] It is possible to "Select Entries" and fill in "Applies-to-Entry No".

        // [THEN] The inventory receipt with red storno is successfully posted.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] The original receipt is reversed.
        VerifyItemInventory(Item, Location.Code, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesRedStornoModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure InboundItemTrackingForInvtShipmentWithRedStorno()
    var
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Item Tracking] [Inventory Shipment] [Red Storno]
        // [SCENARIO 415530] Item Tracking Lines page works in inbound mode when opened for inventory shipment with red storno.
        Initialize();

        // [GIVEN] Enable Red Storno.
        EnableRedStorno();

        // [GIVEN] Serial no.-tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Inventory receipt for 1 pc, assign serial no., post.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Inventory shipment for 1 pc, select serial no., post.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::SelectEntries);
        InvtDocumentLine.OpenItemTrackingLines();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Note item entry no. for the posted shipment.
        ItemLedgerEntry.Get(FindLastNegativeItemLedgEntry(Item."No."));

        // [GIVEN] Inventory shipment with red storno.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        InvtDocumentHeader.Validate(Correction, true);
        InvtDocumentHeader.Modify(true);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);

        // [WHEN] Open item tracking lines for the inventory shipment line.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::ManualSN);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Serial No.");
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        InvtDocumentLine.OpenItemTrackingLines();

        // [THEN] Item Tracking Lines page is opened in an inbound mode.
        // [THEN] It is possible to fill in "Applies-from-Entry No".

        // [THEN] The inventory shipment with red storno is successfully posted.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] The original shipment is reversed.
        VerifyItemInventory(Item, Location.Code, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        SetupInvtDocumentsNoSeries();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CalculateItemGLTurnover(var DebitCost: Decimal; var CreditCost: Decimal; var DebitQty: Decimal; var CreditQty: Decimal; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        ItemGLTurnover: Page "Item G/L Turnover";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ItemGLTurnover.CalculateAmounts(ValueEntry, DebitCost, CreditCost, DebitQty, CreditQty);
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20])
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, DocumentType, LocationCode);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaserCode);
        InvtDocumentHeader.Modify(true);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Quantity);

        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalespersonPurchaseWithDimension(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateFixedAsset(var FixedAssetNo: Code[20]; var DepreciationBookCode: Code[10]; var AcquisitionCostAccountNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAssetNo := FixedAsset."No.";
        DepreciationBookCode := LibraryRUReports.GetFirstFADeprBook(FixedAsset."No.");
        FADepreciationBook.Get(FixedAssetNo, DepreciationBookCode);
        FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
        AcquisitionCostAccountNo := FAPostingGroup."Acquisition Cost Account";
    end;

    local procedure EnableRedStorno()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Enable Red Storno" := true;
        InventorySetup.Modify();
    end;

    local procedure FindLastPositiveItemLedgEntry(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindLastNegativeItemLedgEntry(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure UpdateInvtDocumentLineFA(var InvtDocumentHeader: Record "Invt. Document Header"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.SetRange("Document Type", InvtDocumentHeader."Document Type");
        InvtDocumentLine.SetRange("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.FindFirst();
        InvtDocumentLine.Validate("Unit Amount", LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        InvtDocumentLine.Validate("Unit Cost", LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        InvtDocumentLine.Validate("FA No.", FixedAssetNo);
        InvtDocumentLine.Validate("Depreciation Book Code", DepreciationBookCode);
        InvtDocumentLine.Modify(true);
    end;

    local procedure SetupInvtDocumentsNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Posted Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Posted Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    local procedure PostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, Quantity, UnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemJournalLineRedStorno(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, Quantity, UnitCost);

        ItemJournalLine.Validate("Red Storno", true);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemRevaluation(ItemNo: Code[20]; NewAmount: Decimal)
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        Item.SetRange("No.", ItemNo);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Inventory Value (Revalued)", NewAmount);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemRevaluationPerItemLedgerEntry(ItemNo: Code[20]; NewAmount: Decimal; RedStorno: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);

        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Applies-to Entry", FindLastPositiveItemLedgEntry(ItemNo));
        ItemJournalLine."Red Storno" := RedStorno;
        ItemJournalLine.Validate("Inventory Value (Revalued)", NewAmount);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetupForItemDocument(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var Location: Record Location; var DimensionValue: Record "Dimension Value")
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSalespersonPurchaseWithDimension(SalespersonPurchaser, DimensionValue);
    end;

    local procedure VerifyGLEntrySource(LocationCode: Code[10]; AcquisitionCostAccountNo: Code[20]; FixedAssetNo: Code[20])
    var
        InvtShipmentHeader: Record "Invt. Shipment Header";
        GLEntry: Record "G/L Entry";
    begin
        InvtShipmentHeader.SetRange("Location Code", LocationCode);
        InvtShipmentHeader.FindFirst();

        GLEntry.SetRange("G/L Account No.", AcquisitionCostAccountNo);
        GLEntry.SetRange("Document No.", InvtShipmentHeader."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Source Type", GLEntry."Source Type"::"Fixed Asset");
        GLEntry.TestField("Source No.", FixedAssetNo);
    end;

    local procedure VerifyItemInventory(var Item: Record Item; LocationCode: Code[10]; ExpectedQty: Decimal)
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ExpectedQty);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesRedStornoModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        IsRedStorno: Boolean;
    begin
        IsRedStorno := LibraryVariableStorage.DequeueBoolean();

        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    if IsRedStorno then
                        ItemTrackingLines."Appl.-to Item Entry".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
            ItemTrackingAction::ManualSN:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(-1);
                    if IsRedStorno then
                        ItemTrackingLines."Appl.-from Item Entry".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;
}
