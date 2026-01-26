codeunit 141010 "UT REP Intercompany"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ItemNoLbl: Label 'Item__No__';
        DialogErr: Label 'Dialog';
        PurchaseLbl: Label 'PurchasesText';
        QuantityLbl: Label 'QtyText';
        ItemLedgerEntrySourceNoLbl: Label 'Item_Ledger_Entry__Source_No__';
        ValuesAsOfLbl: Label 'Values As Of %1';
        QuantitiesAndValuesLbl: Label 'Quantities and Values As Of %1';
        SubTitleLbl: Label 'SubTitle';
        ItemFilterTxt: Label '%1|%2', Comment = '%1=Field value,%2=Field value';
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [HandlerFunctions('InventoryLabelsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemNoOfLabelsOneItemInvtLabels()
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord on Report ID - 10137 Inventory Labels.
        Initialize();
        OnAfterGetRecordNoOfLabelsPerRowItemInvtLabels(1);  // Labels Per Row - 1(Minimum limit).
    end;

    [Test]
    [HandlerFunctions('InventoryLabelsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemNoOfLabelsInRangeItemInvtLabels()
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord on Report ID - 10137 Inventory Labels.
        Initialize();
        OnAfterGetRecordNoOfLabelsPerRowItemInvtLabels(LibraryRandom.RandIntInRange(2, 3));  // Labels Per Row in Range 2 to 3(Maximum limit).
    end;

    local procedure OnAfterGetRecordNoOfLabelsPerRowItemInvtLabels(LabelsPerRow: Integer)
    var
        Item: Record Item;
    begin
        // Setup: Create Item.
        CreateItem(Item);

        // Enqueue values for handler - InventoryLabelsRequestPageHandler.
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(LabelsPerRow);

        // Exercise.
        REPORT.Run(REPORT::"Inventory Labels");  // Opens handler - InventoryLabelsRequestPageHandler.

        // Verify: Verify Item No, Item Shelf No and Labels Per Row on Report - Inventory Labels.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ItemNo_1_', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('ItemShelf_1_', Item."Shelf No.");
        LibraryReportDataset.AssertElementWithValueExists('LabelsPerRow', LabelsPerRow);
    end;

    [Test]
    [HandlerFunctions('ItemCommentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCommentLineWithoutItemCommentList()
    begin
        // Purpose of the test is to validate Comment Line - OnAfterGetRecord Trigger of Report ID - 10141 Item Comment List.
        // Setup.
        Initialize();
        OnAfterGetRecordCommentLineItemCommentList('', 'No Item Description');  // Blank Item No and Item Description text.
    end;

    [Test]
    [HandlerFunctions('ItemCommentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCommentLineWithItemCommentList()
    var
        Item: Record Item;
    begin
        // Purpose of the test is to validate Comment Line - OnAfterGetRecord Trigger of Report ID - 10141 Item Comment List.
        // Setup.
        Initialize();
        CreateItem(Item);
        OnAfterGetRecordCommentLineItemCommentList(Item."No.", Item.Description);  // Item No and Item Description.
    end;

    local procedure OnAfterGetRecordCommentLineItemCommentList(ItemNo: Code[20]; Description: Text)
    begin
        // Create Comment Line.
        CreateCommentLineForItem(ItemNo);

        // Exercise.
        REPORT.Run(REPORT::"Item Comment List");  // Opens ItemCommentListRequestPageHandler.

        // Verify: Verify Item Description and Comment Line number on Report - Item Comment List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Item_Description', Description);
        LibraryReportDataset.AssertElementWithValueExists('Comment_Line__No__', ItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithoutSourceCodeItemRegister()
    begin
        // Purpose of the test is to validate Item Register - OnAfterGetRecord of Report ID - 10144 Item Register.
        Initialize();
        OnAfterGetRecordSourceCodeItemRegister(0, '', '');  // Blank Value for Quantity, Source Code and Source Code text.
    end;

    [Test]
    [HandlerFunctions('ItemRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithSourceCodeItemRegister()
    begin
        // Purpose of the test is to validate Item Register - OnAfterGetRecord of Report ID - 10144 Item Register.
        Initialize();
        OnAfterGetRecordSourceCodeItemRegister(LibraryRandom.RandDec(10, 2), LibraryUTUtility.GetNewCode10(), 'Source Code: ');  // Value for Quantity, Source Code and Source Code text.
    end;

    local procedure OnAfterGetRecordSourceCodeItemRegister(Quantity: Decimal; SourceCode: Code[10]; SourceCodeText: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
    begin
        // Setup: Create Item Ledger Entry, Item Register, Value Entry.
        CreateItemLedgerEntry(ItemLedgerEntry, LibraryUTUtility.GetNewCode(), Quantity, WorkDate());
        CreateItemRegister(ItemLedgerEntry."Entry No.", SourceCode);
        CostAmountActual := CreateValueEntry(ItemLedgerEntry);

        // Exercise.
        REPORT.Run(REPORT::"Item Register");  // Opens handler - ItemRegisterRequestPageHandler.

        // Verify: Verify Source Code Text, Invoiced Quantity, and Cost Amount Actual on Report - Item Register.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Item_Ledger_Entry__Invoiced_Quantity_', ItemLedgerEntry."Invoiced Quantity");
        LibraryReportDataset.AssertElementWithValueExists('Item_Ledger_Entry__Cost_Amount__Actual__', CostAmountActual);
        LibraryReportDataset.AssertElementWithValueExists('SourceCodeText', SourceCodeText + SourceCode)
    end;

    [Test]
    [HandlerFunctions('LocationListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLocationList()
    var
        LocationCode: Code[10];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10149 Location List.

        // Setup: Create location.
        Initialize();
        LocationCode := CreateLocation();

        // Exercise.
        REPORT.Run(REPORT::"Location List");  // Opens handler - LocationListRequestPageHandler.

        // Verify: Verify Location code and Location Name on Report - Location List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Location_Code', LocationCode);
        LibraryReportDataset.AssertElementWithValueExists('Location_Name', LocationCode);
    end;

    [Test]
    [HandlerFunctions('OverStockRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithoutStockkeepingUnitOverStock()
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord Trigger of Report ID - 10150 Over Stock.
        Initialize();
        OnAfterGetRecordItemOverStock(false);  // UseStockKeepingUnit - False on Report - Over Stock.
    end;

    [Test]
    [HandlerFunctions('OverStockRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithStockkeepingUnitOverStock()
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord Trigger of Report ID - 10150 Over Stock.
        Initialize();
        OnAfterGetRecordItemOverStock(true);  // UseStockKeepingUnit - TRUE on Report - Over Stock.
    end;

    local procedure OnAfterGetRecordItemOverStock(UseStockKeepingUnit: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup: Create Item, Item Ledger Entry and Stockkeeping Unit.
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CreateStockkeepingUnit(Item."No.");
        LibraryVariableStorage.Enqueue(UseStockKeepingUnit);  // Enqueue value in handler - OverStockRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Over Stock");

        // Verify: Verify Item No, Use Stock Keeping Unit and Quantity on Report - Over Stock.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoLbl, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('UseSKU', UseStockKeepingUnit);
        LibraryReportDataset.AssertElementWithValueExists('QuantityOver', ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryCountRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysicalInventoryCount()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemShelfNo: Code[10];
    begin
        // Purpose of the test is to validate Item Journal Line - OnAfterGetRecord Trigger of Report ID - 10151 Physical Inventory Count.

        // Setup: Create Item, Stockkeeping Unit, Item Journal Line.
        Initialize();
        CreateItem(Item);
        ItemShelfNo := CreateStockkeepingUnit(Item."No.");
        CreateItemJournalTemplateAndBatch(ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");

        // Exercise.
        REPORT.Run(REPORT::"Physical Inventory Count");  // Opens handler - PhysicalInventoryCountRequestPageHandler.

        // Verify: Verify Item Journal Template Name, Item Journal Batch Name and Item Shelf No on Report - Physical Inventory Count.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Item_Journal_Batch_Journal_Template_Name', ItemJournalLine."Journal Template Name");
        LibraryReportDataset.AssertElementWithValueExists('Item_Journal_Line_Journal_Batch_Name', ItemJournalLine."Journal Batch Name");
        LibraryReportDataset.AssertElementWithValueExists('Item__Shelf_No__', ItemShelfNo);
    end;

    [Test]
    [HandlerFunctions('SerialNumberStatusAgingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSerialNumberStatusAging()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
    begin
        // Purpose of the test is to validate Item Ledger Entry - OnAfterGetRecord Trigger of Report ID - 10161 Serial Number Status/Aging.

        // Setup: Create Item, Item Ledger Entry and Value Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2),
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D' + '>', WorkDate()));  // Posting Date before WORKDATE is required.
        CostAmountActual := CreateValueEntry(ItemLedgerEntry);

        // Exercise.
        REPORT.Run(REPORT::"Serial Number Status/Aging");  // Opens handler - SerialNumberStatusAgingRequestPageHandler.

        // Verify: Verify Item No, Unit Cost and Days Aged on Report - Serial Number Status/Aging.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoLbl, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('UnitCost', CostAmountActual / ItemLedgerEntry.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('DaysAged', WorkDate() - ItemLedgerEntry."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ItemVendorCatalogRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSortOrderByVendorItemVendorCatalog()
    var
        ItemVendor: Record "Item Vendor";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10164 Item/Vendor Catalog.

        // Setup: Create Item Vendor. SETCURRENTKEY - Vendor No, Item No, Variant Code on table - Item Vendor.
        Initialize();
        CreateItemVendor(ItemVendor, LibraryUTUtility.GetNewCode(), CreateVendor());
        ItemVendor.SetCurrentKey("Vendor No.", "Item No.", "Variant Code");
        ItemVendor.SetRange("Vendor No.", ItemVendor."Vendor No.");

        // Exercise.
        RunItemVendorCatalogReport(ItemVendor);  // Opens handler - ItemVendorCatalogRequestPageHandler.

        // Verify: Verify Sorting Order - By Item, Item No and Vendor No on Report - Item/Vendor Catalog.
        VerifyItemVendorSortOrder('Items for each Vendor', ItemVendor."Item No.", ItemVendor."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('ItemVendorCatalogRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSortOrderByItemVendorCatalog()
    var
        ItemVendor: Record "Item Vendor";
        Item: Record Item;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10164 Item/Vendor Catalog.

        // Setup: Create Item Vendor. SETCURRENTKEY - Item No, Variant Code, Vendor No on table - Item Vendor.
        Initialize();
        CreateItem(Item);
        CreateItemVendor(ItemVendor, Item."No.", LibraryUTUtility.GetNewCode());
        ItemVendor.SetCurrentKey("Item No.", "Variant Code", "Vendor No.");
        ItemVendor.SetRange("Item No.", ItemVendor."Item No.");

        // Exercise.
        RunItemVendorCatalogReport(ItemVendor);  // Opens handler - ItemVendorCatalogRequestPageHandler.

        // Verify: Verify Sorting Order - By Vendor, Item No and Vendor No on Report - Item/Vendor Catalog.
        VerifyItemVendorSortOrder('Vendors for each Item', ItemVendor."Item No.", ItemVendor."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileErrorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAsOfDateInventoryToGLReconcileError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10138 Inventory to G/L Reconcile.
        Initialize();
        OnPreReportAsOfDateError(REPORT::"Inventory to G/L Reconcile");
    end;

    [Test]
    [HandlerFunctions('InventoryValuationlErrorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAsOfDateInventoryValuationError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10139 Inventory Valuation.
        Initialize();
        OnPreReportAsOfDateError(REPORT::"Inventory Valuation");
    end;

    local procedure OnPreReportAsOfDateError(ReportID: Integer)
    begin
        // Setup.
        LibraryVariableStorage.Enqueue(0D);  // As of Date - 0D. Enqueue value for Request Page Handler.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Opens handler - InventoryValuationlErrorRequestPageHandler or InventoryToGLReconcileErrorRequestPageHandler.

        // Verify: Verify Error Code, Actual error - You must enter an As Of Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithoutAddReportingCurrencyInvtToGLReconcile()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10138 Inventory to G/L Reconcile.
        Initialize();
        OnPreReportAdditionalReportingCurrency(REPORT::"Inventory to G/L Reconcile", '', false, ValuesAsOfLbl);  // Blank value for Currency and Use Additional Reporting Currency - False
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithoutAddReportingCurrencyInvtValuation()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10139 Inventory Valuation.
        Initialize();
        OnPreReportAdditionalReportingCurrency(REPORT::"Inventory Valuation", '', false, QuantitiesAndValuesLbl);  // Blank value for Currency and Use Additional Reporting Currency - False
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithAddReportingCurrencyInvtToGLReconcile()
    begin
        // Purpose of the test is to validate  OnPreReport Trigger Of Report ID - 10138 Inventory to G/L Reconcile.
        Initialize();
        OnPreReportAdditionalReportingCurrency(REPORT::"Inventory to G/L Reconcile", CreateCurrency(), true, ValuesAsOfLbl);  // Use Additional Reporting Currency - True
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithAddReportingCurrencyInvtValuation()
    begin
        // Purpose of the test is to validate OnPreReport Trigger Of Report ID - 10139 Inventory Valuation.
        Initialize();
        OnPreReportAdditionalReportingCurrency(REPORT::"Inventory Valuation", CreateCurrency(), true, QuantitiesAndValuesLbl);  // Use Additional Reporting Currency - True
    end;

    local procedure OnPreReportAdditionalReportingCurrency(ReportID: Integer; AdditionalReportingCurrency: Code[10]; UseAdditionalReportingCurrency: Boolean; ValuesAsOfText: Text)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
    begin
        // Setup: Update General Ledger Setup. Create Item, Item Ledger Entry and Value Entry.
        UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency);
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CostAmountActual := CreateValueEntry(ItemLedgerEntry);
        LibraryVariableStorage.Enqueue(UseAdditionalReportingCurrency);  // Enqueue value - InventoryToGLReconcileRequestPageHandler, InventoryValuationRequestPageHandler.

        // Exercise.
        REPORT.Run(ReportID);  // Opens handler - InventoryToGLReconcileRequestPageHandler, InventoryValuationRequestPageHandler

        // Verify: Verify Addition Reporting Currency, Inventory value and Posting Date on Report - Inventory to G/L Reconcile or Inventory Valuation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ShowACY', UseAdditionalReportingCurrency);
        LibraryReportDataset.AssertElementWithValueExists('InventoryValue', CostAmountActual);
        LibraryReportDataset.AssertElementWithValueExists(
          'STRSUBSTNO_Text003_AsOfDate_', StrSubstNo(ValuesAsOfText, ItemLedgerEntry."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('VendorPurchasesByItemRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorPurchasesByItem()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Purpose of the test is to validate OnPreReport Of Report ID - 10163 Vendor Purchases by Item.

        // Setup: Create Item, Item Ledger Entry and Value Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CreateValueEntry(ItemLedgerEntry);

        // Exercise.
        REPORT.Run(REPORT::"Vendor Purchases by Item");  // Opens handler - VendorPurchasesByItemRequestPageHandler.

        // Verify:
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleLbl, 'All Purchases to Date');
        LibraryReportDataset.AssertElementWithValueExists(ItemNoLbl, ItemLedgerEntry."Item No.");
    end;

    [Test]
    [HandlerFunctions('VendorPurchasesByItemMaximumPurchasesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorMaximumPurchasesPurchasesByItem()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
        MaximumPurchaseAmount: Decimal;
        MaximumPurchaseQuantity: Decimal;
    begin
        // Purpose of the test is to validate OnPreReport Of Report ID - 10163 Vendor Purchases by Item.

        // Setup: Create Item, Item Ledger Entry and Value Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDecInRange(10, 100, 2), WorkDate());
        CostAmountActual := CreateValueEntry(ItemLedgerEntry);
        MaximumPurchaseAmount := CostAmountActual + LibraryRandom.RandDec(10, 2);  // Random value added to make MaximumPurchaseAmount greater than Purchases (LCY) of Item.
        MaximumPurchaseQuantity := ItemLedgerEntry."Invoiced Quantity" + LibraryRandom.RandDec(10, 2);  // Random value added to make MaximumPurchaseQuantity greater than Purchases (Qty.) of Item.

        // Enqueue values for handler - VendorPurchasesByItemMaximumPurchasesRequestPageHandler.
        LibraryVariableStorage.Enqueue(MaximumPurchaseAmount);
        LibraryVariableStorage.Enqueue(MaximumPurchaseQuantity);

        // Exercise.
        REPORT.Run(REPORT::"Vendor Purchases by Item");  // Opens handler - VendorPurchasesByItemMaximumPurchasesRequestPageHandler.

        // Verify: Verify Maximum Purchase Amount, Maximum Purchase Quantity and Source No on Report - Vendor Purchases by Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          PurchaseLbl, StrSubstNo('Items with Net Purchases of less than $%1', MaximumPurchaseAmount));
        LibraryReportDataset.AssertElementWithValueExists(
          QuantityLbl, StrSubstNo('Items with Net Purchase Quantity less than %1', MaximumPurchaseQuantity));
        LibraryReportDataset.AssertElementWithValueExists(ItemLedgerEntrySourceNoLbl, ItemLedgerEntry."Source No.");
    end;

    [Test]
    [HandlerFunctions('VendorPurchasesByItemMinimumPurchasesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorMinimumPurchasesPurchasesByItem()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
        MinimumPurchaseAmount: Decimal;
        MinimumPurchaseQuantity: Decimal;
    begin
        // Purpose of the test is to validate OnPreReport Of Report ID - 10163 Vendor Purchases by Item.

        // Setup: Create Item, Item Ledger Entry and Value Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDecInRange(10, 100, 2), WorkDate());
        CostAmountActual := CreateValueEntry(ItemLedgerEntry);
        MinimumPurchaseAmount := CostAmountActual - LibraryRandom.RandDec(10, 2);  // Random value subtracted to make MinimumPurchaseAmount less than Purchases (LCY) of Item.
        MinimumPurchaseQuantity := ItemLedgerEntry."Invoiced Quantity" - LibraryRandom.RandDec(10, 2);  // Random value subtracted to make MinimumPurchaseQuantity less than Purchases (Qty.) of Item.

        // Enqueue values for handler - VendorPurchasesByItemMinimumPurchasesRequestPageHandler.
        LibraryVariableStorage.Enqueue(MinimumPurchaseAmount);
        LibraryVariableStorage.Enqueue(MinimumPurchaseQuantity);

        // Exercise.
        REPORT.Run(REPORT::"Vendor Purchases by Item");  // Opens handler - VendorPurchasesByItemMinimumPurchasesRequestPageHandler.

        // Verify: Verify Minimum Purchase Amount, Minimum Purchase Quantity and Source No on Report - Vendor Purchases by Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          PurchaseLbl, StrSubstNo('Items with Net Purchases of more than $%1', MinimumPurchaseAmount));
        LibraryReportDataset.AssertElementWithValueExists(
          QuantityLbl, StrSubstNo('Items with Net Purchase Quantity more than %1', MinimumPurchaseQuantity));
        LibraryReportDataset.AssertElementWithValueExists(ItemLedgerEntrySourceNoLbl, ItemLedgerEntry."Source No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityProjectionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemAvailabilityProjection()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord OF Report ID - 10130 Availability Projection.

        // Setup: Create Item and Item Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate() + 1);  // Calculated Posting date required on Report - Availability Projection.
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for AvailabilityProjectionRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Availability Projection");  // Opens handler - AvailabilityProjectionRequestPageHandler.

        // Verify: Verify Item No and Purchased Quantity.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoLbl, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('QtyPurchased_2_', ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('AvailabilityProjectionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemVariantAvailabilityProjection()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Purpose of the test is to validate Item Variant - OnAfterGetRecord OF Report ID - 10130 Availability Projection.

        // Setup: Create Item, Create Item Variant, and Item Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate() + 1);  // Calculated Posting date required on Report - Availability Projection.
        ItemLedgerEntry."Variant Code" := CreateItemVariant(Item."No.");
        ItemLedgerEntry.Modify();
        LibraryVariableStorage.Enqueue(true);  // Enqueue value for AvailabilityProjectionRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Availability Projection");  // Opens handler - AvailabilityProjectionRequestPageHandler.

        // Verify: Verify Item No, Purchased Quantity and Item Variant Code.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoLbl, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('QtyPurchased_2__Control89', ItemLedgerEntry.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Item_Variant_Code', ItemLedgerEntry."Variant Code");
    end;

    [Test]
    [HandlerFunctions('ItemTransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemTransactionDetail()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        CostAmountActual: Decimal;
    begin
        // Purpose of the test is to validate PriorItemLedgerEntry - OnAfterGetRecord Trigger of Report ID - 10136 Item Transaction Detail.

        // Setup: Create Item, Item Ledger Entry, Prior Item Ledger Entry and Value Entry.
        Initialize();
        CreateItem(Item);
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        UpdateItemLedgerEntryVariantCode(ItemLedgerEntry, CreateItemVariant(Item."No."));
        CreateItemLedgerEntry(ItemLedgerEntry2, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate() - 1);  // Prior Item Ledger Entry.
        CostAmountActual := CreateValueEntry(ItemLedgerEntry2);
        UpdateValueEntryPostingDate(ItemLedgerEntry2."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"Item Transaction Detail");  // Opens handler - ItemTransactionDetailRequestPageHandler.

        // Verify: Verify Cost Amount Actual, Item Ledger Entry No and Quantity on Report - Item Transaction Detail.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Adjustment', CostAmountActual);
        LibraryReportDataset.AssertElementWithValueExists('Item_Ledger_Entry__Item_No__', ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('Item_Ledger_Entry_Quantity', ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileRequestPageHandler2')]
    [Scope('OnPrem')]
    procedure RunInvtToGLReconcileReportBreakdownByVariants()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        VariantCode: Code[10];
        VariantCode2: Code[10];
    begin
        // Verify the variants show correctly when run Report - Inventory to G/L Reconcial with Breakdown by Variants.

        // Setup: Create Items, Variants.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        VariantCode := CreateItemVariant(Item."No.");
        VariantCode2 := CreateItemVariant(Item."No.");

        // Create and post Item Ledger Entry with multiple lines.
        // The 1st line for Item with VariantCode, the 2nd line for Item with VariantCode2, the 3rd line for Item2 without "Variant Code".
        CreateAndPostItemJournalWithMultipleLines(ItemJournalLine, Item."No.", Item2."No.", VariantCode, VariantCode2, '', '');

        // Enqueue values for handler - InventoryToGLReconcileRequestPageHandler2.
        EnqueueInventoryToGLReconcileReport(Item."No.", Item2."No.", false, true, ItemJournalLine."Posting Date");

        // Exercise: Run Report - Inventory to G/L Reconcile.
        REPORT.Run(REPORT::"Inventory to G/L Reconcile"); // Opens handler - InventoryToGLReconcileRequestPageHandler2.

        // Verify: Verify Variants show correctly on Report - Inventory to G/L Reconcial.
        // The Variant of the 1st line is VatiantCode, the 2nd line is VariantCode2, the 3rd line is blank.
        LibraryReportDataset.LoadDataSetFile();
        VerifyItemVariantOnInventoryToGLReconcileReport(VariantCode);
        VerifyItemVariantOnInventoryToGLReconcileReport(VariantCode2);
        VerifyItemVariantOnInventoryToGLReconcileReport('');
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileRequestPageHandler2')]
    [Scope('OnPrem')]
    procedure RunInvtToGLReconcileReportBreakdownByLocation()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        Location2: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify the locations show correctly when run Report - Inventory to G/L Reconcial with Breakdown by Location.

        // Setup: Create Items, Locations.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);

        // Create and post Item Ledger Entry with multiple lines.
        // The 1st line for Item with Location.Code, the 2nd line for Item with Location2.Code. The 3rd line for Item2 without "Location Code".
        CreateAndPostItemJournalWithMultipleLines(ItemJournalLine, Item."No.", Item2."No.", '', '', Location.Code, Location2.Code);

        // Enqueue values for handler - InventoryToGLReconcileRequestPageHandler2.
        EnqueueInventoryToGLReconcileReport(Item."No.", Item2."No.", true, false, ItemJournalLine."Posting Date");

        // Exercise: Run Report - Inventory to G/L Reconcile.
        REPORT.Run(REPORT::"Inventory to G/L Reconcile"); // Opens handler - InventoryToGLReconcileRequestPageHandler2.

        // Verify: Verify Locations show correctly on Report - Inventory to G/L Reconcial.
        // The Location of Item2 should be blank.
        LibraryReportDataset.LoadDataSetFile();
        VerifyLocationOnInventoryToGLReconcileReport(Item2."No.", '');
    end;

    [Test]
    [HandlerFunctions('InventoryToGLReconcileRequestPageHandler3')]
    [Scope('OnPrem')]
    procedure CheckInvToGLReconcileReportAsOfDateVisibility()
    begin
        // [SCENARIO 274836] "As Of Date" field is visible when run Report "Inventory to G/L Reconciliation" in "Suite" plan

        // [GIVEN] Current company set to "Suite" plan
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        // [WHEN] Run Report "Inventory to G/L Reconcile"
        REPORT.Run(REPORT::"Inventory to G/L Reconcile");

        // [THEN] "As Of Date" field is visible on opened request page
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'The field is invisible.');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCommentLineForItem(No: Code[20])
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine."Table Name" := CommentLine."Table Name"::Item;
        CommentLine."No." := No;
        CommentLine.Insert();
        LibraryVariableStorage.Enqueue(CommentLine."No.");  // Enqueue value in ItemCommentListRequestPageHandler.
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Item Tracking Code" := LibraryUTUtility.GetNewCode10();
        Item.Description := Item."No.";
        Item."Shelf No." := LibraryUTUtility.GetNewCode10();
        Item.Insert();
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        ItemJournalLine."Journal Template Name" := JournalTemplateName;
        ItemJournalLine."Journal Batch Name" := JournalBatchName;
        ItemJournalLine."Line No." := LibraryRandom.RandInt(10);
        ItemJournalLine."Item No." := ItemNo;
        ItemJournalLine.Insert();

        // Enqueue value for Request Page handler - PhysicalInventoryCountRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemJournalTemplateAndBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        ItemJournalTemplate.Insert();
        ItemJournalBatch."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        ItemJournalBatch.Insert();
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date)
    begin
        ItemLedgerEntry."Entry No." := SelectItemLedgerEntryNo();
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry."Applied Entry to Adjust" := true;
        ItemLedgerEntry."Source Type" := ItemLedgerEntry."Source Type"::Vendor;
        ItemLedgerEntry."Source No." := CreateVendor();
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Invoiced Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Insert();

        // Enqueue value in Request Page Handler.
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Item No.");
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Posting Date");
    end;

    local procedure CreateAndPostItemJournalWithMultipleLines(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ItemNo2: Code[20]; VariantCode: Code[10]; VariantCode2: Code[10]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalTemplateAndBatch(ItemJournalBatch);
        CreateItemJournalLineWithVariantAndLocationCode(ItemJournalLine, ItemJournalBatch, ItemNo, VariantCode, LocationCode);
        CreateItemJournalLineWithVariantAndLocationCode(ItemJournalLine, ItemJournalBatch, ItemNo, VariantCode2, LocationCode2);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo2, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLineWithVariantAndLocationCode(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10));
        UpdateItemJournalLineVariantAndLocationCode(ItemJournalLine, VariantCode, LocationCode);
    end;

    local procedure CreateItemRegister(FromEntryNo: Integer; SourceCode: Code[10])
    var
        ItemRegister: Record "Item Register";
    begin
        ItemRegister."No." := SelectItemRegisterNo();
        ItemRegister."From Entry No." := FromEntryNo;
        ItemRegister."To Entry No." := ItemRegister."From Entry No.";
        ItemRegister."Source Code" := SourceCode;
        ItemRegister.Insert();
        LibraryVariableStorage.Enqueue(ItemRegister."No.");  // Enqueue value in ItemRegisterRequestPageHandler.
    end;

    local procedure CreateItemVariant(ItemNo: Code[20]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant."Item No." := ItemNo;
        ItemVariant.Code := LibraryUTUtility.GetNewCode10();
        ItemVariant.Insert();
        exit(ItemVariant.Code);
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        ItemVendor."Vendor No." := VendorNo;
        ItemVendor."Item No." := ItemNo;
        ItemVendor.Insert();
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Name := Location.Code;
        Location.Insert();
        LibraryVariableStorage.Enqueue(Location.Code);  // Enqueue value in LocationListRequestPageHandler.
        exit(Location.Code);
    end;

    local procedure CreateStockkeepingUnit(ItemNo: Code[20]): Code[10]
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit."Item No." := ItemNo;
        StockkeepingUnit."Shelf No." := LibraryUTUtility.GetNewCode10();
        StockkeepingUnit.Insert();
        exit(StockkeepingUnit."Shelf No.");
    end;

    local procedure CreateValueEntry(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry."Entry No." := SelectValueEntryNo();
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ValueEntry."Item No." := ItemLedgerEntry."Item No.";
        ValueEntry."Posting Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."Cost Amount (Actual)" := LibraryRandom.RandDecInRange(10, 100, 2);
        ValueEntry."Cost Amount (Actual) (ACY)" := ValueEntry."Cost Amount (Actual)";
        ValueEntry."Valued Quantity" := LibraryRandom.RandDec(10, 2);
        ValueEntry."Purchase Amount (Actual)" := ValueEntry."Cost Amount (Actual)";
        ValueEntry."Expected Cost" := true;
        ValueEntry.Insert();
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure EnqueueInventoryToGLReconcileReport(ItemNo: Code[20]; ItemNo2: Code[20]; BreakdownByLocation: Boolean; BreakdownByVariants: Boolean; PostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(ItemNo2);
        LibraryVariableStorage.Enqueue(BreakdownByLocation);
        LibraryVariableStorage.Enqueue(BreakdownByVariants);
        LibraryVariableStorage.Enqueue(PostingDate); // As of Date - Posting Date.
    end;

    local procedure FilterOnReportInventoryToGLReconcileRequestPage(var InventoryToGLReconcile: TestRequestPage "Inventory to G/L Reconcile"; BreakdownByLocation: Boolean; BreakdownByVariants: Boolean)
    var
        AsOfDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(AsOfDate);
        InventoryToGLReconcile.AsOfDate.SetValue(AsOfDate);
        InventoryToGLReconcile.BreakdownByLocation.SetValue(BreakdownByLocation);
        InventoryToGLReconcile.BreakdownByVariants.SetValue(BreakdownByVariants);
    end;

    local procedure FilterOnReportInventoryValuationRequestPage(var InventoryValuation: TestRequestPage "Inventory Valuation"; BreakdownByLocation: Boolean)
    var
        AsOfDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(AsOfDate);
        InventoryValuation.AsOfDate.SetValue(AsOfDate);
        InventoryValuation.BreakdownByLocation.SetValue(BreakdownByLocation);
    end;

    local procedure FilterOnReportVendorPurchasesByItemRequestPage(var VendorPurchasesByItem: TestRequestPage "Vendor Purchases by Item"; IncludeReturns: Boolean)
    var
        No: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        VendorPurchasesByItem.Item.SetFilter("No.", No);
        VendorPurchasesByItem.IncludeReturns.SetValue(IncludeReturns);
        VendorPurchasesByItem.Item.SetFilter("Date Filter", Format(DateFilter));
    end;

    local procedure RunItemVendorCatalogReport(var ItemVendor: Record "Item Vendor")
    var
        ItemVendorCatalog: Report "Item/Vendor Catalog";
    begin
        Clear(ItemVendorCatalog);  // Already Set Currentkey and filter applied on Item Vendor Record, so VAR - True required.
        ItemVendorCatalog.SetTableView(ItemVendor);
        ItemVendorCatalog.Run();  // Opens handler - ItemVendorCatalogRequestPageHandler.
    end;

    local procedure SelectItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectItemRegisterNo(): Integer
    var
        ItemRegister: Record "Item Register";
    begin
        if ItemRegister.FindLast() then
            exit(ItemRegister."No." + 1);
        exit(1);
    end;

    local procedure SelectValueEntryNo(): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        if ValueEntry.FindLast() then
            exit(ValueEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateItemLedgerEntryVariantCode(ItemLedgerEntry: Record "Item Ledger Entry"; VariantCode: Code[10])
    begin
        ItemLedgerEntry."Variant Code" := VariantCode;
        ItemLedgerEntry.Modify();
    end;

    local procedure UpdateItemJournalLineVariantAndLocationCode(ItemJournalLine: Record "Item Journal Line"; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateValueEntryPostingDate(ItemLedgerEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.FindFirst();
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry.Modify();
    end;

    local procedure VerifyItemVendorSortOrder(SortingOrder: Text; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleLbl, SortingOrder);
        LibraryReportDataset.AssertElementWithValueExists('Item_Vendor__Item_No__', ItemNo);
        LibraryReportDataset.AssertElementWithValueExists('Item_Vendor__Vendor_No__', VendorNo);
    end;

    local procedure VerifyItemVariantOnInventoryToGLReconcileReport(VariantCode: Code[10])
    begin
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemLedgerEntry_VariantCode', VariantCode);
    end;

    local procedure VerifyLocationOnInventoryToGLReconcileReport(ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryReportDataset.SetRange('Item__No__', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemLedgerEntry_LocationCode', LocationCode);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryLabelsRequestPageHandler(var InventoryLabels: TestRequestPage "Inventory Labels")
    var
        No: Variant;
        NoOfLabelsPerRow: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(NoOfLabelsPerRow);
        InventoryLabels.Item.SetFilter("No.", No);
        InventoryLabels.NoOfLabelsPerRow.SetValue(NoOfLabelsPerRow);
        InventoryLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCommentListRequestPageHandler(var ItemCommentList: TestRequestPage "Item Comment List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ItemCommentList."Comment Line".SetFilter("No.", Format(No));
        ItemCommentList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemRegisterRequestPageHandler(var ItemRegister: TestRequestPage "Item Register")
    var
        No: Variant;
        ItemNo: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(No);
        ItemRegister."Item Register".SetFilter("No.", Format(No));
        ItemRegister."Item Ledger Entry".SetFilter("Item No.", ItemNo);
        ItemRegister."Item Ledger Entry".SetFilter("Posting Date", Format(PostingDate));
        ItemRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LocationListRequestPageHandler(var LocationList: TestRequestPage "Location List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LocationList.Location.SetFilter(Code, Code);
        LocationList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OverStockRequestPageHandler(var OverStock: TestRequestPage "Over Stock")
    var
        No: Variant;
        DateFilter: Variant;
        UseStockkeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);
        OverStock.Item.SetFilter("No.", No);
        OverStock.Item.SetFilter("Date Filter", Format(DateFilter));
        OverStock.UseStockkeepingUnit.SetValue(UseStockkeepingUnit);
        OverStock.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysicalInventoryCountRequestPageHandler(var PhysicalInventoryCount: TestRequestPage "Physical Inventory Count")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        PhysicalInventoryCount."Item Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        PhysicalInventoryCount."Item Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        PhysicalInventoryCount.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SerialNumberStatusAgingRequestPageHandler(var SerialNumberStatusAging: TestRequestPage "Serial Number Status/Aging")
    var
        No: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        SerialNumberStatusAging.Item.SetFilter("No.", No);
        SerialNumberStatusAging.Item.SetFilter("Date Filter", Format(DateFilter));
        SerialNumberStatusAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemVendorCatalogRequestPageHandler(var ItemVendorCatalog: TestRequestPage "Item/Vendor Catalog")
    begin
        ItemVendorCatalog.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryToGLReconcileErrorRequestPageHandler(var InventoryToGLReconcile: TestRequestPage "Inventory to G/L Reconcile")
    begin
        FilterOnReportInventoryToGLReconcileRequestPage(InventoryToGLReconcile, true, false);  // Breakdown By Location - True.
        InventoryToGLReconcile.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryToGLReconcileRequestPageHandler(var InventoryToGLReconcile: TestRequestPage "Inventory to G/L Reconcile")
    var
        No: Variant;
        UseAdditionalReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        FilterOnReportInventoryToGLReconcileRequestPage(InventoryToGLReconcile, false, false); // Breakdown By Location - False.
        LibraryVariableStorage.Dequeue(UseAdditionalReportingCurrency);
        InventoryToGLReconcile.Item.SetFilter("No.", No);
        InventoryToGLReconcile.UseAdditionalReportingCurrency.SetValue(UseAdditionalReportingCurrency);
        InventoryToGLReconcile.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryToGLReconcileRequestPageHandler2(var InventoryToGLReconcile: TestRequestPage "Inventory to G/L Reconcile")
    var
        No: Variant;
        No2: Variant;
        BreakdownByLocation: Variant;
        BreakdownByVariants: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(No2);
        LibraryVariableStorage.Dequeue(BreakdownByLocation);
        LibraryVariableStorage.Dequeue(BreakdownByVariants);

        FilterOnReportInventoryToGLReconcileRequestPage(InventoryToGLReconcile, BreakdownByLocation, BreakdownByVariants);
        InventoryToGLReconcile.Item.SetFilter("No.", StrSubstNo(ItemFilterTxt, No, No2));
        InventoryToGLReconcile.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryToGLReconcileRequestPageHandler3(var InventoryToGLReconcile: TestRequestPage "Inventory to G/L Reconcile")
    begin
        LibraryVariableStorage.Enqueue(InventoryToGLReconcile.AsOfDate.Visible());
        InventoryToGLReconcile.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPurchasesByItemRequestPageHandler(var VendorPurchasesByItem: TestRequestPage "Vendor Purchases by Item")
    begin
        FilterOnReportVendorPurchasesByItemRequestPage(VendorPurchasesByItem, false);  // Include Returns - False.
        VendorPurchasesByItem.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPurchasesByItemMaximumPurchasesRequestPageHandler(var VendorPurchasesByItem: TestRequestPage "Vendor Purchases by Item")
    var
        MaxPurchaseAmount: Variant;
        MaxPurchaseQuantity: Variant;
    begin
        FilterOnReportVendorPurchasesByItemRequestPage(VendorPurchasesByItem, true);  // Include Returns - True.
        LibraryVariableStorage.Dequeue(MaxPurchaseAmount);
        LibraryVariableStorage.Dequeue(MaxPurchaseQuantity);
        VendorPurchasesByItem.MaxPurchases.SetValue(MaxPurchaseAmount);
        VendorPurchasesByItem.MaxQty.SetValue(MaxPurchaseQuantity);
        VendorPurchasesByItem.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPurchasesByItemMinimumPurchasesRequestPageHandler(var VendorPurchasesByItem: TestRequestPage "Vendor Purchases by Item")
    var
        MinPurchaseAmount: Variant;
        MinPurchaseQuantity: Variant;
    begin
        FilterOnReportVendorPurchasesByItemRequestPage(VendorPurchasesByItem, true);  // Include Returns - True.
        LibraryVariableStorage.Dequeue(MinPurchaseAmount);
        LibraryVariableStorage.Dequeue(MinPurchaseQuantity);
        VendorPurchasesByItem.MinPurchases.SetValue(MinPurchaseAmount);
        VendorPurchasesByItem.MinQty.SetValue(MinPurchaseQuantity);
        VendorPurchasesByItem.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityProjectionRequestPageHandler(var AvailabilityProjection: TestRequestPage "Availability Projection")
    var
        BreakdownByVariant: Variant;
        No: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(BreakdownByVariant);
        AvailabilityProjection.Item.SetFilter("No.", No);
        AvailabilityProjection.Item.SetFilter("Date Filter", Format(DateFilter));
        AvailabilityProjection.BreakdownByVariant.SetValue(BreakdownByVariant);
        AvailabilityProjection.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTransactionDetailRequestPageHandler(var ItemTransactionDetail: TestRequestPage "Item Transaction Detail")
    var
        No: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        ItemTransactionDetail.Item.SetFilter("No.", No);
        ItemTransactionDetail.Item.SetFilter("Date Filter", Format(DateFilter));
        ItemTransactionDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationlErrorRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    begin
        FilterOnReportInventoryValuationRequestPage(InventoryValuation, true);  // Breakdown By Location - True.
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    var
        No: Variant;
        UseAdditionalReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        FilterOnReportInventoryValuationRequestPage(InventoryValuation, false);  // Breakdown By Location - False.
        LibraryVariableStorage.Dequeue(UseAdditionalReportingCurrency);
        InventoryValuation.Item.SetFilter("No.", No);
        InventoryValuation.UseAdditionalReportingCurrency.SetValue(UseAdditionalReportingCurrency);
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

