// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

codeunit 20449 "Qlty. Disp. Move Whse.Reclass." implements "Qlty. Disposition"
{
    var
        WarehouseJournalLineDescriptionTemplateLbl: Label 'Test [%3] changed bin from [%1] to [%2]', Comment = '%1 = From Bin code; %2 = To Bin code; %3 = the test';
        MissingBinMoveBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the Reclass batch.';
        DocumentTypeLbl: Label 'Warehouse Reclassification';

    procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        QltyManagementSetup.Get();
        if QltyManagementSetup."Bin Whse. Move Batch Name" = '' then
            Error(MissingBinMoveBatchErr);

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            CreateWarehouseReclassLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Bin Whse. Move Batch Name", WarehouseJournalLine, WhseItemTrackingLine);
            if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post then begin
                DidSomething := false;
                DidSomething := QltyItemJournalManagement.PostWarehouseJournal(
                    QltyInspectionTestHeader,
                    TempInstructionQltyDispositionBuffer,
                    WarehouseJournalLine);
            end else
                DidSomething := true;

            if not DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then begin
                TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

                QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Bin Whse. Move Batch Name");

                TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;
            end else
                QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Bin Whse. Move Batch Name");
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if not DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" <> TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    /// <summary>
    /// Adds a whse. reclass journal line for directed pick locations
    /// </summary>
    local procedure CreateWarehouseReclassLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; WarehouseReclassBatchName: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseJnlWarehouseJournalBatch: Record "Warehouse Journal Batch";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        Handled: Boolean;
    begin
        Clear(WarehouseJournalLine);
        WarehouseJournalLine.Reset();

        QltyManagementSetup.Get();
        WhseJnlWarehouseJournalBatch.Get(QltyManagementSetup.GetWarehouseReclassificationJournalTemplate(), WarehouseReclassBatchName, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        OnBeforeCreateWarehouseReclassLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseReclassBatchName, WarehouseJournalLine, WhseItemTrackingLine, Handled);
        if Handled then
            exit;

        QltyItemJournalManagement.CreateWarehouseJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WhseJnlWarehouseJournalBatch, WarehouseJournalLine, WhseItemTrackingLine);

        WarehouseJournalLine.Description := CopyStr(StrSubstNo(
            WarehouseJournalLineDescriptionTemplateLbl,
            TempQuantityToActQltyDispositionBuffer.GetFromBinCode(),
            TempQuantityToActQltyDispositionBuffer."New Bin Code",
            QltyInspectionTestHeader.GetFriendlyIdentifier()), 1, MaxStrLen(WarehouseJournalLine.Description));
        WarehouseJournalLine.Modify();

        OnAfterCreateWarehouseReclassLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, WhseItemTrackingLine);
    end;

    /// <summary>
    /// This allows extensions to override or replace the warehouse reclass journal line insertion.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="BatchName"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="WhseItemTrackingLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWarehouseReclassLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var BatchName: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// This allows extensions to alter data after the reclass line has been made.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="WhseItemTrackingLine"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWarehouseReclassLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}
