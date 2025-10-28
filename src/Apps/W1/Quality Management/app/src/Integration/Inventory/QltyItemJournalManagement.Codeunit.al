// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

codeunit 20454 "Qlty. Item Journal Management"
{
    var
        NoFiltersWereSuppliedWhenTryingToPostAWarehouseJournalLineErr: Label 'No filters were supplied when trying to post a warehouse journal line.';
        PostedWarehouseJournalEntryDocumentTypeLbl: Label 'posted warehouse entry';
        NoFiltersWereSuppliedWhenTryingToPostAnItemJournalLineErr: Label 'No filters were supplied when trying to post an item journal line.';
        PostedJournalEntryDocumentTypeLbl: Label 'posted item journal entry';

    /// <summary>
    /// This will create a warehouse journal line.
    /// The kind of line it creates depends on the batch supplied and the instruction.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalBatch"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="WhseItemTrackingLine"></param>
    procedure CreateWarehouseJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        LastWhseJnlWarehouseJournalLine: Record "Warehouse Journal Line";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        ManagementNoSeries: Codeunit "No. Series";
        Handled: Boolean;
        ExpirationDate: Date;
        WhseTracked: Boolean;
    begin
        QltyManagementSetup.Get();
        WarehouseJournalLine.Reset();

        OnBeforeGenericCreateWarehouseJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalBatch, WarehouseJournalLine, Handled);
        if Handled then
            exit;

        WarehouseJournalLine.Reset();
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Location Code", WarehouseJournalBatch."Location Code");

        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Location Code", WarehouseJournalBatch."Location Code");
        LastWhseJnlWarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        LastWhseJnlWarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        LastWhseJnlWarehouseJournalLine.SetRange("Location Code", WarehouseJournalBatch."Location Code");
        if LastWhseJnlWarehouseJournalLine.FindLast() then begin
            LastWhseJnlWarehouseJournalLine."Journal Template Name" := WarehouseJournalBatch."Journal Template Name";
            LastWhseJnlWarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
            LastWhseJnlWarehouseJournalLine."Location Code" := WarehouseJournalBatch."Location Code";
        end;
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalBatch."Journal Template Name";
        WarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
        WarehouseJournalLine."Location Code" := WarehouseJournalBatch."Location Code";
        WarehouseJournalLine.SetUpNewLine(LastWhseJnlWarehouseJournalLine);
        WarehouseJournalLine."Registering Date" := WorkDate();

        if WarehouseJournalBatch."No. Series" <> '' then
            if ManagementNoSeries.IsManual(WarehouseJournalBatch."No. Series") then
                WarehouseJournalLine."Whse. Document No." := QltyInspectionTestHeader."No."
            else
                WarehouseJournalLine."Whse. Document No." := ManagementNoSeries.PeekNextNo(WarehouseJournalBatch."No. Series", WarehouseJournalLine."Registering Date");

        if WarehouseJournalLine."Whse. Document No." = '' then
            WarehouseJournalLine."Whse. Document No." := QltyInspectionTestHeader."No.";

        WarehouseJournalLine."Line No." := LastWhseJnlWarehouseJournalLine."Line No." + 10000;
        WarehouseJournalLine."Registering No. Series" := WarehouseJournalBatch."Registering No. Series";
        WarehouseJournalLine.Validate("Registering Date", WorkDate());
        if TempQuantityToActQltyDispositionBuffer."Reason Code" <> '' then
            WarehouseJournalLine.Validate("Reason Code", TempQuantityToActQltyDispositionBuffer."Reason Code");

        Location.Get(WarehouseJournalBatch."Location Code");
        case true of
            CheckConditionsForWarehouseMovement(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, Location):
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::Movement;
            TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" < 0:
                begin
                    TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" := Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                end;
            else
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
        end;

        WarehouseJournalLine.Validate("Item No.", QltyInspectionTestHeader."Source Item No.");
        if QltyInspectionTestHeader."Source Variant Code" <> '' then
            WarehouseJournalLine.Validate("Variant Code", QltyInspectionTestHeader."Source Variant Code");

        WarehouseJournalLine."From Zone Code" := '';
        WarehouseJournalLine.Validate("From Bin Code", TempQuantityToActQltyDispositionBuffer.GetFromBinCode());

        if TempQuantityToActQltyDispositionBuffer."New Bin Code" <> '' then begin
            WarehouseJournalLine."To Zone Code" := '';
            WarehouseJournalLine.Validate("To Bin Code", TempQuantityToActQltyDispositionBuffer."New Bin Code");
        end;

        WarehouseJournalLine.Validate(Quantity, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");

        WarehouseJournalLine.Insert();

        ExpirationDate := 0D;
        if (QltyInspectionTestHeader."Source Lot No." <> '') or (QltyInspectionTestHeader."Source Serial No." <> '') or (QltyInspectionTestHeader."Source Package No." <> '') then
            ExpirationDate := QltyItemTrackingMgmt.GetExpirationDate(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        WhseTracked := QltyItemTrackingMgmt.GetIsWarehouseTracked(
            WarehouseJournalLine."Item No.");

        if WhseTracked then
            if ((QltyInspectionTestHeader."Source Serial No." <> '') or (QltyInspectionTestHeader."Source Lot No." <> '') or (QltyInspectionTestHeader."Source Package No." <> '') or
               ((TempQuantityToActQltyDispositionBuffer."New Expiration Date" = 0D) and (ExpirationDate <> TempQuantityToActQltyDispositionBuffer."New Expiration Date")))
            then
                QltyItemTrackingMgmt.CreateWarehouseJournalLineReservationEntry(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, WhseItemTrackingLine);

        OnAfterGenericCreateWarehouseJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalBatch, WarehouseJournalLine);
    end;

    local procedure CheckConditionsForWarehouseMovement(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Location: Record Location): Boolean
    begin
        // Check for item tracking movement
        if (TempQuantityToActQltyDispositionBuffer."New Lot No." <> '') and (QltyInspectionTestHeader."Source Lot No." <> TempQuantityToActQltyDispositionBuffer."New Lot No.") then
            exit(true);

        if (TempQuantityToActQltyDispositionBuffer."New Serial No." <> '') and (QltyInspectionTestHeader."Source Serial No." <> TempQuantityToActQltyDispositionBuffer."New Serial No.") then
            exit(true);

        if (TempQuantityToActQltyDispositionBuffer."New Package No." <> '') and (QltyInspectionTestHeader."Source Package No." <> TempQuantityToActQltyDispositionBuffer."New Package No.") then
            exit(true);

        // Check for movement between bins
        if TempQuantityToActQltyDispositionBuffer."New Bin Code" = '' then
            exit(false);

        if TempQuantityToActQltyDispositionBuffer.GetFromBinCode() = TempQuantityToActQltyDispositionBuffer."New Bin Code" then
            exit(false);

        if Location."Adjustment Bin Code" <> TempQuantityToActQltyDispositionBuffer.GetFromBinCode() then
            exit(true);
    end;

    /// <summary>
    /// Posts the supplied warehouse journal line based on the supplied test and instruction.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <returns></returns>
    procedure PostWarehouseJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line") AllLinesPosted: Boolean
    var
        ToPostWarehouseJournalLine: Record "Warehouse Journal Line";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        ConsideredLines: List of [Text];
        ErroredLinesErrorMessages: List of [Text];
        ErrorMessage: Text;
        ErrorStack: Text;
        Handled: Boolean;
    begin
        OnBeforePostWarehouseJournal(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, WarehouseJournalLine, AllLinesPosted, Handled);
        if Handled then
            exit;

        if WarehouseJournalLine."Line No." <> 0 then
            WarehouseJournalLine.SetRecFilter();

        if WarehouseJournalLine.GetFilters() = '' then
            Error(NoFiltersWereSuppliedWhenTryingToPostAWarehouseJournalLineErr);

        if WarehouseJournalLine.FindSet() then begin
            repeat
                ToPostWarehouseJournalLine := WarehouseJournalLine;
                ToPostWarehouseJournalLine.SetRecFilter();
                if not ConsideredLines.Contains(Format(ToPostWarehouseJournalLine.RecordId())) then begin
                    Commit();
                    if not WhseJnlRegisterBatch.Run(ToPostWarehouseJournalLine) then begin
                        ErrorMessage := GetLastErrorText();
                        ErrorStack := GetLastErrorCallStack();
                        ErroredLinesErrorMessages.Add(ErrorMessage);
                        QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, PostedWarehouseJournalEntryDocumentTypeLbl, ErrorMessage, WarehouseJournalLine);
                    end;
                end;
                ConsideredLines.Add(Format(WarehouseJournalLine.RecordId()))
            until WarehouseJournalLine.Next() = 0;
            AllLinesPosted := ErroredLinesErrorMessages.Count() = 0;
        end;

        OnAfterPostWarehouseJournal(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, WarehouseJournalLine, AllLinesPosted);
    end;

    /// <summary>
    /// Creates an item journal line in the appropriate batch.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="ItemJournalBatch"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="ReservationEntry"></param>
    procedure CreateItemJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        LastJnlItemJournalLine: Record "Item Journal Line";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        ManagementNoSeries: Codeunit "No. Series";
        Handled: Boolean;
    begin
        OnBeforeGenericCreateItemJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry, Handled);
        if Handled then
            exit;

        QltyManagementSetup.Get();

        LastJnlItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        LastJnlItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        if not LastJnlItemJournalLine.FindLast() then begin
            LastJnlItemJournalLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
            LastJnlItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        end;

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetUpNewLine(LastJnlItemJournalLine);
        ItemJournalBatch.CalcFields("Template Type");
        case true of
            ItemJournalBatch."Template Type" = ItemJournalBatch."Template Type"::Transfer:
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Transfer;
            TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" < 0:
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
            else
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
        end;
        ItemJournalLine."Line No." := LastJnlItemJournalLine."Line No." + 10000;
        ItemJournalLine.Validate("Posting Date", WorkDate());

        if ItemJournalBatch."No. Series" <> '' then
            if ManagementNoSeries.IsManual(ItemJournalBatch."No. Series") then
                ItemJournalLine."Document No." := QltyInspectionTestHeader."No."
            else
                ItemJournalLine."Document No." := ManagementNoSeries.PeekNextNo(ItemJournalBatch."No. Series", ItemJournalLine."Posting Date");

        if ItemJournalLine."Document No." = '' then
            ItemJournalLine."Document No." := QltyInspectionTestHeader."No.";

        ItemJournalLine.Validate("Item No.", QltyInspectionTestHeader."Source Item No.");
        if QltyInspectionTestHeader."Source Variant Code" <> '' then
            ItemJournalLine.Validate("Variant Code", QltyInspectionTestHeader."Source Variant Code");

        ItemJournalLine.Validate("Location Code", TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        if TempQuantityToActQltyDispositionBuffer."Bin Filter" <> '' then
            ItemJournalLine.Validate("Bin Code", TempQuantityToActQltyDispositionBuffer.GetFromBinCode());

        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then begin
            if TempQuantityToActQltyDispositionBuffer."New Location Code" <> '' then
                ItemJournalLine.Validate("New Location Code", TempQuantityToActQltyDispositionBuffer."New Location Code");

            ItemJournalLine.Validate("New Bin Code", '');
            if (TempQuantityToActQltyDispositionBuffer."New Bin Code" <> '') and (TempQuantityToActQltyDispositionBuffer."New Location Code" <> '') then
                ItemJournalLine.Validate("New Bin Code", TempQuantityToActQltyDispositionBuffer."New Bin Code");
        end;

        ItemJournalLine.Validate(Quantity, Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)"));

        if ((QltyInspectionTestHeader."Source Lot No." <> '') or (QltyInspectionTestHeader."Source Serial No." <> '') or (QltyInspectionTestHeader."Source Package No." <> '')) and (ItemJournalLine."Expiration Date" = 0D) then
            ItemJournalLine."Expiration Date" := QltyItemTrackingMgmt.GetExpirationDate(QltyInspectionTestHeader, ItemJournalLine."Location Code");

        if TempQuantityToActQltyDispositionBuffer."Reason Code" <> '' then
            ItemJournalLine.Validate("Reason Code", TempQuantityToActQltyDispositionBuffer."Reason Code");

        ItemJournalLine.Insert();

        if ((QltyInspectionTestHeader."Source Lot No." <> '') or (QltyInspectionTestHeader."Source Serial No." <> '') or (QltyInspectionTestHeader."Source Package No." <> '') or
           ((TempQuantityToActQltyDispositionBuffer."New Expiration Date" <> 0D) and (ItemJournalLine."Expiration Date" <> TempQuantityToActQltyDispositionBuffer."New Expiration Date")))
        then begin
            ItemJournalLine."Serial No." := QltyInspectionTestHeader."Source Serial No.";
            ItemJournalLine."Lot No." := QltyInspectionTestHeader."Source Lot No.";
            ItemJournalLine."Package No." := QltyInspectionTestHeader."Source Package No.";

            if TempQuantityToActQltyDispositionBuffer."New Package No." <> '' then
                ItemJournalLine."New Package No." := TempQuantityToActQltyDispositionBuffer."New Package No.";

            if TempQuantityToActQltyDispositionBuffer."New Expiration Date" <> 0D then
                ItemJournalLine."New Item Expiration Date" := TempQuantityToActQltyDispositionBuffer."New Expiration Date"
            else
                ItemJournalLine."New Item Expiration Date" := ItemJournalLine."Expiration Date";

            if TempQuantityToActQltyDispositionBuffer."New Lot No." <> '' then
                ItemJournalLine."New Lot No." := TempQuantityToActQltyDispositionBuffer."New Lot No.";

            if TempQuantityToActQltyDispositionBuffer."New Serial No." <> '' then
                ItemJournalLine."New Serial No." := TempQuantityToActQltyDispositionBuffer."New Serial No.";
            if ItemJournalBatch."Item Tracking on Lines" then
                ItemJournalLine.Modify();

            QltyItemTrackingMgmt.CreateItemJournalLineReservationEntry(ItemJournalLine, ReservationEntry);

            if not ItemJournalBatch."Item Tracking on Lines" then begin
                ItemJournalLine."New Lot No." := '';
                ItemJournalLine."New Serial No." := '';
                ItemJournalLine."New Package No." := '';
                ItemJournalLine.Modify(false);
            end;
        end;

        OnAfterGenericCreateItemJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
    end;

    /// <summary>
    /// Posts the supplied item journal line.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="ItemJournalLine"></param>
    /// <returns></returns>
    procedure PostItemJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line") AllLinesPosted: Boolean
    var
        ToPostItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        ConsideredLines: List of [Text];
        ErroredLinesErrorMessages: List of [Text];
        ErrorMessage: Text;
        ErrorStack: Text;
        Handled: Boolean;
    begin
        OnBeforePostItemJournal(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine, AllLinesPosted, Handled);
        if Handled then
            exit;

        if ItemJournalLine."Line No." <> 0 then
            ItemJournalLine.SetRecFilter();

        if ItemJournalLine.GetFilters() = '' then
            Error(NoFiltersWereSuppliedWhenTryingToPostAnItemJournalLineErr);

        if ItemJournalLine.FindSet() then begin
            repeat
                ToPostItemJournalLine := ItemJournalLine;
                ToPostItemJournalLine.SetRecFilter();

                if not ConsideredLines.Contains(Format(ToPostItemJournalLine.RecordId())) then begin
                    Commit();
                    if not ItemJnlPostBatch.Run(ToPostItemJournalLine) then begin
                        ErrorMessage := GetLastErrorText();
                        ErrorStack := GetLastErrorCallStack();
                        ErroredLinesErrorMessages.Add(ErrorMessage);
                        QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, PostedJournalEntryDocumentTypeLbl, ErrorMessage, ItemJournalLine);
                    end;
                end;
                ConsideredLines.Add(Format(ItemJournalLine.RecordId()));
            until ItemJournalLine.Next() = 0;
            AllLinesPosted := ErroredLinesErrorMessages.Count() = 0;
        end;

        OnAfterPostItemJournal(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine, AllLinesPosted);
    end;

    /// <summary>
    /// Used for any warehouse journal line creation.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalBatch"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenericCreateWarehouseJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var Handled: Boolean);
    begin
    end;

    /// <summary>
    /// Used for any warehouse journal line creation.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalBatch"></param>
    /// <param name="WarehouseJournalLine"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGenericCreateWarehouseJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    /// <summary>
    /// Provides an opportunity to extend or replace the creation of a generic item journal line.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="ItemJournalBatch"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="ReservationEntry"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenericCreateItemJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after a generic item journal line has been made, giving the opportunity 
    /// to extend or replace it's functionality.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="ItemJournalBatch"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="ReservationEntry"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGenericCreateItemJournalLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    /// <summary>
    /// Occurs before an item journal post has occurred.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="prbAllLinesPosted"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line"; var prbAllLinesPosted: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after an item journal post has occurred.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="prbAllLinesPosted"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line"; var prbAllLinesPosted: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before a warehouse journal line has been posted.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="prbAllLinesPosted"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWarehouseJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var prbAllLinesPosted: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after a warehouse journal line has been posted.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="prbAllLinesPosted"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWarehouseJournal(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var prbAllLinesPosted: Boolean)
    begin
    end;
}
