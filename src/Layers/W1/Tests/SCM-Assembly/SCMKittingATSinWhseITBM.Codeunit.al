// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;
using Microsoft.Warehouse.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Assembly.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Warehouse.Structure;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Ledger;
using System.Security.User;
using System.TestLibraries.Reflection;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Posting;

codeunit 137104 "SCM Kitting ATS in Whse/IT BM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Assemble-to-Stock] [Warehouse] [Item Tracking] [SCM]
        IsInitialized := false;
    end;

    var
        LocationBM: Record Location;
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
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        MSG_NOT_ON_INVT: Label 'Item ';
        MSG_QTY_BASE_NOT: Label 'Qty. to Handle (Base) in the item tracking';
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
        ConfirmPostCount: Integer;
        MSG_WANT_TO_POST: Label 'Do you want to post the ';
        MSG_ORDERS_POSTED: Label 'All of your selections were processed.';
        MSG_POSTING_DATE_NOTALLOWED: Label 'Posting Date is not within your range of allowed posting dates. in Assembly Header Document Type';
        MSG_INCORRECT_COMMENT: Label 'Type should be blank for comment text:';
        MSG_ENTER_POSTING_DATE: Label 'Enter the posting date.';
        MSG_NOTHING_TO_POST: Label 'There is nothing to post';
        MSG_CANNOT_RENAME: Label 'You cannot rename an Assembly Header.';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        AssemblySetup: Record "Assembly Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT BM");
        ConfirmPostCount := 0;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT BM");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        ClearLastError();
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

        LocationSetupBM(LocationBM);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting ATS in Whse/IT BM");
    end;

    local procedure NormalPosting(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; QtySupplement: Decimal; Release: Boolean): Code[20]
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssembledQty: Decimal;
        NoOfItems: Integer;
    begin
        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, QtySupplement, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        if Release then
            CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContents(AssemblyHeader, TempAssemblyLine, QtySupplement, AssembledQty);
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1, AssemblyHeader."Posting Date");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);

        exit(AssemblyHeader."No.");
    end;

    local procedure NotEnoughItemPosting(HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; AddAdditionalQty: Boolean; ExpectedErrorMessage: Text[1024])
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        NotEnoughItemNo: Code[20];
        Qtys: array[10] of Decimal;
        AssembledQty: Decimal;
        NotEnoughNo: Integer;
        NoOfItems: Integer;
    begin
        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems);
        AddCompInventoryNotEnough(AssemblyHeader, NotEnoughNo, NotEnoughItemNo, PartialPostFactor, Qtys, AddAdditionalQty, LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        PostAssemblyHeader(AssemblyHeader."No.", ExpectedErrorMessage);

        // Verify.
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine, AssembledQty, false, TempAssemblyLine.Count + 1, AssemblyHeader."Posting Date");
        VerifyBinContentsQtys(AssemblyHeader, TempAssemblyLine, 0, Qtys, NoOfItems);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    local procedure SetGenWarehouseEntriesFilter(var WarehouseEntry: Record "Warehouse Entry"; AssemblyHeader: Record "Assembly Header"; PostingDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        WarehouseEntry.Reset();
        SourceCodeSetup.Get();
        WarehouseEntry.SetRange("Source Code", SourceCodeSetup.Assembly);
        // WarehouseEntry.SETRANGE("Whse. Document Type",WarehouseEntry."Whse. Document Type"::Assembly);
        // WarehouseEntry.SETRANGE("Whse. Document No.",AssemblyHeader."No.");
        WarehouseEntry.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseEntry.SetRange("Registering Date", PostingDate);
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

    local procedure VerifyWarehouseEntries(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; AssembledQty: Decimal; ShouldBeCreated: Boolean; ExpectedNoOfWhseEntries: Integer; PostingDate: Date)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Verify whole amount of warehouse entries
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);

        SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader, PostingDate);
        if ShouldBeCreated then
            Assert.AreEqual(ExpectedNoOfWhseEntries, WarehouseEntry.Count,
              'Incorect number of warehouse entries for assembly ' + AssemblyHeader."No.")
        else
            Assert.AreEqual(0, WarehouseEntry.Count,
              'Incorect number of warehouse entries for assembly ' + AssemblyHeader."No.");

        // Verify warehouse entries for header assembly item
        SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader, PostingDate);
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
            SetGenWarehouseEntriesFilter(WarehouseEntry, AssemblyHeader, PostingDate);
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

    local procedure VerifyBinContents(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; QtySupplement: Decimal; AssembledQty: Decimal)
    begin
        // Veryfy bin content for header assembly item
        VerifyBinContent(AssemblyHeader."Location Code", AssemblyHeader."Bin Code", AssemblyHeader."Item No.", AssembledQty);

        // Verify bin contents for components
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        TempAssemblyLine.FindSet();
        repeat
            VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
              TempAssemblyLine."No.",
              QtySupplement + TempAssemblyLine.Quantity - TempAssemblyLine."Quantity to Consume" - TempAssemblyLine."Consumed Quantity");
        until TempAssemblyLine.Next() = 0;
    end;

    local procedure VerifyBinContentsQtys(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; AssembledQty: Decimal; Qtys: array[10] of Decimal; NoOfItems: Integer)
    var
        BinContent: Record "Bin Content";
        i: Integer;
        CompQty: Decimal;
    begin
        // Veryfy bin content for header assembly item
        if AssembledQty = 0 then begin
            BinContent.SetRange("Location Code", AssemblyHeader."Location Code");
            BinContent.SetRange("Bin Code", AssemblyHeader."Bin Code");
            BinContent.SetRange("Item No.", AssemblyHeader."Item No.");
            Assert.AreEqual(0, BinContent.Count, 'Too many item ' + AssemblyHeader."Item No." + ' in a bin content');
        end else
            VerifyBinContent(AssemblyHeader."Location Code", AssemblyHeader."Bin Code", AssemblyHeader."Item No.", AssembledQty);

        // Verify bin contents for components
        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        Assert.AreEqual(NoOfItems, TempAssemblyLine.Count, 'Too many component item ' + AssemblyHeader."Item No." + ' in a bin content');
        i := 1;
        TempAssemblyLine.FindSet();
        repeat
            if AssembledQty = 0 then
                CompQty := Qtys[i]
            else
                CompQty := TempAssemblyLine."Quantity to Consume" - Qtys[i];

            VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
              TempAssemblyLine."No.", CompQty);
            i += 1;
        until TempAssemblyLine.Next() = 0;
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

    local procedure UpdateQtysConsumeAssemble(AssemblyHeader: Record "Assembly Header"; Qtys: array[10] of Decimal; var TempAssemblyLine: Record "Assembly Line" temporary)
    var
        AssemblyLine: Record "Assembly Line";
        i: Integer;
    begin
        TempAssemblyLine.DeleteAll();
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble");
        AssemblyHeader.Validate(Description,
          LibraryUtility.GenerateRandomCode(AssemblyHeader.FieldNo(Description), DATABASE::"Assembly Header"));
        AssemblyHeader.Validate("Posting Date", WorkDate2);
        LibraryAssembly.AddAssemblyHeaderComment(AssemblyHeader, 0);
        AssemblyHeader.Modify(true);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        i := 1;

        AssemblyLine.FindSet();
        repeat
            AssemblyLine.Validate("Quantity to Consume", Qtys[i]);
            AssemblyLine.Validate(Description,
              LibraryUtility.GenerateRandomCode(AssemblyLine.FieldNo(Description), DATABASE::"Assembly Line"));
            LibraryAssembly.AddAssemblyHeaderComment(AssemblyHeader, AssemblyLine."Line No.");
            AssemblyLine.Modify(true);
            TempAssemblyLine := AssemblyLine;
            TempAssemblyLine.Insert();
            i += 1;
        until (AssemblyLine.Next() = 0);

        TempAssemblyLine.SetRange("Quantity to Consume", 0);
        if TempAssemblyLine.FindSet() then
            TempAssemblyLine.Delete();
    end;

    [Normal]
    local procedure UpdateQtysConsume(var AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; QtyToAssemble: Decimal; Qtys: array[10] of Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        i: Integer;
    begin
        TempAssemblyLine.DeleteAll();
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        i := 1;

        AssemblyLine.FindSet();
        repeat
            AssemblyLine.Validate("Quantity to Consume", Qtys[i]);
            AssemblyLine.Modify(true);

            if AssemblyLine."Quantity to Consume" > 0 then begin
                TempAssemblyLine := AssemblyLine;
                TempAssemblyLine.Insert();
            end;
            i += 1;
        until (AssemblyLine.Next() = 0);
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
    local procedure PostAssemblyHeader(AssemblyHeaderNo: Code[20]; ExpectedError: Text[1024])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Init();
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        AssemblyHeader.FindFirst();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);
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
    [Scope('OnPrem')]
    procedure PostNotAllowedDate()
    var
        UserSetup: Record "User Setup";
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        NoOfItems: Integer;
    begin
        // Test posting on not allowed date
        Initialize();

        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Allow Posting From", CalcDate('<-11M>', WorkDate()));
        UserSetup.Validate("Allow Posting To", CalcDate('<11M>', WorkDate()));
        UserSetup.Modify(true);

        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        AssemblyHeader.Validate("Posting Date", CalcDate('<-11M-1D>', WorkDate()));

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, MSG_POSTING_DATE_NOTALLOWED);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWrongComment()
    var
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        NoOfItems: Integer;
    begin
        // Test posting when you have comment with not empty type
        Initialize();

        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, '', '', 0, 0, '');
        AssemblyLine.Validate(Description, 'Comment');
        AssemblyLine.Validate(Type, AssemblyLine.Type::Item);
        AssemblyLine.Modify(true);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, MSG_INCORRECT_COMMENT);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostEmptyOrder1()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        // Test posting when you have only resoure and comment lines
        Initialize();

        AssignBinCodesBM();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, 0);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostEmptyOrder2()
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // Test posting when you have only comment lines
        Initialize();

        AssignBinCodesBM();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, 0);

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Resource);
        AssemblyLine.DeleteAll();

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, MSG_NOTHING_TO_POST);
    end;

    [Test]
    [HandlerFunctions('ConfirmPostQuestion')]
    [Scope('OnPrem')]
    procedure PostWithQuestion()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssembledQty: Decimal;
        NoOfItems: Integer;
    begin
        // This test case calls codeunit 901 in order to get code coverage
        Initialize();

        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        CODEUNIT.Run(CODEUNIT::"Assembly-Post (Yes/No)", AssemblyHeader); // First time reply is no
        CODEUNIT.Run(CODEUNIT::"Assembly-Post (Yes/No)", AssemblyHeader); // First time reply is yes

        // Verify.
        VerifyBinContents(AssemblyHeader, TempAssemblyLine, 0, AssembledQty);
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1, AssemblyHeader."Posting Date");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PostBatchHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWithBatch()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssembledQty: Decimal;
        NoOfItems: Integer;
    begin
        // This test case calls report 900 in order to get code coverage
        Initialize();

        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        Commit();
        AssemblyHeader.SetRange("No.", AssemblyHeader."No.");

        REPORT.RunModal(REPORT::"Batch Post Assembly Orders", true, true, AssemblyHeader);

        // Verify.
        VerifyBinContents(AssemblyHeader, TempAssemblyLine, 0, AssembledQty);
        VerifyWarehouseEntries(AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1, CalcDate('<1M>', WorkDate()));
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('PostBatchHandlerError')]
    [Scope('OnPrem')]
    procedure PostWithBatchError()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        NoOfItems: Integer;
    begin
        // This test case calls report 900 in order to get code coverage
        Initialize();

        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate2, 0, AssemblyHeader."Location Code", LocationToBinCode);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        Commit();
        AssemblyHeader.SetRange("No.", AssemblyHeader."No.");
        asserterror REPORT.RunModal(REPORT::"Batch Post Assembly Orders", true, true, AssemblyHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_ENTER_POSTING_DATE) > 0,
          'Expected:' + MSG_ENTER_POSTING_DATE + '. Actual:' + GetLastErrorText);
        ClearLastError();
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullRelease()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(100, 100, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullPartCompRelease()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(100, LibraryRandom.RandIntInRange(1, 99), 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullNotRelease()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(100, 100, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialRelease()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          0,
          true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialNotRelease()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          0,
          false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullReleaseQtySupplem()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(100, 100, LibraryRandom.RandIntInRange(1, 10), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullNotReleaseQtySupplem()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(100, 100, LibraryRandom.RandIntInRange(1, 10), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartReleaseQtySupplem()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 10),
          true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartNotReleaseQtySuppl()
    begin
        // TC-BINPOST
        Initialize();
        NormalPosting(LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 10),
          false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFull2Steps()
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
        // TC-BINPOST
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesBM();

        HeaderQtyFactor := LibraryRandom.RandIntInRange(1, 99);
        PartialPostFactor := HeaderQtyFactor;
        QtySupplement := LibraryRandom.RandIntInRange(1, 50);

        AssemblyHeaderNo := NormalPosting(HeaderQtyFactor,
            PartialPostFactor,
            QtySupplement,
            true);

        // Post rest of the asembly order
        AssemblyHeader.Reset();
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

        AssembledQty := AssemblyHeader."Quantity to Assemble";
        FullAssembledQty := AssemblyHeader.Quantity;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        VerifyBinContents(AssemblyHeader, TempAssemblyLine2, QtySupplement, FullAssembledQty);

        TempAssemblyLine2.Reset();
        TempAssemblyLine2.SetRange(Type, TempAssemblyLine2.Type::Item);
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine2, AssembledQty, true, 2 * (TempAssemblyLine2.Count + 1), AssemblyHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullNotEnoughItemInBin()
    begin
        // TC-BINPOST
        // There is enough item in inventory, but there is not enough item in ToBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        NotEnoughItemPosting(100, 100, true, MSG_NOT_ON_INVT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartNotEnoughItemInBin()
    begin
        // TC-BINPOST
        // There is enough item in inventory, but there is not enough item in ToBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        NotEnoughItemPosting(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          true,
          MSG_NOT_ON_INVT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullNotEnoughItemInInvt()
    begin
        // TC-BINPOST
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        NotEnoughItemPosting(100, 100, true, MSG_NOT_ON_INVT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartNotEnoughItemInInvt()
    begin
        // TC-BINPOST
        // There is not enough item in inventory (there is not enough item in ToBin)
        // Test checks that correspondent error appears during partial posting
        Initialize();
        NotEnoughItemPosting(
          LibraryRandom.RandIntInRange(1, 99),
          LibraryRandom.RandIntInRange(1, 99),
          false,
          MSG_NOT_ON_INVT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartNotEnoughItemReduce()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        NotEnoughItemNo: Code[20];
        Qtys: array[10] of Decimal;
        AssembledQty: Decimal;
        i: Integer;
        NotEnoughNo: Integer;
        NoOfItems: Integer;
        EarliestDate: Date;
    begin
        // TC-BINPOST
        // There is enough item in inventory, but there is not enough item in ToBin.
        // Test checks that partial posting works fine after reducing Qty To Assemble to smallest avaliable
        Initialize();
        AssignBinCodesBM();

        NoOfItems := LibraryRandom.RandIntInRange(1, 3);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        NotEnoughNo := LibraryRandom.RandIntInRange(1, NoOfItems) - 1;
        AddCompInventoryNotEnough(AssemblyHeader, NotEnoughNo, NotEnoughItemNo, 100, Qtys, false, LocationToBinCode);

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        LibraryAssembly.EarliestAvailableDate(AssemblyHeader, AssemblyLine, AssembledQty, EarliestDate);
        UpdateQtysConsume(AssemblyHeader, TempAssemblyLine, AssembledQty, Qtys);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1, AssemblyHeader."Posting Date");

        // Veryfy bin content for header assembly item
        VerifyBinContent(AssemblyHeader."Location Code", AssemblyHeader."Bin Code", AssemblyHeader."Item No.", AssembledQty);

        // Verify bin contents for components
        Assert.AreEqual(NoOfItems, TempAssemblyLine.Count, 'Too many component item ' + AssemblyHeader."Item No." + ' in a bin content');
        i := 1;
        TempAssemblyLine.FindSet();
        repeat
            VerifyBinContent(TempAssemblyLine."Location Code", TempAssemblyLine."Bin Code",
              TempAssemblyLine."No.", Qtys[i] - TempAssemblyLine."Quantity to Consume");
            i += 1;
        until TempAssemblyLine.Next() = 0;

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFullNoEnoughItemSplit()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        NotEnoughItemNo: Code[20];
        Qtys: array[10] of Decimal;
        AssembledQty: Decimal;
        NotEnoughNo: Integer;
        NoOfItems: Integer;
    begin
        // TC-BINPOST
        // There is enough item in inventory but there is not enough item in ToBin.
        // Test checks that full posting works fine after reducing Qty To Consume on a line with not enough inventory
        // and adding one more line with rest of the quantity and another ToBin
        Initialize();
        AssignBinCodesBM();

        NoOfItems := 1;
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, NoOfItems);

        NotEnoughNo := 1;
        AddCompInventoryNotEnough(AssemblyHeader, NotEnoughNo, NotEnoughItemNo, 100, Qtys, true, LocationToBinCode);

        NoOfItems += 1;
        UpdateQtysConsumeAssemble(AssemblyHeader, Qtys, TempAssemblyLine);
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        // Split lines
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, NotEnoughItemNo,
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, NotEnoughItemNo, true), 0, 0, '');

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", NotEnoughItemNo);
        AssemblyLine.FindLast();

        AssemblyLine.Validate("Quantity per", 1);
        AssemblyLine.Validate("Quantity to Consume", Qtys[NoOfItems]);
        AssemblyLine.Validate("Bin Code", LocationAdditionalBinCode);
        AssemblyLine.Modify(true);

        TempAssemblyLine := AssemblyLine;
        TempAssemblyLine.Insert();

        AssemblyHeader.Validate("Posting Date", WorkDate2);
        PostAssemblyHeader(AssemblyHeader."No.", '');

        // Verify
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        TempAssemblyLine.Reset();
        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
        VerifyWarehouseEntries(
          AssemblyHeader, TempAssemblyLine, AssembledQty, true, TempAssemblyLine.Count + 1, AssemblyHeader."Posting Date");
        VerifyBinContentsQtys(AssemblyHeader, TempAssemblyLine, AssembledQty, Qtys, NoOfItems);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameAO()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();

        AssignBinCodesBM();

        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate2, LocationBM.Code, 0);
        asserterror AssemblyHeader.Rename(AssemblyHeader."Document Type", 'New');
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_CANNOT_RENAME) > 0, 'Expected:' + MSG_CANNOT_RENAME + '. Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmPostQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_WANT_TO_POST) > 0, PadStr('Actual: ' + Question + 'Expected: ' + MSG_WANT_TO_POST, 1024));

        ConfirmPostCount += 1;
        if ConfirmPostCount = 1 then
            Reply := false
        else
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCloseWithQtyZero(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchHandler(var PostBatchForm: TestRequestPage "Batch Post Assembly Orders")
    begin
        PostBatchForm.PostingDate.SetValue(CalcDate('<1M>', WorkDate()));
        PostBatchForm.ReplacePostingDate.SetValue(true);
        PostBatchForm.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchHandlerError(var PostBatchForm: TestRequestPage "Batch Post Assembly Orders")
    begin
        PostBatchForm.PostingDate.SetValue('');
        PostBatchForm.ReplacePostingDate.SetValue(true);
        PostBatchForm.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(MSG_ORDERS_POSTED, Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostFull()
    begin
        Initialize();
        AssignBinCodesBM();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostPartial()
    begin
        Initialize();
        AssignBinCodesBM();
        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99), 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostFullQtySupplem()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationBM, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostPartQtySupplem()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Untracked);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostFull2Steps()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Untracked);

        Post2Steps(LocationBM, WhseActivityType::None, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInBin()
    begin
        // There is enough item in inventory, but there is not enough item in FromBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationBM, 100, 100, true, WhseActivityType::None, MSG_NOT_ON_INVT, '', true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInInvt()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Untracked);

        NotEnoughItemPostingIT(LocationBM, 100, 100, false, WhseActivityType::None, MSG_NOT_ON_INVT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNoEnoughItemSplitLS()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        NotEnoughItemNo: Code[20];
        Qtys: array[10] of Decimal;
        NotEnoughNo: Integer;
        NoOfLines: Integer;
    begin
        // There is enough item in inventory but there is not enough item in ToBin.
        // Test checks that full posting works fine after reducing Qty To Consume on a line with not enough inventory
        // and adding one more line with rest of the quantity and another ToBin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        CreateAssemblyOrder(LocationBM, LibraryRandom.RandIntInRange(6, 8), AssemblyHeader);

        NotEnoughNo := 1;
        PurchaseComponentsNotEnough(LocationBM, AssemblyHeader, NotEnoughNo, NotEnoughItemNo, 100, Qtys, true, LocationToBinCode);

        NoOfLines := 2;
        UpdateQtysConsumeAssemble(AssemblyHeader, Qtys, TempAssemblyLine);

        AssignITToAssemblyLines(AssemblyHeader, false, true, '-');

        // Create new line with remaining qty
        CreateAssemblyLine(AssemblyHeader, NotEnoughItemNo, Qtys[NoOfLines], true, true);

        PostAssemblyHeader(AssemblyHeader."No.", '');
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartialS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99), 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullQtySupplemS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationBM, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartQtySupplemS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFull2StepsS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        Post2Steps(LocationBM, WhseActivityType::None, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInBinS()
    begin
        // There is enough item in inventory, but there is not enough item in FromBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationBM, 100, 100, true, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInInvtS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NotEnoughItemPostingIT(LocationBM, 100, 100, false, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary,ConfirmCloseWithQtyZero')]
    [Scope('OnPrem')]
    procedure ITPostFullPartITS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Serial);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, MSG_QTY_BASE_NOT, true, false, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullL()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartialL()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99), 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullQtySupplemL()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationBM, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartQtySupplemL()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFull2StepsL()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        Post2Steps(LocationBM, WhseActivityType::None, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInBinL()
    begin
        // There is enough item in inventory, but there is not enough item in FromBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationBM, 100, 100, true, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInInvtL()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NotEnoughItemPostingIT(LocationBM, 100, 100, false, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullPartITL()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::Lot);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, MSG_QTY_BASE_NOT, true, false, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartialLS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99), 0, WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationBM, 100, LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostPartQtySupplemLS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationBM, LibraryRandom.RandIntInRange(50, 99),
          LibraryRandom.RandIntInRange(1, 10), WhseActivityType::None, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFull2StepsLS()
    begin
        // Test does partial posting and verifies it. Then it postes rest of the order and verifies
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        Post2Steps(LocationBM, WhseActivityType::None, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInBinLS()
    begin
        // There is enough item in inventory, but there is not enough item in FromBin.
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationBM, 100, 100, true, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPostFullNotEnoughItemInInvtLS()
    begin
        // There is not enough item in inventory (there is not enough item in FromBin)
        // Test checks that correspondent error appears during full posting
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NotEnoughItemPostingIT(LocationBM, 100, 100, false, WhseActivityType::None, MSG_QTY_BASE_NOT, '', true, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary,ConfirmCloseWithQtyZero')]
    [Scope('OnPrem')]
    procedure ITPostFullPartITLS()
    begin
        Initialize();
        AssignBinCodesBM();

        CreateItems(Tracking::LotSerial);

        NormalPostingIT(LocationBM, 100, 0, WhseActivityType::None, MSG_QTY_BASE_NOT, true, false, true);
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostAssemblyOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Assembly Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Assembly Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Assembly Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler(var PostBatchForm: TestRequestPage "Batch Post Assembly Orders")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;
}

