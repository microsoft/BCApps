// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Setup;
using System.Environment.Configuration;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Inventory.Requisition;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Planning;

codeunit 137913 "SCM Whse.-Asm. To Stock"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Warehouse] [SCM]
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
    end;

    var
        Item: Record Item;
        AsmItem: Record Item;
        CompItem: Record Item;
        Location: Record Location;
        BOMComponent: Record "BOM Component";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Resource: Record Resource;
        BinContent: Record "Bin Content";
        WarehouseClass: Record "Warehouse Class";
        Bin: Record Bin;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryAssembly: Codeunit "Library - Assembly";
        ErrBinMandatory1: Label 'must be set up with Bin Mandatory ';
        ErrBinMandatory2: Label 'Bin Mandatory must have a value in Location';
        ErrWrongBinType: Label 'You cannot enter a bin code of bin type Receive, Ship, or %1.';
        ErrWrongBinTypeRecShip: Label 'You cannot enter a bin code of bin type Receive or Ship.';
        ErrNothingToRelease: Label 'There is nothing to release for Order ';
        ErrLocationMustBeFilled: Label 'Location Code must have a value in Assembly Line';
        ConfirmUpdateLoc: Label 'Do you want to update the Location Code on the lines?';
        ConfirmItemNoChange: Label 'Changing Item No. will change all the lines. Do you want to change the Item No. from ';
        MessageNothngToCreate: Label 'There is nothing to create.';
        MessageNothngToHandle: Label 'There is nothing to handle.';
        MessageInvtMvmtCreated: Label 'Number of Invt. Movement activities created: 1 out of a total of 1.';
        MessagePickCreated: Label 'Pick activity no. ';
        MessageCreated: Label 'has been created.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryResource: Codeunit "Library - Resource";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        WorkDate2: Date;
        Initialized: Boolean;
        ErrWhseHandlingReqd: Label 'Warehouse handling is required for Entry Type = Assembly Consumption, Order No. = %1, Order Line No. = %2.';
        MessageExpectedActual: Label 'Expected: %1; Actual: %2';
        Bin1: Label 'BIN1';
        Bin2: Label 'BIN2';
        Bin3: Label 'BIN3';
        Bin4: Label 'BIN4';
        Bin5: Label 'BIN5';
        ConfirmChangeOfAsmItemNoCount: Integer;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Whse.-Asm. To Stock");
        ConfirmChangeOfAsmItemNoCount := 0;

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Whse.-Asm. To Stock");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibraryPatterns.SetNoSeries();
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Whse.-Asm. To Stock");
    end;

    local procedure MockItem(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure MockLocation(var Location: Record Location; BinMandatory: Boolean; RequirePick: Boolean; RequireShipment: Boolean; DirectedPutPick: Boolean)
    var
        BinTypePick: Record "Bin Type";
        BinTypePutaway: Record "Bin Type";
        BinTypeReceive: Record "Bin Type";
        Zone: Record Zone;
        Bin: Record Bin;
        WhseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location.Code, DirectedPutPick);
        if DirectedPutPick then
            BinMandatory := true;
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Directed Put-away and Pick", DirectedPutPick);
        Location.Modify(true);

        if DirectedPutPick then begin // create a zone and set bin type code
            BinTypePick.SetRange(Pick, true);
            BinTypePick.SetRange("Put Away", false);
            BinTypePick.FindFirst();
            LibraryWarehouse.CreateZone(Zone, 'ZONE', Location.Code, BinTypePick.Code, '', '', 0, false);
            BinTypePutaway.SetRange("Put Away", true);
            BinTypePutaway.SetRange(Pick, false);
            BinTypePutaway.FindFirst();
            BinTypeReceive.SetRange(Receive, true);
            BinTypeReceive.FindFirst();
            LibraryWarehouse.CreateBin(Bin, Location.Code, 'BINX', Zone.Code, BinTypePick.Code);
            Location.Validate("Adjustment Bin Code", 'BINX');
            Location.Modify(true);
        end;

        if Location."Require Pick" then
            if Location."Require Shipment" then begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            end else begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Inventory Movement";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Inventory Pick";
            end
        else begin
            Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        end;

        if Location."Require Put-away" and not Location."Require Receive" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);

        // create 4 bins - 2 for Picking and 2 for put-awaying and one for receiving
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin1, Zone.Code, BinTypePick.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin2, Zone.Code, BinTypePick.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin3, Zone.Code, BinTypePutaway.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin4, Zone.Code, BinTypePutaway.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin5, Zone.Code, BinTypeReceive.Code);
    end;

    local procedure MockResource(var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);
    end;

    local procedure MockAsmOrderWithComp(var AsmHeader: Record "Assembly Header"; var AsmItem: Record Item; var CompItem: Record Item; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, AsmItem."No.", '', Quantity, '');
        Commit(); // committing as subsequent errors might roll back bin content creation
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure AddItemToInventory(Item: Record Item; Location: Record Location; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        if Location."Directed Put-away and Pick" then begin
            WarehouseJournalTemplate.SetRange(Type, WarehouseJournalTemplate.Type::Item);
            WarehouseJournalTemplate.FindFirst();
            WarehouseJournalBatch.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
            WarehouseJournalBatch.FindFirst();
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, '', BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);
            LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate2, '');
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        end else begin
            ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
            ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
            ItemJournalLine.DeleteAll();
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", BinCode);
            ItemJournalLine.Modify(true);
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        end;
    end;

    local procedure CreateInvtPickMvmt(CreatePick: Boolean; CreateMvmt: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetCurrentKey("Source Document", "Source No.");
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Assembly Consumption");
        WarehouseRequest.SetRange("Source No.", AsmHeader."No.");
        LibraryAssembly.AsmOrder_CreateInvtMovement(WarehouseRequest, false, CreatePick, CreateMvmt, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5111()
    var
        BinType: Record "Bin Type";
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        Commit(); // committing as subsequent errors might roll back item creation

        // THE NEW BIN CODES MAY BE CHANGED ONLY WHEN Bin Mandatory = TRUE
        // ** negative test
        MockLocation(Location, false, false, false, false);
        asserterror Location.Validate("To-Assembly Bin Code", Bin1);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrBinMandatory1) > 0, 'Expected: ' + ErrBinMandatory1 + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        MockLocation(Location, false, false, false, false);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        Commit(); // committing as subsequent errors might roll back item creation
        AsmHeader.Validate("Location Code", Location.Code);
        asserterror AsmHeader.Validate("Bin Code", Bin1);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrBinMandatory2) > 0, 'Expected: ' + ErrBinMandatory2 + ' Actual: ' + GetLastErrorText);
        ClearLastError();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        asserterror AsmLine.Validate("Bin Code", Bin1);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrBinMandatory2) > 0, 'Expected: ' + ErrBinMandatory2 + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        // ** positive test
        MockLocation(Location, true, false, false, false);
        Location.Validate("To-Assembly Bin Code", Bin1); // expected: no errors

        MockLocation(Location, true, false, false, false);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Validate("Bin Code", Bin1); // expected: no errors
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin1); // expected: no errors

        // TO-ASSEMBLY BIN CCOD FROM LOCATION CARD SHOULD TAKE ONLY SUCH BINS IN DIRECTED PUT-AWAY & PICK LOCATION WHICH HAS Put-away=TRUE
        // ** negative test
        MockLocation(Location, false, false, false, true);
        asserterror Location.Validate("To-Assembly Bin Code", Bin1);
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrWrongBinType, BinType.FieldCaption(Pick))) > 0,
          'Expected: ' + StrSubstNo(ErrWrongBinType, BinType.FieldCaption(Pick)) + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        MockLocation(Location, false, false, false, true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        asserterror AsmLine.Validate("Bin Code", Bin1);
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrWrongBinType, BinType.FieldCaption(Pick))) > 0,
          'Expected: ' + StrSubstNo(ErrWrongBinType, BinType.FieldCaption(Pick)) + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        // ** positive test
        MockLocation(Location, false, false, false, true);
        Location.Validate("To-Assembly Bin Code", Bin3); // expected: no errors

        MockLocation(Location, false, false, false, true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin3); // expected: no errors

        // FROM-ASSEMBLY BIN CODE FROM LOCATION CARD SHOULD TAKE ONLY SUCH BINS IN DIRECTED PUT-AWAY & PICK LOCATION WHICH HAS Receive=TRUE
        // ** negative test
        MockLocation(Location, false, false, false, true);
        asserterror Location.Validate("From-Assembly Bin Code", Bin5); // error expected on Receive bin
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrWrongBinTypeRecShip)) > 0,
          StrSubstNo(MessageExpectedActual, StrSubstNo(ErrWrongBinTypeRecShip), GetLastErrorText));
        ClearLastError();

        MockLocation(Location, false, false, false, true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        asserterror AsmHeader.Validate("Bin Code", Bin5); // error expected on Receive bin
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrWrongBinTypeRecShip)) > 0,
          StrSubstNo(MessageExpectedActual, StrSubstNo(ErrWrongBinTypeRecShip), GetLastErrorText));
        ClearLastError();

        // ** positive test
        MockLocation(Location, false, false, false, true);
        Location.Validate("From-Assembly Bin Code", Bin1);
        Location.Validate("From-Assembly Bin Code", Bin3); // no error on pick type bin

        MockLocation(Location, false, false, false, true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Validate("Bin Code", Bin1);
        AsmHeader.Validate("Bin Code", Bin3); // no error on pick type bin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5112()
    var
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        // BIN CODE IS DEFAULTED TO WHEN CHANGES ARE MADE TO ITEM, VARIANT OR LOCATION
        MockItem(Item, ItemVariant);
        MockLocation(Location, true, false, false, false);
        // add a default bin content with variant
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin1, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        // as no location has been chosen Bin Code on Asm header should be blank
        Assert.AreEqual('', AsmHeader."Bin Code", 'as no location has been chosen Bin Code on Asm header should be blank');
        AsmHeader.Validate("Location Code", Location.Code);
        // location has been chosen but variant not chosen - no bin content should be found
        Assert.AreEqual('', AsmHeader."Bin Code", 'location has been chosen but variant not chosen - no bin content should be found');
        AsmHeader.Validate("Variant Code", ItemVariant.Code);
        // location, variant chosen- bin code to be fetched from bin content
        Assert.AreEqual(StrSubstNo(Bin1), AsmHeader."Bin Code", 'location, variant chosen- bin code to be fetched from bin content');

        // BIN CODE IS DEFAULTED TO FROM-ASSEMBLY BIN ON LOCATION CARD
        MockItem(Item, ItemVariant);
        MockLocation(Location, true, false, false, false);
        // add a default bin content with variant
        Location.Validate("From-Assembly Bin Code", Bin2);
        Location.Modify(true);
        // add a default bin content with variant
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin1, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        // location has been chosen bin code shud be pulled from From-Assembly Bin Code
        Assert.AreEqual(Location."From-Assembly Bin Code", AsmHeader."Bin Code",
          'location has been chosen bin code shud be pulled from From-Assembly Bin Code');
        AsmHeader.Validate("Variant Code", ItemVariant.Code);
        // although variant and location filled in, bin code should still be From-Assembly Bin Code
        Assert.AreEqual(Location."From-Assembly Bin Code", AsmHeader."Bin Code",
          'location has been chosen bin code shud be pulled from From-Assembly Bin Code');

        // IF QTY ON ASM HEADER < 0, BIN CODE SHOULD ACCEPT VALID BIN CONTENT
        MockItem(Item, ItemVariant);
        MockLocation(Location, true, false, false, false);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        Commit(); // committing as subsequent errors might roll back data creation
        // ** negative test
        AsmHeader.Quantity := -1;
        // no bin content exists- bin code should always be blank
        asserterror AsmHeader.Validate("Bin Code", Bin1);
        Assert.AssertNothingInsideFilter();

        // ** positive test
        // add a non-default bin content
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin2, Item."No.", '', Item."Base Unit of Measure");
        AsmHeader.Validate("Bin Code", Bin2); // no errors expected

        // OTHERWISE IT SHOULD POINT TO EXISTING BIN
        AsmHeader.Quantity := 1;
        // ** negative test
        // error expected for non-existing bin
        asserterror AsmHeader.Validate("Bin Code", 'BIN100');
        Assert.ExpectedErrorCannotFind(Database::Bin, 'BIN100');

        // ** positive test
        AsmHeader.Validate("Bin Code", Bin3); // no errors expected

        // IN CASE OF WMS LOCATIONS, IF A BIN CONTENT EXISTS, WAREHOUSE CLASS CODE IS CHECKED
        MockLocation(Location, false, false, false, true);
        MockItem(Item, ItemVariant);
        WarehouseClass.FindFirst();
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate2, Item."No.", '', 1, '');
        AsmHeader.Validate("Location Code", Location.Code);
        Commit(); // committing as subsequent errors might roll back data creation
        // ** negative test with bin
        asserterror AsmHeader.Validate("Bin Code", Bin1);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Warehouse Class Code"), '''');
        ClearLastError();

        // ** positive test with bin
        Bin.Get(Location.Code, Bin1);
        Bin.Validate("Warehouse Class Code", WarehouseClass.Code);
        Bin.Modify(true);
        AsmHeader.Validate("Bin Code", Bin1); // no errors expected

        // ** negative test with bin content
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin1, Item."No.", '', Item."Base Unit of Measure");
        Commit(); // committing as subsequent errors might roll back bin content creation
        asserterror AsmHeader.Validate("Bin Code", Bin1);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Warehouse Class Code"), '''');
        ClearLastError();

        // ** positive test with bin content
        BinContent.Validate("Warehouse Class Code", WarehouseClass.Code);
        BinContent.Modify(true);
        AsmHeader.Validate("Bin Code", Bin1); // no errors expected
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5113()
    var
        ParentItem: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        // IF TYPE IS CHANGED TO RESOURCE, BIN CODE IS EMPTIED AND BIN CODE IS EMPTY WHEN RESOURCE IS CHANGED
        MockLocation(Location, true, false, false, false);
        MockItem(Item, ItemVariant);
        LibraryInventory.CreateItem(ParentItem);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate(), ParentItem."No.", Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin1);
        AsmLine.Validate(Type, AsmLine.Type::Resource);
        Assert.AreEqual('', AsmLine."Bin Code", 'Bin Code needs to blank for resource lines');
        MockResource(Resource);
        AsmLine.Validate("No.", Resource."No.");
        Assert.AreEqual('', AsmLine."Bin Code", 'Bin Code needs to blank for resource lines');

        // ** negative test
        AsmLine."Location Code" := Location.Code;
        asserterror AsmLine.Validate("Bin Code", Bin1);
        Assert.ExpectedTestFieldError(AsmLine.FieldCaption(Type), Format(AsmLine.Type::Item));
        ClearLastError();

        // BIN CODE IS DEFAULTED TO WHEN CHANGES ARE MADE TO ITEM, VARIANT OR LOCATION
        MockItem(Item, ItemVariant);
        MockLocation(Location, true, false, false, false);
        // add a default bin content with variant
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin1, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        LibraryInventory.CreateItem(ParentItem);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate(), ParentItem."No.", Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        // as no location has been chosen Bin Code on Asm line should be blank
        Assert.AreEqual('', AsmLine."Bin Code", 'as no location has been chosen Bin Code on Asm line should be blank');
        AsmLine.Validate("Location Code", Location.Code);
        // location has been chosen but variant not chosen - no bin content should be found
        Assert.AreEqual('', AsmLine."Bin Code", 'location has been chosen but variant not chosen - no bin content should be found');
        AsmLine.Validate("Variant Code", ItemVariant.Code);
        // location, variant chosen- bin code to be fetched from bin content
        Assert.AreEqual(StrSubstNo(Bin1), AsmLine."Bin Code", 'location, variant chosen- bin code to be fetched from bin content');

        // BIN CODE IS DEFAULTED TO TO-ASSEMBLY BIN ON LOCATION CARD
        MockItem(Item, ItemVariant);
        MockLocation(Location, true, false, false, false);
        // add a default bin content with variant
        Location.Validate("To-Assembly Bin Code", Bin2);
        Location.Modify(true);
        // add a default bin content with variant
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin1, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        LibraryInventory.CreateItem(ParentItem);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate(), ParentItem."No.", Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        // location has been chosen bin code shud be pulled from From-Assembly Bin Code
        Assert.AreEqual(Location."To-Assembly Bin Code", AsmLine."Bin Code",
          'location has been chosen bin code shud be pulled from To-Assembly Bin Code');
        AsmLine.Validate("Variant Code", ItemVariant.Code);
        // although variant and location filled in, bin code should still be To-Assembly Bin Code
        Assert.AreEqual(Location."To-Assembly Bin Code", AsmLine."Bin Code",
          'location has been chosen bin code shud be pulled from To-Assembly Bin Code');

        // BIN CODE SHOULD POINT TO EXISTING BIN
        LibraryInventory.CreateItem(Item);
        MockLocation(Location, true, false, false, false);
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        Commit(); // committing as subsequent errors might roll back data creation
        // ** negative test
        // error expected for non-existing bin
        asserterror AsmLine.Validate("Bin Code", 'BIN100');
        Assert.ExpectedErrorCannotFind(Database::Bin, 'BIN100');

        // ** positive test
        AsmLine.Validate("Bin Code", Bin3); // no errors expected

        // IN CASE OF WMS LOCATIONS, IF A BIN CONTENT EXISTS, WAREHOUSE CLASS CODE IS CHECKED
        MockLocation(Location, false, false, false, true);
        LibraryInventory.CreateItem(Item);
        WarehouseClass.FindFirst();
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);
        LibraryInventory.CreateItem(ParentItem);
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate(), ParentItem."No.", Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        Commit(); // committing as subsequent errors might roll back data creation
        // ** negative test with bin
        asserterror AsmLine.Validate("Bin Code", Bin3);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Warehouse Class Code"), '''');
        ClearLastError();

        // ** positive test with bin
        Bin.Get(Location.Code, Bin3);
        Bin.Validate("Warehouse Class Code", WarehouseClass.Code);
        Bin.Modify(true);
        AsmLine.Validate("Bin Code", Bin3); // no errors expected
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateLocationOnLines')]
    [Scope('OnPrem')]
    procedure UT5121()
    begin
        Initialize();
        // POSTING ASSEMBLY RELEASES IT BEFORE PROCEEDING
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 2);
        MockLocation(Location, false, false, false, false);
        AddItemToInventory(CompItem, Location, '', 2);
        AsmHeader.Validate("Location Code", Location.Code);
        Assert.AreEqual(AsmHeader.Status::Open, AsmHeader.Status, 'Status should be open right after creation.');
        AsmHeader.Validate("Quantity to Assemble", 1); // change qty to 1 for partial posting
        AsmHeader.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AsmHeader, '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5122()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);

        // RELEASE OF ASSEMBLY RAISES ERROR IN CASE THERE ARE NO LINES WITH ITEMS WITH NON-ZERO QTY
        // check for line with zero qty
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate(Quantity, 0);
        AsmLine.Modify(true);
        asserterror LibraryAssembly.ReleaseAO(AsmHeader);
        Assert.IsTrue(
          StrPos(GetLastErrorText, ErrNothingToRelease) > 0, 'Expected: ' + ErrNothingToRelease + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        // check for no lines
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Delete(true);
        asserterror LibraryAssembly.ReleaseAO(AsmHeader);
        Assert.IsTrue(
          StrPos(GetLastErrorText, ErrNothingToRelease) > 0, 'Expected: ' + ErrNothingToRelease + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        // IN CASE INVENTORY SETUP HAS Location Mandatory, RELEASING ORDER WITH A LINE FOR ITEM WITH BLANK LOCATION RAISES ERROR
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", true);
        InventorySetup.Modify(true);
        asserterror LibraryAssembly.ReleaseAO(AsmHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrLocationMustBeFilled) > 0,
          'Expected: ' + ErrLocationMustBeFilled + ' Actual: ' + GetLastErrorText);
        ClearLastError();

        // RELEASE SETS STATUS TO Released
        LibraryAssembly.ReleaseAO(AsmHeader);
        Assert.AreEqual(AsmHeader.Status::Released, AsmHeader.Status, 'Wrong status set');

        // REOPEN SETS STATUS TO Open
        LibraryAssembly.ReopenAO(AsmHeader);
        Assert.AreEqual(AsmHeader.Status::Open, AsmHeader.Status, 'Wrong status set');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmChangeOfAsmItemNo')]
    [Scope('OnPrem')]
    procedure UT5123()
    var
        CompItem2: Record Item;
        AsmItem2: Record Item;
    begin
        Initialize();
        // ASSEMBLY ORDER CAN ONLY BE MODIFIED WHEN STATUS IS OPEN
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        LibraryInventory.CreateItem(CompItem2);
        LibraryInventory.CreateItem(AsmItem2);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem2."No.", BOMComponent.Type::Item, CompItem2."No.", 1, CompItem2."Base Unit of Measure");
        LibraryAssembly.ReleaseAO(AsmHeader);
        // ** negative test - modify assembly header
        asserterror AsmHeader.Validate("Item No.", AsmItem2."No.");
        Assert.ExpectedTestFieldError(AsmHeader.FieldCaption(Status), Format(AsmHeader.Status::Open));
        ClearLastError();

        // ** positive test
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        LibraryInventory.CreateItem(CompItem2);
        LibraryInventory.CreateItem(AsmItem2);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem2."No.", BOMComponent.Type::Item, CompItem2."No.", 1, CompItem2."Base Unit of Measure");
        asserterror
        begin
            Commit();
            AsmHeader.Validate("Item No.", AsmItem2."No."); // first time answer is "no" to confirm question
        end;
        ClearLastError();

        Assert.AreEqual(AsmItem."No.", AsmHeader."Item No.", '');

        AsmHeader.Validate("Item No.", AsmItem2."No."); // second time answer is "yes" to confirm question and no errors are expected
        Assert.AreEqual(AsmItem2."No.", AsmHeader."Item No.", '');

        // ASSEMBLY ORDER CAN BE DELETED WHEN STATUS IS RELEASED
        // reuse previous asm order
        AsmHeader.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        AsmHeader.Delete(true); // no errors expected
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5124()
    begin
        Initialize();
        // ASSEMBLY LINE CANNOT BE INSERTED IF STATUS NOT EQUAL Open
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        LibraryAssembly.ReleaseAO(AsmHeader);
        asserterror LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", '', 3, 1, '');
        Assert.ExpectedTestFieldError(AsmHeader.FieldCaption(Status), Format(AsmHeader.Status::Open));
        ClearLastError();

        // FIELDS ON ASSEMBLY LINE CANNOT BE CHANGED IF STATUS NOT EQUAL Open
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        LibraryAssembly.ReleaseAO(AsmHeader);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        asserterror AsmLine.Validate("Quantity per", 10);
        Assert.ExpectedTestFieldError(AsmHeader.FieldCaption(Status), Format(AsmHeader.Status::Open));
        ClearLastError();

        // ASSEMBLY LINE CANNOT BE DELETED IF STATUS NOT EQUAL Open
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        LibraryAssembly.ReleaseAO(AsmHeader);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        asserterror AsmLine.Delete(true);
        Assert.ExpectedTestFieldError(AsmHeader.FieldCaption(Status), Format(AsmHeader.Status::Open));
        ClearLastError();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT5131()
    var
        Location1: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        Location4: Record Location;
        Location5: Record Location;
        Location6: Record Location;
        WhseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        Initialize();
        // RELEASE SHOULD CREATE A Warehouse Request FOR EVERY UNIQUE LOCATION CODE ON ASSEMBLY LINE
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.DeleteAll(true); // delete all lines
        MockLocation(Location1, false, false, false, false); // no bin location
        Location1."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling";
        Location1.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location1.Code);
        AsmLine.Modify(true);
        MockLocation(Location2, true, false, false, false); // Bin Mandatory location
        Location2."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling";
        Location2.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location2.Code);
        AsmLine.Modify(true);
        MockLocation(Location3, true, true, false, false); // Require Pick location
        Location3."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";
        Location3.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location3.Code);
        AsmLine.Modify(true);
        MockLocation(Location4, true, true, true, false); // Require Shipment location
        Location4."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location4.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location4.Code);
        AsmLine.Modify(true);
        MockLocation(Location5, true, false, true, false); // Require Shipment but not pick location
        Location5."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling";
        Location5.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location5.Code);
        AsmLine.Modify(true);
        MockLocation(Location6, false, false, false, true); // WMS location
        Location6."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location6.Modify();
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location6.Code);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // check for warehouse request
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location1.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location1.Code);
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location2.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location2.Code);
        Assert.AreEqual(true,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location3.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be filled for ' + Location3.Code);
        Assert.AreEqual(WhseRequest."Document Status"::Released, WhseRequest."Document Status", '');
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location4.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location4.Code);
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location5.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location5.Code);
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location6.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location6.Code);
        // check for warehouse pick request
        Assert.AreEqual(false,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location1.Code),
          'Whse. Pick Request should be empty for ' + Location1.Code);
        Assert.AreEqual(false,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location2.Code),
          'Whse. Pick Request should be empty for ' + Location2.Code);
        Assert.AreEqual(false,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location3.Code),
          'Whse. Pick Request should be empty for ' + Location3.Code);
        Assert.AreEqual(true,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location4.Code),
          'Whse. Pick Request should be filled for ' + Location4.Code);
        Assert.AreEqual(WhsePickRequest.Status::Released, WhsePickRequest.Status, '');
        Assert.AreEqual(false,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location5.Code),
          'Whse. Pick Request should be empty for ' + Location5.Code);
        Assert.AreEqual(true,
          WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location6.Code),
          'Whse. Pick Request should be filled for ' + Location6.Code);
        Assert.AreEqual(WhsePickRequest.Status::Released, WhsePickRequest.Status, '');

        // REOPEN SETS Document Status OF THE Warehouse Request TO Open
        // reuse previous assembly header
        LibraryAssembly.ReopenAO(AsmHeader);
        WhseRequest.Get(WhseRequest.Type::Outbound, Location3.Code, DATABASE::"Assembly Line", AsmHeader."Document Type", AsmHeader."No.");
        Assert.AreEqual(WhseRequest."Document Status"::Open, WhseRequest."Document Status", '');
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location4.Code);
        Assert.AreEqual(WhsePickRequest.Status::Open, WhsePickRequest.Status, '');
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader."Document Type", AsmHeader."No.", Location6.Code);
        Assert.AreEqual(WhsePickRequest.Status::Open, WhsePickRequest.Status, '');

        // DELETING ASSEMBLY LINE DOES NOT DELETE Warehouse Request IF LINES EXIST FOR SAME LOCATION
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.DeleteAll(true); // delete all lines
        // make 2 asm lines with same location
        MockLocation(Location, true, true, false, false); // Require Pick location
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Modify(true);
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Modify(true);
        // release and reopen asm order
        LibraryAssembly.ReleaseAO(AsmHeader);
        LibraryAssembly.ReopenAO(AsmHeader);
        // delete 2nd line
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindLast();
        AsmLine.Delete(true);
        // verify that warehouse request stays
        Assert.AreEqual(true,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be filled for ' + Location.Code);
        // delete 1st line as well.
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();
        AsmLine.Delete(true);
        // verify that warehouse request is deleted.
        Assert.AreEqual(false,
          WhseRequest.Get(WhseRequest.Type::Outbound, Location.Code, DATABASE::"Assembly Line",
            AsmHeader."Document Type", AsmHeader."No."),
          'Whse. Request should be empty for ' + Location.Code);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageNothingToCreate')]
    [Scope('OnPrem')]
    procedure UT5132()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        CountOfWhseActivityLines: Integer;
    begin
        Initialize();
        // CREATING INVENTORY PICK FOR ASSEMBLY COMPONENTS LEADS TO MESSAGE "Nothing to Handle"
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, true, true, false, false); // Require Pick location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin2);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create inventory pick
        CountOfWhseActivityLines := WhseActivityLine.Count();
        CreateInvtPickMvmt(true, false); // create pick
        Assert.AreEqual(CountOfWhseActivityLines, WhseActivityLine.Count, 'Count should be the same as before');

        // CREATING INVENTORY MOVEMENT FOR NON BIN MANDATORY LEADS TO MESSAGE "Nothing to Handle"
        // reuse above order
        MockLocation(Location, false, true, false, false); // Require Pick location
        AddItemToInventory(CompItem, Location, '', 10);
        LibraryAssembly.ReopenAO(AsmHeader);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        CreateInvtPickMvmt(false, true); // create movement
        Assert.AreEqual(CountOfWhseActivityLines, WhseActivityLine.Count, 'Count should be the same as before');

        // CREATING INVENTORY MOVEMENT FOR COMP BIN BEING SAME AS BIN CONTENT LEADS TO MESSAGE "Nothing to Handle"
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, true, true, false, false); // Require Pick location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        LibraryAssembly.ReopenAO(AsmHeader);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin1);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create inventory pick
        CountOfWhseActivityLines := WhseActivityLine.Count();
        CreateInvtPickMvmt(true, false); // create pick
        Assert.AreEqual(CountOfWhseActivityLines, WhseActivityLine.Count, 'Count should be the same as before');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageInvtMovementCreated')]
    [Scope('OnPrem')]
    procedure UT5133A()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        CountOfWhseActivityLines: Integer;
    begin
        Initialize();
        // CREATING INVENTORY MOVEMENT MAKES AN INVENTORY MOVEMENT
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, true, true, false, false); // Require Pick location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin2);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create inventory movement
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        WhseActivityLine.SetRange("Item No.", CompItem."No.");
        CountOfWhseActivityLines := WhseActivityLine.Count();
        CreateInvtPickMvmt(false, true); // create movement
        Assert.AreEqual(CountOfWhseActivityLines + 2, WhseActivityLine.Count, 'Count should be the more than before by 2');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageNothingToCreate')]
    [Scope('OnPrem')]
    procedure UT5133B()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        CountOfWhseActivityLines: Integer;
    begin
        Initialize();
        // CREATING INVENTORY MOVEMENT FOR WMS LOCATIONS NOT ALLOWED
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, false, false, false, true); // WMS location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin3);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create inventory movement
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        WhseActivityLine.SetRange("Item No.", CompItem."No.");
        CountOfWhseActivityLines := WhseActivityLine.Count();
        CreateInvtPickMvmt(false, true); // create movement
        Assert.AreEqual(CountOfWhseActivityLines, WhseActivityLine.Count, 'Count should be the same as before.');
        // no invt movement created
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UT5134HandlePickCreatedMsg')]
    [Scope('OnPrem')]
    procedure UT5134()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        CountOfWhseActivityLines: Integer;
    begin
        Initialize();
        // CREATE PICK CREATES A WAREHOUSE PICK
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, true, true, true, false); // Require Shipment & Pick location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin2);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create warehouse pick
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        WhseActivityLine.SetRange("Item No.", CompItem."No.");
        CountOfWhseActivityLines := WhseActivityLine.Count();
        LibraryAssembly.CreateWhsePick(AsmHeader, '', 0, false, false, false); // create pick
        Assert.AreEqual(CountOfWhseActivityLines + 2, WhseActivityLine.Count, 'Count should be the more than before by 2'); // Take & Place

        // ALSO FOR WMS LOCATIONS
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, false, false, false, true); // WMS location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin3);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create warehouse pick
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", AsmHeader."No.");
        WhseActivityLine.SetRange("Item No.", CompItem."No.");
        CountOfWhseActivityLines := WhseActivityLine.Count();
        LibraryAssembly.CreateWhsePick(AsmHeader, '', 0, false, false, false); // create pick
        Assert.AreEqual(CountOfWhseActivityLines + 2, WhseActivityLine.Count, 'Count should be the more than before by 2'); // Take & Place
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure UT5134HandlePickCreatedMsg(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, MessagePickCreated) > 0, 'Wrong message. Expected: ' + MessagePickCreated + '; Actual: ' + Msg);
        Assert.IsTrue(StrPos(Msg, MessageCreated) > 0, 'Wrong message. Expected: ' + MessageCreated + '; Actual: ' + Msg);
    end;

    [Test]
    [HandlerFunctions('FormSourceDocuments,MessageNothingToHandle')]
    [Scope('OnPrem')]
    procedure UTInvtPickFromPage()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Initialize();
        // CREATING INVENTORY PICK FROM THE INVENTORY PICK PAGE DOES NOT CREATE INVENTORY PICK
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        MockLocation(Location, true, true, false, false); // Require Pick location
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.Validate("Location Code", Location.Code);
        AsmLine.Validate("Bin Code", Bin2);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);

        // create empty whse. activity header for inventory pick
        Clear(WarehouseActivityHeader);
        WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Pick";
        WarehouseActivityHeader.Insert(true);
        WarehouseActivityHeader.Validate("Location Code", Location.Code);
        WarehouseActivityHeader.Modify(true);
        // create inventory pick from the inventory pick page
        LibraryWarehouse.GetSourceDocInventoryPick(WarehouseActivityHeader); // throws Nothing to Handle message
        WhseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.AreEqual(0, WhseActivityLine.Count, 'Count should be zero as no pick should have been created');

        // ABOVE SCENARIO USING SAME COMP BIN AS BIN CONTENT
        LibraryAssembly.ReopenAO(AsmHeader);
        AsmLine.Validate("Bin Code", Bin1);
        AsmLine.Modify(true);
        LibraryAssembly.ReleaseAO(AsmHeader);
        // create inventory pick from the inventory pick page
        LibraryWarehouse.GetSourceDocInventoryPick(WarehouseActivityHeader); // throws Nothing to Handle message
        Assert.AreEqual(0, WhseActivityLine.Count, 'Count should be zero as no pick should have been created');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmUpdateLocationOnLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ConfirmUpdateLoc) > 0, StrSubstNo(MessageExpectedActual, ConfirmUpdateLoc, Question));
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmChangeOfAsmItemNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ConfirmItemNoChange) > 0, StrSubstNo(MessageExpectedActual, ConfirmItemNoChange, Question));

        ConfirmChangeOfAsmItemNoCount += 1;
        if ConfirmChangeOfAsmItemNoCount = 1 then
            Reply := false
        else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageNothingToCreate(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MessageNothngToCreate) > 0, StrSubstNo(MessageExpectedActual, MessageNothngToCreate, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageNothingToHandle(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MessageNothngToHandle) > 0, StrSubstNo(MessageExpectedActual, MessageNothngToCreate, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageInvtMovementCreated(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MessageInvtMvmtCreated) > 0, StrSubstNo(MessageExpectedActual, MessageInvtMvmtCreated, Message));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormSourceDocuments(var SourceDocuments: TestPage "Source Documents")
    var
        WarehouseRequest: Record "Warehouse Request";
        RecordReached: Boolean;
    begin
        WarehouseRequest.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseRequest.SetRange("Source Subtype", AsmHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", AsmHeader."No.");
        WarehouseRequest.FindFirst();

        SourceDocuments.First();
        if (SourceDocuments."Source Document".AsInteger() <> WarehouseRequest."Source Document".AsInteger()) or
           (SourceDocuments."Source No.".Value <> WarehouseRequest."Source No.")
        then begin
            RecordReached := false;
            while not RecordReached do begin
                Assert.IsTrue(SourceDocuments.Next(), '');
                if (SourceDocuments."Source Document".AsInteger() = WarehouseRequest."Source Document".AsInteger()) and
                   (SourceDocuments."Source No.".Value = WarehouseRequest."Source No.")
                then
                    RecordReached := true;
            end;
        end;

        SourceDocuments.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateLocationOnLines,MessageInvtMovementCreated')]
    [Scope('OnPrem')]
    procedure VSTF278221()
    begin
        Initialize();
        // create inventory pick location
        MockLocation(Location, true, true, false, false);// Require Pick location
        Location.Validate("To-Assembly Bin Code", Bin1);
        Location.Validate("From-Assembly Bin Code", Bin3);
        Location.Modify();
        // Create asm order
        MockAsmOrderWithComp(AsmHeader, AsmItem, CompItem, 1);
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Modify();
        // add items to inventory: both to the ToAsmBin as well as some other bin.
        AddItemToInventory(CompItem, Location, Bin1, 10);
        AddItemToInventory(CompItem, Location, Bin2, 10);
        // create inventory movement for asm order- From Bin2 To ToAsmBin
        LibraryAssembly.ReleaseAO(AsmHeader);
        CreateInvtPickMvmt(false, true); // create movement
        // now post the asm order- error expected
        asserterror LibraryAssembly.PostAssemblyHeader(AsmHeader, '');
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrWhseHandlingReqd, AsmHeader."No.", 10000)) > 0,
          StrSubstNo(MessageExpectedActual, StrSubstNo(ErrWhseHandlingReqd, AsmHeader."No.", 10000), GetLastErrorText));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultBinCodeToBeFilledOnCarryoutAMForAsm()
    var
        ParentItem: Record Item;
        CompItem: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        BomComp: Record "BOM Component";
        ToAsmBin: Record Bin;
        FromAsmBin: Record Bin;
        ReqLine: Record "Requisition Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        // See VSTF 329733 for details
        Initialize();

        // SETUP : Make location with To and From Asm bins and make a req line for asm order
        ParentItem."No." := LibraryUtility.GenerateRandomCode(ParentItem.FieldNo("No."), DATABASE::Item);
        ParentItem.Insert();
        CompItem."No." := LibraryUtility.GenerateRandomCode(CompItem.FieldNo("No."), DATABASE::Item);
        InventoryPostingGroup.FindFirst();
        CompItem."Inventory Posting Group" := InventoryPostingGroup.Code;
        CompItem.Insert();
        DefaultBinCodeToBeFilledSetupBOMLine(BomComp, ParentItem."No.", "BOM Component Type"::Item, CompItem."No.");

        DefaultBinCodeToBeFilledSetupPlanningLine(ParentItem, BomComp, ToAsmBin, FromAsmBin, ReqLine);

        // EXERCISE : call carry out action message on the above req line
        CarryOutAction.SetParameters("Planning Create Source Type"::Assembly, 0, '', '');
        CarryOutAction.Run(ReqLine);

        // VERIFY : in the asm header and lines created, the bin codes are the ones from location card.
        AsmHeader.SetRange("Document Type", AsmHeader."Document Type"::Order);
        AsmHeader.SetRange("Item No.", ParentItem."No.");
        AsmHeader.FindLast();
        Assert.AreEqual(FromAsmBin.Code, AsmHeader."Bin Code", 'Bin Code on header matches From Asm bin');
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindLast();
        Assert.AreEqual(ToAsmBin.Code, AsmLine."Bin Code", 'Bin Code on line matches To Asm bin');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultBinCodeToBeFilledOnExplodingOfBOM()
    var
        ParentItem: Record Item;
        CompItem: Record Item;
        CompResource: Record Resource;
        InventoryPostingGroup: Record "Inventory Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        BomComp: Record "BOM Component";
        ToAsmBin: Record Bin;
        FromAsmBin: Record Bin;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        // SETUP : Make location with To Asm bin and create the asm header
        ParentItem."No." := LibraryUtility.GenerateRandomCode(ParentItem.FieldNo("No."), DATABASE::Item);
        ParentItem.Insert();
        CompItem."No." := LibraryUtility.GenerateRandomCode(CompItem.FieldNo("No."), DATABASE::Item);
        InventoryPostingGroup.FindFirst();
        CompItem."Inventory Posting Group" := InventoryPostingGroup.Code;
        CompItem.Insert();
        CompResource."No." := LibraryUtility.GenerateRandomCode(CompResource.FieldNo("No."), DATABASE::Resource);
        GenProdPostingGroup.FindFirst();
        CompResource."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;
        CompResource.Insert();
        DefaultBinCodeToBeFilledSetupBOMLine(BomComp, ParentItem."No.", "BOM Component Type"::Item, CompItem."No.");
        DefaultBinCodeToBeFilledSetupBOMLine(BomComp, ParentItem."No.", "BOM Component Type"::Resource, CompResource."No.");

        DefaultBinCodeToBeFilledSetupLocation(ToAsmBin, FromAsmBin);

        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."Starting Date" := WorkDate();
        AsmHeader."Location Code" := ToAsmBin."Location Code";
        AsmHeader."Quantity (Base)" := 1;
        AsmHeader.Insert();

        // EXERCISE : Explode BOM on assembly order
        AsmLine."Document Type" := AsmHeader."Document Type";
        AsmLine."Document No." := AsmHeader."No.";
        AsmLine."Line No." := 10000;
        AsmLine.Type := AsmLine.Type::Item;
        AsmLine."No." := ParentItem."No.";
        AsmLine.Insert();
        AsmLine.ExplodeAssemblyList();

        // VERIFY : Asm line has To asm bin filled in for item and blank for resource
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.SetRange(Type, AsmLine.Type::Item);
        AsmLine.FindLast();
        Assert.AreEqual(ToAsmBin.Code, AsmLine."Bin Code", 'Bin Code on line matches To Asm bin');
        AsmLine.SetRange(Type, AsmLine.Type::Resource);
        AsmLine.FindLast();
        Assert.AreEqual('', AsmLine."Bin Code", 'Bin Code on resource line matches blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultBinCodeNotToBeFilledForResourceComponent()
    var
        ParentItem: Record Item;
        CompResource: Record Resource;
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        BomComp: Record "BOM Component";
        ToAsmBin: Record Bin;
        FromAsmBin: Record Bin;
        ReqLine: Record "Requisition Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        Initialize();

        // SETUP : Make location with To and From Asm bins and make a req line for asm order
        ParentItem."No." := LibraryUtility.GenerateRandomCode(ParentItem.FieldNo("No."), DATABASE::Item);
        ParentItem.Insert();
        CompResource."No." := LibraryUtility.GenerateRandomCode(CompResource.FieldNo("No."), DATABASE::Resource);
        GenProdPostingGroup.FindFirst();
        CompResource."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;
        CompResource.Insert();
        DefaultBinCodeToBeFilledSetupBOMLine(BomComp, ParentItem."No.", BomComp.Type::Resource, CompResource."No.");

        DefaultBinCodeToBeFilledSetupPlanningLine(ParentItem, BomComp, ToAsmBin, FromAsmBin, ReqLine);

        // EXERCISE : call carry out action message on the above req line
        CarryOutAction.SetParameters("Planning Create Source Type"::Assembly, 0, '', '');
        CarryOutAction.Run(ReqLine);

        // VERIFY : in the asm header created, the bin code is the one from location card.
        AsmHeader.SetRange("Document Type", AsmHeader."Document Type"::Order);
        AsmHeader.SetRange("Item No.", ParentItem."No.");
        AsmHeader.FindLast();
        Assert.AreEqual(FromAsmBin.Code, AsmHeader."Bin Code", 'Bin Code on header matches From Asm bin');
        // VERIFY : in the asm line created, the bin code is blank as this is a resource line
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindLast();
        Assert.AreEqual('', AsmLine."Bin Code", 'Bin Code on resource line matches blank');
    end;

    local procedure DefaultBinCodeToBeFilledSetupBOMLine(var BomComp: Record "BOM Component"; ParentItem: Code[20]; Type: Enum "BOM Component Type"; No: Code[20])
    var
        RecRef: RecordRef;
    begin
        BomComp."Parent Item No." := ParentItem;
        RecRef.GetTable(BomComp);
        BomComp."Line No." := LibraryUtility.GetNewLineNo(RecRef, BomComp.FieldNo("Line No."));
        BomComp.Type := Type;
        BomComp."No." := No;
        BomComp."Quantity per" := 1;
        BomComp.Insert();
    end;

    local procedure DefaultBinCodeToBeFilledSetupPlanningLine(ParentItem: Record Item; BomComp: Record "BOM Component"; var ToAsmBin: Record Bin; var FromAsmBin: Record Bin; var ReqLine: Record "Requisition Line")
    var
        PlanningComponent: Record "Planning Component";
    begin
        DefaultBinCodeToBeFilledSetupLocation(ToAsmBin, FromAsmBin);

        ReqLine."Action Message" := ReqLine."Action Message"::New;
        ReqLine."Starting Date" := WorkDate();
        ReqLine.Type := ReqLine.Type::Item;
        ReqLine."No." := ParentItem."No.";
        ReqLine."Location Code" := ToAsmBin."Location Code";
        ReqLine."Quantity (Base)" := 2;
        ReqLine.Insert();

        if BomComp.Type <> BomComp.Type::Item then
            exit;
        PlanningComponent.Init();
        PlanningComponent."Item No." := BomComp."No.";
        PlanningComponent."Quantity (Base)" := ReqLine."Quantity (Base)" * BomComp."Quantity per";
        PlanningComponent."Qty. per Unit of Measure" := 1;
        PlanningComponent."Location Code" := Location.Code;
        PlanningComponent.Insert();
    end;

    local procedure DefaultBinCodeToBeFilledSetupLocation(var ToAsmBin: Record Bin; var FromAsmBin: Record Bin)
    begin
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        Location."Bin Mandatory" := true;
        ToAsmBin."Location Code" := Location.Code;
        ToAsmBin.Code := LibraryUtility.GenerateRandomCode(ToAsmBin.FieldNo(Code), DATABASE::Bin);
        ToAsmBin.Insert();
        Location."To-Assembly Bin Code" := ToAsmBin.Code;
        FromAsmBin."Location Code" := Location.Code;
        FromAsmBin.Code := LibraryUtility.GenerateRandomCode(FromAsmBin.FieldNo(Code), DATABASE::Bin);
        FromAsmBin.Insert();
        Location."From-Assembly Bin Code" := FromAsmBin.Code;
        Location.Insert();
    end;
}

