// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.TestLibraries.Utilities;
using System.Environment.Configuration;

codeunit 137914 "SCM Whse.-Asm. To Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Assembly] [Assembly to Order]
        Initialized := false;
    end;

    var
        FirstNumber: Label '137914-001';
        InventorySetup: Record "Inventory Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        ERR_ATS_QTY_TO_ASM: Label 'Quantity to Assemble cannot be higher than the Remaining Quantity, which is %1.';
        ERR_ATO_QTY_TO_ASM: Label 'Quantity to Assemble cannot be lower than %1 or higher than %2.';
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Initialized: Boolean;
        TXT_ASSEMBLY_EXISTS: Label 'Assembly exists.';
        TXT_CHECKING: Label 'Checking %1.';
        BasicWhseBinType: Option " ",BinX,BinAsm;
        MSG_INVTPICK_CREATED: Label 'Number of Invt. Pick activities created: %1 out of a total of %2.';
        MSG_INVTMVMT_CREATED: Label 'Number of Invt. Movement activities created: %1 out of a total of %2.';
        TXT_EXPECTED_ACTUAL: Label 'Expected: %1; Actual: %2';
        ERR_INVTPICK_EXISTS: Label 'One or more Invt. Pick lines exist for the Order.';
        MSG_PICK_ACTIVITY: Label 'Pick activity no.';
        MSG_GENERIC_CREATED: Label 'has been created.';
        ERR_WHSESHPT_EXISTS: Label 'A Warehouse Shipment Line exists for the Order.';
        ERR_QTY_TO_ASM_CANT_BE_CHANGED: Label 'Qty. to Assemble to Order must not be changed when a Warehouse Shipment Line for this Sales Line exists';
        ParentItemSN1: Label 'ParSN1';
        ParentItemSN2: Label 'ParSN2';
        ParentItemSN3: Label 'ParSN3';
        ParentItemSN4: Label 'ParSN4';
        ParentItemSN5: Label 'ParSN5';
        ChildItemSN1: Label 'ChilSN1';
        ChildItemSN2: Label 'ChilSN2';
        ChildItemSN3: Label 'ChilSN3';
        ERR_NO_WHSE_WKSH_LINES_CREATED: Label 'There are no Warehouse Worksheet Lines created.';
        ERR_NOTHING_TO_HANDLE: Label 'There is nothing to handle, because the worksheet lines do not contain a value for quantity to handle.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Whse.-Asm. To Order");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Whse.-Asm. To Order");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        Initialized := true;
        LibraryPatterns.SetNoSeries();
        InventorySetup.Get();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Whse.-Asm. To Order");
    end;

    [Test]
    [HandlerFunctions('AutoReserveAgainstILE')]
    [Scope('OnPrem')]
    procedure RelationOfQtyToAsmToQtyToShipForPartATO()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        Bin: Record Bin;
    begin
        Initialize();
        MockATOItem(Item, ChildItem);
        MockLocation(Location, false, false);

        // Create sales line for mix ATO
        Bin.Init();
        AddItemToInventory(Item, Location, Bin, 3, '', ''); // add inventory of 3 PCS of Parent
        AddItemToInventory(ChildItem, Location, Bin, 7, '', ''); // add inventory of 7 PCS of Child
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        PostponeShptDateforAssemblyLeadTime(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Qty. to Assemble to Order", 7);
        SalesLine.Modify();
        SalesLine.ShowReservation(); // reserve the rest of qty on sales against ILE: Bug 273866
        Assert.IsTrue(SalesLine.AsmToOrderExists(AsmHeader), TXT_ASSEMBLY_EXISTS);

        Assert.AreEqual(10, SalesLine."Qty. to Ship", StrSubstNo(TXT_CHECKING, SalesLine.FieldCaption("Qty. to Ship")));
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 10, 7, 7);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 9, 7, 6);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 8, 7, 5);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 7, 7, 4);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 6, 7, 3);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 5, 5, 2);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 4, 4, 1);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 3, 3, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 2, 2, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 1, 1, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 0, 0, 0);

        // Ship only 1 PCS of item from stock
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify();
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        AsmHeader.Validate("Quantity to Assemble", 0);
        AsmHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        Assert.AreEqual(9, SalesLine."Qty. to Ship", StrSubstNo(TXT_CHECKING, SalesLine.FieldCaption("Qty. to Ship")));
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 9, 7, 7);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 8, 7, 6);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 7, 7, 5);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 6, 6, 4);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 5, 5, 3);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 4, 4, 2);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 3, 3, 1);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 2, 2, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 1, 1, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 0, 0, 0);

        // Ship only 1 PCS of item from assembly
        SalesLine.Validate("Qty. to Ship", 1); // should auto-fill the Qty to asm to 1.
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        Assert.AreEqual(8, SalesLine."Qty. to Ship", StrSubstNo(TXT_CHECKING, SalesLine.FieldCaption("Qty. to Ship")));
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 8, 6, 6);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 7, 6, 5);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 6, 6, 4);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 5, 5, 3);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 4, 4, 2);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 3, 3, 1);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 2, 2, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 1, 1, 0);
        RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(SalesLine, AsmHeader, 0, 0, 0);
    end;

    local procedure RelationOfQtyToAsmToQtyToShipForPartATO_CheckMaxMin(var SalesLine: Record "Sales Line"; AsmHeader: Record "Assembly Header"; QtyToShip: Decimal; MaxQtyToAsm: Decimal; MinQtyToAsm: Decimal)
    var
        QtyToAsm: Decimal;
    begin
        if QtyToShip <> SalesLine."Qty. to Ship" then begin
            SalesLine.Validate("Qty. to Ship", QtyToShip);
            SalesLine.Modify();
        end;
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        if QtyToShip < AsmHeader."Quantity to Assemble" then
            QtyToAsm := QtyToShip
        else
            QtyToAsm := AsmHeader."Quantity to Assemble";
        if MaxQtyToAsm > QtyToShip then
            MaxQtyToAsm := QtyToShip;
        Assert.AreEqual(
          QtyToAsm, AsmHeader."Quantity to Assemble", StrSubstNo(TXT_CHECKING, AsmHeader.FieldCaption("Quantity to Assemble")));
        if MinQtyToAsm > 0 then
            RelationOfQtyToAsmToQtyToShipForPartATO_SetQtyToAsmOnAsmOrder(AsmHeader, MinQtyToAsm - 1, MinQtyToAsm, MaxQtyToAsm);
        RelationOfQtyToAsmToQtyToShipForPartATO_SetQtyToAsmOnAsmOrder(AsmHeader, MaxQtyToAsm + 1, MinQtyToAsm, MaxQtyToAsm);
    end;

    local procedure RelationOfQtyToAsmToQtyToShipForPartATO_SetQtyToAsmOnAsmOrder(AsmHeader: Record "Assembly Header"; NewQtyToAsm: Decimal; MinQty: Decimal; MaxQty: Decimal)
    begin
        Commit();
        asserterror AsmHeader.Validate("Quantity to Assemble", NewQtyToAsm);
        if NewQtyToAsm > AsmHeader."Remaining Quantity" then
            Assert.IsTrue(
              StrPos(GetLastErrorText, StrSubstNo(ERR_ATS_QTY_TO_ASM, MaxQty)) > 0,
              StrSubstNo(TXT_CHECKING, AsmHeader.FieldCaption("Quantity to Assemble")))
        else
            Assert.IsTrue(
              StrPos(GetLastErrorText, StrSubstNo(ERR_ATO_QTY_TO_ASM, MinQty, MaxQty)) > 0,
              StrSubstNo(TXT_CHECKING, AsmHeader.FieldCaption("Quantity to Assemble")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF262634()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AsmSetup: Record "Assembly Setup";
        AsmLine: Record "Assembly Line";
        NewQtyToConsume: Decimal;
    begin
        Initialize();
        MockLocation(Location, false, false);
        MockATOItem(ParentItem, ChildItem);
        // no inventory for child item added to trigger error later on.
        AsmSetup.Get();
        AsmSetup."Stockout Warning" := false;
        AsmSetup.Modify();

        MockATOAsmOrder(AsmHeader, ParentItem, Location, SalesLine, 1);

        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.SetRange(Type, AsmLine.Type::Item);
        AsmLine.SetRange("No.", ChildItem."No.");
        AsmLine.FindFirst();
        NewQtyToConsume := AsmLine."Quantity to Consume" + 1;
        AsmLine."Quantity to Consume" := NewQtyToConsume; // change Qty to consume
        AsmLine.Modify();

        LibraryAssembly.ReleaseAO(AsmHeader); // release Asm order

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false); // try to ship sales but it will fail with components unavailability

        // verify that Asm order is still released.
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        Assert.AreEqual(AsmHeader.Status::Released, AsmHeader.Status, StrSubstNo(TXT_CHECKING, AsmHeader.FieldCaption(Status)));

        // verify that the Qty to consume is still what was set before.
        AsmLine.Get(AsmLine."Document Type", AsmLine."Document No.", AsmLine."Line No.");
        Assert.AreEqual(
          NewQtyToConsume, AsmLine."Quantity to Consume", StrSubstNo(TXT_CHECKING, AsmLine.FieldCaption("Quantity to Consume")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF262676()
    var
        Location: Record Location;
        ParentItem: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        MockLocation(Location, false, false);
        MockATOItem(ParentItem, ChildItem);
        Bin.Init();
        AddItemToInventory(ChildItem, Location, Bin, 10, '', ''); // place enough components in the inventory.

        MockATOAsmOrder(AsmHeader, ParentItem, Location, SalesLine, 1);

        // change Qty to consume = 0 for all lines
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.ModifyAll("Quantity to Consume", 0);

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Commit();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // try to ship sales but it will fail with nothing to post
        // verify that "Qty consumed" on asm lines = 0
        Assert.AreEqual(1, AsmLine.Count, '');
        if AsmLine.FindSet() then
            repeat
                Assert.AreEqual(0, AsmLine."Consumed Quantity", StrSubstNo(TXT_CHECKING, AsmLine.FieldCaption("Consumed Quantity")));
            until AsmLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_DefaultBinCodeCopiedFromSalesToAsmOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, false);
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);

        // create sales line
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange(Default, true);
        BinContent.FindFirst();
        BinMandatory_Verify(SalesLine, false, Location.Code, BinContent."Bin Code");
        SalesLine.Validate(Quantity, 1); // any quantity
        BinMandatory_Verify(SalesLine, true, Location.Code, BinContent."Bin Code");

        // change bin code to another value
        MockBin(Bin, Location.Code);
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        SalesLine.Validate("Bin Code", Bin.Code);
        BinMandatory_Verify(SalesLine, true, Location.Code, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_AsmShptBinCodeCopiedFromSalesToAsmOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ChildItem: Record Item;
        ShipmentBin: Record Bin;
        FromAsmBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);

        // make first bin as Assembly Shipment bin & second as From-Assembly Bin
        ShipmentBin.SetRange("Location Code", Location.Code);
        ShipmentBin.FindFirst();
        Location.Validate("Asm.-to-Order Shpt. Bin Code", ShipmentBin.Code);
        MockBin(FromAsmBin, Location.Code);
        Location.Validate("From-Assembly Bin Code", FromAsmBin.Code);
        Location.Modify();

        // create a sales order for item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        PostponeShptDateforAssemblyLeadTime(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("Location Code", Location.Code);
        BinMandatory_Verify(SalesLine, false, Location.Code, ShipmentBin.Code);
        SalesLine.Validate(Quantity, 1); // any quantity
        BinMandatory_Verify(SalesLine, true, Location.Code, ShipmentBin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_FromAsmBinCodeCopiedFromSalesToAsmOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);

        // make first bin as From-Assembly bin
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        Location.Validate("From-Assembly Bin Code", Bin.Code);
        Location.Modify();

        // create a sales order for item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        PostponeShptDateforAssemblyLeadTime(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("Location Code", Location.Code);
        BinMandatory_Verify(SalesLine, false, Location.Code, Bin.Code);
        SalesLine.Validate(Quantity, 1); // any quantity
        BinMandatory_Verify(SalesLine, true, Location.Code, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_ChangingBinCodeOnAsmOrderRaisesError()
    var
        AsmHeader: Record "Assembly Header";
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);
        MockATOAsmOrder(AsmHeader, Item, Location, SalesLine, 1);

        // Try to change the Bin Code to raise error
        MockBin(Bin, Location.Code);
        asserterror AsmHeader.Validate("Bin Code", Bin.Code);
        Assert.ExpectedTestFieldError(AsmHeader.FieldCaption("Assemble to Order"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_ChangeItem()
    var
        AsmHeader: Record "Assembly Header";
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        NewItem: Record Item;
        NewBin: Record Bin;
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);
        MockATOAsmOrder(AsmHeader, Item, Location, SalesLine, 1);

        // make new item with default bin and set it on sales line
        MockATOItem(NewItem, ChildItem);
        MockBin(NewBin, Location.Code);
        MockBinContent(NewItem, Location, NewBin, '', true);
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Validate("No.", NewItem."No.");
        BinMandatory_Verify(SalesLine, true, Location.Code, NewBin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_ChangeLocation()
    var
        AsmHeader: Record "Assembly Header";
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        NewLocation: Record Location;
        NewBin: Record Bin;
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);
        MockATOAsmOrder(AsmHeader, Item, Location, SalesLine, 1);

        // make new location with default bin and set it on sales line
        MockLocation(NewLocation, true, false);
        MockBin(NewBin, NewLocation.Code);
        MockBinContent(Item, NewLocation, NewBin, '', true);
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Validate("Location Code", NewLocation.Code);
        BinMandatory_Verify(SalesLine, true, NewLocation.Code, NewBin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_ChangeVariant()
    var
        AsmHeader: Record "Assembly Header";
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        NewBin: Record Bin;
    begin
        Initialize();
        MockLocation(Location, true, false);
        MockATOItem(Item, ChildItem);
        MockATOAsmOrder(AsmHeader, Item, Location, SalesLine, 1);

        // make new location with default bin and set it on sales line
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        MockBin(NewBin, Location.Code);
        MockBinContent(Item, Location, NewBin, ItemVariant.Code, true);
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        BinMandatory_Verify(SalesLine, true, Location.Code, NewBin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinMandatory_BinCodeChangedWhenATSSalesLineChangedToATO()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        SalesLine: Record "Sales Line";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        Initialize();
        MockATSItem(Item, ChildItem);

        // make an ATS sales line
        MockLocation(Location, true, false);
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        MockBin(Bin, Location.Code);
        Location."Asm.-to-Order Shpt. Bin Code" := Bin.Code;
        Location.Modify();
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange(Default, true);
        BinContent.FindFirst();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        BinMandatory_Verify(SalesLine, false, Location.Code, BinContent."Bin Code");

        // change sales line to ATO
        SalesLine.Validate("Qty. to Assemble to Order", 1);
        BinMandatory_Verify(SalesLine, true, Location.Code, Location."Asm.-to-Order Shpt. Bin Code");
    end;

    local procedure BinMandatory_Verify(SalesLine: Record "Sales Line"; AsmOrderExists: Boolean; ExpectedLocationCode: Code[10]; ExpectedBinCode: Code[20])
    var
        AsmHeader: Record "Assembly Header";
    begin
        Assert.AreEqual(ExpectedLocationCode, SalesLine."Location Code", 'Checking Sales Line Location Code');
        Assert.AreEqual(ExpectedBinCode, SalesLine."Bin Code", 'Checking Sales Line Bin Code');
        Assert.AreEqual(AsmOrderExists, SalesLine.AsmToOrderExists(AsmHeader), 'Checking Asm Order existence');
        if AsmOrderExists then begin
            Assert.AreEqual(ExpectedLocationCode, AsmHeader."Location Code", 'Checking Asm Order Location Code');
            Assert.AreEqual(ExpectedBinCode, AsmHeader."Bin Code", 'Checking Asm Order Bin Code');
        end;
    end;

    [Test]
    [HandlerFunctions('AutoReserveAgainstILE,BinMandatoryRequirePick_MsgPickCreated')]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_CreateInventoryPickForATO()
    var
        AssemblySetup: Record "Assembly Setup";
        ExpectedQtysOnPickLines: array[3] of Decimal;
        ExpectedBinsOnPickLines: array[3] of Option;
        OldAutoCreateInvtMvmt: Boolean;
    begin
        Initialize();

        // Change Assembly Setup to no auto creation
        AssemblySetup.Get();
        OldAutoCreateInvtMvmt := AssemblySetup."Create Movements Automatically";
        AssemblySetup."Create Movements Automatically" := true;
        AssemblySetup.Modify();

        // Bin Code on Sales line is filled with BinAsm
        ToDecimalArray(ExpectedQtysOnPickLines, 7, 0, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, 0, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 0, 0, false, 1, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 1, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 3, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 4, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 0, 1, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 0, 4, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 0, 10, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 1, 1, false, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinAsm, 10, 7, 1, 1, true, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        // Bin Code on Sales line is filled with BinX
        ToDecimalArray(ExpectedQtysOnPickLines, 7, 0, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, 0, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 0, 0, false, 1, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 1, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 3, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 4, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 0, 1, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 0, 4, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 0, 10, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 1, 1, false, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinX, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::BinX, 10, 7, 1, 1, true, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        // Bin Code on sales line is blank
        ToDecimalArray(ExpectedQtysOnPickLines, 7, 0, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, 0, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 0, 0, false, 1, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 1, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 3, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 4, 0, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 0, 1, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 0, 4, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 3, 0);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinAsm, 0);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 0, 10, false, 2, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::BinAsm, BasicWhseBinType::BinX, BasicWhseBinType::BinAsm);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 1, 1, false, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        ToDecimalArray(ExpectedQtysOnPickLines, 7, 1, 1);
        ToOptionArray(ExpectedBinsOnPickLines, BasicWhseBinType::" ", BasicWhseBinType::BinX, BasicWhseBinType::BinAsm);
        BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(
          BasicWhseBinType::" ", 10, 7, 1, 1, true, 3, ExpectedQtysOnPickLines, ExpectedBinsOnPickLines);

        // revert to old setup
        AssemblySetup."Create Movements Automatically" := OldAutoCreateInvtMvmt;
        AssemblySetup.Modify();
    end;

    local procedure BinMandatoryRequirePick_CreateInventoryPickForATO_Setup(SalesLineBinCode: Option; SalesQty: Decimal; AssemblyQty: Decimal; InventoryInBinX: Decimal; InventoryInBinAsm: Decimal; AsmShptBinBlank: Boolean; ExpectedNoOfInvtPickLines: Integer; ExpectedQtyInPickLines: array[3] of Decimal; ExpectedBinInPickLines: array[3] of Option)
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        BinX: Record Bin;
        BinAsm: Record Bin;
        ComponentBin: Record Bin;
        ToAsmBin: Record Bin;
        BinY: Record Bin;
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityLine2: Record "Warehouse Activity Line";
        AsmHeader: Record "Assembly Header";
        InventoryPick: TestPage "Inventory Pick";
        PickLinesBinCode: array[3] of Code[20];
        SalesBinCode: Code[20];
        OldATOPickBinCode: Code[20];
        i: Integer;
    begin
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        MockBin(BinX, Location.Code); // non- assembly bin
        MockBin(BinAsm, Location.Code); // assembly bin
        if not AsmShptBinBlank then begin
            Location.Validate("Asm.-to-Order Shpt. Bin Code", BinAsm.Code);
            Location.Modify();
        end;

        // Add inventory to bins and BinContent records
        MockBinContent(Item, Location, BinX, '', false);
        if InventoryInBinX > 0 then
            AddItemToInventory(Item, Location, BinX, InventoryInBinX, '', '');
        MockBinContent(Item, Location, BinAsm, '', false);
        if InventoryInBinAsm > 0 then
            AddItemToInventory(Item, Location, BinAsm, InventoryInBinAsm, '', '');

        // Add enough inventory for child item in a new bin
        MockBin(ComponentBin, Location.Code);
        AddItemToInventory(ChildItem, Location, ComponentBin, 100, '', '');
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();

        // Create sales for SalesQty of which Assembly ATO is made for AssemblyQty
        case SalesLineBinCode of
            BasicWhseBinType::" ":
                SalesBinCode := '';
            BasicWhseBinType::BinX:
                SalesBinCode := BinX.Code;
            BasicWhseBinType::BinAsm:
                SalesBinCode := BinAsm.Code;
        end;
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesQty);
        SalesLine.Validate("Qty. to Assemble to Order", AssemblyQty);
        SalesLine.Validate("Bin Code", SalesBinCode);
        SalesLine.Modify(true);
        SalesLine.ShowReservation(); // reserve the rest of qty on sales against ILE (VSTF273866)

        // Create inventory pick from sales line
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // Verify
        for i := 1 to 3 do
            case ExpectedBinInPickLines[i] of
                BasicWhseBinType::" ":
                    PickLinesBinCode[i] := '';
                BasicWhseBinType::BinX:
                    PickLinesBinCode[i] := BinX.Code;
                BasicWhseBinType::BinAsm:
                    PickLinesBinCode[i] := BinAsm.Code;
            end;
        BinMandatoryRequirePick_Verify(
          SalesLine, WhseActivityLine, Location.Code, SalesBinCode, ExpectedNoOfInvtPickLines, ExpectedQtyInPickLines, PickLinesBinCode);

        // Register inventory movement for components
        SalesLine.AsmToOrderExists(AsmHeader);
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Movement");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityHeader.SetRange("Source No.", AsmHeader."No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Edit bin codes for A-T-O line
        Clear(WhseActivityHeader);
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        InventoryPick.Trap();
        PAGE.Run(PAGE::"Inventory Pick", WhseActivityHeader);
        InventoryPick.WhseActivityLines.First(); // first line
        WhseActivityLine2.Get(WhseActivityHeader.Type, WhseActivityHeader."No.", 10000); // first line
        if WhseActivityLine2."Assemble to Order" then begin
            OldATOPickBinCode := InventoryPick.WhseActivityLines."Bin Code".Value();
            InventoryPick.WhseActivityLines."Bin Code".SetValue(''); // blanking of bin allowed
            MockBin(BinY, Location.Code); // new bin for A-T-O
            InventoryPick.WhseActivityLines."Bin Code".SetValue(BinY.Code); // setting of bin allowed
        end;

        // Post 1 PCS of the inventory pick
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Qty. to Handle", 1);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        // Post rest of the inventory pick with old ATO bin Code
        if WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.") then begin
            LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
            WhseActivityLine.SetRange("Assemble to Order", true);
            WhseActivityLine.FindFirst();
            if (WhseActivityLine."Qty. to Handle" > 0) and (OldATOPickBinCode <> '') then begin
                WhseActivityLine.Validate("Bin Code", OldATOPickBinCode); // Use the old Bin Code
                WhseActivityLine.Modify(true);
            end;
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
        end;
    end;

    local procedure BinMandatoryRequirePick_Verify(SalesLine: Record "Sales Line"; var WhseActivityLine: Record "Warehouse Activity Line"; ExpectedLocationCode: Code[10]; ExpectedSalesBinCode: Code[20]; ExpectedNoOfInvtPickLines: Integer; ExpectedQtyInPickLines: array[3] of Decimal; ExpectedBinInPickLines: array[3] of Code[20])
    var
        NumOfLinesFound: Integer;
    begin
        BinMandatory_Verify(SalesLine, true, ExpectedLocationCode, ExpectedSalesBinCode);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", SalesLine."Document Type");
        WhseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        WhseActivityLine.SetRange("Source Line No.", SalesLine."Line No.");
        if WhseActivityLine.FindSet() then
            repeat
                NumOfLinesFound += 1;
                Assert.AreEqual(ExpectedLocationCode, WhseActivityLine."Location Code", 'Checking location code');
                Assert.AreEqual(ExpectedQtyInPickLines[NumOfLinesFound], WhseActivityLine.Quantity, 'Checking quantity');
                Assert.AreEqual(ExpectedBinInPickLines[NumOfLinesFound], WhseActivityLine."Bin Code", 'Checking bin code');
                if NumOfLinesFound = 1 then
                    Assert.IsTrue(WhseActivityLine."Assemble to Order", 'Checking field Assemble to Order.')
                else
                    Assert.IsFalse(WhseActivityLine."Assemble to Order", 'Checking field Assemble to Order.');
            until WhseActivityLine.Next() = 0;
        Assert.AreEqual(ExpectedNoOfInvtPickLines, NumOfLinesFound, 'Checking number of inventory pick lines');
    end;

    [Test]
    [HandlerFunctions('BinMandatoryRequirePick_MsgPickCreated')]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_ChangingQtyToAsmRaisesError()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ComponentBin: Record Bin;
        ToAsmBin: Record Bin;
        AsmHeader: Record "Assembly Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        ExpectedQtyInPickLines: array[3] of Decimal;
        ExpectedBinInPickLines: array[3] of Code[10];
    begin
        Initialize();
        // Create asm order for 10 PCS with 7 to be assembled.
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        MockBin(ComponentBin, Location.Code);
        AddItemToInventory(ChildItem, Location, ComponentBin, 100, '', '');
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Qty. to Assemble to Order", 7);
        SalesLine.Validate("Bin Code", '');

        // Change Qty to Ship = 5 and Qty to Asm = 4
        SalesLine.Validate("Qty. to Ship", 5);
        SalesLine.Modify(true);
        SalesLine.AsmToOrderExists(AsmHeader);
        AsmHeader.Validate("Quantity to Assemble", 4);
        AsmHeader.Modify();

        // Create invt pick
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        ToDecimalArray(ExpectedQtyInPickLines, 4, 0, 0);
        ExpectedBinInPickLines[1] := '';
        BinMandatoryRequirePick_Verify(SalesLine, WhseActivityLine, Location.Code, '', 1, ExpectedQtyInPickLines, ExpectedBinInPickLines);

        // Now change asm header Qty to Asm to another value
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        Commit();
        asserterror AsmHeader.Validate("Quantity to Assemble", 3);
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_INVTPICK_EXISTS) > 0, 'Check for invt pick exists error');
        asserterror AsmHeader.Validate("Quantity to Assemble", 5);
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_INVTPICK_EXISTS) > 0, 'Check for invt pick exists error');

        // Now post the inventory movement & pick
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Movement");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityHeader.SetRange("Source Subtype", AsmHeader."Document Type");
        WhseActivityHeader.SetRange("Source No.", AsmHeader."No.");
        WhseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Pick");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityHeader.SetRange("Source Subtype", SalesLine."Document Type");
        WhseActivityHeader.SetRange("Source No.", SalesLine."Document No.");
        WhseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.FindFirst();
        WhseActivityLine.Validate("Bin Code", ToAsmBin.Code);  // empty bin- fill it up
        WhseActivityLine.Modify();
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_MsgPickCreated(Message: Text[1024])
    var
        MsgInvtPick: Text;
        MsgInvtMvmt: Text;
    begin
        MsgInvtPick := StrSubstNo(MSG_INVTPICK_CREATED, 1, 1);
        Assert.IsTrue(StrPos(Message, MsgInvtPick) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, MsgInvtPick, Message));
        MsgInvtMvmt := StrSubstNo(MSG_INVTMVMT_CREATED, 1, 1);
        Assert.IsTrue(StrPos(Message, MsgInvtMvmt) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, MsgInvtMvmt, Message));
    end;

    [Test]
    [HandlerFunctions('BinMandatoryRequirePick_MsgPickMvmtCreated,BinMandatoryRequirePick_ReportCreatePickHandled')]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_CreateInvtMovement()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        ToAsmBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        StockBin: Record Bin;
        AssemblySetup: Record "Assembly Setup";
        AsmHeader1: Record "Assembly Header";
        AsmHeader2: Record "Assembly Header";
        AsmHeader3: Record "Assembly Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityHeader: Record "Warehouse Activity Header";
        ATOMovementsCreated: Integer;
        ATOTotalMovementsToBeCreated: Integer;
        OldAutoCreateInvtMvmt: Boolean;
    begin
        Initialize();
        // Create 3 sales lines with ATO items each with qty = 1
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine3, SalesHeader, SalesLine3.Type::Item, Item."No.", 1);

        // Put enough of child items on a new bin
        MockBin(StockBin, Location.Code);
        AddItemToInventory(ChildItem, Location, StockBin, 100, '', '');

        // Create inventory movement manually for the Asm Header on the second sales
        SalesLine2.AsmToOrderExists(AsmHeader2);
        LibraryAssembly.ReleaseAO(AsmHeader2);
        AsmHeader2.CreateInvtMovement(true, false, true, ATOMovementsCreated, ATOTotalMovementsToBeCreated);
        Assert.AreEqual(1, ATOMovementsCreated, '1 Inventory movement created.');
        Assert.AreEqual(1, ATOTotalMovementsToBeCreated, '1 Inventory movement to be created.');

        // Change Assembly Setup to auto creation of inventory movements
        AssemblySetup.Get();
        OldAutoCreateInvtMvmt := AssemblySetup."Create Movements Automatically";
        AssemblySetup."Create Movements Automatically" := true;
        AssemblySetup.Modify();

        // Create inventory pick for sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        // VSTF - 335836 addendum, make sure that there is a saved value for CreatePick = TRUE for report 7323.
        WarehouseRequest.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseRequest.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        Commit();
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WarehouseRequest);

        // Now post the inventory movements & pick
        SalesLine1.AsmToOrderExists(AsmHeader1);
        SalesLine3.AsmToOrderExists(AsmHeader3);
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Movement");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityHeader.SetRange("Source Subtype", AsmHeader2."Document Type"::Order);
        WhseActivityHeader.SetFilter("Source No.", '%1|%2|%3', AsmHeader1."No.", AsmHeader2."No.", AsmHeader3."No.");
        Assert.AreEqual(3, WhseActivityHeader.Count, 'Inventory movements will now exist for all the asm orders.');
        WhseActivityHeader.FindSet();
        repeat
            if WhseActivityHeader."Source No." in [AsmHeader1."No.", AsmHeader2."No.", AsmHeader3."No."] then begin
                LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
                LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
            end;
        until WhseActivityHeader.Next() = 0;
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Pick");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityHeader.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseActivityHeader.SetRange("Source No.", SalesHeader."No.");
        WhseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        // revert to old setup
        AssemblySetup."Create Movements Automatically" := OldAutoCreateInvtMvmt;
        AssemblySetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_ReportCreatePickHandled(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CreateInventorytPutAway.SetValue(false);
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_MsgPickMvmtCreated(Message: Text[1024])
    var
        MsgInvtPick: Text;
        MsgInvtMvmt: Text;
    begin
        MsgInvtPick := StrSubstNo(MSG_INVTPICK_CREATED, 1, 1);
        Assert.IsTrue(StrPos(Message, MsgInvtPick) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, MsgInvtPick, Message));
        MsgInvtMvmt := StrSubstNo(MSG_INVTMVMT_CREATED, 2, 3);
        Assert.IsTrue(StrPos(Message, MsgInvtMvmt) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, MsgInvtMvmt, Message));
    end;

    [Test]
    [HandlerFunctions('InvtPickMsgCreated')]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_NoAutoCreateInvtMovement()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        ToAsmBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockBin: Record Bin;
        AssemblySetup: Record "Assembly Setup";
        AsmHeader: Record "Assembly Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        OldAutoCreateInvtMvmt: Boolean;
        MovementsCreated: Integer;
        TotalMovementsCreated: Integer;
    begin
        Initialize();
        // Create ATO sales line for 1 PCS of item
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // Put enough of child items on a new bin
        MockBin(StockBin, Location.Code);
        AddItemToInventory(ChildItem, Location, StockBin, 100, '', '');

        // Change Assembly Setup to no auto creation
        AssemblySetup.Get();
        OldAutoCreateInvtMvmt := AssemblySetup."Create Movements Automatically";
        AssemblySetup."Create Movements Automatically" := false;
        AssemblySetup.Modify();

        // Create inventory pick for sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // Ensure inventory movement is not created
        SalesLine.AsmToOrderExists(AsmHeader);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Movement");
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source Subtype", AsmHeader."Document Type");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        Assert.IsTrue(WhseActivityLine.IsEmpty, '');

        // Create and register inventory movements from Assembly order
        AsmHeader.CreateInvtMovement(true, false, false, MovementsCreated, TotalMovementsCreated);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        // Now post the inventory pick
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityHeader.SetRange("Source Subtype", SalesLine."Document Type");
        WhseActivityHeader.SetRange("Source No.", SalesLine."Document No.");
        WhseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        // revert to old setup
        AssemblySetup."Create Movements Automatically" := OldAutoCreateInvtMvmt;
        AssemblySetup.Modify();
    end;

    [Test]
    [HandlerFunctions('SetSerialITOnAsm,InvtPickMsgCreated')]
    [Scope('OnPrem')]
    procedure BinMandatoryRequirePick_SerialIT()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        CompBin: Record Bin;
        ToAsmBin: Record Bin;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        Initialize();
        // Create item (with serial)/ location
        MockItemTrackingCode(ItemTrackingCode, true, false);
        MockATOItem(ParentItem, ChildItem);
        ParentItem."Item Tracking Code" := ItemTrackingCode.Code;
        ParentItem.Modify();
        ChildItem."Item Tracking Code" := ItemTrackingCode.Code;
        ChildItem.Modify();
        MockLocation(Location, true, true);

        // Put enough of child items on a new bin
        MockBin(CompBin, Location.Code);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN1);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN2);

        // Create sales order for 2 PCS all of which are on Assembly
        MockATOAsmOrder(AsmHeader, ParentItem, Location, SalesLine, 2);

        // Change asm line bin code to a new bin
        MockBin(ToAsmBin, Location.Code);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();
        AsmLine.Validate("Bin Code", ToAsmBin.Code);
        AsmLine.Modify(true);

        // Assign item tracking to assembly
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN1, '', 1);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN2, '', 1);
        AsmHeader.OpenItemTrackingLines();

        // Create Inventory Pick from sales line (should create inventory movement also for the components)
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // Register inventory movement fully
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Movement");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityHeader.SetRange("Source No.", AsmLine."Document No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Register inventory pick
        WhseActivityHeader.Reset();
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Invt. Pick");
        WhseActivityHeader.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityHeader.SetRange("Source No.", SalesLine."Document No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        VerifyWhseEntries(AsmHeader);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VSTF279916_ItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Lot2: Code[20];
        Lot3: Code[20];
        Lot2Qty: Decimal;
        Lot3Qty: Decimal;
    begin
        Lot2 := IncStr(FirstNumber);
        Lot2Qty := 1; // 1 PCS
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(Lot2);
        ItemTrackingLines."Quantity (Base)".SetValue(Lot2Qty);
        Lot3 := IncStr(Lot2);
        Lot3Qty := 2; // 2 PCS
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(Lot3);
        ItemTrackingLines."Quantity (Base)".SetValue(Lot3Qty);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VSTF279916_NotSpecificSNLot(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryInventory.GetReservConfirmText()) > 0, '');
        Reply := false;
    end;

    [Test]
    [HandlerFunctions('WhseShptOrPickCreatedMsg,AutoReserveAgainstILE')]
    [Scope('OnPrem')]
    procedure BinMandatoryWhseShpt_CreateWhseShpt()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        ShptBin: Record Bin;
        ToAsmBin: Record Bin;
        CompStockBin: Record Bin;
        AsmStockBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        NonATOWhseShptLine: Record "Warehouse Shipment Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        ChildItem2: Record Item;
        ATOPostedWhseShptLine: Record "Posted Whse. Shipment Line";
    begin
        Initialize();

        // Create ATO sales line for 10 PCS of item with 7 PCS from ATO
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Asm. Consump. Whse. Handling", Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        MockBin(ShptBin, Location.Code);
        Location.Validate("Shipment Bin Code", ShptBin.Code);
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Qty. to Assemble to Order", 7);
        SalesLine.Modify();

        // Release and create whse shipment
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        BinMandatoryWhseShpt_CreateWhseShpt_Verify(SalesLine);

        // Delete the ATO whse shipment line and recreate
        BinMandatoryWhseShpt_CreateWhseShpt_WhseShptSrcLink(SalesLine, ATOWhseShptLine);
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOWhseShptLine.DeleteAll(true);
        // Check that Qty. to Assemble is zeroed out
        SalesLine.AsmToOrderExists(AsmHeader);
        Assert.AreEqual(0, AsmHeader."Quantity to Assemble", '');
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        BinMandatoryWhseShpt_CreateWhseShpt_Verify(SalesLine);
        // now try to set Qty to Asm on Asm Header to any other value
        asserterror
        begin
            Commit(); // to save setup til now
            AsmHeader.Validate("Quantity to Assemble", AsmHeader."Quantity to Assemble" - 1);
        end;
        Assert.IsTrue(
          StrPos(GetLastErrorText, ERR_WHSESHPT_EXISTS) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, ERR_WHSESHPT_EXISTS, GetLastErrorText));
        ClearLastError();
        ATOWhseShptLine.FindFirst();
        // Check that Qty. to Ship is auto-set to 0 for ATO
        Assert.AreEqual(0, ATOWhseShptLine."Qty. to Ship", '');
        Assert.AreEqual(SalesLine."Qty. to Assemble to Order", ATOWhseShptLine.Quantity, '');
        ATOWhseShptLine.Validate("Qty. to Ship", ATOWhseShptLine.Quantity);
        ATOWhseShptLine.Modify(true);
        // Check that Qty. to Assemble is also set
        SalesLine.AsmToOrderExists(AsmHeader);
        Assert.AreEqual(ATOWhseShptLine."Qty. to Ship", AsmHeader."Quantity to Assemble", '');
        // Verify that changing Qty to Ship also changes Qty to Assemble
        ATOWhseShptLine.Validate("Qty. to Ship", ATOWhseShptLine."Qty. to Ship" - 1);
        ATOWhseShptLine.Modify(true);
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        Assert.AreEqual(ATOWhseShptLine."Qty. to Ship", AsmHeader."Quantity to Assemble", '');

        // Delete the non-ATO whse shipment line and recreate
        BinMandatoryWhseShpt_CreateWhseShpt_WhseShptSrcLink(SalesLine, NonATOWhseShptLine);
        NonATOWhseShptLine.SetRange("Assemble to Order", false);
        NonATOWhseShptLine.DeleteAll(true);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        BinMandatoryWhseShpt_CreateWhseShpt_Verify(SalesLine);

        // Recreate all whse shipments
        ATOWhseShptLine.SetRange("Assemble to Order");
        ATOWhseShptLine.DeleteAll(true);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ATOWhseShptLine.FindFirst();
        // trying to change Qty to Asm to Order on the sales line
        asserterror
        begin
            Commit(); // to not lose setup made as yet
            SalesLine.Validate("Qty. to Assemble to Order", SalesLine."Qty. to Assemble to Order" - 1);
        end;
        Assert.IsTrue(
          StrPos(GetLastErrorText, ERR_QTY_TO_ASM_CANT_BE_CHANGED) > 0,
          StrSubstNo(TXT_EXPECTED_ACTUAL, GetLastErrorText, ERR_QTY_TO_ASM_CANT_BE_CHANGED));

        // Put assembly item into stock
        MockBin(AsmStockBin, Location.Code);
        AddItemToInventory(Item, Location, AsmStockBin, 100, '', '');
        // Put components into inventory
        MockBin(CompStockBin, Location.Code);
        AddItemToInventory(ChildItem, Location, CompStockBin, 100, '', '');
        // Create consolidated pick
        WhseShptHeader.Get(ATOWhseShptLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShptHeader);
        BinMandatoryWhseShpt_CreateWhseShpt_VerifyPick(WhseShptHeader);
        // Register pick
        BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLink(WhseShptHeader, WhseActivityLine);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        // Verify picked
        SalesLine.AsmToOrderExists(AsmHeader);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.SetRange("No.", ChildItem."No.");
        AsmLine.FindFirst();
        Assert.AreEqual(7, AsmLine."Qty. Picked", '');
        Assert.AreEqual(7, AsmLine."Qty. Picked (Base)", '');

        // Make a new asm line after putting it into stock
        LibraryInventory.CreateItem(ChildItem2);
        AddItemToInventory(ChildItem2, Location, AsmStockBin, 100, '', '');
        LibraryAssembly.ReopenAO(AsmHeader);
        LibraryAssembly.CreateAssemblyLine(
          AsmHeader, AsmLine, "BOM Component Type"::Item, ChildItem2."No.", ChildItem2."Base Unit of Measure", 0, 1, '');
        // Create pick directly from asm order
        LibraryAssembly.ReleaseAO(AsmHeader);
        AsmHeader.CreatePick(false, UserId, 0, false, false, false);
        BinMandatoryWhseShpt_CreateWhseShpt_VerifyPickFromAsmOrder(AsmHeader);
        // Register pick
        BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLinkFromAsmOrder(AsmHeader, WhseActivityLine);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        // Verify picked
        AsmLine.SetRange("No.", ChildItem2."No.");
        AsmLine.FindFirst();
        Assert.AreEqual(7, AsmLine."Qty. Picked", '');
        Assert.AreEqual(7, AsmLine."Qty. Picked (Base)", '');

        // Reserve the NonATO part to the sales.
        SalesLine.ShowReservation(); // reserve the rest of qty on sales against ILE - Bug 273866

        // Ship 2 PCS of ATO and 1 PCS from inventory.
        ATOWhseShptLine.SetRange("Source Type", DATABASE::"Sales Line");
        ATOWhseShptLine.SetRange("Source Subtype", SalesLine."Document Type");
        ATOWhseShptLine.SetRange("Source No.", SalesLine."Document No.");
        ATOWhseShptLine.SetRange("Source Line No.", SalesLine."Line No.");
        ATOWhseShptLine.SetRange("No.", WhseShptHeader."No.");
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOWhseShptLine.FindFirst();
        WhseShptHeader.Get(ATOWhseShptLine."No.");
        ATOWhseShptLine.Validate("Qty. to Ship", 7);
        ATOWhseShptLine.Modify(true);
        NonATOWhseShptLine.CopyFilters(ATOWhseShptLine);
        NonATOWhseShptLine.SetRange("Assemble to Order", false);
        NonATOWhseShptLine.FindFirst();
        NonATOWhseShptLine.Validate("Qty. to Ship", 1);
        NonATOWhseShptLine.Modify(true);
        LibraryWarehouse.PostWhseShipment(WhseShptHeader, true);
        // Verify - document after posting
        ATOPostedWhseShptLine.SetRange("Whse. Shipment No.", ATOWhseShptLine."No.");
        ATOPostedWhseShptLine.SetRange("Whse Shipment Line No.", ATOWhseShptLine."Line No.");
        ATOPostedWhseShptLine.FindFirst();
        Assert.AreEqual(7, ATOPostedWhseShptLine.Quantity, ''); // 7 have been shipped
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_Verify(SalesLine: Record "Sales Line")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
    begin
        // Verify that there are two whse shipment lines- 7 for ATO and 3 for rest, both for default shipment bin code
        BinMandatoryWhseShpt_CreateWhseShpt_WhseShptSrcLink(SalesLine, WhseShptLine);
        Assert.AreEqual(2, WhseShptLine.Count, '');

        Location.Get(SalesLine."Location Code");
        WhseShptLine.SetRange("Bin Code", Location."Shipment Bin Code");

        WhseShptLine.SetRange("Assemble to Order", true);
        WhseShptLine.SetRange(Quantity, 7);
        Assert.AreEqual(1, WhseShptLine.Count, ''); // ATO

        WhseShptLine.SetRange("Assemble to Order", false);
        WhseShptLine.SetRange(Quantity, 3);
        Assert.AreEqual(1, WhseShptLine.Count, ''); // Rest
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_WhseShptSrcLink(SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
        Clear(WhseShptLine);
        WhseShptLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseShptLine.SetRange("Source Subtype", SalesLine."Document Type");
        WhseShptLine.SetRange("Source No.", SalesLine."Document No.");
        WhseShptLine.SetRange("Source Line No.", SalesLine."Line No.");
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_VerifyPick(WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLink(WhseShptHeader, WhseActivityLine);
        Assert.AreEqual(4, WhseActivityLine.Count, '');

        WhseActivityLine.SetRange("Assemble to Order", true);
        Assert.AreEqual(2, WhseActivityLine.Count, ''); // ATO

        WhseActivityLine.SetRange("Assemble to Order", false);
        Assert.AreEqual(2, WhseActivityLine.Count, ''); // Rest
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLink(WhseShptHeader: Record "Warehouse Shipment Header"; var WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Shipment);
        WhseActivityLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_VerifyPickFromAsmOrder(AsmHeader: Record "Assembly Header")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLinkFromAsmOrder(AsmHeader, WhseActivityLine);

        WhseActivityLine.SetRange("Assemble to Order", true);
        Assert.AreEqual(2, WhseActivityLine.Count, ''); // ATO
    end;

    local procedure BinMandatoryWhseShpt_CreateWhseShpt_WhsePickSrcLinkFromAsmOrder(AsmHeader: Record "Assembly Header"; var WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source Subtype", AsmHeader."Document Type");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Assembly);
        WhseActivityLine.SetRange("Whse. Document No.", AsmHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SetSerialITOnAsm')]
    [Scope('OnPrem')]
    procedure BinMandatoryWhseShpt_SerialIT()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        CompBin: Record Bin;
        ToAsmBin: Record Bin;
        ShptBin: Record Bin;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        Initialize();
        // Create item (with serial)/ location
        MockItemTrackingCode(ItemTrackingCode, true, false);
        MockATOItem(ParentItem, ChildItem);
        ParentItem."Item Tracking Code" := ItemTrackingCode.Code;
        ParentItem.Modify();
        ChildItem."Item Tracking Code" := ItemTrackingCode.Code;
        ChildItem.Modify();
        MockLocation(Location, true, true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Asm. Consump. Whse. Handling", Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);

        // Put enough of child items on a new bin
        MockBin(CompBin, Location.Code);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN1);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN2);

        // Create sales order for 2 PCS all of which are on Assembly
        MockATOAsmOrder(AsmHeader, ParentItem, Location, SalesLine, 2);

        // Change asm line bin code to a new bin
        MockBin(ToAsmBin, Location.Code);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();
        AsmLine.Validate("Bin Code", ToAsmBin.Code);
        AsmLine.Modify(true);

        // Assign item tracking to assembly
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN1, '', 1);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN2, '', 1);
        AsmHeader.OpenItemTrackingLines();

        // Create warehouse shipment from sales line and set new bin code on warehouse shipment line
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type");
        WhseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        WhseShipmentLine.SetRange("Source Line No.", SalesLine."Line No.");
        WhseShipmentLine.FindFirst();
        MockBin(ShptBin, Location.Code);
        WhseShipmentLine.Validate("Bin Code", ShptBin.Code);
        WhseShipmentLine.Modify(true);

        // Create warehouse pick
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        // Register warehouse pick fully
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type::Pick);
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source No.", AsmLine."Document No.");
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Register warehouse shipment
        WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine.Quantity);
        WhseShipmentLine.Modify(true);
        LibraryWarehouse.PostWhseShipment(WhseShipmentHeader, true);

        VerifyWhseEntries(AsmHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWhsePickFromATOShpt2Components()
    var
        ParentItem: Record Item;
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        BOMComponent: Record "BOM Component";
        Location: Record Location;
        ShptBin: Record Bin;
        ToAsmBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CompStockBin: Record Bin;
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();

        // Create ATO sales line for 2 PCS of parent item
        MockATOItem(ParentItem, ChildItem1);
        LibraryInventory.CreateItem(ChildItem2);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem2."No.", 1, ChildItem2."Base Unit of Measure");
        MockLocation(Location, true, true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Asm. Consump. Whse. Handling", Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        MockBin(ShptBin, Location.Code);
        Location.Validate("Shipment Bin Code", ShptBin.Code);
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();
        MockSalesHeaderWithItemsAndLocation(SalesHeader, ParentItem, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", 2);

        // Release and create whse shipment
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShptHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.FindFirst();
        WhseShptLine.Validate("Qty. to Ship", 1); // change qty. to ship to 1- but still the pick should be made for the full qty of 2 (verified later)
        WhseShptLine.Modify(true);

        // Put components into inventory
        MockBin(CompStockBin, Location.Code);
        AddItemToInventory(ChildItem1, Location, CompStockBin, 100, '', '');
        AddItemToInventory(ChildItem2, Location, CompStockBin, 100, '', '');

        // Create consolidated pick
        LibraryWarehouse.CreateWhsePick(WhseShptHeader);

        // Verify pick
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Shipment);
        WhseActivityLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
        WhseActivityLine.SetRange("Assemble to Order", true);
        WhseActivityLine.SetRange(Quantity, SalesLine.Quantity);
        Assert.AreEqual(4, WhseActivityLine.Count, '');
        WhseActivityLine.SetRange("Item No.", ChildItem1."No.");
        Assert.AreEqual(2, WhseActivityLine.Count, '');
        WhseActivityLine.SetRange("Item No.", ChildItem2."No.");
        Assert.AreEqual(2, WhseActivityLine.Count, '');

        // Register pick
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        // Verify picked
        SalesLine.AsmToOrderExists(AsmHeader);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindSet();
        repeat
            Assert.AreEqual(WhseActivityLine.Quantity, AsmLine."Qty. Picked", '');
            Assert.AreEqual(WhseActivityLine.Quantity, AsmLine."Qty. Picked (Base)", '');
        until AsmLine.Next() = 0;

        // Post whse shipment
        LibraryWarehouse.PostWhseShipment(WhseShptHeader, true);
    end;

    [Test]
    [HandlerFunctions('VSTF283949_SetSerialITOnAsm,VSTF283949_WhseShptOrPickCreatedMsg')]
    [Scope('OnPrem')]
    procedure VSTF283949()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        CompBin: Record Bin;
        ParentBin: Record Bin;
        ToAsmBin: Record Bin;
        ShptBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        WhseShptHeader: Record "Warehouse Shipment Header";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Initialize();

        // Create item (with serial)/ location
        MockItemTrackingCode(ItemTrackingCode, true, false);
        MockATOItem(ParentItem, ChildItem);
        ParentItem."Item Tracking Code" := ItemTrackingCode.Code;
        ParentItem.Modify();
        ChildItem."Item Tracking Code" := ItemTrackingCode.Code;
        ChildItem.Modify();
        MockLocation(Location, true, true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Asm. Consump. Whse. Handling", Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        MockBin(ShptBin, Location.Code);
        Location.Validate("Shipment Bin Code", ShptBin.Code);
        Location.Modify(true);

        // Create sales order for 5 PCS 3 of which are on Assembly
        MockSalesOrder(SalesLine, ParentItem, Location, 5);

        // Put enough of child items on a new bin
        MockBin(CompBin, Location.Code);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN1);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN2);
        AddItemToInventory(ChildItem, Location, CompBin, 1, '', ChildItemSN3);

        // Put 2 PCS of SN of parent on parent bin
        MockBin(ParentBin, Location.Code);
        AddItemToInventory(ParentItem, Location, ParentBin, 1, '', ParentItemSN1);
        AddItemToInventory(ParentItem, Location, ParentBin, 1, '', ParentItemSN2);

        // Set 3 on sales to be assembled and enter IT
        SalesLine.Validate("Qty. to Assemble to Order", 0); // raises Item availability error
        SalesLine.Modify(true);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, ParentItemSN1, '', 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, ParentItemSN2, '', 1);
        SalesLine.Validate("Qty. to Assemble to Order", 3);
        SalesLine.Modify(true);
        SalesLine.AsmToOrderExists(AsmHeader);
        AsmHeader.OpenItemTrackingLines();
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN1, '', 1);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN2, '', 1);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AsmLine, ChildItemSN3, '', 1);

        // Release sales
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Create & release whse shipment
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShptHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShptHeader);
        ATOWhseShptLine.SetRange("No.", WhseShptHeader."No.");
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOWhseShptLine.FindFirst();

        // Open pick worksheet and get whse docs for assembly
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location.Code);
        Assert.AreEqual(1, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // expecting one line for asm components
        CreatePickWkshLine(WhseWkshLine);
        Assert.IsTrue(WhseWkshLine.IsEmpty, ''); // expecting that the line created above vanishes as the full pick has been made
        asserterror
        begin
            Commit();
            Assert.AreEqual(0, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // all picks have been made. getting src docs should lead to error
        end;
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_NO_WHSE_WKSH_LINES_CREATED) > 0, '');
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::Pick);
        WhseActivityHeader.SetRange("Location Code", Location.Code);
        Assert.IsTrue(WhseActivityHeader.FindLast(), ''); // a pick for components must have been made
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(6, WhseActivityLine.Count, ''); // expecting 6 lines or 3 take-place pairs for each of the 3 serial nos of components
        WhseActivityHeader.Delete(true); // delete the pick made from the assembly

        // Open pick worksheet and get whse docs for shipment
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, 0, WhseShptHeader."No.", Location.Code);
        Assert.AreEqual(2, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // expecting two lines - one for ATO (with src doc Assembly) and another for non-ATO
        CreatePickWkshLine(WhseWkshLine);
        Assert.IsTrue(WhseWkshLine.IsEmpty, ''); // expecting that the lines created above vanishes as the full pick has been made
        asserterror
        begin
            Commit();
            Assert.AreEqual(0, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // all picks have been made. getting src docs should lead to error
        end;
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_NO_WHSE_WKSH_LINES_CREATED) > 0, '');
        Assert.IsTrue(WhseActivityHeader.FindLast(), ''); // a pick for components as well shipment items must have been made
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(10, WhseActivityLine.Count, ''); // expecting 10 lines or 3 take-place pairs for each of the 3 serial nos of components + 2 take-place pairs for the 2 parent items in warehouse

        // Delete one of the take pair lines among each of the components and shipment pick
        WhseActivityLine.SetFilter("Serial No.", '%1|%2', ChildItemSN2, ParentItemSN1);
        WhseActivityLine.DeleteAll(true);
        NotificationLifecycleMgt.RecallAllNotifications();

        // open pick worksheet and get whse docs for shipment to make the pick for the extra items
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, 0, WhseShptHeader."No.", Location.Code);
        Assert.AreEqual(2, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // expecting two lines - one for ATO (with src doc Assembly) and another for non-ATO
        WhseWkshLine.SetRange("Source Type", DATABASE::"Assembly Line");
        Assert.AreEqual(1, WhseWkshLine.Count, ''); // one wksh line for assembly type
        WhseWkshLine.FindFirst();
        Assert.AreEqual(1, WhseWkshLine."Qty. Outstanding", '');
        Assert.AreEqual(1, WhseWkshLine."Qty. to Handle", '');
        Assert.AreEqual(ATOWhseShptLine."Destination Type", WhseWkshLine."Destination Type", ''); // ATO Assembly wksh line should have fields filled in from ATO whse shipment
        Assert.AreEqual(ATOWhseShptLine."Destination No.", WhseWkshLine."Destination No.", ''); // ATO Assembly wksh line should have fields filled in from ATO whse shipment
        WhseWkshLine.SetRange("Source Type", DATABASE::"Sales Line");
        Assert.AreEqual(1, WhseWkshLine.Count, ''); // one wksh line for shipment type
        WhseWkshLine.SetRange("Source Type");
        CreatePickWkshLine(WhseWkshLine);
        Assert.IsTrue(WhseWkshLine.IsEmpty, ''); // expecting that the lines created above vanishes as the full pick has been made
        Assert.AreEqual(0, WhseWkshLine.Count, ''); // pick for full amount created so lines should go away
        Assert.IsTrue(WhseActivityHeader.FindLast(), ''); // a pick for the EXTRA components as well shipment items must have been made
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(4, WhseActivityLine.Count, ''); // expecting 4 lines or 2 take-place pairs for component and non-ATO shipment
        WhseActivityLine.SetRange("Serial No.", ChildItemSN2);
        Assert.AreEqual(2, WhseActivityLine.Count, ''); // expecting 2 lines or 1 take-place pairs for 1 serial nos of components
        WhseActivityLine.SetRange("Serial No.", ParentItemSN1);
        Assert.AreEqual(2, WhseActivityLine.Count, ''); // expecting 2 lines or 1 take-place pairs for 1 serial nos of nom-ATO shipment
        WhseActivityLine.SetRange("Serial No."); // remove the filter
        WhseActivityHeader.Delete(true); // delete the pick made for the extra items

        // Remove a serial number each from the components as well as from the inventory of parent item
        AddItemToInventory(ChildItem, Location, CompBin, -1, '', ChildItemSN2);
        AddItemToInventory(ParentItem, Location, ParentBin, -1, '', ParentItemSN1);

        // open pick worksheet and get whse docs for shipment to make the pick for the extra items
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, 0, WhseShptHeader."No.", Location.Code);
        Assert.AreEqual(2, LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code), ''); // expecting two lines - one for ATO (with src doc Assembly) and another for non-ATO
        asserterror
        begin
            Commit();
            CreatePickWkshLine(WhseWkshLine);
        end;
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_NOTHING_TO_HANDLE) > 0, ''); // a pick for the EXTRA components must NOT have been made as there are no items
        Assert.AreEqual(2, WhseWkshLine.Count, ''); // since the pick has not been made the 2 wksh lines stay.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VSTF283949_SetSerialITOnAsm(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Serial No.".SetValue(ParentItemSN3);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.New();
        ItemTrackingLines."Serial No.".SetValue(ParentItemSN4);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.New();
        ItemTrackingLines."Serial No.".SetValue(ParentItemSN5);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VSTF283949_WhseShptOrPickCreatedMsg(Message: Text)
    begin
        Assert.IsTrue(
          (StrPos(Message, MSG_PICK_ACTIVITY) > 0) and (StrPos(Message, MSG_GENERIC_CREATED) > 0), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF297713()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        AsmLine: Record "Assembly Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        Initialize();

        // SETUP
        // Create ATO warehouse shipment with asm line bin code as blank
        MockATOItemAndSalesOrder(Item, ChildItem, Location, SalesLine, AsmLine);

        AsmLine."Bin Code" := ''; // empty the bin code
        AsmLine.Modify();

        LibraryWarehouse.CreateWarehouseShipmentHeader(WhseShptHeader);
        WhseShptHeader.Validate("Location Code", Location.Code);
        WhseShptHeader.Modify();
        LibraryWarehouse.CreateWarehouseShipmentLine(WhseShptLine, WhseShptHeader);
        WhseShptLine.Validate("Location Code", Location.Code);
        WhseShptLine.Validate("Source Document", WhseShptLine."Source Document"::"Sales Order");
        WhseShptLine.Validate("Source Type", DATABASE::"Sales Line");
        WhseShptLine.Validate("Source Subtype", SalesLine."Document Type");
        WhseShptLine.Validate("Source No.", SalesLine."Document No.");
        WhseShptLine.Validate("Source Line No.", SalesLine."Line No.");
        WhseShptLine.Validate("Assemble to Order", true);
        WhseShptLine.Validate("Bin Code", Location."Shipment Bin Code");
        WhseShptLine.Validate("Item No.", Item."No.");
        WhseShptLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
        WhseShptLine.Validate(Quantity, SalesLine.Quantity);
        WhseShptLine.Modify();

        // Create a dummy warehouse worksheet line using the above ATO warehouse shipment line
        WhseActivityLine.Init();
        WhseWkshLine.Init();
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Shipment;
        WhseWkshLine."Whse. Document No." := WhseShptLine."No.";
        WhseWkshLine."Whse. Document Line No." := WhseShptLine."Line No.";

        // EXERCISE
        WhseActivityLine.TransferFromPickWkshLine(WhseWkshLine);

        // VERIFY - the new warehouse activity line has Assemble to Order as TRUE
        Assert.IsTrue(WhseActivityLine."Assemble to Order", '');

        // EXERCISE & VERIFY
        // release warehouse shipment and check for error that bin code is blank
        asserterror WhseShipmentRelease.Release(WhseShptHeader);
        Assert.ExpectedTestFieldError(AsmLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF297713_BothWhseShptAndAsmHeaderCannotBeSelectedAsSourceDoc()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        PickBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AsmLine: Record "Assembly Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseWorksheetCreate: Codeunit "Whse. Worksheet-Create";
    begin
        Initialize();

        // SETUP - Create ATO warehouse shipment and release it. Mock a pick worksheet line created from either the warehouse shipment or asm header.
        MockATOItemAndSalesOrder(Item, ChildItem, Location, SalesLine, AsmLine);

        MockBin(PickBin, Location.Code);
        AddItemToInventory(ChildItem, Location, PickBin, 100, '', '');

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShptHeader.SetRange("Location Code", Location.Code);
        WhseShptHeader.FindLast();
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShptHeader);

        // Create a pick worksheet line for the shpt / asm line.
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWkshLine, '', '', Location.Code, WhseWkshLine."Whse. Document Type"::Assembly);
        WhseWkshLine."Source Type" := DATABASE::"Assembly Line";
        WhseWkshLine."Source Subtype" := AsmLine."Document Type".AsInteger();
        WhseWkshLine."Source No." := AsmLine."Document No.";
        WhseWkshLine."Source Line No." := AsmLine."Line No.";
        WhseWkshLine."Source Subline No." := 0;
        WhseWkshLine.Modify();

        // EXERCISE - Try to create a new pick worksheet line,
        // VERIFY - Creation of new pick worksheet line is unsuccessful.
        Assert.IsFalse(
          WhseWorksheetCreate.FromAssemblyLine('', '', AsmLine), 'Since Pick worksheet line exists, getting source document on asm header should not create new line.');
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.FindFirst();
        Assert.IsFalse(
          WhseWorksheetCreate.FromAssemblyLineInATOWhseShpt('', '', AsmLine, WhseShptLine), 'Since Pick worksheet line exists, getting source document on warehouse shipment document should not create new line.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,BinMandatoryRequirePick_ReportCreatePickHandled')]
    [Scope('OnPrem')]
    procedure CreateInvtPickWithoutWhseRqstAfterCreateAndPostInvtPickFromSalesOrdWithAsm()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item with Assembly BOM. Add inventory for component Item.
        Initialize();
        CreateAsmItemWithAsmBOMAndAddInventory(Item, Location);

        // Create and release the 1st Sales Order. Create and register Inv. Pick from Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item, Location, Quantity);
        CreateAndPostInventoryPickFromSalesOrder(SalesHeader);

        // Create and release the 2nd Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, Item, Location, Quantity);

        // Exercise: Create Inv. Pick from Warehouse Tasks without Warehouse Request
        // by BinMandatoryRequirePick_ReportCreatePickHandled.
        Commit();
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WarehouseRequest);

        // Verify: Verify Inventory Pick created successfully.
        VerifyWhseActivityLine(SalesHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLineModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickingAsmToOrderComponentsWhenPickWorksheetPopulatedFromShipment()
    var
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        TrackedCompItem: Record Item;
        CompItem: Record Item;
        ATOItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Pick Worksheet]
        // [SCENARIO 356658] Creating pick from pick worksheet that is populated from warehouse shipment of an assemble-to-order sales line.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with directed put-away and pick.
        CreateDirectedPutAwayPickLocation(Bin);

        // [GIVEN] Serial no.-tracked item "IS" and non-tracked item "IN".
        MockItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(TrackedCompItem, '', '', ItemTrackingCode.Code);
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Post 1 pc of each item to inventory, assign serial no. "S1" to item "IS".
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, TrackedCompItem."No.", 1, true);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, CompItem."No.", 1, false);

        // [GIVEN] Assemble-to-order item "A" with two components "IS" and "IN".
        CreateATOItem(ATOItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ATOItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ATOItem."No.", BOMComponent.Type::Item, TrackedCompItem."No.", 1, TrackedCompItem."Base Unit of Measure");

        // [GIVEN] Sales order for 1 pc for item "A". "Qty. to Assemble to Order" = 1.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ATOItem."No.", 1, Bin."Location Code", WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Find the linked assembly order and select serial no. "S1" on the assembly component "IS".
        AssemblyLine.SetRange("No.", TrackedCompItem."No.");
        AssemblyLine.FindFirst();
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, SerialNo, '', 1);

        // [GIVEN] Create and release warehouse shipment for the sales order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Open pick worksheet and get the warehouse shipment.
        FindWhsePickRequestForShipment(WhsePickRequest, WarehouseShipmentHeader."No.");
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, '');

        // [WHEN] Create pick from the pick worksheet.
        CreatePickWkshLine(WhseWorksheetLine);

        // [THEN] The pick worksheet is cleared out.
        WhseWorksheetLine.SetRange(Name, WhseWorksheetLine.Name);
        Assert.RecordIsEmpty(WhseWorksheetLine);

        // [THEN] A newly created whse. pick includes both "IS" and "IN" components.
        // [THEN] Serial no. on "IS" component = "S1".
        FindWhseActivityLine(WarehouseActivityLine, AssemblyLine."Document No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", TrackedCompItem."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Serial No.", SerialNo);
        WarehouseActivityLine.SetRange("Item No.", CompItem."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] The pick can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure FromAsmBinCodeAsDefaultBinForAssemblyToOrder()
    var
        Item: Record Item;
        Location: Record Location;
        ShipBin: Record Bin;
        FromAsmBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 406250] "From-Assembly Bin Code" is used as a default bin code for assembly-to-order.
        Initialize();

        CreateATOItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(FromAsmBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", ShipBin.Code);
        Location.Validate("From-Assembly Bin Code", FromAsmBin.Code);
        Location.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
            Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());

        LibraryAssembly.FindLinkedAssemblyOrder(
            AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyHeader.TestField("Bin Code", FromAsmBin.Code);
    end;

    local procedure CreateAsmItemWithAsmBOMAndAddInventory(var Item: Record Item; var Location: Record Location)
    var
        ChildItem: Record Item;
        Bin: Record Bin;
    begin
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        MockBin(Bin, Location.Code);
        AddItemToInventory(ChildItem, Location, Bin, LibraryRandom.RandDec(10, 2) + 100, '', ''); // Large inventory.
    end;

    local procedure CreateATOItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostInventoryPickFromSalesOrder(var SalesHeader: Record "Sales Header")
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        WhseActivityHeader.SetRange("Source No.", SalesHeader."No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, true);
    end;

    local procedure CreateLocation(var Location: Record Location; "Code": Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingSetup2: Record "Inventory Posting Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        Clear(Location);
        Location.Validate(Code, Code);
        Location.Insert(true);

        // set up inventory posting groups
        InventoryPostingGroup.FindFirst();
        Clear(InventoryPostingSetup);
        InventoryPostingSetup2.Get('', InventoryPostingGroup.Code);
        InventoryPostingSetup.Copy(InventoryPostingSetup2);
        InventoryPostingSetup.Validate("Location Code", Code);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup.Code);
        InventoryPostingSetup.Insert(true);

        // set warehouse employee for this location
        CreateWarehouseEmployee(WarehouseEmployee, Location.Code);
    end;

    local procedure CreateDirectedPutAwayPickLocation(var Bin: Record Bin)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
    end;

    local procedure CreateWarehouseEmployee(var WarehouseEmployee: Record "Warehouse Employee"; LocationCode: Code[10])
    begin
        Clear(WarehouseEmployee);
        if UserId = '' then
            exit; // for native database
        if WarehouseEmployee.Get(UserId, LocationCode) then
            exit;
        WarehouseEmployee.Init();
        WarehouseEmployee.Validate("User ID", UserId);
        WarehouseEmployee.Validate("Location Code", LocationCode);
        WarehouseEmployee.Insert(true);
    end;

    local procedure FindWhsePickRequestForShipment(var WhsePickRequest: Record "Whse. Pick Request"; WhseShipmentNo: Code[20])
    begin
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", WhseShipmentNo);
        WhsePickRequest.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WhseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.SetRange("Activity Type", ActivityType);
        WhseActivityLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetSerialITOnAsm(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Serial No.".SetValue(ParentItemSN1);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.New();
        ItemTrackingLines."Serial No.".SetValue(ParentItemSN2);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvtPickMsgCreated(Message: Text[1024])
    var
        MsgInvtPick: Text;
    begin
        MsgInvtPick := StrSubstNo(MSG_INVTPICK_CREATED, 1, 1);
        Assert.IsTrue(StrPos(Message, MsgInvtPick) > 0, StrSubstNo(TXT_EXPECTED_ACTUAL, MsgInvtPick, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure WhseShptOrPickCreatedMsg(Message: Text)
    begin
        Assert.IsTrue(
          (StrPos(Message, MSG_PICK_ACTIVITY) > 0) and (StrPos(Message, MSG_GENERIC_CREATED) > 0), '');
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

    local procedure VerifyWhseEntries(AsmHeader: Record "Assembly Header")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
        WhseEntry: Record "Warehouse Entry";
        WhseRegister: Record "Warehouse Register";
        FirstWhseEntryNo: Integer;
        LastWhseEntryNo: Integer;
    begin
        // Verify warehouse entries
        PostedAsmHeader.SetRange("Order No.", AsmHeader."No.");
        PostedAsmHeader.FindLast();
        WhseEntry.SetRange("Reference Document", WhseEntry."Reference Document"::Assembly);
        WhseEntry.SetRange("Reference No.", PostedAsmHeader."No.");
        WhseEntry.FindFirst();
        FirstWhseEntryNo := WhseEntry."Entry No.";
        WhseEntry.Reset();
        WhseEntry.FindLast();
        LastWhseEntryNo := WhseEntry."Entry No.";
        WhseRegister.FindLast();
        Assert.AreEqual(FirstWhseEntryNo, WhseRegister."From Entry No.", '');
        Assert.AreEqual(LastWhseEntryNo, WhseRegister."To Entry No.", '');
        Assert.AreEqual(6, LastWhseEntryNo - FirstWhseEntryNo + 1, ''); // needs to be 6 entries- 2 with SN for- component, output and shipment
    end;

    local procedure VerifyWhseActivityLine(SalesHeaderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WhseActivityLine, SalesHeaderNo, WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.TestField("Item No.", ItemNo);
        WhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure MockATSItem(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        BomComp: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Assembly Policy", ParentItem."Assembly Policy"::"Assemble-to-Stock");
        ParentItem.Modify();

        LibraryInventory.CreateItem(ChildItem);
        LibraryInventory.CreateBOMComponent(
          BomComp, ParentItem."No.", BomComp.Type::Item, ChildItem."No.", 1, ChildItem."Base Unit of Measure");
    end;

    local procedure MockATOItem(var ParentItem: Record Item; var ChildItem: Record Item)
    begin
        MockATSItem(ParentItem, ChildItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Validate("Assembly Policy", ParentItem."Assembly Policy"::"Assemble-to-Order");
        ParentItem.Modify();
    end;

    local procedure MockLocation(var Location: Record Location; BinMandatory: Boolean; RequirePick: Boolean)
    var
        Bin: Record Bin;
        Name: Code[10];
        CallModify: Boolean;
    begin
        Name := FirstNumber;
        while Location.Get(Name) do
            Name := IncStr(Name);
        CreateLocation(Location, Name);
        if BinMandatory then begin
            Location."Bin Mandatory" := true;
            CallModify := true;
            MockBin(Bin, Location.Code);
        end;

        if RequirePick then begin
            Location."Require Pick" := true;
            CallModify := true;
        end;

        if Location."Require Pick" then begin
            Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
            Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Inventory Movement";
            Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Inventory Pick";
            CallModify := true;
        end else begin
            Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
            CallModify := true;
        end;

        if CallModify then
            Location.Modify();
    end;

    local procedure MockBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Name: Code[10];
    begin
        Name := FirstNumber;
        while Bin.Get(LocationCode, Name) do
            Name := IncStr(Name);
        LibraryWarehouse.CreateBin(Bin, LocationCode, Name, '', '');
    end;

    local procedure MockBinContent(Item: Record Item; Location: Record Location; Bin: Record Bin; VariantCode: Code[10]; Default: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", VariantCode, Item."Base Unit of Measure");
        BinContent.Validate(Default, Default);
        BinContent.Modify();
    end;

    local procedure MockSalesHeaderWithItemsAndLocation(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        // make a default bin content for item
        Bin.SetRange("Location Code", Location.Code);
        if Bin.FindFirst() then
            MockBinContent(Item, Location, Bin, '', true);

        // create a sales order for item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        PostponeShptDateforAssemblyLeadTime(SalesHeader);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
    end;

    local procedure MockSalesOrder(var SalesLine: Record "Sales Line"; var Item: Record Item; var Location: Record Location; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        PostponeShptDateforAssemblyLeadTime(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure MockATOAsmOrder(var AsmHeader: Record "Assembly Header"; var Item: Record Item; var Location: Record Location; var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        MockSalesOrder(SalesLine, Item, Location, Quantity);
        Clear(AsmHeader);
        SalesLine.AsmToOrderExists(AsmHeader);
    end;

    local procedure MockATOItemAndSalesOrder(var Item: Record Item; var ChildItem: Record Item; var Location: Record Location; var SalesLine: Record "Sales Line"; var AsmLine: Record "Assembly Line")
    var
        SalesHeader: Record "Sales Header";
        ShptBin: Record Bin;
        ToAsmBin: Record Bin;
        ATOLink: Record "Assemble-to-Order Link";
    begin
        MockATOItem(Item, ChildItem);
        MockLocation(Location, true, true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Asm. Consump. Whse. Handling", Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        MockBin(ShptBin, Location.Code);
        Location.Validate("Shipment Bin Code", ShptBin.Code);
        MockBin(ToAsmBin, Location.Code);
        Location.Validate("To-Assembly Bin Code", ToAsmBin.Code);
        Location.Modify();

        MockSalesHeaderWithItemsAndLocation(SalesHeader, Item, Location);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        ATOLink.AsmExistsForSalesLine(SalesLine);
        AsmLine.SetRange("Document Type", ATOLink."Assembly Document Type");
        AsmLine.SetRange("Document No.", ATOLink."Assembly Document No.");
        AsmLine.FindFirst();
    end;

    local procedure AddItemToInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal; LotNo: Code[50]; SerialNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", Location.Code);
        if Bin.Code <> '' then
            ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        if (LotNo <> '') or (SerialNo <> '') then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure ToDecimalArray(var Result: array[3] of Decimal; Element1: Decimal; Element2: Decimal; Element3: Decimal)
    begin
        Result[1] := Element1;
        Result[2] := Element2;
        Result[3] := Element3;
    end;

    local procedure ToOptionArray(var Result: array[3] of Option; Element1: Option; Element2: Option; Element3: Option)
    begin
        Result[1] := Element1;
        Result[2] := Element2;
        Result[3] := Element3;
    end;

    local procedure MockItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SerialTracking: Boolean; LotTracking: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SerialTracking, LotTracking);
        if SerialTracking then
            ItemTrackingCode."SN Warehouse Tracking" := true;
        if LotTracking then
            ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode.Modify();
    end;

    local procedure PostponeShptDateforAssemblyLeadTime(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate(
          "Shipment Date", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        SalesHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreatePickWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        CreatePick: Report "Create Pick";
    begin
        Commit(); // As there is a RUNMODAL inside the following call
        WhseWkshLine.Copy(WhseWorksheetLine);
        CreatePick.SetWkshPickLine(WhseWkshLine);
        CreatePick.UseRequestPage(false);
        CreatePick.RunModal();
        if CreatePick.GetResultMessage() then
            WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLineModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(1);
        WhseItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

