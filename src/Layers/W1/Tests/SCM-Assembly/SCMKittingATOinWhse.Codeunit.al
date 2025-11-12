// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Assembly.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.BOM;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;

codeunit 137102 "SCM Kitting ATO in Whse"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        GenProdPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        isInitialized: Boolean;
        WorkDate2: Date;
        AdditionalBinCode1: Code[20];
        AdditionalBinCode2: Code[20];
        DefaultBinCode: Code[20];
        NotDefaultBinCode: Code[20];
        FromBinCode: Code[20];
        InvBinCode: Code[20];
        ToBinCode: Code[20];
        AsmShipBinCode: Code[20];
        ConfirmStatusChangeCount: Integer;
        CHANGE_LOC_CONFIRM: Label 'Do you want to update the Location Code on the lines?';
        ERR_QTY_BASE: Label ' units are not available';
        ERR_ATO_QTY_TO_ASM: Label 'Quantity to Assemble cannot be lower than %1 or higher than %2.';
        ERR_ATS_QTY_TO_ASM: Label 'Quantity to Assemble cannot be higher than the Remaining Quantity, which is %1.';
        TXT_EXPCTD_ACTUAL: Label 'Expected: %1, Actual: %2.';
        MSG_STATUS_WILL_BE_CHANGED: Label 'The status of the linked assembly order will be changed to ';
        ERR_UPDATE_INTERRUPTED: Label 'The update has been interrupted to respect the warning.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting ATO in Whse");
        ConfirmStatusChangeCount := 0;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting ATO in Whse");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        GlobalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting ATO in Whse");
    end;

    local procedure GlobalSetup()
    begin
        SetupAssembly();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        SetupInventorySetup();
        SetupSalesAndReceivablesSetup();
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
        SetupLocation(Location);
    end;

    [Normal]
    local procedure SetupAssembly()
    var
        AssemblySetup: Record "Assembly Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Assembly Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Blanket Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Default Location for Orders", '');
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure SetupLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        Clear(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        AdditionalBinCode1 := 'A1Bin';
        AdditionalBinCode2 := 'A2Bin';
        DefaultBinCode := 'DefBin';
        NotDefaultBinCode := 'NotDefBin';
        FromBinCode := 'FromBin';
        InvBinCode := 'InvBin';
        ToBinCode := 'ToBin';
        AsmShipBinCode := 'AsmShip';
        LibraryWarehouse.CreateBin(Bin, Location.Code, AdditionalBinCode1, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, AdditionalBinCode2, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, DefaultBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, NotDefaultBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, FromBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, ToBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, InvBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, AsmShipBinCode, '', '');
    end;

    local procedure UpdateLocation(var Location: Record Location; SetBinMandatory: Boolean; TestFromBinCode: Code[20]; TestAsmShipBinCode: Code[20])
    begin
        if SetBinMandatory <> Location."Bin Mandatory" then begin
            // Skip validate trigger for bin mandatory to improve performance.
            Location."Bin Mandatory" := SetBinMandatory;
            Location.Modify(true);
        end;

        if TestFromBinCode <> Location."From-Assembly Bin Code" then begin
            Location.Validate("From-Assembly Bin Code", TestFromBinCode);
            Location.Modify(true);
        end;

        if TestAsmShipBinCode <> Location."Asm.-to-Order Shpt. Bin Code" then begin
            Location.Validate("Asm.-to-Order Shpt. Bin Code", TestAsmShipBinCode);
            Location.Modify(true);
        end;
    end;

    local procedure ClearJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure SetupInventorySetup()
    begin
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
    end;

    local procedure SetupSalesAndReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    [Normal]
    local procedure CreateAssemblyList(ParentItem: Record Item; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Integer)
    var
        Item: Record Item;
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        CompCount: Integer;
    begin
        // Add components - qty per is increasing same as no of components
        for CompCount := 1 to NoOfComponents do begin
            Clear(Item);
            LibraryInventory.CreateItem(Item);
            AddComponentToAssemblyList(
              BOMComponent, BOMComponent.Type::Item, Item."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Item."Base Unit of Measure", QtyPer);
        end;

        // Add resources - qty per is increasing same as no of components
        for CompCount := 1 to NoOfResources do begin
            LibraryAssembly.CreateResource(Resource, true, GenProdPostingGr);
            AddComponentToAssemblyList(
              BOMComponent, BOMComponent.Type::Resource, Resource."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Resource."Base Unit of Measure", QtyPer);
        end;

        // Add simple text
        for CompCount := 1 to NoOfTexts do
            AddComponentToAssemblyList(BOMComponent, BOMComponent.Type::" ", '', ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, '', QtyPer);
    end;

    local procedure CreateAssembledItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
        CreateAssemblyList(Item, LibraryRandom.RandInt(5), 1, 1, LibraryRandom.RandInt(1000));
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo1: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; var SalesLine1: Record "Sales Line"; var SalesLine2: Record "Sales Line"; SalesQty: Integer)
    var
        ShipmentDate: Date;
    begin
        ShipmentDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemNo1, ShipmentDate, SalesQty);
        if ItemNo2 <> '' then
            LibrarySales.CreateSalesLineWithShipmentDate(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo2, ShipmentDate, SalesQty);
    end;

    [Normal]
    local procedure CreateItemJournalLine(Item: Record Item; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Posting Date", CalcDate('<-1D>', WorkDate()));
        ItemJournalLine.Validate("Document Date", CalcDate('<-1D>', ItemJournalLine."Posting Date"));
        ItemJournalLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(50, 2));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", InvBinCode);
        ItemJournalLine.Modify(true);
    end;

    [Normal]
    local procedure CreateDefaultBinContent(Item: Record Item)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', DefaultBinCode, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', NotDefaultBinCode, Item."No.", '', Item."Base Unit of Measure");
    end;

    [Normal]
    local procedure CreatePurchOrderDropShipment(var PurchaseHeader: Record "Purchase Header"; SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, SalesLine."Sell-to Customer No.");
        CreatePurchLineFromSalesLine(PurchaseLine, SalesLine, PurchaseHeader."No.");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Cost (LCY)"), PurchaseLine."Unit Cost (LCY)");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Purchase Order No."), PurchaseLine."Document No.");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Purch. Order Line No."), PurchaseLine."Line No.");
    end;

    [Normal]
    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    [Normal]
    local procedure CreatePurchLineFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.Validate("Document No.", DocumentNo);
        CopyDocumentMgt.TransfldsFromSalesToPurchLine(SalesLine, PurchaseLine);
        PurchaseLine.Validate("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.Validate("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.Validate("Drop Shipment", true);
        PurchaseLine.Insert(true);
    end;

    [Normal]
    local procedure AddComponentToAssemblyList(var BOMComponent: Record "BOM Component"; ComponentType: Enum "BOM Component Type"; ComponentNo: Code[20]; ParentItemNo: Code[20]; VariantCode: Code[10]; ResourceUsage: Option; UOM: Code[10]; QuantityPer: Decimal)
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, ComponentType, ComponentNo, QuantityPer, UOM);
        if ComponentType = BOMComponent.Type::Resource then
            BOMComponent.Validate("Resource Usage Type", ResourceUsage);
        BOMComponent.Validate("Variant Code", VariantCode);
        if ComponentNo = '' then
            BOMComponent.Validate(Description,
              LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);
    end;

    [Normal]
    local procedure AddComponentsToInventory(SalesLine: Record "Sales Line")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        if AssemblyLine.FindSet() then
            repeat
                AssemblyLine.Validate("Bin Code", 'ToBin');
                AssemblyLine.Modify(true);
            until AssemblyLine.Next() = 0;

        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);
    end;

    [Normal]
    local procedure AddInventoryNonDirectLocation(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Integer; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure AddItemsInventory(Item1: Record Item; Item2: Record Item; Qty: Decimal)
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);

        CreateItemJournalLine(Item1, Qty);
        CreateItemJournalLine(Item2, Qty);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CHANGE_LOC_CONFIRM) > 0, PadStr('Actual:' + Question + '; Expected:' + CHANGE_LOC_CONFIRM, 1024));
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler2(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmStatusChangeCount += 1;

        Assert.IsTrue(StrPos(Question, MSG_STATUS_WILL_BE_CHANGED) > 0, PadStr('Actual:' + Question + '; Expected:' + MSG_STATUS_WILL_BE_CHANGED, 1024));
        if ConfirmStatusChangeCount = 1 then
            Reply := false
        else
            Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReserveAgainstILE(var ReservationPage: TestPage Reservation)
    var
        EntrySummary: Record "Entry Summary";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        EntrySummary.Init();
        ReservationPage.First();
        if ReservationPage."Summary Type".Value =
           CopyStr(ItemLedgEntry.TableCaption(), 1, MaxStrLen(EntrySummary."Summary Type"))
        then
            ReservationPage."Reserve from Current Line".Invoke();
    end;

    [Normal]
    local procedure CheckCreatedBin(BinMandatory: Boolean; TestFromBinCode: Code[20]; TestAsmShipBinCode: Code[20]; ExpBinCode: Code[20]; ExpBinCodeBC: Code[20]; AddInventory: Boolean; Qty: Integer)
    var
        Item1: Record Item;
        ItemBC: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLineBC: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
        AssemblyHeaderBC: Record "Assembly Header";
    begin
        UpdateLocation(Location, BinMandatory, TestFromBinCode, TestAsmShipBinCode);

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItem(ItemBC, ItemBC."Assembly Policy"::"Assemble-to-Order");
        CreateDefaultBinContent(ItemBC);

        if AddInventory and (Qty > 0) then
            AddItemsInventory(Item1, ItemBC, Qty);

        CreateSalesOrder(SalesHeader, Item1."No.", ItemBC."No.", Location.Code, SalesLine1, SalesLineBC, Qty);
        if Qty > 0 then begin
            Assert.IsTrue(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');
            Assert.IsTrue(SalesLineBC.AsmToOrderExists(AssemblyHeaderBC), 'There is no asm order');
            AssertBinCode(AssemblyHeader1."Bin Code", SalesLine1."Bin Code", ExpBinCode);
            AssertBinCode(AssemblyHeaderBC."Bin Code", SalesLineBC."Bin Code", ExpBinCodeBC)
        end else begin
            Assert.IsFalse(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is an asm order');
            Assert.IsFalse(SalesLineBC.AsmToOrderExists(AssemblyHeaderBC), 'There is an asm order');

            Assert.AreEqual(ExpBinCode, SalesLine1."Bin Code", 'Incorrect sales bin code');
            Assert.AreEqual(ExpBinCodeBC, SalesLineBC."Bin Code", 'Incorrect sales bin code');
        end;
    end;

    [Normal]
    local procedure CheckUpdatedBin(NewBinCode: Code[20]; NewBinCodeBC: Code[20]; ShipPartially: Boolean)
    var
        Item1: Record Item;
        ItemBC: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLineBC: Record "Sales Line";
    begin
        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItem(ItemBC, ItemBC."Assembly Policy"::"Assemble-to-Order");
        CreateDefaultBinContent(ItemBC);

        CreateSalesOrder(SalesHeader, Item1."No.", ItemBC."No.", Location.Code, SalesLine1, SalesLineBC, LibraryRandom.RandInt(1000));
        if ShipPartially then begin
            AddComponentsToInventory(SalesLine1);
            AddComponentsToInventory(SalesLineBC);
            SalesLine1.Validate("Qty. to Ship", SalesLine1."Qty. to Ship" / 2);
            SalesLine1.Modify(true);
            SalesLineBC.Validate("Qty. to Ship", SalesLineBC."Qty. to Ship" / 2);
            SalesLineBC.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        CheckUpdatedBinLine(SalesLine1, SalesLineBC, NewBinCode, NewBinCode, FromBinCode);
        CheckUpdatedBinLine(SalesLineBC, SalesLine1, NewBinCodeBC, NewBinCodeBC, NewBinCode);
    end;

    [Normal]
    local procedure CheckUpdatedLocationLine(SalesLineM: Record "Sales Line"; SalesLineNM: Record "Sales Line"; NewLocationCode: Code[10]; BinCodeM: Code[20]; BinCodeNM: Code[20])
    var
        AssemblyHeaderM: Record "Assembly Header";
        AssemblyHeaderNM: Record "Assembly Header";
    begin
        SalesLineM.Validate("Location Code", NewLocationCode);
        SalesLineM.Modify(true);
        SalesLineNM.Get(SalesLineNM."Document Type", SalesLineNM."Document No.", SalesLineNM."Line No.");

        Assert.IsTrue(SalesLineM.AsmToOrderExists(AssemblyHeaderM), 'There is no asm order');
        Assert.IsTrue(SalesLineNM.AsmToOrderExists(AssemblyHeaderNM), 'There is no asm order');
        AssertBinCode(AssemblyHeaderM."Bin Code", SalesLineM."Bin Code", BinCodeM);
        AssertBinCode(AssemblyHeaderNM."Bin Code", SalesLineNM."Bin Code", BinCodeNM);
    end;

    [Normal]
    local procedure CheckUpdatedBinLine(SalesLineM: Record "Sales Line"; SalesLineNM: Record "Sales Line"; NewBinCode: Code[20]; BinCodeM: Code[20]; BinCodeNM: Code[20])
    var
        AssemblyHeaderM: Record "Assembly Header";
        AssemblyHeaderNM: Record "Assembly Header";
    begin
        SalesLineM.Get(SalesLineM."Document Type", SalesLineM."Document No.", SalesLineM."Line No.");
        SalesLineM.Validate("Bin Code", NewBinCode);
        SalesLineM.Modify(true);
        SalesLineNM.Get(SalesLineNM."Document Type", SalesLineNM."Document No.", SalesLineNM."Line No.");

        Assert.IsTrue(SalesLineM.AsmToOrderExists(AssemblyHeaderM), 'There is no asm order');
        Assert.IsTrue(SalesLineNM.AsmToOrderExists(AssemblyHeaderNM), 'There is no asm order');
        AssertBinCode(AssemblyHeaderM."Bin Code", SalesLineM."Bin Code", BinCodeM);
        AssertBinCode(AssemblyHeaderNM."Bin Code", SalesLineNM."Bin Code", BinCodeNM);
    end;

    [Normal]
    local procedure AssertBinCode(AssemblyBinCode: Code[20]; SalesBinCode: Code[20]; ExpectedBinCode: Code[20])
    begin
        Assert.AreEqual(ExpectedBinCode, SalesBinCode, 'Incorrect sales bin code');
        Assert.AreEqual(ExpectedBinCode, AssemblyBinCode, 'Incorrect assembly bin code');
    end;

    local procedure VerifyBinContent(LocationCode: Code[20]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Reset();
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        if BinContent.FindFirst() then begin
            BinContent.CalcFields(Quantity);
            BinContent.TestField(Quantity, Quantity);
        end else
            Assert.AreEqual(0, Quantity, 'Incorrect Qty of Item ' + ItemNo + ' in Bin ' + BinCode);
    end;

    [Normal]
    local procedure VerifyBinContents(AssemblyHeader: Record "Assembly Header"; AssembledQty: Integer; CompQty: Integer; VerifyComponents: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        // Veryfy bin content for header assembly item
        VerifyBinContent(AssemblyHeader."Location Code", FromBinCode, AssemblyHeader."Item No.", AssembledQty);

        if VerifyComponents then begin
            // Verify bin contents for components
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
            AssemblyLine.FindSet();

            repeat
                VerifyBinContent(
                  AssemblyLine."Location Code", AssemblyLine."Bin Code", AssemblyLine."No.", CompQty * AssemblyLine."Quantity per");
            until AssemblyLine.Next() = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBM()
    begin
        Initialize();

        CheckCreatedBin(true, '', '', '', DefaultBinCode, false, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMLFA()
    begin
        Initialize();

        CheckCreatedBin(true, FromBinCode, '', FromBinCode, FromBinCode, false, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBin()
    begin
        Initialize();

        CheckCreatedBin(false, '', '', '', '', false, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMAddInv()
    begin
        Initialize();

        CheckCreatedBin(true, '', '', InvBinCode, DefaultBinCode, true, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMLFAAddInv()
    begin
        Initialize();

        CheckCreatedBin(true, FromBinCode, '', FromBinCode, FromBinCode, true, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMNoQty()
    begin
        Initialize();

        CheckCreatedBin(true, '', '', '', DefaultBinCode, false, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinNoQty()
    begin
        Initialize();

        CheckCreatedBin(false, '', '', '', '', false, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMS()
    begin
        Initialize();

        CheckCreatedBin(true, '', AsmShipBinCode, AsmShipBinCode, AsmShipBinCode, false, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMLFAS()
    begin
        Initialize();

        CheckCreatedBin(true, FromBinCode, AsmShipBinCode, AsmShipBinCode, AsmShipBinCode, false, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMAddInvS()
    begin
        Initialize();

        CheckCreatedBin(true, '', AsmShipBinCode, AsmShipBinCode, AsmShipBinCode, true, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMLFAAddInvS()
    begin
        Initialize();

        CheckCreatedBin(true, FromBinCode, AsmShipBinCode, AsmShipBinCode, AsmShipBinCode, true, LibraryRandom.RandInt(1000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyBinBMNoQtyS()
    begin
        Initialize();

        CheckCreatedBin(true, '', AsmShipBinCode, AsmShipBinCode, AsmShipBinCode, false, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyMixedATS()
    var
        Item1: Record Item;
        ItemBC: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLineBC: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
        AssemblyHeaderBC: Record "Assembly Header";
        Qty: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, AsmShipBinCode);
        Qty := LibraryRandom.RandInt(1000);

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItem(ItemBC, ItemBC."Assembly Policy"::"Assemble-to-Order");
        CreateDefaultBinContent(ItemBC);

        AddInventoryNonDirectLocation(Item1."No.", Location.Code, Qty, AdditionalBinCode1);
        AddInventoryNonDirectLocation(ItemBC."No.", Location.Code, Qty, AdditionalBinCode1);

        CreateSalesOrder(SalesHeader, Item1."No.", ItemBC."No.", Location.Code, SalesLine1, SalesLineBC, Qty);

        Assert.IsTrue(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');
        Assert.IsTrue(SalesLineBC.AsmToOrderExists(AssemblyHeaderBC), 'There is no asm order');
        AssertBinCode(AssemblyHeader1."Bin Code", SalesLine1."Bin Code", AsmShipBinCode);
        AssertBinCode(AssemblyHeaderBC."Bin Code", SalesLineBC."Bin Code", AsmShipBinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseCopyMixedATSZeroATO()
    var
        Item1: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
        Qty: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, AsmShipBinCode);
        Qty := LibraryRandom.RandInt(1000);

        CreateAssembledItem(Item1, "Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item1."No.", Location.Code, Qty, AdditionalBinCode1);

        CreateSalesOrder(SalesHeader, Item1."No.", '', Location.Code, SalesLine1, SalesLine1, Qty);

        SalesLine1.Validate("Qty. to Assemble to Order", 0);

        Assert.IsFalse(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');
        Assert.AreEqual(AsmShipBinCode, SalesLine1."Bin Code", 'Incorrect sales bin code');

        SalesLine1.Validate("Bin Code", AdditionalBinCode1);
        SalesLine1.Modify(true);
        SalesLine1.Get(SalesLine1."Document Type", SalesLine1."Document No.", SalesLine1."Line No.");

        Assert.AreEqual(AdditionalBinCode1, SalesLine1."Bin Code", 'Incorrect sales bin code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSWhseCopyMixedATO()
    var
        Item1: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
        Qty: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, AsmShipBinCode);
        Qty := LibraryRandom.RandInt(1000);

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Stock");
        AddInventoryNonDirectLocation(Item1."No.", Location.Code, Qty, AdditionalBinCode1);

        CreateSalesOrder(SalesHeader, Item1."No.", '', Location.Code, SalesLine1, SalesLine1, Qty);

        Assert.IsFalse(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is an asm order');
        Assert.AreEqual(AdditionalBinCode1, SalesLine1."Bin Code", 'Incorrect sales bin code');

        SalesLine1.Validate("Qty. to Assemble to Order", Qty);

        Assert.IsTrue(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');
        AssertBinCode(AssemblyHeader1."Bin Code", SalesLine1."Bin Code", AsmShipBinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseUpdBinBM()
    begin
        Initialize();

        CheckUpdatedBin(AdditionalBinCode1, AdditionalBinCode2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseUpdBinBMPartShipped()
    begin
        Initialize();

        CheckUpdatedBin(AdditionalBinCode1, AdditionalBinCode2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseDelBinBM()
    begin
        Initialize();

        CheckUpdatedBin('', '', false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ATOWhseUpdLocBMLFA()
    var
        Item1: Record Item;
        ItemBC: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLineBC: Record "Sales Line";
        NewLocation: Record Location;
    begin
        Initialize();
        UpdateLocation(Location, true, FromBinCode, '');
        SetupLocation(NewLocation);
        UpdateLocation(NewLocation, true, AdditionalBinCode2, '');

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItem(ItemBC, ItemBC."Assembly Policy"::"Assemble-to-Order");
        CreateDefaultBinContent(ItemBC);

        CreateSalesOrder(SalesHeader, Item1."No.", ItemBC."No.", Location.Code, SalesLine1, SalesLineBC, LibraryRandom.RandInt(1000));

        CheckUpdatedLocationLine(SalesLine1, SalesLineBC, NewLocation.Code, AdditionalBinCode2, FromBinCode);
        CheckUpdatedLocationLine(SalesLineBC, SalesLine1, NewLocation.Code, AdditionalBinCode2, AdditionalBinCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseUpdLocToSameBMLFA()
    var
        Item1: Record Item;
        ItemBC: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLineBC: Record "Sales Line";
    begin
        Initialize();
        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItem(ItemBC, ItemBC."Assembly Policy"::"Assemble-to-Order");
        CreateDefaultBinContent(ItemBC);

        CreateSalesOrder(SalesHeader, Item1."No.", ItemBC."No.", Location.Code, SalesLine1, SalesLineBC, LibraryRandom.RandInt(1000));

        CheckUpdatedLocationLine(SalesLine1, SalesLineBC, Location.Code, FromBinCode, FromBinCode);
        CheckUpdatedLocationLine(SalesLineBC, SalesLine1, Location.Code, FromBinCode, FromBinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseEditAsmHeaderBinBMLFA()
    var
        Item1: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
    begin
        Initialize();
        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item1."No.", '', Location.Code, SalesLine1, SalesLine1, LibraryRandom.RandInt(1000));
        Assert.IsTrue(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');

        asserterror AssemblyHeader1.Validate("Bin Code", AdditionalBinCode1);
        Assert.ExpectedTestFieldError(AssemblyHeader1.FieldCaption("Assemble to Order"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOWhseEditAsmHeaderLocBMLFA()
    var
        Item1: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        AssemblyHeader1: Record "Assembly Header";
        NewLocation: Record Location;
    begin
        Initialize();
        UpdateLocation(Location, true, FromBinCode, '');
        SetupLocation(NewLocation);
        UpdateLocation(NewLocation, true, AdditionalBinCode2, '');

        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item1."No.", '', Location.Code, SalesLine1, SalesLine1, LibraryRandom.RandInt(1000));
        Assert.IsTrue(SalesLine1.AsmToOrderExists(AssemblyHeader1), 'There is no asm order');

        asserterror AssemblyHeader1.Validate("Location Code", NewLocation.Code);
        Assert.ExpectedTestFieldError(AssemblyHeader1.FieldCaption("Assemble to Order"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToShip()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToShip: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        NewQtyToShip := 10;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, Qty, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to ship".
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        // Verify Assembly order "Quantity to Assemble"
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.AreEqual(NewQtyToShip, AssemblyHeader."Quantity to Assemble", 'Qty to Assemble is updated incorrecly');
        Assert.AreEqual(Qty, AssemblyHeader.Quantity, 'Quantity is updated');

        // Verify posting
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyBinContents(AssemblyHeader, Qty, Qty - NewQtyToShip, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipZeroSOQtyToAssemble()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to Assemble to Order" to zero
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Modify(true);

        // Verify Assembly order "Quantity to Assemble"
        Assert.IsFalse(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is an asm order');
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship", 'Quantity is updated');

        // Verify posting
        AddInventoryNonDirectLocation(Item."No.", Location.Code, Qty, FromBinCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipZeroAOQtyToAssemble()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AsmOrder: TestPage "Assembly Order";
        Qty: Integer;
        ActualError: Text[1024];
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, Qty, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        // Change Assembly Order "Quantity to Assemble" to zero
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        AsmOrder.Trap();
        PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);

        asserterror AsmOrder."Quantity to Assemble".SetValue(0);
        ActualError := AsmOrder."Quantity to Assemble".GetValidationError(1);
        Assert.IsTrue(
          StrPos(ActualError, StrSubstNo(ERR_ATO_QTY_TO_ASM, Qty, Qty)) > 0,
          PadStr(StrSubstNo(TXT_EXPCTD_ACTUAL, StrSubstNo(ERR_ATO_QTY_TO_ASM, Qty, Qty), ActualError), 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToShipQtyToAssemble()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToShip: Integer;
        QtyFromStock: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');

        Qty := LibraryRandom.RandIntInRange(100, 1000);
        NewQtyToShip := Round(Qty / 2);
        QtyFromStock := 10;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to Ship" and then Sales Order "Qty. to Assemble to Order"
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToShip - QtyFromStock);
        SalesLine.Modify(true);

        // Verify Assembly Order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.AreEqual(NewQtyToShip - QtyFromStock, AssemblyHeader."Quantity to Assemble", 'Qty to Assemble is updated incorrecly');
        Assert.AreEqual(NewQtyToShip - QtyFromStock, AssemblyHeader.Quantity, 'Quantity is updated incorrectly');

        // Verify posting
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, 0, 0, true);

        // Verify Sales Order and Assembly Order after posting
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(
          NewQtyToShip - QtyFromStock, SalesLine."Qty. to Assemble to Order", 'Qty. to Assemble to Order is updated incorrecly');
        Assert.AreEqual(Qty - NewQtyToShip, SalesLine."Qty. to Ship", 'Qty to Assemble is updated incorrecly');
        Assert.AreEqual(NewQtyToShip - QtyFromStock, AssemblyHeader.Quantity, 'Quantity is updated');
        Assert.AreEqual(0, AssemblyHeader."Quantity to Assemble", 'Qty to Assemble is updated incorrecly after posting');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipSOMaxQtyToShip()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AsmOrder: TestPage "Assembly Order";
        Qty: Integer;
        NewQtyToShip: Integer;
        ActualError: Text[1024];
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        NewQtyToShip := 10;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        AsmOrder.Trap();
        PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);

        asserterror AsmOrder."Quantity to Assemble".SetValue(NewQtyToShip + 1);
        ActualError := AsmOrder."Quantity to Assemble".GetValidationError(1);
        Assert.IsTrue(
          StrPos(ActualError, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToShip, NewQtyToShip)) > 0,
          PadStr(StrSubstNo(TXT_EXPCTD_ACTUAL, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToShip, NewQtyToShip), ActualError), 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipSOMaxRemQty()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AsmOrder: TestPage "Assembly Order";
        Qty: Integer;
        ActualError: Text[1024];
    begin
        // Maximum value of "Quantity to Assemble" = Minimum {SalesLine."Qty. to Ship", AsmHeader."Remaining Quantity"}
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, Qty, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        SalesLine.Validate("Qty. to Assemble to Order", 90);
        SalesLine.Modify(true);

        AddComponentsToInventory(SalesLine);

        AsmOrder.Trap();
        PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);

        asserterror AsmOrder."Quantity to Assemble".SetValue(SalesLine."Qty. to Assemble to Order" + 1);
        ActualError := AsmOrder."Quantity to Assemble".GetValidationError(1);
        Assert.IsTrue(
          StrPos(ActualError, StrSubstNo(ERR_ATS_QTY_TO_ASM, SalesLine."Qty. to Assemble to Order")) > 0,
          PadStr(StrSubstNo(TXT_EXPCTD_ACTUAL, StrSubstNo(ERR_ATS_QTY_TO_ASM, SalesLine."Qty. to Assemble to Order"), ActualError), 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipSOMin()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AsmOrder: TestPage "Assembly Order";
        Qty: Integer;
        NewQtyToShip: Integer;
        QtyOnStock: Integer;
        ActualError: Text[1024];
    begin
        // Minimum value of "Quantity to Assemble" = Maximum {0, SalesLine."Quantity to Ship" - UnshippedNonATOQty}
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        QtyOnStock := 50;
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyOnStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        NewQtyToShip := QtyOnStock + 10;
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        AsmOrder.Trap();
        PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);

        asserterror AsmOrder."Quantity to Assemble".SetValue(NewQtyToShip - QtyOnStock - 1);
        ActualError := AsmOrder."Quantity to Assemble".GetValidationError(1);
        Assert.IsTrue(
          StrPos(ActualError, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToShip, NewQtyToShip)) > 0,
          PadStr(StrSubstNo(TXT_EXPCTD_ACTUAL, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToShip, NewQtyToShip), ActualError), 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToAssemble()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        QtyFromStock: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        QtyFromStock := 10;
        NewQtyToAsmSO := Qty - QtyFromStock;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to Assemble to Order"
        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Modify(true);

        // Verify Assembly Order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader."Quantity to Assemble", 'Qty to Assemble is updated incorrecly');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated incorrectly');

        // Verify posting
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToAssembleQtyToShipM()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        QtyFromStock: Integer;
        NewQtyToShip: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        QtyFromStock := 10;
        NewQtyToAsmSO := Qty - QtyFromStock;
        NewQtyToShip := NewQtyToAsmSO - 30;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to Assemble to Order" and then Sales order "Qty. to ship"
        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        // Verify Assembly order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.AreEqual(NewQtyToShip, AssemblyHeader."Quantity to Assemble", 'Quantity to Assemble is updated incorrecly');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated incorrectly');

        // Verify posting
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, QtyFromStock, NewQtyToAsmSO - NewQtyToShip, true);

        // Verify Sales and Assembly order after posting
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(
          NewQtyToAsmSO, SalesLine."Qty. to Assemble to Order", 'Qty. to Assemble to Order is updated incorrecly after posting');
        Assert.AreEqual(Qty - NewQtyToShip, SalesLine."Qty. to Ship", 'Qty to Ship is updated incorrecly after posting');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated');
        Assert.AreEqual(
          NewQtyToAsmSO - NewQtyToShip, AssemblyHeader."Quantity to Assemble", 'Quantity to Assemble is updated incorrecly after posting');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToAssembleQtyToShipP()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        QtyFromStock: Integer;
        NewQtyToShip: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        QtyFromStock := 10;
        NewQtyToAsmSO := Qty - QtyFromStock;
        NewQtyToShip := NewQtyToAsmSO + 3;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Change Sales Order "Qty. to Assemble to Order" and then Sales order "Qty. to ship"
        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        // Verify Assembly order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader."Quantity to Assemble", 'Quantity to Assemble is updated incorrecly');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated incorrectly');

        // Verify posting
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, Qty - NewQtyToShip, 0, true);

        // Verify Sales and Assembly order after posting
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(
          NewQtyToAsmSO, SalesLine."Qty. to Assemble to Order", 'Qty. to Assemble to Order is updated incorrecly after posting');
        Assert.AreEqual(Qty - NewQtyToShip, SalesLine."Qty. to Ship", 'Qty to Ship is updated incorrecly after posting');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated');
        Assert.AreEqual(0, AssemblyHeader."Quantity to Assemble", 'Quantity to Assemble is updated incorrecly after posting');
    end;

    [Test]
    [HandlerFunctions('AutoReserveAgainstILE')]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToAssembleQtyToShipZero()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        QtyFromStock: Integer;
        NewQtyToShip: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        QtyFromStock := 10;
        NewQtyToAsmSO := Qty - QtyFromStock;
        NewQtyToShip := QtyFromStock;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        // Change Sales Order "Qty. to Assemble to Order" and then Sales order "Qty. to ship"
        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        // Verify Assembly order
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        AssemblyHeader.Validate("Quantity to Assemble", 0);
        AssemblyHeader.Modify(true);

        SalesLine.ShowReservation(); // reserve the rest of qty on sales against ILE: Bug 273866
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify posting
        VerifyBinContents(AssemblyHeader, 0, 0, true);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(NewQtyToAsmSO, SalesLine."Qty. to Assemble to Order", 'Qty. to Assemble to Order is updated incorrecly');
        Assert.AreEqual(Qty - NewQtyToShip, SalesLine."Qty. to Ship", 'Qty to Ship is updated incorrecly');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader."Quantity to Assemble", 'Qty to Assemble is updated incorrecly after posting');

        // Post rest of the order
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('AutoReserveAgainstILE')]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipChangeSOQtyToAssembleQtyToShipAO()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        NewQtyToAssembleAO: Integer;
        QtyFromStock: Integer;
        NewQtyToShip: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        QtyFromStock := 10;
        NewQtyToAsmSO := Qty - QtyFromStock;
        NewQtyToShip := QtyFromStock + 1;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);

        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        NewQtyToAssembleAO := 1;
        AssemblyHeader.Validate("Quantity to Assemble", NewQtyToAssembleAO);
        AssemblyHeader.Modify(true);

        SalesLine.ShowReservation(); // reserve the rest of qty on sales against ILE: Bug 273866

        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, 0, NewQtyToAsmSO - NewQtyToAssembleAO, true);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(NewQtyToAsmSO, SalesLine."Qty. to Assemble to Order", 'Qty. to Assemble to Order is updated incorrecly');
        Assert.AreEqual(Qty - NewQtyToShip, SalesLine."Qty. to Ship", 'Qty to Ship is updated incorrecly');
        Assert.AreEqual(NewQtyToAsmSO, AssemblyHeader.Quantity, 'Quantity is updated');
        Assert.AreEqual(
          NewQtyToAsmSO - NewQtyToAssembleAO, AssemblyHeader."Quantity to Assemble",
          'Qty to Assemble is updated incorrecly after posting');

        // Post rest of the order
        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyBinContents(AssemblyHeader, 0, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipNegativeInv()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
        QtyFromStock: Integer;
        NewQtyToShip: Integer;
        ErrMsg: Text[1024];
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        QtyFromStock := 10;
        NewQtyToAsmSO := 22;
        NewQtyToShip := NewQtyToAsmSO + QtyFromStock + 37;

        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, FromBinCode);

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);

        AddComponentsToInventory(SalesLine);
        ErrMsg := Format(NewQtyToShip - QtyFromStock - NewQtyToAsmSO) + ERR_QTY_BASE;
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrMsg) > 0, PadStr('Actual:' + GetLastErrorText + ';Expected:' + ErrMsg, 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToAsmQtyToShipFull()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Qty: Integer;
        NewQtyToAsmSO: Integer;
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');
        Qty := LibraryRandom.RandIntInRange(100, 1000);
        NewQtyToAsmSO := Qty - 10;

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, Qty);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        SalesLine.Validate("Qty. to Assemble to Order", NewQtyToAsmSO);
        SalesLine.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        asserterror AssemblyHeader.Validate("Quantity to Assemble", NewQtyToAsmSO - 1);
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToAsmSO, NewQtyToAsmSO)) > 0,
          PadStr(StrSubstNo(TXT_EXPCTD_ACTUAL, StrSubstNo(ERR_ATO_QTY_TO_ASM, NewQtyToAsmSO, NewQtyToAsmSO), GetLastErrorText), 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODropShipment1()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, LibraryRandom.RandIntInRange(100, 1000));
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        AddInventoryNonDirectLocation(Item."No.", Location.Code, SalesLine.Quantity, FromBinCode);

        asserterror
        begin
            Commit();
            SalesLine.Validate("Drop Shipment", true);
        end;
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Qty. to Asm. to Order (Base)"), Format(0));

        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODropShipment2()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");

        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, LibraryRandom.RandIntInRange(100, 1000));
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        AddInventoryNonDirectLocation(Item."No.", Location.Code, SalesLine.Quantity, FromBinCode);

        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Modify(true);

        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        CreatePurchOrderDropShipment(PurchaseHeader, SalesLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure ATOReopenQuestion()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();

        UpdateLocation(Location, true, FromBinCode, '');

        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, LibraryRandom.RandIntInRange(100, 1000));
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');
        AddInventoryNonDirectLocation(Item."No.", Location.Code, SalesLine.Quantity, FromBinCode);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        asserterror
        begin
            Commit();
            SalesLine.Find(); // To retrieve the latest record.
            SalesLine.Validate("Qty. to Assemble to Order", 10);
        end;
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_UPDATE_INTERRUPTED) > 0, PadStr('Actual: ' + GetLastErrorText + ';Expected: ' + ERR_UPDATE_INTERRUPTED, 1024));

        SalesLine.Validate("Qty. to Assemble to Order", 10); // second time in confirm dialog reply is yes
        SalesLine.Modify(true);

        AddComponentsToInventory(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;
}

