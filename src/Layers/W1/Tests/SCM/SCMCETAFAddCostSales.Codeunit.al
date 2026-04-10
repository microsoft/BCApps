codeunit 137609 "SCM CETAF Add. Cost Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Add. Cost Sales");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Add. Cost Sales");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Add. Cost Sales");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShpdNotInvdFIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::FIFO, 0, 0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShpdNotInvdLIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::LIFO, 0, 0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShpdNotInvdAvg()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Average, 0, 0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShpdNotInvdStd()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Standard, 0, 0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShpdInvdFIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::FIFO, 1, 2, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShpdInvdLIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::LIFO, 1, 2, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShpdInvdAVG()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Average, 1, 2, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShpdInvdSTD()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Standard, 1, 2, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShpdInvdFIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::FIFO, 0, 0, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShpdInvdLIFO()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::LIFO, 0, 0, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShpdInvdAVG()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Average, 0, 0, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShpdInvdSTD()
    var
        Item: Record Item;
    begin
        SetupShipAndInvoice(Item."Costing Method"::Standard, 0, 0, true, false);
    end;

    [Normal]
    local procedure SetupShipAndInvoice(CostingMethod: Enum "Costing Method"; ShipDelta: Decimal; InvoiceDelta: Decimal; Invoice: Boolean; SplitChargeLine: Boolean)
    var
        Customer: Record Customer;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemCharge: Record "Item Charge";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine1: Record "Sales Shipment Line";
        SalesShptLine2: Record "Sales Shipment Line";
        Item: Record Item;
        Day1: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();

        // Setup. Ship 2 orders.
        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(3, 100);
        QtyPer := LibraryRandom.RandIntInRange(3, 10);
        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryRandom.RandDec(100, 2));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 10));

        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 2 * Qty * QtyPer, Day1, LibraryRandom.RandDec(100, 2));

        LibrarySales.PostSalesOrderPartially(SalesHeader1, Item, '', '', Qty * QtyPer, Day1 + 1, 0, true,
          Qty * (QtyPer - ShipDelta), Invoice, Qty * (QtyPer - InvoiceDelta));
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        SalesShptLine1.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        LibrarySales.CreateSalesOrder(SalesHeader2, SalesLine, Item, '', '', Qty, Day1 + 2, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Qty. to Ship", Qty - ShipDelta);
        SalesLine.Validate("Qty. to Invoice", Qty - InvoiceDelta);
        SalesLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader2, true, Invoice);

        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        SalesShptLine2.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        // Assign charges to the 2 shipment lines.
        Customer.Get(SalesHeader1."Sell-to Customer No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", Day1 + 4);
        SalesHeader.Modify(true);

        if SplitChargeLine then begin
            LibrarySales.CreateItemChargeSalesLine(SalesLine, ItemCharge, SalesHeader, 2 * Qty, LibraryRandom.RandDec(100, 2));
            LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
              ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
              SalesShptLine1."Document No.", SalesShptLine1."Line No.",
              SalesShptLine1."No.", Qty, LibraryRandom.RandDec(100, 2));
            ItemChargeAssignmentSales.Insert();

            LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
              ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
              SalesShptLine2."Document No.", SalesShptLine2."Line No.",
              SalesShptLine2."No.", Qty, LibraryRandom.RandDec(100, 2));
            ItemChargeAssignmentSales.Insert();
        end else begin
            LibrarySales.AssignSalesChargeToSalesShptLine(SalesHeader, SalesShptLine1, Qty, LibraryRandom.RandDec(100, 2));
            LibrarySales.AssignSalesChargeToSalesShptLine(SalesHeader, SalesShptLine2, Qty, LibraryRandom.RandDec(100, 2));
        end;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByValuePart1FIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::FIFO, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByValuePart1LIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::LIFO, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByValuePart1AVG()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::Average, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByValuePart1STD()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::Standard, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByQtyPart1FIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::FIFO, PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByQtyPart1LIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::LIFO, PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByQtyPart1AVG()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::Average, PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostByQtyPart1STD()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocsPart1(Item."Costing Method"::Standard, PurchaseHeader."Document Type"::Order);
    end;

    [Normal]
    local procedure PostDocsPart1(CostingMethod: Enum "Costing Method"; PurchDocType: Enum "Purchase Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Item: Record Item;
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        SetAverageCostCalcTypeItem();

        // Setup: purchase invoice/order with and without variant.
        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(3, 100);
        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryRandom.RandDec(100, 2));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(InTransitLocation);
        InTransitLocation."Use As In-Transit" := true;
        InTransitLocation.Modify();
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchDocType, Item,
          StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", 2 * Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchDocType, Item,
          StockkeepingUnit."Location Code", '', 2 * Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Transfer with and without variant.
        FromLocation.Get(StockkeepingUnit."Location Code");
        LibraryInventory.CreateAndPostTransferOrder(TransferHeader, Item, FromLocation,
          ToLocation, InTransitLocation, StockkeepingUnit."Variant Code", Qty, Day1 + 4, Day1 + 4, true, true);
        LibraryInventory.CreateAndPostTransferOrder(TransferHeader, Item, FromLocation,
          ToLocation, InTransitLocation, '', Qty, Day1 + 4, Day1 + 4, true, true);

        // Sell with and without variant.
        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, FromLocation.Code, StockkeepingUnit."Variant Code", Qty, Day1 + 5,
          LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, FromLocation.Code, '', Qty, Day1 + 5,
          LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByValuePart2FIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::FIFO, PurchaseHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByValuePart2LIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::LIFO, PurchaseHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByValuePart2AVG()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::Average, PurchaseHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByValuePart2STD()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::Standard, PurchaseHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByQtyPart2FIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::FIFO, PurchaseHeader."Document Type"::Order,
          SalesHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::"Return Order", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByQtyPart2LIFO()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::LIFO, PurchaseHeader."Document Type"::Order,
          SalesHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::"Return Order", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByQtyPart2AVG()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::Average, PurchaseHeader."Document Type"::Order,
          SalesHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::"Return Order", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostByQtyPart2STD()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        PostDocsPart2(Item."Costing Method"::Standard, PurchaseHeader."Document Type"::Order,
          SalesHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::"Return Order", false);
    end;

    [Normal]
    local procedure PostDocsPart2(CostingMethod: Enum "Costing Method"; PurchDocType: Enum "Purchase Document Type"; SalesDocType: Enum "Sales Document Type"; PurchReturnDocType: Enum "Purchase Document Type"; Invoice: Boolean)
    var
        Vendor: Record Vendor;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemCharge: Record "Item Charge";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        SalesHeader: Record "Sales Header";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Item: Record Item;
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        SetAverageCostCalcTypeItem();

        if Confirm('') then; // workaround for ES.

        // Setup: purchase invoice with and without variant.
        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(3, 100);
        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryRandom.RandDec(100, 2));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(InTransitLocation);
        InTransitLocation."Use As In-Transit" := true;
        InTransitLocation.Modify();
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader1, PurchaseLine, PurchDocType, Item, StockkeepingUnit."Location Code",
          StockkeepingUnit."Variant Code", 2 * Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, Invoice);
        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader2, PurchaseLine, PurchDocType, Item, StockkeepingUnit."Location Code",
          '', 2 * Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, Invoice);

        // Assign charge to purchase and invoice if necessary.
        Vendor.Get(PurchaseHeader1."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", Day1);
        PurchaseHeader.Modify(true);

        case PurchDocType of
            PurchaseHeader."Document Type"::Invoice:
                begin
                    PurchInvLine.SetRange(Type, PurchaseLine.Type);
                    PurchInvLine.SetRange("No.", Item."No.");
                    PurchInvLine.FindFirst();

                    LibraryPurchase.AssignPurchChargeToPurchInvoiceLine(PurchaseHeader, PurchInvLine, Qty,
                      LibraryRandom.RandDec(100, 2));
                end;
            PurchaseHeader."Document Type"::Order:
                begin
                    PurchRcptLine.SetRange("Order No.", PurchaseHeader1."No.");
                    PurchRcptLine.FindFirst();

                    LibraryPurchase.AssignPurchChargeToPurchRcptLine(PurchaseHeader, PurchRcptLine, Qty,
                      LibraryRandom.RandDec(100, 2));
                    LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
                    LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
                end;
        end;

        LibraryPurchase.CreateItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, Qty,
          LibraryRandom.RandDec(100, 2));
        PurchaseLine."Qty. to Invoice" := 0;
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Sales credit memo with and without variant.
        LibrarySales.CreateSalesDocument(SalesHeader1, SalesLine, SalesDocType, Item, StockkeepingUnit."Location Code",
          StockkeepingUnit."Variant Code", Qty, Day1 + 5, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader1, true, Invoice);
        LibrarySales.CreateSalesDocument(SalesHeader2, SalesLine, SalesDocType, Item, StockkeepingUnit."Location Code",
          '', Qty, Day1 + 5, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader2, true, Invoice);

        // Revalue inventory.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, Item, Day1 + 2,
          "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Inventory Value (Revalued)",
          ItemJournalLine."Inventory Value (Calculated)" + LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Sales invoice with and without variant.
        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, StockkeepingUnit."Location Code",
          StockkeepingUnit."Variant Code", Qty, Day1 + 10, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, StockkeepingUnit."Location Code",
          '', Qty, Day1 + 10, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Purchase credit memo with and without variant.
        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader1, PurchaseLine, PurchReturnDocType, Item,
          StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code", Qty, Day1 + 11,
          LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, Invoice);

        LibraryPurchase.CreatePurchaseDocument(PurchaseHeader2, PurchaseLine, PurchReturnDocType, Item,
          StockkeepingUnit."Location Code", '', Qty, Day1 + 11, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, Invoice);

        if not Invoice then begin
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
            SalesHeader1.Get(SalesHeader1."Document Type", SalesHeader1."No.");
            LibrarySales.PostSalesDocument(SalesHeader1, true, true);
            SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
            LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        end;

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    local procedure SetAverageCostCalcTypeItem()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryInventory.UpdateAverageCostSettings(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period");
        LibraryInventory.SetAverageCostSetupInAccPeriods(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

