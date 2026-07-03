#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.Subcontracting.Migration;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 149956 "IT Subc. Migration Tests"
{
    Subtype = Test;
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

    // *** 15. Prod. Order Routing Lines ***

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
}
#endif