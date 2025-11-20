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
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Activity;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.BOM;

codeunit 137105 "SCM Kitting ATS in Whse/IT IM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Assemble-to-Stock] [Warehouse] [Item Tracking] [SCM]
        IsInitialized := false;
    end;

    var
        LocationInvtMvmt: Record Location;
        CompItem: Record Item;
        KitItem: Record Item;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        MSG_MVMT_CREATED: Label 'Number of Invt. Movement activities';
        MSG_NOT_ON_INVT: Label 'Item ';
        MSG_NOTHING_TO_CREATE: Label 'There is nothing to create';
        MSG_NOT_ON_INVT1: Label 'Item %1';
        MSG_QTY_OUTST: Label 'You cannot handle more than the outstanding';
        MSG_SER_NO_MUST: Label 'Serial No. must have a value';
        MSG_LOT_NO_MUST: Label 'Lot No. must have a value';
        LocationTakeBinCode: Code[20];
        LocationAdditionalBinCode: Code[20];
        LocationToBinCode: Code[20];
        LocationFromBinCode: Code[20];
        LocationAdditionalPickBinCode: Code[20];
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
        MSG_WHSE_HANDLING_REQUIRED: Label 'Warehouse handling is required for Entry Type = Assembly Consumption, Order No. = ';
        MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT: Label 'Qty. to Handle (Base) in the item tracking';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        AssemblySetup: Record "Assembly Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT IM");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT IM");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        ClearLastError();
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode());

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LocationSetupInvtMvmt(LocationInvtMvmt);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT IM");
    end;

    local procedure SetGenWarehouseEntriesFilter(var WarehouseEntry: Record "Warehouse Entry"; AssemblyHeader: Record "Assembly Header")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        WarehouseEntry.Reset();
        SourceCodeSetup.Get();
        WarehouseEntry.SetRange("Source Code", SourceCodeSetup.Assembly);
        // WarehouseEntry.SETRANGE("Whse. Document Type",WarehouseEntry."Whse. Document Type"::Assembly);
        // WarehouseEntry.SETRANGE("Whse. Document No.",AssemblyHeader."No.");
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
    begin
        // Veryfy bin content for header assembly item
        VerifyBinContent(AssemblyHeader."Location Code", AssemblyHeader."Bin Code", AssemblyHeader."Item No.", AssembledQty);

        // Verify bin contents for components
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
              TempAssemblyLine."No.", 0);
            VerifyBinContent(TempAssemblyLine."Location Code", LocationTakeBinCode,
              TempAssemblyLine."No.",
              QtySupplement + TempAssemblyLine.Quantity - TempAssemblyLine."Quantity to Consume" - TempAssemblyLine."Consumed Quantity")
        until TempAssemblyLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyRegInvtMvmt(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; WarehouseActivityHeaderNo: Code[20]; ExpectedNoOfRegInvtMmnt: Integer; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        RegdInvtMovementLn: Record "Registered Invt. Movement Line";
        RegdInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        ExpectedNoOfLines: Integer;
    begin
        VerifyRegInvtMvmtHeader(AssemblyHeader, ExpectedNoOfRegInvtMmnt);

        RegdInvtMovementHdr.SetRange("Invt. Movement No.", WarehouseActivityHeaderNo);
        RegdInvtMovementHdr.FindFirst();

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);

        RegdInvtMovementLn.Reset();
        RegdInvtMovementLn.SetRange("No.", RegdInvtMovementHdr."No.");

        ExpectedNoOfLines := 2 * TempAssemblyLine.Count();
        if AdditionalBinQty > 0 then
            ExpectedNoOfLines += 2;
        Assert.AreEqual(
          ExpectedNoOfLines, RegdInvtMovementLn.Count, CopyStr('There are not ' + Format(ExpectedNoOfLines) +
            ' reg Invt mvmt lines within the filter: ' + RegdInvtMovementHdr.GetFilters, 1, 1024));

        VerifyRegInvtMvmtLines(RegdInvtMovementHdr, TempAssemblyLine,
          RegdInvtMovementLn."Action Type"::Take, LocationTakeBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
        VerifyRegInvtMvmtLines(RegdInvtMovementHdr, TempAssemblyLine,
          RegdInvtMovementLn."Action Type"::Place, LocationToBinCode, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);
    end;

    [Normal]
    local procedure VerifyRegInvtMvmtHeader(AssemblyHeader: Record "Assembly Header"; ExpectedNoOfRegInvtMmnt: Integer)
    var
        RegdInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        WarehouseRequest: Record "Warehouse Request";
    begin
        RegdInvtMovementHdr.Reset();
        RegdInvtMovementHdr.SetRange("Source No.", AssemblyHeader."No.");
        RegdInvtMovementHdr.SetRange("Source Document", WarehouseRequest."Source Document"::"Assembly Consumption");
        RegdInvtMovementHdr.SetRange("Source Type", DATABASE::"Assembly Line");
        RegdInvtMovementHdr.SetRange("Source Subtype", AssemblyHeader."Document Type");
        RegdInvtMovementHdr.SetRange("Location Code", AssemblyHeader."Location Code");
        RegdInvtMovementHdr.SetRange("Destination Type", RegdInvtMovementHdr."Destination Type"::Item);
        RegdInvtMovementHdr.SetRange("Destination No.", AssemblyHeader."Item No.");
        Assert.AreEqual(ExpectedNoOfRegInvtMmnt, RegdInvtMovementHdr.Count, CopyStr(
            'There should be 1 registered InvtMvmtHeader within the filter: ' +
            RegdInvtMovementHdr.GetFilters, 1, 1024));
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
    local procedure VerifyRegInvtMvmtLines(RegdInvtMovementHdr: Record "Registered Invt. Movement Hdr."; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        RegdInvtMovementLn: Record "Registered Invt. Movement Line";
    begin
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            if TempAssemblyLine."No." = NotEnoughItemNo then
                VerifyRegInvtMvmtLine(RegdInvtMovementHdr, TempAssemblyLine, ActionType, BinCode, NotEnoughQty)
            else
                VerifyRegInvtMvmtLine(RegdInvtMovementHdr, TempAssemblyLine, ActionType, BinCode,
                  TempAssemblyLine."Quantity to Consume");

        until TempAssemblyLine.Next() = 0;

        if AdditionalBinQty > 0 then begin
            TempAssemblyLine.Reset();
            TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
            TempAssemblyLine.SetRange("No.", NotEnoughItemNo);
            TempAssemblyLine.FindFirst();

            if ActionType = RegdInvtMovementLn."Action Type"::Take then
                VerifyRegInvtMvmtLine(RegdInvtMovementHdr, TempAssemblyLine, ActionType, LocationAdditionalBinCode,
                  AdditionalBinQty)
            else
                VerifyRegInvtMvmtLine(RegdInvtMovementHdr, TempAssemblyLine, ActionType, BinCode,
                  AdditionalBinQty);
        end;
    end;

    [Normal]
    local procedure VerifyRegInvtMvmtLine(RegdInvtMovementHdr: Record "Registered Invt. Movement Hdr."; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; Qty: Decimal)
    var
        RegdInvtMovementLn: Record "Registered Invt. Movement Line";
    begin
        RegdInvtMovementLn.Reset();
        RegdInvtMovementLn.SetRange("No.", RegdInvtMovementHdr."No.");
        RegdInvtMovementLn.SetRange("Action Type", ActionType);
        RegdInvtMovementLn.SetRange("Bin Code", BinCode);
        RegdInvtMovementLn.SetRange("Location Code", TempAssemblyLine."Location Code");
        RegdInvtMovementLn.SetRange("Item No.", TempAssemblyLine."No.");
        RegdInvtMovementLn.SetRange(Description, TempAssemblyLine.Description);
        RegdInvtMovementLn.SetRange("Unit of Measure Code", TempAssemblyLine."Unit of Measure Code");
        RegdInvtMovementLn.SetRange("Qty. per Unit of Measure", 1);
        RegdInvtMovementLn.SetRange("Due Date", TempAssemblyLine."Due Date");

        RegdInvtMovementLn.SetRange(Quantity, Qty);
        RegdInvtMovementLn.SetRange("Qty. (Base)", Qty);

        Assert.AreEqual(1, RegdInvtMovementLn.Count, CopyStr('There are not 1 registered Invt mvmt lines within the filter: ' +
            RegdInvtMovementLn.GetFilters, 1, 1024));
    end;

    [Normal]
    local procedure VerifyWhseActivityLines(WhseActivityHdr: Record "Warehouse Activity Header"; var TempAssemblyLine: Record "Assembly Line" temporary; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();

        repeat
            if TempAssemblyLine."No." = NotEnoughItemNo then
                VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, NotEnoughQty, NotEnoughQty)
            else
                VerifyWhseActivityLine(WhseActivityHdr, TempAssemblyLine, ActionType, BinCode, TempAssemblyLine."Quantity to Consume",
                  TempAssemblyLine."Quantity to Consume");
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
                ResultQtys[i] := Round(ResultQtys[i], 0.00001, '=');
                ResultQtys[i] -= 0.00002;
                ItemsCount := AssemblyLine.Count + 1;
                ResultQtys[ItemsCount] := 0.00002;
            end else
                ResultQtys[i] := Round(ResultQtys[i], 0.00001, '=');

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

    local procedure LocationSetupBM(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // Skip validate trigger for bin mandatory to improve performance.
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        AssignBinCodesBM();

        LibraryWarehouse.CreateBin(Bin, Location.Code, LocationAdditionalBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, LocationToBinCode, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, LocationFromBinCode, '', '');
        Location.Validate("From-Assembly Bin Code", LocationFromBinCode);
        Location.Validate("To-Assembly Bin Code", LocationToBinCode);
        Location.Modify(true);
    end;

    local procedure LocationSetupInvtMvmt(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LocationSetupBM(Location);
        // Skip validate trigger to improve performance.
        Location."Require Pick" := true;
        Location."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";

        AssignBinCodesInvtMvmt();

        LibraryWarehouse.CreateBin(Bin, Location.Code, LocationTakeBinCode, '', '');
        Location.Modify(true);
    end;

    [Normal]
    local procedure AssignBinCodesBM()
    begin
        LocationAdditionalBinCode := 'ABin';
        LocationToBinCode := 'ToBin';
        LocationFromBinCode := 'FromBin';
        LocationTakeBinCode := '';
        LocationAdditionalPickBinCode := '';
    end;

    [Normal]
    local procedure AssignBinCodesInvtMvmt()
    begin
        AssignBinCodesBM();

        LocationTakeBinCode := 'TakeBin';
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

    local procedure NormalPostingInvtMvmt(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; QtySupplement: Decimal): Code[20]
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssembledQty: Decimal;
    begin
        AssignBinCodesInvtMvmt();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, QtySupplement, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

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

    [Normal]
    local procedure CreateInvtMovementAndVerify(AssemblyHeaderNo: Code[20]; var TempAssemblyLine: Record "Assembly Line" temporary; ExpectedNoOfRegInvtMmnt: Integer; NotEnoughItemNo: Code[20]; NotEnoughQty: Decimal; AdditionalBinQty: Decimal)
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();

        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        AutoFillQtyInventoryActivity(AssemblyHeader);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHeader, NotEnoughItemNo, NotEnoughQty, AdditionalBinQty);

        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        VerifyRegInvtMvmt(AssemblyHeader, TempAssemblyLine, WhseActivityHeader."No.", ExpectedNoOfRegInvtMmnt, NotEnoughItemNo,
          NotEnoughQty,
          AdditionalBinQty);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MvmtMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_MVMT_CREATED) > 0,
          PadStr('Actual:' + Message + ',Expected:' + MSG_MVMT_CREATED, 1024));
    end;

    local procedure MoveNotEnoughItemInvtMvmt(HeaderQtyFactor: Integer; PartialPostFactor: Integer)
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
        AssignBinCodesInvtMvmt();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        // Create Inventory Movement and Verify
        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        AutoFillQtyInventoryActivity(AssemblyHeader);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHeader, '', 0, 0);

        // Reduce Quantity to Handled of one of the items
        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems);
        UpdateWhseActivityLine(NotEnoughNo, NotEnoughItemNo, NotEnoughQty, TempAssemblyLine, WhseActivityHeader, -0.00001);

        // Register Inventory Movement and verify
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        VerifyRegInvtMvmt(AssemblyHeader, TempAssemblyLine, WhseActivityHeader."No.", 1, NotEnoughItemNo, NotEnoughQty, 0);

        // Post asssembly order
        PostAssemblyHeader(AssemblyHeader."No.", MSG_WHSE_HANDLING_REQUIRED);

        // Verify inventory movemennt with rest of the item
        VerifyWhseActivityHeader(AssemblyHeader, WhseActivityHeader);

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");

        Assert.AreEqual(
          2, WhseActivityLine.Count, CopyStr('There are not 2 whse activ. lines within the filter: ' + WhseActivityHeader.GetFilters, 1, 1024)
          );

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.SetRange("No.", NotEnoughItemNo);
        TempAssemblyLine.FindFirst();

        VerifyWhseActivityLine(WhseActivityHeader, TempAssemblyLine, WhseActivityLine."Action Type"::Take, LocationTakeBinCode,
          TempAssemblyLine."Quantity to Consume", TempAssemblyLine."Quantity to Consume" - NotEnoughQty);
        VerifyWhseActivityLine(WhseActivityHeader, TempAssemblyLine, WhseActivityLine."Action Type"::Place, LocationToBinCode,
          TempAssemblyLine."Quantity to Consume", TempAssemblyLine."Quantity to Consume" - NotEnoughQty);

        // Register inventory movement
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
        VerifyRegInvtMvmtHeader(AssemblyHeader, 2);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure NotEnoughItemPostingInvtMvmt(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; AddAdditionalQty: Boolean)
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        ExpectedErrorMessage: Text[1024];
        NotEnoughItemNo: Code[20];
        NotEnoughNo: Integer;
        NoOfItems: Integer;
        Qtys: array[10] of Decimal;
    begin
        AssignBinCodesInvtMvmt();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, NoOfItems);

        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems);
        AddCompInventoryNotEnough(AssemblyHeader, NotEnoughNo, NotEnoughItemNo, PartialPostFactor, Qtys, AddAdditionalQty,
          LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        if AddAdditionalQty then
            CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, NotEnoughItemNo, Qtys[NotEnoughNo], Qtys[NoOfItems + 1])
        else
            CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, NotEnoughItemNo, Qtys[NotEnoughNo], 0);

        if AddAdditionalQty then
            ExpectedErrorMessage := ''
        else
            ExpectedErrorMessage := StrSubstNo(MSG_NOT_ON_INVT1, NotEnoughItemNo);

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
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

    [Normal]
    local procedure AutoFillQtyInventoryActivity(AssemblyHeader: Record "Assembly Header")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
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

        asserterror CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, true, '-', '');
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedErrorMessage) > 0,
          CopyStr('Actual:' + GetLastErrorText + ',Expected:' + ExpectedErrorMessage, 1, 1024));
        ClearLastError();
    end;

    local procedure Post2Steps(Location: Record Location; WhseActivity: Option; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine2: Record "Assembly Line" temporary;
        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
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

        ReleaseAssemblyDoc.Reopen(AssemblyHeader);

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

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, false, true, '+')
            else
                AssignITToAssemblyLines(AssemblyHeader, false, false, '+');

        CreateAndRegisterWhseActivity(AssemblyHeaderNo, WhseActivity, AssignITOnWhseAct, false, '+', '');

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Normal]
    local procedure ReuseFromAnotherOrder(Location: Record Location; WhseActivity: Option; AssignITBeforeWhseAct: Boolean; AssignITOnWhseAct: Boolean)
    var
        AssemblyHeader2: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
        HeaderQtyFactor: Decimal;
        Qty1: Integer;
    begin
        HeaderQtyFactor := 100;

        Qty1 := LibraryRandom.RandIntInRange(6, 8);
        CreateAssemblyOrder(Location, Qty1, AssemblyHeader);

        PurchaseComponentsToBin(AssemblyHeader, Qty1, Location, LocationTakeBinCode);

        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        if AssignITBeforeWhseAct then
            if WhseActivity = WhseActivityType::None then
                AssignITToAssemblyLines(AssemblyHeader, false, true, '-')
            else
                AssignITToAssemblyLines(AssemblyHeader, false, false, '-');

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, false, '-', '');

        ReleaseAssemblyDoc.Reopen(AssemblyHeader);

        HeaderQtyFactor := 40;
        PrepareOrderPosting(AssemblyHeader, HeaderQtyFactor);

        // Post asssembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');

        // Create and post another assembly order
        CreateAssemblyOrder(Location, Round(Qty1 * (100 - HeaderQtyFactor) / 100, 1, '<'), AssemblyHeader2);

        PrepareOrderPosting(AssemblyHeader2, 100);

        AssignITToAssemblyLines(AssemblyHeader2, false, true, '-');

        // Components should not be reserved for first order so we expect posting to go correctly
        PostAssemblyHeader(AssemblyHeader2."No.", '');
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

        CreateAssemblyLine(AssemblyHeader, CompItem."No.", LibraryRandom.RandIntInRange(2, 4), false, false);
    end;

    local procedure CreateAssemblyLine(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Integer; AssignBinCode: Boolean; AssignIT: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        LibraryKitting.AddLine(AssemblyHeader, "BOM Component Type"::Item, ItemNo,
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, ItemNo, true),
          Quantity, 1, '');

        if AssignBinCode then begin
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange("No.", ItemNo);
            AssemblyLine.FindLast();

            AssemblyLine.Validate("Bin Code", LocationAdditionalBinCode);
            AssemblyLine.Validate("Quantity to Consume", Quantity);
            AssemblyLine.Modify();
        end;

        if AssignIT then begin
            AssemblyOrderPage.OpenEdit();
            AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");

            AssemblyOrderPage.Lines.Last();

            PrepareHandleSelectEntries(false);
            AssemblyOrderPage.Lines."Item Tracking Lines".Invoke();
            AssemblyOrderPage.OK().Invoke();
        end;
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
    var
        LibraryUtility: Codeunit "Library - Utility";
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

        AssignITToPurchLine(PurchaseHeader, PurchaseLine);
    end;

    [Normal]
    local procedure CreateAndRegisterWhseActivity(AssemblyHeaderNo: Code[20]; WhseActivity: Option; AssignITOnWhseAct: Boolean; ITPartial: Boolean; FindDirection: Code[10]; ExpectedError: Text[1024])
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
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, ITPartial, FindDirection);

        if ExpectedError = '' then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else begin
            asserterror LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            Assert.IsTrue(StrPos(GetLastErrorText, ExpectedError) > 0,
              'Expected:' + ExpectedError + '. Actual:' + GetLastErrorText);
            ClearLastError();
        end;
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
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        PurchaseHeaderNo: Code[20];
    begin
        PurchaseHeaderNo := PurchaseHeader."No.";

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        if Location."Require Receive" then begin
            GetSourceDocInbound.CreateFromPurchOrder(PurchaseHeader);

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
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, false, '-');

        // Register whse activity
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Post asssembly order
        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);

        if AssignITOnWhseAct then
            AssignITWhseActivity(AssemblyHeader, WhseActivityHeader, false, '-');

        // Register rest of the whse activity
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Post asssembly order
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
            AssignITWhseActivity(AssemblyHeader, WhseActivityHdr, false, '-');

        WhseActivityHdr.Delete(true);

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, false, '-', '');

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure AssignItemTrackingCode(var Item: Record Item; LotTracked: Boolean; SerialTracked: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LibraryUtility: Codeunit "Library - Utility";
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

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, ITPartial, '-', '');

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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNLD_ItemTrackingSummary(var ItemTrackingSummaryPage: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummaryPage.OK().Invoke();
    end;

    local procedure AssignITToPurchLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        PurchaseOrderPage: TestPage "Purchase Order";
        ITType: Option;
    begin
        GetItemIT(PurchaseLine."No.", ITType);

        if ITType = Tracking::Untracked then
            exit;

        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        PurchaseOrderPage.PurchLines.Last();

        PrepareHandleAssignPartial(ITType, PurchaseLine.Quantity);
        PurchaseOrderPage.PurchLines."Item Tracking Lines".Invoke();

        PurchaseOrderPage.OK().Invoke();
    end;

    local procedure AssignITToAssemblyLines(var AssemblyHeader: Record "Assembly Header"; ITPartial: Boolean; SelectEntries: Boolean; FindDir: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();

        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");

        repeat
            AssignITToAsmLine(AssemblyLine."No.", AssemblyLine."Quantity to Consume", ITPartial, SelectEntries, AssemblyOrderPage, FindDir);
        until AssemblyLine.Next() = 0;

        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure AssignITToAsmLine(ItemNo: Code[20]; Quantity: Decimal; ITPartial: Boolean; SelectEntries: Boolean; AssemblyOrderPage: TestPage "Assembly Order"; FindDir: Code[10])
    var
        ITType: Option;
    begin
        GetItemIT(ItemNo, ITType);

        if ITType = Tracking::Untracked then
            exit;

        AssemblyOrderPage.Lines.FILTER.SetFilter("No.", ItemNo);

        if SelectEntries then
            PrepareHandleSelectEntries(ITPartial)
        else
            PrepareHandlePutManually(ItemNo, ITType, ITPartial, Quantity, FindDir);

        AssemblyOrderPage.Lines."Item Tracking Lines".Invoke();
    end;

    [Normal]
    local procedure AssignITWhseActivity(AssemblyHeader: Record "Assembly Header"; WhseActivityHeader: Record "Warehouse Activity Header"; ITPartial: Boolean; FindDirection: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        if AssemblyLine.FindSet() then
            repeat
                AssingITWhseActivityLine(AssemblyLine."No.", WhseActivityHeader, ITPartial, FindDirection);
            until (AssemblyLine.Next() = 0);
    end;

    local procedure AssingITWhseActivityLine(ItemNo: Code[20]; WhseActivityHeader: Record "Warehouse Activity Header"; ITPartial: Boolean; FindDirection: Code[10])
    var
        WhseActivityLineTake: Record "Warehouse Activity Line";
        WhseActivityLinePlace: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TrackedQty: Integer;
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.Find(FindDirection);

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
            if not WhseActivityLineTake.FindFirst() then
                exit; // in case of partial posting whse activity has less lines then in item ledger entries

            WhseActivityLinePlace.Reset();
            WhseActivityLinePlace.SetRange("No.", WhseActivityHeader."No.");
            WhseActivityLinePlace.SetRange("Item No.", ItemNo);
            WhseActivityLinePlace.SetRange("Serial No.", '');
            WhseActivityLinePlace.SetRange("Lot No.", '');
            WhseActivityLinePlace.SetRange("Action Type", WhseActivityLinePlace."Action Type"::Place);
            WhseActivityLinePlace.FindFirst();

            WhseActivityLineTake.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WhseActivityLinePlace.Validate("Serial No.", ItemLedgerEntry."Serial No.");

            WhseActivityLineTake.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WhseActivityLinePlace.Validate("Lot No.", ItemLedgerEntry."Lot No.");

            WhseActivityLineTake.Modify(true);
            WhseActivityLinePlace.Modify(true);

        until ItemLedgerEntry.Next() = 0;
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

        CreateAndRegisterWhseActivity(AssemblyHeader."No.", WhseActivity, AssignITOnWhseAct, ITPartial, '-', ExpectedErrorMessageReg);

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessagePost);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullPost()
    begin
        // TC-IMVMT
        Initialize();
        NormalPostingInvtMvmt(100, 100, 0);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullPartCompPost()
    begin
        // TC-IMVMT
        Initialize();
        NormalPostingInvtMvmt(100, LibraryRandom.RandIntInRange(1, 99), 0);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtPartPost()
    begin
        // TC-IMVMT
        Initialize();
        NormalPostingInvtMvmt(LibraryRandom.RandIntInRange(1, 99), LibraryRandom.RandIntInRange(1, 99), 0);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullPostQtySupplem()
    begin
        // TC-IMVMT
        Initialize();
        NormalPostingInvtMvmt(100, 100, LibraryRandom.RandIntInRange(1, 10));
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtPartPostQtySupplem()
    begin
        // TC-IMVMT
        Initialize();
        NormalPostingInvtMvmt(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 10));
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullPost2Steps()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblyHeaderNo: Code[20];
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        QtySupplement: Decimal;
        AssembledQty: Decimal;
        FullAssembledQty: Decimal;
    begin
        // TC-IMVMT
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 99);
        PartialPostFactor := HeaderQtyFactor;
        QtySupplement := LibraryRandom.RandIntInRange(1, 10);

        AssemblyHeaderNo := NormalPostingInvtMvmt(
            HeaderQtyFactor,
            PartialPostFactor,
            QtySupplement);

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

        CreateInvtMovementAndVerify(AssemblyHeaderNo, TempAssemblyLine2, 2, '', 0, 0);

        AssembledQty := AssemblyHeader."Quantity to Assemble";
        FullAssembledQty := AssemblyHeader.Quantity;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContentsMvmt(AssemblyHeader, TempAssemblyLine2, QtySupplement, FullAssembledQty);

        TempAssemblyLine2.Reset();
        TempAssemblyLine2.SetRange(Type, TempAssemblyLine2.Type::Item);
        VerifyWarehouseEntries(AssemblyHeader, TempAssemblyLine2, AssembledQty, true, 2 * (TempAssemblyLine2.Count + 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvtMvmtPostNotRelease()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        ATOMovementsCreated: Integer;
        TotalATOMovementsToBeCreated: Integer;
    begin
        // TC-IMVMT
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        asserterror AssemblyHeader.CreateInvtMovement(false, false, true, ATOMovementsCreated, TotalATOMovementsToBeCreated);
        Assert.ExpectedTestFieldError(AssemblyHeader.FieldCaption(Status), Format(AssemblyHeader.Status::Released));
        ClearLastError();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtCreateSame()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
    begin
        // TC-IMVMT
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, LibraryRandom.RandIntInRange(1, 3));
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        asserterror LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_NOTHING_TO_CREATE) > 0,
          PadStr('Actual:' + GetLastErrorText + ',Expected:' + MSG_NOTHING_TO_CREATE, 1024));
        ClearLastError();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtRecreate()
    var
        AssemblyHeader: Record "Assembly Header";
        WhseActivityHdr: Record "Warehouse Activity Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        AssembledQty: Decimal;
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        // TC-IMVMT
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, LibraryRandom.RandIntInRange(1, 3));

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        AutoFillQtyInventoryActivity(AssemblyHeader);
        VerifyWhseActivity(AssemblyHeader, TempAssemblyLine, WhseActivityHdr, '', 0, 0);

        WhseActivityHdr.Delete(true);

        CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

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
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullNotEnoughItemInBin()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks no error appears during full posting
        Initialize();
        NotEnoughItemPostingInvtMvmt(100, 100, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtPartNotEnoughItemInBin()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during partial posting
        Initialize();
        NotEnoughItemPostingInvtMvmt(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullNotEnoughItemInInv()
    begin
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        NotEnoughItemPostingInvtMvmt(100, 100, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtPartNotEnoughItemInInv()
    begin
        // There is enough item in inventory but there is not enough item in ToBin
        // Test checks that no error appears during partial posting
        Initialize();

        NotEnoughItemPostingInvtMvmt(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtPartPostMoveNotEnItem()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and posts.
        Initialize();
        MoveNotEnoughItemInvtMvmt(LibraryRandom.RandIntInRange(1, 100),
          LibraryRandom.RandIntInRange(1, 100));
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtFullPostMoveNotEnItem()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for full posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and fully posts.
        Initialize();
        MoveNotEnoughItemInvtMvmt(LibraryRandom.RandIntInRange(1, 100),
          LibraryRandom.RandIntInRange(1, 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvtMvmtPostNoInvtMvmt()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        NoOfItems: Integer;
    begin
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, LibraryRandom.RandIntInRange(1, 9),
          AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        PostAssemblyHeader(AssemblyHeader."No.", '');

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtReuseFromAnotherOrder()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblyHeader2: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
        NoOfItems: Integer;
        HeaderQtyFactor: Decimal;
        PartialPostFactor: Decimal;
        AssemblyItemNo: Code[20];
    begin
        // Test checks that inventory movement created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := 100;
        PartialPostFactor := 100;

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, LibraryRandom.RandIntInRange(1, 5),
          AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        CreateInvtMovementAndVerify(AssemblyHeader."No.", TempAssemblyLine, 1, '', 0, 0);

        ReleaseAssemblyDoc.Reopen(AssemblyHeader);

        HeaderQtyFactor := 10;
        PartialPostFactor := 10;
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble" * HeaderQtyFactor / 100);
        AssemblyItemNo := AssemblyHeader."Item No.";

        // Post asssembly order
        PostAssemblyHeader(AssemblyHeader."No.", '');

        // Create another assembly order
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader2, WorkDate2, AssemblyItemNo, LocationInvtMvmt.Code, AssemblyHeader.Quantity, '');
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader2, TempAssemblyLine2, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        // Post assembly order
        PostAssemblyHeader(AssemblyHeader2."No.", '');

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMvmtCreateMoreThenQtyOutst()
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
        // Test checks that inventory movement cannot be created for more then qty outstanding
        Initialize();
        AssignBinCodesInvtMvmt();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 100);
        PartialPostFactor := LibraryRandom.RandIntInRange(1, 100);
        QtySupplement := LibraryRandom.RandIntInRange(5000, 10000);

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationInvtMvmt.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, QtySupplement, AssemblyHeader."Location Code", LocationTakeBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);

        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        // Create Inventory Movement and Verify
        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);
        AutoFillQtyInventoryActivity(AssemblyHeader);
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
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPost()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplem()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplem()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2Steps()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreate()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInBin()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInInv()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_NOT_ON_INVT, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostMoveNotEnL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, false, true, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostMoveNotEnL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for full posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and fully posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationInvtMvmt, 100, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, false, true, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostMoveNotEnLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, false, true, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostMoveNotEnLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for full posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and fully posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationInvtMvmt, 100, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, false, true, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmt()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtReuseFromAnotherOrder()
    begin
        // Test checks that inventory movement created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        ReuseFromAnotherOrder(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostAO()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostAO()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemAO()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemAO()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsAO()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateAO()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInBinAO()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInInvAO()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_NOT_ON_INVT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostMoveNotEnAOL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::InvtMvmt, MSG_WHSE_HANDLING_REQUIRED, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostMoveNotEnAOL()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for full posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and fully posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        MoveNotEnoughItem(LocationInvtMvmt, 100, WhseActivityType::InvtMvmt, MSG_WHSE_HANDLING_REQUIRED, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostMoveNotEnAOLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for partial posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          WhseActivityType::InvtMvmt, MSG_WHSE_HANDLING_REQUIRED, true, false, -1);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostMoveNotEnAOLS()
    begin
        // There is enough item in inventory
        // Test creates inventory movement for full posting, reduces one of the quantity, registeres inventory movement and posts.
        // Then test checks inventory movement for the rest of the qty, registeres inventory movement and fully posts.
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        MoveNotEnoughItem(LocationInvtMvmt, 100, WhseActivityType::InvtMvmt, MSG_WHSE_HANDLING_REQUIRED, true, false, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtAO()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        LocationToBinCode := LocationInvtMvmt."To-Assembly Bin Code";
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtReuseFromAnotherOrdAO()
    begin
        // Test checks that inventory movement created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Untracked);

        ReuseFromAnotherOrder(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsS()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateS()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInBinS()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInInvS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_SER_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsAOS()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateAOS()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInBinAOS()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInInvAOS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        LocationToBinCode := LocationInvtMvmt."To-Assembly Bin Code";
        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITAOS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Serial);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_SER_NO_MUST, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsL()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateL()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInBinL()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInInvL()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtReuseFromAnotherOrderL()
    begin
        // Test checks that inventory movement created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        ReuseFromAnotherOrder(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_LOT_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateAOL()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInBinAOL()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInInvAOL()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtReuseFromAnotherOrdAOL()
    begin
        // Test checks that inventory movement created for one assembly order can be reused for another
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        ReuseFromAnotherOrder(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITAOL()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::Lot);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_LOT_NO_MUST, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsLS()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateLS()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInBinLS()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnoughItemInInvLS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', false, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_SER_NO_MUST, false, true);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, 100, 0, WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 99), 0,
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostQtySupplemAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, 100, LibraryRandom.RandIntInRange(1, 10),
          WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPartPostQtySupplemAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 60),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::InvtMvmt, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPost2StepsAOLS()
    begin
        // Test does partial posting and verifies it. Then it posts rest of the order and verifies
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        Post2Steps(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtRecreateAOLS()
    begin
        // Test creates inventory movement, deletes it, creates a new one and verifies it
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        RecreateWhseActivity(LocationInvtMvmt, WhseActivityType::InvtMvmt, true, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInBinAOLS()
    begin
        // There is enough item in inventory but there is not enough item in FromBin
        // Test checks no error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationInvtMvmt, 100, 100, true, WhseActivityType::InvtMvmt, '', '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullNotEnItemInInvAOLS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(
          LocationInvtMvmt, 100, 100, false, WhseActivityType::InvtMvmt, MSG_QTY_TO_HANDLE_BASE_MUST_BE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtPostNoInvtMvmtAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationInvtMvmt, LibraryRandom.RandIntInRange(50, 100), 0,
          WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('MvmtMessageHandler,HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITInvtMvmtFullPostPartITAOLS()
    begin
        Initialize();
        AssignBinCodesInvtMvmt();
        CreateItems(Tracking::LotSerial);

        PostingPartialIT(LocationInvtMvmt, WhseActivityType::InvtMvmt, MSG_SER_NO_MUST, true, false);
    end;
}

