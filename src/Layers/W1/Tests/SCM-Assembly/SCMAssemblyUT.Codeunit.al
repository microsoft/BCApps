// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Posting;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Availability;
using Microsoft.Assembly.Setup;

codeunit 137928 "SCM Assembly UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM] [UT]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        DueDateBeforeEndingDateErr: Label 'Due Date %1 is before Ending Date %2.', Comment = '%1: Field(Due Date), %2: Field(Ending Date)';
        DatesChangedConfirmHandlerQuestion: Text;
        UpdateDueDateQst: Label 'Do you want to update the Due Date from %1 to %2?', Comment = '%1: xRec.Field(Due Date), %2: Field(Due Date)';
        UpdateEndingDateQst: Label 'Do you want to update the Ending Date from %1 to %2?', Comment = '%1: xRec.Field(Ending Date), %2: Field(Ending Date)';
        UpdateEndingAndDueDateQst: Label 'Do you want to update the Ending Date from %1 to %2 and the Due Date from %3 to %4?', Comment = '%1: xRec.Field(Ending Date), %2: Field(Ending Date), %3: xRec.Field(Due Date), %4: Field(Due Date)';
        FullATOPostedMismatchMsg: Label 'FullATOPosted should return %1.', Comment = '%1: Function(FullATOPosted)';
        WrongQtyInAsmBinErr: Label 'Quantity in Assembly Bin is incorrect.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenEndDateAdvancesBeyondDueDateOnATO()
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        NewEndDate: Date;
    begin
        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        WarningForDueDateWhenEndDateChangeMakeATO(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";

        // EXERCISE & VERIFY error
        NewEndDate := AssemblyHeader."Ending Date" + 10; // change Ending Date by value much greater than the difference between Ending and Due Date.
        AssemblyHeader."Ending Date" := NewEndDate;
        asserterror AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Ending Date"), false);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(DueDateBeforeEndingDateErr, OldDueDate, NewEndDate)) > 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoWarningForDueDateWhenEndDateAdvancesOnATO()
    begin
        NoWarningForDueDateWhenEndDateChangesOnATO(+1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoWarningForDueDateWhenEndDateRegressesOnATO()
    begin
        NoWarningForDueDateWhenEndDateChangesOnATO(-1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhenEndDateAdvancesBeyondDueDateOnATS()
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        OldStartDate: Date;
    begin
        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldStartDate := AssemblyHeader."Starting Date";

        // EXERCISE & VERIFY error
        AssemblyHeader."Ending Date" := AssemblyHeader."Ending Date" + 10; // change Ending Date by value much greater than the difference between Ending and Due Date.
        DatesChangedConfirmHandlerQuestion := StrSubstNo(UpdateDueDateQst, OldDueDate, OldDueDate + 10);
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Ending Date"), false); // successful completion of this is proof of no error

        Assert.AreEqual(OldDueDate + 10, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldStartDate + 10, AssemblyHeader."Starting Date", AssemblyHeader.FieldCaption("Starting Date"));
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarningForDueDateWhenEndDateAdvancesOnATS()
    begin
        WarningForDueDateWhenEndDateChangesOnATS(+1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarningForDueDateWhenEndDateRegressesOnATS()
    begin
        WarningForDueDateWhenEndDateChangesOnATS(-1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenStartDateAdvancesBeyondDueDateOnATO()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        OldDueDate: Date;
        OldEndDate: Date;
        NewStartDate: Date;
    begin
        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        WarningForDueDateWhenEndDateChangeMakeATO(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldEndDate := AssemblyHeader."Ending Date";
        Item.Get(AssemblyHeader."Item No.");

        // EXERCISE & VERIFY error
        NewStartDate := AssemblyHeader."Starting Date" + 10; // change Starting Date by value much greater than the difference between Starting and Due Date.
        AssemblyHeader."Starting Date" := NewStartDate;
        DatesChangedConfirmHandlerQuestion := StrSubstNo(UpdateEndingDateQst, OldEndDate, OldEndDate + 10);
        asserterror AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Starting Date"), false);
        Assert.IsTrue(StrPos(GetLastErrorText,
            StrSubstNo(DueDateBeforeEndingDateErr, OldDueDate, CalcDate(Item."Lead Time Calculation", NewStartDate))) > 0, '');
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoWarningForDueDateWhenStartDateAdvancesOnATO()
    begin
        NoWarningForDueDateWhenStartDateChangesOnATO(+1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoWarningForDueDateWhenStartDateRegressesOnATO()
    begin
        NoWarningForDueDateWhenStartDateChangesOnATO(-1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhenStartDateAdvancesBeyondDueDateOnATS()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        OldDueDate: Date;
        OldEndDate: Date;
        NewStartDate: Date;
    begin
        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldEndDate := AssemblyHeader."Ending Date";
        Item.Get(AssemblyHeader."Item No.");

        // EXERCISE & VERIFY no error
        NewStartDate := AssemblyHeader."Starting Date" + 10; // change Starting Date by value much greater than the difference between Starting and Due Date.
        AssemblyHeader."Starting Date" := NewStartDate;
        DatesChangedConfirmHandlerQuestion :=
          StrSubstNo(UpdateEndingAndDueDateQst, OldEndDate, OldEndDate + 10, OldDueDate, OldDueDate + 10);
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Starting Date"), false); // successful completion of this is proof of no error
        Assert.AreEqual(OldDueDate + 10, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldEndDate + 10, AssemblyHeader."Ending Date", AssemblyHeader.FieldCaption("Ending Date"));
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarningForDueDateWhenStartDateAdvancesOnATS()
    begin
        WarningForDueDateWhenStartDateChangesOnATS(+1);
    end;

    [Test]
    [HandlerFunctions('DatesChangedConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarningForDueDateWhenStartDateRegressesOnATS()
    begin
        WarningForDueDateWhenStartDateChangesOnATS(-1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullATOPostedCheckATSFirstSameWhseShpt()
    var
        ATSWhseShptLine: Record "Warehouse Shipment Line";
    begin
        // Based on VSTF 329599
        // Setup
        SetupFullATOPostedCheckWarehouseShpt(ATSWhseShptLine, 2, 1, 0, 0, 1, false);

        // Exercise + Verify
        Assert.IsFalse(ATSWhseShptLine.FullATOPosted(), StrSubstNo(FullATOPostedMismatchMsg, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullATOPostedCheckATSFIrstDiffWhseShpt()
    var
        ATSWhseShptLine: Record "Warehouse Shipment Line";
    begin
        // Based on VSTF 329599
        // Setup
        SetupFullATOPostedCheckWarehouseShpt(ATSWhseShptLine, 2, 1, 0, 0, 1, true);

        // Exercise + Verify
        Assert.IsFalse(ATSWhseShptLine.FullATOPosted(), StrSubstNo(FullATOPostedMismatchMsg, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullATOPostedCheckBothLinesSameWhseShpt()
    var
        ATSWhseShptLine: Record "Warehouse Shipment Line";
    begin
        // Based on VSTF 329599
        // Setup
        SetupFullATOPostedCheckWarehouseShpt(ATSWhseShptLine, 2, 1, 0, 1, 1, false);

        // Exercise + Verify
        Assert.IsTrue(ATSWhseShptLine.FullATOPosted(), StrSubstNo(FullATOPostedMismatchMsg, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullATOPostedCheckATOAlreadyShipped()
    var
        ATSWhseShptLine: Record "Warehouse Shipment Line";
    begin
        // Based on VSTF 329599
        // Setup
        SetupFullATOPostedCheckWarehouseShpt(ATSWhseShptLine, 2, 1, 1, 0, 1, false);

        // Exercise + Verify
        Assert.IsTrue(ATSWhseShptLine.FullATOPosted(), StrSubstNo(FullATOPostedMismatchMsg, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenATOSalesQuoteReopensAsmQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Refer to VSTF 333539
        ReopenAReleasedAsmDoc(SalesHeader."Document Type"::Quote, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenATOSalesBOrderReopensAsmBOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Refer to VSTF 333539
        ReopenAReleasedAsmDoc(SalesHeader."Document Type"::"Blanket Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenATOSalesOrderDoesNotReopenAsmOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Refer to VSTF 333539
        ReopenAReleasedAsmDoc(SalesHeader."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnAssemblyBinZeroWhenAsmBinIsNotSetUp()
    var
        Location: Record Location;
        ItemNo: array[2] of Code[20];
        LotNo: array[2] of Code[20];
        SerialNo: array[2] of Code[20];
        QtyBase: Decimal;
        QtyInAsmBin: Decimal;
    begin
        // [SCENARIO 381763] Function CalcQtyOnAssemblyBin in codeunit 7314 should return 0 if "To-Assembly Bin Code" on location is blank.

        // [GIVEN] Location with blank "To-Assembly Bin Code".
        // [GIVEN] Warehouse entries on Location "L" for two items, each of them has two lots, for which there are two serial nos. Quantity of each entry = "Q".
        QtyBase := LibraryRandom.RandInt(10);
        MockLocation(Location, '');
        MockItemsLotsSerials(ItemNo, LotNo, SerialNo);
        MockWhseEntries(Location, ItemNo, LotNo, SerialNo, QtyBase);

        // [WHEN] Invoke CalcQtyOnAssemblyBin function in codeunit 7314.
        QtyInAsmBin := CalcQtyOnBin(Location, ItemNo[1], '', '', '');

        // [THEN] The function returns 0.
        Assert.AreEqual(0, QtyInAsmBin, WrongQtyInAsmBinErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnAssemblyBinWithItemFilter()
    var
        Location: Record Location;
        ItemNo: array[2] of Code[20];
        LotNo: array[2] of Code[20];
        SerialNo: array[2] of Code[20];
        QtyBase: Decimal;
        QtyInAsmBin: Decimal;
    begin
        // [SCENARIO 381763] Function CalcQtyOnAssemblyBin in codeunit 7314 should return sum of "Qty (Base)" for warehouse entries in assembly bin for a given item.

        // [GIVEN] Location with "To-Assembly Bin Code".
        // [GIVEN] Warehouse entries on Location "L" for two items, each of them has two lots, for which there are two serial nos. Quantity of each entry = "Q".
        QtyBase := LibraryRandom.RandInt(10);
        MockLocation(Location, LibraryUtility.GenerateGUID());
        MockItemsLotsSerials(ItemNo, LotNo, SerialNo);
        MockWhseEntries(Location, ItemNo, LotNo, SerialNo, QtyBase);

        // [WHEN] Invoke CalcQtyOnAssemblyBin function in codeunit 7314 with first Item No. as a parameter.
        QtyInAsmBin := CalcQtyOnBin(Location, ItemNo[1], '', '', '');

        // [THEN] The function returns 4 * Q (sum of 4 entries).
        Assert.AreEqual(QtyBase * ArrayLen(LotNo) * ArrayLen(SerialNo), QtyInAsmBin, WrongQtyInAsmBinErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnAssemblyBinWithItemAndLotFilter()
    var
        Location: Record Location;
        ItemNo: array[2] of Code[20];
        LotNo: array[2] of Code[20];
        SerialNo: array[2] of Code[20];
        QtyBase: Decimal;
        QtyInAsmBin: Decimal;
    begin
        // [SCENARIO 381763] Function CalcQtyOnAssemblyBin in codeunit 7314 should return sum of "Qty (Base)" for warehouse entries in assembly bin for a given item and lot.

        // [GIVEN] Location with "To-Assembly Bin Code".
        // [GIVEN] Warehouse entries on Location "L" for two items, each of them has two lots, for which there are two serial nos. Quantity of each entry = "Q".
        QtyBase := LibraryRandom.RandInt(10);
        MockLocation(Location, LibraryUtility.GenerateGUID());
        MockItemsLotsSerials(ItemNo, LotNo, SerialNo);
        MockWhseEntries(Location, ItemNo, LotNo, SerialNo, QtyBase);

        // [WHEN] Invoke CalcQtyOnAssemblyBin function in codeunit 7314 with first Item No. and Lot No. as parameters.
        QtyInAsmBin := CalcQtyOnBin(Location, ItemNo[1], '', LotNo[1], '');

        // [THEN] The function returns 2 * Q (sum of 2 entries).
        Assert.AreEqual(QtyBase * ArrayLen(SerialNo), QtyInAsmBin, WrongQtyInAsmBinErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnAssemblyBinWithItemAndLotAndSerialNoFilter()
    var
        Location: Record Location;
        ItemNo: array[2] of Code[20];
        LotNo: array[2] of Code[20];
        SerialNo: array[2] of Code[20];
        QtyBase: Decimal;
        QtyInAsmBin: Decimal;
    begin
        // [SCENARIO 381763] Function CalcQtyOnAssemblyBin in codeunit 7314 should return sum of "Qty (Base)" for warehouse entries in assembly bin for a given item, lot and serial no.

        // [GIVEN] Location with "To-Assembly Bin Code".
        // [GIVEN] Warehouse entries on Location "L" for two items, each of them has two lots, for which there are two serial nos. Quantity of each entry = "Q".
        QtyBase := LibraryRandom.RandInt(10);
        MockLocation(Location, LibraryUtility.GenerateGUID());
        MockItemsLotsSerials(ItemNo, LotNo, SerialNo);
        MockWhseEntries(Location, ItemNo, LotNo, SerialNo, QtyBase);

        // [WHEN] Invoke CalcQtyOnAssemblyBin function in codeunit 7314 with first Item No., Lot No. and Serial No. as parameters.
        QtyInAsmBin := CalcQtyOnBin(Location, ItemNo[1], '', LotNo[1], SerialNo[1]);

        // [THEN] The function returns Q (one entry).
        Assert.AreEqual(QtyBase, QtyInAsmBin, WrongQtyInAsmBinErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderCanBeReleasedOnListPageInvokedFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        SalesOrder: TestPage "Sales Order";
        AssemblyOrders: TestPage "Assembly Orders";
    begin
        // [FEATURE] [Sales Order] [Assemble-to-Order] [UI]
        // [SCENARIO 205220] "Release" button pushed on Assembly Orders page invoked from a linked Sales Order should release opened Assembly Order.

        // [GIVEN] Sales Order with assemble-to-order line.
        // [GIVEN] Status on linked Assembly Order = "Open".
        CreateSalesLine(SalesHeader."Document Type"::Order, SalesHeader, SalesLine);
        CreateATOAssembly(SalesHeader."Document Type"::Order, AssemblyHeader, SalesLine);
        AssemblyHeader.Status := AssemblyHeader.Status::Open;
        AssemblyHeader.Modify();

        // [GIVEN] Navigate to the list of assembly orders from the sales order.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        AssemblyOrders.Trap();
        SalesOrder.AssemblyOrders.Invoke();

        // [WHEN] Push "Release" button on the assembly order list.
        AssemblyOrders.Release.Invoke();

        // [THEN] The Assembly Order is released.
        AssemblyHeader.Find();
        AssemblyHeader.TestField(Status, AssemblyHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderCanBeReopenedOnListPageInvokedFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        SalesOrder: TestPage "Sales Order";
        AssemblyOrders: TestPage "Assembly Orders";
    begin
        // [FEATURE] [Sales Order] [Assemble-to-Order] [UI]
        // [SCENARIO 205220] "Reopen" button pushed on Assembly Orders page invoked from a linked Sales Order should reopen released Assembly Order.

        // [GIVEN] Sales Order with assemble-to-order line.
        // [GIVEN] Status on linked Assembly Order = "Release".
        CreateSalesLine(SalesHeader."Document Type"::Order, SalesHeader, SalesLine);
        CreateATOAssembly(SalesHeader."Document Type"::Order, AssemblyHeader, SalesLine);

        // [GIVEN] Navigate to the list of assembly orders from the sales order.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        AssemblyOrders.Trap();
        SalesOrder.AssemblyOrders.Invoke();

        // [WHEN] Push "Reopen" button on the assembly order list.
        AssemblyOrders.Reopen.Invoke();

        // [THEN] The Assembly Order is open.
        AssemblyHeader.Find();
        AssemblyHeader.TestField(Status, AssemblyHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyToOrderFlagOnWhsePickLineCreatedViaPickWorksheet()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // [FEATURE] [Assemble-to-Order] [Pick] [Pick Worksheet]
        // [SCENARIO 254516] "Assemble to Order" and "ATO Component" flags are ON on warehouse pick line when you create pick via pick worksheet for assemble-to-order component.

        MockATOLink(AssembleToOrderLink);

        MockWhseWorksheetLine(
          WhseWorksheetLine,
          WhseWorksheetLine."Whse. Document Type"::Assembly, DATABASE::"Assembly Line",
          AssembleToOrderLink."Assembly Document Type".AsInteger(), AssembleToOrderLink."Assembly Document No.", '', 0);

        WarehouseActivityLine.TransferFromPickWkshLine(WhseWorksheetLine);

        WarehouseActivityLine.TestField("Assemble to Order", true);
        WarehouseActivityLine.TestField("ATO Component", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOComponentFlagOnWhsePickLineCreatedViaPickWorksheetForATOShipment()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // [FEATURE] [Assemble-to-Order] [Shipment] [Pick] [Pick Worksheet]
        // [SCENARIO 259567] "ATO Component" flag is TRUE on warehouse pick line when you create pick via pick worksheet for shipment with "Assemble-to-Order" = TRUE.

        MockATOLink(AssembleToOrderLink);
        MockWhseShipmentLine(WarehouseShipmentLine, true);

        MockWhseWorksheetLine(
          WhseWorksheetLine,
          WhseWorksheetLine."Whse. Document Type"::Shipment, DATABASE::"Sales Line",
          AssembleToOrderLink."Assembly Document Type".AsInteger(), AssembleToOrderLink."Assembly Document No.",
          WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.");

        WarehouseActivityLine.TransferFromPickWkshLine(WhseWorksheetLine);

        WarehouseActivityLine.TestField("Assemble to Order", true);
        WarehouseActivityLine.TestField("ATO Component", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOComponentFlagOnWhsePickLineCreatedViaPickWorksheetForNonATOShipment()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // [FEATURE] [Shipment] [Pick] [Pick Worksheet]
        // [SCENARIO 259567] "ATO Component" flag is FALSE on warehouse pick line when you create pick via pick worksheet for shipment with "Assemble-to-Order" = FALSE.

        MockATOLink(AssembleToOrderLink);
        MockWhseShipmentLine(WarehouseShipmentLine, false);

        MockWhseWorksheetLine(
          WhseWorksheetLine,
          WhseWorksheetLine."Whse. Document Type"::Shipment, DATABASE::"Sales Line",
          AssembleToOrderLink."Assembly Document Type".AsInteger(), AssembleToOrderLink."Assembly Document No.",
          WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.");

        WarehouseActivityLine.TransferFromPickWkshLine(WhseWorksheetLine);

        WarehouseActivityLine.TestField("Assemble to Order", false);
        WarehouseActivityLine.TestField("ATO Component", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateAssembleOrderForBlockedItem()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // [SCENARIO 271022] Assembly order cannot be created when item is blocked.

        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);

        AssemblyHeader.Init();
        asserterror AssemblyHeader.Validate("Item No.", Item."No.");

        Assert.ExpectedError('Blocked');
    end;

    [Test]
    procedure CannotCreateAssembleOrderForBlockedItemVariant()
    var
        ItemVariant: Record "Item Variant";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [SCENARIO] Assembly order cannot be created when item variant is blocked.

        // [GIVEN] Blocked Item Variant 
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [GIVEN] Assembly Header
        AssemblyHeader.Init();
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        AssemblyHeader.Validate("Item No.", ItemVariant."Item No.");

        // [WHEN] Blocked Variant Code is insert to variant code        
        asserterror AssemblyHeader.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Error 'Blocked must be No' is shown
        Assert.ExpectedTestFieldError(ItemVariant.FieldCaption(Blocked), Format(false));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure AssemblyBOMYesForItemWithAssemblyBOMItem()
    var
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Assembly BOM] [Item]
        // [SCENARIO 286199] "Assembly BOM" field value is TRUE when an Item from Assembly BOM has its own Assembly BOM of Item type.

        // [GIVEN] Add an Item to Assembly BOM of Item "I1".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(),
          BOMComponent.Type::Item, LibraryInventory.CreateItemNo(), 1, '');

        // [WHEN] Add Item "I1" to Assembly BOM of Item "I2".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(),
          BOMComponent.Type::Item, BOMComponent."Parent Item No.", 1, '');

        // [THEN] "Assembly BOM" field value for Assembly BOM line of "I2" is TRUE.
        BOMComponent.CalcFields("Assembly BOM");
        BOMComponent.TestField("Assembly BOM", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyBOMYesForItemWithAssemblyBOMResource()
    var
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Assembly BOM] [Item]
        // [SCENARIO 286199] "Assembly BOM" field value is TRUE when an Item from Assembly BOM has its own Assembly BOM of Resource type.

        // [GIVEN] Add a Resource to Assembly BOM of Item "I1".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(),
          BOMComponent.Type::Resource, LibraryResource.CreateResourceNo(), 1, '');

        // [WHEN] Add Item "I1" to Assembly BOM of Item "I2".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(),
          BOMComponent.Type::Item, BOMComponent."Parent Item No.", 1, '');

        // [THEN] "Assembly BOM" field value for Assembly BOM line of "I2" is TRUE.
        BOMComponent.CalcFields("Assembly BOM");
        BOMComponent.TestField("Assembly BOM", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyBOMNoForItemWithoutAssemblyBOM()
    var
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Assembly BOM] [Item]
        // [SCENARIO 286199] "Assembly BOM" field value is FALSE when an Item from Assembly BOM doesn't have its own Assembly BOM.

        // [WHEN] Add an Item without Assembly BOM to Assembly BOM of Item "I1".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(),
          BOMComponent.Type::Item, LibraryInventory.CreateItemNo(), 1, '');

        // [THEN] "Assembly BOM" field value for Assembly BOM line of "I1" is FALSE.
        BOMComponent.CalcFields("Assembly BOM");
        BOMComponent.TestField("Assembly BOM", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantTableRelationInPostedAssemblyHeader()
    var
        ItemVariant: Record "Item Variant";
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        // [SCENARIO 294619] Variant Code field in posted assembly header is related to Item Variant table by Item No. and Variant Code fields.

        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());

        PostedAssemblyHeader.Init();
        PostedAssemblyHeader."No." := LibraryUtility.GenerateGUID();
        PostedAssemblyHeader."Item No." := ItemVariant."Item No.";

        PostedAssemblyHeader.Validate("Variant Code", ItemVariant.Code);

        PostedAssemblyHeader.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSubstCanBeSelectedInAsmLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemSubstitution: Record "Item Substitution";
        ItemSubst: Codeunit "Item Subst.";
        ItemNo: Code[20];
    begin
        // [FEATURE] [UT] [Item Substitution Entries]
        // [SCENARIO 309436] When run ItemAssemblySubstGet in codeunit "Item Subst." then page Item Substitution Entries opens allowing Stan to select substitution

        // [GIVEN] Item had Item Substitution
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, ItemNo);

        // [GIVEN] Assembly Order had Line with the Item
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Quote;
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader.Insert();

        AssemblyLine.Init();
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        AssemblyLine."Line No." := LibraryUtility.GetNewRecNo(AssemblyLine, AssemblyLine.FieldNo("Line No."));
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine."No." := ItemNo;
        AssemblyLine.Insert();

        // [GIVEN] Ran ItemAssemblySubstGet in codeunit "Item Subst."
        ItemSubst.ItemAssemblySubstGet(AssemblyLine);

        // [GIVEN] Stan Selected Substitution on page Item Substitution Entries
        // [WHEN] Stan pushes OK
        // done in ItemSubstitutionEntriesModalPageHandler

        // [THEN] Assembly Line has No = Item Substitution "Substitute No."
        AssemblyLine.TestField("No.", ItemSubstitution."Substitute No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaterialVarianceAccountOnInvPostingSetupWithEssentialUX()
    var
        InventoryPostingSetup: TestPage "Inventory Posting Setup";
        InventoryPostingSetupCard: TestPage "Inventory Posting Setup Card";
    begin
        // [FEATURE] [Inventory Posting Setup] [UI]
        // [SCENARIO 318473] Material Variance Account is available on Inventory Posting Setup pages with Essential user experience, as it is required for posting an assembly of standard cost item.

        LibraryApplicationArea.EnableEssentialSetup();

        InventoryPostingSetup.OpenView();
        Assert.IsTrue(InventoryPostingSetup."Material Variance Account".Visible(), '');

        InventoryPostingSetupCard.OpenView();
        Assert.IsTrue(InventoryPostingSetupCard."Material Variance Account".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityVarianceAccountOnInvPostingSetupWithEssentialUX()
    var
        InventoryPostingSetup: TestPage "Inventory Posting Setup";
        InventoryPostingSetupCard: TestPage "Inventory Posting Setup Card";
    begin
        // [FEATURE] [Inventory Posting Setup] [UI]
        // [SCENARIO 372199] Capacity Variance Account is available on Inventory Posting Setup pages with Essential user experience, as it is required for posting an assembly of standard cost item.
        Initialize();

        // [GIVEN] Essentials setup is enabled.
        LibraryApplicationArea.EnableEssentialSetup();

        // [WHEN] Open Inventory Posting Setup list.
        // [THEN] "Capacity Variance Account" field is visible.
        InventoryPostingSetup.OpenView();
        Assert.IsTrue(InventoryPostingSetup."Capacity Variance Account".Visible(), '');

        // [WHEN] Open Inventory Posting Setup card.
        // [THEN] "Capacity Variance Account" field is visible.
        InventoryPostingSetupCard.OpenView();
        Assert.IsTrue(InventoryPostingSetupCard."Capacity Variance Account".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MfgOverheadVarianceAccountOnInvPostingSetupWithEssentialUX()
    var
        InventoryPostingSetup: TestPage "Inventory Posting Setup";
        InventoryPostingSetupCard: TestPage "Inventory Posting Setup Card";
    begin
        // [FEATURE] [Inventory Posting Setup] [UI]
        // [SCENARIO 372199] Mfg. Overhead Variance Account is available on Inventory Posting Setup pages with Essential user experience, as it is required for posting an assembly of standard cost item.
        Initialize();

        // [GIVEN] Essentials setup is enabled.
        LibraryApplicationArea.EnableEssentialSetup();

        // [WHEN] Open Inventory Posting Setup list.
        // [THEN] "Mfg. Overhead Variance Account" field is visible.
        InventoryPostingSetup.OpenView();
        Assert.IsTrue(InventoryPostingSetup."Mfg. Overhead Variance Account".Visible(), '');

        // [WHEN] Open Inventory Posting Setup card.
        // [THEN] "Mfg. Overhead Variance Account" field is visible.
        InventoryPostingSetupCard.OpenView();
        Assert.IsTrue(InventoryPostingSetupCard."Mfg. Overhead Variance Account".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapOverheadVarianceAccountOnInvPostingSetupWithEssentialUX()
    var
        InventoryPostingSetup: TestPage "Inventory Posting Setup";
        InventoryPostingSetupCard: TestPage "Inventory Posting Setup Card";
    begin
        // [FEATURE] [Inventory Posting Setup] [UI]
        // [SCENARIO 372199] Cap. Overhead Variance Account is available on Inventory Posting Setup pages with Essential user experience, as it is required for posting an assembly of standard cost item.
        Initialize();

        // [GIVEN] Essentials setup is enabled.
        LibraryApplicationArea.EnableEssentialSetup();

        // [WHEN] Open Inventory Posting Setup list.
        // [THEN] "Cap. Overhead Variance Account" field is visible.
        InventoryPostingSetup.OpenView();
        Assert.IsTrue(InventoryPostingSetup."Cap. Overhead Variance Account".Visible(), '');

        // [WHEN] Open Inventory Posting Setup card.
        // [THEN] "Cap. Overhead Variance Account" field is visible.
        InventoryPostingSetupCard.OpenView();
        Assert.IsTrue(InventoryPostingSetupCard."Cap. Overhead Variance Account".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWhseItemTrackingOnDeleteAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse]
        // [SCENARIO 360240] When you delete assembly line, the related whse. item tracking lines are deleted too.
        Initialize();
        LibraryAssembly.SetStockoutWarning(false);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, LibraryRandom.RandDate(30), '', 1);
        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        MockWhseItemTrackingLineForAsmLine(WhseItemTrackingLine, AssemblyLine);

        AssemblyLine.Delete(true);

        WhseItemTrackingLine.SetRecFilter();
        Assert.RecordIsEmpty(WhseItemTrackingLine);
    end;

    [Test]
    procedure ForceRereadAssemblyHeaderBeforeCheckStatus()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Assembly Header] [Assembly Line] [Status]
        // [SCENARIO 478238] Force reread of assembly header before checking status of assembly line.
        Initialize();
        LibraryAssembly.SetStockoutWarning(false);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, LibraryRandom.RandDate(30), '', 1);
        FindAssemblyLine(AssemblyLine, AssemblyHeader);
        AssemblyLine.TestStatusOpen();
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        asserterror AssemblyLine.TestStatusOpen();
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Status');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        IsInitialized := true;
    end;

    local procedure MockATOLink(var AssembleToOrderLink: Record "Assemble-to-Order Link")
    begin
        AssembleToOrderLink.Init();
        AssembleToOrderLink."Assembly Document Type" := AssembleToOrderLink."Assembly Document Type"::Order;
        AssembleToOrderLink."Assembly Document No." := LibraryUtility.GenerateGUID();
        AssembleToOrderLink.Insert();
    end;

    local procedure MockItemsLotsSerials(var ItemNo: array[2] of Code[20]; var LotNo: array[2] of Code[20]; var SerialNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(SerialNo) do
            SerialNo[i] := LibraryUtility.GenerateGUID();
    end;

    local procedure MockLocation(var Location: Record Location; ToAsmBinCode: Code[20])
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateGUID();
        Location."To-Assembly Bin Code" := ToAsmBinCode;
        Location.Insert();
    end;

    local procedure MockWhseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; IsATO: Boolean)
    begin
        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseShipmentLine, WarehouseShipmentLine.FieldNo("Line No."));
        WarehouseShipmentLine."Assemble to Order" := IsATO;
        WarehouseShipmentLine.Insert();
    end;

    local procedure MockWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocType: Enum "Warehouse Worksheet Document Type"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        WhseWorksheetLine.Init();
        WhseWorksheetLine."Whse. Document Type" := WhseDocType;
        WhseWorksheetLine."Source Type" := SourceType;
        WhseWorksheetLine."Source Subtype" := SourceSubtype;
        WhseWorksheetLine."Source No." := SourceNo;
        WhseWorksheetLine."Whse. Document No." := WhseDocNo;
        WhseWorksheetLine."Whse. Document Line No." := WhseDocLineNo;
    end;

    local procedure MockWhseEntries(Location: Record Location; ItemNo: array[2] of Code[20]; LotNo: array[2] of Code[20]; SerialNo: array[2] of Code[20]; QtyBase: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
        i: Integer;
        j: Integer;
        k: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do
            for j := 1 to ArrayLen(LotNo) do
                for k := 1 to ArrayLen(SerialNo) do begin
                    WarehouseEntry.Init();
                    WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
                    WarehouseEntry."Location Code" := Location.Code;
                    WarehouseEntry."Bin Code" := Location."To-Assembly Bin Code";
                    WarehouseEntry."Item No." := ItemNo[i];
                    WarehouseEntry."Lot No." := LotNo[j];
                    WarehouseEntry."Serial No." := SerialNo[k];
                    WarehouseEntry."Qty. (Base)" := QtyBase;
                    WarehouseEntry.Insert();
                end;
    end;

    local procedure MockWhseItemTrackingLineForAsmLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; AssemblyLine: Record "Assembly Line")
    begin
        WhseItemTrackingLine."Entry No." := LibraryUtility.GetNewRecNo(WhseItemTrackingLine, WhseItemTrackingLine.FieldNo("Entry No."));
        WhseItemTrackingLine."Source Type" := DATABASE::"Assembly Line";
        WhseItemTrackingLine."Source Subtype" := AssemblyLine."Document Type".AsInteger();
        WhseItemTrackingLine."Source ID" := AssemblyLine."Document No.";
        WhseItemTrackingLine."Source Ref. No." := AssemblyLine."Line No.";
        WhseItemTrackingLine.Insert();
    end;

    local procedure ReopenAReleasedAsmDoc(SalesDocType: Enum "Sales Document Type"; AsmDocReopens: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
    begin
        // SETUP: Create released ATO sales and assembly header
        CreateSalesLine(SalesDocType, SalesHeader, SalesLine);
        CreateATOAssembly(SalesDocType, AsmHeader, SalesLine);

        // EXERCISE - reopen
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // VERIFY - status is same if no change, otherwise released
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        if AsmDocReopens then
            Assert.AreEqual(AsmHeader.Status::Open, AsmHeader.Status, 'The status is open as doc has been reopened.')
        else
            Assert.AreEqual(AsmHeader.Status::Released, AsmHeader.Status, 'The status is not changed from released.');
    end;

    local procedure CreateSalesLine(SalesDocType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesHeader."Document Type" := SalesDocType;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Insert();

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Insert();
    end;

    local procedure CreateATOAssembly(SalesDocType: Enum "Sales Document Type"; var AsmHeader: Record "Assembly Header"; SalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        AsmLine: Record "Assembly Line";
    begin
        case SalesDocType of
            SalesLine."Document Type"::Quote:
                AsmHeader."Document Type" := AsmHeader."Document Type"::Quote;
            SalesLine."Document Type"::"Blanket Order":
                AsmHeader."Document Type" := AsmHeader."Document Type"::"Blanket Order";
            SalesLine."Document Type"::Order:
                AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        end;
        AsmHeader."No." := LibraryUtility.GenerateGUID();
        AsmHeader.Status := AsmHeader.Status::Released;
        AsmHeader.Insert();

        // make ATO Link
        ATOLink."Assembly Document Type" := AsmHeader."Document Type";
        ATOLink."Assembly Document No." := AsmHeader."No.";
        ATOLink.Type := ATOLink.Type::Sale;
        ATOLink."Document Type" := SalesLine."Document Type";
        ATOLink."Document No." := SalesLine."Document No.";
        ATOLink."Document Line No." := SalesLine."Line No.";
        ATOLink.Insert();

        // make assembly line to avoid error "Nothing to Release"
        AsmLine."Document Type" := AsmHeader."Document Type";
        AsmLine."Document No." := AsmHeader."No.";
        AsmLine.Type := AsmLine.Type::Item;
        AsmLine.Quantity := 1;
        AsmLine.Insert();
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure SetupFullATOPostedCheckWarehouseShpt(var ATSWhseShptLine: Record "Warehouse Shipment Line"; SalesLineQty: Integer; SalesLineQtyToAsm: Integer; SalesLineQtyShipped: Integer; ATOQtyToShip: Integer; ATSQtyToShip: Integer; ATOandATSinDiffShip: Boolean)
    var
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        SalesLine."Quantity (Base)" := SalesLineQty;
        SalesLine."Qty. to Asm. to Order (Base)" := SalesLineQtyToAsm;
        SalesLine."Qty. Shipped (Base)" := SalesLineQtyShipped;
        SalesLine."Line No." := 10000;
        SalesLine.Insert();

        ATSWhseShptLine."No." := LibraryUtility.GenerateRandomCode(ATSWhseShptLine.FieldNo("No."), DATABASE::"Warehouse Shipment Line");
        ATSWhseShptLine."Line No." := 10000;
        ATSWhseShptLine."Source Document" := ATSWhseShptLine."Source Document"::"Sales Order";
        ATSWhseShptLine."Source Type" := 37;
        ATSWhseShptLine."Source Subtype" := ATSWhseShptLine."Source Subtype"::"1";
        ATSWhseShptLine."Source No." := SalesLine."Document No.";
        ATSWhseShptLine."Source Line No." := 10000;
        ATSWhseShptLine."Qty. to Ship (Base)" := ATSQtyToShip;
        ATSWhseShptLine."Assemble to Order" := false;
        ATSWhseShptLine.Insert();

        // ATO already shipped
        if SalesLineQtyShipped = SalesLineQtyToAsm then
            exit;

        ATOWhseShptLine := ATSWhseShptLine;
        if ATOandATSinDiffShip then
            ATOWhseShptLine."No." := LibraryUtility.GenerateRandomCode(ATOWhseShptLine.FieldNo("No."), DATABASE::"Warehouse Shipment Line");
        ATOWhseShptLine."Line No." := 20000;
        ATOWhseShptLine."Qty. to Ship (Base)" := ATOQtyToShip;
        ATOWhseShptLine."Assemble to Order" := true;
        ATOWhseShptLine.Insert();
    end;

    local procedure NoWarningForDueDateWhenEndDateChangesOnATO(ChangeInDays: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        OldStartDate: Date;
    begin
        // Based on VSTF 323583

        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        WarningForDueDateWhenEndDateChangeMakeATO(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldStartDate := AssemblyHeader."Starting Date";

        // EXERCISE
        AssemblyHeader."Ending Date" += ChangeInDays; // change Ending Date by given value.
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Ending Date"), false);

        // VERIFY
        Assert.AreEqual(OldDueDate, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldStartDate + ChangeInDays, AssemblyHeader."Starting Date", AssemblyHeader.FieldCaption("Starting Date"));
    end;

    local procedure NoWarningForDueDateWhenStartDateChangesOnATO(ChangeInDays: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        OldEndDate: Date;
    begin
        // Based on VSTF 323583

        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        WarningForDueDateWhenEndDateChangeMakeATO(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldEndDate := AssemblyHeader."Ending Date";

        // EXERCISE
        AssemblyHeader."Starting Date" += ChangeInDays; // change Ending Date by given value.
        DatesChangedConfirmHandlerQuestion := StrSubstNo(UpdateEndingDateQst, OldEndDate, OldEndDate + ChangeInDays);
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Starting Date"), false);

        // VERIFY
        Assert.AreEqual(OldDueDate, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldEndDate + ChangeInDays, AssemblyHeader."Ending Date", AssemblyHeader.FieldCaption("Ending Date"));
    end;

    local procedure WarningForDueDateWhenEndDateChangeMakeATSSetup(var AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
    begin
        // Make the Assembly Order with dates having 1D difference
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := LibraryUtility.GenerateRandomCode(AssemblyHeader.FieldNo("No."), DATABASE::"Assembly Header");
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        Evaluate(Item."Lead Time Calculation", '<+1D>');
        Evaluate(Item."Safety Lead Time", '<+1D>');
        Item.Insert();
        AssemblyHeader."Item No." := Item."No.";
        AssemblyHeader."Starting Date" := WorkDate();
        AssemblyHeader."Ending Date" := CalcDate(Item."Lead Time Calculation", AssemblyHeader."Starting Date");
        AssemblyHeader."Due Date" := CalcDate(Item."Safety Lead Time", AssemblyHeader."Ending Date");
        AssemblyHeader.Insert();
    end;

    local procedure WarningForDueDateWhenEndDateChangeMakeATO(AssemblyHeader: Record "Assembly Header")
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // Mark the order as A-T-O
        AssembleToOrderLink.Init();
        AssembleToOrderLink."Assembly Document Type" := AssemblyHeader."Document Type";
        AssembleToOrderLink."Assembly Document No." := AssemblyHeader."No.";
        AssembleToOrderLink.Insert();
    end;

    local procedure WarningForDueDateWhenEndDateChangesOnATS(ChangeInDays: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        OldStartDate: Date;
    begin
        // Based on VSTF 323583

        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldStartDate := AssemblyHeader."Starting Date";

        // EXERCISE
        AssemblyHeader."Ending Date" += ChangeInDays; // change Ending Date by given value.
        DatesChangedConfirmHandlerQuestion := StrSubstNo(UpdateDueDateQst, OldDueDate, OldDueDate + ChangeInDays);
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Ending Date"), false);

        // VERIFY
        Assert.AreEqual(OldDueDate + ChangeInDays, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldStartDate + ChangeInDays, AssemblyHeader."Starting Date", AssemblyHeader.FieldCaption("Starting Date"));
    end;

    local procedure WarningForDueDateWhenStartDateChangesOnATS(ChangeInDays: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        OldDueDate: Date;
        OldEndDate: Date;
    begin
        // Based on VSTF 323583

        // SETUP
        WarningForDueDateWhenEndDateChangeMakeATSSetup(AssemblyHeader);
        OldDueDate := AssemblyHeader."Due Date";
        OldEndDate := AssemblyHeader."Ending Date";

        // EXERCISE
        AssemblyHeader."Starting Date" += ChangeInDays; // change Ending Date by given value.
        DatesChangedConfirmHandlerQuestion :=
          StrSubstNo(UpdateEndingAndDueDateQst, OldEndDate, OldEndDate + ChangeInDays, OldDueDate, OldDueDate + ChangeInDays);
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Starting Date"), false);

        // VERIFY
        Assert.AreEqual(OldDueDate + ChangeInDays, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));
        Assert.AreEqual(OldEndDate + ChangeInDays, AssemblyHeader."Ending Date", AssemblyHeader.FieldCaption("Ending Date"));
    end;

    local procedure CalcQtyOnBin(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        exit(
            WarehouseAvailabilityMgt.CalcQtyOnBin(
                Location.Code, Location."To-Assembly Bin Code", ItemNo, VariantCode, WhseItemTrackingSetup));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesModalPageHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.First();
        ItemSubstitutionEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DatesChangedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(DatesChangedConfirmHandlerQuestion, Question);
        Reply := true;
    end;
}

