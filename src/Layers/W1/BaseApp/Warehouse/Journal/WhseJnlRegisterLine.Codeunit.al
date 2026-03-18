// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 7301 "Whse. Jnl.-Register Line"
{
    Permissions = TableData "Warehouse Entry" = rimd,
                  TableData "Warehouse Register" = rimd,
                  TableData Bin = m,
                  TableData "Bin Content" = rimd;
    TableNo = "Warehouse Journal Line";

    trigger OnRun()
    begin
        RegisterWhseJnlLine(Rec);
    end;

    var
        Location: Record Location;
        WhseJnlLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        WhseReg: Record "Warehouse Register";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgt: Codeunit "WMS Management";
        GlobalWhseEntryNo: Integer;
#pragma warning disable AA0074
        Text000: Label 'is not sufficient to complete this action. The quantity in the bin is %1. %2 units are not available', Comment = '%1 = the value of the Quantity that is in the bin; %2 = the value of the Quantity that is not available.';
#pragma warning disable AA0470
        Text001: Label 'Serial No. %1 is found in inventory .';
#pragma warning restore AA0470
#pragma warning restore AA0074
        OnMovement: Boolean;

    local procedure "Code"()
    var
        GlobalWhseEntry: Record "Warehouse Entry";
        Item: Record Item;
        xGlobalWhseEntryNo: Integer;
        IsHandled: Boolean;
    begin
        xGlobalWhseEntryNo := GlobalWhseEntryNo;
        OnBeforeCode(WhseJnlLine, GlobalWhseEntryNo, IsHandled);
        ValidateSequenceNo(GlobalWhseEntryNo, xGlobalWhseEntryNo, Database::"Warehouse Entry");
        if IsHandled then
            exit;

        if (WhseJnlLine."Qty. (Absolute)" = 0) and (WhseJnlLine."Qty. (Base)" = 0) and (not WhseJnlLine."Phys. Inventory") then
            exit;
        WhseJnlLine.TestField("Item No.");
        GetLocation(WhseJnlLine."Location Code");

        Item.SetLoadFields("Variant Mandatory if Exists");
        Item.Get(WhseJnlLine."Item No.");
        if Item.IsVariantMandatory() then
            WhseJnlLine.TestField("Variant Code");

        OnCodeOnAfterGetLastEntryNo(WhseJnlLine);

        OnMovement := false;
        if WhseJnlLine."From Bin Code" <> '' then begin
            OnCodeBeforeInitWhseEntryFromBinCode(WhseJnlLine, GlobalWhseEntry);
            InitWhseEntry(GlobalWhseEntry, WhseJnlLine."From Zone Code", WhseJnlLine."From Bin Code", -1);
            if WhseJnlLine."To Bin Code" <> '' then begin
                InsertWhseEntry(GlobalWhseEntry);
                OnMovement := true;
                InitWhseEntry(GlobalWhseEntry, WhseJnlLine."To Zone Code", WhseJnlLine."To Bin Code", 1);
            end;
        end else
            InitWhseEntry(GlobalWhseEntry, WhseJnlLine."To Zone Code", WhseJnlLine."To Bin Code", 1);

        InsertWhseEntry(GlobalWhseEntry);

        xGlobalWhseEntryNo := GlobalWhseEntryNo;
        OnAfterCode(WhseJnlLine, GlobalWhseEntryNo, WhseReg);
        ValidateSequenceNo(GlobalWhseEntryNo, xGlobalWhseEntryNo, Database::"Warehouse Entry");
    end;


    procedure LockWarehouseTables()
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseRegister: Record "Warehouse Register";
    begin
        WarehouseEntry.Lock();
        WarehouseRegister.Lock();
    end;

#if not CLEAN27
    [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
    procedure LockIfLegacyPosting()
    begin
    end;

    [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
    procedure LockTables()
    begin
    end;
#endif
    procedure InitWhseEntry(var WhseEntry: Record "Warehouse Entry"; ZoneCode: Code[10]; BinCode: Code[20]; Sign: Integer)
    var
        ToBinContent: Record "Bin Content";
        xGlobalWhseEntryNo: Integer;
        IsHandled: Boolean;
        ShouldDeleteFromBinContent: Boolean;
    begin
        GlobalWhseEntryNo := WhseEntry.GetNextEntryNo();

        WhseEntry.Init();
        WhseEntry."Entry No." := GlobalWhseEntryNo;
        WhseEntry."Journal Template Name" := WhseJnlLine."Journal Template Name";
        WhseEntry."Journal Batch Name" := WhseJnlLine."Journal Batch Name";
        if WhseJnlLine."Entry Type" <> WhseJnlLine."Entry Type"::Movement then begin
            if Sign >= 0 then
                WhseEntry."Entry Type" := WhseEntry."Entry Type"::"Positive Adjmt."
            else
                WhseEntry."Entry Type" := WhseEntry."Entry Type"::"Negative Adjmt.";
        end else
            WhseEntry."Entry Type" := WhseJnlLine."Entry Type";
        WhseEntry."Line No." := WhseJnlLine."Line No.";
        WhseEntry."Whse. Document No." := WhseJnlLine."Whse. Document No.";
        WhseEntry."Whse. Document Type" := WhseJnlLine."Whse. Document Type";
        WhseEntry."Whse. Document Line No." := WhseJnlLine."Whse. Document Line No.";
        WhseEntry."No. Series" := WhseJnlLine."Registering No. Series";
        WhseEntry."Location Code" := WhseJnlLine."Location Code";
        WhseEntry."Zone Code" := ZoneCode;
        WhseEntry."Bin Code" := BinCode;
        GetLocation(WhseJnlLine."Location Code");
        GetBin(WhseJnlLine."Location Code", BinCode);
        WhseEntry.Dedicated := Bin.Dedicated;
        WhseEntry."Bin Type Code" := Bin."Bin Type Code";
        WhseEntry."Item No." := WhseJnlLine."Item No.";
        WhseEntry.Description := GetItemDescription(WhseJnlLine."Item No.", WhseJnlLine.Description);
        if Location."Directed Put-away and Pick" then begin
            WhseEntry.Quantity := WhseJnlLine."Qty. (Absolute)" * Sign;
            WhseEntry."Unit of Measure Code" := WhseJnlLine."Unit of Measure Code";
            WhseEntry."Qty. per Unit of Measure" := WhseJnlLine."Qty. per Unit of Measure";
        end else begin
            WhseEntry.Quantity := WhseJnlLine."Qty. (Absolute, Base)" * Sign;
            WhseEntry."Unit of Measure Code" := WMSMgt.GetBaseUOM(WhseJnlLine."Item No.");
            WhseEntry."Qty. per Unit of Measure" := 1;
        end;
        WhseEntry."Qty. (Base)" := WhseJnlLine."Qty. (Absolute, Base)" * Sign;
        WhseEntry."Registering Date" := WhseJnlLine."Registering Date";
        WhseEntry."User ID" := WhseJnlLine."User ID";
        WhseEntry."Variant Code" := WhseJnlLine."Variant Code";
        WhseEntry."Source Type" := WhseJnlLine."Source Type";
        WhseEntry."Source Subtype" := WhseJnlLine."Source Subtype";
        WhseEntry."Source No." := WhseJnlLine."Source No.";
        WhseEntry."Source Line No." := WhseJnlLine."Source Line No.";
        WhseEntry."Source Subline No." := WhseJnlLine."Source Subline No.";
        WhseEntry."Source Document" := WhseJnlLine."Source Document";
        WhseEntry."Reference Document" := WhseJnlLine."Reference Document";
        WhseEntry."Reference No." := WhseJnlLine."Reference No.";
        WhseEntry."Source Code" := WhseJnlLine."Source Code";
        WhseEntry."Reason Code" := WhseJnlLine."Reason Code";
        WhseEntry.Cubage := WhseJnlLine.Cubage * Sign;
        WhseEntry.Weight := WhseJnlLine.Weight * Sign;
        WhseEntry.CopyTrackingFromWhseJnlLine(WhseJnlLine);
        WhseEntry."Expiration Date" := WhseJnlLine."Expiration Date";
        if OnMovement and (WhseJnlLine."Entry Type" = WhseJnlLine."Entry Type"::Movement) then begin
            WhseEntry.CopyTrackingFromNewWhseJnlLine(WhseJnlLine);
            if (WhseJnlLine."New Expiration Date" <> WhseJnlLine."Expiration Date") and (WhseEntry."Entry Type" = WhseEntry."Entry Type"::Movement) then
                WhseEntry."Expiration Date" := WhseJnlLine."New Expiration Date";
        end;
        WhseEntry."Warranty Date" := WhseJnlLine."Warranty Date";
        WhseEntry."Phys Invt Counting Period Code" := WhseJnlLine."Phys Invt Counting Period Code";
        WhseEntry."Phys Invt Counting Period Type" := WhseJnlLine."Phys Invt Counting Period Type";

        IsHandled := false;
        OnInitWhseEntryCopyFromWhseJnlLine(WhseEntry, WhseJnlLine, OnMovement, Sign, Location, BinCode, IsHandled);
        if not IsHandled then
            if Sign > 0 then begin
                if BinCode <> Location."Adjustment Bin Code" then begin
                    if not ToBinContent.Get(
                            WhseJnlLine."Location Code", BinCode, WhseJnlLine."Item No.", WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code")
                    then
                        InsertToBinContent(WhseEntry)
                    else
                        if Location."Default Bin Selection" = Location."Default Bin Selection"::"Last-Used Bin" then
                            UpdateDefaultBinContent(WhseJnlLine."Item No.", WhseJnlLine."Variant Code", WhseJnlLine."Location Code", BinCode);
                    xGlobalWhseEntryNo := GlobalWhseEntryNo;
                    OnInitWhseEntryOnAfterGetToBinContent(WhseEntry, ItemTrackingMgt, WhseJnlLine, WhseReg, GlobalWhseEntryNo, Bin);
                    ValidateSequenceNo(GlobalWhseEntryNo, xGlobalWhseEntryNo, Database::"Warehouse Entry");
                end
            end else begin
                ShouldDeleteFromBinContent := BinCode <> Location."Adjustment Bin Code";
                OnInitWhseEntryOnAfterCalcShouldDeleteFromBinContent(WhseJnlLine, Location, ShouldDeleteFromBinContent);
                if ShouldDeleteFromBinContent then
                    DeleteFromBinContent(WhseEntry);
            end;
    end;

    local procedure DeleteFromBinContent(var WhseEntry: Record "Warehouse Entry")
    var
        FromBinContent: Record "Bin Content";
        WhseEntry2: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        Sign: Integer;
        xGlobalWhseEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteFromBinContent(WhseEntry, IsHandled);
        if IsHandled then
            exit;

        FromBinContent.ReadIsolation(IsolationLevel::Readcommitted);
        FromBinContent.Get(
            WhseEntry."Location Code", WhseEntry."Bin Code", WhseEntry."Item No.", WhseEntry."Variant Code",
            WhseEntry."Unit of Measure Code");
        ItemTrackingMgt.GetWhseItemTrkgSetup(FromBinContent."Item No.", WhseItemTrackingSetup);
        OnDeleteFromBinContentOnAfterGetWhseItemTrkgSetup(FromBinContent, WhseItemTrackingSetup);
        WhseItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
        FromBinContent.SetTrackingFilterFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
        IsHandled := false;
        xGlobalWhseEntryNo := GlobalWhseEntryNo;
        OnDeleteFromBinContentOnAfterSetFiltersForBinContent(FromBinContent, WhseEntry, WhseJnlLine, WhseReg, GlobalWhseEntryNo, IsHandled);
        ValidateSequenceNo(GlobalWhseEntryNo, xGlobalWhseEntryNo, Database::"Warehouse Entry");
        if IsHandled then
            exit;
        FromBinContent.CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        if FromBinContent."Quantity (Base)" + WhseEntry."Qty. (Base)" = 0 then begin
            WhseEntry2.ReadIsolation(IsolationLevel::ReadCommitted);
            WhseEntry2.SetRange("Item No.", WhseEntry."Item No.");
            WhseEntry2.SetRange("Bin Code", WhseEntry."Bin Code");
            WhseEntry2.SetRange("Location Code", WhseEntry."Location Code");
            WhseEntry2.SetRange("Variant Code", WhseEntry."Variant Code");
            WhseEntry2.SetRange("Unit of Measure Code", WhseEntry."Unit of Measure Code");
            WhseEntry2.SetTrackingFilterFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
            OnDeleteFromBinContentOnAfterSetFiltersForWhseEntry(WhseEntry2, FromBinContent, WhseEntry);
            WhseEntry2.CalcSums(Cubage, Weight, "Qty. (Base)");
            WhseEntry.Cubage := -WhseEntry2.Cubage;
            WhseEntry.Weight := -WhseEntry2.Weight;
            if WhseEntry2."Qty. (Base)" + WhseEntry."Qty. (Base)" <> 0 then
                RegisterRoundResidual(WhseEntry, WhseEntry2);

            FromBinContent.ClearTrackingFilters();
            OnDeleteFromBinContentOnAfterClearTrackingFilters(WhseEntry2, FromBinContent, WhseEntry);
            FromBinContent.CalcFields("Quantity (Base)");
            if FromBinContent."Quantity (Base)" + WhseEntry."Qty. (Base)" = 0 then
                if (FromBinContent."Positive Adjmt. Qty. (Base)" = 0) and
                    (FromBinContent."Put-away Quantity (Base)" = 0) and
                    (not FromBinContent.Fixed)
                then begin
                    OnDeleteFromBinContentOnBeforeFromBinContentDelete(FromBinContent);
                    FromBinContent.Delete();
                end;
        end else begin
            OnDeleteFromBinContentOnBeforeCheckQuantity(FromBinContent, WhseEntry);
            FromBinContent.CalcFields(Quantity);
            if FromBinContent.Quantity + WhseEntry.Quantity = 0 then begin
                WhseEntry."Qty. (Base)" := -FromBinContent."Quantity (Base)";
                Sign := WhseJnlLine."Qty. (Base)" / WhseJnlLine."Qty. (Absolute, Base)";
                WhseJnlLine."Qty. (Base)" := WhseEntry."Qty. (Base)" * Sign;
                WhseJnlLine."Qty. (Absolute, Base)" := Abs(WhseEntry."Qty. (Base)");
                OnDeleteFromBinContenOnAfterQtyUpdate(FromBinContent, WhseEntry, WhseJnlLine, Sign);
            end else
                if FromBinContent."Quantity (Base)" + WhseEntry."Qty. (Base)" < 0 then begin
                    IsHandled := false;
                    OnDeleteFromBinContentOnBeforeFieldError(FromBinContent, WhseEntry, IsHandled);
                    if not IsHandled then
                        FromBinContent.FieldError(
                            "Quantity (Base)",
                            StrSubstNo(Text000, FromBinContent."Quantity (Base)", -(FromBinContent."Quantity (Base)" + WhseEntry."Qty. (Base)")));
                end;
        end;
    end;

    local procedure RegisterRoundResidual(var WhseEntry: Record "Warehouse Entry"; var WhseEntry2: Record "Warehouse Entry")
    var
        WhseJnlLine2: Record "Warehouse Journal Line";
        WhseJnlRegLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        WhseJnlLine2 := WhseJnlLine;
        GetBin(WhseJnlLine2."Location Code", Location."Adjustment Bin Code");
        WhseJnlLine2.Quantity := 0;
        WhseJnlLine2."Qty. (Base)" := WhseEntry2."Qty. (Base)" + WhseEntry."Qty. (Base)";
        RegisterRoundResidualOnAfterGetBin(WhseJnlLine2, WhseEntry, WhseEntry2);
        if WhseEntry2."Qty. (Base)" > Abs(WhseEntry."Qty. (Base)") then begin
            WhseJnlLine2."To Zone Code" := Bin."Zone Code";
            WhseJnlLine2."To Bin Code" := Bin.Code;
        end else begin
            WhseJnlLine2."To Zone Code" := WhseJnlLine2."From Zone Code";
            WhseJnlLine2."To Bin Code" := WhseJnlLine2."From Bin Code";
            WhseJnlLine2."From Zone Code" := Bin."Zone Code";
            WhseJnlLine2."From Bin Code" := Bin.Code;
            WhseJnlLine2."Qty. (Base)" := -WhseJnlLine2."Qty. (Base)";
        end;
        WhseJnlLine2."Qty. (Absolute)" := 0;
        WhseJnlLine2."Qty. (Absolute, Base)" := Abs(WhseJnlLine2."Qty. (Base)");
        OnRegisterRoundResidualOnBeforeWhseJnlRegLineSetWhseRegister(WhseEntry, WhseEntry2, WhseJnlLine, WhseJnlLine2, Bin);
        WhseJnlRegLine.SetWhseRegister(WhseReg);
        WhseJnlRegLine.Run(WhseJnlLine2);
        WhseJnlRegLine.GetWhseRegister(WhseReg);
        GlobalWhseEntryNo := WhseEntry.GetNextEntryNo();
        WhseEntry."Entry No." := GlobalWhseEntryNo;
    end;

    local procedure InsertWhseEntry(var WhseEntry: Record "Warehouse Entry")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertWhseEntryProcedure(WhseEntry, WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        Item.SetLoadFields("Item Tracking Code");
        Item.ReadIsolation(IsolationLevel::ReadCommitted);
        Item.Get(WhseEntry."Item No.");

        if ItemTrackingCode.Get(Item."Item Tracking Code") then
            if (WhseEntry."Serial No." <> '') and
               (WhseEntry."Bin Code" <> Location."Adjustment Bin Code") and
               (WhseEntry.Quantity > 0) and
               ItemTrackingCode."SN Specific Tracking"
            then begin
                IsHandled := false;
                OnInsertWhseEntryOnBeforeCheckSerialNo(WhseEntry, IsHandled);
                if not IsHandled then
                    if WMSMgt.SerialNoOnInventory(WhseEntry."Location Code", WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Serial No.") then
                        Error(Text001, WhseEntry."Serial No.");
            end;

        CheckExpiration(WhseEntry, ItemTrackingCode);

        OnBeforeInsertWhseEntry(WhseEntry, WhseJnlLine);
        InsertWhseReg(WhseEntry."Entry No.");
        WhseEntry."Warehouse Register No." := WhseReg."No.";
        WhseEntry.Insert(true);
        UpdateBinEmpty(WhseEntry);

        OnAfterInsertWhseEntry(WhseEntry, WhseJnlLine);
    end;

    local procedure CheckExpiration(var WarehouseEntry: Record "Warehouse Entry"; ItemTrackingCode: Record "Item Tracking Code")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExistingExpDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExpiration(WarehouseEntry, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode."Man. Expir. Date Entry Reqd." and (WarehouseEntry."Entry Type" = WarehouseEntry."Entry Type"::"Positive Adjmt.") and ItemTrackingCode.IsWarehouseTracking() then begin
            WarehouseEntry.TestField("Expiration Date");
            ItemTrackingSetup.CopyTrackingFromWhseEntry(WarehouseEntry);
            ItemTrackingMgt.GetWhseExpirationDate(WarehouseEntry."Item No.", WarehouseEntry."Variant Code", Location, ItemTrackingSetup, ExistingExpDate);
            if (ExistingExpDate <> 0D) and (WarehouseEntry."Expiration Date" <> ExistingExpDate) then begin
                IsHandled := false;
                OnInsertWhseEntryOnBeforeTestFieldExpirationDate(WarehouseEntry, ExistingExpDate, IsHandled);
                if not IsHandled then
                    WarehouseEntry.TestField("Expiration Date", ExistingExpDate);
            end;
        end;
    end;

    local procedure UpdateBinEmpty(NewWarehouseEntry: Record "Warehouse Entry")
    var
        WarehouseEntry: Record "Warehouse Entry";
        IsHandled: Boolean;
    begin
        OnBeforeUpdateBinEmpty(NewWarehouseEntry, Bin, IsHandled);
        if IsHandled then
            exit;

        if NewWarehouseEntry.Quantity > 0 then
            ModifyBinEmpty(false)
        else begin
            WarehouseEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
            WarehouseEntry.SetRange("Bin Code", NewWarehouseEntry."Bin Code");
            WarehouseEntry.SetRange("Location Code", NewWarehouseEntry."Location Code");
            WarehouseEntry.CalcSums("Qty. (Base)");
            ModifyBinEmpty(WarehouseEntry."Qty. (Base)" = 0);
        end;
        OnAfterUpdateBinEmpty(NewWarehouseEntry, Bin);
    end;

    local procedure ModifyBinEmpty(NewEmpty: Boolean)
    begin
        OnBeforeModifyBinEmpty(Bin, NewEmpty);

        if Bin.Empty <> NewEmpty then begin
            Bin.ReadIsolation(IsolationLevel::UpdLock);
            Bin.Find();
            Bin.Empty := NewEmpty;
            Bin.Modify();
        end;
    end;

    procedure InsertToBinContent(WhseEntry: Record "Warehouse Entry")
    var
        BinContent: Record "Bin Content";
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        OnBeforeInsertToBinContent(WhseEntry);
        GetBinForBinContent(WhseEntry);
        BinContent.Init();
        BinContent."Location Code" := WhseEntry."Location Code";
        BinContent."Zone Code" := WhseEntry."Zone Code";
        BinContent."Bin Code" := WhseEntry."Bin Code";
        BinContent.Dedicated := Bin.Dedicated;
        BinContent."Bin Type Code" := Bin."Bin Type Code";
        BinContent."Block Movement" := Bin."Block Movement";
        BinContent."Bin Ranking" := Bin."Bin Ranking";
        BinContent."Cross-Dock Bin" := Bin."Cross-Dock Bin";
        BinContent."Warehouse Class Code" := Bin."Warehouse Class Code";
        BinContent."Item No." := WhseEntry."Item No.";
        BinContent."Variant Code" := WhseEntry."Variant Code";
        BinContent."Unit of Measure Code" := WhseEntry."Unit of Measure Code";
        BinContent."Qty. per Unit of Measure" := WhseEntry."Qty. per Unit of Measure";
        BinContent.Fixed := WhseIntegrationMgt.IsOpenShopFloorBin(WhseEntry."Location Code", WhseEntry."Bin Code");
        GetLocation(WhseEntry."Location Code");
        if not Location."Directed Put-away and Pick" then begin
            CheckDefaultBin(WhseEntry, BinContent);
            BinContent.Fixed := BinContent.Default;
        end;
        OnBeforeBinContentInsert(BinContent, WhseEntry, Bin);
        BinContent.Insert();
    end;

    local procedure GetBinForBinContent(var WhseEntry: Record "Warehouse Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBinForBinContent(WhseEntry, IsHandled);
        if IsHandled then
            exit;

        GetBin(WhseEntry."Location Code", WhseEntry."Bin Code");
    end;

    local procedure CheckDefaultBin(WhseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDefaultBin(WhseEntry, BinContent, IsHandled);
        if IsHandled then
            exit;

        if WMSMgt.CheckDefaultBin(WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Location Code", WhseEntry."Bin Code") then begin
            if Location."Default Bin Selection" = Location."Default Bin Selection"::"Last-Used Bin" then begin
                DeleteDefaultBinContent(WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Location Code");
                BinContent.Default := true;
            end
        end else
            BinContent.Default := true;
    end;

    procedure UpdateDefaultBinContent(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        BinContent2: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.FindFirst() then
            if BinContent."Bin Code" <> BinCode then begin
                BinContent.Default := false;
                OnUpdateDefaultBinContentOnBeforeBinContentModify(BinContent);
                BinContent.Modify();
            end;

        if BinContent."Bin Code" <> BinCode then begin
            BinContent2.SetRange("Location Code", LocationCode);
            BinContent2.SetRange("Item No.", ItemNo);
            BinContent2.SetRange("Variant Code", VariantCode);
            BinContent2.SetRange("Bin Code", BinCode);
            BinContent2.FindFirst();
            BinContent2.Default := true;
            OnUpdateDefaultBinContentOnBeforeBinContent2Modify(BinContent2);
            BinContent2.Modify();
        end;
    end;

    local procedure DeleteDefaultBinContent(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.FindFirst() then begin
            BinContent.Default := false;
            OnDeleteDefaultBinContentOnBeforeBinContentModify(BinContent);
            BinContent.Modify();
        end;
    end;

    local procedure InsertWhseReg(WhseEntryNo: Integer)
    begin
        if WhseReg."No." = 0 then begin
            WhseReg.Init();
            WhseReg."No." := WhseReg.GetNextEntryNo();
            WhseReg."From Entry No." := WhseEntryNo;
            WhseReg."To Entry No." := WhseEntryNo;
            WhseReg."Creation Date" := Today;
            WhseReg."Creation Time" := Time;
            WhseReg."Journal Batch Name" := WhseJnlLine."Journal Batch Name";
            WhseReg."Source Code" := WhseJnlLine."Source Code";
            WhseReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
            OnInsertWhseRegOnBeforeInsertRecord(WhseReg, WhseJnlLine, WhseEntryNo);
            WhseReg.InsertRecord();
        end else begin
            if ((WhseEntryNo < WhseReg."From Entry No.") and (WhseEntryNo <> 0)) or
               ((WhseReg."From Entry No." = 0) and (WhseEntryNo <> 0))
            then
                WhseReg."From Entry No." := WhseEntryNo;
            if WhseEntryNo > WhseReg."To Entry No." then
                WhseReg."To Entry No." := WhseEntryNo;
            OnInsertWhseRegOnBeforeModifyWarehouseRegister(WhseReg, WhseJnlLine, WhseEntryNo);
            WhseReg.Modify();
        end;
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetItemDescription(ItemNo: Code[20]; Description2: Text[100]): Text[100]
    var
        WarehouseSetup2: Record "Warehouse Setup";
        Item: Record Item;
    begin
        WarehouseSetup2.SetLoadFields("Copy Item Descr. to Entries");
        WarehouseSetup2.Get();
        if WarehouseSetup2."Copy Item Descr. to Entries" then
            exit(Description2);

        Item.SetLoadFields(Description);
        Item.ReadIsolation(IsolationLevel::ReadCommitted);
        Item.Get(ItemNo);
        if Item.Description = Description2 then
            exit('');
        exit(Description2);
    end;

    procedure SetWhseRegister(WhseRegDef: Record "Warehouse Register")
    begin
        WhseReg := WhseRegDef;
        OnAfterSetWhseRegister(WhseReg);
    end;

    procedure GetWhseRegister(var WhseRegDef: Record "Warehouse Register")
    begin
        WhseRegDef := WhseReg;
    end;

    procedure RegisterWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.Copy(WarehouseJournalLine);
        Code();
        WarehouseJournalLine := WhseJnlLine;
    end;

    procedure SetWhseEntryNo(NewWhseEntryNo: Integer)
    var
        xGlobalWhseEntryNo: Integer;
    begin
        xGlobalWhseEntryNo := GlobalWhseEntryNo;
        GlobalWhseEntryNo := NewWhseEntryNo;
        ValidateSequenceNo(GlobalWhseEntryNo, xGlobalWhseEntryNo, Database::"Warehouse Entry");
    end;

    procedure GetWhseEntryNo(): Integer
    begin
        exit(GlobalWhseEntryNo);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Entry", 'r')]
    local procedure ValidateSequenceNo(LedgEntryNo: Integer; xLedgEntryNo: Integer; TableNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if LedgEntryNo = xLedgEntryNo then
            exit;
        SequenceNoMgt.ValidateSeqNo(TableNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sequence No. Mgt.", 'OnPreviewableLedgerEntry', '', false, false)]
    local procedure OnPreviewableLedgerEntry(TableNo: Integer; var IsPreviewable: Boolean)
    begin
        if TableNo in [Database::"Warehouse Entry", Database::"Warehouse Register"] then
            IsPreviewable := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseEntryCopyFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; OnMovement: Boolean; Sign: Integer; Location: Record Location; BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseEntryOnAfterCalcShouldDeleteFromBinContent(WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; var ShouldDeleteFromBinContent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseEntryNo: Integer; var WarehouseRegister: Record "Warehouse Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinContentInsert(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry"; Bin: Record Bin);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExpiration(var WarehouseEntry: Record "Warehouse Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteFromBinContent(var WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBinForBinContent(var WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseEntryProcedure(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToBinContent(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBinEmpty(WarehouseEntry: Record "Warehouse Entry"; var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetLastEntryNo(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeBeforeInitWhseEntryFromBinCode(WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteDefaultBinContentOnBeforeBinContentModify(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterSetFiltersForWhseEntry(var WarehouseEntry2: Record "Warehouse Entry"; var BinContent: Record "Bin Content"; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterSetFiltersForBinContent(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry"; var WhseJnlLine: Record "Warehouse Journal Line"; var WhseReg: Record "Warehouse Register"; var WhseEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeFieldError(BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeFromBinContentDelete(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeCheckQuantity(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseEntryOnAfterGetToBinContent(var WhseEntry: Record "Warehouse Entry"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var WhseJnlLine: Record "Warehouse Journal Line"; var WhseReg: Record "Warehouse Register"; var WhseEntryNo: Integer; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseEntryOnBeforeCheckSerialNo(WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDefaultBinContentOnBeforeBinContentModify(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDefaultBinContentOnBeforeBinContent2Modify(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure RegisterRoundResidualOnAfterGetBin(var WhseJnlLine2: Record "Warehouse Journal Line"; WhseEntry: Record "Warehouse Entry"; WhseEntry2: Record "Warehouse Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContenOnAfterQtyUpdate(var FromBinContent: Record "Bin Content"; var WhseEntry: Record "Warehouse Entry"; var WhseJnlLine: Record "Warehouse Journal Line"; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyBinEmpty(var Bin: Record Bin; NewEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDefaultBin(WhseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterRoundResidualOnBeforeWhseJnlRegLineSetWhseRegister(var WhseEntry: Record "Warehouse Entry"; var WhseEntry2: Record "Warehouse Entry"; var WhseJnlLine: Record "Warehouse Journal Line"; var WhseJnlLine2: Record "Warehouse Journal Line"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterClearTrackingFilters(var WarehouseEntry2: Record "Warehouse Entry"; var FromBinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterGetWhseItemTrkgSetup(FromBinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseEntryOnBeforeTestFieldExpirationDate(WhseEntry: Record "Warehouse Entry"; ExistingExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateBinEmpty(WarehouseEntry: Record "Warehouse Entry"; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertWhseRegOnBeforeInsertRecord(var WarehouseReg: Record "Warehouse Register"; var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertWhseRegOnBeforeModifyWarehouseRegister(var WarehouseReg: Record "Warehouse Register"; var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseRegister(var WarehouseRegister: Record "Warehouse Register")
    begin
    end;
}

