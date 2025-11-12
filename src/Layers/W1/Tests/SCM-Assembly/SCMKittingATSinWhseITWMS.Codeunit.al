// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using System.Environment.Configuration;
using Microsoft.Warehouse.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Assembly.Document;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.BOM;

codeunit 137106 "SCM Kitting ATS in Whse/IT WMS"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Assemble-to-Stock] [Warehouse] [Item Tracking] [SCM]
        IsInitialized := false;
    end;

    var
        LocationWMS: Record Location;
        CompItem: Record Item;
        KitItem: Record Item;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        MSG_PICK_ACT_CREATED: Label 'Pick activity no.';
        MSG_NOTHING_TO_HANDLE: Label 'Nothing to handle.';
        MSG_QTY_OUTST: Label 'You cannot handle more than the outstanding';
        MSG_SER_NO_MUST: Label 'Serial No. must have a value';
        MSG_LOT_NO_MUST: Label 'Lot No. must have a value';
        LocationTakeBinCode: Code[20];
        LocationAdditionalBinCode: Code[20];
        LocationToBinCode: Code[20];
        LocationFromBinCode: Code[20];
        LocationAdditionalPickBinCode: Code[20];
        MsgCount: Integer;
        WhseActivityType: Option "None",WhsePick,InvtMvmt;
        Tracking: Option Untracked,Lot,Serial,LotSerial;
        GLB_ITPageHandler: Option AssignITSpec,SelectITSpec,AssignITSpecPartial,PutManuallyITSpec;
        PAR_ITPage_AssignSerial: Boolean;
        PAR_ITPage_AssignLot: Boolean;
        PAR_ITPage_AssignPartial: Boolean;
        PAR_ITPage_AssignQty: Decimal;
        PAR_ITPage_ITNo: Code[20];
        PAR_ITPage_FINDDIR: Code[20];
        WorkDate2: Date;
        MSG_CANNOT_POST_CONS: Label 'You cannot post consumption for order no.';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        AssemblySetup: Record "Assembly Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT WMS");
        MsgCount := 0;
        ClearLastError();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT WMS");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode());

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LocationSetupWMS(LocationWMS);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT WMS");
    end;

    local procedure SetGenWarehouseEntriesFilter(var WarehouseEntry: Record "Warehouse Entry"; AssemblyHeader: Record "Assembly Header")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        WarehouseEntry.Reset();
        SourceCodeSetup.Get();
        WarehouseEntry.SetRange("Source Code", SourceCodeSetup.Assembly);
        WarehouseEntry.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseEntry.SetRange("Registering Date", AssemblyHeader."Posting Date");
        WarehouseEntry.SetRange("User ID", UserId);
    end;

    local procedure SetLocWarehouseEntriesFilter(var WarehouseEntry: Record "Warehouse Entry"; VariantCode: Code[20]; UOMCode: Code[20]; Quantity: Decimal; WarehouseEntryType: Integer; LocationCode: Code[20]; BinCode: Code[20]; ItemNo: Code[20]; SourceLineNo: Integer)
    begin
        WarehouseEntry.SetRange("Variant Code", VariantCode);
        WarehouseEntry.SetRange("Unit of Measure Code", UOMCode);
        WarehouseEntry.SetRange(Quantity, Quantity);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntryType);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        // Description is not set because of bug
        // WarehouseEntry.SETRANGE(Description,TempAssemblyLine.Description);
        // WarehouseEntry.SETRANGE("Source Document",WarehouseEntry."Source Document"::"Assembly Order");
        WarehouseEntry.SetRange("Source Line No.", SourceLineNo);
    end;

    local procedure VerifyWarehouseEntries(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; AssembledQty: Decimal; ShouldBeCreated: Boolean; ExpectedNoOfWhseEntries: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Verify whole amount of warehouse entries
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);

        SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader);
        if ShouldBeCreated then
            Assert.AreEqual(ExpectedNoOfWhseEntries, WarehouseEntry.Count,
              'Incorect number of warehouse entries for assembly ' + AssemblyHeader."No.")
        else
            Assert.AreEqual(0, WarehouseEntry.Count,
              'Incorect number of warehouse entries for assembly ' + AssemblyHeader."No.");

        // Verify warehouse entries for header assembly item
        SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader);
        SetLocWarehouseEntriesFilter(WarehouseEntry,
          AssemblyHeader."Variant Code",
          AssemblyHeader."Unit of Measure Code",
          AssembledQty,
          WarehouseEntry."Entry Type"::"Positive Adjmt.",
          AssemblyHeader."Location Code",
          AssemblyHeader."Bin Code",
          AssemblyHeader."Item No.",
          0);
        if ShouldBeCreated then
            Assert.AreEqual(1, WarehouseEntry.Count,
              'Incorrect number of warehouse entries for assembly item ' + AssemblyHeader."Item No.")
        else
            Assert.AreEqual(0, WarehouseEntry.Count,
              'Incorrect number of warehouse entries for assembly item ' + AssemblyHeader."Item No.");

        // Verify warehouse entries for components
        TempAssemblyLine.FindSet();
        repeat
            SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader);
            SetLocWarehouseEntriesFilter(WarehouseEntry,
              TempAssemblyLine."Variant Code",
              TempAssemblyLine."Unit of Measure Code",
              -TempAssemblyLine."Quantity to Consume",
              WarehouseEntry."Entry Type"::"Negative Adjmt.",
              TempAssemblyLine."Location Code",
              TempAssemblyLine."Bin Code",
              TempAssemblyLine."No.",
              TempAssemblyLine."Line No.");
            if ShouldBeCreated then
                Assert.AreEqual(1, WarehouseEntry.Count,
                  'Incorrect number of warehouse entries for assembly line ' + TempAssemblyLine."No.")
            else
                Assert.AreEqual(0, WarehouseEntry.Count,
                  'Incorrect number of warehouse entries for assembly line ' + TempAssemblyLine."No.");
        until TempAssemblyLine.Next() = 0;
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
            Assert.AreEqual(Quantity, 0, 'Incorrect Qty of Item ' + ItemNo + ' in Bin ' + BinCode);
    end;

    local procedure VerifyBinContentsMvmt(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; QtySupplement: Decimal; AssembledQty: Decimal)
    var
        Location: Record Location;
    begin
        // Verify bin content for header assembly item
        VerifyBinContent(AssemblyHeader."Location Code", AssemblyHeader."Bin Code", AssemblyHeader."Item No.", AssembledQty);

        // Verify bin contents for components
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            Location.Get(TempAssemblyLine."Location Code");
            if Location."Require Shipment" then begin
                VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
                  TempAssemblyLine."No.",
                  TempAssemblyLine.Quantity - TempAssemblyLine."Quantity to Consume" - TempAssemblyLine."Consumed Quantity");
                VerifyBinContent(TempAssemblyLine."Location Code", LocationTakeBinCode,
                  TempAssemblyLine."No.",
                  QtySupplement);
            end else begin
                VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
                  TempAssemblyLine."No.", 0);
                VerifyBinContent(TempAssemblyLine."Location Code", LocationTakeBinCode,
                  TempAssemblyLine."No.",
                  QtySupplement + TempAssemblyLine.Quantity - TempAssemblyLine."Quantity to Consume" - TempAssemblyLine."Consumed Quantity")
            end;
        until TempAssemblyLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyRegWhsePickHeader(AssemblyHeader: Record "Assembly Header"; ExpectedNoOfRegWhsePick: Integer; WhsePickNo: Code[20])
    var
        RegdWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
    begin
        RegdWhseActivityHdr.Reset();

        RegdWhseActivityHdr.SetRange("Location Code", AssemblyHeader."Location Code");
        RegdWhseActivityHdr.SetRange("Whse. Activity No.", WhsePickNo);
        Assert.AreEqual(ExpectedNoOfRegWhsePick, RegdWhseActivityHdr.Count, CopyStr(
            'There should be 1 registered WhsePickHeader within the filter: ' +
            RegdWhseActivityHdr.GetFilters, 1, 1024));
    end;

    [Normal]
    local procedure VerifyRegWhsePick(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; WarehouseActivityHeaderNo: Code[20]; ExpectedNoOfRegWhsePick: Integer; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        RegdWhseActivityLine: Record "Registered Whse. Activity Line";
        RegdWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        ExpectedNoOfLines: Integer;
    begin
        VerifyRegWhsePickHeader(AssemblyHeader, ExpectedNoOfRegWhsePick, WarehouseActivityHeaderNo);

        RegdWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeaderNo);
        RegdWhseActivityHdr.FindFirst();

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);

        RegdWhseActivityLine.Reset();
        RegdWhseActivityLine.SetRange("No.", RegdWhseActivityHdr."No.");

        ExpectedNoOfLines := 2 * TempAssemblyLine.Count();
        if AdditionalBinQty > 0 then
            ExpectedNoOfLines += 2;
        Assert.AreEqual(
          ExpectedNoOfLines, RegdWhseActivityLine.Count, CopyStr('There are not ' + Format(ExpectedNoOfLines) +
            ' reg Invt mvmt lines within the filter: ' + RegdWhseActivityHdr.GetFilters, 1, 1024));

        VerifyRegWhsePickLines(RegdWhseActivityHdr, TempAssemblyLine,
          RegdWhseActivityLine."Action Type"::Take, LocationTakeBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
        VerifyRegWhsePickLines(RegdWhseActivityHdr, TempAssemblyLine,
          RegdWhseActivityLine."Action Type"::Place, LocationToBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
    end;

    [Normal]
    local procedure VerifyWhseActivity(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; var WhseActivityHdr: Record "Warehouse Activity Header"; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        ExpectedNoOfItems: Integer;
    begin
        VerifyWhseActivityHeader(AssemblyHeader, WhseActivityHdr);

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");

        ExpectedNoOfItems := 2 * TempAssemblyLine.Count();
        if AdditionalBinQty > 0 then
            ExpectedNoOfItems += 2;

        Assert.AreEqual(
          ExpectedNoOfItems, WhseActivityLine.Count, CopyStr('There are not ' + Format(ExpectedNoOfItems) +
            ' whse activity lines within the filter: ' + WhseActivityHdr.GetFilters, 1, 1024));

        VerifyWhseActivityLines(WhseActivityHdr, TempAssemblyLine,
          WhseActivityLine."Action Type"::Take, LocationTakeBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
        VerifyWhseActivityLines(WhseActivityHdr, TempAssemblyLine,
          WhseActivityLine."Action Type"::Place, LocationToBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
    end;

    [Normal]
    local procedure VerifyWhseActivityHeader(AssemblyHeader: Record "Assembly Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange("Location Code", AssemblyHeader."Location Code");

        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::Pick then
            // WarehouseActivityHeader.SETRANGE("Source No.",AssemblyHeader."No.");
            // WarehouseActivityHeader.SETRANGE("Source Document",WarehouseRequest."Source Document"::"Assembly Consumption");
            // WarehouseActivityHeader.SETRANGE("Source Type",DATABASE::"Assembly Line");
            // WarehouseActivityHeader.SETRANGE("Source Subtype",AssemblyHeader."Document Type");
            // WarehouseActivityHeader.SETRANGE("Destination Type",WarehouseActivityHeader."Destination Type"::Item);
            // WarehouseActivityHeader.SETRANGE("Destination No.",AssemblyHeader."Item No.");
            // WarehouseActivityHeader.SETRANGE("Destination Type",WarehouseActivityHeader."Destination Type"::Item);
            // WarehouseActivityHeader.SETRANGE("Destination No.",AssemblyHeader."Item No.");
            ;

        Assert.AreEqual(1, WarehouseActivityHeader.Count, CopyStr('There should be 1 whse activity header within the filter: ' +
            WarehouseActivityHeader.GetFilters, 1, 1024));

        WarehouseActivityHeader.FindFirst();
    end;

    [Normal]
    local procedure VerifyRegWhsePickLine(RegdWhseActivityHdr: Record "Registered Whse. Activity Hdr."; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; Qty: Decimal)
    var
        RegdWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegdWhseActivityLine.Reset();
        RegdWhseActivityLine.SetRange("No.", RegdWhseActivityHdr."No.");
        RegdWhseActivityLine.SetRange("Action Type", ActionType);
        RegdWhseActivityLine.SetRange("Bin Code", BinCode);
        RegdWhseActivityLine.SetRange("Location Code", TempAssemblyLine."Location Code");
        RegdWhseActivityLine.SetRange("Item No.", TempAssemblyLine."No.");
        RegdWhseActivityLine.SetRange(Description, TempAssemblyLine.Description);
        RegdWhseActivityLine.SetRange("Unit of Measure Code", TempAssemblyLine."Unit of Measure Code");
        RegdWhseActivityLine.SetRange("Qty. per Unit of Measure", 1);
        RegdWhseActivityLine.SetRange("Due Date", TempAssemblyLine."Due Date");

        RegdWhseActivityLine.SetRange(Quantity, Qty);
        RegdWhseActivityLine.SetRange("Qty. (Base)", Qty);

        Assert.AreEqual(1, RegdWhseActivityLine.Count, CopyStr('There are not 1 registered whse pick lines within the filter: ' +
            RegdWhseActivityLine.GetFilters, 1, 1024));
    end;

    [Normal]
    local procedure VerifyRegWhsePickLines(RegdWhseActivityHdr: Record "Registered Whse. Activity Hdr."; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        RegdWhseActivityLine: Record "Registered Whse. Activity Line";
        Location: Record Location;
        Item: Record Item;
        QtyOnRegPick: Decimal;
    begin
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            if TempAssemblyLine."No." = NotEnoughItemNo then
                VerifyRegWhsePickLine(RegdWhseActivityHdr, TempAssemblyLine, ActionType, BinCode, NotEnoughQty)
            else begin
                Location.Get(TempAssemblyLine."Location Code");
                if Location."Require Shipment" then begin
                    Item.Get(TempAssemblyLine."No.");
                    Item."Location Filter" := Location.Code;
                    Item.CalcFields(Inventory);
                    if Item.Inventory < TempAssemblyLine."Remaining Quantity" then
                        QtyOnRegPick := Item.Inventory
                    else
                        QtyOnRegPick := TempAssemblyLine."Remaining Quantity";
                    VerifyRegWhsePickLine(RegdWhseActivityHdr, TempAssemblyLine, ActionType, BinCode, QtyOnRegPick);
                end else
                    VerifyRegWhsePickLine(RegdWhseActivityHdr, TempAssemblyLine, ActionType, BinCode,
                      TempAssemblyLine."Quantity to Consume");
            end;
        until TempAssemblyLine.Next() = 0;

        if AdditionalBinQty > 0 then begin
            TempAssemblyLine.Reset();
            TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
            TempAssemblyLine.SetRange("No.", NotEnoughItemNo);
            TempAssemblyLine.FindFirst();

            if ActionType = RegdWhseActivityLine."Action Type"::Take then
                VerifyRegWhsePickLine(RegdWhseActivityHdr, TempAssemblyLine, ActionType, LocationAdditionalBinCode,
                  AdditionalBinQty)
            else
                VerifyRegWhsePickLine(RegdWhseActivityHdr, TempAssemblyLine, ActionType, BinCode,
                  AdditionalBinQty);
        end;
    end;

    [Normal]
    local procedure VerifyWhseActivityLines(WhseActivityHdr: Record "Warehouse Activity Header"; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Item: Record Item;
        QtyOnPick: Decimal;
    begin
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            if TempAssemblyLine."No." = NotEnoughItemNo then
                VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, NotEnoughQty, NotEnoughQty)
            else begin
                Location.Get(TempAssemblyLine."Location Code");
                if Location."Require Shipment" then begin
                    Item.Get(TempAssemblyLine."No.");
                    Item."Location Filter" := Location.Code;
                    Item.CalcFields(Inventory);
                    if Item.Inventory < TempAssemblyLine."Remaining Quantity" then
                        QtyOnPick := Item.Inventory
                    else
                        QtyOnPick := TempAssemblyLine."Remaining Quantity";
                    VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, QtyOnPick, QtyOnPick);
                end else
                    VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, TempAssemblyLine."Quantity to Consume",
                      TempAssemblyLine."Quantity to Consume");
            end;
        until TempAssemblyLine.Next() = 0;

        if AdditionalBinQty > 0 then begin
            TempAssemblyLine.Reset();
            TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
            TempAssemblyLine.SetRange("No.", NotEnoughItemNo);
            TempAssemblyLine.FindFirst();

            if ActionType = WhseActivityLine."Action Type"::Take then
                VerifyWhseActivityLine(
                  WhseActivityHdr, TempAssemblyLine, ActionType, LocationAdditionalBinCode, AdditionalBinQty, AdditionalBinQty)
            else
                VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, AdditionalBinQty, AdditionalBinQty);
        end;
    end;

    [Normal]
    local procedure VerifyWhseActivityLine(WhseActivityHdr: Record "Warehouse Activity Header"; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; Qty: Decimal; QtyToHandle: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");
        WhseActivityLine.SetRange("Action Type", ActionType);
        WhseActivityLine.SetRange("Location Code", TempAssemblyLine."Location Code");
        WhseActivityLine.SetRange("Item No.", TempAssemblyLine."No.");
        WhseActivityLine.SetRange("Bin Code", BinCode);
        WhseActivityLine.SetRange(Quantity, Qty);

        Assert.AreEqual(1, WhseActivityLine.Count, CopyStr('There is no whse activity line within the filter: ' +
            WhseActivityLine.GetFilters, 1, 1024));
        WhseActivityLine.FindFirst();

        Assert.AreEqual(TempAssemblyLine.Description, WhseActivityLine.Description, 'Incorrect descriprion');
        Assert.AreEqual(TempAssemblyLine."Unit of Measure Code", WhseActivityLine."Unit of Measure Code", 'Incorrect UOM');
        Assert.AreEqual(TempAssemblyLine."Due Date", WhseActivityLine."Due Date", 'Incorrect due date');
        Assert.AreEqual(1, WhseActivityLine."Qty. per Unit of Measure", 'Incorrect qty per UOM');
        Assert.AreEqual(Qty, WhseActivityLine."Qty. (Base)", 'Incorrect qty base');

        Assert.AreEqual(QtyToHandle, WhseActivityLine."Qty. to Handle", 'incorrect qty to handle');
        if QtyToHandle > 0 then
            Assert.AreEqual(Qty - QtyToHandle, WhseActivityLine."Qty. Handled", 'incorrect qty. handled')
        else
            Assert.AreEqual(0, WhseActivityLine."Qty. Handled", 'incorrect qty. handled');
    end;

    local procedure AddCompInventoryNotEnough(AssemblyHeader: Record "Assembly Header"; NotEnoughNo: Integer; var NotEnoughItemNo: Code[20]; CompQtyFactor: Integer; var ResultQtys: array[10] of Decimal; AddAdditionalQty: Boolean; BinToPutCode: Code[20])
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        i: Integer;
        ItemsCount: Integer;
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();

        // Calculate result quantities
        i := 1;
        repeat
            ResultQtys[i] := AssemblyLine.Quantity * CompQtyFactor / 100;
            if i = NotEnoughNo then begin
                Item.Get(AssemblyLine."No.");
                NotEnoughItemNo := Item."No.";
                ResultQtys[i] := Round(ResultQtys[i], 0.00001, '>');
                ResultQtys[i] -= 0.00002;
                ItemsCount := AssemblyLine.Count + 1;
                ResultQtys[ItemsCount] := 0.00002;
            end else
                ResultQtys[i] := Round(ResultQtys[i], 0.00001, '>');

            i += 1;
        until AssemblyLine.Next() = 0;

        // Add inventory
        i := 1;
        AssemblyLine.FindSet();
        repeat
            LibraryAssembly.AddItemInventory(AssemblyLine, WorkDate2, AssemblyLine."Location Code", BinToPutCode, ResultQtys[i]);
            i += 1;
        until AssemblyLine.Next() = 0;

        // Add rest inventory to additional bin
        if AddAdditionalQty then begin
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
            AssemblyLine.SetRange("No.", NotEnoughItemNo);
            AssemblyLine.FindFirst();

            LibraryAssembly.AddItemInventory(
              AssemblyLine, WorkDate2, AssemblyLine."Location Code", LocationAdditionalBinCode, ResultQtys[ItemsCount]);
        end;
    end;

    local procedure LocationSetupWMS(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandIntInRange(8, 12));
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        LibraryWarehouse.FindBin(Bin, Location.Code, 'QC', 1);
        LocationToBinCode := Bin.Code;
        LibraryWarehouse.FindBin(Bin, Location.Code, 'QC', 2);
        LocationFromBinCode := Bin.Code;

        Location.Validate("From-Assembly Bin Code", LocationFromBinCode);
        Location.Validate("To-Assembly Bin Code", LocationToBinCode);
        Location.Modify(true);

        AssignBinCodesWMS();
    end;

    [Normal]
    local procedure AssignBinCodesWMS()
    var
        Bin: Record Bin;
    begin
        LocationToBinCode := LocationWMS."To-Assembly Bin Code";
        LocationFromBinCode := LocationWMS."From-Assembly Bin Code";

        LibraryWarehouse.FindBin(Bin, LocationWMS.Code, 'PICK', 3);
        LocationAdditionalBinCode := Bin.Code;

        LibraryWarehouse.FindBin(Bin, LocationWMS.Code, 'PICK', 1);
        LocationTakeBinCode := Bin.Code;

        LibraryWarehouse.FindBin(Bin, LocationWMS.Code, 'PICK', 2);
        LocationAdditionalPickBinCode := Bin.Code;
    end;

    [Normal]
    local procedure PostAssemblyHeader(AssemblyHeaderNo: Code[20]; ExpectedError: Text[1024])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Init();
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure CreateWhsePickAndVerify(AssemblyHeaderNo: Code[20]; var TempAssemblyLine: Record "Assembly Line" temporary; ExpectedNoOfRegInvtMmnt: Integer; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();

        if AssemblyHeader."Assembled Quantity" > 0 then begin
            // assuming that previous posting has created picks for the full remaining qty.
            Commit(); // to save state before expected error
            asserterror LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
            Assert.IsTrue(StrPos(GetLastErrorText, MSG_NOTHING_TO_HANDLE) > 0, '');
        end else begin
            LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
            VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHeader, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);

            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

            VerifyRegWhsePick(AssemblyHeader, TempAssemblyLine, WhseActivityHeader."No.", ExpectedNoOfRegInvtMmnt, NotEnoughItemNo,
              NotEnoughQty, AdditionalBinQty);
        end;
    end;

    [Normal]
    local procedure UpdateWhseActivityLine(NoToChange: Integer; var ChangedItemNo: Code[20]; var ChangedItemQty: Decimal; var TempAssemblyLine: Record "Assembly Line" temporary; WhseActivityHeader: Record "Warehouse Activity Header"; QtyToAdd: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        i := 1;
        repeat
            if i = NoToChange then
                ChangedItemNo := TempAssemblyLine."No.";
            i += 1;
        until TempAssemblyLine.Next() = 0;

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.SetRange("Item No.", ChangedItemNo);
        Assert.AreEqual(2, WhseActivityLine.Count, CopyStr('There are not 2 registered whse activity lines within the filter: ' +
            WhseActivityLine.GetFilters, 1, 1024));

        WhseActivityLine.FindSet();
        ChangedItemQty := Round(WhseActivityLine.Quantity, 0.00001, '<');
        ChangedItemQty += QtyToAdd;

        repeat
            WhseActivityLine.Validate("Qty. to Handle", ChangedItemQty);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;
    end;

    local procedure NormalPostingWMS(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; QtySupplement: Decimal): Code[20]
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssembledQty: Decimal;
    begin
        AssignBinCodesWMS();
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, QtySupplement, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContentsMvmt(AssemblyHeader, TempAssemblyLine, QtySupplement, AssembledQty);

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        VerifyWarehouseEntries(AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);

        exit(AssemblyHeader."No.");
    end;

    local procedure NotEnoughItemPostingWMS(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; AddAdditionalQty: Boolean; ExpectedErrorMessage: Text[1024])
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        NotEnoughItemNo: Code[20];
        NotEnoughNo: Integer;
        NoOfItems: Integer;
        Qtys: array[10] of Decimal;
    begin
        AssignBinCodesWMS();
        NoOfItems := LibraryRandom.RandIntInRange(2, 3);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, NoOfItems);

        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems);
        AddCompInventoryNotEnough(AssemblyHeader, NotEnoughNo, NotEnoughItemNo, PartialPostFactor, Qtys, AddAdditionalQty,
          LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        if AddAdditionalQty then
            CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, NotEnoughItemNo, Qtys[NotEnoughNo], Qtys[NoOfItems + 1])
        else
            CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, NotEnoughItemNo, Qtys[NotEnoughNo], 0);

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    local procedure MoveNotEnoughItemWMS(HeaderQtyFactor: Integer; PartialPostFactor: Integer)
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        NotEnoughItemNo: Code[20];
        NotEnoughNo: Integer;
        NoOfItems: Integer;
        NotEnoughQty: Decimal;
    begin
        AssignBinCodesWMS();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        // Create Warehouse Pick and Verify
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHeader, '', 0, 0);

        // Reduce Quantity to Handled of one of the items
        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems);
        UpdateWhseActivityLine(NotEnoughNo, NotEnoughItemNo, NotEnoughQty, TempAssemblyLine, WhseActivityHeader, -0.00001);

        // Register warehouse activity and verify
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        VerifyRegWhsePick(AssemblyHeader, TempAssemblyLine, WhseActivityHeader."No.", 1, NotEnoughItemNo, NotEnoughQty, 0);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader."No.", ''); // pick for the whole quantity has already been made as partial posting happens

        // Verify warehouse activity with rest of the item
        VerifyWhseActivityHeader(AssemblyHeader, WhseActivityHeader);

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");

        Assert.AreEqual(
          2, WhseActivityLine.Count, CopyStr('There are not 2 whse activity lines within the filter: ' +
            WhseActivityHeader.GetFilters, 1, 1024));

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.SetRange("No.", NotEnoughItemNo);
        TempAssemblyLine.FindFirst();

        VerifyWhseActivityLine(WhseActivityHeader, TempAssemblyLine, WhseActivityLine."Action Type"::Take, LocationTakeBinCode,
          TempAssemblyLine.Quantity, TempAssemblyLine.Quantity - NotEnoughQty);
        VerifyWhseActivityLine(WhseActivityHeader, TempAssemblyLine, WhseActivityLine."Action Type"::Place, LocationToBinCode,
          TempAssemblyLine.Quantity, TempAssemblyLine.Quantity - NotEnoughQty);

        // Register warehouse activity
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        VerifyRegWhsePickHeader(AssemblyHeader, 2, WhseActivityHeader."No.");

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_PICK_ACT_CREATED) > 0, PadStr('Unexpected message: ' + Message, 1024));
    end;

    local procedure PostingPartialIT(Location: Record Location; WhseActivity: Option; ExpectedErrorMessage: Text[1024]; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateAssemblyOrder(Location, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationToBinCode)
        else
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, 100);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, true, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, true, false, '-');

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, true, ExpectedErrorMessage);
    end;

    local procedure Post2Steps(Location: Record Location; WhseActivity: Option; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine2: Record "Assembly Line" temporary;
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        AssemblyHeaderNo: Code[20];
        HeaderQtyFactor: Decimal;
    begin
        HeaderQtyFactor := LibraryRandom.RandIntInRange(50, 60);

        AssemblyHeaderNo := NormalPostingIT(Location, HeaderQtyFactor, 0, WhseActivity, '', AssignITBeforeWhseAct, AssignITOnWhseAct, false);

        // Post rest of the asembly order
        AssemblyHeader.Reset();
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationToBinCode)
        else
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationTakeBinCode);

        LibraryAssembly.ReopenAO(AssemblyHeader);

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        AssemblyLine.FindSet();
        repeat
            if AssemblyLine."Quantity to Consume" > 0 then begin
                AssemblyLine.Validate("Quantity to Consume", 1);
                AssemblyLine.Modify(true);
                TempAssemblyLine2 := AssemblyLine;
                TempAssemblyLine2.Insert();
            end;
        until (AssemblyLine.Next() = 0);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        if AssignITBeforeWhseAct then begin
            WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
            WhseActivityLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
            WhseActivityLine.SetRange("Source No.", AssemblyHeader."No.");
            if WhseActivityLine.FindSet() then
                repeat
                    if WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.") then
                        WhseActivityHeader.Delete(true);
                until WhseActivityLine.Next() = 0;

            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, false, true, '+')
            else
                AssignITToAssemblyLines(AssemblyHeader, false, false, '+');

            if not AssemblyHeader.CompletelyPicked() then
                CreateAndRegisterWhseActivity(AssemblyHeaderNo, WhseActivity, AssignITOnWhseAct, false, '');
        end else begin
            WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
            WhseActivityLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
            WhseActivityLine.SetRange("Source No.", AssemblyHeader."No.");
            if WhseActivityLine.FindFirst() then begin
                WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

                if AssignITOnWhseAct then
                    AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, false);

                LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            end;
        end;

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure PurchaseComponentsToBin(AssemblyHeader: Record "Assembly Header"; QtySupplement: Decimal; Location: Record Location; BinCode: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(Location.Code, PurchaseHeader);

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        if AssemblyLine.FindSet() then
            repeat
                CreatePurchaseLine(PurchaseHeader, AssemblyLine."No.", Location, BinCode,
                  Round(AssemblyLine.Quantity + QtySupplement, 1, '>'));
            until AssemblyLine.Next() = 0;

        PostPurchaseHeader(PurchaseHeader, Location, '');
    end;

    local procedure PurchaseComponentsNotEnough(Location: Record Location; AssemblyHeader: Record "Assembly Header"; NotEnoughNo: Integer; var NotEnoughItemNo: Code[20]; CompQtyFactor: Integer; var ResultQtys: array[10] of Decimal; AddAdditionalQty: Boolean; BinToPutCode: Code[20])
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
        ItemsCount: Integer;
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();

        // Calculate result quantities
        i := 1;
        repeat
            ResultQtys[i] := AssemblyLine.Quantity * CompQtyFactor / 100;
            if i = NotEnoughNo then begin
                Item.Get(AssemblyLine."No.");
                NotEnoughItemNo := Item."No.";
                ResultQtys[i] := Round(ResultQtys[i], 1, '>');
                ResultQtys[i] -= 2;
                ItemsCount := AssemblyLine.Count + 1;
                ResultQtys[ItemsCount] := 2;
            end else
                ResultQtys[i] := Round(ResultQtys[i], 1, '>');

            i += 1;
        until AssemblyLine.Next() = 0;

        // Add inventory
        CreatePurchaseHeader(Location.Code, PurchaseHeader);

        i := 1;
        AssemblyLine.FindSet();
        repeat
            CreatePurchaseLine(PurchaseHeader, AssemblyLine."No.", Location, BinToPutCode, ResultQtys[i]);
            i += 1;
        until AssemblyLine.Next() = 0;

        // Add rest inventory to additional bin
        if AddAdditionalQty then begin
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
            AssemblyLine.SetRange("No.", NotEnoughItemNo);
            AssemblyLine.FindFirst();

            CreatePurchaseLine(PurchaseHeader, AssemblyLine."No.",
              Location, LocationAdditionalBinCode, ResultQtys[ItemsCount]);
            PostPurchaseHeader(PurchaseHeader, Location, NotEnoughItemNo);
        end else
            PostPurchaseHeader(PurchaseHeader, Location, '');
    end;

    [Normal]
    local procedure CreateAssemblyOrder(Location: Record Location; Qty: Integer; var AssemblyHeader: Record "Assembly Header")
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, KitItem."No.", Location.Code, Qty, '');
        LibraryKitting.AddLine(
            AssemblyHeader, "BOM Component Type"::Item, CompItem."No.",
            LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, CompItem."No.", true), LibraryRandom.RandIntInRange(2, 4), 1, '');
    end;

    [Normal]
    local procedure CreateItems(ItemTracking: Option)
    begin
        CreateTrackedItem(CompItem, ItemTracking);
        CreateTrackedItem(KitItem, Tracking::Untracked);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; TrackingType: Option)
    var
        Serial: Boolean;
        Lot: Boolean;
    begin
        LibraryInventory.CreateItem(Item);
        if TrackingType <> Tracking::Untracked then begin
            Lot := (TrackingType = Tracking::Lot) or (TrackingType = Tracking::LotSerial);
            Serial := (TrackingType = Tracking::Serial) or (TrackingType = Tracking::LotSerial);
            AssignItemTrackingCode(Item, Lot, Serial);
        end;
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean)
    begin
        if not ItemTrackingCode.Get(Serial) then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Validate(Code,
              LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code"));
            ItemTrackingCode.Insert(true);
            ItemTrackingCode.Validate("SN Specific Tracking", Serial);
            ItemTrackingCode.Validate("Lot Specific Tracking", Lot);
            ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
            ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure CreatePickFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    [Normal]
    local procedure CreatePurchaseHeader(LocationCode: Code[10]; var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
    end;

    [Normal]
    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Location: Record Location; BinCode: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", Location.Code);
        if not Location."Require Receive" then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);

        AssignITToPurchLine(PurchaseLine);
    end;

    [Normal]
    local procedure CreateAndRegisterWhseActivity(AssemblyHeaderNo: Code[20]; WhseActivity: Option; AssignITOnWhseAct: Boolean; ITPartial: Boolean; ExpectedError: Text[1024])
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        AssemblyHeader: Record "Assembly Header";
    begin
        if WhseActivity = WhseActivityType::None then
            exit;

        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();

        case WhseActivity of
            WhseActivityType::WhsePick:
                LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
            WhseActivityType::InvtMvmt:
                LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        end;

        AutoFillQtyWhseActivity(AssemblyHeader, WhseActivityHeader);

        if AssignITOnWhseAct then
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, ITPartial);

        if ExpectedError = '' then begin
            EmptyQtyToHandleForLinesWithoutIT(WhseActivityHeader);
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        end else begin
            Commit(); // to save state before expected error
            asserterror LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            Assert.IsTrue(StrPos(GetLastErrorText, ExpectedError) > 0,
              'Expected:' + ExpectedError + '. Actual:' + GetLastErrorText);
            ClearLastError();
        end;
    end;

    local procedure EmptyQtyToHandleForLinesWithoutIT(WhseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.SetRange("Serial No.", '');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.SetFilter("Qty. to Handle", '<>%1', 0);
        if WhseActivityLine.FindSet() then
            repeat
                Item.Get(WhseActivityLine."Item No.");
                if Item."Item Tracking Code" <> '' then begin
                    WhseActivityLine.Validate("Qty. to Handle", 0);
                    WhseActivityLine.Modify(true);
                end;
            until WhseActivityLine.Next() = 0;
    end;

    [Normal]
    local procedure PrepareOrderPosting(var AssemblyHeader: Record "Assembly Header"; HeaderQtyFactor: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        ITType: Option;
    begin
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble" * HeaderQtyFactor / 100);
        AssemblyHeader.Modify(true);

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        if AssemblyLine.FindSet() then
            repeat
                GetItemIT(AssemblyLine."No.", ITType);
                if (ITType = Tracking::Serial) or (ITType = Tracking::LotSerial) then begin
                    AssemblyLine.Validate("Quantity to Consume", Round(AssemblyLine."Quantity to Consume", 1, '<'));
                    AssemblyLine.Modify(true)
                end;
            until (AssemblyLine.Next() = 0);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
    end;

    [Normal]
    local procedure PostPurchaseHeader(PurchaseHeader: Record "Purchase Header"; Location: Record Location; NotEnoughItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
        PurchaseHeaderNo: Code[20];
    begin
        PurchaseHeaderNo := PurchaseHeader."No.";

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        if Location."Require Receive" then begin
            LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

            WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
            WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
            WhseReceiptLine.FindFirst();
            WarehouseReceiptHeader.Get(WhseReceiptLine."No.");
            LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        end;

        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("No.", PurchaseHeaderNo);
        PurchaseHeader.FindFirst();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        if Location."Require Put-away" then begin
            WarehouseActivityHeader.SetRange("Location Code", Location.Code);
            WarehouseActivityHeader.FindFirst();
            WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
            WarehouseActivityLine.FindFirst();

            WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

            LibraryWarehouse.FindBin(Bin, Location.Code, 'PICK', 4);
            WarehouseActivityLine.Reset();
            WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
            WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
            if WarehouseActivityLine.FindSet() then
                repeat
                    WarehouseActivityLine.Validate("Zone Code", 'PICK');
                    WarehouseActivityLine.Validate("Bin Code", Bin.Code);
                    WarehouseActivityLine.Modify(true)
                until (WarehouseActivityLine.Next() = 0);

            if (LocationAdditionalPickBinCode <> '') and (NotEnoughItemNo <> '') then begin
                WarehouseActivityLine.Reset();
                WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
                WarehouseActivityLine.SetRange("Item No.", NotEnoughItemNo);
                WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
                WarehouseActivityLine.FindSet();

                WarehouseActivityLine.Validate("Bin Code", LocationAdditionalPickBinCode);
                WarehouseActivityLine.Modify(true);
                WarehouseActivityLine.Next();
                WarehouseActivityLine.Validate("Bin Code", LocationAdditionalPickBinCode);
                WarehouseActivityLine.Modify(true);
            end;

            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        end;
    end;

    local procedure CreateWhseJournalLine(WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; Qty: Decimal; UomCode: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        WarehouseJournalLine.Validate("Unit of Measure Code", UomCode);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure MoveNotEnoughItem(Location: Record Location; HeaderQtyFactor: Integer; WhseActivity: Option; ExpectedErrorMessage: Text[1024]; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean; QtyToAdd: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAssemblyOrder(Location, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationToBinCode)
        else
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, false, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, false, false, '-');

        // Create Whse Activity
        case WhseActivity of
            WhseActivityType::WhsePick:
                LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
            WhseActivityType::InvtMvmt:
                LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        end;

        AutoFillQtyWhseActivity(AssemblyHeader, WhseActivityHeader);

        // Update Quantity to Handled of one of the items
        UpdateWhseActivityLineIT(WhseActivityHeader, CompItem."No.", QtyToAdd);

        if AssignITOnWhseAct then
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, false);

        // Register whse activity
        EmptyQtyToHandleForLinesWithoutIT(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        PrepareOrderPosting(AssemblyHeader, 100);

        if AssignITOnWhseAct then
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, false);

        // Register rest of the whse activity
        EmptyQtyToHandleForLinesWithoutIT(WhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');
    end;

    [Normal]
    local procedure AutoFillQtyWhseActivity(AssemblyHeader: Record "Assembly Header"; var WhseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityHeader.Reset();
        WhseActivityHeader.SetRange("Location Code", AssemblyHeader."Location Code");
        WhseActivityHeader.FindLast();

        // Check that quantity is not autofilled
        if WhseActivityHeader.Type <> WhseActivityHeader.Type::Pick then begin
            WhseActivityLine.Reset();
            WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");

            repeat
                Assert.AreEqual(0, WhseActivityLine."Qty. to Handle", 'Incorrect value');
            until WhseActivityLine.Next() = 0;

            LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        end;
    end;

    local procedure RecreateWhseActivity(Location: Record Location; WhseActivity: Option; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHdr: Record "Warehouse Activity Header";
        HeaderQtyFactor: Decimal;
    begin
        HeaderQtyFactor := LibraryRandom.RandIntInRange(50, 60);

        CreateAssemblyOrder(Location, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationToBinCode)
        else
            PurchaseComponentsToBin(AssemblyHeader, 0, Location, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, false, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, false, false, '-');

        case WhseActivity of
            WhseActivityType::WhsePick:
                LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
            WhseActivityType::InvtMvmt:
                LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        end;

        AutoFillQtyWhseActivity(AssemblyHeader, WhseActivityHdr);

        if AssignITOnWhseAct then
            AssignITWhseActivity(AssemblyHeader, WhseActivityHdr, false);

        WhseActivityHdr.Delete(true);

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, false, '');

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure AssignItemTrackingCode(var Item: Record Item; LotTracked: Boolean; SerialTracked: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, LotTracked, SerialTracked);

        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);

        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());

        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());

        Item.Modify(true);
    end;

    local procedure NormalPostingIT(Location: Record Location; HeaderQtyFactor: Decimal; QtySupplement: Decimal; WhseActivity: Option; ExpectedErrorMessage: Text[1024]; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean; ITPartial: Boolean): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateAssemblyOrder(Location, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsToBin(AssemblyHeader, QtySupplement, Location, LocationToBinCode)
        else
            PurchaseComponentsToBin(AssemblyHeader, QtySupplement, Location, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, ITPartial, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, ITPartial, false, '-');

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, ITPartial, '');

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure GetItemIT(ItemNo: Code[20]; var ITType: Option)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);

        if Item."Item Tracking Code" = '' then
            exit;

        ItemTrackingCode.Get(Item."Item Tracking Code");

        ITType := Tracking::Untracked;

        if ItemTrackingCode."Lot Specific Tracking" and ItemTrackingCode."SN Specific Tracking" then
            ITType := Tracking::LotSerial
        else
            if (not ItemTrackingCode."Lot Specific Tracking") and ItemTrackingCode."SN Specific Tracking" then
                ITType := Tracking::Serial
            else
                if ItemTrackingCode."Lot Specific Tracking" and (not ItemTrackingCode."SN Specific Tracking") then
                    ITType := Tracking::Lot;
    end;

    [Normal]
    local procedure PrepareHandleSelectEntries(ITPartial: Boolean)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::SelectITSpec;
        PAR_ITPage_AssignPartial := ITPartial;
    end;

    [Normal]
    local procedure PrepareHandlePutManually(ItemNo: Code[20]; ITType: Option; ITPartial: Boolean; Quantity: Decimal; FindDir: Code[10])
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::PutManuallyITSpec;
        PAR_ITPage_AssignLot := (ITType = Tracking::LotSerial) or (ITType = Tracking::Lot);
        PAR_ITPage_AssignSerial := (ITType = Tracking::LotSerial) or (ITType = Tracking::Serial);
        PAR_ITPage_AssignPartial := ITPartial;
        PAR_ITPage_AssignQty := Quantity;
        PAR_ITPage_ITNo := ItemNo;
        PAR_ITPage_FINDDIR := FindDir;
    end;

    local procedure PrepareHandleAssignPartial(ITType: Option; Quantity: Decimal)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::AssignITSpec;
        PAR_ITPage_AssignLot := (ITType = Tracking::LotSerial) or (ITType = Tracking::Lot);
        PAR_ITPage_AssignSerial := (ITType = Tracking::LotSerial) or (ITType = Tracking::Serial);
        PAR_ITPage_AssignPartial := true;
        PAR_ITPage_AssignQty := Quantity;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        case GLB_ITPageHandler of
            GLB_ITPageHandler::AssignITSpec, GLB_ITPageHandler::AssignITSpecPartial:
                if PAR_ITPage_AssignSerial then
                    HNDL_ITPage_AssignSerial(ItemTrackingLinesPage)
                else
                    if PAR_ITPage_AssignLot then
                        HNDL_ITPage_AssignLot(ItemTrackingLinesPage);
            GLB_ITPageHandler::SelectITSpec:
                HNDL_ITPage_SelectEntries(ItemTrackingLinesPage);
            GLB_ITPageHandler::PutManuallyITSpec:
                HNDL_ITPage_PutITManually(ItemTrackingLinesPage);
        end
    end;

    [ModalPageHandler]
    [HandlerFunctions('HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_AssignSerial(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Assign Serial No.".Invoke();
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_AssignLot(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Assign Lot No.".Invoke(); // Assign Lot No.
        if PAR_ITPage_AssignPartial then
            ItemTrackingLinesPage."Quantity (Base)".SetValue(PAR_ITPage_AssignQty);
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_SelectEntries(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Select Entries".Invoke(); // Select Entries
        if PAR_ITPage_AssignPartial then begin
            ItemTrackingLinesPage.Last();
            ItemTrackingLinesPage."Quantity (Base)".SetValue(ItemTrackingLinesPage."Quantity (Base)".AsInteger() - 1);
        end;

        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_PutITManually(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TrackedQty: Integer;
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", PAR_ITPage_ITNo);
        ItemLedgerEntry.Find(PAR_ITPage_FINDDIR);

        TrackedQty := ItemLedgerEntry.Count();

        if (ItemLedgerEntry."Serial No." <> '') and (PAR_ITPage_AssignQty < ItemLedgerEntry.Count) then
            TrackedQty := PAR_ITPage_AssignQty;

        if PAR_ITPage_AssignPartial then
            TrackedQty -= 1;

        if ItemTrackingLinesPage.Last() then
            ItemTrackingLinesPage.Next();

        while TrackedQty > 0 do begin
            TrackedQty -= 1;

            if StrLen(ItemLedgerEntry."Serial No.") > 0 then
                ItemTrackingLinesPage."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
            if StrLen(ItemLedgerEntry."Lot No.") > 0 then
                ItemTrackingLinesPage."Lot No.".SetValue(ItemLedgerEntry."Lot No.");

            if PAR_ITPage_AssignQty < ItemLedgerEntry.Quantity then
                ItemTrackingLinesPage."Quantity (Base)".SetValue(PAR_ITPage_AssignQty)
            else
                ItemTrackingLinesPage."Quantity (Base)".SetValue(ItemLedgerEntry.Quantity);
            if ItemLedgerEntry.Next() <> 0 then
                ItemTrackingLinesPage.Next();
        end;

        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_EnterQty(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        if PAR_ITPage_AssignLot then
            EnterQuantityPage.CreateNewLotNo.Value := 'yes';
        if PAR_ITPage_AssignPartial then
            EnterQuantityPage.QtyToCreate.SetValue(PAR_ITPage_AssignQty);
        EnterQuantityPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickMessageHandler1(Message: Text[1024])
    begin
        Assert.IsTrue(
          StrPos(Message, MSG_PICK_ACT_CREATED) > 0,
          CopyStr('Unexpected message ' + Format(MsgCount) + ': ' + Message + '; Expected: ' + MSG_PICK_ACT_CREATED, 1, 1024));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickMessageHandler2(Message: Text[1024])
    begin
        Assert.IsTrue(
          StrPos(Message, MSG_PICK_ACT_CREATED) > 0,
          PadStr('Unexpected message ' + Format(MsgCount) + ': ' + Message + '; Expected: ' + MSG_PICK_ACT_CREATED, 1024));
    end;

    local procedure AssignITToPurchLine(PurchaseLine: Record "Purchase Line")
    var
        ITType: Option;
    begin
        GetItemIT(PurchaseLine."No.", ITType);

        if ITType = Tracking::Untracked then
            exit;

        PrepareHandleAssignPartial(ITType, PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure AssignITToAssemblyLines(var AssemblyHeader: Record "Assembly Header"; ITPartial: Boolean; SelectEntries: Boolean; FindDir: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();
        repeat
            AssignITToAsmLine(AssemblyLine, ITPartial, SelectEntries, FindDir);
        until AssemblyLine.Next() = 0;
    end;

    local procedure AssignITToAsmLine(AssemblyLine: Record "Assembly Line"; ITPartial: Boolean; SelectEntries: Boolean; FindDir: Code[10])
    var
        ITType: Option;
    begin
        GetItemIT(AssemblyLine."No.", ITType);

        if ITType = Tracking::Untracked then
            exit;

        if SelectEntries then
            PrepareHandleSelectEntries(ITPartial)
        else
            PrepareHandlePutManually(AssemblyLine."No.", ITType, ITPartial, AssemblyLine."Quantity to Consume", FindDir);

        AssemblyLine.OpenItemTrackingLines();
    end;

    [Normal]
    local procedure AssignITWhseActivity(AssemblyHeader: Record "Assembly Header"; WhseActivityHeader: Record "Warehouse Activity Header"; ITPartial: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        if AssemblyLine.FindSet() then
            repeat
                AssingITWhseActivityLine(AssemblyLine."No.", WhseActivityHeader, ITPartial);
            until (AssemblyLine.Next() = 0);
    end;

    local procedure AssingITWhseActivityLine(ItemNo: Code[20]; WhseActivityHeader: Record "Warehouse Activity Header"; ITPartial: Boolean)
    var
        WhseActivityLineTake: Record "Warehouse Activity Line";
        WhseActivityLinePlace: Record "Warehouse Activity Line";
        RegdWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegdWhseActivityLine: Record "Registered Whse. Activity Line";
        TrackedQty: Integer;
    begin
        RegdWhseActivityHdr.Reset();
        RegdWhseActivityHdr.SetRange("Location Code", WhseActivityHeader."Location Code");
        RegdWhseActivityHdr.SetRange(Type, RegdWhseActivityHdr.Type::"Put-away");
        RegdWhseActivityHdr.FindLast();

        RegdWhseActivityLine.Reset();
        RegdWhseActivityLine.SetRange("No.", RegdWhseActivityHdr."No.");
        RegdWhseActivityLine.SetRange("Action Type", RegdWhseActivityLine."Action Type"::Place);
        RegdWhseActivityLine.FindSet();

        WhseActivityLineTake.Reset();
        WhseActivityLineTake.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLineTake.SetRange("Item No.", ItemNo);
        WhseActivityLineTake.SetRange("Serial No.", '');
        WhseActivityLineTake.SetRange("Lot No.", '');
        WhseActivityLineTake.SetRange("Action Type", WhseActivityLineTake."Action Type"::Take);

        TrackedQty := WhseActivityLineTake.Count();
        if ITPartial then
            TrackedQty := WhseActivityLineTake.Count - 1;
        repeat
            if TrackedQty = 0 then
                exit;

            TrackedQty -= 1;
            WhseActivityLineTake.Reset();
            WhseActivityLineTake.SetRange("No.", WhseActivityHeader."No.");
            WhseActivityLineTake.SetRange("Item No.", ItemNo);
            WhseActivityLineTake.SetRange("Serial No.", '');
            WhseActivityLineTake.SetRange("Lot No.", '');
            WhseActivityLineTake.SetRange("Action Type", WhseActivityLineTake."Action Type"::Take);
            WhseActivityLineTake.SetRange("Bin Code", RegdWhseActivityLine."Bin Code");
            if not WhseActivityLineTake.FindFirst() then
                exit; // in case of partial posting whse activity has less lines then in item ledger entries

            WhseActivityLinePlace.Reset();
            WhseActivityLinePlace.SetRange("No.", WhseActivityHeader."No.");
            WhseActivityLinePlace.SetRange("Item No.", ItemNo);
            WhseActivityLinePlace.SetRange("Serial No.", '');
            WhseActivityLinePlace.SetRange("Lot No.", '');
            WhseActivityLinePlace.SetRange("Action Type", WhseActivityLinePlace."Action Type"::Place);
            WhseActivityLinePlace.SetFilter("Line No.", '>=' + Format(WhseActivityLineTake."Line No."));
            WhseActivityLinePlace.FindFirst();

            WhseActivityLineTake.Validate("Serial No.", RegdWhseActivityLine."Serial No.");
            WhseActivityLinePlace.Validate("Serial No.", RegdWhseActivityLine."Serial No.");

            WhseActivityLineTake.Validate("Lot No.", RegdWhseActivityLine."Lot No.");
            WhseActivityLinePlace.Validate("Lot No.", RegdWhseActivityLine."Lot No.");

            WhseActivityLineTake.Modify(true);
            WhseActivityLinePlace.Modify(true);

        until RegdWhseActivityLine.Next() = 0;
    end;

    local procedure FindPutAwayPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    [Normal]
    local procedure UpdateWhseActivityLineIT(WhseActivityHeader: Record "Warehouse Activity Header"; ItemNoToUpdate: Code[20]; QtyToAdd: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        ChangedItemQty: Integer;
    begin
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.SetRange("Item No.", ItemNoToUpdate);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
        WhseActivityLine.FindFirst();

        ChangedItemQty := Round(WhseActivityLine.Quantity, 1, '<');
        ChangedItemQty += QtyToAdd;

        WhseActivityLine.Validate("Qty. to Handle", ChangedItemQty);
        WhseActivityLine.Modify(true);

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.SetRange("Item No.", ItemNoToUpdate);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.FindFirst();

        ChangedItemQty := Round(WhseActivityLine.Quantity, 1, '<');
        ChangedItemQty += QtyToAdd;

        WhseActivityLine.Validate("Qty. to Handle", ChangedItemQty);
        WhseActivityLine.Modify(true);
    end;

    local procedure NotEnoughItemPostingIT(Location: Record Location; HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; AddAdditionalQty: Boolean; WhseActivity: Option; ExpectedErrorMessagePost: Text[1024]; ExpectedErrorMessageReg: Text[1024]; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean; ITPartial: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        NotEnoughItemNo: Code[20];
        NotEnoughNo: Integer;
        Qtys: array[10] of Decimal;
    begin
        CreateAssemblyOrder(Location, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        NotEnoughNo := 1;

        if WhseActivity = WhseActivityType::None then
            PurchaseComponentsNotEnough(
              Location, AssemblyHeader, NotEnoughNo, NotEnoughItemNo, PartialPostFactor, Qtys, AddAdditionalQty, LocationToBinCode)
        else
            PurchaseComponentsNotEnough(
              Location, AssemblyHeader, NotEnoughNo, NotEnoughItemNo, PartialPostFactor, Qtys, AddAdditionalQty, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, ITPartial, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, ITPartial, false, '-');

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, ITPartial, ExpectedErrorMessageReg);

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessagePost);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullPost()
    begin
        // TC-WMS
        Initialize();
        NormalPostingWMS(100, 100, 0);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullPartCompPost()
    begin
        // TC-WMS
        Initialize();
        NormalPostingWMS(100, LibraryRandom.RandIntInRange(1, 99), 0);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSPartPost()
    begin
        // TC-WMS
        Initialize();
        NormalPostingWMS(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          0);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullPostQtySupplem()
    begin
        // TC-WMS
        Initialize();
        NormalPostingWMS(100, 100, LibraryRandom.RandIntInRange(1, 10));
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSPartPostQtySupplem()
    begin
        // TC-WMS
        Initialize();
        NormalPostingWMS(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 10));
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullPost2Steps()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblyHeaderNo: Code[20];
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        AssembledQty: Decimal;
        FullAssembledQty: Decimal;
    begin
        // TC-WMS
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 90);
        PartialPostFactor := HeaderQtyFactor;

        AssemblyHeaderNo := NormalPostingWMS(HeaderQtyFactor, PartialPostFactor, 0);

        // Post rest of the asembly order
        AssemblyHeader.Init();
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        AssemblyLine.FindSet();
        repeat
            if AssemblyLine."Quantity to Consume" > 0 then begin
                TempAssemblyLine2 := AssemblyLine;
                TempAssemblyLine2.Insert();
            end;
        until (AssemblyLine.Next() = 0);

        CreateWhsePickAndVerify(AssemblyHeaderNo, TempAssemblyLine2, 1, '', 0, 0);

        AssembledQty := AssemblyHeader."Quantity to Assemble";
        FullAssembledQty := AssemblyHeader.Quantity;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContentsMvmt(AssemblyHeader, TempAssemblyLine2, 0, FullAssembledQty);

        TempAssemblyLine2.Reset();
        TempAssemblyLine2.SetRange(Type, TempAssemblyLine2.Type::Item);
        VerifyWarehouseEntries(AssemblyHeader, TempAssemblyLine2, AssembledQty, true, 2 * (TempAssemblyLine2.Count + 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSPostNotRelease()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
    begin
        // TC-WMS
        Initialize();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        AssignBinCodesWMS();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        asserterror LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        Assert.ExpectedTestFieldError(AssemblyHeader.FieldCaption(Status), Format(AssemblyHeader.Status::Released));
        ClearLastError();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSCreateSame()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
    begin
        // TC-WMS
        Initialize();
        AssignBinCodesWMS();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, LibraryRandom.RandIntInRange(1, 3));
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        asserterror LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_NOTHING_TO_HANDLE) > 0,
          'Actual:' + GetLastErrorText + ',Expected:' + MSG_NOTHING_TO_HANDLE);
        ClearLastError();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSRecreate()
    var
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHdr: Record "Warehouse Activity Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        AssembledQty: Decimal;
    begin
        // TC-WMS
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        AssignBinCodesWMS();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHdr, '', 0, 0);

        WhseActivityHdr.Delete(true);

        CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContentsMvmt(AssemblyHeader, TempAssemblyLine, 0, AssembledQty);
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        VerifyWarehouseEntries(AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullNotEnoughItemInBin()
    begin
        // TC-WMS
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();

        NotEnoughItemPostingWMS(100, 100, false, MSG_CANNOT_POST_CONS);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSPartNotEnoughItemInBin()
    begin
        // TC-WMS
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks that no error appears during partial posting
        Initialize();

        NotEnoughItemPostingWMS(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          false, MSG_CANNOT_POST_CONS);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullNotEnoughItemInInv()
    begin
        // TC-WMS
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();

        NotEnoughItemPostingWMS(100, 100, true, '');
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSPartNotEnoughItemInInv()
    begin
        // TC-WMS
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during partial posting
        Initialize();

        NotEnoughItemPostingWMS(LibraryRandom.RandIntInRange(1, 99), LibraryRandom.RandIntInRange(1, 99), true, '');
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSPartPostMoveNotEnItem()
    begin
        // TC-WMS
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and posts.
        Initialize();

        MoveNotEnoughItemWMS(LibraryRandom.RandIntInRange(1, 100),
          LibraryRandom.RandIntInRange(1, 100));
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSFullPostMoveNotEnItem()
    begin
        // TC-WMS
        // There is enough item in inventory
        // Test creates whse pick for full posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and fully posts.
        Initialize();

        MoveNotEnoughItemWMS(LibraryRandom.RandIntInRange(1, 100),
          LibraryRandom.RandIntInRange(1, 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSPostNoWhsePick()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        NoOfItems: Integer;
    begin
        // TC-WMS
        Initialize();
        AssignBinCodesWMS();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        NoOfItems := LibraryRandom.RandIntInRange(3, 5);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, LibraryRandom.RandIntInRange(3, 9),
          AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        PostAssemblyHeader(AssemblyHeader."No.", MSG_CANNOT_POST_CONS);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSReuseFromAnotherOrder()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblyHeader2: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
        NoOfItems: Integer;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        I: Integer;
    begin
        // TC-WMS
        // Test checks that whse pick created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesWMS();

        HeaderQtyFactor := 100;
        PartialPostFactor := 100;

        NoOfItems := LibraryRandom.RandIntInRange(3, 5);
        LibraryInventory.CreateItem(AssemblyItem);

        for I := 1 to NoOfItems do
            LibraryAssembly.CreateAssemblyListComponent(
                Enum::"BOM Component Type"::Item, LibraryInventory.CreateItemNo(), AssemblyItem."No.", '', BOMComponent."Resource Usage Type"::Direct,
                LibraryRandom.RandIntInRange(1, 10), true);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AssemblyItem."No.", LocationWMS.Code, LibraryRandom.RandIntInRange(10, 20), '');

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, LibraryRandom.RandIntInRange(3, 9),
          AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateWhsePickAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        LibraryAssembly.ReopenAO(AssemblyHeader);

        HeaderQtyFactor := 10;
        PartialPostFactor := 10;
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble" * HeaderQtyFactor / 100);

        // Post asssembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');

        // Create another assembly order
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader2, WorkDate2, AssemblyItem."No.", LocationWMS.Code, Round(AssemblyHeader.Quantity * (100 - HeaderQtyFactor) / 100, 1, '<'),
          '');
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader2, TempAssemblyLine2, 100, 100, true, WorkDate2);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader2."No.", MSG_CANNOT_POST_CONS);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler')]
    [Scope('OnPrem')]
    procedure WMSCreateMoreThenQtyOutst()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        NoOfItems: Integer;
        QtySupplement: Integer;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
    begin
        // TC-WMS
        Initialize();
        AssignBinCodesWMS();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);
        QtySupplement := LibraryRandom.RandIntInRange(5000, 10000);

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationWMS.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, QtySupplement, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        // Create whse pick and Verify
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHeader, '', 0, 0);

        // Increase Quantity to Handled of one of the items
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");

        WhseActivityLine.FindFirst();
        asserterror WhseActivityLine.Validate("Qty. to Handle", QtySupplement);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_QTY_OUTST) > 0,
          'Actual:' + GetLastErrorText + ',Expected:' + MSG_QTY_OUTST);
        ClearLastError();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSPartPost()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplem()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplem()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2Steps()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2')]
    [Scope('OnPrem')]
    procedure ITWMSRecreate()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBin()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInv()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostMoveNotEnL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::WhsePick, '', false, true, -1); // no error as more than required quantity has been registered on pick
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostMoveNotEnL()
    begin
        // There is enough item in inventory
        // Test creates whse pick for full posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and fully posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationWMS, 100, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, false, true, -1);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostMoveNotEnLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::WhsePick, '', false, true, -1); // no error as more than required quantity has been registered on pick
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostMoveNotEnLS()
    begin
        // There is enough item in inventory
        // Test creates whse pick for full posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and fully posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationWMS, 100, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, false, true, -1);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostAO()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostAO()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemAO()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemAO()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsAO()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateAO()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinAO()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvAO()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostMoveNotEnAOL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::WhsePick, '', false, true, -1); // no error as more than required quantity has been registered on pick
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostMoveNotEnAOL()
    begin
        // There is enough item in inventory
        // Test creates whse pick for full posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and fully posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationWMS, 100, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostMoveNotEnAOLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostMoveNotEnAOLS()
    begin
        // There is enough item in inventory
        // Test creates whse pick for full posting, reduces one of the quantity, registeres whse pick and posts.
        // Then test checks whse pick for the rest of the qty, registeres whse pick and fully posts.
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationWMS, 100, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateS()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinS()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();

        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvS()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_SER_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostAOS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostAOS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemAOS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemAOS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsAOS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateAOS()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinAOS()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvAOS()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITAOS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Serial);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_SER_NO_MUST, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsL()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateL()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvL()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_LOT_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostAOL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostAOL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemAOL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemAOL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsAOL()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateAOL()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinAOL()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvAOL()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITAOL()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::Lot);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_LOT_NO_MUST, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsLS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateLS()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinLS()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();

        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvLS()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITLS()
    begin
        Initialize();

        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_SER_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostAOLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, 100, 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostAOLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60), 0, WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostQtySupplemAOLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSPartPostQtySupplemAOLS()
    begin
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationWMS, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::WhsePick, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPost2StepsAOLS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        Post2Steps(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler2,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSRecreateAOLS()
    begin
        // Test creates whse pick, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        RecreateWhseActivity(LocationWMS, WhseActivityType::WhsePick, true, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInBinAOLS()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, true, WhseActivityType::WhsePick, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullNotEnoughItemInInvAOLS()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationWMS, 100, 100, false, WhseActivityType::WhsePick, MSG_CANNOT_POST_CONS, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('PickMessageHandler1,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITWMSFullPostPartITAOLS()
    begin
        Initialize();

        AssignBinCodesWMS();
        CreateItems(Tracking::LotSerial);

        PostingPartialIT(LocationWMS, WhseActivityType::WhsePick, MSG_SER_NO_MUST, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoZeroPickLinesWithAvailableBinContentAssigned()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
        Zone: Record Zone;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent: Record "BOM Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyPerUoM: Integer;
        QtyToConsume: Integer;
        QtyToSell: Integer;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO 207772] Pick line with Quantity = 0 is not created when first available bin content is assigned to the same warehouse pick

        Initialize();

        // [GIVEN] Item "C" is an assembly component for item "P", qty. required to assembly one item "I" is 200
        // [GIVEN] Component item "C" has an additional unit of measure "BOX", base UoM is "PCS", qty. per unit of measure is 200
        CreateItems(Tracking::Untracked);
        QtyPerUoM := LibraryRandom.RandIntInRange(100, 200);
        QtyToConsume := LibraryRandom.RandInt(5);
        QtyToSell := LibraryRandom.RandIntInRange(6, 10);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItem."No.", QtyPerUoM);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, KitItem."No.", BOMComponent.Type::Item, CompItem."No.", QtyPerUoM, CompItem."Base Unit of Measure");

        // [GIVEN] Purchase and put-away 1 box of component item "C" into a bin "B2"
        FindPutAwayPickZone(Zone, LocationWMS.Code);
        LibraryWarehouse.WarehouseJournalSetup(LocationWMS.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.FindBin(Bin, LocationWMS.Code, Zone.Code, 2);
        CreateWhseJournalLine(WarehouseJournalBatch, Bin, CompItem."No.", QtyToConsume, ItemUnitOfMeasure.Code);
        // [GIVEN] Purchase and put-away 3 boxes of component item "C" into a bin "B1"
        LibraryWarehouse.FindBin(Bin, LocationWMS.Code, Zone.Code, 1);
        CreateWhseJournalLine(WarehouseJournalBatch, Bin, CompItem."No.", QtyToSell, ItemUnitOfMeasure.Code);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWMS.Code, true);
        LibraryWarehouse.PostWhseAdjustment(CompItem);

        // [GIVEN] Create a sales order with 2 lines
        // [GIVEN] 1st line - 1 item "P" which requires 1 box of components to assemble
        // [GIVEN] 2nd line - 2 boxes of item "C"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), KitItem."No.", QtyToConsume,
          LocationWMS.Code, WorkDate2);
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CompItem."No.", QtyToSell);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse shipment and pick from the sales order
        CreatePickFromSalesOrder(SalesHeader);

        // [THEN] Total quantity to pick for item "C" is 4 boxes
        // [THEN] There are no pick lines with Quantity = 0
        WarehouseActivityLine.SetRange("Item No.", CompItem."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseActivityLine.SetRange(Quantity, 0);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        WarehouseActivityLine.SetRange(Quantity);
        WarehouseActivityLine.CalcSums(Quantity);
        WarehouseActivityLine.TestField(Quantity, QtyToConsume + QtyToSell);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAssemblyOrderOutputItemUoMDuringReleases()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Assembly Order], [Direct Put-Away and Pick], [UoM required]
        // [SCENARIO 465623] In assembly order, output item must be with unit of meassure if output location is with "Directed Put-away and Pick"
        Initialize();

        //[GIVEN] Advance wms Location and Assembly Item with component
        AssignBinCodesWMS();
        CreateItems(Tracking::Untracked);

        //[GIVEN] Created Assembly order
        CreateAssemblyOrder(LocationWMS, LibraryRandom.RandIntInRange(1, 10), AssemblyHeader);

        // [WHEN] User delete/remove output Unit of Measure
        AssemblyHeader.SetWarningsOff();
        AssemblyHeader.Validate("Unit of Measure Code", '');

        // [THEN] During the releases process system should throw an exception
        asserterror CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
    end;
}

