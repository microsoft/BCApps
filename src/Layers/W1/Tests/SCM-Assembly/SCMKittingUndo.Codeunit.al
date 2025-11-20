// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Item;
using Microsoft.Assembly.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.BOM;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Assembly.History;
using Microsoft.Sales.Document;
using Microsoft.Assembly.Posting;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;

codeunit 137097 "SCM Kitting - Undo"
{
    // // [FEATURE] [Assembly] [Undo] [SCM]
    // Unsupported version tags:
    // SE: Unable to Execute
    // 
    // This CU is covering tests for the kitting undo functionality

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Undo] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationSilver: Record Location;
        LocationSilverWithPick: Record Location;
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        GenProdPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        isInitialized: Boolean;
        WorkDate2: Date;
        ATO_MUST_BE_NO: Label 'Assemble to Order must be equal to ''No''  in ';
        MSG_CANNOT_RESTORE: Label 'must be equal';
        MSG_UPDATE: Label 'Do you want to update the';
        MSG_CREATE_INVT_MOVM: Label 'Do you want to create Inventory Movement?';
        MSG_ACTIVITY_CREATED: Label 'has been created.';
        MSG_REMAINING_QTY: Label 'Remaining Quantity';
        MSG_RESERVED_QTY: Label 'Reserved Quantity';
        MSG_INSUFFICIENT_QTY: Label 'it is not available';
        MSG_CANNOT_RESTORE_2: Label 'number of lines';
        MSG_REVERSED: Label 'Reversed';
        ConfirmUndoCount: Integer;
        MSG_WANT_RECREATE: Label 'Do you want to recreate the assembly order from the posted assembly order?';
        MSG_WANT_UNDO: Label 'Do you want to undo posting of the posted assembly order?';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Undo");
        ConfirmUndoCount := 0;
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Undo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        GlobalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Undo");
    end;

    local procedure GlobalSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        SetupAssembly();
        SetupItemJournal();
        SetupInventorySetup();
        WarehouseEmployee.Reset();
        WarehouseEmployee.DeleteAll(true);
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
        LocationSetup(LocationBlue, false, false, false, false, false, false);
        LocationSetup(LocationSilver, false, false, false, false, false, true);
        LocationSetup(LocationSilverWithPick, false, false, false, false, true, true);
        LocationSetup(LocationWhite, true, true, true, true, true, true);
    end;

    [Normal]
    local procedure SetupAssembly()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblySetup: Record "Assembly Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ManufacturingSetupRec: Record "Manufacturing Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Transfer Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);

        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Assembly Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Blanket Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Default Location for Orders", '');
        AssemblySetup.Validate("Copy Component Dimensions from", AssemblySetup."Copy Component Dimensions from"::"Order Header");
        AssemblySetup.Validate("Copy Comments when Posting", true);
        AssemblySetup.Validate("Stockout Warning", false);
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        ManufacturingSetupRec.Get();
        ManufacturingSetupRec.Validate("Planned Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetupRec.Validate("Firm Planned Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetupRec.Validate("Released Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetupRec.Modify(true);
    end;

    [Normal]
    local procedure SetupItemJournal()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure LocationSetup(var Location: Record Location; Directed: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        BinCount: Integer;
    begin
        if Directed then
            LibraryWarehouse.CreateFullWMSLocation(Location, 8)
        else begin
            LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
            for BinCount := 1 to 8 do
                LibraryWarehouse.CreateBin(Bin, Location.Code, 'Bin ' + Format(BinCount), '', '');
        end;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, Directed);
    end;

    local procedure SetupInventorySetup()
    begin
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
    end;

    [Normal]
    local procedure CreateAssemblyList(ParentItem: Record Item; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Decimal)
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        CompCount: Integer;
    begin
        // Add components - qty per is increasing same as no of components
        for CompCount := 1 to NoOfComponents do begin
            Clear(Item);
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.AddEntityDimensions(AssemblyLine.Type::Item, Item."No.");
            AddComponentToAssemblyList(
              BOMComponent, "BOM Component Type"::Item, Item."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Item."Base Unit of Measure", QtyPer);
        end;

        // Add resources - qty per is increasing same as no of components
        for CompCount := 1 to NoOfResources do begin
            LibraryAssembly.CreateResource(Resource, true, GenProdPostingGr);
            LibraryAssembly.AddEntityDimensions(AssemblyLine.Type::Resource, Resource."No.");
            AddComponentToAssemblyList(
              BOMComponent, "BOM Component Type"::Resource, Resource."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Resource."Base Unit of Measure", QtyPer);
        end;

        // Add simple text
        for CompCount := 1 to NoOfTexts do
            AddComponentToAssemblyList(BOMComponent, "BOM Component Type"::" ", '', ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, '', 0);
    end;

    local procedure CreateInternalMovementGetBin(var InternalMovementHeader: Record "Internal Movement Header"; ItemNo: Code[20]; LocationCode: Code[10]; ToBinCode: Code[20]; BinContentFilter: Code[100])
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, ToBinCode);
        LibraryWarehouse.GetBinContentInternalMovement(InternalMovementHeader, LocationCode, ItemNo, BinContentFilter);
    end;

    local procedure CreateItemReclassificationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[50]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Transfer, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Transfer, ItemNo, Qty);
    end;

    [Normal]
    local procedure AddComponentToAssemblyList(var BOMComponent: Record "BOM Component"; ComponentType: Enum "BOM Component Type"; ComponentNo: Code[20]; ParentItemNo: Code[20]; VariantCode: Code[10]; ResourceUsage: Option; UOM: Code[10]; QuantityPer: Decimal)
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, ComponentType, ComponentNo, QuantityPer, UOM);
        if ComponentType = "BOM Component Type"::Resource then
            BOMComponent.Validate("Resource Usage Type", ResourceUsage);
        BOMComponent.Validate("Variant Code", VariantCode);
        if ComponentNo = '' then
            BOMComponent.Validate(Description,
              LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);
    end;

    [Normal]
    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ParentItem: Record Item; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; DueDate: Date; Quantity: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItem."No.", LocationCode, Quantity, VariantCode);
        AssemblyHeader.Validate("Bin Code", BinCode);
        AssemblyHeader.Modify(true);
    end;

    local procedure CreateAssemblyOrderWithInventory(var AssemblyHeader: Record "Assembly Header"; var Item: Record Item; OrderQty: Decimal; LocationCode: Code[10]; HeaderBinCode: Code[20]; ComponentsBinCode: Code[20])
    var
        DueDate: Date;
    begin
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 1);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, HeaderBinCode, '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, ComponentsBinCode);
    end;

    local procedure CreateAssembledItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
        CreateAssemblyList(Item, NoOfComponents, NoOfResources, NoOfTexts, QtyPer);
    end;

    local procedure AddCommentsToOrder(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.AddAssemblyHeaderComment(AssemblyHeader, 0);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if not AssemblyLine.FindSet() then
            exit;

        repeat
            LibraryAssembly.AddAssemblyHeaderComment(AssemblyHeader, AssemblyLine."Line No.");
        until AssemblyLine.Next() = 0;
    end;

    local procedure CopyPostedAOToTemp(PostedAssemblyHeader: Record "Posted Assembly Header"; var TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary; var TempPostedAssemblyLine: Record "Posted Assembly Line" temporary)
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // Header
        TempPostedAssemblyHeader.DeleteAll();
        TempPostedAssemblyHeader := PostedAssemblyHeader;
        TempPostedAssemblyHeader.Insert();

        // Lines
        TempPostedAssemblyLine.DeleteAll();
        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        if not PostedAssemblyLine.FindSet() then
            exit;

        repeat
            TempPostedAssemblyLine := PostedAssemblyLine;
            TempPostedAssemblyLine.Insert();
        until PostedAssemblyLine.Next() = 0;
    end;

    local procedure CopyAOToTemp(AssemblyHeader: Record "Assembly Header"; var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        // Header
        TempAssemblyHeader.Reset();
        TempAssemblyHeader.DeleteAll();
        TempAssemblyHeader := AssemblyHeader;
        TempAssemblyHeader.Insert();

        // Lines
        TempAssemblyLine.Reset();
        TempAssemblyLine.DeleteAll();
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if not AssemblyLine.FindSet() then
            exit;

        repeat
            TempAssemblyLine := AssemblyLine;
            TempAssemblyLine.Insert();
        until AssemblyLine.Next() = 0;
    end;

    local procedure CreateSaleDocType(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, SalesQty);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSaleDocType(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, VariantCode, SalesQty, ShipmentDate, LocationCode);
    end;

    local procedure FindSOL(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SOLIndex: Integer)
    begin
        Clear(SalesLine);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet(true);

        if SOLIndex > 1 then
            SalesLine.Next(SOLIndex - 1);
    end;

    local procedure GetMaxValue(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);

        exit(Value2);
    end;

    local procedure GetTotalPostedQuantityBaseHeader(AssemblyOrderNo: Code[20]): Decimal
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        Quantity: Decimal;
    begin
        Quantity := 0;

        // Consider the postings of this initial AO without the undone (reversed) orders - and assumes no posted AO has been deleted
        PostedAssemblyHeader.SetRange("Order No.", AssemblyOrderNo);
        PostedAssemblyHeader.SetRange(Reversed, false);
        if not PostedAssemblyHeader.FindSet() then
            exit(Quantity);

        repeat
            Quantity += PostedAssemblyHeader."Quantity (Base)";
        until PostedAssemblyHeader.Next() = 0;

        exit(Quantity);
    end;

    local procedure GetTotalPostedQuantityBaseLine(AssemblyOrderNo: Code[20]; LineNo: Integer): Decimal
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        Quantity: Decimal;
    begin
        Quantity := 0;

        // Consider the postings of this initial AO without the undone (reversed) orders - and assumes no posted AO has been deleted
        PostedAssemblyHeader.SetRange("Order No.", AssemblyOrderNo);
        PostedAssemblyHeader.SetRange(Reversed, false);
        if not PostedAssemblyHeader.FindSet() then
            exit(Quantity);

        repeat
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
            PostedAssemblyLine.SetRange("Line No.", LineNo);
            PostedAssemblyLine.FindFirst(); // let it fail if doesn't exist
            Quantity += PostedAssemblyLine."Quantity (Base)";
        until PostedAssemblyHeader.Next() = 0;

        exit(Quantity);
    end;

    local procedure SetLocAndBinCodeOnAsmLines(AssemblyHeader: Record "Assembly Header"; Bin: Record Bin)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        if AssemblyLine.FindSet() then
            repeat
                AssemblyLine.Validate("Location Code", Bin."Location Code");
                AssemblyLine.Validate("Bin Code", Bin.Code);
                AssemblyLine.Modify(true);
            until AssemblyLine.Next() = 0;
    end;

    local procedure PostAssemblyOrderQty(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal)
    var
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        Clear(AssemblyPost);
        AssemblyHeader.Validate("Quantity to Assemble", Qty);
        AssemblyHeader.Modify(true);

        AssemblyPost.Run(AssemblyHeader);
    end;

    local procedure FindAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[10]; DueDate: Date; UOM: Code[10]; Qty: Decimal)
    begin
        Clear(AssemblyHeader);
        AssemblyHeader.SetRange("Document Type", DocumentType);
        AssemblyHeader.SetRange("Item No.", Item."No.");
        if VariantCode = '' then
            AssemblyHeader.SetRange(Description, Item.Description)
        else
            AssemblyHeader.SetRange(Description, VariantCode);
        AssemblyHeader.SetFilter("Variant Code", '%1', VariantCode);
        AssemblyHeader.SetFilter("Location Code", '%1', LocationCode);
        AssemblyHeader.SetFilter("Bin Code", '%1', BinCode);
        AssemblyHeader.SetRange("Due Date", DueDate);
        AssemblyHeader.SetRange("Unit of Measure Code", UOM);
        AssemblyHeader.SetRange(Quantity, Qty);
        AssemblyHeader.SetRange("Quantity (Base)", Qty * LibraryInventory.GetQtyPerForItemUOM(Item."No.", UOM));

        AssemblyHeader.FindSet();
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; DocumentType: Enum "Assembly Document Type"; DocumentNo: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", DocumentType);
        AssemblyLine.SetRange("Document No.", DocumentNo);
        AssemblyLine.FindFirst();
    end;

    local procedure FindPostedAssemblyHeaderNotReversed(var PostedAssemblyHeader: Record "Posted Assembly Header"; SourceAssemblyHeaderNo: Code[20])
    begin
        Clear(PostedAssemblyHeader);
        PostedAssemblyHeader.SetRange("Order No.", SourceAssemblyHeaderNo);
        PostedAssemblyHeader.SetRange(Reversed, false);
        PostedAssemblyHeader.FindFirst();
    end;

    local procedure FindSalesShptLine(SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line")
    begin
        Clear(SalesShptLine);
        SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShptLine.SetRange("Quantity Invoiced", 0);
        SalesShptLine.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyHeader: Record "Assembly Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type::Pick);
        WarehouseActivityLine.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseRequest."Source Document"::"Assembly Consumption");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseActivityLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WarehouseActivityLine.FindFirst();
    end;

    local procedure MockWhseEntry(Item: Record Item; Qty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
        WarehouseEntry."Location Code" := LocationWhite.Code;
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry."Qty. (Base)" := Qty;
        WarehouseEntry."Unit of Measure Code" := Item."Base Unit of Measure";
        WarehouseEntry."Bin Code" := LocationWhite."From-Assembly Bin Code";
        WarehouseEntry.Insert();
    end;

    local procedure AssertMergedAOAfterUndo(var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary; var TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary; var TempPostedAssemblyLine: Record "Posted Assembly Line" temporary)
    var
        FinalAssemblyHeader: Record "Assembly Header";
        FinalAssemblyLine: Record "Assembly Line";
    begin
        // Check header
        Clear(FinalAssemblyHeader);
        FinalAssemblyHeader.Get(TempAssemblyHeader."Document Type", TempAssemblyHeader."No.");
        FinalAssemblyHeader.TestField("Item No.", TempAssemblyHeader."Item No.");
        FinalAssemblyHeader.TestField("Variant Code", TempAssemblyHeader."Variant Code");
        FinalAssemblyHeader.TestField("Location Code", TempAssemblyHeader."Location Code");
        FinalAssemblyHeader.TestField("Bin Code", TempAssemblyHeader."Bin Code");
        FinalAssemblyHeader.TestField("Due Date", TempAssemblyHeader."Due Date");
        FinalAssemblyHeader.TestField("Quantity (Base)", TempAssemblyHeader."Quantity (Base)");
        FinalAssemblyHeader.TestField(
          "Remaining Quantity (Base)", TempAssemblyHeader."Remaining Quantity (Base)" + TempPostedAssemblyHeader."Quantity (Base)");
        FinalAssemblyHeader.TestField(
          "Assembled Quantity (Base)", TempAssemblyHeader."Assembled Quantity (Base)" - TempPostedAssemblyHeader."Quantity (Base)");
        FinalAssemblyHeader.TestField(
          "Quantity to Assemble (Base)", TempAssemblyHeader."Quantity to Assemble (Base)" + TempPostedAssemblyHeader."Quantity (Base)");
        FinalAssemblyHeader.TestField("Unit of Measure Code", TempAssemblyHeader."Unit of Measure Code");
        FinalAssemblyHeader.TestField("Dimension Set ID", TempAssemblyHeader."Dimension Set ID");

        // Check Lines
        TempAssemblyLine.SetRange("Document Type", FinalAssemblyHeader."Document Type");
        TempAssemblyLine.SetRange("Document No.", FinalAssemblyHeader."No.");
        if TempAssemblyLine.FindSet() then
            repeat
                FinalAssemblyLine.Get(TempAssemblyLine."Document Type", TempAssemblyLine."Document No.", TempAssemblyLine."Line No.");
                TempPostedAssemblyLine.Get(TempPostedAssemblyHeader."No.", TempAssemblyLine."Line No.");
                FinalAssemblyLine.TestField("No.", TempAssemblyLine."No.");
                FinalAssemblyLine.TestField("Variant Code", TempAssemblyLine."Variant Code");
                FinalAssemblyLine.TestField("Location Code", TempAssemblyLine."Location Code");
                FinalAssemblyLine.TestField("Bin Code", TempAssemblyLine."Bin Code");
                FinalAssemblyLine.TestField("Quantity (Base)", FinalAssemblyHeader."Quantity (Base)" * FinalAssemblyLine."Quantity per");
                FinalAssemblyLine.TestField(
                  "Consumed Quantity (Base)", TempAssemblyLine."Consumed Quantity (Base)" - TempPostedAssemblyLine."Quantity (Base)");
                FinalAssemblyLine.TestField(
                  "Remaining Quantity (Base)", FinalAssemblyLine."Quantity (Base)" - FinalAssemblyLine."Consumed Quantity (Base)");
                FinalAssemblyLine.TestField("Quantity to Consume (Base)", FinalAssemblyLine."Quantity to Consume (Base)");
                FinalAssemblyLine.TestField(
                  "Quantity per", GetMaxValue(TempAssemblyLine."Quantity per", TempPostedAssemblyLine."Quantity per"));
                FinalAssemblyLine.TestField("Unit of Measure Code", FinalAssemblyLine."Unit of Measure Code");
                FinalAssemblyLine.TestField("Dimension Set ID", TempAssemblyLine."Dimension Set ID");
            until TempAssemblyLine.Next() = 0;
    end;

    local procedure AssertNewAOAfterUndo(var TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary; var TempPostedAssemblyLine: Record "Posted Assembly Line" temporary)
    var
        FinalAssemblyHeader: Record "Assembly Header";
        FinalAssemblyLine: Record "Assembly Line";
    begin
        // Check header
        Clear(FinalAssemblyHeader);
        FinalAssemblyHeader.Get(FinalAssemblyHeader."Document Type"::Order, TempPostedAssemblyHeader."Order No.");
        FinalAssemblyHeader.TestField("Item No.", TempPostedAssemblyHeader."Item No.");
        FinalAssemblyHeader.TestField("Variant Code", TempPostedAssemblyHeader."Variant Code");
        FinalAssemblyHeader.TestField("Location Code", TempPostedAssemblyHeader."Location Code");
        FinalAssemblyHeader.TestField("Bin Code", TempPostedAssemblyHeader."Bin Code");
        FinalAssemblyHeader.TestField("Due Date", TempPostedAssemblyHeader."Due Date");
        FinalAssemblyHeader.TestField(
          "Quantity (Base)",
          TempPostedAssemblyHeader."Quantity (Base)" + GetTotalPostedQuantityBaseHeader(TempPostedAssemblyHeader."Order No."));
        FinalAssemblyHeader.TestField(
          "Remaining Quantity (Base)", FinalAssemblyHeader."Quantity (Base)" - FinalAssemblyHeader."Assembled Quantity (Base)");
        FinalAssemblyHeader.TestField(
          "Assembled Quantity (Base)", GetTotalPostedQuantityBaseHeader(TempPostedAssemblyHeader."Order No."));
        FinalAssemblyHeader.TestField("Quantity to Assemble (Base)", TempPostedAssemblyHeader."Quantity (Base)");
        FinalAssemblyHeader.TestField("Unit of Measure Code", TempPostedAssemblyHeader."Unit of Measure Code");
        FinalAssemblyHeader.TestField("Dimension Set ID", TempPostedAssemblyHeader."Dimension Set ID");

        // Check Lines
        TempPostedAssemblyLine.Reset();
        TempPostedAssemblyLine.SetRange("Document No.", TempPostedAssemblyHeader."No.");
        if TempPostedAssemblyLine.FindSet() then
            repeat
                FinalAssemblyLine.Get(
                  FinalAssemblyLine."Document Type"::Order, TempPostedAssemblyHeader."Order No.", TempPostedAssemblyLine."Line No.");
                FinalAssemblyLine.TestField("No.", TempPostedAssemblyLine."No.");
                FinalAssemblyLine.TestField("Variant Code", TempPostedAssemblyLine."Variant Code");
                FinalAssemblyLine.TestField("Location Code", TempPostedAssemblyLine."Location Code");
                FinalAssemblyLine.TestField("Bin Code", TempPostedAssemblyLine."Bin Code");
                FinalAssemblyLine.TestField(
                  "Quantity (Base)",
                  TempPostedAssemblyLine."Quantity (Base)" +
                  GetTotalPostedQuantityBaseLine(TempPostedAssemblyLine."Order No.", TempPostedAssemblyLine."Line No."));
                FinalAssemblyLine.TestField(
                  "Consumed Quantity (Base)",
                  GetTotalPostedQuantityBaseLine(TempPostedAssemblyLine."Order No.", TempPostedAssemblyLine."Line No."));
                FinalAssemblyLine.TestField("Quantity per", TempPostedAssemblyLine."Quantity per");
                FinalAssemblyLine.TestField(
                  "Remaining Quantity (Base)", FinalAssemblyLine."Quantity (Base)" - FinalAssemblyLine."Consumed Quantity (Base)");
                FinalAssemblyLine.TestField("Quantity to Consume (Base)", TempPostedAssemblyLine."Quantity (Base)");
                FinalAssemblyLine.TestField("Unit of Measure Code", TempPostedAssemblyLine."Unit of Measure Code");
                FinalAssemblyLine.TestField("Dimension Set ID", TempPostedAssemblyLine."Dimension Set ID");
            until TempPostedAssemblyLine.Next() = 0;
    end;

    local procedure AssertReversedDoc(var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary)
    begin
        // Check header few fields - re-get the header first
        PostedAssemblyHeader.Get(PostedAssemblyHeader."No.");
        PostedAssemblyHeader.TestField(Reversed, true); // this should be the only one changed...
        TempPostedAssemblyHeader.TestField("Order No.", PostedAssemblyHeader."Order No.");
        TempPostedAssemblyHeader.TestField("Item No.", PostedAssemblyHeader."Item No.");
        TempPostedAssemblyHeader.TestField("Location Code", PostedAssemblyHeader."Location Code");
        TempPostedAssemblyHeader.TestField("Bin Code", PostedAssemblyHeader."Bin Code");
        TempPostedAssemblyHeader.TestField("Due Date", PostedAssemblyHeader."Due Date");
        TempPostedAssemblyHeader.TestField("Quantity (Base)", PostedAssemblyHeader."Quantity (Base)");
        TempPostedAssemblyHeader.TestField("Cost Amount", PostedAssemblyHeader."Cost Amount");
    end;

    local procedure ProcessWMSPick(var AssemblyHeader: Record "Assembly Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Release and create whse pick
        LibraryAssembly.ReleaseAO(AssemblyHeader);
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);

        // Find the whse pick
        FindWhseActivityLine(WarehouseActivityLine, AssemblyHeader);

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // Register pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterPickWithQtyToHandle(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, AssemblyHeader);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReserveSalesLine(var SalesLine: Record "Sales Line"; FullReservation: Boolean; QtyToReserve: Decimal)
    var
        ReservationManagement: Codeunit "Reservation Management";
    begin
        ReservationManagement.SetReservSource(SalesLine);
        ReservationManagement.AutoReserve(FullReservation, '', SalesLine."Shipment Date",
          Round(QtyToReserve / SalesLine."Qty. per Unit of Measure", 0.00001), QtyToReserve);
        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        i: Integer;
    begin
        ItemTrackingLines.First();
        for i := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
            ItemTrackingLines.Next();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmUpdateNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_UPDATE) > 0, 'Actual:' + GetLastErrorText);
        Reply := false; // Don't change - as test is verifying this option
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCreateMvmt(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_CREATE_INVT_MOVM) > 0, 'Actual:' + GetLastErrorText);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmUndo(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmUndoCount += 1;

        case ConfirmUndoCount of
            1:
                begin
                    Assert.IsTrue(StrPos(Question, MSG_WANT_UNDO) > 0, PadStr('Actual' + Format(ConfirmUndoCount) + ':' + Question + ';Expected:' + MSG_WANT_UNDO, 1024));
                    Reply := false;
                end;
            2:
                begin
                    Assert.IsTrue(StrPos(Question, MSG_WANT_UNDO) > 0, PadStr('Actual' + Format(ConfirmUndoCount) + ':' + Question + ';Expected:' + MSG_WANT_UNDO, 1024));
                    Reply := true;
                end;
            3:
                begin
                    Assert.IsTrue(StrPos(Question, MSG_WANT_RECREATE) > 0, PadStr('Actual' + Format(ConfirmUndoCount) + ':' + Question + ';Expected:' + MSG_WANT_RECREATE, 1024));
                    Reply := true;
                end;
            else begin
                Assert.Fail(PadStr('Actual' + Format(ConfirmUndoCount) + ':' + Question + ';Expected:', 1024));
                Reply := false;
            end;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageActivityCreated(Text: Text[1024])
    begin
        Assert.IsTrue(StrPos(Text, MSG_ACTIVITY_CREATED) > 0, 'Actual:' + GetLastErrorText);
    end;

    local procedure CreateAssemblyListAndOrder(var AssemblyHeader: Record "Assembly Header"; ParentItem: Record Item; ComponentItem: Record Item; OrderQty: Decimal; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        PostInventoryAdjustment(ComponentItem."No.", OrderQty * QtyPer);
        AddComponentToAssemblyList(
          BOMComponent, BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '',
          BOMComponent."Resource Usage Type"::Direct, ComponentItem."Base Unit of Measure", QtyPer);
        CreateAssemblyOrder(AssemblyHeader, ParentItem, '', '', '', WorkDate2, OrderQty);
    end;

    local procedure PostInventoryAdjustment(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoOutputOutboundedBlank()
    var
        Flow: Option PostOutput,ReserveOutput;
    begin
        Initialize();
        TCCannotUndoOutput('', Flow::PostOutput);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoOutputOutboundedBlue()
    var
        Flow: Option PostOutput,ReserveOutput;
    begin
        Initialize();
        TCCannotUndoOutput(LocationBlue.Code, Flow::PostOutput);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoOutputReservedBlank()
    var
        Flow: Option PostOutput,ReserveOutput;
    begin
        Initialize();
        TCCannotUndoOutput('', Flow::ReserveOutput);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoOutputReservedBlue()
    var
        Flow: Option PostOutput,ReserveOutput;
    begin
        Initialize();
        TCCannotUndoOutput(LocationBlue.Code, Flow::ReserveOutput);
    end;

    local procedure TCCannotUndoOutput(LocationCode: Code[10]; Flow: Option PostOutput,ReserveOutput)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));

        // create AO
        OrderQty := LibraryRandom.RandDec(1000, 2);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Exercise - create SalesOrder and post
        CreateSalesOrder(
          SalesHeader, Item."No.", '', OrderQty, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', DueDate), LocationCode);

        case Flow of
            Flow::PostOutput:
                LibrarySales.PostSalesDocument(SalesHeader, true, true);
            Flow::ReserveOutput:
                begin
                    FindSOL(SalesHeader, SalesLine, 1);
                    ReserveSalesLine(SalesLine, true, 1);
                end;
        end;

        // Exercise - undo - can't undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        case Flow of
            Flow::PostOutput:
                LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_REMAINING_QTY);
            Flow::ReserveOutput:
                LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_RESERVED_QTY);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoATOBlank()
    begin
        Initialize();
        TCCannotUndoATO('', LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoATOBlue()
    begin
        Initialize();
        TCCannotUndoATO(LocationBlue.Code, LibraryRandom.RandDec(100, 2));
    end;

    local procedure TCCannotUndoATO(LocationCode: Code[10]; QtyPercentage: Decimal)
    var
        Item: Record Item;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));

        // create AO
        OrderQty := LibraryRandom.RandDec(1000, 2);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);

        // Exercise - create SalesOrder with ATO
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);

        // Make it mix ATO - if percentage < 100
        FindSOL(SalesHeader, SalesLine, 1);
        SalesLine.Validate("Qty. to Assemble to Order", Round((OrderQty * QtyPercentage) / 100, 0.00001));
        SalesLine.Modify(true);

        // Post
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode, '', DueDate,
          Item."Base Unit of Measure", SalesLine."Qty. to Assemble to Order");
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise - undo - can't undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, ATO_MUST_BE_NO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoReversedDocBlank()
    begin
        Initialize();
        TCCannotUndoUndoneDoc('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoReversedDocBlue()
    begin
        Initialize();
        TCCannotUndoUndoneDoc(LocationBlue.Code);
    end;

    local procedure TCCannotUndoUndoneDoc(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));

        // create AO
        OrderQty := LibraryRandom.RandDec(1000, 2);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // Exercise - can't undo the already reversed order
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_REVERSED);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckDocBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::ReversedDocs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckDocBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::ReversedDocs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckDocBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::ReversedDocs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckDocBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::ReversedDocs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckILEsBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::ILEs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckILEsBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::ILEs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckILEsBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::ILEs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckILEsBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::ILEs, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckCapEntriesBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::CapacityEntries, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckCapEntriesBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::CapacityEntries, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckCapEntriesBlank()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::CapacityEntries, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckCapEntriesBlue()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::CapacityEntries, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckDocBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::ReversedDocs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckDocBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::ReversedDocs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckDocBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::ReversedDocs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckDocBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::ReversedDocs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckILEsBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::ILEs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckILEsBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::ILEs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckILEsBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::ILEs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckILEsBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::ILEs, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckCapEntriesBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', true, AssertOption::CapacityEntries, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckCapEntriesBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, true, AssertOption::CapacityEntries, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckCapEntriesBlankATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc('', false, AssertOption::CapacityEntries, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckCapEntriesBlueATO()
    var
        AssertOption: Option ReversedDocs,ILEs,CapacityEntries;
    begin
        Initialize();
        TCUndoCheckDoc(LocationBlue.Code, false, AssertOption::CapacityEntries, true);
    end;

    local procedure TCUndoCheckDoc(LocationCode: Code[10]; FullPosting: Boolean; AssertOption: Option ReversedDocs,ILEs,CapacityEntries; IsATO: Boolean)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempPostedAssemblyLine: Record "Posted Assembly Line" temporary;
        UndoSalesShptLine: Codeunit "Undo Sales Shipment Line";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);

        if IsATO then begin
            CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
            FindSOL(SalesHeader, SalesLine, 1);
            SalesLine.AsmToOrderExists(AssemblyHeader);
        end else
            CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        if FullPosting then begin
            if IsATO then
                LibrarySales.PostSalesDocument(SalesHeader, true, false)
            else
                PostAssemblyOrderQty(AssemblyHeader, OrderQty)
        end else
            if IsATO then begin
                SalesLine.Find();
                SalesLine.Validate("Qty. to Ship", Round(SalesLine."Qty. to Ship" / 2, 0.00001));
                SalesLine.Modify(true);
                LibrarySales.PostSalesDocument(SalesHeader, true, false);
                AssemblyHeader.Find();
            end else
                PostAssemblyOrderQty(AssemblyHeader, OrderQty / 2);

        // Copy docs to temp
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        CopyPostedAOToTemp(PostedAssemblyHeader, TempPostedAssemblyHeader, TempPostedAssemblyLine);
        if not FullPosting then
            CopyAOToTemp(AssemblyHeader, TempAssemblyHeader, TempAssemblyLine);

        // Exercise - undo
        if IsATO then begin
            FindSalesShptLine(SalesLine, SalesShptLine);
            UndoSalesShptLine.SetHideDialog(true);
            UndoSalesShptLine.Run(SalesShptLine);
        end else
            LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // Verify
        case AssertOption of
            // Check reversed docs
            AssertOption::ReversedDocs:
                begin
                    AssertReversedDoc(PostedAssemblyHeader, TempPostedAssemblyHeader);
                    if FullPosting then
                        AssertNewAOAfterUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine)
                    else
                        AssertMergedAOAfterUndo(TempAssemblyHeader, TempAssemblyLine, TempPostedAssemblyHeader, TempPostedAssemblyLine);
                end;
            AssertOption::ILEs:
                begin
                    // Verify ILEs
                    LibraryAssembly.VerifyILEsUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine, false);
                    LibraryAssembly.VerifyILEsUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine, true);
                end;
            AssertOption::CapacityEntries:
                begin
                    // Verify Cap Ledger
                    LibraryAssembly.VerifyCapEntriesUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine, false);
                    LibraryAssembly.VerifyCapEntriesUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine, true);
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoDocNewLineBlank()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc('', ChangeOption::"New Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoDocNewLineBlue()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationBlue.Code, ChangeOption::"New Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoDocDeletedLineBlank()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc('', ChangeOption::"Delete Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoDocDeletedLineBlue()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationBlue.Code, ChangeOption::"Delete Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoNewLocationLinesBlank()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc('', ChangeOption::"Change Location Lines");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoNewLocationLinesBlue()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationBlue.Code, ChangeOption::"Change Location Lines");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoNewBinLinesSilver()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationSilver.Code, ChangeOption::"Change Bin Lines");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateNo')]
    [Scope('OnPrem')]
    procedure CannotUndoNewLocationBlank()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc('', ChangeOption::"Change Location");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateNo')]
    [Scope('OnPrem')]
    procedure CannotUndoNewLocationBlue()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationBlue.Code, ChangeOption::"Change Location");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotUndoNewBinSilver()
    var
        ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines";
    begin
        Initialize();
        TCCannotUndoChangedDoc(LocationSilver.Code, ChangeOption::"Change Bin");
    end;

    local procedure TCCannotUndoChangedDoc(LocationCode: Code[10]; ChangeOption: Option "New Line","Delete Line","Change Location","Change Bin","Change Location Lines","Change Bin Lines")
    var
        Item: Record Item;
        Location: Record Location;
        NewItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        HeaderBin: Record Bin;
        ComponentsBin: Record Bin;
        BinSilver1: Record Bin;
        BinSilver2: Record Bin;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
        BinIndex: Integer;
    begin
        // Get bins
        BinIndex := 1;
        if LocationCode <> '' then begin
            Location.Get(LocationCode);
            LibraryWarehouse.FindBin(HeaderBin, LocationCode, '', BinIndex + 2);
            LibraryWarehouse.FindBin(ComponentsBin, LocationCode, '', BinIndex);
        end;

        LibraryWarehouse.FindBin(BinSilver1, LocationSilver.Code, '', BinIndex + 2);
        LibraryWarehouse.FindBin(BinSilver2, LocationSilver.Code, '', BinIndex + 1);

        // Create AO item
        LibraryInventory.CreateItem(NewItem);
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);

        // Create AO and add enough inventory for comp
        if (LocationCode <> '') and Location."Bin Mandatory" then begin
            CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, HeaderBin.Code, '', DueDate, OrderQty);
            SetLocAndBinCodeOnAsmLines(AssemblyHeader, ComponentsBin);
            LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, ComponentsBin.Code);
        end else begin
            CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);
            LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        end;

        // Post partial
        PostAssemblyOrderQty(AssemblyHeader, OrderQty / 2);
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.ReopenAO(AssemblyHeader);

        // Change the initial AO
        case ChangeOption of
            ChangeOption::"New Line":
                LibraryAssembly.CreateAssemblyLine(
                  AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, NewItem."No.", NewItem."Base Unit of Measure",
                  LibraryRandom.RandDec(1000, 2), 0, NewItem.Description);
            ChangeOption::"Delete Line":
                LibraryAssembly.DeleteAssemblyLine("BOM Component Type"::Item, AssemblyHeader."No.");
            ChangeOption::"Change Location Lines": // Assumes current function is called with Location <> Location Silver as param
                SetLocAndBinCodeOnAsmLines(AssemblyHeader, BinSilver1);
            ChangeOption::"Change Bin Lines": // Assumes current function is called with Location Silver as param
                SetLocAndBinCodeOnAsmLines(AssemblyHeader, BinSilver1);
            ChangeOption::"Change Location": // Assumes current function is called with Location <> Location Silver as param
                begin
                    AssemblyHeader.Validate("Location Code", LocationSilver.Code);
                    AssemblyHeader.Modify(true);
                end;
            ChangeOption::"Change Bin": // Assumes current function is called with Location Silver as param
                begin
                    AssemblyHeader.Validate("Bin Code", BinSilver2.Code);
                    AssemblyHeader.Modify(true);
                end;
        end;

        // Undo - error
        if ChangeOption in [ChangeOption::"New Line", ChangeOption::"Delete Line"] then
            LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_CANNOT_RESTORE_2)
        else
            LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_CANNOT_RESTORE);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoCheckCommentsBlank()
    begin
        Initialize();
        TCUndoCheckComments('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoCheckCommentsBlue()
    begin
        Initialize();
        TCUndoCheckComments(LocationBlue.Code);
    end;

    local procedure TCUndoCheckComments(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);
        AddCommentsToOrder(AssemblyHeader);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // Exercise - verify comments
        LibraryAssembly.VerifyComments(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoCheckDimensionsBlank()
    begin
        Initialize();
        TCUndoCheckDimensions('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoCheckDimensionsBlue()
    begin
        Initialize();
        TCUndoCheckDimensions(LocationBlue.Code);
    end;

    local procedure TCUndoCheckDimensions(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblySetup: Record "Assembly Setup";
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // Exercise - verify dimensions
        LibraryAssembly.CheckOrderDimensions(AssemblyHeader, AssemblySetup."Copy Component Dimensions from"::"Order Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoMultipleCheckDocBlank()
    begin
        Initialize();
        TCUndoMultipleCheckDoc('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoMultipleCheckDocBlue()
    begin
        Initialize();
        TCUndoMultipleCheckDoc(LocationBlue.Code);
    end;

    local procedure TCUndoMultipleCheckDoc(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempPostedAssemblyLine: Record "Posted Assembly Line" temporary;
        OrderQty: Decimal;
        DueDate: Date;
        i: Integer;
    begin
        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post 4 times
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');

        // Post full in 4 partial postings
        for i := 1 to 4 do
            PostAssemblyOrderQty(AssemblyHeader, OrderQty / 4);

        // Undo and verify
        for i := 1 to 4 do begin
            // Copy docs to temp
            FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
            CopyPostedAOToTemp(PostedAssemblyHeader, TempPostedAssemblyHeader, TempPostedAssemblyLine);
            if i > 1 then begin
                AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeader."No.");
                CopyAOToTemp(AssemblyHeader, TempAssemblyHeader, TempAssemblyLine);
            end;

            // Exercise - undo
            LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

            // Verify
            AssertReversedDoc(PostedAssemblyHeader, TempPostedAssemblyHeader);
            if i = 1 then
                AssertNewAOAfterUndo(TempPostedAssemblyHeader, TempPostedAssemblyLine)
            else
                AssertMergedAOAfterUndo(TempAssemblyHeader, TempAssemblyLine, TempPostedAssemblyHeader, TempPostedAssemblyLine);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoDontCreateAOBlank()
    begin
        Initialize();
        TCUndoDontCreateAO('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoDontCreateAOBlue()
    begin
        Initialize();
        TCUndoDontCreateAO(LocationBlue.Code);
    end;

    local procedure TCUndoDontCreateAO(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Exercise - undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, false, '');

        // Verify - order should not be created
        asserterror AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckWhseEntriesSilver()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationSilver, true, AssertOption::WhseEntries);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckBinContentsSilver()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationSilver, true, AssertOption::BinContents);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoChecWhseEntriesSilver()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationSilver, false, AssertOption::WhseEntries);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckBinContentsSilver()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationSilver, false, AssertOption::BinContents);
    end;

    [Test]
    [HandlerFunctions('MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckWhseEntriesWhite()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationWhite, true, AssertOption::WhseEntries);
    end;

    [Test]
    [HandlerFunctions('MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure PostFullUndoCheckBinContentsWhite()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationWhite, true, AssertOption::BinContents);
    end;

    [Test]
    [HandlerFunctions('MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure PostPartialUndoChecWhseEntriesWhite()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationWhite, false, AssertOption::WhseEntries);
    end;

    [Test]
    [HandlerFunctions('MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure PostPartialUndoCheckBinContentsWhite()
    var
        AssertOption: Option WhseEntries,BinContents;
    begin
        Initialize();
        TCUndoCheckWhse(LocationWhite, false, AssertOption::BinContents);
    end;

    local procedure TCUndoCheckWhse(Location: Record Location; FullPosting: Boolean; AssertOption: Option WhseEntries,BinContents)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        HeaderBin: Record Bin;
        ComponentsBin: Record Bin;
        OrderQty: Decimal;
        BinIndex: Integer;
    begin
        // Get Bin codes
        BinIndex := 1;

        if not Location."Directed Put-away and Pick" then begin// if not Full WMS
            LibraryWarehouse.FindBin(HeaderBin, Location.Code, '', BinIndex);
            LibraryWarehouse.FindBin(ComponentsBin, Location.Code, '', BinIndex + 1);
        end else begin
            HeaderBin.Get(Location.Code, Location."From-Production Bin Code");
            LibraryWarehouse.FindBin(ComponentsBin, Location.Code, 'PICK', BinIndex);
        end;

        // Create AO
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        CreateAssemblyOrderWithInventory(AssemblyHeader, Item, OrderQty, Location.Code, HeaderBin.Code, ComponentsBin.Code);

        // If Full WMS - process whse pick, else set bin on the lines to point where the inventory exists
        if not Location."Directed Put-away and Pick" then
            SetLocAndBinCodeOnAsmLines(AssemblyHeader, ComponentsBin)
        else
            ProcessWMSPick(AssemblyHeader);

        // Copy to temp & post AO
        if FullPosting then begin
            CopyAOToTemp(AssemblyHeader, TempAssemblyHeader, TempAssemblyLine);
            PostAssemblyOrderQty(AssemblyHeader, OrderQty);
        end else begin
            PostAssemblyOrderQty(AssemblyHeader, OrderQty / 2);
            CopyAOToTemp(AssemblyHeader, TempAssemblyHeader, TempAssemblyLine);
        end;

        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");

        // Exercise - undo
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, false, '');

        // Verify
        case AssertOption of
            AssertOption::WhseEntries:
                begin
                    LibraryAssembly.VerifyWarehouseEntries(TempAssemblyHeader, TempAssemblyLine, false);
                    LibraryAssembly.VerifyWarehouseEntries(TempAssemblyHeader, TempAssemblyLine, true);
                end;
            AssertOption::BinContents:
                LibraryAssembly.VerifyBinContents(TempAssemblyHeader, TempAssemblyLine, 0);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmCreateMvmt,MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure CannotUndoWhseEntryNotAvailSilverPick()
    begin
        Initialize();
        TCCannotUndoWhseEntryNotAvail(LocationSilverWithPick.Code);
    end;

    local procedure TCCannotUndoWhseEntryNotAvail(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        InternalMovementHeader: Record "Internal Movement Header";
        HeaderBin: Record Bin;
        ComponentsBin: Record Bin;
        OtherBin: Record Bin;
        OrderQty: Decimal;
        DueDate: Date;
        BinIndex: Integer;
    begin
        // Bin codes
        BinIndex := 1;
        LibraryWarehouse.FindBin(HeaderBin, LocationCode, '', BinIndex + 2);
        LibraryWarehouse.FindBin(ComponentsBin, LocationCode, '', BinIndex);
        LibraryWarehouse.FindBin(OtherBin, LocationCode, '', BinIndex + 3);

        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, HeaderBin.Code, '', DueDate, OrderQty);
        SetLocAndBinCodeOnAsmLines(AssemblyHeader, ComponentsBin);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, ComponentsBin.Code);
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");

        // Create invt movm for the output
        CreateInternalMovementGetBin(InternalMovementHeader, Item."No.", LocationCode, OtherBin.Code, HeaderBin.Code);
        LibraryWarehouse.SetQtyToHandleInternalMovement(InternalMovementHeader, OrderQty);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify Undo - error - output "reserved"
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, MSG_INSUFFICIENT_QTY);
    end;

    [Test]
    [HandlerFunctions('ConfirmUndo')]
    [Scope('OnPrem')]
    procedure UndoWithQuestion()
    var
        Item: Record Item;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        // run undo through codeunit 911 for codecoverage
        Initialize();

        // Create AO
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        OrderQty := LibraryRandom.RandDec(1000, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationBlue.Code, '', '', DueDate, OrderQty);
        AddCommentsToOrder(AssemblyHeader);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationBlue.Code, '');
        PostAssemblyOrderQty(AssemblyHeader, OrderQty);

        // Undo
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", PostedAssemblyHeader); // First time the answer is "no" for conform dialog
        CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", PostedAssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('MessageActivityCreated')]
    [Scope('OnPrem')]
    procedure UndoPartiallyPostedAssemblyOrder()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        HeaderBin: Record Bin;
        ComponentsBin: Record Bin;
        BinType: Record "Bin Type";
        Zone: Record Zone;
        OrderQty: array[3] of Decimal;
    begin
        // [FEATURE] [Undo Assembly] [Warehouse]
        // [SCENARIO 378211] It should be possible to Undo partially Posted Assembly Order if it has Quantity less then in previous posted Assembly Order
        Initialize();

        // [GIVEN] Released Assembly Order "A" with Quantity = "Q"
        OrderQty[3] := LibraryRandom.RandIntInRange(1, 10);
        OrderQty[2] := LibraryRandom.RandIntInRange(11, 100);
        OrderQty[1] := OrderQty[2] + OrderQty[3];

        HeaderBin.Get(LocationWhite.Code, LocationWhite."From-Assembly Bin Code");
        BinType.Get(LibraryWarehouse.SelectBinType(false, false, false, true));
        LibraryWarehouse.CreateZone(Zone, '', LocationWhite.Code, BinType.Code, '', '', 1, false);
        LibraryWarehouse.CreateBin(ComponentsBin, LocationWhite.Code, '', Zone.Code, BinType.Code);
        CreateAssemblyOrderWithInventory(AssemblyHeader, Item, OrderQty[1], LocationWhite.Code, HeaderBin.Code, ComponentsBin.Code);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [GIVEN] Post Assembly Order "A" with Quantity to Assemble = "Q1"
        AssemblyHeader.Validate("Quantity to Assemble", OrderQty[2]);
        AssemblyHeader.Modify(true);
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, true, false);
        RegisterPickWithQtyToHandle(AssemblyHeader, OrderQty[2]);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Post Assembly Order "A" with Quantity to Assemble = "Q2", "Q2" < "Q1"
        AssemblyHeader.Find();
        RegisterPickWithQtyToHandle(AssemblyHeader, OrderQty[3]);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        MockWhseEntry(Item, -OrderQty[2]);

        // [WHEN] Undo Assembly "A2"
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindLast();
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [THEN] Assembly Order A2 is Undone
        PostedAssemblyHeader.Find();
        PostedAssemblyHeader.TestField(Reversed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoPartiallyPostedAsmOrderVerifyCostAmount()
    var
        AsmItem: Record Item;
        ComponentItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        QtyToAssemble: Decimal;
        OrderQty: Decimal;
    begin
        // [FEATURE] [Recreate Assembly Order] [Unit Cost]
        // [SCENARIO 278686] "Cost Amount" in assembly line should be recalculated when undoing a posted assembly order with "Recreate" option

        Initialize();

        QtyToAssemble := LibraryRandom.RandDecInRange(10, 20, 2);
        OrderQty := QtyToAssemble + LibraryRandom.RandDecInRange(30, 50, 2);

        // [GIVEN] Assembled item "ASM" and a component item "COMP" with unit cost = 100
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate("Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        ComponentItem.Modify(true);

        // [GIVEN] Assembly order for 10 pcs of item "ASM". Set "Quantity to Assemble" = 6
        CreateAssemblyListAndOrder(AssemblyHeader, AsmItem, ComponentItem, OrderQty, 1);
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);

        // [GIVEN] Post output of 6 pcs
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeader.Find();

        // [GIVEN] Post output of remaining 4 pcs
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] Undo the first posted assembly order (Quantity = 6) and choose to recreate the assembly order
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [THEN] Cost amount in the assembly line is recalculated according to total order quantity: "Unit Cost" = 10, "Cost Amount" = 100
        FindAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyLine.TestField("Unit Cost", ComponentItem."Unit Cost");
        AssemblyLine.TestField("Cost Amount", OrderQty * ComponentItem."Unit Cost");
    end;

    [Test]
    procedure ExistingExpirationDateForLotWhenUndoAssemblyWithItemTracking()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
        InventoryQty: Decimal;
        AssemblyQty: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 451161] The program must look for newest expiration date for a lot when undoing assembly order with item tracking.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        InventoryQty := LibraryRandom.RandIntInRange(11, 20);
        AssemblyQty := LibraryRandom.RandInt(10);

        // [GIVEN] Assembled item "A", component item "C".
        // [GIVEN] Component "C" is a lot-tracked item with mandatory expiration date.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(CompItem, ItemTrackingCode);
        AddComponentToAssemblyList(
          BOMComponent, "BOM Component Type"::Item, CompItem."No.", AsmItem."No.", '', 0, CompItem."Base Unit of Measure", 1);

        // [GIVEN] Post 10 qty. of item "C" to inventory, set lot no. = "L" and expiration date = "WorkDate".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', InventoryQty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("Expiration Date", WorkDate2);
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Assembly order for 1 qty., select lot no. "L" for assembly line.
        // [GIVEN] Post the assembly order.
        CreateAssemblyOrder(AssemblyHeader, AsmItem, '', '', '', WorkDate2, AssemblyQty);
        FindAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNo, AssemblyLine.Quantity);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Change expiration date for remaining inventory of component "C" from "WorkDate" to "WorkDate() + 1 day" using reclassification journal.
        Clear(ItemJournalLine);
        CreateItemReclassificationJournalLine(ItemJournalLine, CompItem."No.", InventoryQty - AssemblyQty);
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("New Lot No.", LotNo);
        ReservationEntry.Validate("New Expiration Date", WorkDate2 + 1);
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Undo the assembly order.
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [THEN] Expiration date on item entry for undone component consumption = "WorkDate() + 1 day".
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField("Expiration Date", WorkDate2 + 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure ItemTrackingLinesForFullyPostedAndUndoneAssembly()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        LotNos: array[2] of Code[50];
        InventoryQty: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 441849] Show proper values on Item Tracking Lines page after assembly order has been posted, undone, and the reservation has been deleted.
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        InventoryQty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Assembly item; lot-tracked component item.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryItemTracking.CreateLotItem(CompItem);
        AddComponentToAssemblyList(
          BOMComponent, "BOM Component Type"::Item, CompItem."No.", AsmItem."No.", '', 0, CompItem."Base Unit of Measure", 1);

        // [GIVEN] Post two lots "L1" and "L2" of the component item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', InventoryQty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[1], InventoryQty / 2);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[2], InventoryQty / 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Assembly order for 11 pcs - lot "L1" for 5 pcs, lot "L2" for 6 pcs.
        // [GIVEN] Post the assembly order.
        CreateAssemblyOrder(AssemblyHeader, AsmItem, '', '', '', WorkDate2, 11); // odd number so that the quantity will be distributed by lots unequally.
        FindAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNos[1], 5);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNos[2], 6);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Undo the posted assembly and restore the original order.
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [GIVEN] Check that item tracking lines have been recreated correctly and delete them.
        AssemblyHeader.Find();
        FindAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        ReservationEntry.SetSourceFilter(
          Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.", true);
        ReservationEntry.CalcSums("Quantity (Base)");
        ReservationEntry.TestField("Quantity (Base)", -AssemblyLine."Quantity (Base)");
        ReservationEntry.DeleteAll(true);

        // [WHEN] Open item tracking page for the assembly line.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(0);
        AssemblyLine.OpenItemTrackingLines();

        // [THEN] The item tracking lines page is empty.
        // Verification is done in ItemTrackingLinesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure ItemTrackingLinesForPartiallyPostedAndUndoneAssembly()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        LotNos: array[2] of Code[50];
        InventoryQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Partial Posting]
        // [SCENARIO 441849] Show proper values on Item Tracking Lines page after assembly order has been partially posted and undone.
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        InventoryQty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Assembly item; lot-tracked component item.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryItemTracking.CreateLotItem(CompItem);
        AddComponentToAssemblyList(
          BOMComponent, "BOM Component Type"::Item, CompItem."No.", AsmItem."No.", '', 0, CompItem."Base Unit of Measure", 1);

        // [GIVEN] Post two lots "L1" and "L2" of the component item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', InventoryQty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[1], InventoryQty / 2);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[2], InventoryQty / 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Assembly order for 11 pcs, set "Quantity to Assemble " = 5.
        // [GIVEN] Select lot "L1": Quantity = 5 pcs, Qty. to Handle = 2 pcs.
        // [GIVEN] Select lot "L2": Quantity = 6 pcs, Qty. to Handle = 3 pcs.
        // [GIVEN] Partially post the assembly order.
        CreateAssemblyOrder(AssemblyHeader, AsmItem, '', '', '', WorkDate2, 11); // odd number so that the quantity will be distributed by lots unequally.
        AssemblyHeader.Validate("Quantity to Assemble", 5);
        AssemblyHeader.Modify(true);
        FindAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNos[1], 5);
        ReservationEntry.Validate("Qty. to Handle (Base)", -2);
        ReservationEntry.Modify(true);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNos[2], 6);
        ReservationEntry.Validate("Qty. to Handle (Base)", -3);
        ReservationEntry.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Undo the assembly order.
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [WHEN] Open item tracking lines for the assembly line.
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(5);
        LibraryVariableStorage.Enqueue(LotNos[2]);
        LibraryVariableStorage.Enqueue(6);
        AssemblyLine.OpenItemTrackingLines();

        // [THEN] Item tracking has been restored properly - 5 pcs of lot "L1" and 6 pcs of lot "L2".
        // Verification is done in ItemTrackingLinesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;
}

