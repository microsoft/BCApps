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
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using System.Reflection;

codeunit 20438 "Qlty. - Warehouse Integration"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnAfterInsertWhseEntry', '', true, true)]
    local procedure HandleOnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        if WarehouseEntry.Quantity <= 0 then
            exit;

        if WarehouseEntry."Entry Type" <> WarehouseEntry."Entry Type"::Movement then
            exit;

        if not QltyManagementSetup.ReadPermission() then
            exit;
        if not QltyManagementSetup.Get() then
            exit;

        QltyInTestGenerationRule.SetRange("Warehouse Movement Trigger", QltyInTestGenerationRule."Warehouse Movement Trigger"::OnWhseMovementRegister);
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not QltyInTestGenerationRule.IsEmpty() then
            AttemptCreateTestWithWhseJournalLine(WarehouseEntry, WarehouseJournalLine, QltyInTestGenerationRule);
    end;

    local procedure AttemptCreateTestWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        DoNotSendSourceVariant: Variant;
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeWarehouseAttemptCreateTestWithWhseJournalLine(WarehouseEntry, WarehouseJournalLine, Handled);
        if Handled then
            exit;

        Clear(TempTrackingSpecification);
        TempTrackingSpecification."Item No." := WarehouseEntry."Item No.";
        TempTrackingSpecification."Variant Code" := WarehouseEntry."Variant Code";
        TempTrackingSpecification."Lot No." := WarehouseEntry."Lot No.";
        TempTrackingSpecification."Serial No." := WarehouseEntry."Serial No.";
        if TempTrackingSpecification.Insert(false) then;

        if GetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, DoNotSendSourceVariant) then
            CollectSourceItemTracking(DoNotSendSourceVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseEntry, WarehouseJournalLine, TempTrackingSpecification, DummyVariant, false, QltyInTestGenerationRule) then begin
                    HasTest := true;
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else
            if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseEntry, WarehouseJournalLine, DummyVariant, DummyVariant, false, QltyInTestGenerationRule) then begin
                HasTest := true;
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
            end;

        OnAfterWarehouseAttemptCreateTestWithWhseJournalLine(HasTest, QltyInspectionTestHeader, WarehouseEntry, WarehouseJournalLine, DoNotSendSourceVariant);
    end;

    internal procedure GetOptionalSourceVariantForWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var OptionalSourceRecordVariant: Variant) Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        Handled: Boolean;
    begin
        OnBeforeGetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, OptionalSourceRecordVariant, Result, Handled);
        if Handled then
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
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRefToSource: RecordRef;
        Counter: Integer;
    begin
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.IsTemporary() then
            TempTrackingSpecification.DeleteAll();

        if not DataTypeManagement.GetRecordRef(OptionalSourceLineVariant, RecordRefToSource) then
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
                Counter += 1;
                Clear(TempTrackingSpecification);
                TempTrackingSpecification."Entry No." := Counter;
                TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                TempTrackingSpecification."Package No." := ReservationEntry."Package No.";
                TempTrackingSpecification.Insert();
            until ReservationEntry.Next() = 0;
    end;

    /// <summary>
    /// This occurs before a test is about to be created with a warehouse entry.
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseAttemptCreateTestWithWhseJournalLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs after a test has been created for a warehouse entry.
    /// </summary>
    /// <param name="HasTest"></param>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="WarehouseEntry"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="poptionalSourceVariant"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterWarehouseAttemptCreateTestWithWhseJournalLine(var HasTest: Boolean; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; poptionalSourceVariant: Variant)
    begin
    end;

    /// <summary>
    /// Use this to provide alternate source variants for a given warehouse journal line.
    /// </summary>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="OptionalSourceRecordVariant"></param>
    /// <param name="Result"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOptionalSourceVariantForWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var OptionalSourceRecordVariant: Variant; var Result: Boolean; var Handled: Boolean)
    begin
    end;
}
