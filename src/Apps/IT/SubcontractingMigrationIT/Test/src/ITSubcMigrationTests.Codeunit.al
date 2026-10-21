#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.Subcontracting.Migration;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 149956 "IT Subc. Migration Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    ObsoleteState = Pending;
    ObsoleteReason = 'The legacy subcontracting feature is being deprecated.';
    ObsoleteTag = '29.0';

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        PurchaseReceiptNo: Code[20];
        PurchaseReceiptLineNo: Integer;
        GuardedProductionBOMNo: Code[20];
        SubcontractingLocationsBlockedErr: Label 'Migration can''t start because one or more subcontracting locations are invalid.';
        UnsupportedSubcontractingLocationErr: Label 'Migration can''t start because subcontracting location %1 uses unsupported warehouse settings: %2. Update the location or subcontracting setup, and then run the precheck again.', Comment = '%1 = location code, %2 = unsupported warehouse settings';
        MissingSubcontractingLocationErr: Label 'Migration can''t start because legacy subcontracting data references location %1, but that location doesn''t exist. Update the legacy vendor or purchase document, and then run the precheck again.', Comment = '%1 = location code';
        OpenWIPPurchaseOrdersExistErr: Label 'There are still open purchase orders with WIP Items. All purchase orders with WIP Items must be completed before disabling Legacy Subcontracting.';

    [Test]
    [Scope('OnPrem')]
    procedure MigrateVendors_CopiesSubcLocationCode()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateVendors copies "Subcontracting Location Code" to "Subc. Location Code"
        Initialize();

        // [GIVEN] A vendor with "Subcontracting Location Code" set and "Subc. Location Code" empty
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := Location.Code;
        Vendor."Subc. Location Code" := '';
        Vendor.Modify(false);

        // [WHEN] MigrateVendors is called
        ITSubcMigration.MigrateVendors();

        // [THEN] Vendor."Subc. Location Code" equals the legacy location code
        Vendor.Get(Vendor."No.");
        Assert.AreEqual(Location.Code, Vendor."Subc. Location Code",
            'MigrateVendors should copy "Subcontracting Location Code" to "Subc. Location Code".');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateSubcontractorPrices_CreatesNewPriceWithAllMappedFields()
    var
#pragma warning disable AL0432
        LegacyPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        NewPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        StartDate: Date;
        EndDate: Date;
        DirectUnitCost1, MinimumQuantity1, MinimumAmount1 : Decimal;
        DirectUnitCost2, MinimumQuantity2, MinimumAmount2 : Decimal;
        DirectUnitCostToCheck, MinimumQuantityToCheck, MinimumAmountToCheck : Decimal;
        i: Integer;
    begin
        // [SCENARIO] MigrateSubcontractorPrices creates a new "Subcontractor Price" with all fields mapped from the legacy record
        Initialize();

        // [GIVEN] A vendor, item, and work center
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);

        // [GIVEN] two legacy "Subcontractor Prices" record with all fields populated
        StartDate := WorkDate();
        EndDate := CalcDate('<+30D>', StartDate);
        DirectUnitCost1 := 150;
        MinimumQuantity1 := 10;
        MinimumAmount1 := 1;
        CreateLegacySubcontractorPrice(LegacyPrice,
            WorkCenter."No.", Vendor."No.", Item."No.", Item."Base Unit of Measure",
            StartDate, EndDate, DirectUnitCost1, MinimumQuantity1, MinimumAmount1);

        DirectUnitCost2 := 75;
        MinimumQuantity2 := 5;
        MinimumAmount2 := 2;
        CreateLegacySubcontractorPrice(LegacyPrice,
            WorkCenter."No.", Vendor."No.", Item."No.", Item."Base Unit of Measure",
            StartDate, EndDate, DirectUnitCost2, MinimumQuantity2, MinimumAmount2);

        // [WHEN] MigrateSubcontractorPrices is called
        ITSubcMigration.MigrateSubcontractorPrices();

        // [THEN] two new "Subcontractor Price" exists with all fields correctly mapped
        i := 0;
        NewPrice.SetRange("Vendor No.", Vendor."No.");
        NewPrice.SetRange("Item No.", Item."No.");
        Assert.RecordCount(NewPrice, 2);
#pragma warning disable AA0181
        NewPrice.FindSet();
#pragma warning restore AA0181
        repeat
            DirectUnitCostToCheck := (i = 0) ? DirectUnitCost1 : DirectUnitCost2;
            MinimumQuantityToCheck := (i = 0) ? MinimumQuantity1 : MinimumQuantity2;
            MinimumAmountToCheck := (i = 0) ? MinimumAmount1 : MinimumAmount2;

#pragma warning disable AA0233
            Assert.IsTrue(
                NewPrice.Get(Vendor."No.", Item."No.", WorkCenter."No.", '', '', StartDate, Item."Base Unit of Measure", MinimumQuantityToCheck, ''),
                'A new Subcontractor Price record should have been created.');
#pragma warning restore AA0233
            Assert.AreEqual(WorkCenter."No.", NewPrice."Work Center No.", '"Work Center No." must match.');
            Assert.AreEqual(Vendor."No.", NewPrice."Vendor No.", '"Vendor No." must match.');
            Assert.AreEqual(Item."No.", NewPrice."Item No.", '"Item No." must match.');
            Assert.AreEqual(StartDate, NewPrice."Starting Date", '"Starting Date" must match legacy "Start Date".');
            Assert.AreEqual(EndDate, NewPrice."Ending Date", '"Ending Date" must match legacy "End Date".');
            Assert.AreEqual(DirectUnitCostToCheck, NewPrice."Direct Unit Cost", '"Direct Unit Cost" must match.');
            Assert.AreEqual(MinimumQuantityToCheck, NewPrice."Minimum Quantity", '"Minimum Quantity" must match.');
            Assert.AreEqual(MinimumAmountToCheck, NewPrice."Minimum Amount", '"Minimum Amount" must match.');
            i += 1;
        until NewPrice.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateSubcontractorPrices_UpdatesExistingWithoutDuplicate()
    var
#pragma warning disable AL0432
        LegacyPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        NewPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        CountBefore: Integer;
        StartDate: Date;
    begin
        // [SCENARIO] MigrateSubcontractorPrices updates an existing "Subcontractor Price" without creating a duplicate
        Initialize();

        // [GIVEN] A vendor, item, and work center
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        StartDate := WorkDate();

        // [GIVEN] A legacy "Subcontractor Prices" record with Direct Unit Cost = 100
        CreateLegacySubcontractorPrice(LegacyPrice,
            WorkCenter."No.", Vendor."No.", Item."No.", Item."Base Unit of Measure",
            StartDate, 0D, 100, 1, 1);

        // [GIVEN] An existing "Subcontractor Price" with the same PK but stale Direct Unit Cost = 50
        NewPrice.Init();
        NewPrice."Vendor No." := Vendor."No.";
        NewPrice."Item No." := Item."No.";
        NewPrice."Work Center No." := WorkCenter."No.";
        NewPrice."Standard Task Code" := '';
        NewPrice."Variant Code" := '';
        NewPrice."Starting Date" := StartDate;
        NewPrice."Unit of Measure Code" := Item."Base Unit of Measure";
        NewPrice."Minimum Quantity" := 1;
        NewPrice."Currency Code" := '';
        NewPrice."Direct Unit Cost" := 50;
        NewPrice.Insert(false);

        NewPrice.Reset();
        NewPrice.SetRange("Vendor No.", Vendor."No.");
        NewPrice.SetRange("Item No.", Item."No.");
        CountBefore := NewPrice.Count();

        // [WHEN] MigrateSubcontractorPrices is called
        ITSubcMigration.MigrateSubcontractorPrices();

        // [THEN] No duplicate record was created
        NewPrice.Reset();
        NewPrice.SetRange("Vendor No.", Vendor."No.");
        NewPrice.SetRange("Item No.", Item."No.");
        Assert.RecordCount(NewPrice, CountBefore);

        // [THEN] The existing record was updated with the legacy Direct Unit Cost
        NewPrice.Get(Vendor."No.", Item."No.", WorkCenter."No.", '', '', StartDate, Item."Base Unit of Measure", 1, '');
        Assert.AreEqual(100, NewPrice."Direct Unit Cost",
            '"Direct Unit Cost" should be updated to the legacy value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigratePurchaseHeaders_CopiesSubcLocationCode()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Location: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigratePurchaseHeaders copies "Subcontracting Location Code" to "Subc. Location Code"
        Initialize();

        // [GIVEN] A purchase order with "Subcontracting Location Code" set and "Subc. Location Code" empty
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := Location.Code;
        PurchaseHeader."Subc. Location Code" := '';
        PurchaseHeader.Modify(false);

        // [WHEN] MigratePurchaseHeaders is called
        ITSubcMigration.MigratePurchaseHeaders();

        // [THEN] "Subc. Location Code" equals the legacy location code
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(Location.Code, PurchaseHeader."Subc. Location Code",
            'MigratePurchaseHeaders should copy "Subcontracting Location Code" to "Subc. Location Code".');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigratePurchaseLines_SetsLastOperationType()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
    begin
        // [SCENARIO] MigratePurchaseLines sets "Subc. Purchase Line Type" = LastOperation when the routing line has no next operation
        Initialize();

        // [GIVEN] A released prod. order setup where the routing line has "Next Operation No." = ''
        InsertReleasedProdOrderSetup(ProductionOrder, ProdOrderLine, ProdOrderRoutingLine, '');

        // [GIVEN] A purchase order line linked to that routing line (WIP Item = false)
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
        PurchaseLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        PurchaseLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        PurchaseLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := false;
#pragma warning restore AL0432
        PurchaseLine."Subc. Purchase Line Type" := SubcPurchaseLineType::None;
        PurchaseLine.Modify(false);

        // [WHEN] MigratePurchaseLines is called
        ITSubcMigration.MigratePurchaseLines();

        // [THEN] "Subc. Purchase Line Type" = LastOperation
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            SubcPurchaseLineType::LastOperation,
            PurchaseLine."Subc. Purchase Line Type",
            'MigratePurchaseLines should set LastOperation when no next operation exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigratePurchaseLines_SetsNotLastOperationType()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
    begin
        // [SCENARIO] MigratePurchaseLines sets "Subc. Purchase Line Type" = NotLastOperation when the routing line has a next operation
        Initialize();

        // [GIVEN] A released prod. order setup where the routing line has "Next Operation No." = '20'
        InsertReleasedProdOrderSetup(ProductionOrder, ProdOrderLine, ProdOrderRoutingLine, '20');

        // [GIVEN] A purchase order line linked to that routing line (WIP Item = false)
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
        PurchaseLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        PurchaseLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        PurchaseLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := false;
#pragma warning restore AL0432
        PurchaseLine."Subc. Purchase Line Type" := SubcPurchaseLineType::None;
        PurchaseLine.Modify(false);

        // [WHEN] MigratePurchaseLines is called
        ITSubcMigration.MigratePurchaseLines();

        // [THEN] "Subc. Purchase Line Type" = NotLastOperation
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            SubcPurchaseLineType::NotLastOperation,
            PurchaseLine."Subc. Purchase Line Type",
            'MigratePurchaseLines should set NotLastOperation when a next operation exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigratePurchaseLines_SetsNoneWhenNoProdOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
    begin
        // [SCENARIO] MigratePurchaseLines sets "Subc. Purchase Line Type" = None when no matching released production order/ prod order line / prod oder routing line exists
        Initialize();

        // [GIVEN] A purchase order line with "Operation No." set but referencing a non-existent production order
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Operation No." := '10';
        PurchaseLine."Prod. Order No." := LibraryUtility.GenerateGUID();
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := false;
#pragma warning restore AL0432
        PurchaseLine."Subc. Purchase Line Type" := SubcPurchaseLineType::None;
        PurchaseLine.Modify(false);

        // [WHEN] MigratePurchaseLines is called
        ITSubcMigration.MigratePurchaseLines();

        // [THEN] "Subc. Purchase Line Type" remains None
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            SubcPurchaseLineType::None,
            PurchaseLine."Subc. Purchase Line Type",
            'MigratePurchaseLines should set None when no matching released production order exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigratePurchaseLines_SkipsWIPItemLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
    begin
        // [SCENARIO] MigratePurchaseLines does not process lines where "WIP Item" = true
        Initialize();

        // [GIVEN] A purchase order line with "WIP Item" = true and "Operation No." set
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Operation No." := '10';
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := true;
#pragma warning restore AL0432
        PurchaseLine."Subc. Purchase Line Type" := SubcPurchaseLineType::NotLastOperation;
        PurchaseLine.Modify(false);

        // [WHEN] MigratePurchaseLines is called
        ITSubcMigration.MigratePurchaseLines();

        // [THEN] "Subc. Purchase Line Type" remains NotLastOperation (line was filtered out)
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            SubcPurchaseLineType::NotLastOperation,
            PurchaseLine."Subc. Purchase Line Type",
            'MigratePurchaseLines should skip lines with WIP Item = true.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateTransferLines_CopiesAllSubcFields()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        PurchOrderNo: Code[20];
        ProdOrderNo: Code[20];
        WorkCenterNo: Code[20];
        RoutingNo: Code[20];
        OperationNo: Code[10];
    begin
        // [SCENARIO] MigrateTransferLines copies all 9 legacy subcontracting fields to the new Subc. fields for WIP Item = false lines
        Initialize();

        // [GIVEN] A transfer header and a non-WIP transfer line with all legacy Subc. fields populated
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        PurchOrderNo := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Subcontr. Purch. Order No."), TransferLine.RecordId().TableNo());
        ProdOrderNo := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Prod. Order No."), TransferLine.RecordId().TableNo());
        WorkCenterNo := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Work Center No."), TransferLine.RecordId().TableNo());
        RoutingNo := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Routing No."), TransferLine.RecordId().TableNo());
        OperationNo := '10';

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := false;
        TransferLine."Subcontr. Purch. Order No." := PurchOrderNo;
        TransferLine."Subcontr. Purch. Order Line" := 20000;
        TransferLine."Prod. Order No." := ProdOrderNo;
        TransferLine."Prod. Order Line No." := 10000;
        TransferLine."Prod. Order Comp. Line No." := 30000;
        TransferLine."Routing No." := RoutingNo;
        TransferLine."Routing Reference No." := 10000;
        TransferLine."Work Center No." := WorkCenterNo;
        TransferLine."Operation No." := OperationNo;
        TransferLine.Insert(false);

        // [WHEN] MigrateTransferLines is called
        ITSubcMigration.MigrateTransferLines();

        // [THEN] All 9 Subc. fields on the transfer line are populated with the legacy values
        TransferLine.Get(TransferHeader."No.", 10000);
        Assert.AreEqual(PurchOrderNo, TransferLine."Subc. Purch. Order No.", '"Subc. Purch. Order No." must match.');
        Assert.AreEqual(20000, TransferLine."Subc. Purch. Order Line No.", '"Subc. Purch. Order Line No." must match.');
        Assert.AreEqual(ProdOrderNo, TransferLine."Subc. Prod. Order No.", '"Subc. Prod. Order No." must match.');
        Assert.AreEqual(10000, TransferLine."Subc. Prod. Order Line No.", '"Subc. Prod. Order Line No." must match.');
        Assert.AreEqual(30000, TransferLine."Subc. Prod. Ord. Comp Line No.", '"Subc. Prod. Ord. Comp Line No." must match.');
        Assert.AreEqual(RoutingNo, TransferLine."Subc. Routing No.", '"Subc. Routing No." must match.');
        Assert.AreEqual(10000, TransferLine."Subc. Routing Reference No.", '"Subc. Routing Reference No." must match.');
        Assert.AreEqual(WorkCenterNo, TransferLine."Subc. Work Center No.", '"Subc. Work Center No." must match.');
        Assert.AreEqual(OperationNo, TransferLine."Subc. Operation No.", '"Subc. Operation No." must match.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateTransferLines_SkipsWIPItemLines()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateTransferLines does not modify transfer lines where "WIP Item" = true
        Initialize();

        // [GIVEN] A transfer header and a WIP transfer line with "Subcontr. Purch. Order No." set
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := true;
        TransferLine."Subcontr. Purch. Order No." := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Subcontr. Purch. Order No."), TransferLine.RecordId().TableNo());
        TransferLine.Insert(false);

        // [WHEN] MigrateTransferLines is called
        ITSubcMigration.MigrateTransferLines();

        // [THEN] "Subc. Purch. Order No." remains empty (line was filtered out)
        TransferLine.Get(TransferHeader."No.", 10000);
        Assert.AreEqual('', TransferLine."Subc. Purch. Order No.",
            'MigrateTransferLines should skip transfer lines with WIP Item = true.');
    end;

    // *** 11-13. Transfer Headers ***

    [Test]
    [Scope('OnPrem')]
    procedure MigrateTransferHeaders_CopiesReturnOrder()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateTransferHeaders copies "Return Order" to "Subc. Return Order"
        Initialize();

        // [GIVEN] A transfer header with "Return Order" = true and "Subc. Return Order" = false
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader."Return Order" := true;
        TransferHeader."Subc. Return Order" := false;
        TransferHeader.Modify(false);

        // [WHEN] MigrateTransferHeaders is called
        ITSubcMigration.MigrateTransferHeaders();

        // [THEN] "Subc. Return Order" = true
        TransferHeader.Get(TransferHeader."No.");
        Assert.IsTrue(TransferHeader."Subc. Return Order",
            'MigrateTransferHeaders should copy "Return Order" = true to "Subc. Return Order".');

        // Cleanup
        TransferHeader.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateTransferHeaders_SetsSubcontractingSourceTypeWhenSubcLineExists()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        TransferSourceType: Enum "Transfer Source Type";
    begin
        // [SCENARIO] MigrateTransferHeaders sets "Subc. Source Type" = Subcontracting when at least one line has "Subc. Purch. Order No." set
        Initialize();

        // [GIVEN] A transfer header with a line that has "Subc. Purch. Order No." already populated
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := false;
        TransferLine."Subc. Purch. Order No." := LibraryUtility.GenerateRandomCode20(TransferLine.FieldNo("Subc. Purch. Order No."), TransferLine.RecordId().TableNo());
        TransferLine.Insert(false);

        // [WHEN] MigrateTransferHeaders is called
        ITSubcMigration.MigrateTransferHeaders();

        // [THEN] "Subc. Source Type" = Subcontracting
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(
            TransferSourceType::Subcontracting,
            TransferHeader."Subc. Source Type",
            '"Subc. Source Type" should be Subcontracting when a line has "Subc. Purch. Order No." set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateTransferHeaders_SetsEmptySourceTypeWhenNoSubcLines()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        TransferSourceType: Enum "Transfer Source Type";
    begin
        // [SCENARIO] MigrateTransferHeaders sets "Subc. Source Type" = Empty when no line has "Subc. Purch. Order No." set
        Initialize();

        // [GIVEN] A transfer header with a line that has no "Subc. Purch. Order No."
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := false;
        TransferLine."Subc. Purch. Order No." := '';
        TransferLine.Insert(false);

        // [WHEN] MigrateTransferHeaders is called
        ITSubcMigration.MigrateTransferHeaders();

        // [THEN] "Subc. Source Type" = Empty
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(
            TransferSourceType::Empty,
            TransferHeader."Subc. Source Type",
            '"Subc. Source Type" should be Empty when no line has "Subc. Purch. Order No." set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateProdOrderComponents_CopiesOriginalLocation()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateProdOrderComponents copies "Original Location" to "Subc. Original Location Code"
        Initialize();

        // [GIVEN] A production order component with "Original Location" set and "Subc. Original Location Code" empty
        LibraryWarehouse.CreateLocation(Location);

        ProdOrderComponent.Init();
        ProdOrderComponent.Status := "Production Order Status"::Released;
        ProdOrderComponent."Prod. Order No." := LibraryUtility.GenerateRandomCode20(ProdOrderComponent.FieldNo("Prod. Order No."), ProdOrderComponent.RecordId().TableNo());
        ProdOrderComponent."Prod. Order Line No." := 10000;
        ProdOrderComponent."Line No." := 10000;
#pragma warning disable AL0432
        ProdOrderComponent."Original Location" := Location.Code;
#pragma warning restore AL0432
        ProdOrderComponent."Subc. Original Location Code" := '';
        ProdOrderComponent.Insert(false);

        // [WHEN] MigrateProdOrderComponents is called
        ITSubcMigration.MigrateProdOrderComponents();

        // [THEN] "Subc. Original Location Code" equals the legacy "Original Location"
        ProdOrderComponent.Get(
            ProdOrderComponent.Status,
            ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.",
            ProdOrderComponent."Line No.");
        Assert.AreEqual(Location.Code, ProdOrderComponent."Subc. Original Location Code",
            'MigrateProdOrderComponents should copy "Original Location" to "Subc. Original Location Code".');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMigration_MapsLegacyProcurementToComponentSupplyMethods()
    var
        ConsignmentProductionBOMLine: Record "Production BOM Line";
        TransferProductionBOMLine: Record "Production BOM Line";
        ConsignmentProdOrderComponent: Record "Prod. Order Component";
        TransferProdOrderComponent: Record "Prod. Order Component";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 649440] Migration maps legacy subcontractor procurement to component supply methods
        Initialize();

        // [GIVEN] Linked BOM and production order components for vendors with subcontractor procurement enabled and disabled
        CreateComponentSupplyMethodMigrationScenario(ConsignmentProductionBOMLine, ConsignmentProdOrderComponent, true);
        CreateComponentSupplyMethodMigrationScenario(TransferProductionBOMLine, TransferProdOrderComponent, false);

        // [WHEN] The legacy subcontracting data is migrated
        ITSubcMigration.RunMigration();

        // [THEN] Procurement-enabled components use consignment at vendor
        ConsignmentProductionBOMLine.Get(
            ConsignmentProductionBOMLine."Production BOM No.",
            ConsignmentProductionBOMLine."Version Code",
            ConsignmentProductionBOMLine."Line No.");
        Assert.AreEqual(
            "Component Supply Method"::"Consignment at Vendor",
            ConsignmentProductionBOMLine."Component Supply Method",
            'Procurement-enabled BOM component must migrate to Consignment at Vendor.');
        ConsignmentProdOrderComponent.Get(
            ConsignmentProdOrderComponent.Status,
            ConsignmentProdOrderComponent."Prod. Order No.",
            ConsignmentProdOrderComponent."Prod. Order Line No.",
            ConsignmentProdOrderComponent."Line No.");
        Assert.AreEqual(
            "Component Supply Method"::"Consignment at Vendor",
            ConsignmentProdOrderComponent."Component Supply Method",
            'Procurement-enabled production order component must migrate to Consignment at Vendor.');

        // [THEN] Procurement-disabled inventory components use transfer to vendor
        TransferProductionBOMLine.Get(
            TransferProductionBOMLine."Production BOM No.",
            TransferProductionBOMLine."Version Code",
            TransferProductionBOMLine."Line No.");
        Assert.AreEqual(
            "Component Supply Method"::"Transfer to Vendor",
            TransferProductionBOMLine."Component Supply Method",
            'Procurement-disabled BOM component must migrate to Transfer to Vendor.');
        TransferProdOrderComponent.Get(
            TransferProdOrderComponent.Status,
            TransferProdOrderComponent."Prod. Order No.",
            TransferProdOrderComponent."Prod. Order Line No.",
            TransferProdOrderComponent."Line No.");
        Assert.AreEqual(
            "Component Supply Method"::"Transfer to Vendor",
            TransferProdOrderComponent."Component Supply Method",
            'Procurement-disabled production order component must migrate to Transfer to Vendor.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateProductionBOMLines_SkipsAlreadyMigratedComponents()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        ITSubcMigrationTests: Codeunit "IT Subc. Migration Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 649440] Already migrated BOM components do not resolve versions or routing again.
        Initialize();

        // [GIVEN] A linked BOM component already has a supply method.
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProductionBOMLine."Component Supply Method" := "Component Supply Method"::"Vendor-Supplied";
        ProductionBOMLine.Modify(false);
        ITSubcMigrationTests.SetGuardedProductionBOMNo(ProductionBOMLine."Production BOM No.");
        BindSubscription(ITSubcMigrationTests);

        // [WHEN] The BOM supply methods are migrated.
        ITSubcMigration.MigrateProductionBOMLines();

        // [THEN] Its method is preserved without performing version resolution.
        UnbindSubscription(ITSubcMigrationTests);
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual("Component Supply Method"::"Vendor-Supplied", ProductionBOMLine."Component Supply Method",
            'An existing component supply method must be preserved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_VerifiesMigratedSupplyMethods()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 649440] Supply method changes preserve the record-count verification and are idempotent.
        Initialize();

        // [GIVEN] Linked BOM and production order components with blank supply methods.
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);

        // [WHEN] The full migration including verification is run twice.
        ITSubcMigration.StartDisableLegacySubcontracting(false);
        ITSubcMigration.StartDisableLegacySubcontracting(false);

        // [THEN] Verification succeeds and both components retain their migrated method.
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
        Assert.AreEqual("Component Supply Method"::"Consignment at Vendor", ProductionBOMLine."Component Supply Method",
            'The full migration must preserve the migrated BOM method on repeat.');
        Assert.AreEqual("Component Supply Method"::"Consignment at Vendor", ProdOrderComponent."Component Supply Method",
            'The full migration must preserve the migrated order component method on repeat.');
    end;

    // *** 15. Prod. Order Routing Lines ***

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveNonInventoryWithProcurement()
    begin
        VerifyNonInventorySupplyMethods(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveNonInventoryWithoutProcurement()
    begin
        VerifyNonInventorySupplyMethods(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveServiceWithProcurement()
    begin
        VerifyNonInventorySupplyMethods(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveMixedInternalOperations()
    begin
        VerifyDuplicateRoutingLink(0, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveMixedMissingVendorOperations()
    begin
        VerifyDuplicateRoutingLink(1, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveConflictingOperations()
    begin
        VerifyDuplicateRoutingLink(2, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_MapConsistentDuplicateOperations()
    begin
        VerifyDuplicateRoutingLink(3, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveMixedMachineCenterOperations()
    begin
        VerifyDuplicateRoutingLink(4, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_ResolveInheritedSKURouting()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        StockkeepingUnit."Item No." := OutputItem."No.";
        StockkeepingUnit."Production BOM No." := ProductionBOMLine."Production BOM No.";
        StockkeepingUnit.Insert(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveInheritedBOMWithConflictingSKU()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        StockkeepingUnit."Item No." := OutputItem."No.";
        StockkeepingUnit."Routing No." := CreateAlternateRouting(ProductionBOMLine, false);
        StockkeepingUnit.Insert(false);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveConflictingFamilyRouting()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        Family: Record Family;
        FamilyLine: Record "Family Line";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        Family."No." := LibraryUtility.GenerateGUID();
        Family."Routing No." := CreateAlternateRouting(ProductionBOMLine, false);
        Family.Insert(false);
        FamilyLine."Family No." := Family."No.";
        FamilyLine."Line No." := 10000;
        FamilyLine."Item No." := OutputItem."No.";
        FamilyLine.Quantity := 1;
        FamilyLine.Insert(false);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_ResolveFamilyOnlyRouting()
    begin
        VerifyFamilyOnlyRouting(false, false, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_ResolveFamilyOnlyInheritedSKU()
    begin
        VerifyFamilyOnlyRouting(true, false, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveInvalidItemRoutingWithFamily()
    begin
        VerifyFamilyOnlyRouting(false, true, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveAbsentRoutingUsage()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        OutputItem."Routing No." := '';
        OutputItem.Modify(false);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_RefreshItemRoutingCacheBetweenPasses()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        Index: Integer;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        for Index := 1 to 2 do begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, OutputItem."No.", '');
            StockkeepingUnit.Validate("Production BOM No.", ProductionBOMLine."Production BOM No.");
            StockkeepingUnit.Validate("Routing No.", '');
            StockkeepingUnit.Modify(true);
        end;
        OutputItem."Production BOM No." := '';
        OutputItem.Modify(false);

        ITSubcMigration.MigrateProductionBOMLines();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual("Component Supply Method"::"Consignment at Vendor", ProductionBOMLine."Component Supply Method",
            'Multiple SKUs must share the inherited item routing.');

        ProductionBOMLine."Component Supply Method" := "Component Supply Method"::Empty;
        ProductionBOMLine.Modify(false);
        OutputItem."Routing No." := CreateAlternateRouting(ProductionBOMLine, false);
        OutputItem.Modify(false);
        StockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        StockkeepingUnit.ModifyAll("Routing No.", '');
        ITSubcMigration.MigrateProductionBOMLines();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual("Component Supply Method"::"Transfer to Vendor", ProductionBOMLine."Component Supply Method",
            'A new migration pass must not reuse the previous item routing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_RefreshFamilyRoutingCacheBetweenPasses()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", OutputItem."Routing No.");
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", OutputItem."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", OutputItem."No.", 2);
        OutputItem."Routing No." := '';
        OutputItem.Modify(false);

        ITSubcMigration.MigrateProductionBOMLines();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual("Component Supply Method"::"Consignment at Vendor", ProductionBOMLine."Component Supply Method",
            'Repeated family lines must resolve consistently.');

        ProductionBOMLine."Component Supply Method" := "Component Supply Method"::Empty;
        ProductionBOMLine.Modify(false);
        Family.Validate("Routing No.", CreateAlternateRouting(ProductionBOMLine, false));
        Family.Modify(true);
        ITSubcMigration.MigrateProductionBOMLines();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual("Component Supply Method"::"Transfer to Vendor", ProductionBOMLine."Component Supply Method",
            'A new migration pass must not reuse the previous family routing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_ResolveNestedBOM()
    begin
        VerifyNestedBOMUsage(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveConflictingNestedUsage()
    begin
        VerifyNestedBOMUsage(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_MapFutureBOMVersion()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        CreateFutureBOMVersion(ProductionBOMLine);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveFutureRoutingConflict()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        CreateFutureRoutingVersion(ProductionBOMLine, OutputItem."Routing No.");

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_RespectBOMAndRoutingVersionIntervals()
    var
        ProductionBOMLine: Record "Production BOM Line";
        FutureBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        FutureBOMLine := ProductionBOMLine;
        CreateFutureBOMVersion(FutureBOMLine);
        CreateFutureRoutingVersion(ProductionBOMLine, OutputItem."Routing No.");

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::"Consignment at Vendor");
        MigrateAndAssertBOM(FutureBOMLine, "Component Supply Method"::"Transfer to Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_RespectComponentStartingDate()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        ProductionBOMLine."Starting Date" := CalcDate('<1M>', WorkDate());
        ProductionBOMLine.Modify(false);
        CreateFutureRoutingVersion(ProductionBOMLine, OutputItem."Routing No.");

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::"Transfer to Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_ResolveFamilyOrderRoutingReference()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        ProdOrderLine."Routing Reference No." := 0;
        ProdOrderLine.Modify(false);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Delete(false);
        ProdOrderRoutingLine."Routing Reference No." := 0;
        ProdOrderRoutingLine.Insert(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_IgnoreOtherOrderRouting()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine."Routing No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine.Insert(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_RespectComponentEndingDate()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        ProductionBOMLine."Ending Date" := CalcDate('<1M>', WorkDate()) - 1;
        ProductionBOMLine.Modify(false);
        CreateFutureRoutingVersion(ProductionBOMLine, OutputItem."Routing No.");

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::"Consignment at Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveUncertifiedBOMVersion()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        CreateFutureBOMVersion(ProductionBOMLine);
        ProductionBOMVersion.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code");
        ProductionBOMVersion.Status := ProductionBOMVersion.Status::"Under Development";
        ProductionBOMVersion.Modify(false);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveCyclicBOMUsage()
    var
        ProductionBOMLine: Record "Production BOM Line";
        CycleLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        CycleLine."Production BOM No." := ProductionBOMLine."Production BOM No.";
        CycleLine."Line No." := ProductionBOMLine."Line No." + 10000;
        CycleLine.Type := CycleLine.Type::"Production BOM";
        CycleLine."No." := ProductionBOMLine."Production BOM No.";
        CycleLine.Quantity := 1;
        CycleLine.Insert(false);

        MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveExistingOrderMethod()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProdOrderComponent."Component Supply Method" := "Component Supply Method"::"Vendor-Supplied";
        ProdOrderComponent.Modify(false);

        ITSubcMigration.MigrateProdOrderComponentSupplyMethods();
        ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
        Assert.AreEqual("Component Supply Method"::"Vendor-Supplied", ProdOrderComponent."Component Supply Method",
            'An explicit order component method must not be overwritten.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMethods_PreserveBlankRoutingLinks()
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProductionBOMLine."Routing Link Code" := '';
        ProductionBOMLine.Modify(false);
        ProdOrderComponent."Routing Link Code" := '';
        ProdOrderComponent.Modify(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, "Component Supply Method"::Empty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateProdOrderRoutingLines_CopiesWIPItem()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateProdOrderRoutingLines copies "WIP Item" = true to "Transfer WIP Item"
        Initialize();

        // [GIVEN] A released prod. order routing line with "WIP Item" = true and "Transfer WIP Item" = false
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := "Production Order Status"::Released;
        ProdOrderRoutingLine."Prod. Order No." := LibraryUtility.GenerateRandomCode20(ProdOrderRoutingLine.FieldNo("Prod. Order No."), ProdOrderRoutingLine.RecordId().TableNo());
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Routing No." := '';
        ProdOrderRoutingLine."Operation No." := '10';
#pragma warning disable AL0432
        ProdOrderRoutingLine."WIP Item" := true;
#pragma warning restore AL0432
        ProdOrderRoutingLine."Transfer WIP Item" := false;
        ProdOrderRoutingLine.Insert(false);

        // [WHEN] MigrateProdOrderRoutingLines is called
        ITSubcMigration.MigrateProdOrderRoutingLines();

        // [THEN] "Transfer WIP Item" = true
        ProdOrderRoutingLine.Get(
            ProdOrderRoutingLine.Status,
            ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.",
            ProdOrderRoutingLine."Operation No.");
        Assert.IsTrue(ProdOrderRoutingLine."Transfer WIP Item",
            'MigrateProdOrderRoutingLines should copy "WIP Item" = true to "Transfer WIP Item".');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MigrateRoutingLines_CopiesWIPItem()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] MigrateRoutingLines copies "WIP Item" = true to "Transfer WIP Item"
        Initialize();

        // [GIVEN] A routing line with "WIP Item" = true and "Transfer WIP Item" = false
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
#pragma warning disable AL0432
        RoutingLine."WIP Item" := true;
#pragma warning restore AL0432
        RoutingLine."Transfer WIP Item" := false;
        RoutingLine.Modify(false);

        // [WHEN] MigrateRoutingLines is called
        ITSubcMigration.MigrateRoutingLines();

        // [THEN] "Transfer WIP Item" = true
        RoutingLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.");
        Assert.IsTrue(RoutingLine."Transfer WIP Item",
            'MigrateRoutingLines should copy "WIP Item" = true to "Transfer WIP Item".');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunMigration_MigratesAllEntityTypes()
    var
#pragma warning disable AL0432
        LegacyPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        NewPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        Item: Record Item;
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        TransferSourceType: Enum "Transfer Source Type";
        SubcLocationCode: Code[10];
        PurchOrderNo: Code[20];
    begin
        // [SCENARIO] RunMigration migrates all entity types in one pass; transfer header "Subc. Source Type" is resolved via lines that are migrated first
        Initialize();

        // [GIVEN] A location for subcontracting
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        SubcLocationCode := LocationFrom.Code;

        // [GIVEN] A vendor with a legacy subcontracting location
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := SubcLocationCode;
        Vendor."Subc. Location Code" := '';
        Vendor.Modify(false);

        // [GIVEN] A legacy subcontractor price
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        CreateLegacySubcontractorPrice(LegacyPrice,
            WorkCenter."No.", Vendor."No.", Item."No.", Item."Base Unit of Measure",
            WorkDate(), 0D, 80, 1, 1);

        // [GIVEN] A purchase header with a legacy subcontracting location
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := SubcLocationCode;
        PurchaseHeader."Subc. Location Code" := '';
        PurchaseHeader.Modify(false);

        // [GIVEN] A transfer header + line with legacy "Subcontr. Purch. Order No." set (proves line-before-header ordering)
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        PurchOrderNo := LibraryUtility.GenerateGUID();
        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := false;
        TransferLine."Subcontr. Purch. Order No." := PurchOrderNo;
        TransferLine.Insert(false);

        // [GIVEN] A routing line with "WIP Item" = true
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
#pragma warning disable AL0432
        RoutingLine."WIP Item" := true;
#pragma warning restore AL0432
        RoutingLine."Transfer WIP Item" := false;
        RoutingLine.Modify(false);

        // [WHEN] RunMigration is called
        ITSubcMigration.RunMigration();

        // [THEN] Vendor "Subc. Location Code" was migrated
        Vendor.Get(Vendor."No.");
        Assert.AreEqual(SubcLocationCode, Vendor."Subc. Location Code",
            'Vendor "Subc. Location Code" should be migrated.');

        // [THEN] New "Subcontractor Price" was created with correct cost
        Assert.IsTrue(
            NewPrice.Get(Vendor."No.", Item."No.", WorkCenter."No.", '', '', WorkDate(), Item."Base Unit of Measure", 1, ''),
            'A new Subcontractor Price should have been created.');
        Assert.AreEqual(80, NewPrice."Direct Unit Cost",
            'Subcontractor Price "Direct Unit Cost" should be migrated.');

        // [THEN] Purchase header "Subc. Location Code" was migrated
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(SubcLocationCode, PurchaseHeader."Subc. Location Code",
            'Purchase header "Subc. Location Code" should be migrated.');

        // [THEN] Transfer line "Subc. Purch. Order No." was migrated
        TransferLine.Get(TransferHeader."No.", 10000);
        Assert.AreEqual(PurchOrderNo, TransferLine."Subc. Purch. Order No.",
            'Transfer line "Subc. Purch. Order No." should be migrated.');

        // [THEN] Transfer header "Subc. Source Type" = Subcontracting
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(
            TransferSourceType::Subcontracting,
            TransferHeader."Subc. Source Type",
            'Transfer header "Subc. Source Type" should be Subcontracting after RunMigration.');

        // [THEN] Routing line "Transfer WIP Item" was migrated
        RoutingLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.");
        Assert.IsTrue(RoutingLine."Transfer WIP Item",
            'Routing line "Transfer WIP Item" should be migrated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractingLocations_ReportsEveryLocationAndSetting()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLocation: Record Location;
        PurchaseLocation: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        BlockingError: Text;
    begin
        // [SCENARIO] The migration precheck reports every incompatible location and its unsupported warehouse settings
        Initialize();

        // [GIVEN] A vendor whose legacy subcontracting location requires bins and picks
        LibraryWarehouse.CreateLocation(VendorLocation);
        VendorLocation."Bin Mandatory" := true;
        VendorLocation."Require Pick" := true;
        VendorLocation.Modify(false);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := VendorLocation.Code;
        Vendor.Modify(false);

        // [GIVEN] A purchase header with a different legacy location that is bin-mandatory
        // (Require Put-away/Receive/Shipment are not restricted for purchase-header-only locations)
        LibraryWarehouse.CreateLocation(PurchaseLocation);
        PurchaseLocation."Bin Mandatory" := true;
        PurchaseLocation.Modify(false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := PurchaseLocation.Code;
        PurchaseHeader.Modify(false);

        // [WHEN] The subcontracting location precheck runs
        asserterror ITSubcMigration.CheckSubcontractingLocations();
        Assert.ExpectedError(SubcontractingLocationsBlockedErr);

        // [THEN] The blocking error reports every incompatible location and its unsupported settings
        BlockingError := GetLastErrorText();
        Assert.IsTrue(
            BlockingError.Contains(
                StrSubstNo(
                    UnsupportedSubcontractingLocationErr,
                    VendorLocation.Code,
                    VendorLocation.FieldCaption("Bin Mandatory") + ', ' + VendorLocation.FieldCaption("Require Pick"))),
            'The precheck should report the vendor location and its unsupported settings.');
        Assert.IsTrue(
            BlockingError.Contains(
                StrSubstNo(
                    UnsupportedSubcontractingLocationErr,
                    PurchaseLocation.Code,
                    PurchaseLocation.FieldCaption("Bin Mandatory"))),
            'The precheck should report the purchase location and its unsupported settings.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractingLocations_ReportsMissingAndUnsupportedLegacyLocations()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        MissingLocation: Record Location;
        UnsupportedLocation: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
        BlockingError: Text;
    begin
        // [SCENARIO] The migration precheck aggregates missing and unsupported legacy subcontracting locations
        Initialize();

        // [GIVEN] A vendor whose legacy subcontracting location references a deleted location
        LibraryWarehouse.CreateLocation(MissingLocation);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := MissingLocation.Code;
        Vendor.Modify(false);
        MissingLocation.Delete(false);

        // [GIVEN] A purchase header whose legacy subcontracting location requires bins
        LibraryWarehouse.CreateLocation(UnsupportedLocation);
        UnsupportedLocation."Bin Mandatory" := true;
        UnsupportedLocation.Modify(false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := UnsupportedLocation.Code;
        PurchaseHeader.Modify(false);
        Commit();

        // [WHEN] The subcontracting location precheck runs
        asserterror ITSubcMigration.CheckSubcontractingLocations();
        Assert.ExpectedError(SubcontractingLocationsBlockedErr);

        // [THEN] The blocking error reports both legacy location problems
        BlockingError := GetLastErrorText();
        Assert.IsTrue(
            BlockingError.Contains(StrSubstNo(MissingSubcontractingLocationErr, MissingLocation.Code)),
            'The precheck should report the missing legacy location.');
        Assert.IsTrue(
            BlockingError.Contains(
                StrSubstNo(
                    UnsupportedSubcontractingLocationErr,
                    UnsupportedLocation.Code,
                    UnsupportedLocation.FieldCaption("Bin Mandatory"))),
            'The precheck should continue and report the unsupported legacy location.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractingLocations_AllowsPurchaseHeaderOnlyLocationWithSupportedWarehouseHandling()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SupportedLocation: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] The migration precheck does not block a purchase-header-only legacy location whose only
        // enabled warehouse handling setting is one the purchase header's target field allows
        Initialize();

        // [GIVEN] A purchase header whose legacy subcontracting location requires picks but is not bin-mandatory
        // and is not referenced by any vendor
        LibraryWarehouse.CreateLocation(SupportedLocation);
        SupportedLocation."Require Pick" := true;
        SupportedLocation.Modify(false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := SupportedLocation.Code;
        PurchaseHeader.Modify(false);

        // [WHEN] The subcontracting location precheck runs
        ITSubcMigration.CheckSubcontractingLocations();

        // [THEN] No error is thrown because "Require Pick" is not restricted for purchase-header-only locations
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractingLocations_AppliesVendorRuleSetWhenLocationSharedWithPurchaseHeader()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SharedLocation: Record Location;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] The migration precheck still applies the stricter vendor rule set to a legacy location that
        // is referenced by both a vendor and a purchase header, even though the setting would be allowed if the
        // location were purchase-header-only
        Initialize();

        // [GIVEN] A legacy subcontracting location that requires picks (allowed for purchase-header-only
        // locations) but is not bin-mandatory
        LibraryWarehouse.CreateLocation(SharedLocation);
        SharedLocation."Require Pick" := true;
        SharedLocation.Modify(false);

        // [GIVEN] The same location is referenced by both a vendor and a purchase header
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := SharedLocation.Code;
        Vendor.Modify(false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Subcontracting Location Code" := SharedLocation.Code;
        PurchaseHeader.Modify(false);
        Commit();

        // [WHEN] The subcontracting location precheck runs
        asserterror ITSubcMigration.CheckSubcontractingLocations();
        Assert.ExpectedError(SubcontractingLocationsBlockedErr);

        // [THEN] The precheck blocks on "Require Pick" because the location is also used as a vendor
        // subcontracting location, so the stricter vendor rule set takes precedence over the looser
        // purchase-header-only rule set
        Assert.IsTrue(
            GetLastErrorText().Contains(
                StrSubstNo(
                    UnsupportedSubcontractingLocationErr,
                    SharedLocation.Code,
                    SharedLocation.FieldCaption("Require Pick"))),
            'The precheck should apply the vendor rule set to a location shared with a purchase header.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_BlocksInTransitLocationBeforeMigration()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] Disabling legacy subcontracting stops before migration when a location is used as in-transit
        Initialize();

        // [GIVEN] No open WIP transfers or purchase orders
        TransferLine.SetRange("WIP Item", true);
        if not TransferLine.IsEmpty() then
            TransferLine.DeleteAll();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AL0432
        PurchaseLine.SetRange("WIP Item", true);
#pragma warning restore AL0432
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.DeleteAll();

        // [GIVEN] A vendor with an unmigrated legacy subcontracting location used as in-transit
        LibraryWarehouse.CreateLocation(Location);
        Location."Use As In-Transit" := true;
        Location.Modify(false);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := Location.Code;
        Vendor."Subc. Location Code" := '';
        Vendor.Modify(false);
        Commit();

        // [WHEN] Legacy subcontracting is disabled
        asserterror ITSubcMigration.StartDisableLegacySubcontracting(false);

        // [THEN] The precheck reports the incompatible location
        Assert.ExpectedError(
            StrSubstNo(
                UnsupportedSubcontractingLocationErr,
                Location.Code,
                Location.FieldCaption("Use As In-Transit")));

        // [THEN] Migration has not changed the vendor
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."Subc. Location Code", 'The vendor must not be migrated when the precheck fails.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerReturnFalse')]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_NotConfirmedNothingHappens()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
        CanceledByUserErr: Label 'Canceled by user.', Locked = true;
    begin
        // [SCENARIO] StartDisableLegacySubcontracting does not migrate data or flip the flag when the user cancels the confirm dialog
        Initialize();

        // [GIVEN] A vendor with a legacy location code that has not been migrated yet
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := Location.Code;
        Vendor."Subc. Location Code" := '';
        Vendor.Modify(false);
        Commit();

        // [GIVEN] No open WIP transfers or purchase orders
        TransferLine.SetRange("WIP Item", true);
        if not TransferLine.IsEmpty() then
            TransferLine.DeleteAll();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AL0432
        PurchaseLine.SetRange("WIP Item", true);
#pragma warning restore AL0432
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.DeleteAll();

        // [GIVEN] Legacy subcontracting flag is true
        AssertLegacySubcontractingFlag(true);

        // [WHEN] StartDisableLegacySubcontracting is called with ShowDialog = true and the user cancels
        asserterror ITSubcMigration.StartDisableLegacySubcontracting(true);

        // [THEN] The expected error is thrown
        Assert.ExpectedError(CanceledByUserErr);

        // [THEN] The legacy subcontracting flag is unchanged
        AssertLegacySubcontractingFlag(true);

        // [THEN] The vendor was not migrated ("Subc. Location Code" is still empty)
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."Subc. Location Code",
            'Vendor "Subc. Location Code" should remain empty when migration was cancelled.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyTextAndReturnTrue')]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_ConfirmDialogIsShown()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO] StartDisableLegacySubcontracting shows a confirm dialog before running migration when ShowDialog = true
        Initialize();

        // [GIVEN] No open WIP transfers or purchase orders
        TransferLine.SetRange("WIP Item", true);
        if not TransferLine.IsEmpty() then
            TransferLine.DeleteAll();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AL0432
        PurchaseLine.SetRange("WIP Item", true);
#pragma warning restore AL0432
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.DeleteAll();

        // [WHEN] StartDisableLegacySubcontracting is called with ShowDialog = true and the user confirms
        ITSubcMigration.ConfirmDisableLegacySubcontracting();

        // [THEN] The confirm handler verified the dialog question text and confirms the dialog
        // [THEN] No Error is thrown
    end;

    [Test]
    [HandlerFunctions('UndoReceiptAndConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_RechecksOpenWIPAfterConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        // [SCENARIO 649448] Migration rechecks open WIP after confirmation and locks prevent a concurrent receipt undo race
        Initialize();

        // [GIVEN] A fully received legacy WIP purchase line passes the initial precheck
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := true;
#pragma warning restore AL0432
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        PurchaseReceiptNo := PurchRcptLine."Document No.";
        PurchaseReceiptLineNo := PurchRcptLine."Line No.";

        // [WHEN] The receipt is undone while the migration confirmation is open
        asserterror ITSubcMigration.StartDisableLegacySubcontracting(true);

        // [THEN] The post-lock precheck detects the newly open WIP line and stops migration
        Assert.ExpectedError(OpenWIPPurchaseOrdersExistErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IT Subc. Migration Tests");

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IT Subc. Migration Tests");
        Initialized := true;
        ActivateLegacySubcontracting();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IT Subc. Migration Tests");
    end;

    local procedure CreateLegacySubcontractorPrice(
#pragma warning disable AL0432
        var LegacyPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        WorkCenterNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        DirectUnitCost: Decimal;
        MinimumQuantity: Decimal;
        MinimumAmount: Decimal)
    begin
        LegacyPrice.Init();
        LegacyPrice."Work Center No." := WorkCenterNo;
        LegacyPrice."Vendor No." := VendorNo;
        LegacyPrice."Item No." := ItemNo;
        LegacyPrice."Standard Task Code" := '';
        LegacyPrice."Variant Code" := '';
        LegacyPrice."Currency Code" := '';
        LegacyPrice."Start Date" := StartDate;
        LegacyPrice."End Date" := EndDate;
        LegacyPrice."Unit of Measure Code" := UnitOfMeasureCode;
        LegacyPrice."Minimum Quantity" := MinimumQuantity;
        LegacyPrice."Direct Unit Cost" := DirectUnitCost;
        LegacyPrice."Minimum Amount" := MinimumAmount;
        LegacyPrice.Insert(false);
    end;

    local procedure InsertReleasedProdOrderSetup(
        var ProductionOrder: Record "Production Order";
        var ProdOrderLine: Record "Prod. Order Line";
        var ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NextOperationNo: Code[20])
    begin
        ProductionOrder.Init();
        ProductionOrder.Status := "Production Order Status"::Released;
        ProductionOrder."No." := LibraryUtility.GenerateGUID();
        ProductionOrder.Insert(false);

        ProdOrderLine.Init();
        ProdOrderLine.Status := "Production Order Status"::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Routing Reference No." := 10000;
        ProdOrderLine.Insert(false);

        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := "Production Order Status"::Released;
        ProdOrderRoutingLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Routing No." := '';
        ProdOrderRoutingLine."Operation No." := '10';
        ProdOrderRoutingLine."Next Operation No." := NextOperationNo;
        ProdOrderRoutingLine.Insert(false);
    end;

    local procedure CreateComponentSupplyMethodMigrationScenario(
        var ProductionBOMLine: Record "Production BOM Line";
        var ProdOrderComponent: Record "Prod. Order Component";
        SubcontractorProcurement: Boolean)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ComponentItem: Record Item;
        OutputItem: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontracting Location Code" := Location.Code;
        Vendor."Subcontractor Procurement" := SubcontractorProcurement;
        Vendor.Modify(false);

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := Vendor."No.";
        WorkCenter.Modify(false);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine."Routing Link Code" := RoutingLink.Code;
        RoutingLine.Modify(false);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItem(OutputItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, OutputItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine."Routing Link Code" := RoutingLink.Code;
        ProductionBOMLine."Component Supply Method" := "Component Supply Method"::Empty;
        ProductionBOMLine.Modify(false);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Validate("Routing No.", RoutingHeader."No.");
        OutputItem.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, OutputItem."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindFirst();
#pragma warning disable AL0432
        ProdOrderComponent."Original Location" := Location.Code;
#pragma warning restore AL0432
        ProdOrderComponent."Component Supply Method" := "Component Supply Method"::Empty;
        ProdOrderComponent.Modify(false);
    end;

    procedure SetGuardedProductionBOMNo(ProductionBOMNo: Code[20])
    begin
        GuardedProductionBOMNo := ProductionBOMNo;
    end;

    local procedure VerifyNonInventorySupplyMethods(Procurement: Boolean; ServiceItem: Boolean)
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ComponentItem: Record Item;
    begin
        // [SCENARIO 649440] Automatic legacy mapping preserves noninventory components.
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, Procurement);
        ComponentItem.Get(ProductionBOMLine."No.");
        if ServiceItem then
            ComponentItem.Type := ComponentItem.Type::Service
        else
            ComponentItem.Type := ComponentItem.Type::"Non-Inventory";
        ComponentItem.Modify(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, "Component Supply Method"::Empty);
    end;

    local procedure FindBOMOutputItem(ProductionBOMLine: Record "Production BOM Line"; var OutputItem: Record Item)
    begin
        OutputItem.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
        OutputItem.FindFirst();
    end;

    local procedure CreateAlternateRouting(ProductionBOMLine: Record "Production BOM Line"; Procurement: Boolean): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontractor Procurement" := Procurement;
        Vendor.Modify(false);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := Vendor."No.";
        WorkCenter.Modify(false);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine."Routing Link Code" := ProductionBOMLine."Routing Link Code";
        RoutingLine.Modify(false);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure VerifyFamilyOnlyRouting(WithSKU: Boolean; InvalidItemRouting: Boolean; ExpectedMethod: Enum "Component Supply Method")
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        OutputItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        Location: Record Location;
    begin
        // [SCENARIO 649440] Family routing does not require an item routing; an invalid explicit routing remains ambiguous.
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", OutputItem."Routing No.");
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", OutputItem."No.", 1);
        OutputItem."Routing No." := '';
        if InvalidItemRouting then
            OutputItem."Routing No." := LibraryUtility.GenerateGUID();
        OutputItem.Modify(false);
        if WithSKU then begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, OutputItem."No.", '');
            StockkeepingUnit.Validate("Production BOM No.", '');
            StockkeepingUnit.Validate("Routing No.", '');
            StockkeepingUnit.Modify(true);
        end;

        MigrateAndAssertBOM(ProductionBOMLine, ExpectedMethod);
    end;

    local procedure VerifyNestedBOMUsage(ConflictingParent: Boolean)
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ParentBOMHeader: Record "Production BOM Header";
        ParentBOMLine: Record "Production BOM Line";
        OutputItem: Record Item;
        ParentItem: Record Item;
    begin
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        FindBOMOutputItem(ProductionBOMLine, OutputItem);
        LibraryInventory.CreateItem(ParentItem);
        LibraryManufacturing.CreateProductionBOMHeader(ParentBOMHeader, OutputItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ParentBOMHeader, ParentBOMLine, '',
            ParentBOMLine.Type::"Production BOM", ProductionBOMLine."Production BOM No.", 1);
        ParentBOMHeader.Validate(Status, ParentBOMHeader.Status::Certified);
        ParentBOMHeader.Modify(true);
        ParentItem."Production BOM No." := ParentBOMHeader."No.";
        ParentItem."Routing No." := OutputItem."Routing No.";
        if ConflictingParent then
            ParentItem."Routing No." := CreateAlternateRouting(ProductionBOMLine, false)
        else begin
            OutputItem."Production BOM No." := '';
            OutputItem.Modify(false);
        end;
        ParentItem.Modify(false);

        if ConflictingParent then
            MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::Empty)
        else
            MigrateAndAssertBOM(ProductionBOMLine, "Component Supply Method"::"Consignment at Vendor");
    end;

    local procedure CreateFutureBOMVersion(var ProductionBOMLine: Record "Production BOM Line")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        ProductionBOMVersion."Production BOM No." := ProductionBOMLine."Production BOM No.";
        ProductionBOMVersion."Version Code" := 'FUTURE';
        ProductionBOMVersion."Starting Date" := CalcDate('<1M>', WorkDate());
        ProductionBOMVersion."Unit of Measure Code" := ProductionBOMHeader."Unit of Measure Code";
        ProductionBOMVersion.Status := ProductionBOMVersion.Status::Certified;
        ProductionBOMVersion.Insert(false);
        ProductionBOMLine."Version Code" := ProductionBOMVersion."Version Code";
        ProductionBOMLine.Insert(false);
    end;

    local procedure CreateFutureRoutingVersion(ProductionBOMLine: Record "Production BOM Line"; RoutingNo: Code[20])
    var
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", CreateAlternateRouting(ProductionBOMLine, false));
        RoutingLine.FindFirst();
        RoutingVersion."Routing No." := RoutingNo;
        RoutingVersion."Version Code" := 'FUTURE';
        RoutingVersion."Starting Date" := CalcDate('<1M>', WorkDate());
        RoutingVersion.Status := RoutingVersion.Status::Certified;
        RoutingVersion.Insert(false);
        RoutingLine."Routing No." := RoutingNo;
        RoutingLine."Version Code" := RoutingVersion."Version Code";
        RoutingLine.Insert(false);
    end;

    local procedure MigrateAndAssertBOM(var ProductionBOMLine: Record "Production BOM Line"; ExpectedMethod: Enum "Component Supply Method")
    var
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        ITSubcMigration.MigrateProductionBOMLines();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        Assert.AreEqual(ExpectedMethod, ProductionBOMLine."Component Supply Method", 'BOM method must reflect every effective usage.');
    end;

    local procedure VerifyDuplicateRoutingLink(OperationKind: Integer; ExpectedMethod: Enum "Component Supply Method")
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 649440] Every operation sharing a link must have the same resolved meaning.
        Initialize();
        CreateComponentSupplyMethodMigrationScenario(ProductionBOMLine, ProdOrderComponent, true);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.FindFirst();
        RoutingLine.SetRange("Routing Link Code", ProductionBOMLine."Routing Link Code");
        RoutingLine.FindFirst();
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        case OperationKind of
            1:
                WorkCenter."Subcontractor No." := LibraryUtility.GenerateGUID();
            2, 3:
                begin
                    LibraryPurchase.CreateVendor(Vendor);
                    Vendor."Subcontractor Procurement" := OperationKind = 3;
                    Vendor.Modify(false);
                    WorkCenter."Subcontractor No." := Vendor."No.";
                end;
        end;
        WorkCenter.Modify(false);
        RoutingLine."Operation No." := '20';
        RoutingLine."No." := WorkCenter."No.";
        ProdOrderRoutingLine."Operation No." := '20';
        ProdOrderRoutingLine."No." := WorkCenter."No.";
        if OperationKind = 4 then begin
            RoutingLine.Type := RoutingLine.Type::"Machine Center";
            ProdOrderRoutingLine.Type := ProdOrderRoutingLine.Type::"Machine Center";
        end;
        RoutingLine.Insert(false);
        ProdOrderRoutingLine.Insert(false);

        MigrateAndAssertSupplyMethods(ProductionBOMLine, ProdOrderComponent, ExpectedMethod);
    end;

    local procedure MigrateAndAssertSupplyMethods(var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component"; ExpectedMethod: Enum "Component Supply Method")
    var
        ITSubcMigration: Codeunit "IT Subc. Migration";
    begin
        ITSubcMigration.MigrateProductionBOMLines();
        ITSubcMigration.MigrateProdOrderComponentSupplyMethods();
        ProductionBOMLine.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code", ProductionBOMLine."Line No.");
        ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
        Assert.AreEqual(ExpectedMethod, ProductionBOMLine."Component Supply Method", 'BOM migration must preserve eligibility and ambiguity rules.');
        Assert.AreEqual(ExpectedMethod, ProdOrderComponent."Component Supply Method", 'Order migration must preserve eligibility and ambiguity rules.');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::VersionManagement, 'OnBeforeGetBOMVersion', '', false, false)]
    local procedure RejectAlreadyMigratedBOMLookup(BOMHeaderNo: Code[20])
    var
        AlreadyMigratedBOMLookupErr: Label 'Already migrated BOM components must not resolve their BOM version.', Locked = true;
    begin
        if BOMHeaderNo = GuardedProductionBOMNo then
            Error(AlreadyMigratedBOMLookupErr);
    end;

    local procedure AssertLegacySubcontractingFlag(ExpectedValue: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
#pragma warning disable AA0233
#pragma warning disable AA0217
        Assert.AreEqual(ExpectedValue, ManufacturingSetup."Legacy Subcontracting",
            StrSubstNo('ManufacturingSetup."Legacy Subcontracting" should be %1.', ExpectedValue));
#pragma warning restore AA0217
#pragma warning restore AA0233
    end;

    local procedure ActivateLegacySubcontracting()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
        ManufacturingSetup."Legacy Subcontracting" := true;
        ManufacturingSetup.Modify();
        LibraryApplicationArea.EnablePremiumSetup();
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
        Commit();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerVerifyTextAndReturnTrue(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(
            Question.Contains('migrates legacy IT subcontracting data'),
            'Confirm question text is not as expected: ' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerReturnFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure UndoReceiptAndConfirmHandler(Question: Text; var Reply: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.Get(PurchaseReceiptNo, PurchaseReceiptLineNo);
        PurchRcptLine.SetRecFilter();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        Reply := true;
    end;
}
#endif