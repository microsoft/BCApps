// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Setup;
using Microsoft.Assembly.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Item;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using Microsoft.Purchases.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Setup;

codeunit 137095 "SCM Kitting - Reservations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reservation] [SCM]
        isInitialized := false;
    end;

    var
        InventorySetup: Record "Inventory Setup";
        AssemblySetup: Record "Assembly Setup";
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;
        GlobalSupplyType: Option "Purchase Order","Assembly Order","Released Production Order","Firm Planned Production Order";
        ErrorChangeLine: Label '%1 must not be changed when a quantity is reserved in Assembly Line Document Type';
        ErrorInventory: Label 'is not on inventory.';
        ErrorResAlways: Label 'Automatic reservation is not possible.';
        GlobalILESupply: Decimal;
        GlobalPOSupply: Decimal;
        GlobalAOSupply: Decimal;
        GlobalSupply: Decimal;
        GlobalCancelReservation: Boolean;
        GlobalSourceType: Integer;
        ErrorResNever: Label 'Reserve must not be Never in Assembly Line:';
        ErrorCancelRes: Label 'Do you want to cancel all reservations';
        ErrorInsufSupply: Label 'Full automatic Reservation is not possible';
        GlobalReserveTwice: Boolean;
        ErrorFullyReserved: Label 'Fully reserved.';
        ErrorNotAvail: Label 'There is nothing available to reserve.';
        WorkDate2: Date;
        MsgDueDateBeforeWorkDate: Label 'before work date';

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Reservations");
        // Initialize setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Reservations");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Vendor Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
        LibraryAssembly.UpdateAssemblySetup(
          AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header", LibraryUtility.GetGlobalNoSeriesCode());

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Reservations");
    end;

    [Test]
    [HandlerFunctions('ResPageHandler,ResEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ShowItem()
    begin
        ShowReservationPages(AssemblyLine.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowResource()
    begin
        ShowReservationPages(AssemblyLine.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowText()
    begin
        ShowReservationPages(AssemblyLine.Type::" ");
    end;

    local procedure ShowReservationPages(LineType: Enum "BOM Component Type")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Setup. Create Assembly structure.
        Initialize();
        SetupAssemblyData(AssemblyHeader, WorkDate2);

        // Exercise. Find a random Assembly Component Line of the specified type.
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, LineType);
        AssemblyLine.Next(LibraryRandom.RandInt(AssemblyLine.Count));

        // Try to open the Reservation and the Reservation Entries page.
        // Validate: Pages are raised according to the test function handler.
        AssemblyLine.ShowReservation();
        AssemblyLine.ShowReservationEntries(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure SetupAssemblyData(var AssemblyHeader: Record "Assembly Header"; DueDate: Date)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Modify(true);

        LibraryAssembly.CreateAssemblyList(
          Item."Costing Method"::Standard, Item."No.", true, 1, 1, 1, 1, Item."Gen. Prod. Posting Group", '');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, Item."No.", '', LibraryRandom.RandDec(10, 2), '');
    end;

    local procedure TestAutoReserve(Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailToReserve: Decimal;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve,
          ExcessSupply, FilterOnVariant, FilterOnLocation, DueDateDelay, 2);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");

        // Exercise: Auto reserve.
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);
        NotificationLifecycleMgt.RecallAllNotifications();
        exit(AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveOptional()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveNever()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Never, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveAlways()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Always, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExcessSupply()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsufficientSupply()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, -LibraryRandom.RandIntInRange(7, 50), false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateBefore()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, 0, false, false, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DifferentLocation()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, 0, false, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DifferentVariant()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, 0, true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DifferentVarAndLoc()
    begin
        // [FEATURE] [Auto Reserve]
        TestAutoReserve(Item.Reserve::Optional, 0, true, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOptional()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        RemainingResQty: Decimal;
        ItemNo: Code[20];
        InitialResQty: Decimal;
        InitialInventory: Decimal;
    begin
        // Setup: Create an Assembly Order with reservations for components. The order must be posted partially.
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, TestAutoReserve(Item.Reserve::Optional, 0, false, false, 0));
        AssemblyHeader.Validate("Quantity to Assemble (Base)", AssemblyHeader."Quantity (Base)" - 1);
        AssemblyHeader.Modify(true);
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        // Identify the Assembly Lines containing reservations.
        // Prepare the lines for posting.
        if AssemblyLine.FindSet() then
            repeat
                Item.Get(AssemblyLine."No.");
                Item.CalcFields(Inventory);
                AssemblyLine.Validate("Quantity to Consume", Item.Inventory / AssemblyLine."Qty. per Unit of Measure");
                AssemblyLine.Modify(true);
                AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                if AssemblyLine."Reserved Quantity" > 0 then begin
                    ItemNo := AssemblyLine."No.";
                    InitialResQty := AssemblyLine."Reserved Qty. (Base)";
                    InitialInventory := Item.Inventory;
                end;
            until AssemblyLine.Next() = 0;

        // Exercise: Post reservations.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Validate: Reservations are eliminated.
        ReservationEntry.Reset();
        ReservationEntry.SetRange(Positive, false);
        ReservationEntry.SetRange("Source Type", 901);
        ReservationEntry.SetRange("Source ID", AssemblyHeader."No.");
        ReservationEntry.SetRange("Item No.", ItemNo);

        if InitialResQty > InitialInventory then
            if ReservationEntry.FindSet() then begin
                repeat
                    RemainingResQty += Abs(ReservationEntry."Quantity (Base)");
                until ReservationEntry.Next() = 0;
                Assert.AreNearlyEqual(InitialResQty - InitialInventory, RemainingResQty, LibraryERM.GetAmountRoundingPrecision(),
                  'Remaining reserved quantity is not correct.');
            end
            else
                Assert.Fail('Reservation entry are expected when the initial res. qty ' + Format(InitialResQty) + ' is higher than ' +
                  Format(InitialInventory))
        else
            Assert.AreEqual(0, ReservationEntry.Count, 'There shouldn''t be any reservation entries left.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure TestNormalReserve(ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean)
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        TrackingSpecification: Record "Tracking Specification";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AvailToReserve: Decimal;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional,
          ExcessSupply, FilterOnVariant, FilterOnLocation, 0, 2);

        // Exercise: Reserve for current assembly line, using all available supply lines.
        if TempReservationEntry.FindSet() then
            repeat
                TrackingSpecification.InitTrackingSpecification(
                  TempReservationEntry."Source Type",
                  TempReservationEntry."Source Subtype",
                  TempReservationEntry."Source ID",
                  '', 0, TempReservationEntry."Source Ref. No.",
                  TempReservationEntry."Variant Code",
                  TempReservationEntry."Location Code",
                  TempReservationEntry."Qty. per Unit of Measure");
                AssemblyLineReserve.CreateReservationSetFrom(TrackingSpecification);

                // If we are expecting not to be able to create a reservation.
                if TempReservationEntry."Quantity (Base)" = 0 then
                    asserterror
                      AssemblyLineReserve.CreateBindingReservation(
                        AssemblyLine,
                        AssemblyLine.Description,
                        TempReservationEntry."Expected Receipt Date",
                        Round(TempReservationEntry."Qty. to Handle (Base)" / TempReservationEntry."Qty. per Unit of Measure", 0.00001),
                        TempReservationEntry."Qty. to Handle (Base)")
                // For reservation entries where expected qty. to reserve is 0, use supply qty to attempt reservation.
                else
                    AssemblyLineReserve.CreateBindingReservation(
                      AssemblyLine,
                      AssemblyLine.Description,
                      TempReservationEntry."Expected Receipt Date",
                      TempReservationEntry.Quantity,
                      TempReservationEntry."Quantity (Base)");
                Commit();
            until TempReservationEntry.Next() = 0;

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLineExcessSupply()
    begin
        TestNormalReserve(LibraryRandom.RandIntInRange(7, 50), false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLineInsuffSupply()
    begin
        TestNormalReserve(-LibraryRandom.RandIntInRange(7, 50), false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLineDifferentLocation()
    begin
        TestNormalReserve(0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLineDifferentVariant()
    begin
        TestNormalReserve(0, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLineDifferentVarAndLoc()
    begin
        TestNormalReserve(0, true, true);
    end;

    [Normal]
    local procedure TestFindHeaderRes(FilterOnLocation: Boolean; FilterOnVariant: Boolean; DueDateDelay: Integer)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        FullAutoReservation: Boolean;
        AvailToReserve: Decimal;
        Multiplicity: Integer;
    begin
        // Setup Reservations.
        // If negative scenarios, do not create available supply.
        if FilterOnLocation or FilterOnVariant or (DueDateDelay <> 0) then
            Multiplicity := 0
        else
            Multiplicity := 1;

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional,
          0, FilterOnVariant, FilterOnLocation, DueDateDelay, Multiplicity);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");

        // Exercise: Auto reserve.
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Validate: Reservation functions in CU925.
        TempReservationEntry.SetRange("Source Type", 900);
        TempReservationEntry.FindFirst();
        AssemblyHeader.Get(AssemblyLine."Document Type", TempReservationEntry."Source ID");

        if FilterOnLocation or FilterOnVariant or (DueDateDelay <> 0) then begin
            Assert.IsFalse(AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservationEntry), 'FindResEnt,Item:' + AssemblyLine."No.");
            Assert.IsFalse(AssemblyHeaderReserve.ReservEntryExist(AssemblyHeader), 'ReservEntryExist,Item: ' + AssemblyLine."No.");
            Assert.IsTrue(ReservationEntry.IsEmpty, 'Item: ' + AssemblyLine."No.");
        end else begin
            Assert.IsTrue(
              AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservationEntry), 'FindResEntry,Item:' + AssemblyLine."No.");
            Assert.IsTrue(AssemblyHeaderReserve.ReservEntryExist(AssemblyHeader), 'ReservEntryExist, Item:' + AssemblyLine."No.");
            Assert.IsFalse(ReservationEntry.IsEmpty, 'Item: ' + AssemblyLine."No.");
        end;

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderResSunshine()
    begin
        TestFindHeaderRes(false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderResDiffLocation()
    begin
        TestFindHeaderRes(true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderResDiffVariant()
    begin
        TestFindHeaderRes(false, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderResDueDateBefore()
    begin
        TestFindHeaderRes(false, false, 5);
    end;

    [Normal]
    local procedure TestFindLineRes(FilterOnLocation: Boolean; FilterOnVariant: Boolean; DueDateDelay: Integer)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        FullAutoReservation: Boolean;
        AvailToReserve: Decimal;
        Multiplicity: Integer;
    begin
        // Setup Reservations.
        // If negative scenarios, do not create available supply.
        if FilterOnLocation or FilterOnVariant or (DueDateDelay <> 0) then
            Multiplicity := 0
        else
            Multiplicity := 1;

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional,
          0, FilterOnVariant, FilterOnLocation, DueDateDelay, Multiplicity);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");

        // Exercise: Auto reserve.
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Validate: Reservation functions in CU926.
        if FilterOnLocation or FilterOnVariant or (DueDateDelay <> 0) then begin
            Assert.IsFalse(
              AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservationEntry), 'FindReservEntry,Item:' + AssemblyLine."No.");
            Assert.IsFalse(AssemblyLineReserve.ReservEntryExist(AssemblyLine), 'ReservEntryExist,Item:' + AssemblyLine."No.");
            Assert.IsTrue(ReservationEntry.IsEmpty, 'Item: ' + AssemblyLine."No.");
        end else begin
            Assert.IsTrue(
              AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservationEntry), 'FindReservEntry,Item: ' + AssemblyLine."No.");
            Assert.IsTrue(AssemblyLineReserve.ReservEntryExist(AssemblyLine), 'ReservEntryExist,Item: ' + AssemblyLine."No.");
            Assert.IsFalse(ReservationEntry.IsEmpty, 'ReservEntryExist,Item: ' + AssemblyLine."No.");
        end;

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineResSunshine()
    begin
        TestFindLineRes(false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineResDiffLocation()
    begin
        TestFindLineRes(false, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineResDueDateBefore()
    begin
        TestFindHeaderRes(false, false, 5);
    end;

    [Normal]
    local procedure TestUIAutoReserve(Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        AvailToReserve: Decimal;
    begin
        // Setup Reservations.
        Initialize();

        LibraryNotificationMgt.DisableMyNotification(ItemCheckAvail.GetItemAvailabilityNotificationId());

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve,
          ExcessSupply, FilterOnVariant, FilterOnLocation, DueDateDelay, 2);

        // No action is expected in this test for Items with Reserve <> Always.
        if Reserve <> Item.Reserve::Always then begin
            AvailToReserve := 0;
            TempReservationEntry.DeleteAll();
        end else
            AssemblyLine.Delete(true);

        // Exercise: Auto reserve record using the page triggers.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        AssemblyLine.TestField("Reserved Qty. (Base)", 0);

        AddAssemblyLineOnPage(AssemblyLine);

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveOptional()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Optional, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveNever()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Never, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveAlways()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, 0, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoExcessSupply()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, LibraryRandom.RandIntInRange(7, 50), false, false, 0);
    end;

    [Test]
    [HandlerFunctions('PartialResConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure AutoInsufficientSupply()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), false, false, 0);
    end;

    [Test]
    [HandlerFunctions('PartialResConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure AutoInsSupplyLocation()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), false, true, 0);
    end;

    [Test]
    [HandlerFunctions('PartialResConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure AutoInsSupplyVariant()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoDueDateBefore()
    begin
        TestUIAutoReserve(Item.Reserve::Always, 0, false, false, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoDifferentLocation()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, 0, false, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoDifferentVariant()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, 0, true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoDifferentVarAndLoc()
    begin
        // [FEATURE] [Auto Reserve]
        TestUIAutoReserve(Item.Reserve::Always, 0, true, true, 0);
    end;

    [Normal]
    local procedure TestUIAvailToReserve(Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer; ReserveTwice: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        AvailToReserve: Decimal;
        Qty: Decimal;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve,
          ExcessSupply, FilterOnVariant, FilterOnLocation, DueDateDelay, 2);

        // Exercise: Auto reserve record using the page triggers.
        GlobalILESupply := GetTotalAvailSupply(
            TempReservationEntry, Qty, AssemblyLine."Location Code", AssemblyLine."Variant Code", AssemblyLine."Due Date", 32);
        GlobalPOSupply := GetTotalAvailSupply(
            TempReservationEntry, Qty, AssemblyLine."Location Code", AssemblyLine."Variant Code", AssemblyLine."Due Date", 39);
        GlobalAOSupply := GetTotalAvailSupply(
            TempReservationEntry, Qty, AssemblyLine."Location Code", AssemblyLine."Variant Code", AssemblyLine."Due Date", 900);
        GlobalReserveTwice := ReserveTwice;

        AssemblyLine.ShowReservation();
        // Reservation page handler is triggered.

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveOptional()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 0, false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveAlways()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Always, 0, false, false, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailToReserveNever()
    begin
        // [FEATURE] [Available to Reserve]
        asserterror
          TestUIAvailToReserve(Item.Reserve::Never, 0, false, false, 0, false);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorResNever) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveExcessSupply()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 10, false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,InsufSupplyMessagHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveInsufSupply()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, -10, false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveLocation()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 0, false, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveVariant()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 0, true, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveVarLoc()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 0, true, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveDueDate()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, 0, false, false, 5, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,InsufSupplyMessagHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveInsufLocation()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, -10, false, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,InsufSupplyMessagHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveInsufVariant()
    begin
        // [FEATURE] [Available to Reserve]
        TestUIAvailToReserve(Item.Reserve::Optional, -10, true, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('AvailToResModalHandler,AvailILEModalHandler,AvailPOModalHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure AvailToReserveNegativeFullyRes()
    begin
        // [FEATURE] [Available to Reserve]
        asserterror
          TestUIAvailToReserve(Item.Reserve::Optional, 0, false, false, 0, true);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorFullyReserved) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Normal]
    local procedure TestUIReserveCancel(FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer; CancelReservation: Boolean; SourceType: Integer; ReserveTwice: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        AvailToReserve: Decimal;
        Qty: Decimal;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional, 0,
          FilterOnVariant, FilterOnLocation, DueDateDelay, 1);
        GlobalCancelReservation := CancelReservation;
        GlobalSourceType := SourceType;

        // Exercise: Auto reserve record using the page triggers.
        GlobalSupply := GetTotalAvailSupply(TempReservationEntry, Qty, AssemblyLine."Location Code",
            AssemblyLine."Variant Code", AssemblyLine."Due Date", SourceType);
        GlobalReserveTwice := ReserveTwice;

        AssemblyLine.ShowReservation();
        // Reservation page handler is triggered.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveLocationILE()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, true, 0, false, 32, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVariantILE()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, false, 0, false, 32, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveDueDateILE()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, false, 5, false, 32, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVarLocILE()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, false, 32, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveLocationPO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, true, 0, false, 39, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVariantPO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, false, 0, false, 39, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveDueDatePO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, false, 5, false, 39, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVarLocPO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, false, 39, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveLocationAO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, true, 0, false, 900, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVariantAO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, false, 0, false, 900, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveDueDateAO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(false, false, 5, false, 900, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveVarLocAO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, false, 900, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler,CancelResConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelAO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, true, 900, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler,CancelResConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPO()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, true, 39, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler,CancelResConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelILE()
    begin
        // [FEATURE] [Cancel Reservation]
        TestUIReserveCancel(true, true, 0, true, 32, false);
    end;

    [Test]
    [HandlerFunctions('ReserveCancelModalHandler')]
    [Scope('OnPrem')]
    procedure NegativeReserveILETwice()
    begin
        // [FEATURE] [Cancel Reservation]
        asserterror
          TestUIReserveCancel(false, true, 0, false, 32, true);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorNotAvail) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Normal]
    local procedure TestChangeLine(AssemblyLineFieldNo: Integer; PositiveTest: Boolean; ExcessSupply: Decimal; SupplyDelayFactor: Integer; Multiplicity: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservMgt: Codeunit "Reservation Management";
        NewFieldValue: Variant;
        AvailToReserve: Decimal;
        DueDateDelay: Integer;
        FullAutoReservation: Boolean;
    begin
        // Setup Reservations.
        // If Due Date is changed, ensure supply outside the initial filters is created.
        if (AssemblyLine.FieldNo("Due Date") = AssemblyLineFieldNo) and PositiveTest then
            DueDateDelay := 30;

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional, ExcessSupply,
          AssemblyLine.FieldNo("Variant Code") = AssemblyLineFieldNo,
          AssemblyLine.FieldNo("Location Code") = AssemblyLineFieldNo,
          DueDateDelay, Multiplicity);

        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Exercise: Update Assembly Line.
        SetSupplyFilters(NewFieldValue, TempReservationEntry, AssemblyLine, AssemblyLineFieldNo, PositiveTest,
          SupplyDelayFactor * LibraryRandom.RandInt(DueDateDelay));
        UpdateAssemblyLine(AssemblyLine, AssemblyLineFieldNo, NewFieldValue);

        // Update TempReservationEntry based on the new line, using SetQtyToReserve.
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        UpdateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine);

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        // If no eligible supply was created initially, we don't expect any reservation to be made after the line change.
        if Multiplicity = 0 then begin
            TempReservationEntry.Reset();
            TempReservationEntry.DeleteAll();
            AvailToReserve := 0;
        end;

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateLocationPosOptional()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Location Code"), true, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateLocationPosOptPartial()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Location Code"), true, -LibraryRandom.RandIntInRange(7, 50), 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateLocationNegOptional()
    begin
        asserterror
          TestChangeLine(AssemblyLine.FieldNo("Location Code"), false, 0, 0, 1);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorChangeLine, 'Location Code')) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVariantPosOptional()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Variant Code"), true, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVariantPosOptPartial()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Variant Code"), true, -LibraryRandom.RandIntInRange(7, 50), 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVariantNegOptional()
    begin
        asserterror
          TestChangeLine(AssemblyLine.FieldNo("Variant Code"), false, 0, 0, 1);
        Assert.ExpectedTestFieldError(AssemblyLine.FieldCaption("Reserved Quantity"), Format(0));
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdDueDatePosOptUnavailSupply()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Due Date"), true, 0, -1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdDueDatePosOptAvailSupply()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Due Date"), true, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDate')]
    [Scope('OnPrem')]
    procedure UpdateDueDateNegOptional()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Due Date"), false, 0, 1, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateTypeNegOptional()
    begin
        // Bug in VerifyChange: xRec.Type <> Rec.Type is not handled.
        asserterror
          TestChangeLine(AssemblyLine.FieldNo(Type), false, 0, 0, 1);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorChangeLine, 'Type')) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateNoNegOptional()
    begin
        asserterror
          TestChangeLine(AssemblyLine.FieldNo("No."), false, 0, 0, 1);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorChangeLine, 'No.')) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Normal]
    local procedure TestChangeLineQty(Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; NewQtyDelta: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservMgt: Codeunit "Reservation Management";
        AvailToReserve: Decimal;
        FullAutoReservation: Boolean;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve, ExcessSupply, false, false, 0, 2);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Exercise: Update Assembly Line.
        UpdateAssemblyLine(AssemblyLine, AssemblyLine.FieldNo("Quantity (Base)"), AssemblyLine."Quantity (Base)" + NewQtyDelta);

        // Update TempReservationEntry based on the new line, using SetQtyToReserve.
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        if (NewQtyDelta < 0) or ((Reserve <> Item.Reserve::Optional) and (NewQtyDelta > 0)) then
            UpdateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine);

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncrQtyFullyResOptional()
    var
        ExcessSupply: Decimal;
    begin
        ExcessSupply := LibraryRandom.RandIntInRange(7, 50);
        TestChangeLineQty(Item.Reserve::Optional, ExcessSupply, LibraryRandom.RandInt(ExcessSupply - 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncrQtyPartialResOptional()
    var
        ExcessSupply: Decimal;
    begin
        ExcessSupply := LibraryRandom.RandIntInRange(7, 50);
        TestChangeLineQty(Item.Reserve::Optional, ExcessSupply, ExcessSupply + LibraryRandom.RandInt(25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecrQtyAboveAvailOptional()
    var
        ExcessSupply: Decimal;
    begin
        ExcessSupply := LibraryRandom.RandIntInRange(7, 50);
        TestChangeLineQty(Item.Reserve::Optional, -ExcessSupply, -LibraryRandom.RandInt(ExcessSupply - 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecrQtyBelowAvailOptional()
    var
        ExcessSupply: Decimal;
    begin
        ExcessSupply := LibraryRandom.RandIntInRange(7, 50);
        TestChangeLineQty(Item.Reserve::Optional, -ExcessSupply, -ExcessSupply - LibraryRandom.RandInt(25));
    end;

    [Normal]
    local procedure TestDeleteLine(Reserve: Enum "Reserve Method")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailToReserve: Decimal;
    begin
        // Setup Reservations.
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve, 0, false, false, 0, 2);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Exercise: Update Assembly Line.
        AssemblyLine.Delete(true);
        AvailToReserve := 0;
        TempReservationEntry.DeleteAll();

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLineOptional()
    begin
        TestDeleteLine(Item.Reserve::Optional);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLineAlways()
    begin
        TestDeleteLine(Item.Reserve::Always);
    end;

    [Normal]
    local procedure TestChangeHeader(AssemblyHeaderFieldNo: Integer; PositiveTest: Boolean; ExcessSupply: Decimal; SupplyDelayFactor: Integer; Multiplicity: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ReservMgt: Codeunit "Reservation Management";
        NewFieldValue: Variant;
        AvailToReserve: Decimal;
        DueDateDelay: Integer;
        FullAutoReservation: Boolean;
    begin
        // Setup Reservations.
        // If Due Date is changed, ensure supply outside the initial filters is created.
        if (AssemblyHeader.FieldNo("Due Date") = AssemblyHeaderFieldNo) and PositiveTest then
            DueDateDelay := 30;

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Item.Reserve::Optional, ExcessSupply,
          false, AssemblyHeader.FieldNo("Location Code") = AssemblyHeaderFieldNo, DueDateDelay, Multiplicity);

        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        // Exercise: Update Assembly Header.
        SetHeaderSupplyFilters(NewFieldValue, TempReservationEntry, AssemblyHeader, AssemblyHeaderFieldNo, PositiveTest,
          SupplyDelayFactor * LibraryRandom.RandInt(DueDateDelay));
        UpdateAssemblyHeader(AssemblyHeader, AssemblyHeaderFieldNo, NewFieldValue);

        // Update TempReservationEntry based one the new line, using SetQtyToReserve.
        if (Multiplicity = 0) or (AssemblyHeaderFieldNo = AssemblyHeader.FieldNo("Item No."))
        then begin
            TempReservationEntry.Reset();
            TempReservationEntry.DeleteAll();
            AvailToReserve := 0;
        end
        else
            if (not PositiveTest) and (AssemblyHeaderFieldNo = AssemblyHeader.FieldNo(Quantity)) then begin
                AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
                UpdateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine);
            end;

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        AssemblyLine.TestField("Reserved Quantity", AssemblyLine."Reserved Qty. (Base)" * AssemblyLine."Qty. per Unit of Measure");
        VerifyReservationEntries(TempReservationEntry, AssemblyLine);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdHdrLocationPosOptional()
    begin
        TestChangeHeader(AssemblyHeader.FieldNo("Location Code"), true, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdHdrLocationPosOptPartial()
    begin
        TestChangeHeader(AssemblyHeader.FieldNo("Location Code"), true, -LibraryRandom.RandIntInRange(7, 50), 0, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdHdrLocationNegOptional()
    begin
        asserterror
          TestChangeHeader(AssemblyHeader.FieldNo("Location Code"), false, 0, 0, 1);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorChangeLine, 'Location Code')) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdHdrDDatePosOptUnavailSupply()
    begin
        TestChangeLine(AssemblyLine.FieldNo("Due Date"), true, 0, -1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdHdrDueDatePosOptAvailSupply()
    begin
        TestChangeHeader(AssemblyHeader.FieldNo("Due Date"), true, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdHdrItemNoNegOptional()
    begin
        TestChangeHeader(AssemblyHeader.FieldNo("Item No."), false, 0, 0, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdHdrQtyPosOptional()
    begin
        TestChangeHeader(AssemblyHeader.FieldNo(Quantity), true, 0, 0, 2);
    end;

    [Normal]
    local procedure TestSalesLineReserve(Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer; ReserveSalesLineFirst: Boolean): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservMgt: Codeunit "Reservation Management";
        ExpectedSalesResQty: Decimal;
        ExpectedAsyResQty: Decimal;
        AvailToReserve: Decimal;
        AvailToReserve2: Decimal;
        RemainingQty: Decimal;
        FullAutoReservation: Boolean;
    begin
        // Setup Reservations.
        Initialize();
        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve, ExcessSupply,
          FilterOnVariant, FilterOnLocation, DueDateDelay, 2);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyLine."No.", AssemblyLine.Quantity);
        SalesLine.Validate("Variant Code", AssemblyLine."Variant Code");
        SalesLine.Validate("Location Code", AssemblyLine."Location Code");
        SalesLine.Validate("Shipment Date", AssemblyLine."Due Date");
        SalesLine.Modify(true);

        // Exercise: Reserve Sales Line, Assembly Line in the specified order.
        if ReserveSalesLineFirst then
            LibrarySales.AutoReserveSalesLine(SalesLine);

        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", AssemblyLine.Quantity, AssemblyLine."Quantity (Base)");

        if not ReserveSalesLineFirst then
            LibrarySales.AutoReserveSalesLine(SalesLine);

        // Validate: Reserved Qty on Sales Line.
        RemainingQty :=
          GetTotalAvailSupply(TempReservationEntry, AvailToReserve2, AssemblyLine."Location Code", AssemblyLine."Variant Code",
            AssemblyLine."Due Date", 0) - AvailToReserve;

        if ReserveSalesLineFirst then begin
            ExpectedSalesResQty := AvailToReserve;
            if RemainingQty < 0 then
                ExpectedAsyResQty := 0
            else
                ExpectedAsyResQty :=
                  (AssemblyLine."Quantity (Base)" + RemainingQty - Abs(AssemblyLine."Quantity (Base)" - RemainingQty)) / 2;
        end else begin
            ExpectedAsyResQty := AvailToReserve;
            if RemainingQty < 0 then
                ExpectedSalesResQty := 0
            else
                ExpectedSalesResQty := (SalesLine."Quantity (Base)" + RemainingQty - Abs(SalesLine."Quantity (Base)" - RemainingQty)) / 2;
        end;

        // Raise Reservation page in case the remaining qty to reserve from the demand is positive.
        PAGE.RunModal(PAGE::Reservation);

        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(ExpectedSalesResQty, SalesLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong Res. Qty Sales Line');
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(ExpectedAsyResQty, AssemblyLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong Res. Qty Assembly Line');

        NotificationLifecycleMgt.RecallAllNotifications();
        exit(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosOptionalAssemblyFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegOptionalAssemblyFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, -LibraryRandom.RandIntInRange(7, 50), false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosAlwaysAssemblyFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Always, LibraryRandom.RandIntInRange(7, 50), false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegAlwaysAssemblyFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosOptionalAssemblyFirstLoc()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), true, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegOptionalAssemblyFirstVar()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, -LibraryRandom.RandIntInRange(7, 50), false, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosOptionalAssemblyFirstDDate()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), false, false, 2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegOptionalAssemblyFirstDDate()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, -LibraryRandom.RandIntInRange(7, 50), false, false, 2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosAlwaysAssemblyFirstVar()
    begin
        TestSalesLineReserve(Item.Reserve::Always, LibraryRandom.RandIntInRange(7, 50), false, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegAlwaysAssemblyFirstLoc()
    begin
        TestSalesLineReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), true, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosOptionalSalesFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), false, false, 0, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegAlwaysSalesFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Always, -LibraryRandom.RandIntInRange(7, 50), false, false, 0, true);
    end;

    [Test]
    [HandlerFunctions('ResPageHandler')]
    [Scope('OnPrem')]
    procedure PosOptionalLocSalesFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, LibraryRandom.RandIntInRange(7, 50), true, false, 0, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure NegOptionalDDateSalesFirst()
    begin
        TestSalesLineReserve(Item.Reserve::Optional, -LibraryRandom.RandIntInRange(7, 50), false, false, 7, true);
    end;

    [Normal]
    local procedure PostOptionalSalesLine(PositiveTest: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        QtyToPost: Decimal;
    begin
        // Setup: Create a Supply - Demand pair between a Sales Line and an Assembly Header.
        SalesHeader.Get(SalesHeader."Document Type"::Order, TestSalesLineReserve(Item.Reserve::Optional, 0, false, false, 0, true));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Item.Get(SalesLine."No.");
        Item.CalcFields(Inventory);

        // Exercise: Try to post reservations on sales header.
        if PositiveTest then
            QtyToPost := Item.Inventory
        else
            QtyToPost := LibraryRandom.RandIntInRange(Item.Inventory, Item.Inventory + 10);

        SalesLine.Validate("Qty. to Ship (Base)", QtyToPost);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Validate: No ILE reservation entries remaining.
        FindReservationEntries(ReservationEntry, true, SalesLine."No.", 32, '');
        Assert.AreEqual(0, ReservationEntry.Count, 'There are reservation entries remaining against ILEs.');
    end;

    [Test]
    [HandlerFunctions('ResPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesLinePos()
    begin
        PostOptionalSalesLine(true);
    end;

    [Test]
    [HandlerFunctions('ResPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesLineNeg()
    begin
        asserterror PostOptionalSalesLine(false);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorInventory) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ResPageHandler')]
    [Scope('OnPrem')]
    procedure PostOptionalAssemblyHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        PostedQty: Decimal;
        InitialResQty: Decimal;
        SourceID: Code[20];
    begin
        // Setup: Create a Supply - Demand pair between a Sales Line and an Assembly Header.
        Initialize();

        SalesHeader.Get(SalesHeader."Document Type"::Order, TestSalesLineReserve(Item.Reserve::Optional, 0, false, false, 0, true));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Item.Get(SalesLine."No.");
        Item.CalcFields(Inventory);

        FindReservationEntries(ReservationEntry, true, SalesLine."No.", 900, '');
        ReservationEntry.FindFirst();
        PostedQty := ReservationEntry."Quantity (Base)";
        SourceID := ReservationEntry."Source ID";
        InitialResQty := GetReservedQty(ReservationEntry);

        // Exercise: Post Supply: Assembly Order.
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, SourceID);
        AssemblyHeader.Validate("Quantity to Assemble", PostedQty / AssemblyHeader."Qty. per Unit of Measure");
        AssemblyHeader.Modify(true);

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, AssemblyHeader."Item No.",
          Item."Base Unit of Measure", LibraryRandom.RandInt(20), 0, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Validate: Reservation entry has been shifted to ILE.
        // No more Assembly Header reservation entries.
        FindReservationEntries(ReservationEntry, true, SalesLine."No.", 900, AssemblyHeader."No.");
        Assert.AreEqual(0, ReservationEntry.Count, 'There are reservation entries remaining against the Assembly Header.');

        // Sum of qty reserved against ILEs shifts with posted header qty.
        FindReservationEntries(ReservationEntry, true, SalesLine."No.", 32, '');
        Assert.AreNearlyEqual(InitialResQty + PostedQty, GetReservedQty(ReservationEntry), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong shifted qty.');
    end;

    [Normal]
    local procedure TestChangeSalesLine(Reserve: Enum "Reserve Method"; SalesLineFieldNo: Integer; PositiveTest: Boolean; ExcessSupply: Decimal; SupplyDelayFactor: Integer; Multiplicity: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        NewFieldValue: Variant;
        AvailToReserve: Decimal;
        DueDateDelay: Integer;
    begin
        // Setup Reservations.
        // If Due Date is changed, ensure supply outside the initial filters is created.
        if (SalesLine.FieldNo("Shipment Date") = SalesLineFieldNo) and PositiveTest then
            DueDateDelay := 30;

        SetupReservations(TempReservationEntry, AssemblyLine, AvailToReserve, Reserve, ExcessSupply,
          SalesLine.FieldNo("Variant Code") = SalesLineFieldNo,
          SalesLine.FieldNo("Location Code") = SalesLineFieldNo,
          DueDateDelay, Multiplicity);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyLine."No.", AvailToReserve);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // Exercise: Update Sales Line.
        SetSalesSupplyFilters(NewFieldValue, TempReservationEntry, SalesLine, SalesLineFieldNo, PositiveTest,
          SupplyDelayFactor * LibraryRandom.RandInt(DueDateDelay));
        UpdateSalesLine(SalesLine, SalesLineFieldNo, NewFieldValue);

        // Update TempReservationEntry based one the new line, using SetQtyToReserve.
        UpdateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine);

        // Validate: Reservation entries and Reserved Qty on Assembly Line.
        if Reserve <> Item.Reserve::Always then begin
            TempReservationEntry.Reset();
            TempReservationEntry.DeleteAll();
            AvailToReserve := 0;
        end;

        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        Assert.AreNearlyEqual(AvailToReserve, SalesLine."Reserved Qty. (Base)", LibraryERM.GetAmountRoundingPrecision(), 'Wrong Res. Qty');
        SalesLine.TestField("Reserved Quantity", SalesLine."Reserved Qty. (Base)" * SalesLine."Qty. per Unit of Measure");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineLocPos()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Location Code"), true, 0, 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineVarPos()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Variant Code"), true, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineLocNeg()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Location Code"), false, 0, 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineVarNeg()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Variant Code"), false, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineDueDatePos()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Shipment Date"), true, 0, 1, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler,ShipmentDateMessageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineDueDateNeg()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo("Shipment Date"), false, 0, 1, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineQtyIncr()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo(Quantity), true, 0, 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResPageHandler')]
    [Scope('OnPrem')]
    procedure UpdSalesLineQtyDecr()
    begin
        TestChangeSalesLine(Item.Reserve::Optional, SalesLine.FieldNo(Quantity), false, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailAOModalHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAssemblySupplyForPurchaseReturnDemand()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Purchase Lines] [Purchase Return] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Purchase Lines" page when demand is Purchase Return Order, and supply - Assembly Order

        Initialize();
        GlobalAOSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', GlobalAOSupply, '');

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", GlobalAOSupply);

        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableAssemblyLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveForAssemblyDemandFromProductionSupply()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Available - Assembly Lines] [Assembly] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Assembly Order, and supply - Production Order

        Initialize();
        GlobalAOSupply := LibraryRandom.RandDec(200, 2);
        CreateAssemblyOrder(WorkDate2, GlobalAOSupply);

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", GlobalAOSupply, WorkDate() - 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.");

        LibraryVariableStorage.Enqueue(GlobalAOSupply);
        ProdOrderLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandProductionSupplyReserveFromDemand()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Assembly] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Assembly Order, and supply - Production Order

        Initialize();
        GlobalAOSupply := LibraryRandom.RandDec(200, 2);
        CreateAssemblyOrder(WorkDate2, GlobalAOSupply);

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", GlobalAOSupply, WorkDate() - 1);

        LibraryVariableStorage.Enqueue(GlobalAOSupply);
        AssemblyLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveForProductionDemandFromAssembly()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Available - Prod. Order Comp.] [Assembly] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Comp." page when demand is Production Order, and supply - Assembly Order

        Initialize();
        GlobalAOSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', GlobalAOSupply, '');

        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalAOSupply, WorkDate2, '');

        LibraryVariableStorage.Enqueue(GlobalAOSupply);
        AssemblyHeader.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableAssemblyHeadersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveAssemblySupplyProductionDemandReserveFromDemand()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Available - Assembly Lines] [Assembly] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Production Order, and supply - Assembly Order

        Initialize();
        GlobalAOSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', GlobalAOSupply, '');

        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalAOSupply, WorkDate2, '');

        LibraryVariableStorage.Enqueue(GlobalAOSupply);
        ProdOrderComponent.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProductionSupplyProductionDemandReserveFromSupply()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Available - Prod. Order Comp.] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Comp." page when demand is Production Order, and supply - Production Order

        Initialize();
        GlobalPOSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);

        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalPOSupply, WorkDate2, '');

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", GlobalPOSupply, WorkDate());
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.");

        LibraryVariableStorage.Enqueue(GlobalPOSupply);
        ProdOrderLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationPageHandler,AvailableProdOrderCompPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProductionDemandTransferSupplyReserveFromSupply()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Available - Prod. Order Comp.] [Production] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Comp." page when demand is Production Order, and supply - Transfer Order

        Initialize();
        GlobalSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalSupply, WorkDate2, ToLocation.Code);
        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", GlobalSupply);

        LibraryVariableStorage.Enqueue(GlobalSupply);
        TransferLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProductionDemandTransferSupplyReserveFromDemand()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Available - Transfer Lines] [Production] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Production Order, and supply - Transfer Order

        Initialize();
        GlobalSupply := LibraryRandom.RandDec(200, 2);
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalSupply, WorkDate2, ToLocation.Code);
        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", GlobalSupply);

        LibraryVariableStorage.Enqueue(GlobalSupply);
        ProdOrderComponent.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompCancelReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveProductionDemandCancelReservation()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Available - Prod. Order Comp.] [Production] [Reservation]
        // [SCENARIO] Reservation can be cancelled from "Available - Prod. Order Comp." page

        Initialize();
        SetupProductionDemandWithProductionSupply(ProdOrderLine);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        ProdOrderLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompDrillDownQtyPageHandler,ResEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProductionDemandDrillDownReservedQty()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Available - Prod. Order Comp.] [Production] [Reservation]
        // [SCENARIO] Drill down action in "Available - Prod. Order Comp." page should show full reserved quantity

        Initialize();
        SetupProductionDemandWithProductionSupply(ProdOrderLine);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        ProdOrderLine.ShowReservation();
    end;

    local procedure SetupReservations(var TempReservationEntry: Record "Reservation Entry" temporary; var AssemblyLine: Record "Assembly Line"; var AvailToReserve: Decimal; Reserve: Enum "Reserve Method"; ExcessSupply: Decimal; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer; Multiplicity: Integer)
    var
        Item: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        QtyFactor: Integer;
    begin
        // Setup: Create Assembly structure and order.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 2, 2, 0, 1, '', '');
        UpdateBOMReservationPolicy(Item."No.", Reserve);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, WorkDate2, Item."No.", Location.Code, 50 + LibraryRandom.RandInt(50), '');
        AssemblyHeader.Validate("Due Date", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate2));
        AssemblyHeader.Modify(true);

        // Find any item component line for the Assembly Order.
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.Next(LibraryRandom.RandInt(AssemblyLine.Count));
        AssemblyLine.Validate("Quantity per", Round(AssemblyLine."Quantity per", 1, '<'));
        AssemblyLine.Modify(true);

        // Create an assortment of supply for the item: ILEs, Purchase Order, Firm Planned Prod. Order, Released Prod. Order.
        // 2 supply document sets that fit the actual Assembly Order Line.
        AvailToReserve := 0;
        if Multiplicity <> 0 then
            QtyFactor := 3 * Multiplicity
        else
            QtyFactor := 1;

        TempReservationEntry.DeleteAll();
        CreateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine, AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Due Date", Round((AssemblyLine."Quantity (Base)" + ExcessSupply) / QtyFactor, 1, '>'), Multiplicity);

        // Create supply that falls outside the filter, as per the passed parameters.
        CreateFilterSupply(TempReservationEntry, AvailToReserve, AssemblyLine, FilterOnVariant, FilterOnLocation, DueDateDelay, ExcessSupply);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure UpdateBOMReservationPolicy(ParentItemNo: Code[20]; Reserve: Enum "Reserve Method")
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.FindSet() then
            repeat
                Item.Get(BOMComponent."No.");
                Item.Validate(Reserve, Reserve);
                Item.Modify(true);
            until BOMComponent.Next() = 0;
    end;

    [Normal]
    local procedure CreateSupplyLine(var TempReservationEntry: Record "Reservation Entry" temporary; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; Type: Option; Quantity: Decimal; QtyToReserve: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        case Type of
            GlobalSupplyType::"Purchase Order":
                begin
                    LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
                    LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
                    PurchaseLine.Validate("Variant Code", VariantCode);
                    PurchaseLine.Validate("Location Code", LocationCode);
                    PurchaseLine.Validate("Expected Receipt Date", DueDate);
                    PurchaseLine.Modify(true);
                    CreateReservationEntry(TempReservationEntry, ItemNo, VariantCode, LocationCode, Quantity, QtyToReserve, 39, PurchaseHeader."No.",
                      PurchaseLine."Line No.", DueDate);
                end;
            GlobalSupplyType::"Assembly Order":
                begin
                    LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ItemNo, LocationCode, Quantity, VariantCode);
                    CreateReservationEntry(TempReservationEntry, ItemNo, VariantCode, LocationCode, Quantity,
                      QtyToReserve, 900, AssemblyHeader."No.", 0, DueDate);
                end;
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure CreateSupplyLines(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailToReserve: Decimal; AssemblyLine: Record "Assembly Line"; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; Qty: Decimal; Multiplicity: Integer)
    var
        i: Integer;
        j: Integer;
        QtyToReserve: Decimal;
    begin
        // ILEs should not be created outside the due date filter, since they are always valid, even if posted with a later date.
        if DueDate <= AssemblyLine."Due Date" then
            for i := 1 to Multiplicity do begin
                QtyToReserve := Qty;
                AddCompInventory(TempReservationEntry, QtyToReserve, AvailToReserve, AssemblyLine."No.", VariantCode, LocationCode, AssemblyLine);
            end;

        for i := 0 to 1 do
            for j := 1 to Multiplicity do begin
                QtyToReserve := Qty;
                SetQtyToReserve(QtyToReserve, AvailToReserve, AssemblyLine, AssemblyLine."No.", VariantCode, LocationCode, DueDate);
                CreateSupplyLine(TempReservationEntry, AssemblyLine."No.", VariantCode, LocationCode, DueDate, i, Qty, QtyToReserve);
            end;
    end;

    [Normal]
    local procedure UpdateSupplyLines(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailToReserve: Decimal; AssemblyLine: Record "Assembly Line")
    begin
        AvailToReserve := 0;

        // Update expected reserved qty. for ILE supply.
        UpdateSourceTypeLines(TempReservationEntry, AvailToReserve, AssemblyLine, 32);

        // Update expected reserved qty. for Purchase Order supply.
        UpdateSourceTypeLines(TempReservationEntry, AvailToReserve, AssemblyLine, 900);

        // Update expected reserved qty. for Assembly Header supply.
        UpdateSourceTypeLines(TempReservationEntry, AvailToReserve, AssemblyLine, 39);
    end;

    [Normal]
    local procedure UpdateSourceTypeLines(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailToReserve: Decimal; AssemblyLine: Record "Assembly Line"; SourceType: Integer)
    var
        QtyToReserve: Decimal;
    begin
        TempReservationEntry.Reset();
        TempReservationEntry.SetRange("Source Type", SourceType);
        if TempReservationEntry.FindSet() then
            repeat
                QtyToReserve := TempReservationEntry."Qty. to Handle (Base)";

                // Shifting of due date is allowed for ILE reservation entries.
                if (TempReservationEntry."Source Type" = 32) and
                   (TempReservationEntry."Expected Receipt Date" > AssemblyLine."Due Date")
                then
                    TempReservationEntry."Expected Receipt Date" := AssemblyLine."Due Date";

                SetQtyToReserve(QtyToReserve, AvailToReserve, AssemblyLine, TempReservationEntry."Item No.", TempReservationEntry."Variant Code",
                  TempReservationEntry."Location Code", TempReservationEntry."Expected Receipt Date");
                TempReservationEntry."Quantity (Base)" := QtyToReserve;
                TempReservationEntry.Modify(true);

            until TempReservationEntry.Next() = 0;
    end;

    [Normal]
    local procedure SetQtyToReserve(var QtyToReserve: Decimal; var AvailToReserve: Decimal; AssemblyLine: Record "Assembly Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date)
    begin
        // Do not expect to reserve anything outside location, variant and due date filters.
        if (AssemblyLine."Variant Code" <> VariantCode) or
           (AssemblyLine."Location Code" <> LocationCode) or
           (AssemblyLine."Due Date" < DueDate) or
           (AssemblyLine."No." <> ItemNo)
        then
            QtyToReserve := 0;

        // Update total available to reserve qty. until we reach the assembly line quantity.
        if AvailToReserve + QtyToReserve > AssemblyLine."Quantity (Base)" then begin
            QtyToReserve := AssemblyLine."Quantity (Base)" - AvailToReserve;
            AvailToReserve := AssemblyLine."Quantity (Base)";
        end else
            AvailToReserve += QtyToReserve;
    end;

    [Normal]
    local procedure SetSupplyFilters(var AssemblyLineFieldValue: Variant; var TempReservationEntry: Record "Reservation Entry" temporary; var AssemblyLine: Record "Assembly Line"; AssemblyLineFieldNo: Integer; PositiveTest: Boolean; SupplyDelay: Integer)
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        // Positive test: Extract expected reservation entry that will drive the line update.
        TempReservationEntry.Reset();
        if PositiveTest then
            case AssemblyLineFieldNo of
                AssemblyLine.FieldNo("Location Code"):
                    begin
                        TempReservationEntry.SetFilter("Location Code", '<>%1', AssemblyLine."Location Code");
                        TempReservationEntry.FindFirst();
                        AssemblyLineFieldValue := TempReservationEntry."Location Code";
                    end;
                AssemblyLine.FieldNo("Variant Code"):
                    begin
                        TempReservationEntry.SetFilter("Variant Code", '<>%1', AssemblyLine."Variant Code");
                        TempReservationEntry.FindFirst();
                        AssemblyLineFieldValue := TempReservationEntry."Variant Code";
                    end;
                AssemblyLine.FieldNo("Due Date"):
                    begin
                        TempReservationEntry.SetFilter("Expected Receipt Date", '>%1', AssemblyLine."Due Date");
                        TempReservationEntry.FindFirst();
                        AssemblyLineFieldValue := CalcDate('<' + Format(SupplyDelay, 0, '<sign><integer>') + 'D>',
                            TempReservationEntry."Expected Receipt Date");
                        AssemblyLine.SetTestReservationDateConflict(true);
                    end;
                AssemblyLine.FieldNo(Type):
                    AssemblyLineFieldValue := AssemblyLine.Type::Item;
                AssemblyLine.FieldNo("No."):
                    AssemblyLineFieldValue := AssemblyLine."No.";
            end
        // Negative test: Create new filter values so that nothing will be reserved after the line changes.
        else
            case AssemblyLineFieldNo of
                AssemblyLine.FieldNo("Location Code"):
                    begin
                        LibraryWarehouse.CreateLocation(Location);
                        AssemblyLineFieldValue := Location.Code;
                    end;
                AssemblyLine.FieldNo("Variant Code"):
                    begin
                        LibraryInventory.CreateItemVariant(ItemVariant, AssemblyLine."No.");
                        AssemblyLineFieldValue := ItemVariant.Code;
                    end;
                AssemblyLine.FieldNo("Due Date"):
                    begin
                        AssemblyLineFieldValue := CalcDate('<-7D>', AssemblyLine."Due Date");
                        AssemblyLine.SetTestReservationDateConflict(true);
                    end;
                AssemblyLine.FieldNo(Type):
                    AssemblyLineFieldValue := AssemblyLine.Type::Resource;
                AssemblyLine.FieldNo("No."):
                    AssemblyLineFieldValue := '';
            end;
    end;

    [Normal]
    local procedure SetHeaderSupplyFilters(var AssemblyHeaderFieldValue: Variant; var TempReservationEntry: Record "Reservation Entry" temporary; AssemblyHeader: Record "Assembly Header"; AssemblyHeaderFieldNo: Integer; PositiveTest: Boolean; SupplyDelay: Integer)
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        // Positive test: Extract expected reservation entry that will drive the header update.
        TempReservationEntry.Reset();
        if PositiveTest then
            case AssemblyHeaderFieldNo of
                AssemblyHeader.FieldNo("Location Code"):
                    begin
                        TempReservationEntry.SetFilter("Location Code", '<>%1', AssemblyHeader."Location Code");
                        TempReservationEntry.FindFirst();
                        AssemblyHeaderFieldValue := TempReservationEntry."Location Code";
                    end;
                AssemblyHeader.FieldNo("Variant Code"):
                    begin
                        LibraryInventory.CreateItemVariant(ItemVariant, AssemblyHeader."Item No.");
                        AssemblyHeaderFieldValue := ItemVariant.Code;
                    end;
                AssemblyHeader.FieldNo("Due Date"):
                    begin
                        TempReservationEntry.SetFilter("Expected Receipt Date", '>%1', AssemblyHeader."Due Date");
                        TempReservationEntry.FindFirst();
                        AssemblyHeaderFieldValue := CalcDate('<' + Format(SupplyDelay, 0, '<sign><integer>') + 'D>',
                            TempReservationEntry."Expected Receipt Date");
                    end;
                AssemblyHeader.FieldNo("Item No."):
                    AssemblyHeaderFieldValue := '';
                AssemblyHeader.FieldNo(Quantity), AssemblyHeader."Quantity (Base)":
                    AssemblyHeaderFieldValue := LibraryRandom.RandIntInRange(AssemblyHeader."Quantity (Base)" + 1,
                        AssemblyHeader."Quantity (Base)" + 10);
            end
        // Negative test: Create new filter values so that nothing will be reserved after the header changes.
        else
            case AssemblyHeaderFieldNo of
                AssemblyHeader.FieldNo("Location Code"):
                    begin
                        LibraryWarehouse.CreateLocation(Location);
                        AssemblyHeaderFieldValue := Location.Code;
                    end;
                AssemblyHeader.FieldNo("Variant Code"):
                    begin
                        LibraryInventory.CreateItemVariant(ItemVariant, AssemblyHeader."No.");
                        AssemblyHeaderFieldValue := ItemVariant.Code;
                    end;
                AssemblyHeader.FieldNo("Due Date"):
                    AssemblyHeaderFieldValue := CalcDate('<-7D>', AssemblyHeader."Starting Date");
                AssemblyHeader.FieldNo("Item No."):
                    AssemblyHeaderFieldValue := '';
                AssemblyHeader.FieldNo(Quantity), AssemblyHeader."Quantity (Base)":
                    AssemblyHeaderFieldValue := LibraryRandom.RandIntInRange(AssemblyHeader."Assembled Quantity (Base)",
                        AssemblyHeader."Quantity (Base)" - 1);
            end;
    end;

    [Normal]
    local procedure SetSalesSupplyFilters(var SalesLineFieldValue: Variant; var TempReservationEntry: Record "Reservation Entry" temporary; SalesLine: Record "Sales Line"; SalesLineFieldNo: Integer; PositiveTest: Boolean; SupplyDelay: Integer)
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        // Positive test: Extract expected reservation entry that will drive the line update.
        TempReservationEntry.Reset();
        if PositiveTest then
            case SalesLineFieldNo of
                SalesLine.FieldNo("Location Code"):
                    begin
                        TempReservationEntry.SetFilter("Location Code", '<>%1', SalesLine."Location Code");
                        TempReservationEntry.FindFirst();
                        SalesLineFieldValue := TempReservationEntry."Location Code";
                    end;
                SalesLine.FieldNo("Variant Code"):
                    begin
                        LibraryInventory.CreateItemVariant(ItemVariant, SalesLine."No.");
                        SalesLineFieldValue := ItemVariant.Code;
                    end;
                SalesLine.FieldNo("Shipment Date"):
                    begin
                        TempReservationEntry.SetFilter("Expected Receipt Date", '>%1', SalesLine."Shipment Date");
                        TempReservationEntry.FindFirst();
                        SalesLineFieldValue := CalcDate('<' + Format(SupplyDelay, 0, '<sign><integer>') + 'D>',
                            TempReservationEntry."Expected Receipt Date");
                    end;
                SalesLine.FieldNo("No."):
                    SalesLineFieldValue := '';
                SalesLine.FieldNo(Quantity), AssemblyHeader."Quantity (Base)":
                    SalesLineFieldValue := SalesLine.Quantity + LibraryRandom.RandInt(Round(SalesLine.Quantity, 1, '=') - 1);
            end
        // Negative test: Create new filter values so that nothing will be reserved after the line changes.
        else
            case SalesLineFieldNo of
                SalesLine.FieldNo("Location Code"):
                    begin
                        LibraryWarehouse.CreateLocation(Location);
                        SalesLineFieldValue := Location.Code;
                    end;
                SalesLine.FieldNo("Variant Code"):
                    begin
                        LibraryInventory.CreateItemVariant(ItemVariant, SalesLine."No.");
                        SalesLineFieldValue := ItemVariant.Code;
                    end;
                SalesLine.FieldNo("Shipment Date"):
                    SalesLineFieldValue := CalcDate('<-7D>', SalesLine."Shipment Date");
                SalesLine.FieldNo("No."):
                    SalesLineFieldValue := '';
                SalesLine.FieldNo(Quantity), SalesLine."Quantity (Base)":
                    SalesLineFieldValue := SalesLine.Quantity - LibraryRandom.RandInt(Round(SalesLine.Quantity, 1, '=') - 1);
            end;
    end;

    local procedure SetupProductionDemandWithProductionSupply(var ProdOrderLine: Record "Prod. Order Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        CreateItemWithAlwaysReservePolicy(Item);
        GlobalPOSupply := LibraryRandom.RandDec(200, 2);
        CreateAndRefreshProductionOrderWithComponent(ProdOrderComponent, Item."No.", GlobalPOSupply, WorkDate2, '');

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", GlobalPOSupply, WorkDate());
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.");
        ProdOrderComponent.AutoReserve();
    end;

    [Normal]
    local procedure AddAssemblyLineOnPage(var AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");

        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrder.GotoRecord(AssemblyHeader);

        // Add line again to trigger page triggers.
        AssemblyOrder.Lines.New();
        AssemblyOrder.Lines.Type.Value := 'Item';
        AssemblyOrder.Lines."No.".Value := AssemblyLine."No.";
        AssemblyOrder.Lines."Variant Code".Value := AssemblyLine."Variant Code";
        AssemblyOrder.Lines."Location Code".Value := AssemblyLine."Location Code";
        AssemblyOrder.Lines."Unit of Measure Code".Value := AssemblyLine."Unit of Measure Code";
        AssemblyOrder.Lines."Quantity per".Value := Format(AssemblyLine."Quantity per", 5);

        AssemblyOrder.Close();

        // Fetch the line from the database for validation.
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", AssemblyLine."No.");
        AssemblyLine.FindLast();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure AddCompInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var Quantity: Decimal; var AvailToReserve: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; AssemblyLine: Record "Assembly Line")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyToReserve: Decimal;
    begin
        if Quantity <= 0 then
            exit;
        QtyToReserve := Quantity;

        // Post the desired quantity using item journal.
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", AssemblyLine."Due Date");
        ItemJournalLine.Validate("Document Date", AssemblyLine."Due Date");
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(50, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // Do not expect to reserve if location and variant do not match the assembly line.
        if (VariantCode <> AssemblyLine."Variant Code") or (LocationCode <> AssemblyLine."Location Code") then
            QtyToReserve := 0
        else
            // Do not expect to reserve for more than the Assembly line quantity.
            if AvailToReserve + Quantity > AssemblyLine."Quantity (Base)" then begin
                QtyToReserve := AssemblyLine."Quantity (Base)" - AvailToReserve;
                AvailToReserve := AssemblyLine."Quantity (Base)";
            end else
                AvailToReserve += QtyToReserve;

        // Construct expected reservation entry.
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange("Document No.", ItemJournalLine."Document No.");
        ItemLedgerEntry.SetRange(Quantity, Quantity);
        ItemLedgerEntry.FindFirst();
        CreateReservationEntry(TempReservationEntry, ItemNo, VariantCode, LocationCode, Quantity, QtyToReserve, 32,
          Format(ItemLedgerEntry."Entry No."), ItemLedgerEntry."Entry No.", WorkDate2);

        Quantity := QtyToReserve;
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
    end;

    [Normal]
    local procedure FindReservationEntries(var ReservationEntry: Record "Reservation Entry"; Positive: Boolean; ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20])
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetRange(Positive, Positive);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        if SourceID <> '' then
            ReservationEntry.SetRange("Source ID", SourceID);
    end;

    [Normal]
    local procedure GetReservedQty(var ReservationEntry: Record "Reservation Entry"): Decimal
    var
        ReservedQty: Decimal;
    begin
        if ReservationEntry.FindSet() then
            repeat
                ReservedQty += ReservationEntry."Quantity (Base)";
            until ReservationEntry.Next() = 0;

        exit(ReservedQty);
    end;

    [Normal]
    local procedure VerifyReservationEntries(var TempReservationEntry: Record "Reservation Entry" temporary; AssemblyLine: Record "Assembly Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
    begin
        TempReservationEntry.SetFilter("Quantity (Base)", '<>%1', 0);
        // Group the reserved qty. per source type.
        // ILEs.
        VerifyReservedQty(TempReservationEntry, 32);
        // Purchase Orders.
        VerifyReservedQty(TempReservationEntry, 39);
        // Assembly Orders.
        VerifyReservedQty(TempReservationEntry, 900);

        // Check the number of reservation entries.
        TempReservationEntry.Reset();
        TempReservationEntry.SetFilter("Quantity (Base)", '<>%1', 0);
        ReservationEntry.Reset();
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.SetRange("Item No.", AssemblyLine."No.");
        ReservationEntry.SetRange("Location Code", AssemblyLine."Location Code");
        ReservationEntry.SetRange("Variant Code", AssemblyLine."Variant Code");
        Assert.AreEqual(TempReservationEntry.Count, ReservationEntry.Count, 'Too many res. for ' + AssemblyLine."Document No.");

        // Verify the pairs of reservations entries are consistent.
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry2.Get(ReservationEntry."Entry No.", false);
                ReservationEntry2.TestField("Source Type", 901);
                ReservationEntry2.TestField("Source ID", AssemblyLine."Document No.");
                ReservationEntry2.TestField("Source Ref. No.", AssemblyLine."Line No.");
                ReservationEntry2.TestField("Item No.", AssemblyLine."No.");
                ReservationEntry2.TestField("Variant Code", AssemblyLine."Variant Code");
                ReservationEntry2.TestField("Location Code", AssemblyLine."Location Code");
                ReservationEntry2.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
                Assert.AreEqual(-ReservationEntry."Quantity (Base)", ReservationEntry2."Quantity (Base)", 'Wrong Qty base.');
            until ReservationEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifyReservedQty(var TempReservationEntry: Record "Reservation Entry" temporary; SourceType: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        ExpectedQty: Decimal;
        ActualQty: Decimal;
    begin
        TempReservationEntry.SetRange("Source Type", SourceType);
        if TempReservationEntry.FindSet() then begin
            ReservationEntry.Reset();
            ReservationEntry.SetRange(Positive, true);
            ReservationEntry.SetRange("Source Type", TempReservationEntry."Source Type");
            ReservationEntry.SetRange("Item No.", TempReservationEntry."Item No.");
            ReservationEntry.SetRange("Variant Code", TempReservationEntry."Variant Code");
            ReservationEntry.SetRange("Location Code", TempReservationEntry."Location Code");
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
            if ReservationEntry.FindSet() then begin
                Assert.AreEqual(TempReservationEntry.Count, ReservationEntry.Count,
                  'Too many entries for source type ' + Format(SourceType));
                ExpectedQty := 0;
                repeat
                    ExpectedQty += TempReservationEntry."Quantity (Base)";
                until TempReservationEntry.Next() = 0;

                ActualQty := 0;
                repeat
                    ActualQty += ReservationEntry."Quantity (Base)";
                until ReservationEntry.Next() = 0;

                Assert.AreEqual(ExpectedQty, ActualQty, 'Wrong res. qty for source type ' + Format(TempReservationEntry."Source Type"));
            end;
        end;
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Starting Date", DueDate);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshProductionOrderWithComponent(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; Qty: Decimal; DueDate: Date; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo, Qty, DueDate);
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.");
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, ItemNo, Qty, LocationCode);
    end;

    local procedure CreateAssemblyOrder(DueDate: Date; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, Item."No.", '', Quantity, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", Quantity, 1, '');
    end;

    local procedure CreateItemWithAlwaysReservePolicy(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Remaining Qty. (Base)", Quantity);
        ProdOrderComponent.Modify(true);
    end;

    [Normal]
    local procedure CreateReservationEntry(var TempReservationEntry: Record "Reservation Entry" temporary; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; QtyToReserve: Decimal; SourceType: Integer; SourceID: Code[20]; SourceRefNo: Integer; ExpectedReceiptDate: Date)
    var
        LastEntryNo: Integer;
    begin
        if TempReservationEntry.FindLast() then
            LastEntryNo := TempReservationEntry."Entry No.";

        TempReservationEntry.Init();
        TempReservationEntry.Validate("Entry No.", LastEntryNo + 1);
        TempReservationEntry.Validate(Positive, true);
        TempReservationEntry.Validate("Item No.", ItemNo);
        TempReservationEntry.Validate("Variant Code", VariantCode);
        TempReservationEntry.Validate("Location Code", LocationCode);
        TempReservationEntry.Validate("Quantity (Base)", Round(QtyToReserve, LibraryERM.GetUnitAmountRoundingPrecision()));
        // Save overall supply line qty. in an unused field.
        TempReservationEntry.Validate("Qty. to Handle (Base)", Quantity);
        TempReservationEntry.Validate("Reservation Status", TempReservationEntry."Reservation Status"::Reservation);
        TempReservationEntry.Validate("Source Type", SourceType);
        TempReservationEntry.Validate("Expected Receipt Date", ExpectedReceiptDate);
        // Except for ILE reservation entries, the subtype is 1 = Order for normal documents.
        if SourceType = 32 then
            TempReservationEntry.Validate("Source Subtype", 0)
        else
            TempReservationEntry.Validate("Source Subtype", 1);
        TempReservationEntry.Validate("Source ID", SourceID);
        TempReservationEntry.Validate("Source Ref. No.", SourceRefNo);
        TempReservationEntry.Insert(true);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    [Normal]
    local procedure CreateFilterSupply(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailToReserve: Decimal; AssemblyLine: Record "Assembly Line"; FilterOnVariant: Boolean; FilterOnLocation: Boolean; DueDateDelay: Integer; ExcessSupply: Decimal)
    var
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        Item: Record Item;
        VariantCode: Code[10];
        LocationCode: Code[10];
    begin
        Item.Get(AssemblyLine."No.");

        if FilterOnVariant then begin
            LibraryInventory.CreateVariant(ItemVariant, Item);
            VariantCode := ItemVariant.Code;
        end else
            VariantCode := AssemblyLine."Variant Code";

        if FilterOnLocation then begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            LocationCode := Location.Code;
        end else
            LocationCode := AssemblyLine."Location Code";

        if FilterOnVariant or FilterOnLocation or (DueDateDelay <> 0) then
            CreateSupplyLines(TempReservationEntry, AvailToReserve, AssemblyLine, VariantCode, LocationCode,
              CalcDate('<' + Format(DueDateDelay, 0, '<sign><integer>') + 'D>', AssemblyLine."Due Date"),
              LibraryRandom.RandInt(Round((AssemblyLine."Quantity (Base)" + ExcessSupply) / 3, 1, '>')), 1);
    end;

    [Normal]
    local procedure UpdateAssemblyLine(var AssemblyLine: Record "Assembly Line"; FieldNo: Integer; Value: Variant)
    var
        AsmHeader: Record "Assembly Header";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(AssemblyLine);
        FieldRef := RecRef.Field(FieldNo);

        // Testability issue for Due Date field.
        AssemblyLine.SetTestReservationDateConflict(true);
        if FieldNo = AssemblyLine.FieldNo("Due Date") then begin
            AsmHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
            AsmHeader."Starting Date" := CalcDate(AssemblyLine."Lead-Time Offset", Value);
            AsmHeader.ValidateDates(AssemblyHeader.FieldNo("Starting Date"), true);
            AsmHeader.Modify(true);
        end;
        FieldRef.Validate(Value);

        RecRef.SetTable(AssemblyLine);
        AssemblyLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(AssemblyHeader);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(AssemblyHeader);
        AssemblyHeader.Modify(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(SalesLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(SalesLine);
        SalesLine.Modify(true);
    end;

    [Normal]
    local procedure GetTotalAvailSupply(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailToReserve: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; SourceType: Integer): Decimal
    var
        AvailableSupply: Decimal;
    begin
        TempReservationEntry.Reset();
        TempReservationEntry.SetRange("Location Code", LocationCode);
        TempReservationEntry.SetRange("Variant Code", VariantCode);
        if SourceType <> 0 then
            TempReservationEntry.SetRange("Source Type", SourceType);

        if TempReservationEntry.FindSet() then
            repeat
                if ((TempReservationEntry."Source Type" <> 32) and (TempReservationEntry."Expected Receipt Date" <= DueDate)) or
                   (TempReservationEntry."Source Type" = 32)
                then begin
                    AvailToReserve += TempReservationEntry."Quantity (Base)";
                    AvailableSupply += TempReservationEntry."Qty. to Handle (Base)";
                end;
            until TempReservationEntry.Next() = 0;

        exit(AvailableSupply)
    end;

    [Normal]
    local procedure VerifyEntrySummary(Reservation: TestPage Reservation; ExpectedTotalQty: Text[30]; ExpectedAvailQty: Text[30]; ExpectedSummaryType: Text[30])
    begin
        Assert.IsTrue(StrPos(Reservation."Summary Type".Value, ExpectedSummaryType) > 0,
          'Expected: ' + ExpectedSummaryType + ' Actual: ' + Reservation."Summary Type".Value);
        Assert.AreEqual(ExpectedTotalQty, Reservation."Total Quantity".Value, 'Wrong total qty for ' + ExpectedSummaryType);
        Assert.AreEqual(ExpectedAvailQty, Reservation.TotalAvailableQuantity.Value, 'Wrong avail qty for ' + ExpectedSummaryType);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResEntryPageHandler(var ReservationEntries: Page "Reservation Entries"; var Response: Action)
    begin
        Response := ACTION::None;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResPageHandler(var Reservation: Page Reservation; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipmentDateMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PartialResConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ErrorResAlways) > 0, 'Actual:' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CancelResConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ErrorCancelRes) > 0, 'Actual:' + Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailToResModalHandler(var Reservation: TestPage Reservation)
    var
        counter: Integer;
    begin
        Reservation.First();

        // Validate: Entry summaries for various supply types.
        VerifyEntrySummary(Reservation, Format(GlobalILESupply), Format(GlobalILESupply), 'Item Ledger Entry');
        Reservation.AvailableToReserve.Invoke();
        Reservation.Next();

        VerifyEntrySummary(Reservation, Format(GlobalPOSupply), Format(GlobalPOSupply), 'Purchase');
        Reservation.AvailableToReserve.Invoke();
        Reservation.Next();

        VerifyEntrySummary(Reservation, Format(GlobalAOSupply), Format(GlobalAOSupply), 'Assembly');
        Reservation.AvailableToReserve.Invoke();

        Reservation.First();
        if Reservation."Summary Type".Value <> '' then
            counter := 1;
        while Reservation.Next() do
            counter += 1;

        Assert.AreEqual(3, counter, 'Wrong no. of Summary entries.');

        // Exercise: Autoreserve.
        Reservation."Auto Reserve".Invoke();
        if GlobalReserveTwice then
            Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveCancelModalHandler(var Reservation: TestPage Reservation)
    var
        SupplyType: Text[80];
        CapableToReserve: Decimal;
        QtyToReserve: Decimal;
    begin
        // Set label filtering for Entry Summary.
        case GlobalSourceType of
            32:
                SupplyType := 'Item Ledger Entry';
            39:
                SupplyType := 'Purchase';
            900:
                SupplyType := 'Assembly';
        end;

        Reservation.First();
        // Set the cursor on the desired supply type.
        while StrPos(Reservation."Summary Type".Value, SupplyType) = 0 do
            if not Reservation.Next() then
                Assert.Fail('Expected line for ' + SupplyType + ' not found.');

        // Exercise: Reserve from current line.
        Reservation."Reserve from Current Line".Invoke();
        if GlobalReserveTwice then
            Reservation."Reserve from Current Line".Invoke();

        // Validate: Reserved Qty.
        // Capable to Reserve = min(Assembly Line Qty, Avail To Reserve Qty for the current Supply Type).
        Evaluate(QtyToReserve, Reservation.QtyToReserveBase.Value);
        CapableToReserve := (GlobalSupply + QtyToReserve - Abs(GlobalSupply - QtyToReserve)) / 2;

        Assert.IsTrue(StrPos(Reservation."Summary Type".Value, SupplyType) > 0, 'Actual:' + Reservation."Summary Type".Value);
        Assert.AreEqual(Format(CapableToReserve), Reservation."Current Reserved Quantity".Value, 'Wrong reserved qty for ' + SupplyType);

        // Exercise: Cancel reservation if required.
        if GlobalCancelReservation then begin
            Reservation.CancelReservationCurrentLine.Invoke();
            // Validate: Reservation was canceled.
            Assert.AreEqual('', Reservation."Current Reserved Quantity".Value, 'Wrong reserved qty for ' + SupplyType);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InsufSupplyMessagHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ErrorInsufSupply) > 0, 'Actual:' + Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailILEModalHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    var
        ActualQty: Decimal;
        LineQty: Decimal;
    begin
        AvailableItemLedgEntries.First();
        if AvailableItemLedgEntries."Remaining Quantity".Value <> '' then
            repeat
                Evaluate(LineQty, AvailableItemLedgEntries."Remaining Quantity".Value);
                ActualQty += LineQty;
            until not AvailableItemLedgEntries.Next();

        Assert.AreEqual(GlobalILESupply, ActualQty, 'Wrong drilled down ILE qty.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailPOModalHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    var
        ActualQty: Decimal;
        LineQty: Decimal;
    begin
        AvailablePurchaseLines.First();
        if AvailablePurchaseLines."Outstanding Qty. (Base)".Value <> '' then
            repeat
                Evaluate(LineQty, AvailablePurchaseLines."Outstanding Qty. (Base)".Value);
                ActualQty += LineQty;
            until not AvailablePurchaseLines.Next();

        Assert.AreEqual(GlobalPOSupply, ActualQty, 'Wrong drilled down PO qty.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailAOModalHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    var
        ActualQty: Decimal;
        LineQty: Decimal;
    begin
        AvailableAssemblyHeaders.First();
        if AvailableAssemblyHeaders."Remaining Quantity".Value <> '' then
            repeat
                Evaluate(LineQty, AvailableAssemblyHeaders."Remaining Quantity".Value);
                ActualQty += LineQty;
            until not AvailableAssemblyHeaders.Next();

        Assert.AreEqual(GlobalAOSupply, ActualQty, 'Wrong drilled down AO qty.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyHeadersPageHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.Reserve.Invoke();
        AvailableAssemblyHeaders."Reserved Qty. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyLinesPageHandler(var AvailableAssemblyLines: TestPage "Available - Assembly Lines")
    begin
        AvailableAssemblyLines.Reserve.Invoke();
        AvailableAssemblyLines."Reserved Qty. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLinesPageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.Reserve.Invoke();
        AvailableProdOrderLines."Reserved Qty. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderCompPageHandler(var AvailableProdOrderComp: TestPage "Available - Prod. Order Comp.")
    begin
        AvailableProdOrderComp.Reserve.Invoke();
        AvailableProdOrderComp."Reserved Qty. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableTransferLinesPageHandler(var AvailableTransferLines: TestPage "Available - Transfer Lines")
    begin
        AvailableTransferLines.Reserve.Invoke();
        AvailableTransferLines."Reserved Qty. Inbnd. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderCompCancelReservationPageHandler(var AvailableProdOrderComp: TestPage "Available - Prod. Order Comp.")
    begin
        AvailableProdOrderComp.CancelReservation.Invoke();
        AvailableProdOrderComp."Reserved Qty. (Base)".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderCompDrillDownQtyPageHandler(var AvailableProdOrderComp: TestPage "Available - Prod. Order Comp.")
    begin
        AvailableProdOrderComp.ReservedQuantity.DrillDown();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DueDateBeforeWorkDate(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, MsgDueDateBeforeWorkDate) > 0, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;  // Reserve inbound transfer
    end;
}

