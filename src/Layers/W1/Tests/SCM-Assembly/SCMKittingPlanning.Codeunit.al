// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using System.Environment.Configuration;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 137089 "SCM Kitting - Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Planning] [SCM]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Planning");

        LibraryApplicationArea.EnableEssentialSetup();

        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Planning");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Planning");
    end;

    [Normal]
    local procedure NoSeriesSetup()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        LibraryAssembly.CreateAssemblySetup(AssemblySetup, '', 0, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure SetupItems(var ParentNo: Code[20]; var ChildNo: Code[20]; var QtyPer: Decimal)
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
    begin
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);
        ParentNo := ParentAssemblyItem."No.";
        ChildNo := ChildItem."No.";
    end;

    local procedure SetupItemsVariant(var ParentNo: Code[20]; var ChildNo: Code[20]; var QtyPer: Decimal; var VarCode: Code[10])
    var
        ParentAssemblyItem: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        SetupItems(ParentNo, ChildNo, QtyPer);

        ParentAssemblyItem.Get(ParentNo);
        LibraryInventory.CreateVariant(ItemVariant, ParentAssemblyItem);
        VarCode := ItemVariant.Code;
    end;

    local procedure SetupSupplyDemand(KitItemNo: Code[20]; DemandQty: Decimal; InventoryQty: Decimal; VarCode: Code[10])
    var
        KitItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        KitItem.Get(KitItemNo);
        CreateSalesOrder(SalesLine, KitItem, SalesLineShipmentDate(), DemandQty, VarCode);
        if InventoryQty > 0 then
            AddToInventoryWithVariantCodeAndLocation(KitItem, InventoryQty, VarCode, '');
    end;

    local procedure SetupAssemblyOrders(ParentItemNo: Code[20]; ParentQty: Decimal; ChildItemNo: Code[20]; ChildQty: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, SalesLineShipmentDate() - 3, ChildItemNo, '', ChildQty, '');
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, SalesLineShipmentDate() - 2, ParentItemNo, '', ParentQty, '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure ExecutePlanning(UsePlanningWorksheet: Boolean; ParentNo: Code[20]; ChildNo: Code[20])
    var
        PlanningFilterItem: Record Item;
    begin
        PlanningFilterItem.SetFilter("No.", '%1|%2', ParentNo, ChildNo);
        RunPlanning(PlanningFilterItem, SalesLineShipmentDate() + 20, UsePlanningWorksheet);
    end;

    [Normal]
    local procedure AddToInventory(Item: Record Item; Quantity: Decimal)
    begin
        AddToInventoryWithVariantCodeAndLocation(Item, Quantity, '', '')
    end;

    [Normal]
    local procedure AddToInventoryWithVariantCodeAndLocation(Item: Record Item; Quantity: Decimal; VariantCode: Code[10]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalLine.DeleteAll();

        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name,
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.",
          Quantity);

        ItemJournalLine.Validate(
          "Gen. Bus. Posting Group", FindGenBusPostingGroup(ItemJournalLine."Gen. Prod. Posting Group"));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [Normal]
    local procedure AssemblyOrderDueDate(): Date
    begin
        exit(WorkDate() + 8);
    end;

    local procedure SalesLineShipmentDate(): Date
    begin
        exit(WorkDate() + 10);
    end;

    [Normal]
    local procedure SelectGenProdPostingGroupCode(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        GeneralPostingSetup.Next(LibraryRandom.RandInt(GeneralPostingSetup.Count));
        exit(GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    [Normal]
    local procedure InventoryPostingGroupCode(): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.Next(LibraryRandom.RandInt(InventoryPostingGroup.Count));
        exit(InventoryPostingGroup.Code);
    end;

    [Normal]
    local procedure CreateKitItem(var AssemblyItem: Record Item; AssemblyPolicy: Enum "Assembly Policy")
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", "Replenishment System"::Assembly);
        AssemblyItem.Validate("Reordering Policy", AssemblyItem."Reordering Policy"::"Lot-for-Lot");
        AssemblyItem.Validate("Assembly Policy", AssemblyPolicy);
        Evaluate(AssemblyItem."Rescheduling Period", '<1M>');
        AssemblyItem.Modify(true);
    end;

    [Normal]
    local procedure CreateChildItem(var Item: Record Item; ParentItem: Record Item; ReplenishmentSystem: Enum "Replenishment System"; var QtyPer: Decimal)
    begin
        CreateChildItem2(Item, ParentItem, ReplenishmentSystem, QtyPer);
    end;

    [Normal]
    local procedure CreateChildItem2(var Item: Record Item; ParentItem: Record Item; ReplenishmentSystem: Enum "Replenishment System"; var QtyPer: Decimal)
    var
        BOMCompItem: Record "BOM Component";
    begin
        LibraryAssembly.CreateAssemblyList(
          Item."Costing Method"::Standard, ParentItem."No.", true, 1, 0, 0, 1, SelectGenProdPostingGroupCode(), InventoryPostingGroupCode());

        BOMCompItem.SetRange("Parent Item No.", ParentItem."No.");
        BOMCompItem.FindFirst();
        Item.Get(BOMCompItem."No.");

        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<1M>');
        Item.Modify(true);

        // Make sure that the Quantity per is always >= 1
        BOMCompItem.Validate("Quantity per", BOMCompItem."Quantity per" + 1);
        BOMCompItem.Modify(true);

        QtyPer := BOMCompItem."Quantity per";
    end;

    [Normal]
    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; SalesItem: Record Item; SalesLineShipmentDate: Date; Quantity: Decimal; VariantCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesItem."No.", SalesLineShipmentDate, Quantity);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    [Normal]
    local procedure CreateSalesOrder2(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; SalesItem: Record Item; SalesLineShipmentDate: Date; Quantity: Decimal; VariantCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesItem."No.", SalesLineShipmentDate, Quantity);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure FindGenBusPostingGroup(GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();
        exit(GeneralPostingSetup."Gen. Bus. Posting Group");
    end;

    [Normal]
    local procedure RunPlanning(var FilterRecordItem: Record Item; ToDate: Date; UsePlanningWorksheet: Boolean)
    begin
        if UsePlanningWorksheet then
            LibraryPlanning.CalcRegenPlanForPlanWksh(FilterRecordItem, WorkDate(), ToDate)
        else
            CalculatePlanForReqWksh(FilterRecordItem, WorkDate(), ToDate);
    end;

    [Normal]
    local procedure RunAvailableToPromiseOnSalesHeader(SalesHeader: Record "Sales Header"; var OrderPromisingLine: Record "Order Promising Line")
    var
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(OrderPromisingLine);
    end;

    local procedure HandlingTime(Location: Record Location): Integer
    begin
        exit(CalcDate(Location."Outbound Whse. Handling Time", WorkDate()) - WorkDate());
    end;

    [Normal]
    local procedure VerifyNumberOfReqLines(nExpectedReqLines: Integer; NoFilter: Code[20])
    var
        ReqLine: Record "Requisition Line";
    begin
        // Filter to make sure we avoid any left over req lines
        ReqLine.SetFilter("No.", NoFilter);

        // Verify: x req. lines were created
        Assert.AreEqual(nExpectedReqLines, ReqLine.Count, StrSubstNo('Exactly %1 req lines should have been created!', nExpectedReqLines));
    end;

    [Normal]
    local procedure VerifyReqLineExists(No: Code[20]; VariantCode: Code[10]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date)
    var
        ReqLine: Record "Requisition Line";
    begin
        VerifyReqLineExists2(No, VariantCode, ActionMessage, OriginalQuantity, DueDate);

        ReqLine.SetRange("No.", No);
        ReqLine.FindFirst();
        Assert.AreEqual(Quantity, ReqLine.Quantity, 'Quantity on requisition line didn''t have expected value');
    end;

    [Normal]
    local procedure VerifyReqLineExists2(No: Code[20]; VariantCode: Code[10]; ActionMessage: Enum "Action Message Type"; OriginalQuantity: Decimal; DueDate: Date)
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.SetRange("No.", No);
        Assert.IsTrue(ReqLine.FindFirst(), 'No requisition line create for item');
        Assert.AreEqual(VariantCode, ReqLine."Variant Code", 'Variant code on requisition line didn''t have expected value');
        Assert.AreEqual(ActionMessage, ReqLine."Action Message", 'Action Message on requisition line didn''t have expected value');
        Assert.AreEqual(
          OriginalQuantity, ReqLine."Original Quantity", 'Original Quantity on requisition line didn''t have expected value');
        Assert.AreEqual(DueDate, ReqLine."Due Date", 'Due Date on requisition line didn''t have expected value');
    end;

    [Normal]
    local procedure CalculatePlanForReqWksh(var Item: Record Item; StartDate: Date; EndDate: Date)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.Next(LibraryRandom.RandInt(ReqWkshTemplate.Count));
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Next(LibraryRandom.RandInt(RequisitionWkshName.Count));
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartDate, EndDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ChildItemsOnAO()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit sunshine scenario: No inventory, 5 child items on pre-existing AO, a SO of 10 parent items.

        QtyOnSalesOrder := 10;
        QtyOnInventory := 0;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 5;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::New, QtyOnSalesOrder, 0, SalesLineShipmentDate());
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyPer * QtyOnSalesOrder, ChildQtyOnAO, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_VariantItemsOnInventory()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        VarCode: Code[10];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario with variant: 3 parent items on inventory, no pre-existing AO, a SO of 10 parent items.

        QtyOnSalesOrder := 10;
        QtyOnInventory := 3;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItemsVariant(ParentNo, ChildNo, QtyPer, VarCode);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, VarCode);
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, VarCode, "Action Message Type"::New, QtyOnSalesOrder - QtyOnInventory, 0, SalesLineShipmentDate());
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::New, QtyPer * (QtyOnSalesOrder - QtyOnInventory), 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_NoDemandNoSupply()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario. No demand and no supply, meaning no req lines
        // This is to verify that the planning worksheet doesn't plan for empty orders

        QtyOnSalesOrder := 0;
        QtyOnInventory := 0;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(0, ParentNo);
        VerifyNumberOfReqLines(0, ChildNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ParentItemsOnAO()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario: No inventory, 4 parent items on pre-existing AO, a SO of 10 parent items.

        QtyOnSalesOrder := 10;
        QtyOnInventory := 0;
        ParentQtyOnAO := 4;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyOnSalesOrder, ParentQtyOnAO, SalesLineShipmentDate());
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::New, QtyPer * QtyOnSalesOrder, 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ChildItemsOnAOAndParentItemsOnInventory()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario: 2 parent items on inventory, 3 child items on pre-existing AO, a SO of 15 parent items.

        QtyOnSalesOrder := 15;
        QtyOnInventory := 2;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 3;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::New, QtyOnSalesOrder - QtyOnInventory, 0, SalesLineShipmentDate());
        VerifyReqLineExists(
          ChildNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyPer * (QtyOnSalesOrder - QtyOnInventory), ChildQtyOnAO, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ChildAndParentItemsOnAO()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario: 0 parent items on inventory, 1 child items on pre-existing AO, 4 parent items on pre-existing AO, a SO of 23 parent items.

        QtyOnSalesOrder := 23;
        QtyOnInventory := 0;
        ParentQtyOnAO := 4;
        ChildQtyOnAO := 1;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyOnSalesOrder, 4, SalesLineShipmentDate());
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyPer * QtyOnSalesOrder, ChildQtyOnAO, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ItemsOnAOAndInventory()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario: 8 parent items on inventory, 1 child items on pre-existing AO, 4 parent items on pre-existing AO, a SO of 28 parent items.
        // (Some of everything)

        QtyOnSalesOrder := 28;
        QtyOnInventory := 8;
        ParentQtyOnAO := 4;
        ChildQtyOnAO := 1;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(
          ParentNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyOnSalesOrder - QtyOnInventory, ParentQtyOnAO, SalesLineShipmentDate());
        VerifyReqLineExists(
          ChildNo, '', "Action Message Type"::"Resched. & Chg. Qty.", QtyPer * (QtyOnSalesOrder - QtyOnInventory), ChildQtyOnAO, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_EnoughInventory()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario where demand is completely covered by inventory

        QtyOnSalesOrder := 11;
        QtyOnInventory := 13;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(0, ParentNo);
        VerifyNumberOfReqLines(0, ChildNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_EnoughInventoryAndAOs()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario where demand is completely covered by inventory and pre-existing AO

        QtyOnSalesOrder := 11;
        QtyOnInventory := 7;
        ParentQtyOnAO := 4;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::Reschedule, ParentQtyOnAO, 0, SalesLineShipmentDate());
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::New, QtyPer * ParentQtyOnAO, 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_TestCancel()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario where demand is completely covered by inventory and all pre-existing AOs should be cancelled

        QtyOnSalesOrder := 17;
        QtyOnInventory := 17;
        ParentQtyOnAO := 4;
        ChildQtyOnAO := 2;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(true, ParentNo, ChildNo);

        VerifyNumberOfReqLines(1, ParentNo);
        VerifyNumberOfReqLines(1, ChildNo);

        // VerifyReqLineExists(No,VariantCode,ActionMessage,Quantity,originalQuantity,DueDate)
        VerifyReqLineExists(ParentNo, '', "Action Message Type"::Cancel, 0, ParentQtyOnAO, WorkDate() + 8);
        VerifyReqLineExists(ChildNo, '', "Action Message Type"::Cancel, 0, ChildQtyOnAO, WorkDate() + 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_ReqWorkWithVariant()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        VarCode: Code[10];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit variant scenario in req worksheet. No req lines should be created.

        QtyOnSalesOrder := 10;
        QtyOnInventory := 0;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 0;

        Initialize();

        SetupItemsVariant(ParentNo, ChildNo, QtyPer, VarCode);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, VarCode);
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(false, ParentNo, ChildNo);

        VerifyNumberOfReqLines(0, ParentNo);
        VerifyNumberOfReqLines(0, ChildNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_KiK_TestReqWorkLeavesAOsAlone()
    var
        QtyPer: Decimal;
        ParentNo: Code[20];
        ChildNo: Code[20];
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
        ParentQtyOnAO: Decimal;
        ChildQtyOnAO: Decimal;
    begin
        // Kit-in-kit scenario in req worksheet. No req lines should be created.

        QtyOnSalesOrder := 10;
        QtyOnInventory := 0;
        ParentQtyOnAO := 0;
        ChildQtyOnAO := 2;

        Initialize();

        SetupItems(ParentNo, ChildNo, QtyPer);
        SetupSupplyDemand(ParentNo, QtyOnSalesOrder, QtyOnInventory, '');
        SetupAssemblyOrders(ParentNo, ParentQtyOnAO, ChildNo, ChildQtyOnAO);
        ExecutePlanning(false, ParentNo, ChildNo);

        VerifyNumberOfReqLines(0, ParentNo);
        VerifyNumberOfReqLines(0, ChildNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_PurchasedItemsInKit()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
        PlanningFilterItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        QtyPer: Decimal;
        QtyOnSalesOrder: Decimal;
        ParentQtyOnAO: Decimal;
    begin
        // Item-in-kit scenario in req worksheet. 10 parent items on AO, 10 parent items on SO, child item is purchased

        QtyOnSalesOrder := 10;
        ParentQtyOnAO := 10;

        Initialize();

        // A kit item, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item, Replenishment System=Assembly, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Resched. Period=2M
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Purchase, QtyPer);

        // A SO, with a line of TS1-KIT, Qty.=10, Shipment Date=W + 10D
        CreateSalesOrder(SalesLine, ParentAssemblyItem, SalesLineShipmentDate(), QtyOnSalesOrder, '');

        Clear(AssemblyHeader);

        // Create an AO for parent item
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, SalesLineShipmentDate(), ParentAssemblyItem."No.", '', ParentQtyOnAO, '');

        // Run Req. Worksheet from W to W + 30D, No. = ParentAssemblyItem."No."|ChildItem."No."
        PlanningFilterItem.SetFilter("No.", '%1|%2', ParentAssemblyItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningFilterItem, WorkDate(), WorkDate() + 30);

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        // Works with: VerifyReqLineExists(ChildItem."No.",'',ReqLine."Action Message"::New,BOMCompItem."Quantity per" * 10,0,WorkDate() + 9);
        VerifyReqLineExists(ChildItem."No.", '', "Action Message Type"::New, QtyPer * ParentQtyOnAO, 0, SalesLineShipmentDate() - 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_ATO_AOCreatedFromSO()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
        PlanningFilterItem: Record Item;
        QtyPer: Decimal;
        QtyOnSalesOrder: Decimal;
    begin
        // Kit-in-ATOKit scenario in planning worksheet. 10 parent items on SO.
        // AO for the parent item will be created automatically for the SO, so planning should only suggest an AO for the child item.

        QtyOnSalesOrder := 10;

        Initialize();

        // A kit item, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        // A kit item TS1-COMP1, Replenishment System=Assembly, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Resched. Period=2M
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);

        CreateSalesOrder(SalesLine, ParentAssemblyItem, SalesLineShipmentDate(), QtyOnSalesOrder, '');

        // Run Planning Worksheet from W to W + 30D, No. = ParentAssemblyItem."No."|ChildItem."No."
        PlanningFilterItem.SetFilter("No.", '%1|%2', ParentAssemblyItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningFilterItem, WorkDate(), WorkDate() + 30);

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists2(ChildItem."No.", '', "Action Message Type"::New, 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_ATOInKit()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
        PlanningFilterItem: Record Item;
        QtyPer: Decimal;
        QtyOnSalesOrder: Decimal;
    begin
        // ATOKit-in-Kit scenario in planning worksheet. 10 parent items on SO.
        // Simple test to verify that ATO items are treated like ATS when they are child items.

        QtyOnSalesOrder := 10;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item TS1-COMP1, Replenishment System=Assembly, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Resched. Period=2M
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);

        ChildItem.Validate("Assembly Policy", ChildItem."Assembly Policy"::"Assemble-to-Order");
        ChildItem.Modify(true);

        // A SO, TS1-SO1, with a line of TS1-KIT, Qty.=10, Shipment Date=W + 10D
        CreateSalesOrder(SalesLine, ParentAssemblyItem, SalesLineShipmentDate(), QtyOnSalesOrder, '');

        // Run Planning Worksheet from W to W + 30D, No. = ParentAssemblyItem."No."|ChildItem."No."
        PlanningFilterItem.SetFilter("No.", '%1|%2', ParentAssemblyItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningFilterItem, WorkDate(), WorkDate() + 30);

        VerifyNumberOfReqLines(1, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists(ParentAssemblyItem."No.", '', "Action Message Type"::New, QtyOnSalesOrder, 0, SalesLineShipmentDate());
        VerifyReqLineExists(ChildItem."No.", '', "Action Message Type"::New, QtyPer * QtyOnSalesOrder, 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Worksheet_ATOReservation()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
        PlanningFilterItem: Record Item;
        QtyPer: Decimal;
        QtyOnSalesOrder: Decimal;
        QtyToAssembleToOrder: Decimal;
    begin
        // Kit-in-ATOKit scenario in planning worksheet. 10 parent items on SO with Quantity to assemble to order set to 7.
        // Tests that the reservation link between the SO and the AO for the ATO item is respected.

        QtyOnSalesOrder := 10;
        QtyToAssembleToOrder := 7;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        // A kit item TS1-COMP1, Replenishment System=Assembly, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Resched. Period=2M
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);

        // A SO, TS1-SO1, with a line of TS1-KIT, Qty.=10, Shipment Date=W + 10D
        CreateSalesOrder(SalesLine, ParentAssemblyItem, SalesLineShipmentDate(), QtyOnSalesOrder, '');

        SalesLine.Validate("Qty. to Assemble to Order", QtyToAssembleToOrder);
        SalesLine.Modify(true);

        // Run Planning Worksheet from W to W + 30D, No. = ParentAssemblyItem."No."|ChildItem."No."
        PlanningFilterItem.SetFilter("No.", '%1|%2', ParentAssemblyItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningFilterItem, WorkDate(), WorkDate() + 30);

        VerifyNumberOfReqLines(1, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists(ParentAssemblyItem."No.", '', "Action Message Type"::New, QtyOnSalesOrder - QtyToAssembleToOrder, 0, SalesLineShipmentDate());
        VerifyReqLineExists2(ChildItem."No.", '', "Action Message Type"::New, 0, SalesLineShipmentDate() - 1);
    end;

    [Normal]
    local procedure RunOrderPlanningAsm()
    var
        RequisitionLine: Record "Requisition Line";
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
    begin
        OrderPlanningMgt.SetDemandType("Demand Order Source Type"::"Assembly Demand");
        OrderPlanningMgt.GetOrdersToPlan(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanning_PlentyOfInventory()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        QtyPer: Decimal;
    begin
        // Kit-in-kit scenario. 1500 (ie. plenty) components on inventory, 5 parent items on AO.
        // Tests that the Order planning doesn't create unnecessary AOs.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATS, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item TS1-COMP1, Replenishment System=Purchase, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE
        CreateChildItem2(ChildItem, ParentAssemblyItem, "Replenishment System"::Purchase, QtyPer);

        AddToInventory(ChildItem, 1500);

        // Create an AO for parent
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AssemblyOrderDueDate(), ParentAssemblyItem."No.", '', 5, '');
        AssemblyHeader.Modify(true);

        RunOrderPlanningAsm();

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(0, ChildItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanning_PurchasedItemInKitVariant()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ItemVariant: Record "Item Variant";
        QtyPer: Decimal;
    begin
        // Purchased item in assembly variant. 7 child item on inventory. 10 parent items on AO. No SO.
        // Tests the Order planning with variants and demand partially covered by inventory.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATS, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item TS1-COMP1, Replenishment System=Purchase, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE
        CreateChildItem2(ChildItem, ParentAssemblyItem, "Replenishment System"::Purchase, QtyPer);

        // Make a variant of TS1-KIT: VAR1
        LibraryInventory.CreateVariant(ItemVariant, ParentAssemblyItem);

        AddToInventory(ChildItem, 7);

        // Create an AO for parent
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 8, ParentAssemblyItem."No.", '', 10, ItemVariant.Code);

        RunOrderPlanningAsm();

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists2(ChildItem."No.", '', "Action Message Type"::New, 0, AssemblyOrderDueDate() - 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanning_TwoProducedComps()
    var
        ParentAssemblyItem: Record Item;
        BOMCompItem: Record "BOM Component";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Produced items in assembly. 0 item on inventory. 10 parent items on AO. No SO.
        // Tests the Order planning with two produced components.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATS, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item TS1-COMP1, Replenishment System=Purchase, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE
        LibraryAssembly.CreateAssemblyList(
          ParentAssemblyItem."Costing Method"::Standard, ParentAssemblyItem."No.", true, 1, 0, 0, 1, SelectGenProdPostingGroupCode(),
          InventoryPostingGroupCode());

        // A kit item TS1-COMP2, Replenishment System=Purchase, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE
        LibraryAssembly.CreateAssemblyList(
          ParentAssemblyItem."Costing Method"::Standard, ParentAssemblyItem."No.", true, 1, 0, 0, 1, SelectGenProdPostingGroupCode(),
          InventoryPostingGroupCode());

        BOMCompItem.SetRange("Parent Item No.", ParentAssemblyItem."No.");
        BOMCompItem.FindSet();
        ChildItem1.Get(BOMCompItem."No.");
        ChildItem1.Validate("Replenishment System", ChildItem1."Replenishment System"::"Prod. Order");
        ChildItem1.Validate("Reordering Policy", ChildItem1."Reordering Policy"::"Lot-for-Lot");
        ChildItem1.Modify(true);

        BOMCompItem.Next();
        ChildItem2.Get(BOMCompItem."No.");
        ChildItem2.Validate("Replenishment System", ChildItem2."Replenishment System"::"Prod. Order");
        ChildItem2.Validate("Reordering Policy", ChildItem2."Reordering Policy"::"Lot-for-Lot");
        ChildItem2.Modify(true);

        // Create an AO for parent
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AssemblyOrderDueDate(), ParentAssemblyItem."No.", '', 10, '');
        AssemblyHeader.Modify(true);

        RunOrderPlanningAsm();

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem1."No.");
        VerifyNumberOfReqLines(1, ChildItem2."No.");

        VerifyReqLineExists2(ChildItem1."No.", '', "Action Message Type"::New, 0, AssemblyOrderDueDate() - 1);
        VerifyReqLineExists2(ChildItem2."No.", '', "Action Message Type"::New, 0, AssemblyOrderDueDate() - 1);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanning_ChangeBeforeCarryOut()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ReqLine: Record "Requisition Line";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        QtyPer: Decimal;
        ParentQtyOnAO: Decimal;
        NewQtyOnAO: Decimal;
    begin
        // Demand for ATS item changed between calculation and carry out. 10 parent items on AO. Order planning suggests AO for child components.
        // Parent AO qty is then changed before carry out. Order Planning should display an error message.

        ParentQtyOnAO := 10;
        NewQtyOnAO := 5;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATS, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        // A kit item TS1-COMP1, Replenishment System=Purchase, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE
        CreateChildItem2(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);

        // Create an AO for parent
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AssemblyOrderDueDate(), ParentAssemblyItem."No.", '', ParentQtyOnAO, '');
        AssemblyHeader.Modify(true);

        RunOrderPlanningAsm();

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists2(ChildItem."No.", '', "Action Message Type"::New, 0, AssemblyOrderDueDate() - 1);

        AssemblyHeader.Validate(Quantity, NewQtyOnAO);
        AssemblyHeader.Modify(true);

        Clear(ReqLine);

        ReqLine.SetRange("No.", ChildItem."No.");
        ReqLine.SetRange("Action Message", "Action Message Type"::New);
        ReqLine.SetRange(Quantity, QtyPer * ParentQtyOnAO);

        CarryOutActionMsgPlan.SetReqWkshLine(ReqLine);
        CarryOutActionMsgPlan.UseRequestPage := false;
        asserterror CarryOutActionMsgPlan.Run();
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("Demand Quantity (Base)"), Format(1));
        ClearLastError();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanning_ATO()
    var
        ParentAssemblyItem: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
    begin
        // Kit-in-ATOKit scenario in Order Planning. 10 parent items on SO.
        // AO for the parent item will be created automatically for the SO, so order planning should only suggest an AO for the child item.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(ParentAssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        // A kit item TS1-COMP1, Replenishment System=Assembly, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Resched. Period=2M
        CreateChildItem(ChildItem, ParentAssemblyItem, "Replenishment System"::Assembly, QtyPer);

        // A SO, TS1-SO1, with a line of TS1-KIT, Qty.=10, Shipment Date=W + 10D
        CreateSalesOrder(SalesLine, ParentAssemblyItem, SalesLineShipmentDate(), 10, '');

        RunOrderPlanningAsm();

        VerifyNumberOfReqLines(0, ParentAssemblyItem."No.");
        VerifyNumberOfReqLines(1, ChildItem."No.");

        VerifyReqLineExists2(ChildItem."No.", '', "Action Message Type"::New, 0, SalesLineShipmentDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATP_SomeInventoryNoAO()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
    begin
        // 5 items on inventory and non on AO. SO of 10. ATP should not be able not produce an earliest shipment date because the demand cannot be met without creating additional orders.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), 10, '');

        AddToInventory(AssemblyItem, 5);

        RunAvailableToPromiseOnSalesHeader(SalesHeader, OrderPromisingLine);

        Assert.AreEqual(
          0D, OrderPromisingLine."Earliest Shipment Date",
          'Available to promise should have failed to produce an earliest shipment date when it didn''t');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATP_SOCoveredByInventoryAndAO()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        AssemblyHeader: Record "Assembly Header";
        AODueDate: Date;
    begin
        // 5 items on inventory and 5 on AO. SO of 10. ATP should be able to produce the earliest shipment date which should be the due date of the AO.

        AODueDate := WorkDate() + 3;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), 10, '');

        AddToInventory(AssemblyItem, 5);

        // Create an AO for assembly of 5
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AODueDate, AssemblyItem."No.", '', 5, '');

        RunAvailableToPromiseOnSalesHeader(SalesHeader, OrderPromisingLine);

        Assert.AreEqual(
          AODueDate, OrderPromisingLine."Earliest Shipment Date",
          'Available to promise did not produce the correct earliest shipment date');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATP_ATO()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        SODueDate: Date;
    begin
        // 10 ATO items on SO. ATP should be able to produce the earliest shipment date which should be the due date of the AO that was produced by the SO.

        SODueDate := WorkDate() + 5;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, SODueDate, 10, '');

        RunAvailableToPromiseOnSalesHeader(SalesHeader, OrderPromisingLine);

        Assert.AreEqual(
          SODueDate, OrderPromisingLine."Earliest Shipment Date",
          'Available to promise did not produce the correct earliest shipment date for ATO');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATP_ATO_LoweredQtyToATO()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        AssemblyHeader: Record "Assembly Header";
        AODueDate: Date;
    begin
        // 10 ATO items on SO. ATP should be able to produce the earliest shipment date which should be the due date of the AO that was produced by the SO.
        // FAILS DUE TO BUG 267049

        AODueDate := WorkDate() + 2;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        AddToInventory(AssemblyItem, 5);

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), 10, '');
        SalesLine.Validate("Qty. to Assemble to Order", 3);
        SalesLine.Modify(true);

        // Create an AO for assembly of 5
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AODueDate, AssemblyItem."No.", '', 2, '');

        RunAvailableToPromiseOnSalesHeader(SalesHeader, OrderPromisingLine);

        Assert.AreEqual(
          AODueDate, OrderPromisingLine."Earliest Shipment Date",
          'Available to promise did not produce the correct earliest shipment date for ATO');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CTP_SOPartiallyCoveredByInventory()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        Location: Record Location;
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        // 5 items on inventory and non on AO. SO of 10. CTP should be able to produce an earliest shipment date because it can suggest an AO of the missing items.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), 10, '');
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        AddToInventoryWithVariantCodeAndLocation(AssemblyItem, 5, '', Location.Code);

        // Exercise: Run Capable to Promise.
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");

        Assert.AreEqual(
          WorkDate() + 2 + HandlingTime(Location), OrderPromisingLine."Earliest Shipment Date",
          'Capable to promise produced the wrong earliest shipment date');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CTP_ATO()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        Location: Record Location;
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        // 5 ATO items on inventory and non on AO. SO of 10, QtATO=3. CTP should be able to produce an earliest shipment date and the appropriate req line should be generated.

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Order");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        AddToInventoryWithVariantCodeAndLocation(AssemblyItem, 5, '', Location.Code);

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), 10, '');
        SalesLine.Validate("Qty. to Assemble to Order", 3);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // Exercise: Run Capable to Promise.
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");

        Assert.AreEqual(
          WorkDate() + 2 + HandlingTime(Location), OrderPromisingLine."Earliest Shipment Date",
          'Capable to promise produced the wrong earliest shipment date');

        VerifyNumberOfReqLines(1, AssemblyItem."No.");

        VerifyReqLineExists(AssemblyItem."No.", '', "Action Message Type"::New, 2, 0, WorkDate() + 2 + HandlingTime(Location));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CTP_Variant()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        ItemVariant: Record "Item Variant";
        AvailabilityMgt: Codeunit AvailabilityManagement;
        QtyOnSalesOrder: Decimal;
        QtyOnInventory: Decimal;
    begin
        // 0 variant items on inventory and 5 on AO. SO of 20. CTP should be able to produce an earliest shipment date and the appropriate req line should be generated.

        QtyOnSalesOrder := 20;
        QtyOnInventory := 5;

        Initialize();

        // A kit item TS1-KIT, UOM=PCS, Item Category Code=FURNITUE, Reorder Policy=LFL, Include Inventory=TRUE, Replenishment System=Assembly, Assembly Policy=ATO, BOM=1xTS1-COMP1
        CreateKitItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Stock");

        LibraryInventory.CreateVariant(ItemVariant, AssemblyItem);

        AddToInventoryWithVariantCodeAndLocation(AssemblyItem, QtyOnInventory, ItemVariant.Code, '');

        CreateSalesOrder2(SalesLine, SalesHeader, AssemblyItem, WorkDate(), QtyOnSalesOrder, ItemVariant.Code);

        // Exercise: Run Capable to Promise.
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");

        Assert.AreEqual(
          WorkDate() + 2, OrderPromisingLine."Earliest Shipment Date", 'Capable to promise produced the wrong earliest shipment date');

        VerifyNumberOfReqLines(1, AssemblyItem."No.");

        VerifyReqLineExists(AssemblyItem."No.", ItemVariant.Code, "Action Message Type"::New, QtyOnSalesOrder - QtyOnInventory, 0, WorkDate() + 2);
    end;
}

