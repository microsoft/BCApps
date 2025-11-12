codeunit 137301 "SCM Inventory Reports - I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        IncorrectValueInCellErr: Label 'Row count in report Inventory Validation before posting purchase order should be the same as after posting purchase order', Comment = '%1 - row % 2 - column';
        QuantityErr: Label 'Quantity Must Be %1 for %2  Document No. %3';
        NothingToPostTxt: Label 'There is nothing to post to the general ledger.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/Inventory Posting Setup, %2 %3 %4 %5 - posting groups.';

    [Test]
    [HandlerFunctions('InvtCostAndPriceListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtCostAndPriceListSKUFalse()
    var
        Item: Record Item;
    begin
        // Create Setup to Generate Inventory Cost and Price List Report with Use Stockkeeping as False.
        Initialize();
        InvtCostAndPriceListSetup(Item, false);

        // Verify: Standard Cost shown in Inventory Cost and Price List Report is equal to the Standard Cost in Item Table.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('StandardCost_Item', Item."Standard Cost");
    end;

    [Test]
    [HandlerFunctions('InvtCostAndPriceListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtCostAndPriceListSKUTrue()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Create Setup to Generate Inventory Cost and Price List Report with Use Stockkeeping as True.
        Initialize();
        InvtCostAndPriceListSetup(Item, true);

        // Verify: Stockkeeping  units are created and Standard Cost shown in Inventory Cost and Price List Report is equal to the
        // Standard Cost in Item Table.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('LocationCode_StockKeepingUnit', StockkeepingUnit."Location Code");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('StandardCost_StockKeepingUnit',
              StockkeepingUnit."Standard Cost");
            LibraryReportDataset.AssertCurrentRowValueEquals('StandardCost_Item', Item."Standard Cost");
        until StockkeepingUnit.Next() = 0;
    end;

    local procedure InvtCostAndPriceListSetup(var Item: Record Item; UseStockkeepingUnit: Boolean)
    begin
        // Setup :Create Item with costing method as standard and Create Stockkeeping Unit.
        CreateItem(Item);
        if UseStockkeepingUnit then
            CreateStockKeepingUnit(Item."No.", "SKU Creation Method"::Location);

        // Exercise: Generate the Inventory Cost and Price List.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Cost and Price List", true, false, Item);
    end;

    [Test]
    [HandlerFunctions('InvtListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryList()
    var
        Item: Record Item;
    begin
        // Setup: Create Item with costing method as standard.
        Initialize();
        CreateItem(Item);

        // Exercise: Generate Inventory List Report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory - List", true, false, Item);

        // Verify: No. shown in Inventory List Report is equal to the No. shown in Item Table.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_Item', Item."No.");
    end;

    [Test]
    [HandlerFunctions('InvtTransactionDetailRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryTransactionDetail()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup: Create Item with costing method as standard and update Inventory.
        Initialize();
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // Create and Post Sales Order using Random Value.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, '', Item."No.", Item.Inventory + LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Generate Inventory - Transaction Detail Report.
        Item.SetRange("No.", Item."No.");
        Item.FindFirst();
        REPORT.Run(REPORT::"Inventory - Transaction Detail", true, false, Item);

        // Verify: Document No. shown in Inventory - Transaction Detail Report is equal Document No. in Item Ledger Entry Table.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.SetRange('EntryNo_ItemLedgerEntry', ItemLedgerEntry."Entry No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_PItemLedgEntry', ItemLedgerEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('InvtTop10ListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtTop10ListLargestSalesLCY()
    var
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ShowSorting: Option Largest,Smallest;
        ShowType: Option "Sales (LCY)",Inventory;
    begin
        // Create Setup to Generate Inventory Cost Top 10 List with Show Sorting option as Largest and ShowType as Sales (LCY).
        Initialize();
        InventoryTop10ListSetup(ItemNo, ItemNo2, ShowSorting::Largest, ShowType::"Sales (LCY)");

        // Verify: Sales (LCY) shown in Inventory Top 10 List Report is equal to the Sales (LCY) in Item Table.
        VerifyTop10ListReport(ItemNo, ItemNo2);
    end;

    [Test]
    [HandlerFunctions('InvtTop10ListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtTop10ListSmallestSalesLCY()
    var
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ShowSorting: Option Largest,Smallest;
        ShowType: Option "Sales (LCY)",Inventory;
    begin
        // Create Setup to Generate Inventory Cost Top 10 List with Show Sorting option as Smallest and ShowType as Sales (LCY).
        Initialize();
        InventoryTop10ListSetup(ItemNo, ItemNo2, ShowSorting::Smallest, ShowType::"Sales (LCY)");

        // Verify: Sales (LCY) shown in Inventory Top 10 List Report is equal to the Sales (LCY) in Item Table.
        VerifyTop10ListReport(ItemNo, ItemNo2);
    end;

    [Test]
    [HandlerFunctions('InvtTop10ListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtTop10ListLargestInventory()
    var
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ShowSorting: Option Largest,Smallest;
        ShowType: Option "Sales (LCY)",Inventory;
    begin
        // Create Setup to Generate Inventory Cost Top 10 List with Show Sorting option as Largest and ShowType as Inventory.
        Initialize();
        InventoryTop10ListSetup(ItemNo, ItemNo2, ShowSorting::Largest, ShowType::Inventory);

        // Verify: Inventory shown in Inventory Top 10 List Report is equal to the Inventory in Item Table.
        VerifyTop10ListReport(ItemNo, ItemNo2);
    end;

    [Test]
    [HandlerFunctions('InvtTop10ListRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtTop10ListSmallestInventory()
    var
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ShowSorting: Option Largest,Smallest;
        ShowType: Option "Sales (LCY)",Inventory;
    begin
        // Create Setup to Generate Inventory Cost Top 10 List with Show Sorting option as Smallest and ShowType as Inventory.
        Initialize();
        InventoryTop10ListSetup(ItemNo, ItemNo2, ShowSorting::Smallest, ShowType::Inventory);

        // Verify: Inventory shown in Inventory Top 10 List Report is equal to the Inventory in Item Table.
        VerifyTop10ListReport(ItemNo, ItemNo2);
    end;

    local procedure InventoryTop10ListSetup(var ItemNo: Code[20]; var ItemNo2: Code[20]; ShowSorting: Option; ShowType: Option)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create two Items with costing method as standard. Update Inventory.
        CreateItem(Item);
        ItemNo := Item."No.";
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, LibraryRandom.RandDec(100, 2));
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        ItemNo2 := Item."No.";

        // Create and Post Sales Order.
        CreateSalesOrder(SalesHeader, '', Item."No.", LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Generate Inventory - Transaction Detail Report.
        Commit();
        LibraryVariableStorage.Enqueue(ShowSorting);
        LibraryVariableStorage.Enqueue(ShowType);
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        REPORT.Run(REPORT::"Inventory - Top 10 List", true, false, Item);
    end;

    [Test]
    [HandlerFunctions('InvtReordersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryReorderSKUFalse()
    begin
        // Create Setup to Generate Inventory Reorder with Use Stockkeeping as False.
        Initialize();
        InventoryReorder(false);
    end;

    [Test]
    [HandlerFunctions('InvtReordersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryReorderSKUTrue()
    begin
        // Create Setup to Generate Inventory Reorder with Use Stockkeeping as True. Value used is important for test.
        Initialize();
        InventoryReorder(true);
    end;

    local procedure InventoryReorder(UseStockKeepingUnit: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create a Item and Stockkeeping Unit. Update Inventory.
        CreateItem(Item);
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        if UseStockKeepingUnit then
            CreateStockKeepingUnit(Item."No.", "SKU Creation Method"::Location);
        CreateAndPostItemJrnl(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        Item.CalcFields(Inventory);

        // Create Sales Order.
        Location.FindFirst();
        CreateSalesOrder(SalesHeader, Location.Code, Item."No.", Item.Inventory + LibraryRandom.RandDec(100, 2));
        Item.CalcFields(Inventory, "Qty. on Sales Order");

        // Exercise: Generate the Inventory Reorder Report.
        Commit();
        LibraryVariableStorage.Enqueue(UseStockKeepingUnit);
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory - Reorders", true, false, Item);

        // Verify: Value of Available Inventory in Inventory Reorders Report is equal to the Available Inventory in
        // corresponding Item Table.
        LibraryReportDataset.LoadDataSetFile();

        if UseStockKeepingUnit then begin
            LibraryReportDataset.SetRange('ItemNo_SKU', Item."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('QtyAvailable_StockKeepingUnit', -Item."Qty. on Sales Order")
        end else begin
            LibraryReportDataset.SetRange('No_Item', Item."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('QtyAvailable', Item.Inventory - Item."Qty. on Sales Order");
        end;
    end;

    [Test]
    [HandlerFunctions('RevalPostingTestItemRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RevaluationPostingTest()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item with costing method as standard. Value important for Test.
        Initialize();
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100) + 10);
        Item.CalcFields(Inventory);

        // Create and Post Purchase order with One Item Line.
        // Run Adjust cost and create Revaluation Journal.Update Unit Cost (Revalued).
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Item.Inventory, LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        Item.SetRange("No.", Item."No.");
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Document No.", "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
        UpdateRevaluationJrnl(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Exercise: Generate Revaluation Posting - Test Report.
        Commit();
        ItemJournalLine.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Revaluation Posting - Test", true, false, ItemJournalLine);

        // Verify: Unit Cost (Revalued) shown in Revaluation Posting - Test Report is equal to the
        // Unit Cost (Revalued) shown in Item Journal Line Table.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Item_Journal_Line__Item_No__', ItemJournalLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Journal_Line__Unit_Cost__Revalued__',
          ItemJournalLine."Unit Cost (Revalued)");
    end;

    [Test]
    [HandlerFunctions('InvtInboundTransferRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryInboundTransfer()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
    begin
        // Setup: Create Item, Location and Transfer Order to New Location.
        Initialize();
        CreateItem(Item);

        // Create Transfer From Location.
        CreateLocation(Location, false);
        FromLocationCode := Location.Code;

        // Create Transfer To Location.
        CreateLocation(Location, false);
        ToLocationCode := Location.Code;

        // Create Intransit Location.
        CreateLocation(Location, true);
        InTransitLocationCode := Location.Code;
        CreateAndRealeaseTransferOrder(TransferLine, FromLocationCode, ToLocationCode, InTransitLocationCode, Item."No.");

        // Exercise: Run Inventory Inbound Transfer report.
        Commit();
        TransferLine.SetRange("Transfer-to Code", ToLocationCode);
        REPORT.Run(REPORT::"Inventory - Inbound Transfer", true, false, TransferLine);

        // Verify: Check Transfer Line Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('InTransitCode_TransLine', InTransitLocationCode);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstandQty_TransLine', TransferLine."Outstanding Quantity");
    end;

    [Test]
    [HandlerFunctions('InvtOrderDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryOrderDetails()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesQuantity: Decimal;
    begin
        // Setup: Create Item, and Sales Order.
        Initialize();
        CreateItem(Item);
        SalesQuantity := LibraryRandom.RandDec(100, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", SalesQuantity);
        SalesHeader.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        SalesHeader.Modify(true);

        // Exercise : Run Inventory Order Details report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Order Details", true, false, Item);

        // Verify : Check Sales Header Shipment with report Shipment Date.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SalesLineDocumentNo', SalesHeader."No.");
        // The element ShipmentDate_SalesLine is formatted in the report layout.
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ShipmentDate_SalesLine', Format(SalesHeader."Shipment Date"));
    end;

    [Test]
    [HandlerFunctions('InventoryOrderDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryOrderDetailsTotals()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Report "Inventory Order Details" should correctly represent Subtotals and Totals values
        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandInt(10));
        Item.Modify();

        // [GIVEN] Create customer "CUST"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Order for customer "CUST" with item "I" on "SL"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(20, 2));

        // [GIVEN] Item "I2" with "Type" = "Service"
        LibraryInventory.CreateItem(Item2);
        Item2.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item2.Validate("Unit Price", Item2."Unit Cost" + LibraryRandom.RandInt(10));
        Item2.Modify();

        // [GIVEN] Create a Sales Order for customer "CUST2" with item "I" on "SL2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", LibraryRandom.RandDec(20, 2));

        // [WHEN] Run report "Inventory Order Details"
        Commit();
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        RequestPageXML := Report.RunRequestPage(Report::"Inventory Order Details", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Inventory Order Details", Item, RequestPageXML);

        // [THEN] Subtotals and Totals elements exist and their values match those generated by the "Customer Statistics" page 
        // and the associated "Cust. Ledger Entry" records for "CUST" & "CUST2" Subtotals "CUST"
        // Subtotals for "SL"
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_OutstandingQty', SalesLine."Outstanding Quantity");
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_OutstandingAmt', SalesLine."Outstanding Amount");
        // Subtotals for "SL2"
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_OutstandingQty', SalesLine2."Outstanding Quantity");
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_OutstandingAmt', SalesLine2."Outstanding Amount");
        // Totals
        LibraryReportDataset.AssertElementWithValueExists('Totals_OutstandingAmt', (SalesLine."Outstanding Amount" + SalesLine2."Outstanding Amount"));
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('InvtPurchaseOrdersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPurchaseOrderDetails()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Item, and Purchase Order with one Item Line.
        Initialize();
        CreateItem(Item);
        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", PurchaseQuantity, LibraryRandom.RandDec(100, 2), 1);
        PurchaseHeader.Validate("Expected Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        PurchaseHeader.Modify(true);

        // Exercise : Run Inventory Purchase Orders report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Purchase Orders", true, false, Item);

        // Verify : Check Purchase Header Expected Receipt Date with Report Expected Receipt Date.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_PurchaseLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExpReceiptDt_PurchaseLine', Format(PurchaseHeader."Expected Receipt Date"));
    end;

    [Test]
    [HandlerFunctions('InvtPurchaseOrdersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPurchaseOrderDescription()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Item, and Purchase Order with one Item Line.
        Initialize();
        CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateRandomText(50));
        Item.Modify(true);

        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", PurchaseQuantity, LibraryRandom.RandDec(100, 2), 1);

        // Exercise : Run Inventory Purchase Orders report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Purchase Orders", true, false, Item);

        // Verify : Check Purchase Header Expected Receipt Date with Report Expected Receipt Date.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_PurchaseLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_Item', Item.Description);
    end;

    [Test]
    [HandlerFunctions('InvtSalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventorySalesStatistic()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuantity: Decimal;
    begin
        // Setup: Create Item, Create And Post Sales Order.
        Initialize();
        CreateItem(Item);
        SalesQuantity := LibraryRandom.RandDec(100, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", SalesQuantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise : Run Inventory - Sales Statistics report.
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory - Sales Statistics", true, false, Item);

        // Verify : Check Sales Quantity with Quantity in report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesQty', SalesQuantity);
    end;

    [Test]
    [HandlerFunctions('InvtCustomerSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryCustomerSales()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuantity: Decimal;
    begin
        // Setup: Create Item, Create And Post Sales Order.
        Initialize();
        CreateItem(Item);
        SalesQuantity := LibraryRandom.RandDec(100, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", SalesQuantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise : Run Inventory - Customer Sales report.
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory - Customer Sales", true, false, Item);

        // Verify : Check Sales Quantity with Quantity in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CustName', SalesHeader."Sell-to Customer Name");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvQty_ItemLedgEntry', SalesQuantity);
    end;

    [Test]
    [HandlerFunctions('InventoryCustomerSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryCustomerSalesTotals()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RequestPageXML: Text;
        TotalsProfitLCY: Decimal;
        TotalsSalesLCY: Decimal;
        TotalsProfitLCY2: Decimal;
        TotalsSalesLCY2: Decimal;
    begin
        // [SCENARIO] Report "Inventory Customer Sales" should correctly represent Subtotals and Totals values
        Initialize();

        // [GIVEN] Create Item "I1" and post one Sales Order
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Item "I2" and post one Sales Order
        Clear(SalesHeader);
        CreateItem(Item2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", LibraryRandom.RandDec(100, 2));
        SalesLine2.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine2.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Commit();

        // [GIVEN] Calculate the Total Profit and Total Sales Amount (Actual) from the Item Ledger Entries for Item "I1"
        ItemLedgerEntry.SetAutoCalcFields("Sales Amount (Actual)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        if ItemLedgerEntry.FindSet() then
            repeat
                TotalsProfitLCY += ItemLedgerEntry."Sales Amount (Actual)" + ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Non-Invtbl.)";
                TotalsSalesLCY += ItemLedgerEntry."Sales Amount (Actual)";
            until ItemLedgerEntry.Next() = 0;

        // [GIVEN] Calculate the Total Profit and Total Sales Amount (Actual) from the Item Ledger Entries for Item "I2"
        ItemLedgerEntry.SetRange("Item No.", Item2."No.");
        if ItemLedgerEntry.FindSet() then
            repeat
                TotalsProfitLCY2 += ItemLedgerEntry."Sales Amount (Actual)" + ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Non-Invtbl.)";
                TotalsSalesLCY2 += ItemLedgerEntry."Sales Amount (Actual)";
            until ItemLedgerEntry.Next() = 0;

        // [WHEN] Run report "Inventory Customer Sales"
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        RequestPageXML := Report.RunRequestPage(Report::"Inventory - Customer Sales", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Inventory - Customer Sales", Item, RequestPageXML);


        // [THEN] Subtotals and Totals elements exist and their values match those in the associated "Item Ledger Entry" records for "I1" & "I2"
        // Subtotals for I1
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_SalesAmtActual', TotalsSalesLCY);
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_Profit', TotalsProfitLCY);
        // Subtotals for I2
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_SalesAmtActual', TotalsSalesLCY2);
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_Profit', TotalsProfitLCY2);
        // Totals
        LibraryReportDataset.AssertElementWithValueExists('Totals_SalesAmtActual', (TotalsSalesLCY + TotalsSalesLCY2));
        LibraryReportDataset.AssertElementWithValueExists('Totals_Profit', (TotalsProfitLCY + TotalsProfitLCY2));
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('InvtVendorPurchasesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryVendorPurchases()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Item, Create And Post Purchase Order with one Item Line.
        Initialize();
        CreateItem(Item);
        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", PurchaseQuantity, LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Run Inventory - Vendor Purchases report.
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory - Vendor Purchases", true, false, Item);

        // Verify : Check Purchase Quantity with Quantity in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VendName', PurchaseHeader."Buy-from Vendor Name");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvQty_ValueEntry', PurchaseQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InvtSalesBackOrdersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventorySalesBackOrders()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        RequestPageXML: Text;
    begin
        // Setup: Create Item, Sales Order with Back Date.
        Initialize();
        CreateItem(Item);
        CreateSalesOrder(SalesHeader, '', Item."No.", LibraryRandom.RandDec(100, 2));
        SalesHeader.Validate("Shipment Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        SalesHeader.Modify(true);

        // Exercise : Run Inventory - Sales Back Orders report.
        Commit();
        Item.SetRange("No.", Item."No.");
        RequestPageXML := Report.RunRequestPage(Report::"Inventory - Sales Back Orders", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Inventory - Sales Back Orders", Item, RequestPageXML);

        // Verify : Check Sales Header Document No. with Document No. on Report.
        LibraryReportDataset.AssertElementWithValueExists('ShipmentDate_SalesLine', Format(SalesHeader."Shipment Date"));
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InvtSalesBackOrdersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventorySalesBackOrdersTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Item: Record Item;
        RequestPageXML: Text;
    begin
        // [SCENARIO] Report "Inventory - Sales Back Orders" should correctly represent Subtotals values
        Initialize();

        // [GIVEN] Create Item "I1" and one Sales Order with one Sales Line
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        // [GIVEN] Create one more Sales Line
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesHeader.Validate("Shipment Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        SalesHeader.Modify(true);

        // [WHEN] Run report "Inventory - Sales Back Orders"
        Commit();
        Item.SetRange("No.", Item."No.");
        RequestPageXML := Report.RunRequestPage(Report::"Inventory - Sales Back Orders", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Inventory - Sales Back Orders", Item, RequestPageXML);

        // [THEN] Subtotals elements exist and their values match those in the associated "Sales Line" records for "I1"
        // Subtotals for "I1"
        LibraryReportDataset.AssertElementWithValueExists('SubTotals_Outstanding_Qty', SalesLine."Outstanding Quantity" + SalesLine2."Outstanding Quantity");
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryStatus()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup : Create Item, Update Inventory And Find Item Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise : Run Status Report.
        Commit();
        Item.SetRange("No.", Item."No.");
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::Status, true, false, Item);

        // Verify : Check Item Ledger Entry Quantity with Quantity on report.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_ItemLedgerEntry', ItemLedgerEntry."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', ItemLedgerEntry.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventory()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        PurchaseQuantity: Decimal;
    begin
        // Setup : Create item , Location, Post Purchase Order ,Create Item Journal Batch and assign to Item Journal Line.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrder(Item."No.", Location.Code, PurchaseQuantity);

        // Exercise : Run Calculate Inventory report.
        ItemJournalLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
        Item.SetRange("No.", Item."No.");
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), true, false);

        // Verify : Check Purchase Quantity with Inventory Journal Line Physical Qty.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Location.Code);
        VerifyQuantity(
          PurchaseQuantity, ItemJournalLine."Qty. (Phys. Inventory)", ItemJournalLine."Document No.", ItemJournalLine.TableCaption());
        VerifyQuantity(PurchaseQuantity, ItemJournalLine."Qty. (Calculated)", ItemJournalLine."Document No.", ItemJournalLine.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRevaluationJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        Quantity: Decimal;
    begin
        // Setup: Create Item with costing method as standard, Random Value important.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100) + 10;
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        Item.CalcFields(Inventory);

        // Create and Post Purchase order with one Item line.
        // Run Adjust cost and create Revaluation Journal.Update Unit Cost (Revalued).
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Item.Inventory, LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);

        // Exercise: Generate Calculate Inventory Value Report.
        Item.SetRange("No.", Item."No.");
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Document No.", "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);

        // Verify : Verify that Revaluation Journal is created.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, '');

        // Verify quantity on Revaluation Journal is equal to Item quantity.
        VerifyQuantity(2 * Quantity, ItemJournalLine.Quantity, ItemJournalLine."Document No.", ItemJournalLine.TableCaption());
    end;

    [Test]
    [HandlerFunctions('ItemRegQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegisterQuantity()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemRegister: Record "Item Register";
        ItemLedgerEntry: Record "Item Ledger Entry";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        // Setup: Create Item with costing method as standard.Create Purchase order with Two Item Lines.
        Initialize();
        CreateItem(Item);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindItemRegister(ItemRegister, FromEntryNo, ToEntryNo, Item."No.");

        // Exercise: Generate Calculate Inventory Value Report.
        REPORT.Run(REPORT::"Item Register - Quantity", true, false, ItemRegister);

        // Verify : Check Item Ledger Entry Quantity with Quantity on report.Rounding in RTC is hard coded as 1.
        ItemLedgerEntry.Get(ItemRegister."From Entry No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_ItemLedgEntry', ItemLedgerEntry."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ItemLedgEntry', ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLPostTrue()
    begin
        // Run Post Inventory Cost to G/L with Post as True.
        Initialize();
        PostInventoryCostToGLPost(true);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLPostFalse()
    begin
        // Run Post Inventory Cost to G/L with Post as False.
        Initialize();
        PostInventoryCostToGLPost(false);
    end;

    [Normal]
    local procedure PostInventoryCostToGLPost(Post: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Setup: Create Item with costing method as standard.Create Purchase Order with two Item Lines and Post It.
        Initialize();
        CreateItem(Item);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchInvHeader(PurchInvHeader, PurchaseHeader."No.");

        // Exercise: Generate the Post Inventory Cost to G/L report.
        Commit();
        LibraryVariableStorage.Enqueue(PostMethod::"per Posting Group");
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        LibraryVariableStorage.Enqueue(Post);
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);

        // Verify: Document No shown in Inventory Cost to G/L Report is equal to the Document No shown of Purchase Invoice Header.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_PostValueEntryToGL', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemValueEntryDocumentNo', PurchInvHeader."No.");

        // Verify Inventory Account in Gl Entry.
        VerifyInvtAccountInGLEntry(Item."No.", PurchInvHeader."No.", Post);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationExpCostFalse()
    begin
        Initialize();
        InventoryValuationWithExpCost(false);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationExpCostTrue()
    begin
        Initialize();
        InventoryValuationWithExpCost(true);
    end;

    [Normal]
    local procedure InventoryValuationWithExpCost(IncludeExpectedCost: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Setup: Create Item with costing method as standard.Create Purchase Order with two Item Lines.
        CreateItem(Item);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchInvHeader(PurchInvHeader, PurchaseHeader."No.");

        // Exercise: Generate Inventory Valuation with include Expected Cost False.
        Commit();
        RunInvtValuationReport(Item, '', 0D, WorkDate(), IncludeExpectedCost);

        // Verify Value Entry Quantity.
        LibraryReportDataset.LoadDataSetFile();
        if IncludeExpectedCost then
            LibraryReportDataset.AssertElementWithValueExists('Expected_Cost_IncludedCaption', 'Expected Cost Included');

        VerifyValueEntryQuantity(Item."No.", PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValuationNoDuplicateExpCostLines()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        RowNo: Integer;
        ValueFound: Boolean;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 378286] Expected cost line should not be shown in the report "Inventory Valuation" when expected amount is 0.
        // [GIVEN] Create item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post purchase order as received and invoiced
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Inventory Valuation" with parameter "Include expected cost" = TRUE
        SaveAsExcelInventoryValuationReport(Item."No.");

        // [THEN] The string with description "Expected Cost Included" shouldn't be in this report for created item
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(
            LibraryReportValidation.FindColumnNoFromColumnCaption('Item No.'), Item."No.");
        Assert.AreNotEqual(
          'Expected Cost Included', LibraryReportValidation.GetValueAt(ValueFound, RowNo + 1,
            LibraryReportValidation.FindColumnNoFromColumnCaption('Description')), IncorrectValueInCellErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValuationDuplicateExpCostLines()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        RowNo: Integer;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 378286] Expected cost line should be shown in the report "Inventory Valuation" when expected amount is not 0.
        // [GIVEN] Create item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Posting the receipt in Purchase Order
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run report "Inventory Valuation" with parameter "Include expected cost" = TRUE
        SaveAsExcelInventoryValuationReport(Item."No.");

        // [THEN] The string with description "Expected Cost Included" should be in this report for created item
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(
            LibraryReportValidation.FindColumnNoFromColumnCaption('Item No.'), Item."No.");
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          RowNo + 1, LibraryReportValidation.FindColumnNoFromColumnCaption('Description'), 'Expected Cost Included', '1');
    end;

    [Test]
    [HandlerFunctions('CloseInvtPeriodTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseInventoryPeriodTest()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        InventoryPeriod: Record "Inventory Period";
    begin
        // Setup: Create Item with costing method as standard and update Inventory.
        Initialize();
        CreateInventoryPeriod(InventoryPeriod);
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // Create and Post Sales Order using Random Value.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, '', Item."No.", Item.Inventory + LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Generate Inventory - Transaction Detail Report.
        REPORT.Run(REPORT::"Close Inventory Period - Test", true, false, Item);

        // Verify : Verify Item No. With Generated Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_Item', Item.Description);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationWithLocationAndTransfer()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Item and Locations for Transfer.Create and post Purchase Order / Transfer Order with Location.
        CreateItem(Item);
        CreateLocation(FromLocation, false);
        CreateLocation(ToLocation, false);
        CreateLocation(IntransitLocation, true);
        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrder(Item."No.", FromLocation.Code, PurchaseQuantity);
        CreateAndPostTransferOrder(FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", PurchaseQuantity / 2);

        // Exercise: Generate Inventory Valuation.
        Commit();
        RunInvtValuationReport(Item, ToLocation.Code, CalcDate('<1D>', WorkDate()), CalcDate('<CM>', WorkDate()), false);

        // Verify: Verify Quantity of Opening Balance on Inventory Valuation Report.
        VerifyOpeningBalanceOnInvtValuationReport(PurchaseQuantity / 2);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure CheckFilterInfoOnPostInventoryCostToGLReport()
    var
        Item: Record Item;
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO 364399] Post Inventory Cost to G/L report should show Item filter information
        Initialize();

        // [GIVEN] Item with "No." = "X"
        CreateItem(Item);

        // [WHEN] Run Post Inventory Cost to G/L report with filters on "Item No." = "X"
        Commit();
        PostValueEntryToGL.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(PostMethod::"per Entry"); // Equeue for PostInvtCostToGLRequestPageHandler
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);

        // [THEN] Report contains info of applied filter "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryFilter', StrSubstNo('Item No.: %1', Item."No."));
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckFilterInfoOnPostInventoryCostToGLTestReport()
    var
        Item: Record Item;
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        SalesHeader: Record "Sales Header";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // [FEATURE] [Post Inventory Cost to G/L Test]
        // [SCENARIO 364399] Post Inventory Cost to G/L Test report should show Item filter information
        Initialize();

        // [GIVEN] Item with "No." = "X" with Inventory Transactions
        CreateItem(Item);
        CreateSalesOrder(SalesHeader, '', Item."No.", LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Post Inventory Cost to G/L Test report with filters on "Item No." = "X"
        Commit();
        PostValueEntryToGL.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(PostMethod::"per Entry"); // Equeue for PostInvtCostToGLRequestPageHandler
        LibraryVariableStorage.Enqueue('');
        REPORT.Run(REPORT::"Post Invt. Cost to G/L - Test", true, false, PostValueEntryToGL);

        // [THEN] Report contains info of applied filter "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryFilter', StrSubstNo('Item No.: %1', Item."No."));
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBlankSetupOnPostInventoryCostToGLTestReport()
    var
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        SalesHeader: Record "Sales Header";
        PostMethod: Option "per Posting Group","per Entry";
        BlankSetupErrText: Text;
    begin
        // [FEATURE] [Post Inventory Cost to G/L Test] [Blocked]
        // [SCENARIO 403129] Post Inventory Cost to G/L Test report should show Item filter information
        Initialize();

        // [GIVEN] Item with "No." = "X" with Inventory Transactions
        CreateItem(Item);
        CreateSalesOrder(SalesHeader, '', Item."No.", LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] GeneralPostingSetup, where Blocked is Yes
        GeneralPostingSetup.Get(SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.Blocked := true;
        GeneralPostingSetup.Modify();

        // [WHEN] Run Post Inventory Cost to G/L Test report with filters on "Item No." = "X"
        Commit();
        PostValueEntryToGL.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(PostMethod::"per Entry"); // Equeue for PostInvtCostToGLRequestPageHandler
        LibraryVariableStorage.Enqueue('');
        REPORT.Run(REPORT::"Post Invt. Cost to G/L - Test", true, false, PostValueEntryToGL);

        // [THEN] Report contains info of applied filter "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryFilter', StrSubstNo('Item No.: %1', Item."No."));
        // [THEN] Error in the report: "Setup is blocked in General Posting Setup..."
        BlankSetupErrText :=
            StrSubstNo(
                SetupBlockedErr,
                GeneralPostingSetup.TableCaption(),
                GeneralPostingSetup.FieldCaption("Gen. Bus. Posting Group"), GeneralPostingSetup."Gen. Bus. Posting Group",
                GeneralPostingSetup.FieldCaption("Gen. Prod. Posting Group"), GeneralPostingSetup."Gen. Prod. Posting Group");
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', BlankSetupErrText);
        // Tear down
        GeneralPostingSetup.Blocked := false;
        GeneralPostingSetup.Modify();
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckItemInfoOnInventoryValuationReport()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 371760] Item info should not be shown in Inventory Valuation report if there are no Item Ledger Entries posted
        Initialize();

        // [GIVEN] Item "X" has no related Item Ledger Entries
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run Inventory Valuation report
        Commit();
        RunInvtValuationReport(Item, '', 0D, WorkDate(), false);

        // [THEN] Report doesn't contain info for Item "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('ItemNo', Item."No.");
    end;

    [Test]
    [HandlerFunctions('InvtTransactionDetailRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryTransactionDetailClearQuantities()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 333122] Inventory - Transaction Detail report clears the unused IncreasesQty/DecreasesQty when switching to ILE of different sign
        Initialize();

        // [GIVEN] Item created
        // [GIVEN] Positive Adjustment for Item posted for Quantity = 5
        // [GIVEN] Negative Adjustment for Item posted for Quantity = 10
        CreateItem(Item);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Created and Posted Sales Order for the Item with Quantity = 14
        CreateSalesOrder(SalesHeader, '', Item."No.", LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Inventory - Transaction Detail Report for the Item
        Item.SetRange("No.", Item."No.");
        Item.FindFirst();
        REPORT.Run(REPORT::"Inventory - Transaction Detail", true, false, Item);

        // [THEN] Increases Qty = 0, Decreases Qty = 14 for the entry of type "Sale"
        LibraryReportDataset.LoadDataSetFile();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindFirst();
        VerifyInventoryTransactionDetailQuantities(ItemLedgerEntry, 0, Abs(ItemLedgerEntry.Quantity));

        // [THEN] Increases Qty = 5, Decreases Qty = 0 for the entry of type "Positive Adj."
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.FindFirst();
        VerifyInventoryTransactionDetailQuantities(ItemLedgerEntry, ItemLedgerEntry.Quantity, 0);

        // [THEN] Increases Qty = 0, Decreases Qty = 10 for the entry of type "Negative Adj."
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.FindFirst();
        VerifyInventoryTransactionDetailQuantities(ItemLedgerEntry, 0, Abs(ItemLedgerEntry.Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValuationFillZeroesInQtyAndExpectedCostIncluded()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnPurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        RowNo: Integer;
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 351691] Expected Cost Included line should show Quantity = 0 and Value = 0 for Inventory Posting Group Name = Increase (LCY)
        // [GIVEN] Created item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Posting the receipt and invoice for Purchase Order
        Quantity := LibraryRandom.RandDec(100, 2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Quantity, DirectUnitCost, 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posting the shipment for Return Purchase Order
        CreateReturnPurchaseOrder(ReturnPurchaseHeader, Item."No.", Quantity, DirectUnitCost);
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, true, false);

        // [WHEN] Run report "Inventory Valuation" with parameter "Include expected cost" = TRUE
        SaveAsExcelInventoryValuationReport(Item."No.");

        // [THEN] The Quantity should be equal to 0 for Inventory Posting Group Name = Increase (LCY) in Expected Cost Included line
        // [THEN] The Value should be equal to 0 for Inventory Posting Group Name = Increase (LCY) in Expected Cost Included line
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(
            LibraryReportValidation.FindColumnNoFromColumnCaption('Item No.'), Item."No.");

        LibraryReportValidation.VerifyCellValueOnWorksheet(
          RowNo + 1, LibraryReportValidation.FindColumnNoFromColumnCaption('Increases (LCY)'), '0', '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          RowNo + 1, LibraryReportValidation.FindColumnNoFromColumnCaption('Increases (LCY)') + 2, '0', '1');
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyIncreasesInInventoryValuationReport()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
    begin
        // [SCENARIO 457224] Transfer receipts are shown as negative decreases in Inventory Valuation report when using Location Filter

        // [GIVEN] Create Item, Location and Transfer Order to New Location.
        Initialize();
        CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(9, 10, 0));
        Item.Modify(true);

        // [GIVEN] Create Transfer From Location.
        CreateLocation(Location, false);
        FromLocationCode := Location.Code;

        // [GIVEN] Update inventory
        CreateAndPostItemJrnlWithLocation(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", FromLocationCode, LibraryRandom.RandDecInRange(9, 10, 0));

        // [GIVEN] Create Transfer To Location.
        CreateLocation(Location, false);
        ToLocationCode := Location.Code;

        // [GIVEN] Create Intransit Location.
        CreateLocation(Location, true);
        InTransitLocationCode := Location.Code;
        Item.CalcFields(Inventory);

        // [GIVEN] Post Transfer Order to new location
        CreateAndPostTransferOrderWithQty(FromLocationCode, ToLocationCode, InTransitLocationCode, Item."No.", Item.Inventory);

        // [WHEN] Run "Inventory Valuation" report
        Commit();
        RunInvtValuationReport(Item, ToLocationCode, WorkDate(), WorkDate(), false);

        // [THEN] Verify: Increase Expected Quantity on "Inventory Valuation" report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncreaseExpectedQty', Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLWithBatchRequestPageHandler,MessageHandler')]
    procedure CheckDocNoInPostInvCostToGLReportWhenTemplateAndBatchAreDifferFromGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        i: Integer;
    begin
        // [SCENARIO 560866] Verify the document number in 'Post Inventory Cost to G/L' when the report request page parameters for Template and Batch differ from the G/L setup.
        Initialize();

        // [GIVEN] Create two General Journal Batches with No. Series.
        for i := 1 to 2 do
            CreateGenJournalBatchWithNoSeries(GenJournalBatch[i]);

        // [GIVEN] Setup: General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Journal Templ. Name Mandatory", true);
        GeneralLedgerSetup.Validate("Apply Jnl. Template Name", GenJournalBatch[1]."Journal Template Name");
        GeneralLedgerSetup.Validate("Apply Jnl. Batch Name", GenJournalBatch[1].Name);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Enqueue the Journal Template Name and Batch Name.
        LibraryVariableStorage.Enqueue(GenJournalBatch[2]."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch[2].Name);

        // [WHEN] Exercise: Run Post Inventory Cost to G/L report.
        Commit();
        Report.RunModal(Report::"Post Inventory Cost to G/L");

        // [THEN] Verify the document number when different templates and batches are used.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('DocNo', GenJournalBatch[1]."No. Series");
        LibraryReportDataset.AssertElementWithValueExists('DocNo', GenJournalBatch[2]."No. Series");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports - I");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - I");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateInventorySetupCostPosting();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - I");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), Item."Reordering Policy",
          Item."Flushing Method", '', '');
    end;

    local procedure CreateStockKeepingUnit(ItemNo: Code[20]; SKUCreationMethod: Enum "SKU Creation Method")
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Item.SetRange("No.", ItemNo);
        LibraryInventory.CreateStockKeepingUnit(Item, SKUCreationMethod, false, true);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        if StockkeepingUnit.FindSet() then
            repeat
                StockkeepingUnit.Validate(
                  "Standard Cost",
                  LibraryRandom.RandDecInDecimalRange(StockkeepingUnit."Standard Cost", StockkeepingUnit."Standard Cost" + 100, 2));
                StockkeepingUnit.Modify(true);
            until StockkeepingUnit.Next() = 0;
    end;

    [Normal]
    local procedure CreateAndPostItemJrnl(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; NoOfItemLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        "Count": Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for Count := 1 to NoOfItemLines do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);

        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location; InTransit: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", InTransit);
        Location.Modify(true);
    end;

    local procedure CreateAndRealeaseTransferOrder(var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10]; ItemNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(100, 2));
        ReleaseTransferDocument.Run(TransferHeader);
    end;

    local procedure CreateAndPostTransferOrder(FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10]; ItemNo: Code[20]; TransferQty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, TransferQty);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; LocationCode: Code[10]; PurchaseQuantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, PurchaseQuantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateInventoryPeriod(var InventoryPeriod: Record "Inventory Period")
    begin
        InventoryPeriod.SetRange("Ending Date", WorkDate());
        if InventoryPeriod.FindFirst() then
            exit;

        InventoryPeriod.Init();
        InventoryPeriod.Validate("Ending Date", WorkDate());
        InventoryPeriod.Insert(true);
    end;

    local procedure CreateAndPostItemJrnlWithLocation(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity with Location
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostTransferOrderWithQty(FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10]; ItemNo: Code[20]; TransferQty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, TransferQty);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    [Normal]
    local procedure SelectInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
    end;

    local procedure FindItem(var Item: Record Item; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        Item.FindSet();
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindItemRegister(var ItemRegister: Record "Item Register"; var FromEntryNo: Integer; var ToEntryNo: Integer; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        FromEntryNo := ItemLedgerEntry."Entry No.";
        ItemLedgerEntry.FindLast();
        ToEntryNo := ItemLedgerEntry."Entry No.";
        ItemRegister.SetRange("From Entry No.", FromEntryNo);
        ItemRegister.SetRange("To Entry No.", ToEntryNo);
        ItemRegister.FindFirst();
    end;

    local procedure FindPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; OrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure SaveAsExcelInventoryValuationReport(ItemNo: Code[20])
    var
        Item: Record Item;
        InventoryValuation: Report "Inventory Valuation";
    begin
        Item.SetRange("No.", ItemNo);
        InventoryValuation.SetTableView(Item);
        InventoryValuation.InitializeRequest(0D, WorkDate(), true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        InventoryValuation.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenExcelFile();
    end;

    local procedure UpdateRevaluationJrnl(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        FindItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName, '');
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Modify(true);
    end;

    local procedure RunInvtValuationReport(Item: Record Item; LocationCode: Code[20]; StartDate: Date; EndingDate: Date; IncludeExpectedCost: Boolean)
    begin
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(IncludeExpectedCost);
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);
    end;

    local procedure VerifyTop10ListReport(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        FindItem(Item, ItemNo, ItemNo2);
        LibraryReportDataset.LoadDataSetFile();
        repeat
            Item.CalcFields(Inventory, "Sales (LCY)");
            LibraryReportDataset.SetRange('Item__No__', Item."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('Item_Inventory', Item.Inventory);
            LibraryReportDataset.AssertCurrentRowValueEquals('Item__Sales__LCY__', Item."Sales (LCY)");
        until Item.Next() = 0;
    end;

    [Normal]
    local procedure VerifyInvtAccountInGLEntry(ItemNo: Code[20]; DocumentNo: Code[20]; Post: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account");

        // Verify row existence for Inventory Account in G/L Entry.
        Assert.AreEqual(Post, GLEntry.FindFirst(), 'Unexpected GL entries for document ' + DocumentNo);
    end;

    [Normal]
    local procedure VerifyValueEntryQuantity(ItemNo: Code[20]; DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Item Ledger Entry Quantity");
        LibraryReportDataset.SetRange('ItemNo', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('IncreaseInvoicedQty', ValueEntry."Item Ledger Entry Quantity");
    end;

    [Normal]
    local procedure VerifyQuantity(ExpectedQuantity: Decimal; ActualQuantity: Decimal; DocumentNo: Code[20]; TableCaption2: Text[1024])
    begin
        Assert.AreEqual(ExpectedQuantity, ActualQuantity, StrSubstNo(QuantityErr, ActualQuantity, TableCaption2, DocumentNo));
    end;

    local procedure VerifyOpeningBalanceOnInvtValuationReport(ExpectedOpenningBalance: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingInvoicedQty', ExpectedOpenningBalance);
    end;

    local procedure VerifyInventoryTransactionDetailQuantities(ItemLedgerEntry: Record "Item Ledger Entry"; IncreasesQty: Decimal; DecreasesQty: Decimal)
    begin
        LibraryReportDataset.SetRange('No_Item', ItemLedgerEntry."Item No.");
        LibraryReportDataset.SetRange('EntryNo_ItemLedgerEntry', ItemLedgerEntry."Entry No.");
        LibraryReportDataset.SetRange('EntryType_ItemLedgEntry', Format(ItemLedgerEntry."Entry Type"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('IncreasesQty', IncreasesQty);
        LibraryReportDataset.AssertCurrentRowValueEquals('DecreasesQty', DecreasesQty);
    end;

    local procedure UpdateInventorySetupCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    local procedure CreateReturnPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateNoSeriesWithIncrementByNo(NoSeriesLine);
        GenJournalBatch.Validate("No. Series", NoSeriesLine."Series Code");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateNoSeriesWithIncrementByNo(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.FindFirst();
        NoSeriesLine.Validate("Starting Date", WorkDate());
        NoSeriesLine.Validate("Starting No.", NoSeries.Code);
        NoSeriesLine.Validate("Increment-by No.", 10);
        NoSeriesLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtCostAndPriceListRepRequestPageHandler(var InventoryCostAndPriceList: TestRequestPage "Inventory Cost and Price List")
    begin
        InventoryCostAndPriceList.UseStockkeepingUnit.SetValue(true); // Use Stockkeeping Units in the report.
        InventoryCostAndPriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtListRepRequestPageHandler(var InventoryList: TestRequestPage "Inventory - List")
    begin
        InventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtTransactionDetailRepRequestPageHandler(var InventoryTransactionDetail: TestRequestPage "Inventory - Transaction Detail")
    begin
        InventoryTransactionDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtTop10ListRepRequestPageHandler(var InventoryTopTenList: TestRequestPage "Inventory - Top 10 List")
    var
        ShowSorting: Variant;
        ShowType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowSorting);
        LibraryVariableStorage.Dequeue(ShowType);
        InventoryTopTenList.ShowSorting.SetValue(ShowSorting); // Show sorting: Largest, Smallest.
        InventoryTopTenList.ShowType.SetValue(ShowType); // Show Type: Sales, Inventory.
        InventoryTopTenList.NoOfRecordsToPrint.SetValue(0); // No. of records to print.
        InventoryTopTenList.PrintAlsoIfZero.SetValue(false); // Item not in inventory.
        InventoryTopTenList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtReordersRequestPageHandler(var InventoryReorders: TestRequestPage "Inventory - Reorders")
    var
        UseStockkeepingUnit: Variant;
    begin
        // Use stockkeeping units in the report.
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);
        InventoryReorders.UseStockkeepUnit.SetValue(UseStockkeepingUnit);
        InventoryReorders.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NonstockItemSalesRequestPageHandler(var NonstockItemSales: TestRequestPage "Catalog Item Sales")
    begin
        NonstockItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RevalPostingTestItemRequestPageHandler(var RevaluationPostingTest: TestRequestPage "Revaluation Posting - Test")
    var
        ShowDim: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowDim);
        RevaluationPostingTest.ShowDim.SetValue(ShowDim); // Show dimensions in report.
        RevaluationPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtInboundTransferRequestPageHandler(var InventoryInboundTransfer: TestRequestPage "Inventory - Inbound Transfer")
    begin
        InventoryInboundTransfer.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtOrderDetailsRequestPageHandler(var InventoryOrderDetails: TestRequestPage "Inventory Order Details")
    begin
        InventoryOrderDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryOrderDetailsRequestPageHandler(var InventoryOrderDetails: TestRequestPage "Inventory Order Details")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtPurchaseOrdersRequestPageHandler(var InventoryPurchaseOrder: TestRequestPage "Inventory Purchase Orders")
    begin
        InventoryPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtSalesStatisticsRequestPageHandler(var InventorySalesStatistics: TestRequestPage "Inventory - Sales Statistics")
    begin
        InventorySalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtCustomerSalesRequestPageHandler(var InventoryCustomerSales: TestRequestPage "Inventory - Customer Sales")
    begin
        InventoryCustomerSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryCustomerSalesRequestPageHandler(var InventoryCustomerSales: TestRequestPage "Inventory - Customer Sales")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtVendorPurchasesRequestPageHandler(var InventoryVendorPurchases: TestRequestPage "Inventory - Vendor Purchases")
    begin
        InventoryVendorPurchases.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtSalesBackOrdersRequestPageHandler(var InventorySalesBackOrders: TestRequestPage "Inventory - Sales Back Orders")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatusRequestPageHandler(var Status: TestRequestPage Status)
    var
        StatusDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatusDate);
        Status.StatusDate.SetValue(StatusDate);
        Status.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemRegQuantityRequestPageHandler(var ItemRegisterQuantity: TestRequestPage "Item Register - Quantity")
    begin
        ItemRegisterQuantity.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLRequestPageHandler(var PostInventoryCostToGL: TestRequestPage "Post Inventory Cost to G/L")
    var
        PostMethod: Variant;
        DocNo: Variant;
        Post: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostMethod);
        PostInventoryCostToGL.PostMethod.SetValue(PostMethod); // Post Method: per entry or per Posting Group.
        LibraryVariableStorage.Dequeue(DocNo);
        PostInventoryCostToGL.DocumentNo.SetValue(DocNo); // Doc No. required when posting per Posting Group.
        LibraryVariableStorage.Dequeue(Post); // Post to G/L.
        PostInventoryCostToGL.Post.SetValue(Post);
        PostInventoryCostToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLTestRequestPageHandler(var PostInventoryCostToGLTest: TestRequestPage "Post Invt. Cost to G/L - Test")
    var
        PostMethod: Variant;
        DocNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostMethod);
        PostInventoryCostToGLTest.PostingMethod.SetValue(PostMethod); // Post Method: per entry or per Posting Group.
        LibraryVariableStorage.Dequeue(DocNo);
        PostInventoryCostToGLTest.DocumentNo.SetValue(DocNo); // Doc No. required when posting per Posting Group.
        PostInventoryCostToGLTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    var
        StartDate: Variant;
        EndingDate: Variant;
        IncludeExpectedCost: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        InventoryValuation.StartingDate.SetValue(StartDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        InventoryValuation.EndingDate.SetValue(EndingDate);
        LibraryVariableStorage.Dequeue(IncludeExpectedCost);
        InventoryValuation.IncludeExpectedCost.SetValue(IncludeExpectedCost);
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseInvtPeriodTestRequestPageHandler(var CloseInventoryPeriodTest: TestRequestPage "Close Inventory Period - Test")
    begin
        CloseInventoryPeriodTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingPostedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToPostTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;

    [RequestPageHandler]
    procedure PostInvtCostToGLWithBatchRequestPageHandler(var PostInventoryCostToGL: TestRequestPage "Post Inventory Cost to G/L")
    var
        PostMethod: Option "per Posting Group","per Entry";
    begin
        PostInventoryCostToGL.PostMethod.SetValue(PostMethod::"per Posting Group"); // Post Method: per entry or per Posting Group.
        PostInventoryCostToGL.JnlTemplateName.SetValue(LibraryVariableStorage.DequeueText()); // Set New Template Name.
        PostInventoryCostToGL.JnlBatchName.SetValue(LibraryVariableStorage.DequeueText()); // Set New Batch Name.
        PostInventoryCostToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

