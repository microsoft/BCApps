codeunit 137601 "SCM CETAF Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Purchase");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Purchase");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Purchase");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOSKUPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::FIFO, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgSKUPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::Standard, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdSKUPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::Standard, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::LIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOSKUPurchaseWithCharge()
    var
        Item: Record Item;
    begin
        PurchaseWithCharge(Item."Costing Method"::LIFO, true);
    end;

    local procedure PurchaseWithCharge(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        Initialize();

        // Setup Item and SKU.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        LibraryPatterns.GRPH1Outbound1PurchRcvd(
          TempItemLedgerEntry, PurchaseLine, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // Extract the Purchase Receipt No. from the ILEs.
        TempItemLedgerEntry.SetRange(Positive, true);
        TempItemLedgerEntry.FindFirst();
        PurchRcptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        // Cost modification.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeader, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        LibraryPurchase.AssignPurchChargeToPurchaseLine(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchRcptLine."Order No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOPurchaseItemTrackingOverridesCostingMethod()
    var
        Item: Record Item;
    begin
        PurchaseLotTrackingOverridesCostingMethod(Item."Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOSKUPurchaseItemTrackingOverridesCostingMethod()
    var
        Item: Record Item;
    begin
        PurchaseLotTrackingOverridesCostingMethod(Item."Costing Method"::FIFO, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOPurchaseItemTrackingOverridesCostingMethod()
    var
        Item: Record Item;
    begin
        PurchaseLotTrackingOverridesCostingMethod(Item."Costing Method"::LIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOSKUPurchaseItemTrackingOverridesCostingMethod()
    var
        Item: Record Item;
    begin
        PurchaseLotTrackingOverridesCostingMethod(Item."Costing Method"::LIFO, true);
    end;

    local procedure PurchaseLotTrackingOverridesCostingMethod(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup Item Tracking Code, Item and SKU.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, ItemTrackingCode.Code);
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory flow.
        LibraryPatterns.GRPH3Purch1SalesItemTracked(
          SalesLine, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", false, false);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Average, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Average, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgSKUReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Average, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::FIFO, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::FIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOSKUReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::FIFO, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::LIFO, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::LIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOSKUReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::LIFO, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Standard, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchPartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Standard, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDSKUReversePurchInvoicePartRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchasePosting(Item."Costing Method"::Standard, true, true);
    end;

    local procedure ReversePurchasePosting(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean; InvoicePartialReceipt: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        PurchaseHeader1: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
    begin
        // Setup Item and SKU.
        Initialize();
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        LibraryPatterns.GRPHPurchPartialRcvd1PurchReturn(
          TempItemLedgerEntry, PurchaseLine, PurchaseLine1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code",
          InvoicePartialReceipt);
        PurchaseLine1.Validate(Quantity, PurchaseLine.Quantity);
        PurchaseLine1.Modify();

        // Extract the Purchase Receipt No. from the ILEs.
        TempItemLedgerEntry.SetRange(Positive, true);
        TempItemLedgerEntry.FindFirst();
        PurchRcptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        // Cost modification.
        // for Purchase.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeader, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        LibraryPurchase.AssignPurchChargeToPurchaseLine(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // for Purchase Return.
        PurchaseHeader1.Get(PurchaseLine1."Document Type", PurchaseLine1."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader1);
        LibraryPurchase.AssignPurchChargeToPurchReturnLine(
          PurchaseHeader1, PurchaseLine1, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));

        // Exercise.
        PurchaseHeader1.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchInvoicePartRcptWApplnNoReturnInv()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Average, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchPartRcptWApplnInvReturn()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Average, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchInvoicePartRcptWApplnNoInvoices()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Average, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchPartRcptWApplnInvoiceAll()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Average, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchInvoicePartRcptWApplnNoReturnInv()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::FIFO, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchPartRcptWApplnInvReturn()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::FIFO, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchInvoicePartRcptWApplnNoInvoices()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::FIFO, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchPartRcptWApplnInvoiceAll()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::FIFO, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchInvoicePartRcptWApplnNoReturnInv()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::LIFO, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchPartRcptWApplnInvReturn()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::LIFO, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchInvoicePartRcptWApplnNoInvoices()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::LIFO, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchPartRcptWApplnInvoiceAll()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::LIFO, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchInvoicePartRcptWApplnNoReturnInv()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Standard, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchPartRcptWApplnInvReturn()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Standard, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchInvoicePartRcptWApplnNoInvoices()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Standard, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDReversePurchPartRcptWApplnInvoiceAll()
    var
        Item: Record Item;
    begin
        ReversePurchasePostingWithApplication(Item."Costing Method"::Standard, false, true, true);
    end;

    local procedure ReversePurchasePostingWithApplication(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean; InvoicePurchase: Boolean; InvoicePurchReturn: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        PurchaseHeader1: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
    begin
        // Setup Item and SKU.
        Initialize();
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        LibraryPatterns.GRPHPurchPartialRcvd1PurchReturn(
          TempItemLedgerEntry, PurchaseLine, PurchaseLine1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", false);

        // Extract the Purchase Receipt No. from the ILEs.
        TempItemLedgerEntry.SetRange(Positive, true);
        TempItemLedgerEntry.FindLast();
        PurchRcptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        // Cost modification.
        // Apply charge to last Purchase Receipt.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeader, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchase);

        // Apply return to charged receipt.
        PurchaseLine1.Validate(Quantity, PurchRcptLine.Quantity);
        PurchaseLine1.Validate("Appl.-to Item Entry", TempItemLedgerEntry."Entry No.");
        PurchaseLine1.Modify();

        // Exercise.
        PurchaseHeader1.Get(PurchaseLine1."Document Type", PurchaseLine1."Document No.");
        PurchaseHeader1.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, InvoicePurchReturn);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReverseChargePurchRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchaseCharge(Item."Costing Method"::FIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReverseChargePurchRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchaseCharge(Item."Costing Method"::LIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReverseChargePurchRcpt()
    var
        Item: Record Item;
    begin
        ReversePurchaseCharge(Item."Costing Method"::Average, false, false);
    end;

    local procedure ReversePurchaseCharge(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean; InvoicePartialReceipt: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        PurchaseHeader1: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
    begin
        // Setup Item and SKU.
        Initialize();
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        LibraryPatterns.GRPHPurchPartialRcvd1PurchReturn(
          TempItemLedgerEntry, PurchaseLine, PurchaseLine1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code",
          InvoicePartialReceipt);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Extract the Purchase Receipt No. from the ILEs.
        TempItemLedgerEntry.SetRange(Positive, true);
        TempItemLedgerEntry.FindFirst();
        PurchRcptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        // Cost modification.
        // for Purchase Return.
        PurchaseHeader1.Get(PurchaseLine1."Document Type", PurchaseLine1."Document No.");
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeader1, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));

        // Exercise.
        PurchaseHeader1.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOReversePurchOnlyInvoice()
    var
        Item: Record Item;
    begin
        ReversePurchaseOnlyInvoice(Item."Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOReversePurchOnlyInvoice()
    var
        Item: Record Item;
    begin
        ReversePurchaseOnlyInvoice(Item."Costing Method"::LIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgReversePurchOnlyInvoice()
    var
        Item: Record Item;
    begin
        ReversePurchaseOnlyInvoice(Item."Costing Method"::Average, false);
    end;

    local procedure ReversePurchaseOnlyInvoice(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
    begin
        // Setup Item and SKU.
        Initialize();
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        LibraryPurchase.CreatePurchaseInvoice(
          PurchaseHeader, PurchaseLine, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code",
          LibraryRandom.RandInt(10), WorkDate(), LibraryRandom.RandDec(100, 5));
        LibraryPurchase.CreatePurchaseReturnOrder(
          PurchaseHeader1, PurchaseLine1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", PurchaseLine.Quantity,
          WorkDate() + 1, LibraryRandom.RandDec(100, 5));

        // Cost modification.
        // for Purchase.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.AssignPurchChargeToPurchaseLine(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // for Purchase Return.
        PurchaseHeader1.Get(PurchaseLine1."Document Type", PurchaseLine1."Document No.");
        LibraryPurchase.AssignPurchChargeToPurchReturnLine(
          PurchaseHeader1, PurchaseLine1, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));

        // Exercise.
        PurchaseHeader1.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::FIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::FIFO, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOSKUInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::FIFO, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOSKUPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::FIFO, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Average, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Average, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgSKUInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Average, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgSKUPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Average, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Average, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Standard, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdSKUInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Standard, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdSKUPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::Standard, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::LIFO, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::LIFO, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOSKUInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::LIFO, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOSKUPartiallyInvoiceChargeForPurchase()
    var
        Item: Record Item;
    begin
        InvoiceChargeForPurchase(Item."Costing Method"::LIFO, true, true);
    end;

    local procedure InvoiceChargeForPurchase(CostingMethod: Enum "Costing Method"; MakeSKU: Boolean; PartialPosting: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeaderInv: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Qty: Decimal;
        InvoiceQty: Decimal;
    begin
        // Setup Item and SKU.
        Initialize();
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        if MakeSKU then
            LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Inventory Flow.
        if PartialPosting then begin
            Qty := LibraryRandom.RandDec(100, 2);
            InvoiceQty := LibraryRandom.RandDecInRange(0, 1, 1) * Qty;
            LibraryPurchase.PostPurchaseOrderPartially(
              PurchaseHeader1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", Qty, WorkDate(),
              LibraryRandom.RandDec(100, 5), true, LibraryRandom.RandDecInDecimalRange(InvoiceQty, Qty, 2), true, InvoiceQty);

            Qty := LibraryRandom.RandDec(100, 2);
            InvoiceQty := LibraryRandom.RandDecInRange(0, 1, 1) * Qty;
            LibraryPurchase.PostPurchaseOrderPartially(
              PurchaseHeader2, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", Qty, WorkDate() + 1,
              LibraryRandom.RandDec(100, 5), true, LibraryRandom.RandDecInDecimalRange(InvoiceQty, Qty, 2), true, InvoiceQty);
        end else begin
            Qty := LibraryRandom.RandDec(100, 2);
            InvoiceQty := LibraryRandom.RandDecInRange(0, 1, 1) * Qty;
            LibraryPurchase.PostPurchaseOrderPartially(
              PurchaseHeader1, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", Qty, WorkDate(),
              LibraryRandom.RandDec(100, 5), true, Qty, true, InvoiceQty);

            Qty := LibraryRandom.RandDec(100, 2);
            InvoiceQty := LibraryRandom.RandDecInRange(0, 1, 1) * Qty;
            LibraryPurchase.PostPurchaseOrderPartially(
              PurchaseHeader2, Item, StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", Qty, WorkDate() + 1,
              LibraryRandom.RandDec(100, 5), true, Qty, true, InvoiceQty);
        end;

        // Cost modification.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInv, PurchaseHeaderInv."Document Type"::Invoice, '');
        PurchaseHeaderInv.Validate("Posting Date", WorkDate() + 3);
        PurchRcptLine.SetRange("Order No.", PurchaseHeader1."No.");
        PurchRcptLine.FindFirst();
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeaderInv, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));
        PurchRcptLine.SetRange("Order No.", PurchaseHeader2."No.");
        PurchRcptLine.FindFirst();
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchaseHeaderInv, PurchRcptLine, LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 5));

        // Exercise.
        PurchaseHeader1.Get(PurchaseHeader1."Document Type", PurchaseHeader1."No.");
        PurchaseHeader1.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
        PurchaseHeader2.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        PurchaseHeader2.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;
}

