codeunit 137303 "SCM Order Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SCM]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('WorkOrderRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise : Generate the Work Order report.
        Commit();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Work Order", true, false, SalesHeader);

        // Verify : Check the value of quantity.
        VerifyQuantityOnWorkOrderReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmationRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmationReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // Exercise : Generate the Return Order Confirmation report.
        Commit();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Return Order Confirmation", true, false, SalesHeader);

        // Verify : Check the value of Quantity.
        VerifyQuantityOnReturnOrderConfReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ReturnOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Purchase Return Order.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        // Exercise : Generate the Return Order report.
        Commit();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        REPORT.Run(REPORT::"Return Order", true, false, PurchaseHeader);

        // Verify : Check the value of Quantity and Item No.
        VerifyReturnOrder(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('BinCreationWorksheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetReport()
    var
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // Setup : Create Bin Creation Worksheet Line.
        Initialize();
        CreateBinCreationWorksheetLine(BinCreationWorksheetLine);

        // Exercise : Generate the Bin Creation Worksheet Report.
        Commit();
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWorksheetLine."Worksheet Template Name");
        BinCreationWorksheetLine.SetRange(Name, BinCreationWorksheetLine.Name);
        BinCreationWorksheetLine.SetRange("Line No.", BinCreationWorksheetLine."Line No.");
        REPORT.Run(REPORT::"Bin Creation Wksh. Report", true, false, BinCreationWorksheetLine);

        // Verify : Check the value of Maximum Volume.
        VerifyBinCreationWorksheet(BinCreationWorksheetLine);
    end;

    [Test]
    [HandlerFunctions('PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhyInventoryNotQtyCalculated()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup : Create Item Journal Line.
        Initialize();
        CreateAndModifyItemJournalLine(ItemJournalLine);

        // Exercise : Generate Physical Inventory List.
        GeneratePhysicalInventory(ItemJournalLine, false);

        // Verify : Check the value of Location Code.
        VerifyLocationCode(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryQtyCalculated()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup : Create Item Journal Line.
        Initialize();
        CreateAndModifyItemJournalLine(ItemJournalLine);

        // Exercise : Generate Physical Inventory List.
        GeneratePhysicalInventory(ItemJournalLine, true);

        // Verify : Check the value of Quantity Calculated and Location Code.
        VerifyPhysicalInventory(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('InventoryMovementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementWithBlank()
    var
        ItemJournalLine: Record "Item Journal Line";
        ActivityType: Option " ","Put-away",Pick,Movement;
    begin
        InventoryMovementReport(ItemJournalLine."Entry Type"::Purchase, ActivityType::" ");
    end;

    [Test]
    [HandlerFunctions('InventoryMovementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementPick()
    var
        ItemJournalLine: Record "Item Journal Line";
        ActivityType: Option " ","Put-away",Pick,Movement;
    begin
        InventoryMovementReport(ItemJournalLine."Entry Type"::Purchase, ActivityType::"Put-away");
    end;

    [Test]
    [HandlerFunctions('InventoryMovementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementPutAway()
    var
        ItemJournalLine: Record "Item Journal Line";
        ActivityType: Option " ","Put-away",Pick,Movement;
    begin
        InventoryMovementReport(ItemJournalLine."Entry Type"::Sale, ActivityType::Pick);
    end;

    [Normal]
    local procedure InventoryMovementReport(EntryType: Enum "Item Ledger Document Type"; ActivityType: Option " ","Put-away",Pick,Movement)
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Setup: Create Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.", EntryType);

        // Exercise : Generate the Inventory Movement Report.
        Commit();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(ActivityType);
        REPORT.Run(REPORT::"Inventory Movement", true, false, ItemJournalLine);

        // Verify : Check the value of Quantity and Item No.
        VerifyInventoryMovement(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('CompareProductionCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionBOMCompareProductionCostSharesReport()
    var
        Item: array[4] of Record Item;
        "Count": Integer;
    begin
        // Setup : Create Item  Array.
        Initialize();
        for Count := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[Count]);
            Item[Count].Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
            Item[Count].Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            Item[Count].Validate("Replenishment System", Item[Count]."Replenishment System"::Purchase);
            Item[Count].Modify(true);
        end;

        // Exercise : Create Two Production BOM with Item array. Generate Compare Production Cost Shares Report.
        CreateProductionBOMAndLine(Item, 1);
        CreateProductionBOMAndLine(Item, 2);
        Commit();
        LibraryVariableStorage.Enqueue(Item[1]."No.");
        LibraryVariableStorage.Enqueue(Item[2]."No.");
        Report.Run(Report::"Compare Production Cost Shares", true, false);

        // Verify: Check that the value of Unit Cost in Compare Production Cost Shares is equal to the value of Unit Cost in corresponding Production
        // BOM Item. Check that Exploded Quantity.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCompareProductionCostSharesReport(Item[3]);
        VerifyCompareProductionCostSharesReport(Item[4]);
    end;

    [Test]
    [HandlerFunctions('CompareProductionCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionBOMWithVersionCompareProductionCostSharesReport()
    var
        Item1: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418989] There are no any errors if "Production BOM Version"."Version Code" has length 20
        Initialize();

        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item1."Base Unit of Measure");
        Item1.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item1.Modify(true);

        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.",
            LibraryUtility.GenerateRandomCode20(ProductionBOMVersion.FieldNo("Version Code"), Database::"Production BOM Version"),
            ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item2."Base Unit of Measure");
        Item2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item2.Modify(true);

        Commit();
        LibraryVariableStorage.Enqueue(Item1."No.");
        LibraryVariableStorage.Enqueue(Item2."No.");
        Report.Run(Report::"Compare Production Cost Shares", true, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Reports");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Reports");
    end;

    [Normal]
    local procedure CreateAndModifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Create Item, Create Item JOurnal Batch, Create Item Journal Line.
        LibraryInventory.CreateItem(Item);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.", ItemJournalLine."Entry Type"::Purchase);
        ItemJournalLine.Validate("Phys. Inventory", true);
        ItemJournalLine.Modify(true);
    end;

    [Normal]
    local procedure CreateBinCreationWorksheetLine(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    var
        Bin: Record Bin;
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        Location: Record Location;
    begin
        // Taking Random value for Maximum Cubage and Maximum Weight.
        BinCreationWkshTemplate.SetRange(Type, BinCreationWkshTemplate.Type::Bin);
        BinCreationWkshTemplate.FindFirst();
        BinCreationWkshName.FindFirst();
        Location.SetRange("Bin Mandatory", true);
        Location.FindFirst();
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        LibraryWarehouse.CreateBinCreationWorksheetLine(
          BinCreationWorksheetLine, BinCreationWkshTemplate.Name, BinCreationWkshName.Name, Location.Code, Bin.Code);
        BinCreationWorksheetLine.Validate("Maximum Cubage", LibraryRandom.RandDec(100, 2));
        BinCreationWorksheetLine.Validate("Maximum Weight", LibraryRandom.RandDec(100, 2));
        BinCreationWorksheetLine.Modify(true);
    end;

    [Normal]
    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    [Normal]
    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    var
        Location: Record Location;
    begin
        // Taking Random value for Quantity.
        Location.FindFirst();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
    end;

    [Normal]
    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        // Taking Random value for Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    [Normal]
    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        // Taking Random value for Quantity.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateProductionBOMAndLine(var Item: array[4] of Record Item; "Count": Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        I: Integer;
    begin
        // Create Production BOM Header and two Production BOM Line.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[Count]."Base Unit of Measure");
        Item[Count].Validate("Replenishment System", Item[Count]."Replenishment System"::"Prod. Order");
        Item[Count].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[Count].Modify(true);

        // Create two Line of Production BOM With Random Quantity. Taking Random value for Quantity.
        for I := 1 to 2 do
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
              Item[I + Count]."No.", LibraryRandom.RandInt(10));
    end;

    [Normal]
    local procedure GeneratePhysicalInventory(var ItemJournalLine: Record "Item Journal Line"; ShowQtyCalculated: Boolean)
    begin
        Commit();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(ShowQtyCalculated);
        REPORT.Run(REPORT::"Phys. Inventory List", true, false, ItemJournalLine);
    end;

    [Normal]
    local procedure VerifyBinCreationWorksheet(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('BinCode_BinCreateWkshLine', BinCreationWorksheetLine."Bin Code");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('MaxCubage_BinCreateWkshLine', BinCreationWorksheetLine."Maximum Cubage");
    end;

    [Normal]
    local procedure VerifyInventoryMovement(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ItemJournalLine', ItemJournalLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ItemJournalLine', ItemJournalLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_ItemJournalLine', ItemJournalLine."Location Code");
    end;

    [Normal]
    local procedure VerifyPhysicalInventory(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ItemJournalLine', ItemJournalLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', ItemJournalLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyCalculated_ItemJnlLin', ItemJournalLine."Qty. (Calculated)");
    end;

    [Normal]
    local procedure VerifyLocationCode(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ItemJournalLine', ItemJournalLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', ItemJournalLine."Location Code");
    end;

    [Normal]
    local procedure VerifyQuantityOnWorkOrderReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesLine', Format(SalesLine."No."));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_SalesLine', SalesLine.Quantity);
    end;

    [Normal]
    local procedure VerifyQuantityOnReturnOrderConfReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No2_SalesLine', Format(SalesLine."No."));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesLine', SalesLine.Quantity);
    end;

    [Normal]
    local procedure VerifyReturnOrder(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_PurchLine', PurchaseLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_PurchLine', PurchaseLine.Quantity);
    end;

    local procedure VerifyCompareProductionCostSharesReport(var Item: Record Item)
    begin
        LibraryReportDataset.SetRange('No', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item2UnitCost', Item."Unit Cost");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item1UnitCost', Item."Unit Cost");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmationRepRequestPageHandler(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName(),
          LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkOrderRepRequestPageHandler(var WorkOrder: TestRequestPage "Work Order")
    begin
        WorkOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderRequestPageHandler(var ReturnOrder: TestRequestPage "Return Order")
    begin
        ReturnOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetRequestPageHandler(var BinCreationWkshReport: TestRequestPage "Bin Creation Wksh. Report")
    begin
        BinCreationWkshReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompareProductionCostSharesRequestPageHandler(var CompareProductionCostShares: TestRequestPage "Compare Production Cost Shares")
    var
        ItemNo1: Variant;
        ItemNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo1);
        LibraryVariableStorage.Dequeue(ItemNo2);

        CompareProductionCostShares.ItemNo1.SetValue(ItemNo1);
        CompareProductionCostShares.ItemNo2.SetValue(ItemNo2);

        CompareProductionCostShares.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryMovementRequestPageHandler(var InventoryMovement: TestRequestPage "Inventory Movement")
    var
        ActivityType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActivityType);
        InventoryMovement.ActivityType.SetValue(ActivityType);
        InventoryMovement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryListRequestPageHandler(var PhysInventoryList: TestRequestPage "Phys. Inventory List")
    var
        ShowQtyCalculated: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowQtyCalculated);
        PhysInventoryList.ShowCalculatedQty.SetValue(ShowQtyCalculated);

        PhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

