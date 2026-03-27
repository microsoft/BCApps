// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Warehouse;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

codeunit 20438 "Qlty. Warehouse Integration"
{
    SingleInstance = true;

    var
        ListOfCreatedInspectionIds: List of [RecordId];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnAfterInsertWhseEntry', '', true, true)]
    local procedure HandleOnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if (WarehouseEntry."Entry Type" <> WarehouseEntry."Entry Type"::Movement) or (WarehouseEntry.Quantity <= 0) then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyInspectionGenRule.SetRange("Warehouse Movement Trigger", QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not QltyInspectionGenRule.IsEmpty() then
            AttemptCreateInspectionWithWhseJournalLine(WarehouseEntry, WarehouseJournalLine, QltyInspectionGenRule);
    end;

    local procedure AttemptCreateInspectionWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        DoNotSendSourceVariant: Variant;
        IsHandled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeWarehouseAttemptCreateInspectionWithWhseJournalLine(WarehouseEntry, WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        Clear(TempTrackingSpecification);
        TempTrackingSpecification."Item No." := WarehouseEntry."Item No.";
        TempTrackingSpecification."Variant Code" := WarehouseEntry."Variant Code";
        TempTrackingSpecification."Lot No." := WarehouseEntry."Lot No.";
        TempTrackingSpecification."Serial No." := WarehouseEntry."Serial No.";
        TempTrackingSpecification."Package No." := WarehouseEntry."Package No.";
        TempTrackingSpecification.Insert(false);

        if GetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, DoNotSendSourceVariant) then
            CollectSourceItemTracking(DoNotSendSourceVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                Clear(QltyInspectionHeader);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseEntry, WarehouseJournalLine, TempTrackingSpecification, DummyVariant, false, QltyInspectionGenRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    if QltyInspectionHeader."No." <> '' then
                        ListOfCreatedInspectionIds.Add(QltyInspectionHeader.RecordId);
                end;
            until TempTrackingSpecification.Next() = 0
        else
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseEntry, WarehouseJournalLine, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                if QltyInspectionHeader."No." <> '' then
                    ListOfCreatedInspectionIds.Add(QltyInspectionHeader.RecordId);
            end;

        OnAfterWarehouseAttemptCreateInspectionWithWhseJournalLine(HasInspection, QltyInspectionHeader, WarehouseEntry, WarehouseJournalLine, DoNotSendSourceVariant);
    end;

    internal procedure GetOptionalSourceVariantForWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var OptionalSourceRecordVariant: Variant) Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        OnBeforeGetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, OptionalSourceRecordVariant, Result, IsHandled);
        if IsHandled then
            exit;

        case WarehouseJournalLine."Source Type" of
            Database::"Purchase Line":
                if PurchaseLine.Get(WarehouseJournalLine."Source Subtype", WarehouseJournalLine."Source No.", WarehouseJournalLine."Source Line No.") then begin
                    OptionalSourceRecordVariant := PurchaseLine;
                    exit(true);
                end;
            Database::"Sales Line":
                if SalesLine.Get(WarehouseJournalLine."Source Subtype", WarehouseJournalLine."Source No.", WarehouseJournalLine."Source Line No.") then begin
                    OptionalSourceRecordVariant := SalesLine;
                    exit(true);
                end;
            Database::"Transfer Line":
                if TransferLine.Get(WarehouseJournalLine."Source No.", WarehouseJournalLine."Source Line No.") then begin
                    OptionalSourceRecordVariant := TransferLine;
                    exit(true);
                end;
        end;
    end;

    internal procedure CollectSourceItemTracking(var OptionalSourceLineVariant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        RecordRefToSource: RecordRef;
        ReservationCounter: Integer;
    begin
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.IsTemporary() then
            TempTrackingSpecification.DeleteAll();

        if not QltyMiscHelpers.GetRecordRefFromVariant(OptionalSourceLineVariant, RecordRefToSource) then
            exit;

        case RecordRefToSource.Number() of
            Database::"Purchase Line":
                PurchLineReserve.FindReservEntry(OptionalSourceLineVariant, ReservationEntry);
            Database::"Transfer Line":
                TransferLineReserve.FindInboundReservEntry(OptionalSourceLineVariant, ReservationEntry);
            Database::"Sales Line":
                SalesLineReserve.FindReservEntry(OptionalSourceLineVariant, ReservationEntry);
            else
                exit;
        end;

        ReservationEntry.SetFilter("Quantity (Base)", '<>0');
        ReservationEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if ReservationEntry.FindSet() then
            repeat
                ReservationCounter += 1;
                Clear(TempTrackingSpecification);
                TempTrackingSpecification."Entry No." := ReservationCounter;
                TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                TempTrackingSpecification.Insert();
            until ReservationEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnBeforeCode', '', true, true)]
    local procedure HandleOnBeforeCodeWhseActivityRegister(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        Clear(ListOfCreatedInspectionIds);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterRegisterWhseActivity', '', true, true)]
    local procedure HandleOnAfterRegisterWhseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        if ListOfCreatedInspectionIds.Count() > 0 then begin
            QltyInspectionCreate.DisplayInspectionsIfConfigured(false, ListOfCreatedInspectionIds);
            Clear(ListOfCreatedInspectionIds);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnBeforePostWhseJnlLines', '', true, true)]
    local procedure HandleOnBeforePostWhseJnlLines(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlTemplateType: Enum "Item Journal Template Type"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
        Clear(ListOfCreatedInspectionIds);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnPostLinesOnAfterPostWhseJnlLine', '', true, true)]
    local procedure HandleOnPostLinesOnAfterPostWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        if ListOfCreatedInspectionIds.Count() > 0 then begin
            QltyInspectionCreate.DisplayInspectionsIfConfigured(false, ListOfCreatedInspectionIds);
            Clear(ListOfCreatedInspectionIds);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Batch", 'OnBeforeCode', '', true, true)]
    local procedure HandleOnBeforeCodeWhseJnlRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
        Clear(ListOfCreatedInspectionIds);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Batch", 'OnAfterCode', '', true, true)]
    local procedure HandleOnAfterCodeWhseJnlRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; WhseRegNo: Integer)
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        if ListOfCreatedInspectionIds.Count() > 0 then begin
            QltyInspectionCreate.DisplayInspectionsIfConfigured(false, ListOfCreatedInspectionIds);
            Clear(ListOfCreatedInspectionIds);
        end;
    end;

    /// <summary>
    /// This occurs before an inspection is about to be created with a warehouse entry.
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseAttemptCreateInspectionWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs after an inspection has been created for a warehouse entry.
    /// </summary>
    /// <param name="HasInspection"></param>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="WarehouseEntry"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="OptionalSourceVariant"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterWarehouseAttemptCreateInspectionWithWhseJournalLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; OptionalSourceVariant: Variant)
    begin
    end;

    /// <summary>
    /// Use this to provide alternate source variants for a given warehouse journal line.
    /// </summary>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="OptionalSourceRecordVariant"></param>
    /// <param name="Result"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOptionalSourceVariantForWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var OptionalSourceRecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
