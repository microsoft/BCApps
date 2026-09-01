// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.TestLibraries.Utilities;

codeunit 139971 "Qlty. Tests - Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        NegativeTrackingErr: Label 'Cannot create negative tracking entries on the item %1 in the purchase document %2', Comment = '%1=the item no., %2=the purchase document no';
        SNAlreadyEnteredErr: Label 'Serial Number: [%1] has already been entered.', Comment = '%1 = The serial number';
        IsInitialized: Boolean;

    [Test]
    procedure AddWhseItemJnlTracking_LotTracked_QtyPerUOM1_ViaChangeBin()
    var
        Location: Record Location;
        AnyBin: Record Bin;
        PickBin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[50];
    begin
        // [SCENARIO] Add warehouse item journal tracking for lot-tracked item with Qty per UOM=1 via bin change disposition

        // [GIVEN] Quality management setup is initialized with warehouse trigger disabled
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Lot-tracked item with no. series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item, LotNoSeries);

        // [GIVEN] Full WMS location with bins is created and bin content is set up
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;
        PickBin.SetRange("Location Code", Location.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindSet();

        // [GIVEN] Warehouse employee is set for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal templates and batches are created for initial inventory and reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Initial inventory of 100 units with lot number is created in pick bin
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := LotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);
        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Lot No.", LotNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Disposition buffer is configured to move 6 units to a different pick bin
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := LotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := TempQltyDispositionBuffer."New Bin Code";
        PickBin.Next();
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to create warehouse journal line for bin change
        QltyInspectionUtility.PerformMoveAutoChooseDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] Warehouse reclassification journal line is created with correct bin and quantity
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal Line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(TempQltyDispositionBuffer."New Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'target bin code should match.');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        // [THEN] Warehouse item tracking line is created with correct lot number and quantity
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(LotNo, CheckCreatedJnlWhseItemTrackingLine."Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotTracked_QtyPerUOM1_PosAdj()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot-tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Lot number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'H<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'H<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot-tracked item with Qty per UOM = 1 is created
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 10 units and lot number is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, lot number, and quantities
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_SerialTracked_PosAdj()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for serial-tracked item via positive adjustment

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Serial-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 1 unit and serial number is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, serial number, and quantity of 1
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_PackageTracked_QtyPerUOM1_PosAdj()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for package-tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Package number series and tracking code are configured in inventory setup
        Initialize();
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Package-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", PackageItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 10 units and package number is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Package No." := PackageNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, package number, and quantities
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_SerialAndPackageTracked_QtyPerUOM1_PosAdj()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for serial and package tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Serial and package tracking code is created with both serial and package tracking enabled
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, false, true, true);

        // [GIVEN] Serial and package tracked item is created
        LibraryInventory.CreateTrackedItem(Item, SerialNoSeries.Code, '', SerialItemTrackingCode.Code);

        // [GIVEN] Package number series is configured in inventory setup
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 1 unit with both serial and package numbers is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine."Package No." := PackageNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, serial number, package number, and quantity of 1
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the item journal line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotAndSerialTracked_QtyPerUOM1_PosAdj()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialAndLotItemTrackingCode: Record "Item Tracking Code";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
        LotNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot and serial tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot number series and tracking code are created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot and serial tracking code is created with both tracking types enabled
        LibraryItemTracking.CreateItemTrackingCode(SerialAndLotItemTrackingCode, true, true, false);

        // [GIVEN] Lot and serial tracked item is created
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, SerialNoSeries.Code, SerialAndLotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 1 unit with both serial and lot numbers is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, serial number, lot number, and quantity of 1
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the item journal line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotAndPackageTracked_QtyPerUOM1_PosAdj()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotAndPackageItemTrackingCode: Record "Item Tracking Code";
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot and package tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Lot number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'H<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'H<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot and package tracking code is created with both tracking types enabled
        LibraryItemTracking.CreateItemTrackingCode(LotAndPackageItemTrackingCode, false, true, true);

        // [GIVEN] Lot and package tracked item is created
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotAndPackageItemTrackingCode.Code);

        // [GIVEN] Package number series is configured in inventory setup
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 10 units with both lot and package numbers is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine."Package No." := PackageNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, lot number, and quantities of 10 units
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(10, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotAndSerialAndPackageTracked_QtyPerUOM1_PosAdj()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        SerialLotPackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
        LotNo: Code[20];
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot, serial, and package tracked item with Qty per UOM=1 via positive adjustment

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'I<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot number series and tracking code are created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Package number series is created
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'J<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Package number series is configured in inventory setup
        InventorySetup.Get();
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Lot, serial, and package tracking code is created with all three tracking types enabled
        LibraryItemTracking.CreateItemTrackingCode(SerialLotPackageItemTrackingCode, true, true, true);

        // [GIVEN] Lot, serial, and package tracked item is created
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, SerialNoSeries.Code, SerialLotPackageItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 1 unit with serial, lot, and package numbers is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine."Package No." := PackageNo;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, serial number, lot number, package number, and quantity of 1
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the item journal line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the item journal line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_NoItemTracking()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
    begin
        // [SCENARIO] Add item journal reservation entry for item without item tracking

        // [GIVEN] Item without item tracking is created
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Item journal line with positive adjustment of 10 units without tracking numbers is created
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine.Modify();

        // [WHEN] Reservation entry creation is attempted for the item journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(JnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] No reservation entries are created because item has no tracking
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", JnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", JnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(0, ReservationEntry.Count(), 'There should be no reservation entries because there is no lot/serial/package.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotTracked_QtyPerUOM1_NegAdj()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        AdjJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot-tracked item with Qty per UOM=1 via negative adjustment

        // [GIVEN] Lot number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'K<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot-tracked item with Qty per UOM = 1 is created
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Initial inventory of 10 units with lot number is created and posted
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, JnlItemJournalLine, '', LotNo, 10);
        JnlItemJournalLine."Lot No." := '';
        JnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(JnlItemJournalLine);

        // [GIVEN] Item journal line with negative adjustment of 5 units with existing lot number is created
        LibraryInventory.CreateItemJournalLine(AdjJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, AdjJnlItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 5);
        AdjJnlItemJournalLine."Location Code" := Location.Code;
        AdjJnlItemJournalLine."Lot No." := LotNo;
        AdjJnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the negative adjustment journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(AdjJnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", AdjJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", AdjJnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, lot number, and negative quantity of 5 units
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(-5, ReservationEntry.Quantity, 'The quantity should be negative and match the item journal line.');
        LibraryAssert.AreEqual(-5, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and should match the item journal line.');
        LibraryAssert.AreEqual(AdjJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_SerialTracked_QtyPerUOM1_NegAdj()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        AdjJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for serial-tracked item with Qty per UOM=1 via negative adjustment

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Serial-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, SerialNoSeries.Code, '', SerialItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Initial inventory of 1 unit with serial number is created and posted
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, JnlItemJournalLine, '', SerialNo, 1);
        JnlItemJournalLine."Serial No." := '';
        JnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(JnlItemJournalLine);

        // [GIVEN] Transfer journal template and batch are created for negative adjustment
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Item journal line with negative adjustment of 1 unit with existing serial number is created
        LibraryInventory.CreateItemJournalLine(AdjJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, AdjJnlItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 1);
        AdjJnlItemJournalLine."Location Code" := Location.Code;
        AdjJnlItemJournalLine."Serial No." := SerialNo;
        AdjJnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the negative adjustment journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(AdjJnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", AdjJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", AdjJnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, serial number, and negative quantity of 1 unit
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the original.');
        LibraryAssert.AreEqual(-1, ReservationEntry.Quantity, 'The quantity should be negative and match the item journal line.');
        LibraryAssert.AreEqual(-1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the item journal line.');
        LibraryAssert.AreEqual(AdjJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_PackageTracked_QtyPerUOM1_NegAdj()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        AdjJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for package-tracked item with Qty per UOM=1 via negative adjustment

        // [GIVEN] Package number series is configured in inventory setup
        Initialize();
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'M<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'M<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Package-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", PackageItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch with item tracking enabled are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();

        // [GIVEN] Initial inventory of 10 units with package number is created and posted
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Package No." := PackageNo;
        JnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, JnlItemJournalLine, '', '', PackageNo, 10);
        JnlItemJournalLine."Package No." := '';
        JnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(JnlItemJournalLine);

        // [GIVEN] Item journal line with negative adjustment of 5 units with existing package number is created
        LibraryInventory.CreateItemJournalLine(AdjJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, AdjJnlItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 5);
        AdjJnlItemJournalLine."Location Code" := Location.Code;
        AdjJnlItemJournalLine."Package No." := PackageNo;
        AdjJnlItemJournalLine.Modify();

        // [WHEN] Reservation entry is created for the negative adjustment journal line
        QltyInspectionUtility.CreateItemJournalLineReservationEntry(AdjJnlItemJournalLine, CreatedActualReservationEntry);

        // [THEN] One reservation entry is created with correct source references
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", AdjJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatch.Name);
        ReservationEntry.SetRange("Source Ref. No.", AdjJnlItemJournalLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(ReservationEntry.RecordId(), CreatedActualReservationEntry.RecordId(), 'the output of the record id should match what we expect.');

        // [THEN] Reservation entry has correct item, location, package number, and negative quantity of 5 units
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the item journal line.');
        LibraryAssert.AreEqual(-5, ReservationEntry.Quantity, 'The quantity should be negative and match the item journal line.');
        LibraryAssert.AreEqual(-5, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the item journal line.');
        LibraryAssert.AreEqual(JnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_LotTracked_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        InventoryCreationItemJournalTemplate: Record "Item Journal Template";
        InventoryCreationItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";

        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[20];
        ReclassLotNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for lot-tracked item with Qty per UOM=1 via reclassification to change lot number

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Lot number series and tracking code are created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'N<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'N<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot-tracked item with Qty per UOM = 1 is created
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch are created for initial inventory
        LibraryInventory.CreateItemJournalTemplateByType(InventoryCreationItemJournalTemplate, InventoryCreationItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(InventoryCreationItemJournalBatch, InventoryCreationItemJournalTemplate.Name);

        // [GIVEN] Initial inventory of 10 units with original lot number is created and posted
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InventoryCreationItemJournalTemplate.Name, InventoryCreationItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code, Today(), true);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := Location.Code;
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := OriginalLotNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, 10);
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        ItemLedgerEntry.FindLast();

        // [GIVEN] Transfer journal template and batch are created for reclassification
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        ReclassItemJournalBatch.CalcFields("Template Type");
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] New lot number is generated for reclassification
        ReclassLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] Disposition buffer is configured to change lot number
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Lot No." := ReclassLotNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";

        // [WHEN] Disposition is performed to create reclassification journal line with new lot number
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created in the batch
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the reclassification
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassJnlItemJournalLine."Journal Template Name");
        ReservationEntry.SetRange("Source Batch Name", ReclassJnlItemJournalLine."Journal Batch Name");

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();

        // [THEN] Reservation entry has correct item, location, original lot number, new lot number, and quantities
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(ReclassLotNo, ReservationEntry."New Lot No.", 'The new lot no. should match the item journal line');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine.Quantity, -ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Quantity (Base)", -ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_ChangeLot_KeepExpDate_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        InventoryCreationItemJournalTemplate: Record "Item Journal Template";
        InventoryCreationItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[20];
        ReclassLotNo: Code[20];
        ExpDate: Date;
    begin
        // [SCENARIO] Add item journal reservation entry for lot-tracked item with Qty per UOM=1 via reclassification to change lot number while keeping expiration date

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A lot-tracked item with expiration date tracking is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'O<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'O<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(LotItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Initial inventory with lot number and expiration date is posted
        LibraryInventory.CreateItemJournalTemplateByType(InventoryCreationItemJournalTemplate, InventoryCreationItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(InventoryCreationItemJournalBatch, InventoryCreationItemJournalTemplate.Name);
        InventoryCreationItemJournalBatch."Item Tracking on Lines" := true;
        InventoryCreationItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InventoryCreationItemJournalTemplate.Name, InventoryCreationItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := Location.Code;
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := OriginalLotNo;
        ExpDate := WorkDate();
        InitialInspectionInventoryJnlItemJournalLine."Expiration Date" := ExpDate;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, 10);
        ReservationEntry."Expiration Date" := ExpDate;
        ReservationEntry.Modify();

        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        ItemLedgerEntry.FindLast();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        ReclassLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [WHEN] Reclassification disposition is performed to change the lot number while keeping the expiration date
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Lot No." := ReclassLotNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with correct tracking information
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();

        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(ExpDate, ReservationEntry."Expiration Date", 'The original expiration date should be retained.');
        LibraryAssert.AreEqual(ReclassLotNo, ReservationEntry."New Lot No.", 'The new lot no. should match the item journal line');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine.Quantity, -ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Quantity (Base)", -ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_ChangeLot_ChangeExpDate_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        InventoryCreationItemJournalTemplate: Record "Item Journal Template";
        InventoryCreationItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[20];
        ReclassLotNo: Code[20];
        ExpDate: Date;
        NewExpDate: Date;
    begin
        // [SCENARIO] Add item journal reservation entry for lot-tracked item with Qty per UOM=1 via reclassification to change both lot number and expiration date

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A lot-tracked item with expiration date tracking is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(LotItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Initial inventory with lot number and expiration date is posted
        LibraryInventory.CreateItemJournalTemplateByType(InventoryCreationItemJournalTemplate, InventoryCreationItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(InventoryCreationItemJournalBatch, InventoryCreationItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InventoryCreationItemJournalTemplate.Name, InventoryCreationItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := OriginalLotNo;
        ExpDate := WorkDate();
        InitialInspectionInventoryJnlItemJournalLine."Expiration Date" := ExpDate;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, 10);

        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();

        ReservationEntry."Expiration Date" := ExpDate;
        ReservationEntry."New Expiration Date" := ExpDate;
        ReservationEntry.Modify();

        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();
        LibraryAssert.AreEqual(ExpDate, ItemLedgerEntry."Expiration Date", 'test setup failed, expected an expiration date');

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Reclassification disposition is performed to change both lot number and expiration date
        ReclassLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        NewExpDate := CalcDate('<+10D>', WorkDate());

        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Lot No." := ReclassLotNo;
        TempQltyDispositionBuffer."New Expiration Date" := NewExpDate;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with updated tracking information
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(ReclassLotNo, ReservationEntry."New Lot No.", 'The new lot no. should match the item journal line');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(NewExpDate, ReservationEntry."New Expiration Date", 'The expiration date should be updated.');
        LibraryAssert.AreEqual(ExpDate, ReservationEntry."Expiration Date", 'The original expiration date should be retained.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine.Quantity, -ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Quantity (Base)", -ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_SerialTracked_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalSerialNo: Code[20];
        ReclassSerialNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for serial-tracked item with Qty per UOM=1 via reclassification to change serial number

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A serial-tracked item is created
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'Q<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'Q<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, SerialNoSeries.Code, '', SerialItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Initial inventory with serial number is posted
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        OriginalSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine."Serial No." := OriginalSerialNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, OriginalSerialNo, '', 1);
        InitialInspectionInventoryJnlItemJournalLine."Serial No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        if ItemLedgerEntry.FindLast() then;
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Reclassification disposition is performed to change serial number
        ReclassSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);

        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Serial No." := ReclassSerialNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with correct serial number tracking information
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(ReclassSerialNo, ReservationEntry."New Serial No.", 'The new serial no. should match the item journal line');
        LibraryAssert.AreEqual(OriginalSerialNo, ReservationEntry."Serial No.", 'The serial no. should match the original.');
        LibraryAssert.AreEqual(-1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(-1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_ChangeSerial_KeepExpDate_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalSerialNo: Code[20];
        ReclassSerialNo: Code[20];
        ExpDate: Date;
    begin
        // [SCENARIO] Add item journal reservation entry for serial-tracked item with Qty per UOM=1 via reclassification to change serial number while keeping expiration date

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A serial-tracked item with expiration date tracking is created
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'R<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'R<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(SerialItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, SerialNoSeries.Code, '', SerialItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Initial inventory with serial number and expiration date is posted
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        OriginalSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := Location.Code;
        InitialInspectionInventoryJnlItemJournalLine."Serial No." := OriginalSerialNo;
        ExpDate := WorkDate();
        InitialInspectionInventoryJnlItemJournalLine."Expiration Date" := ExpDate;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, OriginalSerialNo, '', 1);
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        ReservationEntry."Expiration Date" := ExpDate;
        ReservationEntry."New Expiration Date" := ExpDate;

        ReservationEntry.Modify();

        InitialInspectionInventoryJnlItemJournalLine."Serial No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();
        LibraryAssert.AreEqual(ExpDate, ItemLedgerEntry."Expiration Date", 'test setup failed, expected an expiration date');

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Reclassification disposition is performed to change the serial number while keeping the expiration date
        ReclassSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);

        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Serial No." := ReclassSerialNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with correct tracking information and retained expiration date
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(ReclassSerialNo, ReservationEntry."New Serial No.", 'The new serial no. should match the item journal line');
        LibraryAssert.AreEqual(OriginalSerialNo, ReservationEntry."Serial No.", 'The serial no. should match the original.');
        LibraryAssert.AreEqual(ExpDate, ReservationEntry."Expiration Date", 'The original expiration date should be retained.');
        LibraryAssert.AreEqual(-1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(-1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_ChangeSerial_ChangeExpDate_Reclass_QtyPerUOM1()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalSerialNo: Code[20];
        ReclassSerialNo: Code[20];
        ExpDate: Date;
        NewExpDate: Date;
    begin
        // [SCENARIO] Add item journal reservation entry for serial-tracked item with Qty per UOM=1 via reclassification to change both serial number and expiration date

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A serial-tracked item with expiration date tracking is created
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(SerialItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Initial inventory with serial number and expiration date is posted
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        OriginalSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := Location.Code;
        InitialInspectionInventoryJnlItemJournalLine."Serial No." := OriginalSerialNo;
        ExpDate := WorkDate();
        InitialInspectionInventoryJnlItemJournalLine."Expiration Date" := ExpDate;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, OriginalSerialNo, '', 1);
        ReservationEntry."Expiration Date" := ExpDate;
        ReservationEntry.Modify();

        InitialInspectionInventoryJnlItemJournalLine."Serial No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();
        LibraryAssert.AreEqual(ExpDate, ItemLedgerEntry."Expiration Date", 'test setup failed, expected an expiration date');

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Reclassification disposition is performed to change both serial number and expiration date
        ReclassSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        NewExpDate := CalcDate('<+10D>', WorkDate());

        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Serial No." := ReclassSerialNo;
        TempQltyDispositionBuffer."New Expiration Date" := NewExpDate;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with updated serial number and expiration date
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(ReclassSerialNo, ReservationEntry."New Serial No.", 'The new serial no. should match the item journal line');
        LibraryAssert.AreEqual(OriginalSerialNo, ReservationEntry."Serial No.", 'The serial no. should match the original.');
        LibraryAssert.AreEqual(NewExpDate, ReservationEntry."New Expiration Date", 'The new expiration date should be updated.');
        LibraryAssert.AreEqual(ExpDate, ReservationEntry."Expiration Date", 'The original expiration date should be retained.');
        LibraryAssert.AreEqual(-1, ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(-1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ReclassJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddItemJnlResEntry_ChangePackage_Reclass_QtyPerUOM1()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReclassJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSeries: Codeunit "No. Series";
        OriginalPackageNo: Code[20];
        ReclassPackageNo: Code[20];
    begin
        // [SCENARIO] Add item journal reservation entry for package-tracked item with Qty per UOM=1 via reclassification to change package number

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Package number series is created and configured in inventory setup
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'T<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'T<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Package-tracked item with package-specific tracking is created
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        LibraryInventory.CreateItem(Item);
        PackageItemTrackingCode."Package Specific Tracking" := true;
        PackageItemTrackingCode.Modify();
        Item.Validate("Item Tracking Code", PackageItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Location is created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Item journal template and batch for initial inventory are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Initial inventory of 10 units with original package number is created and posted
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        OriginalPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := Location.Code;
        InitialInspectionInventoryJnlItemJournalLine."Package No." := OriginalPackageNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");
        ItemLedgerEntry.SetRange("Package No.", InitialInspectionInventoryJnlItemJournalLine."Package No.");

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', '', OriginalPackageNo, 10);
        InitialInspectionInventoryJnlItemJournalLine."Package No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');

        // [GIVEN] Transfer journal template and batch for reclassification are created
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] New package number is generated
        ReclassPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);

        // [GIVEN] Disposition buffer is configured to change package number (new package no., prepare only behavior, item tracked quantity)
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := OriginalPackageNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyDispositionBuffer."New Package No." := ReclassPackageNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";

        // [WHEN] Disposition is performed to create reclassification journal line with new package number
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclassification journal line is created in the batch
        ReclassJnlItemJournalLine.Reset();
        ReclassJnlItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
        LibraryAssert.AreEqual(1, ReclassJnlItemJournalLine.Count(), 'There should be one journal line in the reclass batch.');
        ReclassJnlItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the reclassification
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ReclassJnlItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", ReclassItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", ReclassItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();

        // [THEN] Reservation entry has correct item, location, original package number, new package number, and quantity
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalPackageNo, ReservationEntry."Package No.", 'The package no. should match the original.');
        LibraryAssert.AreEqual(ReclassPackageNo, ReservationEntry."New Package No.", 'The new package no. should match the item journal line');
        LibraryAssert.AreEqual(-InitialInspectionInventoryJnlItemJournalLine."Quantity (Base)", ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(-InitialInspectionInventoryJnlItemJournalLine."Quantity (Base)", ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_NoTracking_NoEntries()
    var
        SourceLocation: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        // [SCENARIO] Add outbound transfer reservation entry for item without tracking - verify no entries are created

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Lot number series is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'U<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'U<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Item without tracking is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(SourceLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Item journal template and batch for initial inventory are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Initial inventory of 10 units at source location without lot number is posted
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := SourceLocation.Code;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', '', 10);
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [GIVEN] Disposition buffer is configured for transfer from source to destination location with specific quantity of 5
        TempQltyInspectionHeader."No." := NoSeries.GetNextNo(LotNoSeries.Code);
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;

        TempQltyInspectionHeader."Location Code" := SourceLocation.Code;
        TempQltyDispositionBuffer."Location Filter" := SourceLocation.Code;
        TempQltyDispositionBuffer."New Location Code" := DestinationLocation.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 5;

        // [WHEN] Disposition is performed to create transfer order
        QltyInspectionUtility.PerformTransferDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        TransferHeader.SetRange("Qlty. Inspection No.", TempQltyInspectionHeader."No.");
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'there should be only one transfer header');
        LibraryAssert.IsTrue(TransferHeader.FindFirst(), 'there should be a transfer header');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'there should be only one transfer line');
        LibraryAssert.IsTrue(TransferLine.FindFirst(), 'there should be a transfer line');
        LibraryAssert.AreEqual(5, TransferLine."Quantity (Base)", '10 were made, but a specific quantity of 5 was requested');
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.AreEqual(0, ReservationEntry.Count(), 'No reservation entries should be created');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_NoQty()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
    begin
        // [SCENARIO] Verify no outbound transfer reservation entries are created for lot-tracked items when transfer quantity is zero

        // [GIVEN] A lot-tracked item is created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'V<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'V<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory with lot number is posted
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Lot No." := LotNo;
        JnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, JnlItemJournalLine, '', LotNo, 10);
        JnlItemJournalLine."Lot No." := '';
        JnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(JnlItemJournalLine);

        // [WHEN] A transfer order is created with zero quantity
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, DestinationLocation.Code, '');
        TransferHeader."Direct Transfer" := true;
        TransferHeader.Modify();
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 0);

        // [THEN] No reservation entries should be created for the transfer line
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.IsTrue(ReservationEntry.IsEmpty(), 'No reservation entries should be created');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_LotAndExpiry()
    var
        SourceLocation: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
        ExpDate: Date;
    begin
        // [SCENARIO] Add outbound transfer reservation entry for lot-tracked item with expiration date using specific quantity via transfer disposition

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A lot-tracked item with expiration date tracking is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'W<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'W<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(LotItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(SourceLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory with lot number and expiration date is posted at source location
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        LotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := SourceLocation.Code;
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := LotNo;
        ExpDate := WorkDate();
        InitialInspectionInventoryJnlItemJournalLine."Expiration Date" := ExpDate;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', LotNo, 10);
        ReservationEntry.Validate("Expiration Date", ExpDate);
        ReservationEntry.Modify();

        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();

        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [WHEN] Transfer disposition is performed with specific quantity for outbound transfer
        TempQltyInspectionHeader."No." := NoSeries.GetNextNo(LotNoSeries.Code);
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := LotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyInspectionHeader."Location Code" := SourceLocation.Code;
        TempQltyDispositionBuffer."Location Filter" := SourceLocation.Code;
        TempQltyDispositionBuffer."New Location Code" := DestinationLocation.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 5;
        QltyInspectionUtility.PerformTransferDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One transfer header and transfer line are created with correct quantity
        TransferHeader.SetRange("Qlty. Inspection No.", TempQltyInspectionHeader."No.");
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'there should be only one transfer header');
        LibraryAssert.IsTrue(TransferHeader.FindFirst(), 'there should be a transfer header');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'there should be only one transfer line');
        LibraryAssert.IsTrue(TransferLine.FindFirst(), 'there should be a transfer line');
        LibraryAssert.AreEqual(5, TransferLine."Quantity (Base)", '10 were made, but a specific quantity of 5 was requested');

        // [THEN] One reservation entry is created with correct lot and expiration date tracking information
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the transfer line.');
        LibraryAssert.AreEqual(SourceLocation.Code, ReservationEntry."Location Code", 'The location code should match the from-location of the transfer line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the item.');
        LibraryAssert.AreEqual(ExpDate, ReservationEntry."Expiration Date", 'The expiration date should match the item.');
        LibraryAssert.AreEqual(-5, ReservationEntry.Quantity, 'The quantity should be negative and match the transfer line.');
        LibraryAssert.AreEqual(-5, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the transfer line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the transfer line.');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_Serial()
    var
        SourceLocation: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
    begin
        // [SCENARIO] Add outbound transfer reservation entry for serial-tracked item with specific quantity via transfer disposition

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item);

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(SourceLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory with serial number is posted at source location
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(Item."Serial Nos.");
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := SourceLocation.Code;
        InitialInspectionInventoryJnlItemJournalLine."Serial No." := SerialNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, SerialNo, '', 1);
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine."Serial No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [WHEN] Transfer disposition is performed with specific quantity for outbound transfer
        TempQltyInspectionHeader."No." := NoSeries.GetNextNo(Item."Serial Nos.");
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := SerialNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;

        TempQltyInspectionHeader."Location Code" := SourceLocation.Code;
        TempQltyDispositionBuffer."Location Filter" := SourceLocation.Code;
        TempQltyDispositionBuffer."New Location Code" := DestinationLocation.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 1;
        QltyInspectionUtility.PerformTransferDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One transfer header and transfer line are created with quantity 1
        TransferHeader.SetRange("Qlty. Inspection No.", TempQltyInspectionHeader."No.");
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'there should be only one transfer header');
        LibraryAssert.IsTrue(TransferHeader.FindFirst(), 'there should be a transfer header');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'there should be only one transfer line');
        LibraryAssert.IsTrue(TransferLine.FindFirst(), 'there should be a transfer line');
        LibraryAssert.AreEqual(1, TransferLine."Quantity (Base)", '1 sn only');

        // [THEN] One reservation entry is created with correct serial number tracking information
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the transfer line.');
        LibraryAssert.AreEqual(SourceLocation.Code, ReservationEntry."Location Code", 'The location code should match the from-location of the transfer line.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'The serial no. should match the transfer line.');
        LibraryAssert.AreEqual(-1, ReservationEntry.Quantity, 'The quantity should be negative and match the transfer line.');
        LibraryAssert.AreEqual(-1, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the transfer line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the transfer line.');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_Serial_NoQty()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        JnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[20];
    begin
        // [SCENARIO] Verify no outbound transfer reservation entries are created for serial-tracked items with zero quantity

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'Y<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'Y<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Serial-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory of 1 unit with serial number is created and posted at source location
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(JnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, JnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        SerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        JnlItemJournalLine."Location Code" := Location.Code;
        JnlItemJournalLine."Serial No." := SerialNo;
        JnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, JnlItemJournalLine, SerialNo, '', 1);
        JnlItemJournalLine."Serial No." := '';
        JnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(JnlItemJournalLine);

        // [GIVEN] Direct transfer order with transfer line for 1 unit is created
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, DestinationLocation.Code, '');
        TransferHeader."Direct Transfer" := true;
        TransferHeader.Modify();
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);

        // [WHEN] Checking for outbound transfer reservation entries

        // [THEN] No reservation entries are created because quantity to track is zero
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.IsTrue(ReservationEntry.IsEmpty(), 'No reservation entries should be created');
    end;

    [Test]
    procedure AddOutboundTransferResEntry_Package()
    var
        InventorySetup: Record "Inventory Setup";
        SourceLocation: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[20];
    begin
        // [SCENARIO] Add outbound transfer reservation entry for package-tracked item with specific quantity via transfer disposition

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Package number series is configured in inventory setup
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'Z<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'Z<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'), 19, '9'));
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Package-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", PackageItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(SourceLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory of 10 units with package number is created and posted at source location
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        PackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine."Location Code" := SourceLocation.Code;
        InitialInspectionInventoryJnlItemJournalLine."Package No." := PackageNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', '', PackageNo, 10);

        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Package No.", InitialInspectionInventoryJnlItemJournalLine."Package No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine."Package No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [GIVEN] Disposition buffer is configured for transfer from source to destination location with specific quantity of 5
        TempQltyInspectionHeader."No." := NoSeries.GetNextNo(PackageNoSeries.Code);
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := PackageNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := InitialInspectionInventoryJnlItemJournalLine.Quantity;
        TempQltyInspectionHeader."Location Code" := SourceLocation.Code;
        TempQltyDispositionBuffer."Location Filter" := SourceLocation.Code;
        TempQltyDispositionBuffer."New Location Code" := DestinationLocation.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 5;

        // [WHEN] Disposition is performed to create transfer order
        QltyInspectionUtility.PerformTransferDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] Transfer header and line are created with correct quantity
        TransferHeader.SetRange("Qlty. Inspection No.", TempQltyInspectionHeader."No.");
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'there should be only one transfer header for ' + TransferHeader.GetFilters());
        LibraryAssert.IsTrue(TransferHeader.FindFirst(), 'there should be a transfer header');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'there should be only one transfer line');
        LibraryAssert.IsTrue(TransferLine.FindFirst(), 'there should be a transfer line');
        LibraryAssert.AreEqual(5, TransferLine."Quantity (Base)", '10 were made, but a specific quantity of 5 was requested');

        // [THEN] One outbound transfer reservation entry is created with correct package number and quantity
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the transfer line.');
        LibraryAssert.AreEqual(SourceLocation.Code, ReservationEntry."Location Code", 'The location code should match the from-location of the transfer line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the transfer line.');
        LibraryAssert.AreEqual(-5, ReservationEntry.Quantity, 'The quantity should be negative and match the transfer line.');
        LibraryAssert.AreEqual(-5, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the transfer line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the transfer line.');
    end;

    [Test]
    procedure CreateOutboundTransferUsingTestQuantityZero()
    var
        InventorySetup: Record "Inventory Setup";
        SourceLocation: Record Location;
        DestinationLocation: Record Location;
        Item: Record Item;
        LotAndPackageNoSeries: Record "No. Series";
        LotAndPackageNoSeriesLine: Record "No. Series Line";
        LotAndPackageItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[20];
        LotNo: Code[20];
    begin
        // [SCENARIO] Create outbound transfer using test quantity when specific quantity is set to zero for lot and package tracked item

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Lot and package number series is configured in inventory setup
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(LotAndPackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotAndPackageNoSeriesLine, LotAndPackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'ZA<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'), 18, '0'), PadStr(Format(CurrentDateTime(), 0, 'ZA<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'), 18, '9'));
        InventorySetup.Validate("Package Nos.", LotAndPackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] Lot and package tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(LotAndPackageItemTrackingCode, false, true, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", LotAndPackageItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Source and destination locations are created
        LibraryWarehouse.CreateLocationWMS(SourceLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] Initial inventory of 10 units with lot and package numbers is created and posted
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        PackageNo := NoSeries.GetNextNo(LotAndPackageNoSeries.Code);
        LotNo := NoSeries.GetNextNo(LotAndPackageNoSeries.Code);

        InitialInspectionInventoryJnlItemJournalLine."Location Code" := SourceLocation.Code;
        InitialInspectionInventoryJnlItemJournalLine."Package No." := PackageNo;
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := LotNo;
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', LotNo, PackageNo, 10);

        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", InitialInspectionInventoryJnlItemJournalLine."Variant Code");
        ItemLedgerEntry.SetRange("Lot No.", InitialInspectionInventoryJnlItemJournalLine."Lot No.");
        ItemLedgerEntry.SetRange("Serial No.", InitialInspectionInventoryJnlItemJournalLine."Serial No.");
        ItemLedgerEntry.SetRange("Package No.", InitialInspectionInventoryJnlItemJournalLine."Package No.");
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine."Package No." := '';
        InitialInspectionInventoryJnlItemJournalLine."Lot No." := '';
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(InitialInspectionInventoryJnlItemJournalLine);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [GIVEN] Disposition buffer is configured for transfer with specific quantity set to zero but test quantity of 3
        TempQltyInspectionHeader."No." := NoSeries.GetNextNo(LotAndPackageNoSeries.Code);
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := PackageNo;
        TempQltyInspectionHeader."Source Lot No." := LotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := 3;
        TempQltyInspectionHeader."Location Code" := SourceLocation.Code;
        TempQltyDispositionBuffer."Location Filter" := SourceLocation.Code;
        TempQltyDispositionBuffer."New Location Code" := DestinationLocation.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 0;

        // [WHEN] Disposition is performed to create transfer order
        QltyInspectionUtility.PerformTransferDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] Transfer header and line are created using test quantity of 3 instead of zero
        TransferHeader.SetRange("Qlty. Inspection No.", TempQltyInspectionHeader."No.");
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'there should be only one transfer header for ' + TransferHeader.GetFilters());
        LibraryAssert.IsTrue(TransferHeader.FindFirst(), 'there should be a transfer header');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'there should be only one transfer line');
        LibraryAssert.IsTrue(TransferLine.FindFirst(), 'there should be a transfer line');
        LibraryAssert.AreEqual(3, TransferLine."Quantity (Base)", '10 were made, but a specific quantity of 3 was requested');

        // [THEN] Outbound transfer reservation entry is created with test quantity and correct tracking numbers
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", Enum::"Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the transfer line.');
        LibraryAssert.AreEqual(SourceLocation.Code, ReservationEntry."Location Code", 'The location code should match the from-location of the transfer line.');
        LibraryAssert.AreEqual(PackageNo, ReservationEntry."Package No.", 'The package no. should match the transfer line.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the transfer line.');
        LibraryAssert.AreEqual(-3, ReservationEntry.Quantity, 'The quantity should be negative and match the transfer line.');
        LibraryAssert.AreEqual(-3, ReservationEntry."Quantity (Base)", 'The Quantity (Base) should be negative and match the transfer line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the transfer line.');
    end;

    [Test]
    procedure DeleteAndRecreatePurchRtnOrderLineTracking()
    var
        Location: Record Location;
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrderPurchaseLine: Record "Purchase Line";
        PurRtnOrderPurchaseHeader: Record "Purchase Header";
        PurPurchRcptLine: Record "Purch. Rcpt. Line";
        PurRtnOrderPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SpecTrackingSpecification: Record "Tracking Specification";
        OrdGenQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        DocCopyDocumentMgt: Codeunit "Copy Document Mgt.";
        RecordRef: RecordRef;
        LotNo: Code[50];
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedLinesNotCopied: Integer;
        UnusedMissingExCostRevLink: Boolean;
    begin
        // [SCENARIO] Delete and recreate purchase return order line tracking for lot-tracked item with positive quantity

        // [GIVEN] Lot number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'AA<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '0'), PadStr(Format(CurrentDateTime(), 0, 'AA<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '9'));

        // [GIVEN] Lot-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location, vendor, purchase order with 10 units are created and received
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryPurchase.CreateVendor(Vendor);
        OrdGenQltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrderPurchaseLine, ReservationEntry);
        OrdGenQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrderPurchaseLine);

        // [GIVEN] Quality inspection template and inspection are created for purchase line
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line");
        RecordRef.GetTable(PurOrderPurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        LotNo := ReservationEntry."Lot No.";
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Purchase return order is created and lines are copied from receipt
        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurRtnOrderPurchaseHeader, Vendor."No.", Location.Code);
        PurPurchRcptLine.SetRange("Order No.", PurOrderPurchaseHeader."No.");
        PurPurchRcptLine.SetRange("Order Line No.", PurOrderPurchaseLine."Line No.");
        PurPurchRcptLine.FindFirst();
        DocCopyDocumentMgt.CopyPurchRcptLinesToDoc(PurRtnOrderPurchaseHeader, PurPurchRcptLine, UnusedLinesNotCopied, UnusedMissingExCostRevLink);

        PurRtnOrderPurchaseLine.SetRange("Document Type", PurRtnOrderPurchaseLine."Document Type"::"Return Order");
        PurRtnOrderPurchaseLine.SetRange("Document No.", PurRtnOrderPurchaseHeader."No.");
        PurRtnOrderPurchaseLine.SetRange("No.", QltyInspectionHeader."Source Item No.");
        PurRtnOrderPurchaseLine.FindFirst();

        // [WHEN] Tracking is deleted and recreated for purchase return order line with quantity 10
        QltyInspectionUtility.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, PurRtnOrderPurchaseLine, 10);

        // [THEN] One reservation entry is created with correct location, lot number, and negative quantity
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source ID", PurRtnOrderPurchaseHeader."No.");
        ReservationEntry.SetRange("Source Ref. No.", PurRtnOrderPurchaseLine."Line No.");
        LibraryAssert.IsTrue(ReservationEntry.Count() = 1, 'There should be one reservation entry.');
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location of the reservation entry should match.');
        LibraryAssert.AreEqual(LotNo, ReservationEntry."Lot No.", 'The lot no. should match the originating lot no.');
        LibraryAssert.AreEqual((PurRtnOrderPurchaseLine."Quantity (Base)" * -1), ReservationEntry."Quantity (Base)", 'The quantity should be negative and match the originating line.');
        LibraryAssert.AreEqual(PurRtnOrderPurchaseLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The quantity per unit of measure should match the originating line.');
    end;

    [Test]
    procedure DeleteAndRecreatePurchRtnOrderLineTracking_NegQtyShouldErr()
    var
        Location: Record Location;
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrderPurchaseLine: Record "Purchase Line";
        PurRtnOrderPurchaseHeader: Record "Purchase Header";
        PurPurchRcptLine: Record "Purch. Rcpt. Line";
        PurRtnOrderPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SpecTrackingSpecification: Record "Tracking Specification";
        OrdGenQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        DocCopyDocumentMgt: Codeunit "Copy Document Mgt.";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedLinesNotCopied: Integer;
        UnusedMissingExCostRevLink: Boolean;
    begin
        // [SCENARIO] Delete and recreate purchase return order line tracking with negative quantity should throw error

        // [GIVEN] Lot number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'BB<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '0'), PadStr(Format(CurrentDateTime(), 0, 'BB<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '9'));

        // [GIVEN] Lot-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Location, vendor, purchase order with 10 units are created and received
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryPurchase.CreateVendor(Vendor);
        OrdGenQltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrderPurchaseLine, ReservationEntry);
        OrdGenQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrderPurchaseLine);

        // [GIVEN] Quality inspection template and inspection are created for purchase line
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line");
        RecordRef.GetTable(PurOrderPurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Purchase return order is created and lines are copied from receipt
        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurRtnOrderPurchaseHeader, Vendor."No.", Location.Code);
        PurPurchRcptLine.SetRange("Order No.", PurOrderPurchaseHeader."No.");
        PurPurchRcptLine.SetRange("Order Line No.", PurOrderPurchaseLine."Line No.");
        PurPurchRcptLine.FindFirst();
        DocCopyDocumentMgt.CopyPurchRcptLinesToDoc(PurRtnOrderPurchaseHeader, PurPurchRcptLine, UnusedLinesNotCopied, UnusedMissingExCostRevLink);

        PurRtnOrderPurchaseLine.SetRange("Document Type", PurRtnOrderPurchaseLine."Document Type"::"Return Order");
        PurRtnOrderPurchaseLine.SetRange("Document No.", PurRtnOrderPurchaseHeader."No.");
        PurRtnOrderPurchaseLine.SetRange("No.", QltyInspectionHeader."Source Item No.");
        PurRtnOrderPurchaseLine.FindFirst();

        // [WHEN] Attempting to delete and recreate tracking with negative quantity of -10
        asserterror QltyInspectionUtility.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, PurRtnOrderPurchaseLine, -10);

        // [THEN] Error is thrown indicating negative tracking entries cannot be created
        LibraryAssert.ExpectedError(StrSubstNo(NegativeTrackingErr, Item."No.", PurRtnOrderPurchaseHeader."No."));
    end;

    [Test]
    procedure DeleteAndRecreatePurchRtnOrderLineTracking_SerialQtyGreaterThan1ShouldErr()
    var
        Location: Record Location;
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrderPurchaseLine: Record "Purchase Line";
        PurRtnOrderPurchaseHeader: Record "Purchase Header";
        PurPurchRcptLine: Record "Purch. Rcpt. Line";
        PurRtnOrderPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SpecTrackingSpecification: Record "Tracking Specification";
        OrdGenQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        DocCopyDocumentMgt: Codeunit "Copy Document Mgt.";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedLinesNotCopied: Integer;
        UnusedMissingExCostRevLink: Boolean;
        Serial: Code[50];
    begin
        // [SCENARIO] Delete and recreate purchase return order line tracking for serial-tracked item with quantity greater than 1 should throw error

        // [GIVEN] Serial number series and tracking code are created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'CC<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '0'), PadStr(Format(CurrentDateTime(), 0, 'CC<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 18, '9'));

        // [GIVEN] Serial-tracked item is created
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Location, vendor, purchase order with 10 units are created and received
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryPurchase.CreateVendor(Vendor);
        OrdGenQltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrderPurchaseLine, ReservationEntry);
        OrdGenQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrderPurchaseLine);

        // [GIVEN] Quality inspection template and inspection are created for purchase line with serial number tracking
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line");
        RecordRef.GetTable(PurOrderPurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        Serial := ReservationEntry."Serial No.";
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Purchase return order is created and lines are copied from receipt
        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurRtnOrderPurchaseHeader, Vendor."No.", Location.Code);
        PurPurchRcptLine.SetRange("Order No.", PurOrderPurchaseHeader."No.");
        PurPurchRcptLine.SetRange("Order Line No.", PurOrderPurchaseLine."Line No.");
        PurPurchRcptLine.FindFirst();
        DocCopyDocumentMgt.CopyPurchRcptLinesToDoc(PurRtnOrderPurchaseHeader, PurPurchRcptLine, UnusedLinesNotCopied, UnusedMissingExCostRevLink);

        PurRtnOrderPurchaseLine.SetRange("Document Type", PurRtnOrderPurchaseLine."Document Type"::"Return Order");
        PurRtnOrderPurchaseLine.SetRange("Document No.", PurRtnOrderPurchaseHeader."No.");
        PurRtnOrderPurchaseLine.SetRange("No.", QltyInspectionHeader."Source Item No.");
        PurRtnOrderPurchaseLine.FindFirst();

        // [WHEN] Attempting to delete and recreate tracking with quantity 10 for serial-tracked item
        asserterror QltyInspectionUtility.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, PurRtnOrderPurchaseLine, 10);

        // [THEN] Error is thrown indicating serial number has already been entered
        LibraryAssert.ExpectedError(StrSubstNo(SNAlreadyEnteredErr, Serial));
    end;

    [Test]
    procedure GetIsWarehouseTracked_True()
    var
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialItemTrackingCode: Record "Item Tracking Code";
        IsTracked: Boolean;
    begin
        // [SCENARIO] Verify GetIsWarehouseTracked returns true for serial-tracked item

        // [GIVEN] Serial-tracked item is created
        Initialize();
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [WHEN] Checking if item is warehouse tracked
        IsTracked := QltyInspectionUtility.GetIsWarehouseTracked(Item."No.");

        // [THEN] Result is true indicating item is tracked
        LibraryAssert.IsTrue(IsTracked, 'Should return true (is tracked).');
    end;

    [Test]
    procedure GetIsWarehouseTracked_False()
    var
        Item: Record Item;
        IsTracked: Boolean;
    begin
        // [SCENARIO] Verify GetIsWarehouseTracked returns false for non-tracked item

        // [GIVEN] Item without tracking is created
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [WHEN] Checking if item is warehouse tracked
        IsTracked := QltyInspectionUtility.GetIsWarehouseTracked(Item."No.");

        // [THEN] Result is false indicating item is not tracked
        LibraryAssert.IsFalse(IsTracked, 'Should return false (is not tracked).');
    end;

    [Test]
    procedure SetLotBlockState_Block()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        LotNoInformation: Record "Lot No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        LotNo: Code[50];
    begin
        // [SCENARIO] Set lot block state to blocked for a lot-tracked item

        // [GIVEN] Lot-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with lot number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        LotNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Lot No." := LotNo;

        // [WHEN] Setting lot block state to blocked
        QltyInspectionUtility.SetLotBlockState(TempQltyInspectionHeader, true);

        // [THEN] Lot number information shows lot is blocked
        LotNoInformation.Get(Item."No.", '', LotNo);
        LibraryAssert.IsTrue(LotNoInformation.Blocked, 'Should be blocked.');
    end;

    [Test]
    procedure SetLotBlockState_Unblock()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        LotNoInformation: Record "Lot No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        LotNo: Code[50];
    begin
        // [SCENARIO] Set lot block state to unblocked for a previously blocked lot

        // [GIVEN] Lot-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with lot number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        LotNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Lot No." := LotNo;

        // [GIVEN] Lot number information is created as blocked
        LotNoInformation.Init();
        LotNoInformation."Item No." := TempQltyInspectionHeader."Source Item No.";
        LotNoInformation."Lot No." := TempQltyInspectionHeader."Source Lot No.";
        LotNoInformation.Insert(true);
        LotNoInformation.Blocked := true;
        LotNoInformation.Modify();

        // [WHEN] Setting lot block state to unblocked
        QltyInspectionUtility.SetLotBlockState(TempQltyInspectionHeader, false);

        // [THEN] Lot number information shows lot is not blocked
        LotNoInformation.Get(Item."No.", '', LotNo);
        LibraryAssert.IsFalse(LotNoInformation.Blocked, 'Should not be blocked.');
    end;

    [Test]
    procedure SetSerialBlockState_Block()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        SerialNoInformation: Record "Serial No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [SCENARIO] Set serial block state to blocked for a serial-tracked item

        // [GIVEN] Serial-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with serial number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        SerialNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Serial No." := SerialNo;

        // [WHEN] Setting serial block state to blocked
        QltyInspectionUtility.SetSerialBlockState(TempQltyInspectionHeader, true);

        // [THEN] Serial number information shows serial is blocked
        SerialNoInformation.Get(Item."No.", '', SerialNo);
        LibraryAssert.IsTrue(SerialNoInformation.Blocked, 'Should be blocked.');
    end;

    [Test]
    procedure SetSerialBlockState_Unblock()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        SerialNoInformation: Record "Serial No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [SCENARIO] Set serial block state to unblocked for a previously blocked serial number

        // [GIVEN] Serial-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with serial number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        SerialNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Serial No." := SerialNo;

        // [GIVEN] Serial number information is created as blocked
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := TempQltyInspectionHeader."Source Item No.";
        SerialNoInformation."Serial No." := TempQltyInspectionHeader."Source Serial No.";
        SerialNoInformation.Insert(true);
        SerialNoInformation.Blocked := true;
        SerialNoInformation.Modify();

        // [WHEN] Setting serial block state to unblocked
        QltyInspectionUtility.SetSerialBlockState(TempQltyInspectionHeader, false);

        // [THEN] Serial number information shows serial is not blocked
        SerialNoInformation.Get(Item."No.", '', SerialNo);
        LibraryAssert.IsFalse(SerialNoInformation.Blocked, 'Should not be blocked.');
    end;

    [Test]
    procedure SetPackageBlockState_Block()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        PackageNoInformation: Record "Package No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[50];
    begin
        // [SCENARIO] Set package block state to blocked for a package-tracked item

        // [GIVEN] Package-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with package number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        PackageNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Package No." := PackageNo;

        // [WHEN] Setting package block state to blocked
        QltyInspectionUtility.SetPackageBlockState(TempQltyInspectionHeader, true);

        // [THEN] Package number information shows package is blocked
        PackageNoInformation.Get(Item."No.", '', PackageNo);
        LibraryAssert.IsTrue(PackageNoInformation.Blocked, 'Should be blocked.');
    end;

    [Test]
    procedure SetPackageBlockState_Unblock()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        PackageNoInformation: Record "Package No. Information";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[50];
    begin
        // [SCENARIO] Set package block state to unblocked for a previously blocked package number

        // [GIVEN] Package-tracked item with number series is created
        Initialize();
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] Inspection header with package number is prepared
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        PackageNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        TempQltyInspectionHeader."Source Package No." := PackageNo;

        // [GIVEN] Package number information is created as blocked
        PackageNoInformation.Init();
        PackageNoInformation."Item No." := TempQltyInspectionHeader."Source Item No.";
        PackageNoInformation."Package No." := TempQltyInspectionHeader."Source Package No.";
        PackageNoInformation.Insert(true);
        PackageNoInformation.Blocked := true;
        PackageNoInformation.Modify();

        // [WHEN] Setting package block state to unblocked
        QltyInspectionUtility.SetPackageBlockState(TempQltyInspectionHeader, false);

        // [THEN] Package number information shows package is not blocked
        PackageNoInformation.Get(Item."No.", '', PackageNo);
        LibraryAssert.IsFalse(PackageNoInformation.Blocked, 'Should not be blocked.');
    end;

    [Test]
    procedure IsLotTracked_True()
    var
        Item: Record Item;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is lot-tracked returns true for lot-tracked item

        // [GIVEN] Lot-tracked item is created
        Initialize();
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [WHEN] Checking if item is lot-tracked
        TempItemTrackingSetup."Lot No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is true indicating item is lot-tracked
        LibraryAssert.IsTrue(TempItemTrackingSetup."Lot No. Required", 'Should return is lot-tracked (true)');
    end;

    [Test]
    procedure IsLotTracked_False()
    var
        Item: Record Item;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is lot-tracked returns false for non-lot-tracked item

        // [GIVEN] Item without lot tracking is created
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [WHEN] Checking if item is lot-tracked
        TempItemTrackingSetup."Lot No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is false indicating item is not lot-tracked
        LibraryAssert.IsFalse(TempItemTrackingSetup."Lot No. Required", 'Should return is not lot-tracked (false)');
    end;

    [Test]
    procedure IsSerialTracked_True()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is serial-tracked returns true for serial-tracked item

        // [GIVEN] Serial-tracked item is created
        Initialize();
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [WHEN] Checking if item is serial-tracked
        TempItemTrackingSetup."Serial No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is true indicating item is serial-tracked
        LibraryAssert.IsTrue(TempItemTrackingSetup."Serial No. Required", 'Should return is serial-tracked (true)');
    end;

    [Test]
    procedure IsSerialTracked_False()
    var
        Item: Record Item;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is serial-tracked returns false for non-serial-tracked item

        // [GIVEN] Item without serial tracking is created
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [WHEN] Checking if item is serial-tracked
        TempItemTrackingSetup."Serial No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is false indicating item is not serial-tracked
        LibraryAssert.IsFalse(TempItemTrackingSetup."Serial No. Required", 'Should return is not serial-tracked (false)');
    end;

    [Test]
    procedure IsPackageTracked_True()
    var
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is package-tracked returns true for package-tracked item

        // [GIVEN] Package-tracked item is created
        Initialize();
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [WHEN] Checking if item is package-tracked
        TempItemTrackingSetup."Package No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is true indicating item is package-tracked
        LibraryAssert.IsTrue(TempItemTrackingSetup."Package No. Required", 'Should return is package-tracked (true)');
    end;

    [Test]
    procedure IsPackageTracked_False()
    var
        Item: Record Item;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        // [SCENARIO] Verify that checking if an item is package-tracked returns false for non-package-tracked item

        // [GIVEN] Item without package tracking is created
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [WHEN] Checking if item is package-tracked
        TempItemTrackingSetup."Package No. Required" := true;
        QltyInspectionUtility.IsItemTrackingUsed(Item."No.", TempItemTrackingSetup);

        // [THEN] Result is false indicating item is not package-tracked
        LibraryAssert.IsFalse(TempItemTrackingSetup."Package No. Required", 'Should return is not package-tracked (false)');
    end;

    [Test]
    procedure ItemTrackingDetailsAreNotPopulatedOnTestForNonTrackingItem()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        LotTrackedItem: Record Item;
        NonTrackingItem: Record Item;
        LotNoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        NoSeries: Codeunit "No. Series";
    begin
        // [SCENARIO 615767] Verify that item tracking details are not populated on quality inspection test for non-tracking item
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] The generation rule is set to trigger on purchase order receive and automatic only
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::"Automatic only";
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        QltyInspectionGenRule.Modify();

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Lot-tracked item with no. series is created
        QltyInspectionUtility.CreateLotTrackedItem(LotTrackedItem, LotNoSeries);

        // [GIVEN] An Non tracking item is created
        LibraryInventory.CreateItem(NonTrackingItem);

        // [GIVEN] A purchase order with the Lot trackeditem is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, LotTrackedItem, PurchaseHeader, PurchaseLine);

        // [GIVEN] Add purchase line with the Non tracking item to the purchase order
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, NonTrackingItem."No.", LibraryRandom.RandInt(10));

        // [WHEN] The purchase order is received
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Find first test and verify item tracking details are populated for Lot tracked item
        FindQltyInspectionHeader(QltyInspectionHeader, LotTrackedItem."No.");
        LibraryAssert.AreEqual(LotTrackedItem."No.", QltyInspectionHeader."Source Item No.", 'Should be same item.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Lot No.", NoSeries.GetLastNoUsed(LotNoSeries.Code), 'Lot No. should be populated.');

        // [THEN] Find first test and verify item tracking details are populated for Lot tracked item
        FindQltyInspectionHeader(QltyInspectionHeader, NonTrackingItem."No.");
        LibraryAssert.AreEqual(NonTrackingItem."No.", QltyInspectionHeader."Source Item No.", 'Should be same item.');
        LibraryAssert.IsTrue(QltyInspectionHeader."Source Lot No." = '', 'Lot No. should not be populated.');

        QltyInspectionGenRule.Delete();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    local procedure FindQltyInspectionHeader(var QltyInspectionHeader: Record "Qlty. Inspection Header"; ItemNo: Code[20])
    begin
        QltyInspectionHeader.Reset();
        QltyInspectionHeader.SetRange("Source Item No.", ItemNo);
        QltyInspectionHeader.FindFirst();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
    end;
}
