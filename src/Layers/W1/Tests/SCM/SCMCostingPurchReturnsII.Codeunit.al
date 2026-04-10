codeunit 137032 "SCM Costing Purch Returns II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Return Order] [Purchase] [SCM]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PurchaseAmountMustBeSameErr: Label 'Purchase Amount must be same.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnsChargeAVG()
    begin
        // Purchase return with one Item and One Charge (Item).Costing Method Average.
        PurchReturnApplyCharge(Enum::"Costing Method"::Average, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnsNegChargeAVG()
    begin
        // Purchase return with two Item and One Charge (Item) with Negative Quantity.Costing Method Average.
        PurchReturnApplyCharge(Enum::"Costing Method"::Average, 2, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnsChargeFIFO()
    begin
        // Purchase return with One Charge (Item).Costing Method FIFO.
        PurchReturnApplyCharge(Enum::"Costing Method"::FIFO, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnsItemNegChargeAVG()
    begin
        // Purchase return with one Item and One Charge (Item) with Negative Quantity.Costing Method Average.
        PurchReturnApplyCharge(Enum::"Costing Method"::Average, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnsItemNegChargeFIFO()
    begin
        // Purchase return with one Item and One Charge (Item) with Negative Quantity.Costing Method FIFO.
        PurchReturnApplyCharge(Enum::"Costing Method"::FIFO, 1, -1);
    end;

    local procedure PurchReturnApplyCharge(CostingMethod: Enum "Costing Method"; ChargeOnItem: Integer; SignFactor: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase Setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        CreatePurchaseReturnSetup(PurchaseHeader, TempPurchaseLine, CostingMethod);

        // 2. Exercise: Create Purchase Return Order and apply on Purchase shipment.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", TempPurchaseLine."Buy-from Vendor No.");
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, CostingMethod, ChargeOnItem, 1);
        UpdatePurchaseLineQty(PurchaseLine, SignFactor);
        CreateItemChargeAssignmentLine(PurchaseLine, TempPurchaseLine."Document No.", TempPurchaseLine."No.");
        TransferPurchaseLineToTemp(TempPurchaseLine2, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(TempPurchaseLine."No.", '');

        // 3. Verify: Verify Purchase Amount after charge returned.
        // Verify Vendor ledger entry for total amount including VAT.
        VerifyPurchAmountChargeReturn(TempPurchaseLine, TempPurchaseLine2);
        VerifyVendorLedgerEntry(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnCopyDocPostedRecpt()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        CreatePurchaseReturnSetup(PurchaseHeader, TempPurchaseLine, Enum::"Costing Method"::Average);

        // 2. Exercise: Create Purchase Return Order using Copy Document of Posted Purchase shipment.
        PurchaseCopyDocument(
          PurchaseHeader, TempPurchaseLine2, PurchaseHeader."Document Type"::"Return Order", "Purchase Document Type From"::"Posted Receipt");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(TempPurchaseLine."No.", '');

        // 3. Verify: Verify Vendor ledger entry for total amount including VAT.
        VerifyVendorLedgerEntry(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnCopyDocPostedCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.Random Values used are notImportant for Test.
        // Update Apply From Item Entry No.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Enum::"Costing Method"::Average);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        UpdatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandInt(10));
        UpdateApplyToItemEntryNo(PurchaseLine, 1);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create Purchase Invoice using Copy Document of Posted Credit Memo.
        PurchaseCopyDocument(
          PurchaseHeader, TempPurchaseLine2, PurchaseHeader."Document Type"::Invoice, "Purchase Document Type From"::"Posted Credit Memo");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // 3. Verify: Verify Vendor ledger entry for total amount including VAT.
        VerifyVendorLedgerEntry(TempPurchaseLine2, TempPurchaseLine);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnApplyToItemEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BaseExactCostReversingMand: Boolean;
    begin
        // Covers TFS_TC_ID 120935.
        // 1. Setup: Create required Purchase setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", Enum::"Costing Method"::FIFO);

        // 2. Exercise: Post Purchase Return Order with 'Appl.-from Item Entry = 0'.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Verify Apply from Item Entry Error.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Appl.-to Item Entry"), '');

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnItemAVGFIFO()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Enum::"Costing Method"::FIFO);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::Average, 1, 0);
        UpdatePurchaseLineQty(PurchaseLine, -1);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create Purchase Return Order with Charge (Item) and apply on Purchase shipment to single Item.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseLine."Document Type"::"Return Order", TempPurchaseLine."Buy-from Vendor No.");
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::FIFO, 1, 1);
        CreateItemChargeAssignmentLine(PurchaseLine, TempPurchaseLine."Document No.", TempPurchaseLine."No.");
        TransferPurchaseLineToTemp(TempPurchaseLine2, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Verify Purchase Amount after charge returned.
        // Verify Vendor ledger entry for total amount including VAT.
        VerifyPurchAmountChargeReturn(TempPurchaseLine, TempPurchaseLine2);
        VerifyVendorLedgerEntry(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceChargeTwoItemsAVG()
    begin
        // Purchase Invoice for One charge (Item) and Two Items with Costing Method Average.
        PurchInvoiceApplyCharge(Enum::"Costing Method"::Average, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceChargeOneItemFIFO()
    begin
        // Purchase Invoice for One charge (Item) and One Item with Costing Method FIFO.
        PurchInvoiceApplyCharge(Enum::"Costing Method"::FIFO, 1);
    end;

    local procedure PurchInvoiceApplyCharge(CostingMethod: Enum "Costing Method"; NoOfItemLine: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        CreatePurchaseReturnSetup(PurchaseHeader, TempPurchaseLine, CostingMethod);

        // 2. Exercise: Create Purchase Invoice with one Charge (Item) and one or two Item line. Apply Charge on Purchase shipment.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TempPurchaseLine."Buy-from Vendor No.");
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, CostingMethod, 0, 1);
        UpdatePurchaseLineQty(PurchaseLine, -1);
        CreateItemChargeAssignmentLine(PurchaseLine, TempPurchaseLine."Document No.", TempPurchaseLine."No.");
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, CostingMethod, NoOfItemLine, 0);
        TransferPurchaseLineToTemp(TempPurchaseLine2, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify Purchase Amount after charge returned.
        VerifyPurchAmountChargeReturn(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceApplyTotemEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.Random Values used are notImportant for Test.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Enum::"Costing Method"::FIFO);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::Average, 1, 0);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create Purchase Invoice with one Charge (Item) and two Item line,Items with different costing method.
        // Update Apply FromItem Entry No and Apply Charge on Purchase shipment.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TempPurchaseLine."Buy-from Vendor No.");
        UpdatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, TempPurchaseLine."No.", TempPurchaseLine.Quantity);
        UpdateApplyToItemEntryNo(PurchaseLine, -1);

        PurchaseLine.Validate("Direct Unit Cost", -PurchaseLine."Direct Unit Cost");
        PurchaseLine.Modify(true);

        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::Average, 0, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
        CreateItemChargeAssignmentLine(PurchaseLine, TempPurchaseLine."Document No.", TempPurchaseLine."No.");
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::FIFO, 1, 0);
        TransferPurchaseLineToTemp(TempPurchaseLine2, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify Purchase Amount after charge returned.
        VerifyPurchAmountChargeReturn(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdMoveNegLineApplyEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create required Purchase setup.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        CreatePurchaseReturnSetup(PurchaseHeader, TempPurchaseLine, Enum::"Costing Method"::FIFO);

        // 2. Exercise: Create Purchase Order with two Items one with (negative Quantity).
        // Move Negative Item line to new Purchase Return Order.
        // Post Purchase Return Order  and Purchase Order. Run Adjust cost.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, TempPurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, TempPurchaseLine."No.", TempPurchaseLine.Quantity);
        UpdateApplyToItemEntryNo(PurchaseLine, -1);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::FIFO, 1, 0);
        MoveNegativeLines(PurchaseHeader, PurchaseHeader2, "Purchase Document Type From"::Order, "Purchase Document Type From"::"Return Order");
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        FindPurchaseLine(PurchaseHeader2, PurchaseLine);
        TransferPurchaseLineToTemp(TempPurchaseLine2, PurchaseLine);
        UpdatePurchaseHeader(PurchaseHeader2);
        UpdatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify Vendor ledger entry for total amount including VAT.
        VerifyVendorLedgerEntry(TempPurchaseLine, TempPurchaseLine2);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyChargeDivByZero()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        Vendor: Record Vendor;
        ItemNo: Code[20];
        BaseExactCostReversingMand: Boolean;
    begin
        // 1. Setup: Create Purchase Order with two Item Lines.Update Quantity to Ship as ZERO for first Line.
        // Post Partial Purchase Order. Create Item Charge Assignment and apply using Get Receipt Lines.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        UpdatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::FIFO, 2, 0);
        ItemNo := GetItemToBeInvUpdateQtyToRecv(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, Enum::"Costing Method"::FIFO, 0, 1);
        CreateItemChargeAssignmentLine(PurchaseLine, PurchaseLine."Document No.", ItemNo);
        UpdatePurchaseHeader(PurchaseHeader);

        // 2. Exercise: Post remaining Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Posted Purchase Order.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        Assert.RecordIsNotEmpty(PurchInvLine);

        // 4. Tear Down: Set value of 'Ext. Doc. No. Mandatory' to default in Purchase and Payable Setup.
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnPostOrderInvoiceStandard()
    var
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        BaseExactCostReversingMand: Boolean;
    begin
        // [FEATURE] [Standard Cost] [Adjust Cost - Item Entries] [Undo Return Shipment]
        // [SCENARIO 375439] When undoing purchase return shipment for standard cost item, variance of original receipt is recognized.

        // [GIVEN] "Exact Cost Reversing Mandatory" = TRUE, "Automatic Cost Posting" = TRUE, "Automatic Cost Adjustment" = Always.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        InventorySetup.Get();
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Item of Standard Cost = "C", purchase item, receive only, set "Direct Unit Cost" <> "C".
        // [GIVEN] Return item, ship only.
        // [GIVEN] Invoice purchase.
        // [WHEN] Undo Return Shipment.
        ItemNo := StandardItemPurchReturnShipmentVariance();

        // [THEN] Inserted adjusting Value Entries, where "Entry Type" is "Variance".
        VerifyValueEntryType(ItemNo, true, ValueEntry."Entry Type"::Variance);

        // Teardown.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnPostOrderInvoiceStandardNoOnlineAdj()
    var
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        BaseExactCostReversingMand: Boolean;
    begin
        // [FEATURE] [Standard Cost] [Adjust Cost - Item Entries] [Undo Return Shipment]
        // [SCENARIO 375842] When undoing purchase return shipment for standard cost item, variance of original receipt is recognized.

        // [GIVEN] "Exact Cost Reversing Mandatory" = TRUE, "Automatic Cost Posting" = FALSE, "Automatic Cost Adjustment" = Never.
        Initialize();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, true);
        InventorySetup.Get();
        UpdateInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Never);

        // [GIVEN] Item of Standard Cost = "C", purchase item, receive only, set "Direct Unit Cost" <> "C".
        // [GIVEN] Return item, ship only.
        // [GIVEN] Invoice purchase.
        // [GIVEN] Undo Return Shipment.
        ItemNo := StandardItemPurchReturnShipmentVariance();

        // [WHEN] Run Adjust Cost - Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // [THEN] Inserted adjusting Value Entries, where "Entry Type" is "Variance".
        VerifyValueEntryType(ItemNo, true, ValueEntry."Entry Type"::Variance);

        // Teardown.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoExactCostRevMandPurchReturnOrderInvStandard()
    var
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        BaseExactCostReversingMand: Boolean;
    begin
        // [FEATURE] [Standard Cost] [Adjust Cost - Item Entries] [Undo Return Shipment]
        // [SCENARIO 375439] When undoing purchase return shipment for standard cost item, variance of original receipt is recognized.

        // [GIVEN] "Exact Cost Reversing Mandatory" = FALSE, "Automatic Cost Posting" = TRUE, "Automatic Cost Adjustment" = Always.
        Initialize();
        InventorySetup.Get();
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, false);
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Item of Standard Cost = "C", purchase item, receive only, set "Direct Unit Cost" <> "C".
        // [GIVEN] Return item, ship only.
        // [GIVEN] Invoice purchase.
        // [WHEN] Undo Return Shipment.
        ItemNo := StandardItemPurchReturnShipmentVariance();

        // [THEN] Inserted adjusting Value Entries, where "Entry Type" is "Variance".
        VerifyValueEntryType(ItemNo, true, ValueEntry."Entry Type"::Variance);

        // Teardown.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(BaseExactCostReversingMand, BaseExactCostReversingMand);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoExactCostRevMandPurchReturnOrderInvStandardNoOnlineAdj()
    var
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        PrevExactCostReversingMand: Boolean;
    begin
        // [FEATURE] [Standard Cost] [Adjust Cost - Item Entries] [Undo Return Shipment]
        // [SCENARIO 375842] When undoing purchase return shipment for standard cost item, variance of original receipt is recognized.

        // [GIVEN] "Exact Cost Reversing Mandatory" = FALSE, "Automatic Cost Posting" = FALSE, "Automatic Cost Adjustment" = Never.
        Initialize();
        InventorySetup.Get();
        UpdatePurchasesPayablesSetup(PrevExactCostReversingMand, false);
        UpdateInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Never);

        // [GIVEN] Item of Standard Cost = "C", purchase item, receive only, set "Direct Unit Cost" <> "C".
        // [GIVEN] Return item (ship only), invoice purchase, undo Return Shipment.
        ItemNo := StandardItemPurchReturnShipmentVariance();

        // [WHEN] Run Adjust Cost - Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // [THEN] Inserted adjusting Value Entries, where "Entry Type" is "Variance".
        VerifyValueEntryType(ItemNo, true, ValueEntry."Entry Type"::Variance);

        // Teardown.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(PrevExactCostReversingMand, PrevExactCostReversingMand);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Purch Returns II");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Purch Returns II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Purch Returns II");
    end;

    local procedure StandardItemPurchReturnShipmentVariance(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Enum::"Costing Method"::Standard);

        Item.Get(PurchaseLine."No.");
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader2, PurchaseHeader2."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        UpdatePurchaseHeader(PurchaseHeader2);
        PurchaseHeader2.GetPstdDocLinesToReverse();
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);

        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        ReturnShipmentLine.FindFirst();
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        exit(PurchaseLine."No.");
    end;

    local procedure UpdatePurchasesPayablesSetup(var BaseExactCostReversingMand: Boolean; ExactCostReversingMand: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        BaseExactCostReversingMand := PurchasesPayablesSetup."Exact Cost Reversing Mandatory";
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMand);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure CreatePurchaseReturnSetup(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; CostingMethod: Enum "Costing Method")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CostingMethod);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        // Random Values used are notImportant for Test.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; CostingMethod: Enum "Costing Method")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, CostingMethod, 1, 0);
    end;

    local procedure CreatePurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; CostingMethod: Enum "Costing Method"; NoOfItems: Integer; NoOfCharges: Integer)
    var
        "Count": Integer;
    begin
        // Random Values used are notImportant for Test.
        for Count := 1 to NoOfItems do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(CostingMethod), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2) + 50);
            PurchaseLine.Modify(true);
        end;

        for Count := 1 to NoOfCharges do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(5, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure PurchaseHeaderCopyPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocType, DocNo, true, true);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.RunModal();
    end;

    local procedure PurchaseCopyDocument(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; DocumentType: Enum "Purchase Document Type"; FromDocType: Enum "Purchase Document Type From")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then begin
            PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
            PurchCrMemoHdr.FindFirst();
            DocumentNo := PurchCrMemoHdr."No.";
        end else begin
            PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
            PurchRcptHeader.FindFirst();
            DocumentNo := PurchRcptHeader."No.";
        end;

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        PurchaseHeaderCopyPurchaseDoc(PurchaseHeader, FromDocType, DocumentNo);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseLine);
        UpdatePurchaseHeader(PurchaseHeader);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // Random Values used are notImportant for Test.
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Validate(
          "Vendor Cr. Memo No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLineQty(var PurchaseLine: Record "Purchase Line"; SignFactor: Integer)
    begin
        // Update Purchase line qunatity and Unit Price with Sign Factor.
        PurchaseLine.Validate(Quantity, SignFactor * PurchaseLine.Quantity);
        PurchaseLine.Validate("Direct Unit Cost", SignFactor * PurchaseLine."Direct Unit Cost");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateApplyToItemEntryNo(var PurchaseLine: Record "Purchase Line"; SignFactor: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.FindFirst();

        PurchaseLine.Validate(Quantity, SignFactor * ItemLedgerEntry.Quantity);
        PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemChargeAssignmentLine(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch.Validate("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.Validate("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.Validate("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.Validate("Item Charge No.", PurchaseLine."No.");
        ItemChargeAssignmentPurch.Validate("Unit Cost", PurchaseLine."Direct Unit Cost");
        AssignItemChargeToReceipt(ItemChargeAssignmentPurch, PurchaseOrderNo, ItemNo);
        UpdateItemChargeQtyToAssign(PurchaseLine."Document Type", ItemChargeAssignmentPurch."Document No.", PurchaseLine.Quantity);
    end;

    local procedure AssignItemChargeToReceipt(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        ItemChargeAssgntPurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssignmentPurch);
    end;

    local procedure UpdateItemChargeQtyToAssign(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; QtyToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", DocumentType);
        ItemChargeAssignmentPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure MoveNegativeLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; ToDocType: Enum "Purchase Document Type From")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, true, true, true, false, false);
        PurchaseHeader2."Document Type" := CopyDocumentMgt.GetPurchaseDocumentType(ToDocType);
        CopyDocumentMgt.CopyPurchDoc(FromDocType, PurchaseHeader."No.", PurchaseHeader2);
    end;

    local procedure FindPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure TransferPurchaseLineToTemp(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindSet();
        repeat
            TempPurchaseLine := PurchaseLine;
            TempPurchaseLine.Insert();
        until PurchaseLine.Next() = 0;
    end;

    local procedure GetItemToBeInvUpdateQtyToRecv(var PurchaseLine: Record "Purchase Line") ItemNo: Code[20]
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        ItemNo := PurchaseLine."No.";
        PurchaseLine.Next();
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);
    end;

    local procedure CalcExpectedPurchaseDocAmount(var TempPurchaseLine: Record "Purchase Line" temporary) ExpectedPurchaseDocumnetAmount: Decimal
    begin
        TempPurchaseLine.FindSet();
        repeat
            ExpectedPurchaseDocumnetAmount +=
              TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost" + TempPurchaseLine."VAT %" * (TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost") / 100;
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchAmountChargeReturn(var TempPurchaseLine: Record "Purchase Line" temporary; var TempPurchaseLine2: Record "Purchase Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpectedPurchaseAmt: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", TempPurchaseLine."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Purchase Amount (Actual)");

        TempPurchaseLine2.SetRange(Type, TempPurchaseLine2.Type::"Charge (Item)");
        TempPurchaseLine2.FindFirst();

        case TempPurchaseLine2."Document Type" of
            TempPurchaseLine2."Document Type"::Invoice:
                ExpectedPurchaseAmt :=
                  TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost" +
                  TempPurchaseLine2.Quantity * TempPurchaseLine2."Direct Unit Cost";
            TempPurchaseLine2."Document Type"::"Return Order":
                ExpectedPurchaseAmt :=
                  TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost" -
                  TempPurchaseLine2.Quantity * TempPurchaseLine2."Direct Unit Cost";
        end;

        Assert.AreNearlyEqual(ExpectedPurchaseAmt, ItemLedgerEntry."Purchase Amount (Actual)", 0.1, PurchaseAmountMustBeSameErr);
    end;

    local procedure VerifyVendorLedgerEntry(var TempPurchaseLine: Record "Purchase Line" temporary; var TempPurchaseLine2: Record "Purchase Line" temporary)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ActualVendLedgerAmount: Decimal;
        ExpectedPurchaseInvoiceAmount: Decimal;
        ExpectedPurchaseCrMemoAmount: Decimal;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", TempPurchaseLine."Buy-from Vendor No.");
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields(Amount);
            ActualVendLedgerAmount += VendorLedgerEntry.Amount;
        until VendorLedgerEntry.Next() = 0;

        ExpectedPurchaseInvoiceAmount := CalcExpectedPurchaseDocAmount(TempPurchaseLine);

        TempPurchaseLine2.Reset();
        ExpectedPurchaseCrMemoAmount := CalcExpectedPurchaseDocAmount(TempPurchaseLine2);

        Assert.AreNearlyEqual(
          -ExpectedPurchaseInvoiceAmount + ExpectedPurchaseCrMemoAmount, ActualVendLedgerAmount, 0.1, PurchaseAmountMustBeSameErr);
    end;

    local procedure VerifyValueEntryType(ItemNo: Code[20]; IsAdjustment: Boolean; ExpectedEntryType: Enum "Cost Entry Type")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, IsAdjustment);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Entry Type", ExpectedEntryType);
        until ValueEntry.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesModalHandler(var PostedPurchaseDocumentLinesPage: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLinesPage.PostedReceiptsBtn.SetValue(0); // Posted Receipts
        PostedPurchaseDocumentLinesPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

