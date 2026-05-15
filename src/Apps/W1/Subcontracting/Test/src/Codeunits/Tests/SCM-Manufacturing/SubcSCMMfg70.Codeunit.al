// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting.Test;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 149917 "Subc SCM Mfg. 70"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Subcontracting] [SCM]
        IsInitialized := false;
    end;

    var
        LocationGreen: Record Location;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        NumberOfLineErr: Label 'Number of line must be same.';
        StatusTxt: Label 'Status must be';
        CertifiedTxt: Label 'Certified';
        ModifyRtngErr: Label 'You cannot modify Routing No. %1 because there is at least one %2 associated with it.', Locked = true;
        DeleteRtngErr: Label 'You cannot delete Prod. Order Line %1 because there is at least one %2 associated with it.', Locked = true;
        SubcontractingDescriptionErr: Label 'The description in Subcontracting Worksheet must be from Work Center if available.';
        OperationNoErr: Label 'Operation No. must be equal to %1', Comment = '%1 = Operation No.';

    [Test]
    [Scope('OnPrem')]
    procedure B44327_RefreshProdOrderSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Production Order line after refreshing Released Production Order for Subcontracting.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // Exercise: Create and Refresh Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Verify: Verify Production Order line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_RoutingStatusNotCertifiedSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Error message after refreshing Released Production Order for Subcontracting if Routing Status not certified.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Modify Routing Status not certified.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message.
        Assert.IsFalse((StrPos(GetLastErrorText, StatusTxt) = 0) or (StrPos(GetLastErrorText, CertifiedTxt) = 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_ProdBOMStatusNotCertifiedSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Error message after refreshing Released Production Order for Subcontracting if Production BOM Status not certified.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Modify Production BOM status not certified.
        ProductionBOMHeader.Find();
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message.
        Assert.IsFalse((StrPos(GetLastErrorText, StatusTxt) = 0) or (StrPos(GetLastErrorText, CertifiedTxt) = 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_CalcSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        OperationNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Requisition Line after Calculation of Subcontracting.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, ProductionOrder."Source Type"::Item, false);

        // Exercise: Calculation of Subcontracting.
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Operation No in Requisition Line.
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
        RequisitionLine.TestField("Operation No.", OperationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_PostPurchOrderSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        OperationNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Capacity Ledger Entry after Carry out action message of subcontracting and post Purchase Order.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, ProductionOrder."Source Type"::Item, false);
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);

        // Exercise: Run Carry out action message of subcontracting.
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Verify: Verify Line Amount in Purchase Line.
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Line Amount", Quantity * WorkCenter."Direct Unit Cost");

        // Exercise: Posting Purchase Order with Subcontracting.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Capacity Ledger Entry.
        VerifyCapacityLedgerEntry(WorkCenter, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateSubcontractForReleasedProdOrderWithVariantCode()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Work Center for subcontracting and create Item.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(LibraryRandom.RandInt(10)));
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");

        // Create Released Production Order and update Variant Code on Production Line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        CreateAndUpdateVariantCodeOnProductionOrderLine(ProdOrderLine);
        WorkCenter.SetRange("No.", WorkCenter."No.");

        // Exercise: Calculate Subcontract.
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Variant Code in Requisition Line.
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
        RequisitionLine.TestField("Variant Code", ProdOrderLine."Variant Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRtngOnProdOrdLnWithSubcontr()
    var
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check error when modifying routing No. on subcontracted Prod. Order line
        // Setup: Create 2 released prod. order lines, subcontract the first line
        Initialize();

        SetupProdOrdLnWithSubContr(ProdOrderLine);
        CreateRoutingSetup(RoutingHeader);

        // Get the first Prod. order line
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Exercise
        asserterror ProdOrderLine.Validate("Routing No.", RoutingHeader."No.");

        // Verify: Existing Error Message
        Assert.AreEqual(StrSubstNo(ModifyRtngErr, ProdOrderLine."Routing No.", PurchaseLine.TableCaption()), GetLastErrorText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteProdOrdLnWithSubcontr()
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check error when deleting subcontracted Prod. Order line
        // Setup: Create 2 released prod. order lines, subcontract the first line
        Initialize();
        SetupProdOrdLnWithSubContr(ProdOrderLine);

        // Get the first Prod. order line
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Exercise
        asserterror ProdOrderLine.Delete(true);

        // Verify: Existing Error Message
        Assert.AreEqual(StrSubstNo(DeleteRtngErr, ProdOrderLine."Line No.", PurchaseLine.TableName), GetLastErrorText, '');
    end;

    [Test]
    procedure CalculateSubcontractsForMultilineProductionOrder()
    var
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Production] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 380493] "Calculate Subcontracts" in subcontracting worksheet creates worksheet lines for multiline production order

        // [GIVEN] Subcontracting work center "W", routing "R" including work center "W"
        // [GIVEN] Production order with two lines, both with routing "R"
        Initialize();
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Two requisition lines created - one worksheet line per production order line
        Assert.RecordCount(RequisitionLine, 2);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindSet();
        repeat
            VerifyProdOrderRequisitionLine(ProdOrderLine);
        until ProdOrderLine.Next() = 0;
    end;

    [Test]
    procedure VendorItemNoWhenCalculateSubcontractsItemVendorCatalog()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ItemVendor: Record "Item Vendor";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts] [Item Vendor]
        // [SCENARIO 395878] Vendor Item No. is set from Item Vendor Catalog for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". Item Vendor Catalog for Item "I" and Vendor "SV" with Vendor Item No. = "ItemVendorCatalog".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());
        CreateItemVendor(ItemVendor, WorkCenter."Subcontractor No.", Item."No.", LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "ItemVendorCatalog" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoWhenCalculateSubcontractsSKUAndNoItemVendorCatalog()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts] [SKU]
        // [SCENARIO 395878] Vendor Item No. is set from Item's SKU for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". There is no Item Vendor Catalog for Item "I" and Vendor "SV".
        // [GIVEN] SKU with Vendor Item No. = "StockKeepingUnit" for Item "I" and Location "L".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());
        CreateStockKeepingUnit(StockkeepingUnit, Item, LocationGreen.Code);
        UpdateVendorItemNoOnSKU(StockkeepingUnit, LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order with Location "L" for Item "I".
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateProductionOrder(ProductionOrder, StockkeepingUnit."Location Code", WorkDate());
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "StockKeepingUnit" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", StockkeepingUnit."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoWhenCalculateSubcontractsNoItemVendorCatalogNoSKU()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 395878] Vendor Item No. is set from Item for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog and SKU.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". There is no Item Vendor Catalog for Item "I" and Vendor "SV". There is no SKU for Item "I".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "Item" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    [Test]
    procedure VendorItemNoBlankWhenCalculateSubcontractsNoItemVendorCatalogNoSKUBlankItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 395878] Vendor Item No. is blank in Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog and SKU; Item."Vendor Item No." is blank.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and blank Vendor Item No.. There is no Item Vendor Catalog for Item "I" and Vendor "SV". There is no SKU for Item "I".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, '');

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and blank Vendor Item No. is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", '');
    end;

    [Test]
    procedure SubcontractingWorksheetDescriptionIsPopulatedFromWorkCenter()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: array[2] of Record Item;
        RequisitionLine: Record "Requisition Line";
        OperationNo: Code[10];
        Quantity: Decimal;
        WorkCenterName: Text;
    begin
        // [SCENARIO 540333] When the work Center changed in Subcontracting Worksheet the description is populated.
        Initialize();

        // [GIVEN] Store Operation No., Quantity and Work Center Description in a variable.
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        WorkCenterName := LibraryRandom.RandText(50);

        // [GIVEN] Create a Subcontracting Setup and Validate Name.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        WorkCenter.Validate("Name 2", WorkCenterName);
        WorkCenter.Modify(true);

        // [GIVEN] Create two Items with Routing No.
        CreateItem(
            Item[1], Item[1]."Replenishment System"::"Prod. Order", Item[1]."Reordering Policy"::" ",
            false, 0, 0, 0, RoutingHeader."No.");
        CreateItem(
            Item[2], Item[2]."Replenishment System"::"Prod. Order", Item[2]."Reordering Policy"::" ",
            false, 0, 0, 0, RoutingHeader."No.");

        // [GIVEN] Create Production BOM and Certify.
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, Item[1]."Base Unit of Measure",
            ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Validate Routing No. in Item.
        Item[1].Validate("Routing No.", RoutingHeader."No.");
        Item[1].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrder(
            ProductionOrder, ProductionOrder.Status::Released, Item[1]."No.", Quantity,
            ProductionOrder."Source Type"::Item, false);

        // [GIVEN] Calculate Subcontracting for Work Center.
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Find the Requisition Line of Production Order.
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Validate Item No. into different Item and Validate Work Center No.
        RequisitionLine.Validate("No.", Item[2]."No.");
        RequisitionLine.Validate("Work Center No.", WorkCenter."No.");
        RequisitionLine.Modify(true);

        // [THEN] Description must be as same as Work Center Name.
        Assert.AreEqual(RequisitionLine.Description, WorkCenter.Name, SubcontractingDescriptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldSkipThoseItemsIfProductionBlockedIsOutputOnItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should skip those item if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Delete Prod. Order Routing Lines.
        ProdOrderRoutingLine.DeleteAll(false);

        // [GIVEN] Create Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder);

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Get(ProductionOrder."Source No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be no requisition line if "Production Blocked" is Output on "Item".
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        Assert.RecordCount(RequisitionLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldCreateOnlyThoseLinesIfProductionBlockedIsBlankOnItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: array[2] of Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should create only those lines if "Production Blocked" is blank on "Item".
        Initialize();

        // [GIVEN] Create Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder[1]);

        // [GIVEN] Create another Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder[2]);

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Get(ProductionOrder[1]."Source No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be two requisition lines if "Production Blocked" is blank on "Item".
        RequisitionLine.SetRange("No.", ProductionOrder[2]."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder[2].Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder[2]."No.");
        Assert.RecordCount(RequisitionLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldSkipThoseItemsIfProductionBlockedIsOutputOnItemVariant()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ItemVariant: Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should skip those item if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Create Item With Rounting.
        CreateProdItem(Item, RoutingHeader."No.");

        // [GIVEN] Create Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be no requisition line if "Production Blocked" is Output on "Item Variant".
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        Assert.RecordCount(RequisitionLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldCreateOnlyThoseLinesIfProductionBlockedIsBlankOnItemVariant()
    var
        Item: array[2] of Record Item;
        WorkCenter: Record "Work Center";
        ItemVariant: array[2] of Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: array[2] of Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should create only those lines if "Production Blocked" is blank on "Item Variant".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Create Item and Item Variant With Rounting.
        CreateProdItem(Item[1], RoutingHeader."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item[1]."No.");

        // [GIVEN] Create another Item and Item Variant With Rounting.
        CreateProdItem(Item[2], RoutingHeader."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item[2]."No.");

        // [GIVEN] Create Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProductionOrder[1]."Source Type"::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        ProductionOrder[1].Validate("Variant Code", ItemVariant[1].Code);
        ProductionOrder[1].Modify(true);

        // [GIVEN] Create another Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::Released, ProductionOrder[2]."Source Type"::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        ProductionOrder[2].Validate("Variant Code", ItemVariant[2].Code);
        ProductionOrder[2].Modify(true);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Refresh another Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant[1].Validate("Production Blocked", ItemVariant[1]."Production Blocked"::Output);
        ItemVariant[1].Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be one requisition line if "Production Blocked" is blank on "Item Variant".
        RequisitionLine.SetRange("No.", ProductionOrder[2]."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder[2].Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder[2]."No.");
        Assert.RecordCount(RequisitionLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySubConWorkSheetOrderByOperationNo()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        WorkCenter: array[2] of Record "Work Center";
        WorkCenter2: Record "Work Center";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        OperationNo: array[2] of Code[10];
    begin
        // [SCENARIO 561326] Subcontracting Worksheet - order of the lines is based on the "Operation No"
        Initialize();

        // [GIVEN] Create multiple subcontracting setup with multiple Work Center
        CreateMultipleSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);

        // [GIVEN] Create one Production Item and two Raw Item
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);

        // [GIVEN] Create Production BOM and certify it
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);

        // [GIVEN] Update Production BOM No. and Routing on Item
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // [GIVEN] Create Released Production order
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run "Calculate Subcontracts" report
        WorkCenter2.SetFilter("No.", '%1|%2', WorkCenter[1]."No.", WorkCenter[2]."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter2);

        // [THEN] Verify Operation No. on Requisition Line will be in order of routing
        VerifyOperationNoOnRequisitionLineForProductionOrder(ProductionOrder, OperationNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc SCM Mfg. 70");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc SCM Mfg. 70");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        CreateLocationSetup();
        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc SCM Mfg. 70");
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationGreen);
    end;

    local procedure CreateSubcontractingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header"; OperationNo: Code[10])
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenterSetup(MachineCenter, WorkCenter."No.");
        CreateRouting(RoutingHeader, RoutingLine, MachineCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Machine Center");
        UpdateRoutingLine(RoutingLine, LibraryRandom.RandInt(15), LibraryRandom.RandInt(15), 0);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Wait Time", LibraryRandom.RandInt(5));
        RoutingLine.Modify(true);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateMachineCenterSetup(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
    begin
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterSetup(var WorkCenter: Record "Work Center"; CapacityType: Enum "Capacity Type"; StartTime: Time; EndTime: Time)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityType);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", UpdateShopCalendarWorkingDays(StartTime, EndTime));
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', WorkDate()), CalcDate('<2M>', WorkDate()));
    end;

    local procedure UpdateShopCalendarWorkingDays(StartTime: Time; EndTime: Time): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkShift: Record "Work Shift";
        Day: Option Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        for Day := Day::Monday to Day::Sunday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendar.Code, Day, WorkShift.Code, StartTime, EndTime);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean; ReorderPoint: Decimal; ReorderQuantity: Decimal; MaximumInventory: Decimal; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateMultipleItems(var Item: Record Item; var Item2: Record Item; var Item3: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReplenishmentSystem2: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean)
    begin
        CreateItem(Item, ReplenishmentSystem, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
        CreateItem(Item2, ReplenishmentSystem, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
        CreateItem(Item3, ReplenishmentSystem2, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
    end;

    local procedure CreateProdItem(var Item: Record Item; RoutingNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        CreateItemsWithInventory(ChildItemNo, ChildItemNo2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingNo);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
    end;

    local procedure CreateItemsWithInventory(var ChildItemNo: Code[20]; var ChildItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        ChildItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        ChildItemNo2 := Item."No.";
        UpdateItemInventory(ChildItemNo, ChildItemNo2);
    end;

    local procedure UpdateItemInventory(ChildItemNo: Code[20]; ChildItemNo2: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItemNo, LibraryRandom.RandDec(100, 2) + 50);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItemNo2, LibraryRandom.RandDec(100, 2) + 50);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateProductionBOMAndCertify(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; ComponentType: Enum "Production BOM Line Type"; ComponentNo: Code[20]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ComponentType, ComponentNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(Item);
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMHeaderStatus(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal)
    begin
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateProductionOrder(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; DueDate: Date)
    begin
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
    end;

    local procedure UpdateVendorItemNoOnItem(var Item: Record Item; VendorItemNo: Text[20])
    begin
        Item.Validate("Vendor Item No.", VendorItemNo);
        Item.Modify(true);
    end;

    local procedure UpdateVendorItemNoOnSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; VendorItemNo: Text[20])
    begin
        StockkeepingUnit.Validate("Vendor Item No.", VendorItemNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; SourceType: Enum "Prod. Order Source Type"; Forward: Boolean)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; Type: Option; RoutingLineType: Enum "Capacity Type Routing")
    var
        OperationNo: Code[10];
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, Type);
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLineType, WorkCenterNo);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(105, 1));
        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
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
        exit('');
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindRequisitionLineForProductionOrder(var RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order")
    begin
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
    end;

    local procedure CalculateSubcontractOrder(var RequisitionLine: Record "Requisition Line"; WorkCenterNo: Code[20]; ProductionOrder: Record "Production Order")
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("No.", WorkCenterNo);
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
    end;

    local procedure CreateProdOrderWithSubcontractWorkCenter(var WorkCenter: Record "Work Center"; var ProductionOrder: Record "Production Order")
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
    begin
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateProdItem(Item, RoutingHeader."No.");
        SetupProdOrdWithRtng(ProductionOrder, Item."No.");
    end;

    local procedure SetupProdOrdWithRtng(var ProdOrd: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        LineQuantity: array[2] of Decimal;
    begin
        LineQuantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        LineQuantity[2] := LibraryRandom.RandDecInRange(30, 40, 2);
        LibraryManufacturing.CreateProductionOrder(
          ProdOrd, ProdOrd.Status::Released, ProdOrd."Source Type"::Item, ItemNo,
          LineQuantity[1] + LineQuantity[2]);

        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrd.Status, ProdOrd."No.", ItemNo, '', '', LineQuantity[1]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrd.Status, ProdOrd."No.", ItemNo, '', '', LineQuantity[2]);
        LibraryManufacturing.RefreshProdOrder(ProdOrd, false, false, true, false, false);
    end;

    local procedure SetupProdOrdLnWithSubContr(var ProdOrdLn: Record "Prod. Order Line")
    var
        ProdOrd: Record "Production Order";
        ReqLn: Record "Requisition Line";
        WorkCtr: Record "Work Center";
    begin
        CreateProdOrderWithSubcontractWorkCenter(WorkCtr, ProdOrd);
        CalculateSubcontractOrder(ReqLn, WorkCtr."No.", ProdOrd);
        LibraryPlanning.CarryOutAMSubcontractWksh(ReqLn);
        FindProdOrderLine(ProdOrdLn, ProdOrd.Status, ProdOrd."No.");
    end;

    local procedure CreateAndUpdateVariantCodeOnProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ProdOrderLine."Item No.");
        ProdOrderLine.Validate("Variant Code", ItemVariant.Code);
        ProdOrderLine.Modify(true);
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VendorItemNo: Text[20])
    begin
        ItemVendor.Init();
        ItemVendor.Validate("Vendor No.", VendorNo);
        ItemVendor.Validate("Item No.", ItemNo);
        ItemVendor.Validate("Vendor Item No.", VendorItemNo);
        ItemVendor.Insert(true);
    end;

    local procedure CreateStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; LocationCode: Code[10])
    begin
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        StockkeepingUnit.Get(LocationCode, Item."No.", '');
    end;

    local procedure CreateMultipleSubcontractingSetup(
        var WorkCenter: array[2] of Record "Work Center";
        var RoutingHeader: Record "Routing Header";
        var OperationNo: array[2] of Code[10])
    var
        WorkCenterNo: array[2] of Code[20];
        RoutingHeaderNo: Code[20];
    begin
        Create2WorkCenter(WorkCenter, WorkCenterNo);
        CreateRoutingWithSequentialOperations(WorkCenterNo, OperationNo, RoutingHeaderNo);
        RoutingHeader.Get(RoutingHeaderNo);
    end;

    local procedure Create2WorkCenter(var WorkCenter: array[2] of Record "Work Center"; var WorkCenterNo: array[2] of Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
        i: Integer;
    begin
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        CreateWorkCenterSetup(WorkCenter[1], CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        CreateWorkCenterSetup(WorkCenter[2], CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        for i := 1 to ArrayLen(WorkCenter) do begin
            WorkCenterNo[i] := WorkCenter[i]."No.";
            WorkCenter[i].Validate("Unit Cost Calculation", WorkCenter[i]."Unit Cost Calculation"::Time);
            WorkCenter[i].Validate("Subcontractor No.", Vendor."No.");
            WorkCenter[i].Modify(true);
        end;
    end;

    local procedure CreateRoutingWithSequentialOperations(
        WorkCenterNo: array[2] of Code[20];
        var OperationNo: array[2] of Code[10];
        var RoutingHeaderNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo[2]);
        OperationNo[1] := RoutingLine."Operation No.";
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo[1]);
        OperationNo[2] := RoutingLine."Operation No.";
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        RoutingHeaderNo := RoutingHeader."No.";
    end;

    local procedure VerifyCapacityLedgerEntry(WorkCenter: Record "Work Center"; Quantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenter."No.");
        Assert.AreEqual(1, CapacityLedgerEntry.Count, NumberOfLineErr);
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.CalcFields("Direct Cost");
        CapacityLedgerEntry.TestField("Direct Cost", Quantity * WorkCenter."Direct Unit Cost");
    end;

    local procedure VerifyProdOrderRequisitionLine(ProdOrderLine: Record "Prod. Order Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        RequisitionLine.TestField("No.", ProdOrderLine."Item No.");
        RequisitionLine.TestField(Quantity, ProdOrderLine.Quantity);
        RequisitionLine.TestField("Replenishment System", RequisitionLine."Replenishment System"::"Prod. Order");
    end;

    local procedure VerifyOperationNoOnRequisitionLineForProductionOrder(
        ProductionOrder: Record "Production Order";
        OperationNo: array[2] of Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindSet();

        Assert.AreEqual(OperationNo[1], RequisitionLine."Operation No.", StrSubstNo(OperationNoErr, OperationNo[1]));
        RequisitionLine.Next();
        Assert.AreEqual(OperationNo[2], RequisitionLine."Operation No.", StrSubstNo(OperationNoErr, OperationNo[2]));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}