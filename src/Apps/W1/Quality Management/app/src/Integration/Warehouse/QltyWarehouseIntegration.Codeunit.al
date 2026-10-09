// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Warehouse;

using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

codeunit 20438 "Qlty. Warehouse Integration"
{
    Permissions =
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Header" = r;

    /// <summary>
    /// Creates inspections for positive warehouse movement entries when an active automatic generation rule applies.
    /// </summary>
    /// <param name="WarehouseEntry">The registered warehouse entry.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line that produced the entry.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
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

        if not HasWhseMovementRegisterGenRule(QltyInspectionGenRule) then
            exit;

        AttemptCreateInspectionWithWhseJournalLine(WarehouseEntry, WarehouseJournalLine, QltyInspectionGenRule);
    end;

    /// <summary>
    /// Filters generation rules for automatic warehouse movement registration.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasWhseMovementRegisterGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.SetRange("Warehouse Movement Trigger", QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Attempts to create inspections for a warehouse movement entry and its tracking details.
    /// </summary>
    /// <param name="WarehouseEntry">The registered warehouse entry.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line that produced the entry.</param>
    /// <param name="QltyInspectionGenRule">The filtered generation rules to apply.</param>
    local procedure AttemptCreateInspectionWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyBatchNotifHelper: Codeunit "Qlty. Batch Notif. Helper";
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

        QltyBatchNotifHelper.BeginBatch();
        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                Clear(QltyInspectionHeader);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseEntry, WarehouseJournalLine, TempTrackingSpecification, DummyVariant, false, QltyInspectionGenRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                end;
            until TempTrackingSpecification.Next() = 0
        else
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseEntry, WarehouseJournalLine, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
            end;
        QltyBatchNotifHelper.EndBatch();

        OnAfterWarehouseAttemptCreateInspectionWithWhseJournalLine(HasInspection, QltyInspectionHeader, WarehouseEntry, WarehouseJournalLine, DoNotSendSourceVariant);
    end;

    /// <summary>
    /// Resolves the purchase, sales, or transfer line referenced by a warehouse journal line.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line whose source is resolved.</param>
    /// <param name="OptionalSourceRecordVariant">The resolved source line.</param>
    /// <returns>True if a supported source line was found; otherwise, false.</returns>
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

    /// <summary>
    /// Collects nonzero reservation tracking details for a supported source line.
    /// </summary>
    /// <param name="OptionalSourceLineVariant">The purchase, sales, or transfer line from which to collect reservations.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking specification populated from matching reservations.</param>
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

    /// <summary>
    /// Notifies subscribers before inspections are created for a warehouse movement entry.
    /// </summary>
    /// <param name="WarehouseEntry">The registered warehouse entry.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line that produced the entry.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseAttemptCreateInspectionWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for a warehouse movement entry.
    /// </summary>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="QltyInspectionHeader">The last inspection created or resolved.</param>
    /// <param name="WarehouseEntry">The registered warehouse entry.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line that produced the entry.</param>
    /// <param name="OptionalSourceVariant">The source line resolved from the warehouse journal line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterWarehouseAttemptCreateInspectionWithWhseJournalLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; OptionalSourceVariant: Variant)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before resolving the source line for a warehouse journal line.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line whose source is resolved.</param>
    /// <param name="OptionalSourceRecordVariant">The source line supplied by the subscriber.</param>
    /// <param name="Result">Indicates whether a source line was resolved.</param>
    /// <param name="IsHandled">Set to true to skip the default source resolution.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOptionalSourceVariantForWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var OptionalSourceRecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
