codeunit 137302 "SCM Inventory Reports - II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        FullShipmentValueTxt: Label 'Full Shipment';
        NoShipmentValueTxt: Label 'No Shipment';
        PartialShipmentValueTxt: Label 'Partial Shipment';
        DirectUnitCostErr: Label 'Direct Unit Cost must match.';
        MsgQtytoShipErr: Label 'Qty. to Ship  must match.';
        MsgQtytoReceiveErr: Label 'Qty. to Receive  must match.';
        StatusConstantCap: Label 'Finished';
        ReportQtyErr: Label 'Wrong Quantity on Report';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListCustomer()
    begin
        // Test Price List Report - Sales Type: Customer.
        Initialize();
        CustomerPriceListReport('');
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListCustomerCurr()
    var
        CurrencyCode: Code[10];
    begin
        // Test Price List Report - Sales Type: Customer, and Random Currency.
        Initialize();
        CurrencyCode := SelectCurrencyCode();
        CustomerPriceListReport(CurrencyCode);
    end;

    local procedure CustomerPriceListReport(CurrencyCode: Code[10])
    var
        Item: Record Item;
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        CustNo: Code[20];
    begin
        // 1. Setup: Create Item with random unit price.
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(10, 2));

        // 2. Exercise: Generate the Price List.
        CustNo := LibrarySales.CreateCustomerNo();
        Commit();
        RunPriceListReport(Item."No.", SalesType::Customer, CustNo, CurrencyCode);

        // 3. Verify: Check the value of Item Unit Price in Price List.
        VerifyUnitPrice(Item, CurrencyCode, Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListCustPriceGroup()
    begin
        // Test Price List Report - Sales Type: Customer Price Group.
        Initialize();
        CustPriceGroupPriceListReport('');
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListCustPriceGroupCurr()
    var
        CurrencyCode: Code[10];
    begin
        // Test Price List Report - Sales Type: Customer Price Group, and Random Currency.
        Initialize();
        CurrencyCode := SelectCurrencyCode();
        CustPriceGroupPriceListReport(CurrencyCode);
    end;

    local procedure CustPriceGroupPriceListReport(CurrencyCode: Code[10])
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
    begin
        // 1. Setup: Create Item with random unit price and Customer Price Group.
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomerWithPriceGroup(CustomerPriceGroup.Code);

        // 2. Exercise: Generate the Price List.
        Commit();
        RunPriceListReport(Item."No.", SalesType::"Customer Price Group", CustomerPriceGroup.Code, CurrencyCode);

        // 3. Verify: Check the value of Item Unit Price in Price List.
        VerifyUnitPrice(Item, CurrencyCode, Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListAllCustomer()
    begin
        // Test Price List Report - Sales Type: All Customer.
        Initialize();
        AllCustomerPriceListReport('');
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListAllCustomerCurr()
    var
        CurrencyCode: Code[10];
    begin
        // Test Price List Report - Sales Type: All Customer, and Random Currency.
        Initialize();
        CurrencyCode := SelectCurrencyCode();
        AllCustomerPriceListReport(CurrencyCode);
    end;

    local procedure AllCustomerPriceListReport(CurrencyCode: Code[10])
    var
        Item: Record Item;
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
    begin
        // 1. Setup: Create Item with random unit price.
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(10, 2));

        // 2. Exercise: Generate the Price List.
        Commit();
        RunPriceListReport(Item."No.", SalesType::"All Customers", '', CurrencyCode);

        // 3. Verify: Check the value of Item Unit Price in Price List.
        VerifyUnitPrice(Item, CurrencyCode, Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportCampaignNative()
    begin
        // Test Price List Report - Sales Type: Campaign.
        Initialize();
        CampaignPriceListReport('');
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportCampaignCurrNative()
    var
        CurrencyCode: Code[10];
    begin
        // Test Price List Report - Sales Type: Campaign, and Random Currency.
        Initialize();
        CurrencyCode := SelectCurrencyCode();
        CampaignPriceListReport(CurrencyCode);
    end;

    local procedure CampaignPriceListReport(CurrencyCode: Code[10])
    var
        Item: Record Item;
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
    begin
        PriceListLine.DeleteAll();
        // 1. Setup: Create Item, Campaign and Sales Price.
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        LibraryMarketing.CreateCampaign(Campaign);
        CreateSalesPriceForCampaign(SalesPrice, Item."No.", Campaign."No.");
        //PriceListLine.CopyFrom(SalesPrice);

        // 2. Exercise: Generate the Price List.
        Commit();
        RunPriceListReport(Item."No.", SalesType::Campaign, Campaign."No.", CurrencyCode);

        // 3. Verify: Check the value of Unit Price from Sales Price.
        SalesPrice.SetRange("Item No.", Item."No.");
        SalesPrice.FindFirst();
        VerifyUnitPrice(Item, CurrencyCode, SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('InventoryPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPostingReport()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // 1. Setup: Create Item and Item Journal Line.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, Item."No.");

        // 2. Exercise: Generate the Inventory Posting - Test report.
        Commit();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        REPORT.Run(REPORT::"Inventory Posting - Test", true, false, ItemJournalLine);

        // 3. Verify: Check the values of Quantity, Unit Cost and Cost Amount in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Item_Journal_Line__Item_No__', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Journal_Line_Quantity', ItemJournalLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Journal_Line__Unit_Cost_', ItemJournalLine."Unit Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmount', ItemJournalLine.Quantity * ItemJournalLine."Unit Cost");

        // 4. Tear Down.
        ItemJournalBatch.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReport()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // 1. Setup: Create Item and post Item Journal Line for Item purchase.
        Initialize();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, Item."No.");
        ItemJournalLine.Validate("Document No.", Item."No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 2. Exercise: Generate the Status report.
        RunStatusReport(Item."No.");

        // 3. Verify: Check the value of Quantity in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        Item.CalcFields(Inventory);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', Item.Inventory);

        // 4. Tear Down.
        ItemJournalBatch.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('InvtValCostSpecWithFiltersPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecReportWithLimitsTotalsFilter()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 360763] Report Inventory Valuation - Cost Spec. Quantity is equal to ItemLedgerEntry's Quantity that correspondes with "Limits Totals to" filters
        Initialize();

        // [GIVEN] Create Item
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        // [GIVEN] Item Ledger Entry for Item 'I', where Quantity='Q1', 'Location' ='L1','Varian'= 'V1', 'Global Dim' = 'D1'
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.");
        // [GIVEN] Item Ledger Entry for Item 'I', where Quantity='Q2' , 'Location' ='L2','Varian'= 'V2', 'Global Dim' = 'D2'
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.");
        Commit();

        // [WHEN]  Run 'Inventory Valuation - Cost Spec.' report with filters: 'L2', 'V2', 'D2'
        SetLimitsTotalsFilterOnItem(Item, ItemLedgerEntry);
        REPORT.Run(REPORT::"Invt. Valuation - Cost Spec.", true, false, Item);

        // [THEN] Report shows 'Quantity' = 'Q2'
        VerifyLibraryReportDatasetQuantity(ItemLedgerEntry.Quantity, Item."No.");
    end;

    [Test]
    [HandlerFunctions('InvtValCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecReport()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // 1. Setup: Create Item and post Item Journal Line for Item purchase.
        Initialize();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo(Description), Item."No.");
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, Item."No.");
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 2. Exercise: Generate the Inventory Valuation - Cost Spec. report.
        RunInvtValuationCostSpecReport(Item."No.");

        // 3. Verify: Check the value of Quantity in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        Quantity := LibraryReportDataset.Sum('RemainingQty');
        ItemJournalLine.TestField(Quantity, Quantity);

        // 4. Tear Down.
        ItemJournalBatch.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('PostProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
    begin
        // 1. Setup: Create Production Order Setup.
        Initialize();

        // Create Production BOM.
        // Create Parent Item and attach Routing and Production BOM.
        CreateParentItemWithRoutingAndProductionBOM(Item);

        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        OpenProductionJournal(ProductionOrder);

        // 2. Exercise: Generate the Inventory Valuation WIP report.
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);

        // 3. Verify: Check the value of Source No. and Consumption.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SourceNo_ProductionOrder', ProductionOrder."Source No.");

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Source No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            CostAmountActual += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;

        LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfMatConsump', -CostAmountActual)
    end;

    [Test]
    [HandlerFunctions('PurchResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReserveAvail()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        PurchaseReserveAvailReport(PurchaseHeader, Item."No.", false);  // PurchaseReserveAvailReport contains Exercise.

        // Verify: Check Expected Receipt Date value in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentStatus', FullShipmentValueTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExpctRecptDate_PurchLine', Format(PurchaseHeader."Expected Receipt Date"));
    end;

    [Test]
    [HandlerFunctions('PurchResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReserveAvailWithLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        PurchaseReserveAvailReport(PurchaseHeader, Item."No.", true);  // PurchaseReserveAvailReport contains Exercise.

        // Verify: Check Outstanding Quantity (Base) in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_PurchaseLine', Item."No.");
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstQtyBase_PurchLine', PurchaseLine."Outstanding Qty. (Base)")
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReserveAvail()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        SalesReserveAvailReport(SalesHeader, Item."No.", false);  // SalesReserveAvailReport contains Exercise.

        // Verify: Check the Shipment Date in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentStatus', NoShipmentValueTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ShipmentDt_SalesHeader', Format(SalesHeader."Shipment Date"));
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReserveAvailWithLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        SalesReserveAvailReport(SalesHeader, Item."No.", true);  // SalesReserveAvailReport contains Exercise.

        // Verify: Check the Outstanding Quantity (Base) in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesLine', Item."No.");
        SelectSalesLine(SalesLine, SalesHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstdngQtyBase_SalesLine', SalesLine."Outstanding Qty. (Base)")
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReserveAvailWithReserve()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Reservation - Always, Purchase Order and Sales Order. Auto-reserve Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo(Reserve), Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateSalesOrder(SalesHeader, Item."No.", Quantity);
        SelectSalesLine(SalesLine, SalesHeader."No.");
        LibrarySales.AutoReserveSalesLine(SalesLine);
        Clear(SalesLine);

        // Exercise: Generate the Sales Reservation Avail. report with Show Reservation Entries.
        Commit();
        RunSalesReservationAvail(SalesHeader."No.", true, true);

        // Verify: Check the Reserved Quantity in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesLine', Item."No.");
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ReservationEntry', -SalesLine."Reserved Qty. (Base)");
        LibraryReportDataset.AssertCurrentRowValueEquals('ResrvdQtyBase_SalesLine', SalesLine."Reserved Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesReport()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Production Item Setup.
        Initialize();
        CreateProdItemSetup(Item);

        // Exercise: Generate the Rolled up Cost Shares report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Rolled-up Cost Shares", true, false, Item);

        // Verify: Check Item details.
        LibraryReportDataset.LoadDataSetFile();

        // Verify Child Items exist in the report.
        SelectProductionBOMLines(ProductionBOMLine, Item."Production BOM No.");
        repeat
            LibraryReportDataset.SetRange('ProdBOMLineIndexNo', ProductionBOMLine."No.");
            Item.Get(ProductionBOMLine."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('ProdBOMLineIndexDesc', Item.Description);
        until ProductionBOMLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('SglLevelCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SingleLevelCostSharesReport()
    var
        Item: Record Item;
    begin
        // Setup: Create Item.
        Initialize();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");

        // Exercise: Generate the Single Level Cost Shares report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Single-level Cost Shares", true, false, Item);

        // Verify: Check Item details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitCost_Item', Item."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationReport()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Production Item Setup.
        Initialize();
        CreateProdItemSetup(Item);

        // Exercise: Generate the Detailed Calculation report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        // Verify: Check Item details.
        LibraryReportDataset.LoadDataSetFile();

        // Verify Child Items exist in the report.
        SelectProductionBOMLines(ProductionBOMLine, Item."Production BOM No.");
        repeat
            LibraryReportDataset.SetRange('ProdBOMLineLevelNo', ProductionBOMLine."No.");
            LibraryReportDataset.GetNextRow();
            Item.Get(ProductionBOMLine."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('ProdBOMLineLevelDesc', Item.Description);
        until ProductionBOMLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('WhereUsedTopLevelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedTopLevelReport()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Production Item Setup and select a child item.
        Initialize();
        CreateProdItemSetup(Item);
        SelectProductionBOMLines(ProductionBOMLine, Item."Production BOM No.");

        // Exercise: Generate the Where Used (Top Level) report.
        Commit();
        Item.SetRange("No.", ProductionBOMLine."No.");
        REPORT.Run(REPORT::"Where-Used (Top Level)", true, false, Item);

        // Verify: Check Item details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ProductionBOMLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('WhereUsedListItemNo', Item."No.");
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityReport()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GrossReq: Decimal;
        ScheduledReceipt: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        ScheduledReceipt := LibraryRandom.RandDecInRange(10, 100, 2);
        GrossReq := LibraryRandom.RandDecInDecimalRange(1, ScheduledReceipt, 2);
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreatePurchaseOrder(PurchaseHeader, Item."No.", ScheduledReceipt);
        CreateSalesOrder(SalesHeader, Item."No.", GrossReq);

        // Exercise: Generate the Inventory Availability report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Availability", true, false, Item);

        // Verify: Check Item details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ScheduledReceipt', ScheduledReceipt);
        LibraryReportDataset.AssertCurrentRowValueEquals('GrossRequirement', GrossReq);
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvailBalance', ScheduledReceipt - GrossReq);
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportForPurchaseOrderWithSameUOM()
    begin
        // Setup.
        Initialize();
        StatusReportForPurchaseOrder(false);  // Change Unit of Measure as False.
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportForPurchaseOrderWithDiffUOM()
    begin
        // Setup.
        Initialize();
        StatusReportForPurchaseOrder(true);  // Change Unit of Measure as True.
    end;

    local procedure StatusReportForPurchaseOrder(ChangeUnitOfMeasure: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Item, Create Purchase Order, Change Unit of Measure on Purchase Line and Post Purchase Order with Receive Option.
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndPostPurchaseOrderWithUOM(PurchaseHeader, Item, ChangeUnitOfMeasure);

        // Exercise: Generate the Status report.
        RunStatusReport(Item."No.");

        // Verify: Verify Item No, Direct Unit Cost and Quantity(Base) on Generated Report.
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        VerifyStatusReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('InvtValCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationCostSpecReportForPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Item, Create and Post Purchase Order with Receive Option.
        Initialize();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndPostPurchaseOrderWithUOM(PurchaseHeader, Item, false);  // Change Unit Of Measure  as False.

        // Exercise: Generate the Invt. Valuation - Cost Spec. report.
        RunInvtValuationCostSpecReport(Item."No.");

        // Verify: Verify Amount, Direct Unit Cost and Quantity on Generated Report.
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        VerifyInventoryValuationCostSpecReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PostProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostPostedToGLAfterRunningInventoryValuationWIPReport()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
    begin
        // Run the Inventory Valuation - WIP report. Verify Cost Posted To GL After Posting Revalution Journal.

        // Setup: Create and Post Revaluation Journal after Adjusting Cost Item Entries.
        Initialize();

        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Stock");
        UpdateItem(Item, Item.FieldNo("Costing Method"), Item."Costing Method"::Standard);
        UpdateItem(Item, Item.FieldNo("Standard Cost"), LibraryRandom.RandDec(10, 2));
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        OpenProductionJournal(ProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        UpdateItem(Item, Item.FieldNo("Standard Cost"), Item."Standard Cost" + LibraryRandom.RandDec(5, 2));
        CreateAndUpdateRevaluationJournal(ItemJournalLine, Item."No.", Item."Standard Cost");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Exercise: Run Inventory Valuation WIP Report.
        Commit();
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', WorkDate()));
        LibraryVariableStorage.Enqueue(CalcDate('<CM>', WorkDate()));
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);

        // Verify: Verify  Cost Posted To GL on Generated Report.
        VerifyCostPostedToGL(ProductionOrder."No.", ItemJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailWithFullReservFromInventory()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchQty: Decimal;
        ExpectedPurchQty: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Setup: Create and post Purchase Order
        PurchQty := LibraryRandom.RandDec(10, 2) * 10;
        CreatePurchaseOrder(PurchHeader, Item."No.", PurchQty);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Setup: Auto-reserve for Sales Order.
        AutoReserveForSalesOrder(SalesHeader, Item."No.", WorkDate(), PurchQty - 1);
        ExpectedPurchQty := PurchQty - 1;

        // Exercise: Generate the Sales Reservation Avail. report with Show Sales Line & Reservation Entries & Modify Qty. to Ship In Order Lines.
        Commit();
        RunSalesReservationAvailReport(SalesHeader."No.", true, true, true);

        // Verify: Check the Quantity On Hand(Base) in the report.
        VerifySalesReservationAvailReport(SalesLine, SalesHeader."No.", ExpectedPurchQty, FullShipmentValueTxt);

        // Verify: Check Qty. to Ship in Sales Line.
        Assert.AreEqual(ExpectedPurchQty, SalesLine."Qty. to Ship", MsgQtytoShipErr);
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler,PurchResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailReportFullReservFromPurchOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchQty: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Setup: Create and post Purchase Order.
        PurchQty := LibraryRandom.RandDec(10, 2) * 10;
        CreatePurchaseOrder(PurchHeader, Item."No.", PurchQty);

        // Setup: Auto-reserve for Sales Order.
        AutoReserveForSalesOrder(SalesHeader, Item."No.", CalcDate('<+5D>', WorkDate()), PurchQty - 1);

        // Exercise1: Generate the Sales Reservation Avail. report with Show Sales Line & Reservation Entries & Modify Qty. to Ship In Order Lines.
        Commit();
        RunSalesReservationAvailReport(SalesHeader."No.", true, true, true);

        // Verify: Check the Quantity On Hand(Base) in the Sales Reservation Avail. Report.
        VerifySalesReservationAvailReport(SalesLine, SalesHeader."No.", 0, NoShipmentValueTxt);

        // Verify: Check Qty. to Ship in Sales Line.
        Assert.AreEqual(0, SalesLine."Qty. to Ship", MsgQtytoShipErr);

        // Exercise2: Generate the Purchase Reservation Avail. report with Show Sales Line & Reservation Entries & Modify Qty. to Ship In Order Lines.
        Commit();
        RunPurchReserveAvailReport(PurchHeader."No.", true, true, true);

        // Verify: Check Qty. to Ship in Purchase Line.
        VerifyQtyToReceiveInPurchLine(PurchHeader);
    end;

    [Test]
    [HandlerFunctions('SalesResAvailRequestPageHandler,PurchResAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailReportReserveFromDifSupplyType()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchHeader: array[3] of Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchQty: Decimal;
        ExpectedPurchQty: Decimal;
    begin
        // Setup: Create Item. Create three Purchase Order and post two of them. Create Sales Order. Auto-reserve Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Setup: Create three Purchase Order and post two of them.
        PurchQty := LibraryRandom.RandDec(10, 2) * 10;
        CreatePurchaseOrder(PurchHeader[1], Item."No.", PurchQty);
        CreatePurchaseOrder(PurchHeader[2], Item."No.", PurchQty);
        CreatePurchaseOrder(PurchHeader[3], Item."No.", PurchQty);
        LibraryPurchase.PostPurchaseDocument(PurchHeader[1], true, true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader[2], true, true);

        // Setup: Auto-reserve for Sales Order.
        AutoReserveForSalesOrder(SalesHeader, Item."No.", CalcDate('<+7D>', WorkDate()), 3 * PurchQty - 1);
        ExpectedPurchQty := 2 * PurchQty;
        // Exercise1: Generate the Sales Reservation Avail. report with Show Sales Line & Reservation Entries & Modify Qty. to Ship In Order Lines.
        Commit();
        RunSalesReservationAvailReport(SalesHeader."No.", true, true, true);

        // Verify: Check the Quantity On Hand(Base) in the report.
        VerifySalesReservationAvailReport(SalesLine, SalesHeader."No.", ExpectedPurchQty, PartialShipmentValueTxt);

        // Verify: Check Qty. to Ship in Sales Line.
        Assert.AreEqual(ExpectedPurchQty, SalesLine."Qty. to Ship", MsgQtytoShipErr);

        // Exercise2: Generate the Purchase Reservation Avail. report with Show Sales Line & Reservation Entries & Modify Qty. to Ship In Order Lines.
        Commit();
        RunPurchReserveAvailReport(PurchHeader[3]."No.", true, true, true);

        // Verify: Check Qty. to Receive in Purchase Line.
        VerifyQtyToReceiveInPurchLine(PurchHeader[3]);
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportVariant()
    var
        Item: Record Item;
        ItemVariant1: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        PriceListLine: Record "Price List Line";
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        CustomerNo: Code[20];
        MinimumQty: array[4] of Decimal;
        UnitPrice: array[2] of Decimal;
        LineDiscount: array[2] of Decimal;
        i: Integer;
    begin
        // 1. Setup: Create Item with Variant Code, Sales Price & Line Discount.
        Initialize();
        PriceListLine.DeleteAll();

        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(100, 2));

        LibraryInventory.CreateItemVariant(ItemVariant1, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        for i := 1 to 4 do
            MinimumQty[i] := LibraryRandom.RandDec(10, 2);

        for i := 1 to 2 do begin
            UnitPrice[i] := LibraryRandom.RandDec(100, 2);
            LineDiscount[i] := LibraryRandom.RandDec(99, 2);
        end;

        CreateSalesPriceForItem(
          Item, "Sales Price Type"::Customer, CustomerNo, ItemVariant1.Code, MinimumQty[1], UnitPrice[1]);
        CreateSalesPriceForItem(
          Item, "Sales Price Type"::Customer, CustomerNo, ItemVariant1.Code, MinimumQty[2], UnitPrice[2]);
        //PriceListLine.CopyFrom(SalesPrice);

        CreateSalesLineDiscountForItem(Item, CustomerNo, ItemVariant2.Code, MinimumQty[3], LineDiscount[1]);
        CreateSalesLineDiscountForItem(Item, CustomerNo, ItemVariant2.Code, MinimumQty[4], LineDiscount[2]);
        //PriceListLine.CopyFrom(SalesLineDiscount);

        // 2. Execise: Generate Price List Report.
        Commit();
        RunPriceListReport(Item."No.", SalesType::Customer, CustomerNo, '');

        // 3. Verify: Check Variant lines in Price List Report.
        LibraryReportDataset.LoadDataSetFile();

        VerifyVariantLineInPriceListReport(
          'ItemNo_Variant_SalesPrices', ItemVariant1.Code, 'MinimumQty_Variant_SalesPrices', MinimumQty[1],
          'UnitPrince_Variant_SalesPrices', UnitPrice[1]);
        VerifyVariantLineInPriceListReport(
          'ItemNo_Variant_SalesPrices', ItemVariant1.Code, 'MinimumQty_Variant_SalesPrices', MinimumQty[2],
          'UnitPrince_Variant_SalesPrices', UnitPrice[2]);
        VerifyVariantLineInPriceListReport(
          'ItemNo_Variant_SalesLineDescs', ItemVariant2.Code, 'MinimumQty_Variant_SalesLineDescs', MinimumQty[3],
          'LineDisc_Variant_SalesLineDescs', LineDiscount[1]);
        VerifyVariantLineInPriceListReport(
          'ItemNo_Variant_SalesLineDescs', ItemVariant2.Code, 'MinimumQty_Variant_SalesLineDescs', MinimumQty[4],
          'LineDisc_Variant_SalesLineDescs', LineDiscount[2]);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MessageHandler,GenericConfirmHandlerYes,RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ZeroLineNotDisplayedInInventoryValuationWIPReport()
    var
        ProdOrderArray: array[3] of Code[10];
    begin
        // Setup
        ChangeThreeReleasedProdOrdersToFinished(ProdOrderArray);

        // Exercise
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Starting Date and Ending Date is work correctly in Inventory Valuation WIP report.
        Commit();
        RunInventoryValuationWIPReportWithTimePeriod(CalcDate('<-1M-1D>', WorkDate()), CalcDate('<-1D>', WorkDate()), ProdOrderArray);
        ValidateInventoryValuationWIPReport(ProdOrderArray);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler,InventoryValuationWIPRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CostPostedToGLShownInWIPReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        PostMethod: Option "per Posting Group","per Entry";
        CostPostedToGL: Decimal;
    begin
        // Setup: Create Production Order Setup.
        Initialize();

        // Setup: Create Production BOM.
        // Setup: Create Parent Item and attach Routing and Production BOM.
        CreateParentItemWithRoutingAndProductionBOM(Item);

        // Setup: Create a Production Order and post Output.
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(5));
        ExplodeAndPostOutputJournal(Item."No.", ProductionOrder."No.");

        // Setup: Post consumptions in the next month.
        WorkDate := CalcDate('<+1M>', WorkDate());
        CalculateAndPostConsumption(ProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Setup: Run Adjust Cost Item Entries batch job and Run Post Inventory Cost to G/L.
        LibraryCosting.AdjustCostItemEntries('', '');
        PostInventoryCostToGLRun(PostMethod::"per Entry", true);

        // Exercise: Run WIP report.
        LibraryVariableStorage.Enqueue(CalcDate('<-1M>', WorkDate()));
        LibraryVariableStorage.Enqueue(CalcDate('<-1M+CM>', WorkDate()));
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);

        // Verify: Check the value of Cost Posted to G/L column.
        ValueEntry.SetRange("Posting Date", CalcDate('<-1M>', WorkDate()), CalcDate('<-1M+CM>', WorkDate()));
        ValueEntry.SetRange("Source No.", Item."No.");
        ValueEntry.FindSet();
        repeat
            CostPostedToGL += ValueEntry."Cost Posted to G/L";
        until ValueEntry.Next() = 0;

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SourceNo_ProductionOrder', Item."No.");
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueEntryCostPostedtoGL', -CostPostedToGL);
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostShareRepWithUnderDevelopmentStatus()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Run the Rolled Up Cost Shares report and check the item on report when one component is delete from Production BOM Version with Under Development status.
        RolledUpCostShareReportWithStatus(ProductionBOMVersion.Status::"Under Development");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostShareRepWithCertifiedStatus()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Run the Rolled Up Cost Shares report and check the item on report when one component is delete from Production BOM Version with certified status.
        RolledUpCostShareReportWithStatus(ProductionBOMVersion.Status::Certified);
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostShareRepWithUnderDevStatusWithProdBOM()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Run the Rolled Up Cost Shares report with type Production BOM and check the item on report when one component is delete from Production BOM Version with Under Development status.
        RolledUpCostShareReportWithTypeProdBOM(ProductionBOMHeader.Status::"Under Development");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostShareRepWithCertifiedStatusWithTypeProdBOM()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Run the Rolled Up Cost Shares report with type Production BOM and check the item on report when one component is delete from Production BOM Version with Certified status.
        RolledUpCostShareReportWithTypeProdBOM(ProductionBOMHeader.Status::Certified);
    end;

    [Test]
    [HandlerFunctions('InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AsOfValueInInventoryValuationWIPReport()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        ConsumptionQty: array[3] of Decimal;
        OutputQty: array[3] of Decimal;
        PostingDate: array[3] of Date;
        i: Integer;
        Number: Integer;
    begin
        // Setup: Create Component Item and Production Item, and update Inventory.
        Initialize();
        CreateItem(ComponentItem, '', '', ComponentItem."Manufacturing Policy"::"Make-to-Stock");
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        ItemJournalSetup(ItemJournalBatch);
        Quantity := 4 * LibraryRandom.RandIntInRange(1, 10);
        PostItemPositiveAdjmt(ItemJournalBatch, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", Quantity);

        // Create a Production Order.
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", Quantity);

        // Post Consumption and Output in different period.
        Number := LibraryRandom.RandIntInRange(1, 10);
        PostingDate[1] := WorkDate();
        PostingDate[2] := CalcDate('<' + Format(Number) + 'D>', WorkDate());
        PostingDate[3] := CalcDate('<' + Format(2 * Number) + 'D>', WorkDate());
        ConsumptionQty[1] := Quantity / 4;
        ConsumptionQty[2] := 3 * Quantity / 4;
        ConsumptionQty[3] := 0;
        OutputQty[1] := Quantity / 2;
        OutputQty[2] := Quantity / 4;
        OutputQty[3] := Quantity / 4;
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        for i := 1 to 3 do
            PostConsumptionAndOutput(ProdOrderLine, ComponentItem, Item."Unit Cost", ConsumptionQty[i], OutputQty[i], PostingDate[i]);

        // Finish the Production Order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Run Adjust Cost Item Entries batch job
        LibraryCosting.AdjustCostItemEntries('', '');
        Commit(); // To avoid test failure.

        // Exercise: Run Inventory Valuation - WIP report.
        RunInventoryValuationWIPReport(ProductionOrder, CalcDate('<+1D>', WorkDate()), CalcDate('<' + Format(Number + 1) + 'D>', WorkDate()));

        // Verify: Verify "As of..." value is correct in report Inventory Valuation - WIP
        LibraryReportDataset.LoadDataSetFile();
        VerifyVariantLineInPriceListReport(
          'SourceNo_ProductionOrder', Item."No.", 'LastWIP', -ComponentItem."Unit Cost", 'AtLastDate', ComponentItem."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckInventoryAvailabilityReportForRequisitionLine()
    var
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Availability]
        // [SCENARIO 363787] Planned Order Receipt and Projected Available Balance in Inventory Availability report is equal to Quantity of appropriate Requisition Line
        Initialize();

        // [GIVEN] Item with Inventory = 0
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);

        // [GIVEN] Requisition Line for Item with Quantity = "X"
        Qty := LibraryRandom.RandDec(10, 2);
        CreateReqLine(Item."No.", Qty);

        // [WHEN] Run Inventory Availability report
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Availability", true, false, Item);

        // [THEN] Planned Order Receipt = "X", Projected Available Balance = "X"
        VerifyInventoryAvailabilityReport(Item."No.", Qty);
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationReportIncludesPhantomBOMComponents()
    var
        ParentItem: Record Item;
        ProdBOMHeaderParent: Record "Production BOM Header";
        ProdBOMHeaderChild: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBomVersion: Record "Production BOM Version";
        ChildItem: Record Item;
    begin
        // [FEATURE] [Manufacturing] [Production BOM] [Phantom BOM]
        // [SCENARIO 371942] Phantom BOM components should be included in the report "Detailed Calculation" when the phantom BOM is a part of the active BOM version

        // [GIVEN] Item "I1" with bill of materials "ParentBOM"
        LibraryInventory.CreateItem(ParentItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProdBOMHeaderParent, LibraryInventory.CreateItemNo(), 1);
        ParentItem.Validate("Production BOM No.", ProdBOMHeaderParent."No.");
        ParentItem.Modify(true);

        // [GIVEN] Component item "I2"
        LibraryInventory.CreateItem(ChildItem);
        // [GIVEN] Bill of materials "Child BOM" that includes item "I2"
        LibraryManufacturing.CreateCertifiedProductionBOM(ProdBOMHeaderChild, ChildItem."No.", 1);

        // [GIVEN] Version of the "ParentBOM" including the "ChildBOM" as a phantom BOM
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBomVersion, ProdBOMHeaderParent."No.", LibraryUtility.GenerateGUID(), ProdBOMHeaderParent."Unit of Measure Code");
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeaderParent, ProductionBOMLine, ProductionBomVersion."Version Code",
          ProductionBOMLine.Type::"Production BOM", ProdBOMHeaderChild."No.", 1);
        ProductionBomVersion.Validate(Status, ProductionBomVersion.Status::Certified);
        ProductionBomVersion.Modify(true);

        // [WHEN] Run report "Detailed Calculation" for item "I1"
        Commit();
        ParentItem.SetRecFilter();
        REPORT.Run(REPORT::"Detailed Calculation", true, false, ParentItem);

        // [THEN] Item "I2" is reported in the list of components
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProdBOMLineLevelNo', ChildItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhantomBOMScrapIncludedInCostSharesReport()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        QtyPerBOMLine: Integer;
        ScrapPct: Integer;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Scrap] [Cost Shares]
        // [SCENARIO 378057] When generating "Cost Shares" report, scrap % in a phantom BOM line is included in calculation

        // [GIVEN] Component item "I1" with unit cost 10
        CreateItem(Item[1], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "B1" with one component "I1"
        CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", 1);

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Scrap %" = 5 in prod. BOM line, "Qty. per" = 1
        QtyPerBOMLine := LibraryRandom.RandInt(10);
        ScrapPct := LibraryRandom.RandIntInRange(5, 10);
        CreateCertifiedProdBOMWithScrap(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.",
          QtyPerBOMLine, ScrapPct);

        // [GIVEN] Manufactured item "I2" with BOM "B2"
        CreateItem(Item[2], '', ProductionBOMHeader[2]."No.", Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Scrap Qty. per Parent" = 0,05, "Qty. per Parent" = 1,05, "Rolled-up Material Cost" = 10,5
        VerifyBOMBuffer(TempBOMBuffer, Item[1], QtyPerBOMLine, QtyPerBOMLine * ScrapPct / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhantomBOMScrapIncludedInCostSharesReportMultilevelBOM()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        Scrap: array[2] of Integer;
        QtyPer: array[2] of Integer;
        TotalScrapQty: Decimal;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Scrap] [Cost Shares]
        // [SCENARIO 378057] When generating "Cost Shares" report for a multilevel phantom BOM, scrap % in all phantom BOM lines is included in calculation

        // [GIVEN] Component item "I1" with unit cost 10
        CreateItem(Item[1], '', '', Item[1]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "B1" with one component "I1"
        CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", 1);

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Scrap %" = 5 in prod. BOM line, "Qty. per" = 1
        QtyPer[1] := LibraryRandom.RandInt(50);
        Scrap[1] := LibraryRandom.RandIntInRange(10, 20);
        CreateCertifiedProdBOMWithScrap(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.", QtyPer[1], Scrap[1]);

        // [GIVEN] Production BOM "B3" which includes BOM "B2" as a phantom BOM. Set "Scrap %" = 5 in prod. BOM line, "Qty. per" = 1
        QtyPer[2] := LibraryRandom.RandInt(50);
        Scrap[2] := LibraryRandom.RandIntInRange(10, 20);
        CreateCertifiedProdBOMWithScrap(
          ProductionBOMHeader[3], Item[1]."Base Unit of Measure",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[2]."No.", QtyPer[2], Scrap[2]);

        // [GIVEN] Manufactured item "I2" with BOM "B3"
        CreateItem(Item[2], '', ProductionBOMHeader[3]."No.", Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Scrap Qty. per Parent" = 0,1025, "Qty. per Parent" = 1,1025, "Rolled-up Material Cost" = 11,025
        TotalScrapQty := QtyPer[1] * QtyPer[2] * (Scrap[1] + Scrap[2] + Scrap[1] * Scrap[2] / 100) / 100;
        VerifyBOMBuffer(TempBOMBuffer, Item[1], QtyPer[1] * QtyPer[2], TotalScrapQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilevelPhantomBOMWithDifferentUOM()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        I: Integer;
        QtyPer: array[3] of Integer;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Unit of Measure] [Cost Shares]
        // [SCENARIO 378057] When generating "Cost Shares" report for a multilevel phantom BOM with different UoMs on BOM levels, unit of measure is considered in calculation

        // [GIVEN] Component item "I1"
        CreateItem(Item[1], '', '', Item[1]."Manufacturing Policy"::"Make-to-Stock");

        for I := 1 to ArrayLen(QtyPer) do
            QtyPer[I] := LibraryRandom.RandInt(50);

        // [GIVEN] Production BOM "B1" with one component "I1", "Qty. per" = "X"
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", QtyPer[1]);

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Qty. per" = "Y", unit of measure = "U1"
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.", QtyPer[2]);

        // [GIVEN] Production BOM "B3" and manufactured item "I2" with BOM "B3", "Qty. per" = "Z"
        // [GIVEN] Create item unit of measure "U2" with "quantity per" = "Q", set it a UoM for production BOM "B3"
        CreateItem(Item[2], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item[2]."No.", LibraryRandom.RandIntInRange(5, 10));
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[3], ItemUnitOfMeasure.Code,
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[2]."No.", QtyPer[3]);
        UpdateProdBOMCodeOnItem(Item[2], ProductionBOMHeader[3]."No.");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Qty. per Parent" = "X" * "Y" * "Z" / "Q"
        VerifyBOMBuffer(
          TempBOMBuffer, Item[1],
          Round(QtyPer[1] * QtyPer[2] * QtyPer[3] / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilevelPhantomBOMWithBOMVersion()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        I: Integer;
        QtyPer: array[3] of Integer;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Unit of Measure] [Cost Shares] [BOM Version]
        // [SCENARIO 378057] When generating "Cost Shares" report for a multilevel phantom BOM with different UoMs on BOM levels, unit of measure is taken from active BOM version

        // [GIVEN] Component item "I1"
        CreateItem(Item[1], '', '', Item[1]."Manufacturing Policy"::"Make-to-Stock");

        for I := 1 to ArrayLen(QtyPer) do
            QtyPer[I] := LibraryRandom.RandInt(50);

        // [GIVEN] Production BOM "B1" with one component "I1", "Qty. per" = "X1"
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", QtyPer[1]);

        // [GIVEN] Create active BOM version for production BOM "B1", set "Qty. per" = "X2"
        CreateCertifiedProdBOMVersion(ProductionBOMVersion, ProductionBOMHeader[1], Item[1]."Base Unit of Measure");

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Qty. per" = "Y", unit of measure = "U1"
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.", QtyPer[2]);

        // [GIVEN] Production BOM "B3" and manufactured item "I2" with BOM "B3", "Qty. per" = "Z"
        // [GIVEN] Create item unit of measure "U2" with "quantity per" = "Q", set it a UoM for production BOM "B3"
        CreateItem(Item[2], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item[2]."No.", LibraryRandom.RandIntInRange(10, 20));
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[3], ItemUnitOfMeasure.Code,
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[2]."No.", QtyPer[3]);
        UpdateProdBOMCodeOnItem(Item[2], ProductionBOMHeader[3]."No.");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Qty. per Parent" = "X2" * "Y" * "Z" / "Q"
        VerifyBOMBuffer(
          TempBOMBuffer, Item[1],
          Round(QtyPer[1] * QtyPer[2] * QtyPer[3] / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilevelBOMWithDifferentUOMAndMultipleLines()
    var
        Item: array[3] of Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
    begin
        // [FEATURE] [Production BOM]  [Unit of Measure]
        // [SCENARIO 379112] When generating BOM tree for a multilevel BOM with different UoMs on BOM levels, unit of measure should be taken from Base Unit of Measure.
        Initialize();

        // [GIVEN] Component item "I1" with Production BOM "B1" and base UoM = "X"
        CreateItemWithProductionBOM(Item[1]);

        // [GIVEN] Item "ParentItem" with base UoM = "Y"
        CreateItemWithUpdatedBaseUnitOfMeasure(ItemUnitOfMeasure[1], Item[2], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Component item "I3" with base UoM = "Z"
        CreateItemWithUpdatedBaseUnitOfMeasure(ItemUnitOfMeasure[2], Item[3], '', '', Item[3]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "B2" with component items "I1" and "I3".
        CreateCertifiedProductionBOMWithMultipleLines(ProductionBOMHeader[2], ItemUnitOfMeasure[1].Code,
          ItemUnitOfMeasure[2].Code, ProductionBOMLine.Type::Item, Item[1]."No.", 1, Item[3]."No.", ProductionBOMLine.Type::Item);
        UpdateProdBOMCodeOnItem(Item[2], ProductionBOMHeader[2]."No.");

        // [WHEN] Generate BOM tree for ParentItem
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line with item "I3" Unit of Measure Code = "X"
        TempBOMBuffer.SetRange("No.", Item[3]."No.");
        TempBOMBuffer.FindFirst();
        TempBOMBuffer.TestField("Unit of Measure Code", Item[3]."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingScrapConsideredInCostSharesForPhantomBOM()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        RoutingHeader: Record "Routing Header";
        QtyPerBOMLine: Integer;
        ScrapPct: Integer;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Scrap] [Cost Shares] [Routing]
        // [SCENARIO 378260] When generating "Cost Shares" for a phantom BOM, scrap % in a routing line is included in calculation

        // [GIVEN] Component item "I1" with unit cost 10
        CreateItem(Item[1], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "B1" with one component "I1"
        CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", 1);

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Qty. per" = 1
        QtyPerBOMLine := LibraryRandom.RandInt(10);
        ScrapPct := LibraryRandom.RandIntInRange(5, 10);
        CreateCertifiedProductionBOM(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.",
          QtyPerBOMLine);

        // [GIVEN] Manufactured item "I2" with BOM "B2" and routing "R". Routing line has 5% scrap
        CreateRoutingWithScrap(RoutingHeader, ScrapPct);
        CreateItem(Item[2], RoutingHeader."No.", ProductionBOMHeader[2]."No.", Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Scrap Qty. per Parent" = 0,05, "Qty. per Parent" = 1,05, "Rolled-up Material Cost" = 10,5
        VerifyBOMBuffer(TempBOMBuffer, Item[1], QtyPerBOMLine, QtyPerBOMLine * ScrapPct / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingAndBOMScrapConsideredInCostSharesForPhantomBOM()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        RoutingHeader: Record "Routing Header";
        QtyPerBOMLine: Integer;
        ScrapPct: Integer;
    begin
        // [FEATURE] [Production BOM] [Phantom BOM] [Scrap] [Cost Shares] [Routing]
        // [SCENARIO 378260] When generating "Cost Shares" for a phantom BOM with scrap % in routing line and BOM line, both settings are included in calculation

        // [GIVEN] Component item "I1" with unit cost 10
        CreateItem(Item[1], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "B1" with one component "I1"
        CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.", 1);

        // [GIVEN] Production BOM "B2" which includes BOM "B1" as a phantom BOM. Set "Scrap %" = 5 in prod. BOM line, "Qty. per" = 1
        QtyPerBOMLine := LibraryRandom.RandInt(10);
        ScrapPct := LibraryRandom.RandIntInRange(5, 10);
        CreateCertifiedProdBOMWithScrap(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.",
          QtyPerBOMLine, ScrapPct);

        // [GIVEN] Manufactured item "I2" with BOM "B2" and routing "R". Routing line has 5% scrap
        CreateRoutingWithScrap(RoutingHeader, ScrapPct);
        CreateItem(Item[2], RoutingHeader."No.", ProductionBOMHeader[2]."No.", Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Scrap Qty. per Parent" = 0,1025, "Qty. per Parent" = 1,1025, "Rolled-up Material Cost" = 11,025
        VerifyBOMBuffer(TempBOMBuffer, Item[1], QtyPerBOMLine, QtyPerBOMLine * ScrapPct * (2 + ScrapPct / 100) / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecimalRoutingAndBOMScrapInCostShares()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        RoutingHeader: Record "Routing Header";
        QtyPerBOMLine: Integer;
        ScrapPct: Decimal;
    begin
        // [FEATURE] [Production BOM] [Scrap] [Cost Shares] [Routing]
        // [SCENARIO 378260] "Cost Shares" report can be generated for an item which has scrap in both linked routing and production BOM, and scrap % is a decimal value

        // [GIVEN] Component item "I1" with unit cost 10
        CreateItem(Item[1], '', '', Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production BOM "BOM" which includes item "I1" as a component. Set "Scrap %" = 5.1 in prod. BOM line, "Qty. per" = 1
        QtyPerBOMLine := LibraryRandom.RandInt(10);
        ScrapPct := LibraryRandom.RandDecInRange(5, 10, 1);
        CreateCertifiedProdBOMWithScrap(
          ProductionBOMHeader[2], Item[1]."Base Unit of Measure", ProductionBOMLine.Type::Item, Item[1]."No.",
          QtyPerBOMLine, ScrapPct);

        // [GIVEN] Manufactured item "I2" with BOM "B2" and routing "R". Routing line has 5.1 % scrap
        CreateRoutingWithScrap(RoutingHeader, ScrapPct);
        CreateItem(Item[2], RoutingHeader."No.", ProductionBOMHeader[2]."No.", Item[2]."Manufacturing Policy"::"Make-to-Stock");

        // [WHEN] Generate "Cost Shares" report for item "I2"
        GenerateBOMCostTree(Item[2], TempBOMBuffer);

        // [THEN] In the component line, "Scrap Qty. per Parent" = 0,1046, "Qty. per Parent" = 1,1046, "Rolled-up Material Cost" = 11,046
        VerifyBOMBuffer(TempBOMBuffer, Item[1], QtyPerBOMLine, QtyPerBOMLine * ScrapPct * (2 + ScrapPct / 100) / 100);
    end;

    [Test]
    [HandlerFunctions('InventoryPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPostingReportBatchTemplateFilters()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ExtraItemJournalBatch: Record "Item Journal Batch";
        ExtraItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Report] [RDLC Layout]
        // [SCENARIO 348957] "Inventory Posting - Test" report doesn't include empty Item Journal Templates and Batches
        Initialize();

        // [GIVEN] Created an Item Line for Item Journal Template = IT1, Item Journal Batch = IB1
        GeneralLedgerSetup.Get();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, Item."No.");

        // [WHEN] Created Item Journal Template = IT2, Item Journal Batch = IB2
        LibraryInventory.CreateItemJournalTemplate(ExtraItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ExtraItemJournalBatch, ExtraItemJournalTemplate.Name);

        // [WHEN] Run "Inventory Posting - Test" report for Item Line
        Commit();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        REPORT.Run(REPORT::"Inventory Posting - Test", true, false, ItemJournalLine);

        // [THEN] Dataset includes elements for IT1, IB1
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Item_Journal_Batch_Name', ItemJournalBatch.Name);
        LibraryReportDataset.AssertElementWithValueExists(
          'Item_Journal_Batch_Journal_Template_Name', ItemJournalBatch."Journal Template Name");

        // [THEN] Dataset doesn't include elements for IT2, IB2
        LibraryReportDataset.AssertElementWithValueNotExist(
          'Item_Journal_Batch_Journal_Template_Name', ExtraItemJournalTemplate.Name);
        LibraryReportDataset.AssertElementWithValueNotExist(
          'Item_Journal_Batch_Name', ExtraItemJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportForItemWithoutSalesPrice()
    var
        Item: array[2] of Record Item;
        SalesPrice: Record "Sales Price";
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        CustomerNo: Code[20];
        SalesPriceUnitPrice: Decimal;
        UnitPrice: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Unit Price] [Sales Price]
        // [SCENARIO 365188] Price List report shows Item's Unit Price, when Sales Price doesn't exist.
        Initialize();

        // [GIVEN] Two Items, "I1" with Unit Price "UP1", Sales Price "SP" and "I2" with Unit Price "UP2".
        for i := 1 to 2 do begin
            CreateItem(Item[i], '', '', Item[i]."Manufacturing Policy"::"Make-to-Order");
            UnitPrice := LibraryRandom.RandDec(100, 2);
            UpdateItem(Item[i], Item[i].FieldNo("Unit Price"), UnitPrice);
        end;
        CustomerNo := LibrarySales.CreateCustomerNo();
        SalesPriceUnitPrice := LibraryRandom.RandDec(100, 2);
        CreateSalesPriceForItem(Item[1], SalesPrice."Sales Type"::Customer, CustomerNo, '', 0, SalesPriceUnitPrice);

        // [WHEN] Report Price List is run for Items "I1" and "I2".
        Commit();
        RunPriceListReport(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), SalesType::Customer, CustomerNo, '');

        // [THEN] Report dataset contains "SP" and "UP2".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('SalesPriceUnitPrice', SalesPriceUnitPrice);
        LibraryReportDataset.AssertElementWithValueExists('SalesPriceUnitPrice', UnitPrice);
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportForItemWithoutSalesDiscount()
    var
        Item: array[2] of Record Item;
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        CustomerNo: Code[20];
        LineDiscount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Unit Price] [Line Discount]
        // [SCENARIO 365188] Price List report doesn't show Sales Discount for Item without it.
        Initialize();

        // [GIVEN] Two Items, "I1" with Line Discount "LD" and "I2" without Line discount.
        for i := 1 to 2 do begin
            CreateItem(Item[i], '', '', Item[i]."Manufacturing Policy"::"Make-to-Order");
            UpdateItem(Item[i], Item[i].FieldNo("Unit Price"), LibraryRandom.RandDec(100, 2));
        end;
        CustomerNo := LibrarySales.CreateCustomerNo();
        LineDiscount := LibraryRandom.RandDec(99, 2);
        CreateSalesLineDiscountForItem(Item[1], CustomerNo, '', 0, LineDiscount);

        // [WHEN] Report Price List is run for Items "I1" and "I2".
        Commit();
        RunPriceListReport(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), SalesType::Customer, CustomerNo, '');

        // [THEN] Report dataset contains exactly one "LD".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('LineDisc_SalesLineDisc', LineDiscount);
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), '');
    end;

    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReportForCustomerAndAllCustomerPrice()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        CustomerNo: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [SCENARIO 387837] Created two price of Item: one for Customer, another for All Customer. Then run report "Price List" for Customer
        // [GIVEN] Created Customer and Item
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Generated 2 Unit prices
        UnitPrice[1] := LibraryRandom.RandDec(100, 2);
        UnitPrice[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Created Sales Price Line with first Unit Price for Customer
        CreateSalesPriceForItem(
          Item, SalesPrice."Sales Type"::Customer, CustomerNo, '', 0, UnitPrice[1]);

        // [GIVEN] Created Sales Price Line with second Unit Price for All Customers
        CreateSalesPriceForItem(
          Item, SalesPrice."Sales Type"::"All Customers", '', '', 0, UnitPrice[2]);

        // [WHEN] Run report 715 "Price List"
        Commit();
        RunPriceListReport(Item."No.", SalesType::Customer, CustomerNo, '');

        // [THEN] Both "Unit Price" are shown
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('SalesPriceUnitPrice', UnitPrice[1]);
        LibraryReportDataset.AssertElementWithValueExists('SalesPriceUnitPrice', UnitPrice[2]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports - II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - II");
    end;

    local procedure CreateItem(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        // Random value unimportant for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(50, 2), Item."Reordering Policy",
          Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Manufacturing Policy", ItemManufacturingPolicy);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateItemWithUpdatedBaseUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy")
    var
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
    begin
        CreateItem(Item, RoutingNo, ProductionBOMNo, ItemManufacturingPolicy);
        ItemUnitOfMeasure2.Get(Item."No.", Item."Base Unit of Measure");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
        ItemUnitOfMeasure2.Delete(true);
    end;

    local procedure UpdateItem(var Item: Record Item; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Item based on Field and its corresponding value.
        Item.Find();
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(Item);
        Item.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QtyPer);
        UpdateProdBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateCertifiedProductionBOMWithMultipleLines(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; UoMCode2: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QtyPer: Decimal; No2: Code[20]; Type2: Enum "Production BOM Line Type")
    var
        ProductionBOMLine: array[2] of Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine[1], '', Type, No, QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine[2], '', Type2, No2, QtyPer);
        ProductionBOMLine[2].Validate("Unit of Measure Code", UoMCode2);
        ProductionBOMLine[2].Modify(true);
        UpdateProdBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateCertifiedProdBOMWithScrap(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QtyPer: Decimal; ScrapPct: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoMCode);
        CreateProdBOMLineWithScrap(ProductionBOMHeader, ProductionBOMLine, Type, No, QtyPer, ScrapPct);
    end;

    local procedure CreateCertifiedProdBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10])
    var
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader."No.", LibraryUtility.GenerateGUID(), UoMCode);

        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure SelectCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());

        // Using RANDOM Exchange Rate Amount and Adjustment Exchange Rate, between 100 and 400 (Standard Value).
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithPriceGroup(CustomerPriceGroup: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Price Group", CustomerPriceGroup);
        Customer.Modify(true);
    end;

    local procedure CreateProdBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; Item: Record Item; Status: Enum "BOM Status")
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, Item."Production BOM No.", LibraryUtility.GenerateGUID(), Item."Base Unit of Measure");
        UpdateProdBOMVersionLine(Item."Production BOM No.", ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure RunPriceListReport(NoFilter: Text; SalesType: Option; SalesCode: Code[20]; CurrencyCode: Code[10])
    var
        Item: Record Item;
    begin
        // Execute Price List report with the required combinations of Sales Type and Sales Code.
        Item.SetFilter("No.", NoFilter);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(SalesType);
        LibraryVariableStorage.Enqueue(SalesCode);
        LibraryVariableStorage.Enqueue(CurrencyCode);
        REPORT.Run(REPORT::"Price List", true, false, Item);
    end;

    local procedure VerifyUnitPrice(Item: Record Item; CurrencyCode: Code[10]; ExpUnitPrice: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryReportDataset.LoadDataSetFile();
        if CurrencyCode <> '' then begin
            CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
            CurrencyExchangeRate.FindFirst();
            LibraryReportDataset.SetRange('UnitPriceFieldCaption', Item.FieldCaption("Unit Price") + ' ' + '(' + CurrencyCode + ')');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('SalesPriceUnitPrice', ExpUnitPrice /
              (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));
        end else begin
            LibraryReportDataset.SetRange('UnitPriceFieldCaption', Item.FieldCaption("Unit Price"));
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('SalesPriceUnitPrice', ExpUnitPrice);
        end;
    end;

    local procedure VerifyVariantLineInPriceListReport(VariantCap: Text[40]; VariantCode: Code[20]; MinimumQtyCap: Text[40]; MinimumQty: Decimal; AmountCap: Text[40]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(VariantCap, VariantCode);
        LibraryReportDataset.AssertElementWithValueExists(MinimumQtyCap, MinimumQty);
        LibraryReportDataset.AssertElementWithValueExists(AmountCap, Amount);
    end;

    local procedure CreateParentItemWithRoutingAndProductionBOM(var Item: Record Item)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        ChildItemNo: array[2] of Code[20];
    begin
        ItemJournalSetup(ItemJournalBatch);
        ChildItemNo[1] := CreateChildItemWithInventory(ItemJournalBatch);
        ChildItemNo[2] := CreateChildItemWithInventory(ItemJournalBatch);

        // Setup: Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo[1], ChildItemNo[2], 1);

        // Setup: Create Parent Item and attach Routing and Production BOM.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(Item, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        if ItemLedgerEntry.FindLast() then;

        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." += 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := LibraryRandom.RandDec(100, 2);
        ItemLedgerEntry."Location Code" := LibraryUtility.GenerateGUID();
        ItemLedgerEntry."Variant Code" := LibraryUtility.GenerateGUID();
        ItemLedgerEntry."Global Dimension 1 Code" := LibraryUtility.GenerateGUID();
        ItemLedgerEntry."Global Dimension 2 Code" := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateSalesPriceForCampaign(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; CampaignNo: Code[20])
    begin
        // Create Sales Price with random unit price.
        LibraryMarketing.CreateSalesPriceForCampaign(SalesPrice, ItemNo, CampaignNo);
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesPriceForItem(Item: Record Item; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; VariantCode: Code[10]; MinimumQty: Decimal; UnitPrice: Decimal)
    var
        SalesPrice: Record "Sales Price";
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, SalesCode, Item."No.", WorkDate(), '', VariantCode, Item."Base Unit of Measure", MinimumQty);
        SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesLineDiscountForItem(Item: Record Item; SalesCode: Code[20]; VariantCode: Code[10]; MinimumQty: Decimal; LineDiscount: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.",
          SalesLineDiscount."Sales Type"::Customer, SalesCode, WorkDate(), '', VariantCode, Item."Base Unit of Measure", MinimumQty);
        SalesLineDiscount.Validate("Line Discount %", LineDiscount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item)
    var
        ItemComponent: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CreateItemWithUpdatedBaseUnitOfMeasure(
          ItemUnitOfMeasure, Item, '', ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock");
        CreateItem(ItemComponent, '', '', ItemComponent."Manufacturing Policy"::"Make-to-Stock");
        CreateCertifiedProductionBOM(ProductionBOMHeader, ItemUnitOfMeasure.Code, ProductionBOMLine.Type::Item, ItemComponent."No.", 1);
        UpdateProdBOMCodeOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        ItemJournalSetup(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, LibraryRandom.RandDec(10, 2));
        // Value not important.
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndUpdateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; UnitCostRevalued: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemNo);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJournalLine.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    begin
        CreateRouting(RoutingHeader);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithScrap(var RoutingHeader: Record "Routing Header"; ScrapPct: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        CreateRouting(RoutingHeader);

        FindRoutingLine(RoutingLine, RoutingHeader."No.");
        RoutingLine.Validate("Scrap Factor %", ScrapPct);
        RoutingLine.Modify(true);

        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        WorkCenter.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        MachineCenter.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        MachineCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure CreateChildItemWithInventory(ItemJournalBatch: Record "Item Journal Batch"): Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Stock");
        PostItemPositiveAdjmt(
          ItemJournalBatch, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2) + 10);
        exit(Item."No.");
    end;

    local procedure PostItemPositiveAdjmt(ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournal(var ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Integer; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalSetup(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindSet();
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Qty: Decimal)
    begin
        // Create Production Order with small random value.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure ChangeThreeReleasedProdOrdersToFinished(var ProdOrderArray: array[3] of Code[20])
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        ProdOrderItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        QtyPer: Decimal;
        i: Integer;
    begin
        for i := 1 to 3 do begin
            // Create 3 Items
            LibraryInventory.CreateItem(CompItem1);
            LibraryInventory.CreateItem(CompItem2);
            LibraryInventory.CreateItem(ProdOrderItem);
            ProdOrderItem.Validate("Replenishment System", ProdOrderItem."Replenishment System"::"Prod. Order");
            ProdOrderItem.Modify(true);

            // Create BOM
            QtyPer := LibraryRandom.RandInt(10);
            LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem1."No.", CompItem2."No.", QtyPer);

            // Update Item Card
            ProdOrderItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
            ProdOrderItem.Modify(true);

            // Create Production Order
            LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
              ProductionOrder."Source Type"::Item, ProdOrderItem."No.", LibraryRandom.RandInt(10));
            ProdOrderArray[i] := ProductionOrder."No.";

            // Post Item Journal
            CreateItemJournal(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, CompItem1."No.",
              ProductionOrder.Quantity * QtyPer, 15);
            CreateItemJournal(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, CompItem2."No.",
              ProductionOrder.Quantity * QtyPer, 15);
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

            // Refresh Production Order, Post Production Journal and Change the Status to Finished
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.FindFirst();
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

            // Update the WORKDATE
            WorkDate := CalcDate('<+1M>', WorkDate());
        end;
    end;

    local procedure CreateReqLine(ItemNo: Code[20]; Qty: Decimal)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Validate("Due Date", WorkDate());
        RequisitionLine.Modify(true);
    end;

    local procedure GenerateBOMCostTree(var Item: Record Item; var TempBOMBuffer: Record "BOM Buffer" temporary)
    var
        CalcBOMTree: Codeunit "Calculate BOM Tree";
    begin
        CalcBOMTree.GenerateTreeForOneItem(Item, TempBOMBuffer, WorkDate(), "BOM Tree Type"::Cost);
    end;

    local procedure OpenProductionJournal(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Open Production Journal based on selected Production Order Line.
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PurchaseReserveAvailReport(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ShowPurchLines: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, LibraryRandom.RandDec(10, 2));  // Random Values not important.

        // Exercise: Generate the Purchase Reservation Avail. report.
        Commit();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(ShowPurchLines);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Purchase Reservation Avail.", true, false, PurchLine);
    end;

    local procedure RolledUpCostShareReportWithStatus(Status: Enum "BOM Status")
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup: Create Production BOM with component Item and Production BOM Version.
        Initialize();
        CreateProdItemSetup(Item);
        CreateProdBOMVersion(ProductionBOMVersion, Item, Status);

        // Exercise: Run report Rolled-up Cost Shares.
        RunRolledUpCostShareReport(Item."No.");

        // Verify: Verifying component Item exist on Report.
        VerifyComponentItem(Item."Production BOM No.", ProductionBOMVersion."Version Code");
    end;

    local procedure RolledUpCostShareReportWithTypeProdBOM(Status: Enum "BOM Status")
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Run the Rolled Up Cost Shares report with Type Production BOM and check the component item on report when one component is delete from Production BOM Version with Under Development status.

        // Setup: Create Production BOM with component Item and with One Production BOM and Create Production BOM Version.
        Initialize();
        CreateProdItemSetup(Item);
        ProductionBOMHeader.Get(Item."Production BOM No.");
        UpdateProdBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        CreateProdItemSetup(Item2);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", Item2."Production BOM No.",
          LibraryRandom.RandInt(10));
        UpdateProdBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        CreateProdBOMVersion(ProductionBOMVersion, Item, Status);

        // Exercise: Run report Rolled-up Cost Shares.
        RunRolledUpCostShareReport(Item."No.");

        // Verify: Verifying component Item exist on Report.
        VerifyComponentItem(Item."Production BOM No.", ProductionBOMVersion."Version Code");
    end;

    local procedure RunPurchReserveAvailReport(PurchHeaderNo: Code[20]; ShowPurchLines: Boolean; ShowReservationEntries: Boolean; ShowModifyQtytoReceive: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeaderNo);
        LibraryVariableStorage.Enqueue(ShowPurchLines);
        LibraryVariableStorage.Enqueue(ShowReservationEntries);
        LibraryVariableStorage.Enqueue(ShowModifyQtytoReceive);
        REPORT.Run(REPORT::"Purchase Reservation Avail.", true, false, PurchLine);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Expected Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure SalesReserveAvailReport(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShowSalesLines: Boolean)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, LibraryRandom.RandDec(10, 2));  // Random Values not important.

        // Exercise: Generate the Sales Reservation Avail. report.
        Commit();
        RunSalesReservationAvail(SalesHeader."No.", ShowSalesLines, false);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure AutoReserveForSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date; SalesQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, ItemNo, SalesQty);
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure RunSalesReservationAvail(SalesHeaderNo: Code[20]; ShowSalesLines: Boolean; ShowReservationEntries: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        LibraryVariableStorage.Enqueue(ShowSalesLines);
        LibraryVariableStorage.Enqueue(ShowReservationEntries);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Sales Reservation Avail.", true, false, SalesLine);
    end;

    local procedure RunSalesReservationAvailReport(SalesHeaderNo: Code[20]; ShowSalesLines: Boolean; ShowReservationEntries: Boolean; ModifyQtyToShip: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        LibraryVariableStorage.Enqueue(ShowSalesLines);
        LibraryVariableStorage.Enqueue(ShowReservationEntries);
        LibraryVariableStorage.Enqueue(ModifyQtyToShip);
        REPORT.Run(REPORT::"Sales Reservation Avail.", true, false, SalesLine);
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateProdItemSetup(var Item3: Record Item)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item, '', '', Item."Manufacturing Policy"::"Make-to-Stock");
        CreateItem(Item2, '', '', Item2."Manufacturing Policy"::"Make-to-Stock");
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Item."No.", Item2."No.", LibraryRandom.RandInt(10));  // Random Values not important.
        CreateItem(Item3, '', ProductionBOMHeader."No.", Item3."Manufacturing Policy"::"Make-to-Order");
    end;

    local procedure SelectProductionBOMLines(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindSet();
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure RunStatusReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::Status, true, false, Item);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 2 * LibraryRandom.RandInt(10));
    end;

    local procedure UpdateProdBOMVersionLine(ProductionBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProdBOMHeader.Get(ProductionBOMNo);
        ProductionBOMCopy.CopyBOM(ProductionBOMNo, '', ProdBOMHeader, VersionCode);
        ProductionBOMVersion.Get(ProductionBOMNo, VersionCode);
        ProductionBOMVersion.Validate("Unit of Measure Code", ProdBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.FindFirst();
        ProductionBOMLine.Delete();
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; UnitOfMeasureCode: Code[10]; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure RunInventoryValuationWIPReportWithTimePeriod(StartingDate: Date; EndingDate: Date; ProdOrderArray: array[3] of Code[10])
    var
        ProductNoFilter: Code[50];
    begin
        ProductNoFilter := ProdOrderArray[1] + '|' + ProdOrderArray[2] + '|' + ProdOrderArray[3];
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(ProductNoFilter);
        REPORT.Run(REPORT::"Inventory Valuation - WIP");
    end;

    local procedure RunInvtValuationCostSpecReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::"Invt. Valuation - Cost Spec.", true, false, Item);
    end;

    local procedure RunInventoryValuationWIPReport(ProductionOrder: Record "Production Order"; StartingDate: Date; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);
    end;

    local procedure CreateAndPostPurchaseOrderWithUOM(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; ChangeUnitOfMeasure: Boolean)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandDec(10, 2));
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        if ChangeUnitOfMeasure then begin
            CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
            UpdatePurchaseLine(PurchaseLine, ItemUnitOfMeasure.Code, LibraryRandom.RandDec(10, 2));
        end else
            UpdatePurchaseLine(PurchaseLine, Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post with Receive Option.
    end;

    local procedure CreateProdBOMLineWithScrap(ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; Type: Enum "Production BOM Line Type"; No: Code[20]; QtyPer: Decimal; ScrapPct: Decimal)
    begin
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QtyPer);
        ProductionBOMLine.Validate("Scrap %", ScrapPct);
        ProductionBOMLine.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst();
    end;

    local procedure ExplodeOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
    end;

    local procedure ExplodeAndPostOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    begin
        OutputJournalSetup();

        ExplodeOutputJournal(ItemNo, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(OutputItemJournalTemplate.Name, OutputItemJournalBatch.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CalculateAndPostConsumption(ProductionOrder: Record "Production Order")
    begin
        ConsumptionJournalSetup();

        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        Clear(ConsumptionItemJournalTemplate);
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(
          ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        Clear(ConsumptionItemJournalBatch);
        ConsumptionItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type,
          ConsumptionItemJournalTemplate.Name);
    end;

    local procedure PostInventoryCostToGLRun(PostMethod: Option "per Posting Group","per Entry"; Post: Boolean)
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        Commit(); // Required to run the report.

        LibraryVariableStorage.Enqueue(PostMethod);
        LibraryVariableStorage.Enqueue(''); // Blank for Document No..
        LibraryVariableStorage.Enqueue(Post);
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);
    end;

    local procedure PostConsumptionAndOutput(ProdOrderLine: Record "Prod. Order Line"; ComponentItem: Record Item; ProdItemUnitCost: Decimal; ConsumptionQty: Decimal; OutputQty: Decimal; PostingDate: Date)
    begin
        if ConsumptionQty <> 0 then
            LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', ConsumptionQty, PostingDate, ComponentItem."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, OutputQty, PostingDate, ProdItemUnitCost);
    end;

    local procedure RunRolledUpCostShareReport(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Commit();
        REPORT.Run(REPORT::"Rolled-up Cost Shares", true, false, Item);
    end;

    local procedure UpdateProdBOMCodeOnItem(var Item: Record Item; ProdBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateProdBOMStatus(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure VerifyBOMBuffer(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; QtyPerTop: Decimal; ScrapQty: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        BOMBuffer.SetRange("No.", Item."No.");
        BOMBuffer.FindFirst();
        Assert.AreEqual(Round(QtyPerTop + ScrapQty, 0.00001), BOMBuffer."Qty. per Parent", ReportQtyErr);
        Assert.AreEqual(Round(QtyPerTop + ScrapQty, 0.00001), BOMBuffer."Qty. per Top Item", ReportQtyErr);
        Assert.AreEqual(Round(ScrapQty, 0.00001), BOMBuffer."Scrap Qty. per Parent", ReportQtyErr);
        Assert.AreEqual(
          Round(Item."Unit Cost" * Round(ScrapQty, 0.00001), GLSetup."Unit-Amount Rounding Precision"),
          BOMBuffer."Rolled-up Scrap Cost", ReportQtyErr);
        Assert.AreEqual(
          Round(Item."Unit Cost" * (QtyPerTop + Round(ScrapQty, 0.00001)), GLSetup."Unit-Amount Rounding Precision"),
          BOMBuffer."Rolled-up Material Cost", ReportQtyErr);
    end;

    local procedure VerifyStatusReport(PurchaseLine: Record "Purchase Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitCost: Decimal;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.");

        // Verify Item No exist on the Report.
        LibraryReportDataset.LoadDataSetFile();
        UnitCost := LibraryReportDataset.Sum('UnitCost');
        LibraryReportDataset.SetRange('No_Item', PurchaseLine."No.");
        LibraryReportDataset.SetRange('DocumentNo_ItemLedgerEntry', ItemLedgerEntry."Document No.");
        LibraryReportDataset.GetNextRow();

        // Verify Unit Cost on the Report.
        Assert.AreNearlyEqual(PurchaseLine."Direct Unit Cost" / PurchaseLine."Qty. per Unit of Measure", UnitCost,
          LibraryERM.GetAmountRoundingPrecision(), 'Wrong unit cost in report.');

        // Verify Quantity on the Report.
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', PurchaseLine."Quantity (Base)");
    end;

    local procedure VerifyInventoryValuationCostSpecReport(PurchaseLine: Record "Purchase Line")
    var
        UnitCost: Decimal;
    begin
        // Verify Item No exist on the Report.
        LibraryReportDataset.LoadDataSetFile();
        UnitCost := LibraryReportDataset.Sum('UnitCost1');
        LibraryReportDataset.SetRange('No_Item', PurchaseLine."No.");
        LibraryReportDataset.GetNextRow();

        // Verify Direct Unit Cost, quantity and line amount on the Report.
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCostTotal1', PurchaseLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', PurchaseLine.Quantity);
        Assert.AreNearlyEqual(PurchaseLine."Unit Cost (LCY)", UnitCost, LibraryERM.GetAmountRoundingPrecision(), DirectUnitCostErr);
    end;

    local procedure VerifyComponentItem(ProductionBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('ProdBOMLineIndexNo', ProductionBOMLine."No.");
        until ProductionBOMLine.Next() = 0;
    end;

    local procedure VerifyCostPostedToGL(ProductionOrderNo: Code[20]; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrderNo);
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueEntryCostPostedtoGL', GLEntry.Amount);
    end;

    local procedure VerifySalesReservationAvailReport(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20]; LineQtyOnHand: Decimal; LineStatus: Text)
    var
        DocTypeAndNo: Text;
    begin
        LibraryReportDataset.LoadDataSetFile();
        SelectSalesLine(SalesLine, SalesHeaderNo);
        DocTypeAndNo := StrSubstNo('%1 %2', Format(SalesLine."Document Type"), Format(SalesLine."Document No."));
        LibraryReportDataset.SetRange('StrsubstnoDocTypeDocNo', DocTypeAndNo);
        LibraryReportDataset.AssertElementWithValueExists('LineQuantityOnHand', LineQtyOnHand);
        LibraryReportDataset.AssertElementWithValueExists('LineStatus', LineStatus);
    end;

    local procedure VerifyQtyToReceiveInPurchLine(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchLine, PurchHeader."No.");
        Assert.AreEqual(0, PurchLine."Qty. to Receive", MsgQtytoReceiveErr);
    end;

    local procedure ValidateInventoryValuationWIPReport(var ProdOrderArray: array[3] of Code[10])
    begin
        LibraryReportDataset.LoadDataSetFile();

        asserterror LibraryReportDataset.AssertElementWithValueExists('No_ProductionOrder', ProdOrderArray[1]);
        asserterror LibraryReportDataset.AssertElementWithValueExists('No_ProductionOrder', ProdOrderArray[2]);
        LibraryReportDataset.AssertElementWithValueExists('No_ProductionOrder', ProdOrderArray[3]);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProdJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ProdOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProdOrderNo);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.FindFirst();
        ItemJnlPostLine.RunWithCheck(ItemJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPRequestPageHandler(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    var
        StartingDate: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        InventoryValuationWIP.StartingDate.SetValue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        InventoryValuationWIP.EndingDate.SetValue(EndingDate);
        InventoryValuationWIP.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageTest: Text[1024])
    begin
        // Dummy message Handler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PriceListRequestPageHandler(var PriceList: TestRequestPage "Price List")
    var
        DateReq: Variant;
        SalesType: Variant;
        SalesCode: Variant;
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateReq);
        PriceList.Date.SetValue(DateReq);
        LibraryVariableStorage.Dequeue(SalesType);
        PriceList.SalesType.SetValue(SalesType); // Sales Type: Customer,Customer Price Group,All Customers,Campaign.
        LibraryVariableStorage.Dequeue(SalesCode);
        PriceList.SalesCodeCtrl.SetValue(SalesCode);
        LibraryVariableStorage.Dequeue(CurrencyCode);
        PriceList."Currency.Code".SetValue(CurrencyCode);
        PriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPostingTestRequestPageHandler(var InventoryPostingTest: TestRequestPage "Inventory Posting - Test")
    begin
        InventoryPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    procedure InvtValCostSpecWithFiltersPageHandler(var InvtValuationCostSpec: TestRequestPage "Invt. Valuation - Cost Spec.")
    begin
        InvtValuationCostSpec.ValuationDate.SetValue(WorkDate());
        InvtValuationCostSpec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValCostSpecRequestPageHandler(var InvtValuationCostSpec: TestRequestPage "Invt. Valuation - Cost Spec.")
    var
        ValuationDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ValuationDate);
        InvtValuationCostSpec.ValuationDate.SetValue(ValuationDate);
        InvtValuationCostSpec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchResAvailRequestPageHandler(var PurchaseReservationAvail: TestRequestPage "Purchase Reservation Avail.")
    var
        ShowPurchaseLines: Variant;
        ShowResEntries: Variant;
        ModifyQtyToShip: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowPurchaseLines);
        PurchaseReservationAvail.ShowPurchLine.SetValue(ShowPurchaseLines);
        LibraryVariableStorage.Dequeue(ShowResEntries);
        PurchaseReservationAvail.ShowReservationEntries.SetValue(ShowResEntries);
        LibraryVariableStorage.Dequeue(ModifyQtyToShip);
        PurchaseReservationAvail.ModifyQtuantityToShip.SetValue(ModifyQtyToShip);
        PurchaseReservationAvail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesResAvailRequestPageHandler(var SalesReservationAvail: TestRequestPage "Sales Reservation Avail.")
    var
        ShowSalesLines: Variant;
        ShowResEntries: Variant;
        ModifyQtyToShip: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowSalesLines);
        SalesReservationAvail.ShowSalesLines.SetValue(ShowSalesLines);
        LibraryVariableStorage.Dequeue(ShowResEntries);
        SalesReservationAvail.ShowReservationEntries.SetValue(ShowResEntries);
        LibraryVariableStorage.Dequeue(ModifyQtyToShip);
        SalesReservationAvail.ModifyQuantityToShip.SetValue(ModifyQtyToShip);
        SalesReservationAvail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesRequestPageHandler(var RolledUpCostShares: TestRequestPage "Rolled-up Cost Shares")
    begin
        RolledUpCostShares.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SglLevelCostSharesRequestPageHandler(var SingleLevelCostShares: TestRequestPage "Single-level Cost Shares")
    begin
        SingleLevelCostShares.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DetailedCalculationRequestPageHandler(var DetailedCalculation: TestRequestPage "Detailed Calculation")
    begin
        DetailedCalculation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedTopLevelRequestPageHandler(var WhereUsedTopLevel: TestRequestPage "Where-Used (Top Level)")
    begin
        WhereUsedTopLevel.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityRequestPageHandler(var InventoryAvailability: TestRequestPage "Inventory Availability")
    begin
        InventoryAvailability.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure GenericConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var InventoryValuationWIPRep: TestRequestPage "Inventory Valuation - WIP")
    var
        StartingDate: Variant;
        EndingDate: Variant;
        ProductNoFilter: Variant;
    begin
        // Set the Starting Date and Ending Date in the report Inventory Valuation WIP.
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(ProductNoFilter);
        InventoryValuationWIPRep.StartingDate.SetValue(StartingDate);
        InventoryValuationWIPRep.EndingDate.SetValue(EndingDate);
        InventoryValuationWIPRep."Production Order".SetFilter(Status, StatusConstantCap);
        InventoryValuationWIPRep."Production Order".SetFilter("No.", ProductNoFilter);

        InventoryValuationWIPRep.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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

    local procedure VerifyInventoryAvailabilityReport(ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PlannedOrderReceipt', Qty);
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvailBalance', Qty);
    end;

    local procedure VerifyLibraryReportDatasetQuantity(ExpectedQty: Decimal; ItemNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        Assert.AreEqual(ExpectedQty, LibraryReportDataset.Sum('RemainingQty'), ReportQtyErr);
    end;

    local procedure SetLimitsTotalsFilterOnItem(var Item: Record Item; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        Item.SetRange("Location Filter", ItemLedgerEntry."Location Code");
        Item.SetRange("Variant Filter", ItemLedgerEntry."Variant Code");
        Item.SetRange("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
        Item.SetRange("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}
