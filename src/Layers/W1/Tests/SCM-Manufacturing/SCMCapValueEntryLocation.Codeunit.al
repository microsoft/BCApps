// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 137215 "SCM Cap. Value Entry Location"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostingCopiesLocationToCapValueEntryWhenEnabled()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        LocationCode: Code[10];
    begin
        // [SCENARIO] When "Copy Loc. to Cap. Val. Entries" is enabled, capacity value entries get the Location Code from the production order.
        Initialize();

        // [GIVEN] Manufacturing Setup with "Copy Loc. to Cap. Val. Entries" = true
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Copy Loc. to Cap. Val. Entries", true);
        ManufacturingSetup.Modify(true);

        // [GIVEN] A location "L" with Inventory Posting Setup
        CreateLocationWithInventoryPostingSetup(Location);
        LocationCode := Location.Code;

        // [GIVEN] A released production order at location "L" with routing (Work Center)
        CreateReleasedProdOrderWithRoutingAtLocation(ProductionOrder, LocationCode);

        // [WHEN] Post output journal for the production order
        PostOutputForProductionOrder(ProductionOrder);

        // [THEN] Value entries linked to capacity ledger entries with Type = "Work Center" have Location Code = "L"
        VerifyCapacityValueEntryLocationCode(ProductionOrder."No.", LocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostingLeavesLocationBlankOnCapValueEntryWhenDisabled()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // [SCENARIO] When "Copy Loc. to Cap. Val. Entries" is disabled, capacity value entries have blank Location Code.
        Initialize();

        // [GIVEN] Manufacturing Setup with "Copy Loc. to Cap. Val. Entries" = false
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Copy Loc. to Cap. Val. Entries", false);
        ManufacturingSetup.Modify(true);

        // [GIVEN] A location "L" with Inventory Posting Setup
        CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] A released production order at location "L" with routing (Work Center)
        CreateReleasedProdOrderWithRoutingAtLocation(ProductionOrder, Location.Code);

        // [WHEN] Post output journal for the production order
        PostOutputForProductionOrder(ProductionOrder);

        // [THEN] Value entries linked to capacity ledger entries with Type = "Work Center" have blank Location Code
        VerifyCapacityValueEntryLocationCode(ProductionOrder."No.", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Cap. Value Entry Location");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Cap. Value Entry Location");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Cap. Value Entry Location");
    end;

    local procedure CreateLocationWithInventoryPostingSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure CreateReleasedProdOrderWithRoutingAtLocation(var ProductionOrder: Record "Production Order"; LocationCode: Code[10])
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure PostOutputForProductionOrder(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Item No.", ProductionOrder."Source No.");
        ItemJournalLine.Modify(true);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SetRunTimeOnOutputJournalLines(ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(
            ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SetRunTimeOnOutputJournalLines(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(10));
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure VerifyCapacityValueEntryLocationCode(OrderNo: Code[20]; ExpectedLocationCode: Code[10])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ValueEntry: Record "Value Entry";
        EntryFound: Boolean;
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", OrderNo);
        CapacityLedgerEntry.SetRange(Type, CapacityLedgerEntry.Type::"Work Center");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        CapacityLedgerEntry.FindSet();
        repeat
            ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntry."Entry No.");
            if ValueEntry.FindSet() then begin
                EntryFound := true;
                repeat
                    Assert.AreEqual(ExpectedLocationCode, ValueEntry."Location Code",
                        'Location Code on capacity value entry is incorrect.');
                until ValueEntry.Next() = 0;
            end;
        until CapacityLedgerEntry.Next() = 0;
        Assert.IsTrue(EntryFound, 'Expected at least one value entry linked to a capacity ledger entry.');
    end;
}
