// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 149908 "Subc. Warehouse Library"
{
    // [FEATURE] Subcontracting Warehouse Test Library
    // Consolidated data creation functions for warehouse tests to avoid code duplication

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";

    /// <summary>
    /// Creates and calculates needed work and machine centers.
    /// </summary>
    /// <param name="WorkCenter">The array of work centers which will be created</param>
    /// <param name="MachineCenter">The array of machine centers which will be created</param>
    /// <param name="Subcontracting">Indicates if the work centers are subcontracting work centers</param>
    procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; Subcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Location: Record Location;
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryManufacturing.UpdateShopCalendarWorkingDays();

        if Subcontracting then begin
            LibraryPurchase.CreateSubcontractor(Vendor1);
            Vendor1."Subc. Location Code" := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            Vendor1.Modify(true);
            LibraryPurchase.CreateSubcontractor(Vendor2);
            Vendor2."Subc. Location Code" := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            Vendor2.Modify(true);
        end;

        // Create first work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[1], LibraryRandom.RandDec(10, 2));
        WorkCenterNo := WorkCenter[1]."No.";

        if Subcontracting then begin
            WorkCenter[1]."Subcontractor No." := Vendor1."No.";
            WorkCenter[1].Modify(true);
        end;

        // Create machine centers
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[1], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[2], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        // Create second work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[2], LibraryRandom.RandDec(10, 2));

        if Subcontracting then begin
            WorkCenter[2]."Subcontractor No." := Vendor2."No.";
            WorkCenter[2].Modify(true);
        end;
    end;

    /// <summary>
    /// Creates and calculates needed work and machine centers for the same vendor
    /// </summary>
    /// <param name="WorkCenter">The Work Center which has been created</param>
    /// <param name="MachineCenter">The Machine Center which has been created</param>
    /// <param name="Subcontracting">Indicates if the work center is a subcontracting work center</param>
    procedure CreateAndCalculateNeededWorkAndMachineCenterSameVendor(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; Subcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // Create single vendor for both work centers
        if Subcontracting then
            LibraryPurchase.CreateSubcontractor(Vendor);

        // Create first work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[1], LibraryRandom.RandDec(10, 2));
        WorkCenterNo := WorkCenter[1]."No.";

        if Subcontracting then begin
            WorkCenter[1]."Subcontractor No." := Vendor."No.";
            WorkCenter[1].Modify(true);
        end;

        // Create machine centers for first work center
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[1], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[2], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        // Create second work center with same vendor
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[2], LibraryRandom.RandDec(10, 2));

        if Subcontracting then begin
            WorkCenter[2]."Subcontractor No." := Vendor."No.";
            WorkCenter[2].Modify(true);
        end;
    end;

    /// <summary>
    /// Creates an item with a production BOM and routing, where the routing has both in-house and subcontracting operations. The subcontracting operations are linked to the provided work centers and machine centers.
    /// The item created is a finished good item which can be used for end-to-end testing of the subcontracting flow from production order creation to warehouse receipt.
    /// This function is used to set up the data for testing the scenario where a production order has both in-house and subcontracting operations, and the impact on warehouse receipts when posting the production order.
    /// </summary>
    /// <param name="Item">The item record which will be created</param>
    /// <param name="WorkCenter">The array of work centers which will be linked to the subcontracting operations in the routing</param>
    /// <param name="MachineCenter">The array of machine centers which will be linked to the in-house operations in the routing</param>
    procedure CreateItemForProductionIncludeRoutingAndProdBOM(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        // Create routing
        RoutingNo := CreateRouting(MachineCenter, WorkCenter);

        // Create component items
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // Create production BOM
        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, Item2."No.", Item3."No.", 1);

        // Create finished item
        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandDec(10, 2),
            "Reordering Policy"::" ", "Flushing Method"::Backward, RoutingNo, ProductionBOMNo);
    end;

    /// <summary>
    /// Creates a production item with a parallel routing that includes subcontracting operations.
    /// </summary>
    /// <param name="Item">The production item to create.</param>
    /// <param name="MachineCenter">The in-house machine centers used by the routing.</param>
    /// <param name="WorkCenter">The subcontracting work centers used by the routing.</param>
    procedure CreateParallelRoutingItemWithSubcontracting(var Item: Record Item; var MachineCenter: array[2] of Record "Machine Center"; var WorkCenter: array[2] of Record "Work Center")
    var
        Item2: Record Item;
        Item3: Record Item;
        Location: Record Location;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WorkCenterNonSC: Record "Work Center";
        ProductionBOMNo: Code[20];
    begin
        // Create non-subcontracting work center with machine centers for ops 10 and 20
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenterNonSC, LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[1], WorkCenterNonSC."No.", LibraryRandom.RandDec(10, 1));
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[2], WorkCenterNonSC."No.", LibraryRandom.RandDec(10, 1));

        // Create subcontracting work center for op 30 (parallel SC branch) with dedicated vendor + location
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[1], LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreateSubcontractor(Vendor1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor1."Subc. Location Code" := Location.Code;
        Vendor1.Modify(true);
        WorkCenter[1]."Subcontractor No." := Vendor1."No.";
        WorkCenter[1].Modify(true);

        // Create subcontracting work center for op 40 (last SC operation) with dedicated vendor + location
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[2], LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreateSubcontractor(Vendor2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor2."Subc. Location Code" := Location.Code;
        Vendor2.Modify(true);
        WorkCenter[2]."Subcontractor No." := Vendor2."No.";
        WorkCenter[2].Modify(true);

        // Create a PARALLEL routing: 10 → 20 | 30 → 40
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter[1]."No.");
        RoutingLine."Next Operation No." := '20|30';
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Machine Center", MachineCenter[2]."No.");
        RoutingLine."Previous Operation No." := '10';
        RoutingLine."Next Operation No." := '40';
        RoutingLine."Transfer WIP Item" := true;
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingLine."Previous Operation No." := '10';
        RoutingLine."Next Operation No." := '40';
        RoutingLine."Transfer WIP Item" := true;
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '40', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingLine."Previous Operation No." := '20|30';
        RoutingLine."Transfer WIP Item" := true;
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Create two component items and a certified production BOM
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, Item2."No.", Item3."No.", 1);

        // Create the finished item linked to the parallel routing and production BOM
        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandDec(10, 2),
            "Reordering Policy"::" ", "Flushing Method"::Backward, RoutingHeader."No.", ProductionBOMNo);
    end;

    /// <summary>
    /// Creates a routing with the specified machine centers and work centers.
    /// </summary>
    /// <param name="MachineCenter">The array of machine centers to be used in the routing</param>
    /// <param name="WorkCenter">The array of work centers to be used in the routing</param>
    /// <returns>The routing number of the created routing</returns>
    procedure CreateRouting(var MachineCenter: array[2] of Record "Machine Center"; var WorkCenter: array[2] of Record "Work Center"): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Create routing lines
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Machine Center", MachineCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '40', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        exit(RoutingHeader."No.");
    end;

    /// <summary>
    /// Updates the production BOM and routing with the specified routing link.
    /// </summary>
    /// <param name="Item">The item record which will be updated</param>
    /// <param name="WorkCenterNo">The work center number to be linked to the routing</param>
    procedure UpdateProdBomAndRoutingWithRoutingLink(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        // Create routing link
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // Update routing
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update production BOM
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindLast() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
            ProductionBOMLine.Modify(true);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    /// <summary>
    /// Updates the production BOM and routing with the specified routing links for both operations.
    /// </summary>
    /// <param name="Item">The item record which will be updated</param>
    /// <param name="WorkCenter">The array of work centers to be linked to the routing</param>
    procedure UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item: Record Item; var WorkCenter: array[2] of Record "Work Center")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink1: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
    begin
        // Create routing links for both operations
        LibraryManufacturing.CreateRoutingLink(RoutingLink1);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);

        // Update routing
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        // Update first operation (intermediate)
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenter[1]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink1.Code);
            RoutingLine.Modify(true);
        end;

        // Update second operation (last)
        RoutingLine.SetRange("No.", WorkCenter[2]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink2.Code);
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update production BOM
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindFirst() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink1.Code);
            ProductionBOMLine.Modify(true);
        end;
        if ProductionBOMLine.FindLast() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink2.Code);
            ProductionBOMLine.Modify(true);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    /// <summary>
    /// Creates a production item with a three-operation routing where the first subcontracting
    /// operation transfers WIP and the second subcontracting operation is the last operation.
    /// </summary>
    /// <param name="Item">The item record that is created and configured for the scenario</param>
    /// <param name="WorkCenter">The work centers used for the subcontracting operations</param>
    /// <param name="MachineCenter">The machine centers used for the in-house routing operation</param>
    procedure CreateThreeOpRoutingWithWIPTransfer(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink1: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
        ProductionBOMNo: Code[20];
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingLine."Transfer WIP Item" := true;
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, Item2."No.", Item3."No.", 1);

        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandDec(10, 2),
            "Reordering Policy"::" ", "Flushing Method"::Backward, RoutingHeader."No.", ProductionBOMNo);

        LibraryManufacturing.CreateRoutingLink(RoutingLink1);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenter[1]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink1.Code);
            RoutingLine.Modify(true);
        end;

        RoutingLine.SetRange("No.", WorkCenter[2]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink2.Code);
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindFirst() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink1.Code);
            ProductionBOMLine.Modify(true);
        end;
        if ProductionBOMLine.FindLast() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink2.Code);
            ProductionBOMLine.Modify(true);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithWarehouseHandling(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and require receive only (not put-away).
    /// This is used to test scenarios where the location requires a warehouse receipt but does not require
    /// a warehouse put-away. The expected behavior in this case is that when receiving into this location, a warehouse receipt will be created,
    /// but no put-away will be required and the item will be received directly into the location without needing to be put away to another location.
    /// This allows testing of the system's handling of warehouse receipts when put-away is not required.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithRequireReceiveOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := false;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a bin-mandatory location that requires warehouse receipts but not warehouse put-aways.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    /// <param name="ReceiveBin">The receipt bin record which will be created and assigned to the location</param>
    internal procedure CreateLocationWithRequireReceiveOnlyAndBinMandatory(var Location: Record Location; var ReceiveBin: Record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, false);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", false);
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, 'RECEIVE', '', '');
        Location.Validate("Receipt Bin Code", ReceiveBin.Code);
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with bin mandatory enabled only.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithBinMandatoryOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location."Require Receive" := false;
        Location."Require Put-away" := false;

        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and bin mandatory. This is used to test scenarios where the location requires a warehouse receipt and put-away,
    /// and also requires that items be placed in bins within the location.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithWarehouseHandlingAndBinMandatory(var Location: Record Location)
    begin
        // Creates location with Bin Mandatory = true, Require Receive = true, Require Put-away = true
        // This creates Take/Place warehouse activity lines with Bin Code
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location for single-step logistics (Inventory Put-away).
    /// Require Receive = false, Require Put-away = true, Bin Mandatory = false.
    /// This is the minimal location setup that triggers the Inventory Put-away code path
    /// instead of the two-step Warehouse Receipt + Put-away path.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithInvtPutAwaySetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        Location."Require Receive" := false;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location pair for WIP transfer pick scenarios: a shipping location with
    /// single-step outbound pick enabled and a production location that can be used as the
    /// WIP transfer source.
    /// </summary>
    /// <param name="ShipLocation">The shipping location created with Require Pick = true and Require Shipment = false</param>
    /// <param name="ProdLocation">The production location created for the WIP transfer source</param>
    /// <param name="BinMandatory">Specifies whether both locations should be created as bin mandatory</param>
    procedure CreateLocationForWIPPick(var ShipLocation: Record Location; var ProdLocation: Record Location; BinMandatory: Boolean)
    var
        ProdBin: Record Bin;
        ShipBin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWMS(ShipLocation, BinMandatory, false, true, false, false);
        ShipLocation."Require Pick" := true;
        ShipLocation."Require Shipment" := false;
        ShipLocation.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(ShipLocation);

        if BinMandatory then begin
            LibraryWarehouse.CreateBin(ShipBin, ShipLocation.Code, 'PICK', '', '');
            ShipLocation.Validate("Default Bin Code", ShipBin.Code);
            ShipLocation.Modify(true);

            CreateLocationWithBinMandatoryOnly(ProdLocation);
            LibraryWarehouse.CreateBin(ProdBin, ProdLocation.Code, 'PROD', '', '');
            ProdLocation.Validate("Default Bin Code", ProdBin.Code);
            ProdLocation."From-Production Bin Code" := ProdBin.Code;
            ProdLocation.Modify(true);
        end else
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProdLocation);
    end;

    /// <summary>
    /// Creates a location for single-step logistics (Inventory Put-away) with Bin Mandatory = true.
    /// Require Receive = false, Require Put-away = true, Bin Mandatory = true.
    /// A default bin is created and assigned so that Inventory Put-away lines can be posted.
    /// A Warehouse Employee must additionally be created for the location before posting
    /// (see Library - Warehouse.CreateWarehouseEmployee), since Bin Mandatory locations
    /// enforce warehouse employee authorization.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    /// <param name="DefaultBin">The bin record which will be created and set as the default bin</param>
    procedure CreateLocationWithInvtPutAwaySetupAndBin(var Location: Record Location; var DefaultBin: Record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, false);
        Location."Require Receive" := false;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        LibraryWarehouse.CreateBin(DefaultBin, Location.Code, 'PUTAWAY', '', '');
        Location.Validate("Default Bin Code", DefaultBin.Code);
        Location."From-Production Bin Code" := DefaultBin.Code;
        Location.Modify(true);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and bins for both receiving and put-away.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    /// <param name="ReceiveBin">The bin record which will be created and updated for receiving</param>
    /// <param name="PutAwayBin">The bin record which will be created and updated for put-away</param>
    procedure CreateLocationWithWarehouseHandlingAndBins(var Location: Record Location; var ReceiveBin: Record Bin; var PutAwayBin: Record Bin)
    begin
        // Creates location with Bin Mandatory = true, Require Receive = true, Require Put-away = true
        // Sets up both Receive Bin (for warehouse receipt) and Default Bin (for put-away destination)
        CreateLocationWithWarehouseHandlingAndBinMandatory(Location);

        // Create receive bin - used when posting warehouse receipt
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, 'RECEIVE', '', '');
        Location.Validate("Receipt Bin Code", ReceiveBin.Code);

        // Create put-away bin - destination for put-away Place line
        LibraryWarehouse.CreateBin(PutAwayBin, Location.Code, 'PUTAWAY', '', '');
        Location.Validate("Default Bin Code", PutAwayBin.Code);

        Location.Modify(true);
    end;

    /// <summary>
    /// Creates and refreshes a production order with the specified parameters. This function is used to set up production orders for testing scenarios that involve production orders and their impact on warehouse receipts.
    /// </summary>
    /// <param name="ProductionOrder">The production order record which will be created and updated</param>
    /// <param name="Status">The status of the production order</param>
    /// <param name="SourceType">The source type of the production order</param>
    /// <param name="SourceNo">The source number of the production order</param>
    /// <param name="Quantity">The quantity of the production order</param>
    /// <param name="LocationCode">The location code of the production order</param>
    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    /// <summary>
    /// Updates the subcontracting management setup with a subcontracting requirement worksheet template and name. This is used to set up the subcontracting management parameters for testing scenarios that involve subcontracting and the use of subcontracting requirement worksheets in the subcontracting process.
    /// </summary>
    procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        SubcLibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
    end;

    /// <summary>
    /// Creates a subcontracting purchase order from a production order routing line with the specified routing number and work center number, and finds the created purchase line.
    /// This function is used to set up subcontracting purchase orders for testing scenarios that involve the creation of subcontracting purchase orders from production order routings and
    /// their impact on warehouse receipts.
    /// </summary>
    /// <param name="RoutingNo">The routing number of the production order</param>
    /// <param name="WorkCenterNo">The work center number of the production order</param>
    /// <param name="PurchaseLine">The purchase line record which will be created and updated</param>
    procedure CreateSubcontractingOrderFromProdOrderRouting(RoutingNo: Code[20]; WorkCenterNo: Code[20]; var PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Work Center");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();

        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRtngLine);

        // Find the created purchase line
        PurchaseLine.SetRange("Routing No.", RoutingNo);
        PurchaseLine.SetRange("Work Center No.", WorkCenterNo);
        PurchaseLine.FindFirst();
    end;

    /// <summary>
    /// Same as <see cref="CreateSubcontractingOrderFromProdOrderRouting"/>, but additionally filters the
    /// Prod. Order Routing Line lookup by Prod. Order No. This disambiguation is required whenever more than
    /// one production order for the same item/routing exists (e.g. a LastOperation order and a separate
    /// NotLastOperation order created from the same Item in the same test) - without it, the plain
    /// (Routing No. + Work Center No.) filter can silently match a DIFFERENT production order's routing line
    /// (e.g. one that has already produced its full output and has Remaining Quantity = 0), causing
    /// "Subc. Purchase Order Creator".CreateSubcontractingPurchaseOrderFromRoutingLine to exit without creating
    /// any purchase line at all.
    /// </summary>
    procedure CreateSubcontractingOrderFromProdOrderRouting(RoutingNo: Code[20]; WorkCenterNo: Code[20]; ProdOrderNo: Code[20]; var PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Work Center");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();

        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRtngLine);

        // Find the created purchase line
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderNo);
        PurchaseLine.SetRange("Routing No.", RoutingNo);
        PurchaseLine.SetRange("Work Center No.", WorkCenterNo);
        PurchaseLine.FindFirst();
    end;

    /// <summary>
    /// Creates subcontracting purchase orders from worksheet lines for the specified production order.
    /// </summary>
    /// <param name="ProductionOrderNo">The production order number used to filter worksheet and resulting purchase lines</param>
    /// <param name="PurchaseHeader">The purchase header record which will be found for the created purchase order</param>
    procedure CreateSubcontractingOrdersViaWorksheet(ProductionOrderNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // Get worksheet template and batch from setup
        ManufacturingSetup.Get();

        // Initialize requisition line for the Calculate Subcontracts report
        RequisitionLine."Worksheet Template Name" := ManufacturingSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := ManufacturingSetup."Subcontracting Batch Name";

        // Calculate subcontracting lines to fill the worksheet
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        // Find requisition lines for the production order
        RequisitionLine.SetRange("Worksheet Template Name", ManufacturingSetup."Subcontracting Template Name");
        RequisitionLine.SetRange("Journal Batch Name", ManufacturingSetup."Subcontracting Batch Name");
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        // Create purchase orders from the worksheet - combines lines for same vendor into one PO
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // Find the created purchase header
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    /// <summary>
    /// Creates a warehouse receipt from a released purchase order.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record that is released and used as source</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header record that will be found after creation</param>
    procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    /// <summary>
    /// Creates a warehouse receipt header and populates it using get source documents for the given location.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header record which will be created and populated</param>
    /// <param name="LocationCode">The location code used to retrieve source documents</param>
    procedure CreateWarehouseReceiptUsingGetSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);

        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    /// <summary>
    /// Posts a warehouse receipt and finds the resulting posted warehouse receipt header.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header to post</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header found after posting</param>
    procedure PostWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindFirst();
    end;

    /// <summary>
    /// Posts a partial warehouse receipt for the specified quantity and finds the latest posted warehouse receipt header.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header to post partially</param>
    /// <param name="PartialQuantity">The quantity to receive on the warehouse receipt line</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header found after posting</param>
    procedure PostPartialWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PartialQuantity: Decimal; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQuantity);
        WarehouseReceiptLine.Modify(true);

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindLast();
    end;

    /// <summary>
    /// Creates a put-away document from a posted warehouse receipt if none exists and returns the latest put-away header.
    /// </summary>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header used as source for put-away creation</param>
    /// <param name="WarehouseActivityHeader">The warehouse activity header for the created or existing put-away</param>
    procedure CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.FindFirst();

        WarehouseActivityLine.SetRange("Location Code", PostedWhseReceiptHeader."Location Code");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Source Type", PostedWhseReceiptLine."Source Type");
        WarehouseActivityLine.SetRange("Source No.", PostedWhseReceiptLine."Source No.");

        if WarehouseActivityLine.IsEmpty() then begin
            PostedWhseReceiptLine.SetHideValidationDialog(true);
            PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, PostedWhseReceiptHeader."Assigned User ID");
        end;

        if WarehouseActivityLine.FindLast() then
            WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    /// <summary>
    /// Creates an Inventory Put-away document (single-step logistics) from a released
    /// subcontracting Purchase Order, without showing the source documents request page.
    /// </summary>
    /// <param name="PurchaseHeader">The released purchase header used as source</param>
    /// <param name="WarehouseActivityHeader">The created Inventory Put-away header</param>
    procedure CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseRequest: Record "Warehouse Request";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange(Type, WhseRequest.Type::Inbound);
        WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Purchase Order");
        WhseRequest.SetRange("Source No.", PurchaseHeader."No.");
        WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);
        WhseRequest.FindFirst();

        LibraryWarehouse.CreateInvtPutAwayPick(WhseRequest, true, false, false);
        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange(Type, "Warehouse Activity Type"::"Invt. Put-away");
        WarehouseActivityHeader.SetRange("Source Document", "Warehouse Activity Source Document"::"Purchase Order");
        WarehouseActivityHeader.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseActivityHeader.SetRange("Source Type", Database::"Purchase Line");
        WarehouseActivityHeader.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseActivityHeader.FindFirst();
    end;

    /// <summary>
    /// Creates an Inventory Put-away document (single-step logistics) from a released,
    /// shipped subcontracting Transfer Order (e.g. a WIP Item transfer between subcontracting
    /// locations), without showing the source documents request page.
    /// </summary>
    /// <param name="TransferHeader">The released, shipped transfer header used as source</param>
    /// <param name="WarehouseActivityHeader">The created Inventory Put-away header</param>
    procedure CreateInvtPutAwayFromTransferOrder(TransferHeader: Record "Transfer Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseRequest: Record "Warehouse Request";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange(Type, WhseRequest.Type::Inbound);
        WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Inbound Transfer");
        WhseRequest.SetRange("Source No.", TransferHeader."No.");
        WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);
        WhseRequest.FindFirst();

        LibraryWarehouse.CreateInvtPutAwayPick(WhseRequest, true, false, false);
        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange(Type, "Warehouse Activity Type"::"Invt. Put-away");
        WarehouseActivityHeader.SetRange("Source Document", "Warehouse Activity Source Document"::"Inbound Transfer");
        WarehouseActivityHeader.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityHeader.SetRange("Source Type", Database::"Transfer Line");
        WarehouseActivityHeader.FindFirst();
    end;

    /// <summary>
    /// Creates an Inventory Pick document (single-step logistics) from a released
    /// transfer order using the outbound transfer warehouse request.
    /// </summary>
    /// <param name="TransferHeader">The released transfer header used as source</param>
    /// <param name="WarehouseActivityHeader">The created Inventory Pick header</param>
    procedure CreateInvtPickFromTransferOrder(TransferHeader: Record "Transfer Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseRequest: Record "Warehouse Request";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange(Type, WhseRequest.Type::Outbound);
        WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Outbound Transfer");
        WhseRequest.SetRange("Source No.", TransferHeader."No.");
        WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);
        WhseRequest.FindFirst();

        // Create the activity for this transfer request only.
        LibraryWarehouse.CreateInvtPutAwayPick(WhseRequest, true, true, false);

        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange(Type, "Warehouse Activity Type"::"Invt. Pick");
        WarehouseActivityHeader.SetRange("Source Document", "Warehouse Activity Source Document"::"Outbound Transfer");
        WarehouseActivityHeader.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityHeader.SetRange("Source Type", Database::"Transfer Line");
        WarehouseActivityHeader.FindFirst();
    end;

    /// <summary>
    /// Posts a partial put-away by setting quantity to handle on all lines and posting the warehouse activity.
    /// </summary>
    /// <param name="WarehouseActivityHeader">The warehouse activity header for the put-away to post</param>
    /// <param name="PartialQuantity">The quantity to handle assigned to each warehouse activity line</param>
    procedure PostPartialPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PartialQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", PartialQuantity);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::"Invt. Put-away" then
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false)
        else
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    /// <summary>
    /// Posts a partial inventory pick by setting quantity to handle on all lines and posting the warehouse activity.
    /// </summary>
    /// <param name="WarehouseActivityHeader">The warehouse activity header for the inventory pick to post</param>
    /// <param name="PartialQuantity">The quantity to handle assigned to each warehouse activity line</param>
    procedure PostPartialInventoryPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PartialQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", PartialQuantity);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    /// <summary>
    /// Splits the first warehouse activity line on the document across up to three bins.
    /// </summary>
    /// <param name="WarehouseActivityHeader">The warehouse activity header whose first line is split</param>
    /// <param name="ActivityType">The activity type of the document being split</param>
    /// <param name="Bins">The bins assigned to the resulting split lines</param>
    /// <param name="Quantities">The quantities assigned to the resulting split lines; zero quantities are skipped</param>
    procedure SplitActivityLineAcrossBins(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActivityType: Enum "Warehouse Activity Type"; Bins: array[3] of Record Bin; Quantities: array[3] of Decimal)
    var
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
    begin
        WarehouseActivityHeader.TestField(Type, ActivityType);

        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        Bins[1].TestField(Code);
        WarehouseActivityLine.Validate("Bin Code", Bins[1].Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantities[1]);
        WarehouseActivityLine.Modify(true);

        for Index := 2 to ArrayLen(Quantities) do
            if Quantities[Index] <> 0 then begin
                Bins[Index].TestField(Code);

                // SplitLine derives the quantities from Qty. to Handle.
                WarehouseActivityLine.SplitLine(WarehouseActivityLine, NewWarehouseActivityLine);
                NewWarehouseActivityLine.Validate("Bin Code", Bins[Index].Code);
                NewWarehouseActivityLine.Validate("Qty. to Handle", Quantities[Index]);
                NewWarehouseActivityLine.Modify(true);
                WarehouseActivityLine := NewWarehouseActivityLine;
            end;
    end;

    /// <summary>
    /// Creates a put-away worksheet name for the specified location, ensuring a put-away worksheet template exists.
    /// </summary>
    /// <param name="WhseWorksheetTemplate">The worksheet template record that is found or created</param>
    /// <param name="WhseWorksheetName">The worksheet name record that is created</param>
    /// <param name="LocationCode">The location code assigned to the worksheet name</param>
    procedure CreatePutAwayWorksheet(var WhseWorksheetTemplate: Record "Whse. Worksheet Template"; var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        EnsurePutAwayWorksheetTemplate(WhseWorksheetTemplate);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    /// <summary>
    /// Ensures that a put-away worksheet template exists by finding an existing one or creating a new one.
    /// </summary>
    /// <param name="WhseWorksheetTemplate">The worksheet template record that is found or created</param>
    local procedure EnsurePutAwayWorksheetTemplate(var WhseWorksheetTemplate: Record "Whse. Worksheet Template")
    begin
        // Try to find existing put-away template
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::"Put-away");
        if WhseWorksheetTemplate.FindFirst() then
            exit;

        // No template exists, create one
        WhseWorksheetTemplate.Init();
        WhseWorksheetTemplate.Validate(Name,
            CopyStr(LibraryUtility.GenerateRandomCode(WhseWorksheetTemplate.FieldNo(Name), Database::"Whse. Worksheet Template"),
                1, MaxStrLen(WhseWorksheetTemplate.Name)));
        WhseWorksheetTemplate.Validate(Type, WhseWorksheetTemplate.Type::"Put-away");
        WhseWorksheetTemplate.Validate(Description, 'Put-away Worksheet');
        WhseWorksheetTemplate.Validate("Page ID", Page::"Put-away Worksheet");
        WhseWorksheetTemplate.Insert(true);
    end;

    /// <summary>
    /// Retrieves inbound source documents for the put-away worksheet at the specified location.
    /// </summary>
    /// <param name="WhseWorksheetTemplateName">The worksheet template name used by the worksheet context</param>
    /// <param name="WhseWorksheetName">The worksheet name record used to populate worksheet lines</param>
    /// <param name="LocationCode">The location code used to filter put-away requests</param>
    procedure GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplateName: Code[10]; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
    end;

    /// <summary>
    /// Creates a put-away document from worksheet lines and returns the latest put-away warehouse activity header.
    /// </summary>
    /// <param name="WhseWorksheetName">The worksheet name containing the worksheet lines to process</param>
    /// <param name="WarehouseActivityHeader">The warehouse activity header found after document creation</param>
    procedure CreatePutAwayFromWorksheet(WhseWorksheetName: Record "Whse. Worksheet Name"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", WhseWorksheetName."Location Code");
        WhseWorksheetLine.FindFirst();

        // Create put-away from worksheet lines using correct function
        LibraryWarehouse.WhseSourceCreateDocument(
            WhseWorksheetLine,
            "Whse. Activity Sorting Method"::None,
            false,
            false,
            false);

        WarehouseActivityHeader.SetRange("Location Code", WhseWorksheetName."Location Code");
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.FindLast();
    end;

    /// <summary>
    /// Verifies that output item ledger entries exist for the item and location and match the expected quantity.
    /// </summary>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="ExpectedQuantity">The expected summed output quantity</param>
    /// <param name="LocationCode">The location code to verify</param>
    procedure VerifyItemLedgerEntry(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry should have correct output quantity');
    end;

    /// <summary>
    /// Verifies that capacity ledger entries exist for the work center and match the expected output quantity.
    /// </summary>
    /// <param name="WorkCenterNo">The work center number to verify</param>
    /// <param name="ExpectedQuantity">The expected summed output quantity</param>
    procedure VerifyCapacityLedgerEntry(WorkCenterNo: Code[20]; ExpectedQuantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Assert: Codeunit Assert;
    begin
        CapacityLedgerEntry.SetRange(Type, CapacityLedgerEntry.Type::"Work Center");
        CapacityLedgerEntry.SetRange("No.", WorkCenterNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(ExpectedQuantity, CapacityLedgerEntry."Output Quantity",
            'Capacity Ledger Entry should have correct output quantity');
    end;

    /// <summary>
    /// Verifies that bin content exists for the given location, bin, and item and matches the expected quantity.
    /// </summary>
    /// <param name="LocationCode">The location code to verify</param>
    /// <param name="BinCode">The bin code to verify</param>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="ExpectedQuantity">The expected bin content quantity</param>
    procedure VerifyBinContents(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
        Assert: Codeunit Assert;
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(BinContent);

        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(ExpectedQuantity, BinContent.Quantity,
            'Bin contents should show correct quantity after put-away posting');
    end;

    /// <summary>
    /// Returns the number of posted inventory put-away lines created from the specified purchase order.
    /// </summary>
    /// <param name="PurchOrderNo">The purchase order number used as source</param>
    /// <returns>The number of posted inventory put-away lines for the purchase order</returns>
    procedure GetPostedInvtPutAwayLineCountForPurchaseOrder(PurchOrderNo: Code[20]): Integer
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source Document", PostedInvtPutAwayLine."Source Document"::"Purchase Order");
        PostedInvtPutAwayLine.SetRange("Source No.", PurchOrderNo);
        exit(PostedInvtPutAwayLine.Count());
    end;

    /// <summary>
    /// Returns the number of posted inventory put-away lines created from the specified transfer order.
    /// </summary>
    /// <param name="TransferOrderNo">The transfer order number used as source</param>
    /// <returns>The number of posted inventory put-away lines for the transfer order</returns>
    procedure GetPostedInvtPutAwayLineCountForTransferOrder(TransferOrderNo: Code[20]): Integer
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source Document", PostedInvtPutAwayLine."Source Document"::"Inbound Transfer");
        PostedInvtPutAwayLine.SetRange("Source No.", TransferOrderNo);
        exit(PostedInvtPutAwayLine.Count());
    end;

    /// <summary>
    /// Verifies that no warehouse entries exist for the item at the specified location.
    /// </summary>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="LocationCode">The location code to verify</param>
    procedure VerifyNoWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseEntry: Record "Warehouse Entry";
        Assert: Codeunit Assert;
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        Assert.RecordIsEmpty(WarehouseEntry);
    end;

    /// <summary>
    /// Verifies that no output item ledger entries exist for the item at the specified location.
    /// </summary>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="LocationCode">The location code to verify</param>
    procedure VerifyNoItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    /// <summary>
    /// Sets up a complete subcontracting warehouse scenario including item, location, production order, and purchase order.
    /// </summary>
    /// <param name="Item">The item record that is created and configured for the scenario</param>
    /// <param name="Location">The location record that is created and configured for warehouse handling</param>
    /// <param name="ProductionOrder">The production order record that is created and refreshed</param>
    /// <param name="PurchaseHeader">The purchase header record found for the created subcontracting purchase order</param>
    /// <param name="Quantity">The production order quantity used in the setup</param>
    procedure SetupCompleteSubcontractingWarehouseScenario(var Item: Record Item; var Location: Record Location; var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    var
        MachineCenter: array[2] of Record "Machine Center";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // Complete setup for most common warehouse scenarios
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        CreateLocationWithWarehouseHandling(Location);

        // Configure vendor with location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // Create production order
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // Setup subcontracting
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // Create purchase order
        CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    /// <summary>
    /// Creates a production item with lot tracking setup using generated number series and routing/BOM configuration.
    /// </summary>
    /// <param name="Item">The item record that is created and updated with lot tracking setup</param>
    /// <param name="WorkCenter">The work centers used when creating routing data for the item</param>
    /// <param name="MachineCenter">The machine centers used when creating routing data for the item</param>
    procedure CreateLotTrackedItemForProductionWithSetup(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
    begin
        // Implemented by Copilot - Create lot tracking components internally
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);

        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LotNoSeries.Code);
        Item.Modify(true);
    end;

    /// <summary>
    /// Creates a production item with serial tracking setup using generated number series and routing/BOM configuration.
    /// </summary>
    /// <param name="Item">The item record that is created and updated with serial tracking setup</param>
    /// <param name="WorkCenter">The work centers used when creating routing data for the item</param>
    /// <param name="MachineCenter">The machine centers used when creating routing data for the item</param>
    procedure CreateSerialTrackedItemForProductionWithSetup(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
    begin
        // Create serial tracking components internally
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);

        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", SerialNoSeries.Code);
        Item.Modify(true);
    end;

    /// <summary>
    /// Creates a production item with combined lot and package tracking setup using generated
    /// number series and routing/BOM configuration.
    /// </summary>
    /// <param name="Item">The item record that is created and updated with lot and package tracking setup</param>
    /// <param name="WorkCenter">The work centers used when creating routing data for the item</param>
    /// <param name="MachineCenter">The machine centers used when creating routing data for the item</param>
    procedure CreatePackageAndLotTrackedItemForProductionWithSetup(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);

        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LotNoSeries.Code);
        Item.Modify(true);
    end;

    /// <summary>
    /// Creates a transfer order line marked as a WIP item without subcontracting routing references.
    /// </summary>
    /// <param name="TransferHeader">The transfer header to create.</param>
    /// <param name="TransferLine">The WIP transfer line to create.</param>
    /// <param name="FromLocation">The source location code.</param>
    /// <param name="ToLocation">The destination location code.</param>
    /// <param name="InTransitCode">The in-transit location code.</param>
    /// <param name="Item">The transfer item.</param>
    /// <param name="Quantity">The transfer quantity.</param>
    procedure CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; InTransitCode: Code[10]; Item: Record Item; Quantity: Decimal)
    var
        TransferRoute: Record "Transfer Route";
    begin
        if Item."No." = '' then
            LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, FromLocation, ToLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, InTransitCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Modify();
    end;

    /// <summary>
    /// Sets Transfer WIP Item = true on the routing line for the specified work center.
    /// The routing is temporarily uncertified, modified, and re-certified.
    /// Must be called BEFORE the production order is refreshed so the Prod. Order Routing Line
    /// inherits the flag.
    /// </summary>
    procedure SetTransferWIPItemOnRoutingLine(Item: Record Item; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        if RoutingLine.FindFirst() then begin
            RoutingLine."Transfer WIP Item" := true;
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    /// <summary>
    /// Creates bidirectional Transfer Routes between production and subcontractor locations,
    /// both using the supplied in-transit location. Required for WIP item forward and return
    /// transfers that use an in-transit step.
    /// </summary>
    procedure CreateTransferRoutesForWIPTransfer(ProdLocationCode: Code[10]; SubcLocationCode: Code[10]; InTransitLocationCode: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, ProdLocationCode, SubcLocationCode, InTransitLocationCode, '', '');
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, SubcLocationCode, ProdLocationCode, InTransitLocationCode, '', '');
    end;

    /// <summary>
    /// Creates a subcontracting forward Transfer Order from the purchase order by running
    /// "Subc. Create Transf. Order" without the request page.
    /// The caller must register a page handler for the Transfer Order page that is opened
    /// by the report's ShowDocument() procedure.
    /// </summary>
    procedure CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create Transf. Order", false, false, PurchaseHeader);
    end;

    /// <summary>
    /// Finds the first subcontracting Transfer Header linked to the purchase order.
    /// IsReturn = false for forward transfers, true for return transfers (Rückumlagerungen).
    /// </summary>
    procedure FindSubcontractingTransferHeader(PurchaseHeader: Record "Purchase Header"; IsReturn: Boolean; var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange("Subc. Return Order", IsReturn);
        TransferHeader.FindFirst();
    end;

    /// <summary>
    /// Creates a WIP item Return Transfer Order (Rückumlagerung) directly, with the full
    /// subcontracting routing context copied from the given purchase line.
    /// This is used instead of running SubcCreateSubCReturnOrder (which requires
    /// non-zero Subcontractor WIP Ledger Entries that cannot be created automatically).
    /// </summary>
    procedure CreateReturnTransferWithSubcContext(
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcLocationCode: Code[10];
        ProdLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        Quantity: Decimal;
        var ReturnTransferHeader: Record "Transfer Header")
    var
        ReturnTransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(ReturnTransferHeader, SubcLocationCode, ProdLocationCode, InTransitLocationCode);
        ReturnTransferHeader."Subc. Source Type" := ReturnTransferHeader."Subc. Source Type"::Subcontracting;
        ReturnTransferHeader."Source ID" := PurchaseHeader."Buy-from Vendor No.";
        ReturnTransferHeader."Subcontr. Purch. Order No." := PurchaseHeader."No.";
        ReturnTransferHeader."Subc. Return Order" := true;
        ReturnTransferHeader.Modify();

        LibraryWarehouse.CreateTransferLine(ReturnTransferHeader, ReturnTransferLine, PurchaseLine."No.", Quantity);
        ReturnTransferLine.Validate("Transfer WIP Item", true);
        ReturnTransferLine."Subc. Purch. Order No." := PurchaseLine."Document No.";
        ReturnTransferLine."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
        ReturnTransferLine."Subc. Prod. Order No." := PurchaseLine."Prod. Order No.";
        ReturnTransferLine."Subc. Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
        ReturnTransferLine."Subc. Routing No." := PurchaseLine."Routing No.";
        ReturnTransferLine."Subc. Routing Reference No." := PurchaseLine."Routing Reference No.";
        ReturnTransferLine."Subc. Work Center No." := PurchaseLine."Work Center No.";
        ReturnTransferLine."Subc. Operation No." := PurchaseLine."Operation No.";
        ReturnTransferLine."Subc. Return Order" := true;
        ReturnTransferLine.Modify();
    end;

    /// <summary>
    /// Creates work and machine centers with detailed cost setup (Direct Unit Cost, Indirect Cost %,
    /// Overhead Rate, Unit Cost Calculation). Preserves the original SubcSubcontractingTest behaviour
    /// where the first work center is never a subcontractor.
    /// </summary>
    procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; IsSubcontracting: Boolean; UnitCostCalc: Option Time,Units)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        CreateWorkCenterForTest(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not IsSubcontracting, UnitCostCalc, '');
        WorkCenter[1].Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        SubcLibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[1].Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        SubcLibraryMfgManagement.CreateMachineCenter(MachineCenterNo2, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[2].Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        if IsSubcontracting then
            CreateWorkCenterForTest(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", IsSubcontracting, UnitCostCalc, '')
        else
            CreateWorkCenterForTest(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not IsSubcontracting, UnitCostCalc, '');
        WorkCenter[2].Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    /// <summary>
    /// Creates a production item with routing and BOM using detailed cost fields on both
    /// the item and its components (Overhead Rate, Indirect Cost %, Lot-for-Lot reorder policy,
    /// Pick + Manual flushing). Preserves original SubcSubcontractingTest behaviour.
    /// </summary>
    procedure CreateItemForProductionWithCostOverrides(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        NoSeries: Codeunit "No. Series";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        ManufacturingSetup.SetLoadFields("Routing Nos.");
        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.", WorkDate(), true);

        SubcLibraryMfgManagement.CreateRouting(RoutingNo, MachineCenter[1]."No.", MachineCenter[2]."No.", WorkCenter[1]."No.", WorkCenter[2]."No.");

        CreateItemForTest(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo := Item."No.";
        Clear(Item);
        CreateItemForTest(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo2 := Item."No.";
        Clear(Item);

        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, ItemNo2, 1);

        CreateItemForTest(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMNo);
    end;

    /// <summary>
    /// Links a routing line and a production BOM line through a routing link whose code
    /// is derived from the production BOM number. Preserves original SubcSubcontractingTest behaviour.
    /// </summary>
    procedure UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.Init();
        RoutingLink.Validate(Code, CopyStr(Item."Production BOM No.", 1, 10));
        RoutingLink.Insert(true);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateWorkCenterForTest(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean; UnitCostCalc: Option; CurrencyCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        SubcLibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", SubcLibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateItemForTest(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20])
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);
    end;
}