// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

codeunit 20452 "Qlty. Disp. Move Item Reclass." implements "Qlty. Disposition"
{
    var
        ItemJournalLineDescriptionTemplateLbl: Label 'Test [%3] changed bin from [%1] to [%2]', Comment = '%1 = From Bin code; %2 = To Bin code; %3 = the test';
        MissingBinMoveBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the movement batches.';
        DocumentTypeLbl: Label 'Item Reclassification';

    procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ItemJournalLine: Record "Item Journal Line";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        CreatedLineNo: Integer;
        Handled: Boolean;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";

        OnBeforeProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething, Handled);
        if Handled then
            exit;

        QltyManagementSetup.Get();
        if QltyManagementSetup."Bin Move Batch Name" = '' then
            Error(MissingBinMoveBatchErr);

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(CreatedLineNo);
            CreateItemReclassificationLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Bin Move Batch Name", CreatedLineNo);

            if CreatedLineNo <> 0 then begin
                DidSomething := true;
                if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post then begin
                    ItemJournalLine.SetRange("Journal Template Name", QltyManagementSetup.GetItemReclassJournalTemplate());
                    ItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Bin Move Batch Name");
                    ItemJournalLine.SetRange("Line No.", CreatedLineNo);
                    DidSomething := QltyItemJournalManagement.PostItemJournal(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine);
                    if DidSomething then
                        QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Bin Move Batch Name")
                    else begin
                        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

                        QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Bin Move Batch Name");

                        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;
                    end;
                end else
                    QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Bin Move Batch Name");
            end;
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if not DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" <> TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);

        OnAfterProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething);
    end;

    local procedure CreateItemReclassificationLine(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; BatchName: Code[10]; var CreatedLineNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        Handled: Boolean;
    begin
        QltyManagementSetup.Get();
        OnBeforeCreateItemReclassificationLine(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, BatchName, ItemJournalLine, Handled);
        if Handled then
            exit;

        ItemJournalBatch.SetAutoCalcFields("Template Type");
        ItemJournalBatch.Get(QltyManagementSetup.GetItemReclassJournalTemplate(), BatchName);

        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
        ItemJournalLine.Description := CopyStr(StrSubstNo(ItemJournalLineDescriptionTemplateLbl, TempInstructionQltyDispositionBuffer.GetFromBinCode(), TempInstructionQltyDispositionBuffer."New Bin Code", QltyInspectionTestHeader.GetFriendlyIdentifier()), 1, MaxStrLen(ItemJournalLine.Description));
        ItemJournalLine.Modify(false);

        CreatedLineNo := ItemJournalLine."Line No.";
    end;

    /// <summary>
    /// This allows extensions to override or replace the item reclassification event.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="BatchName"></param>
    /// <param name="ItemJournalLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemReclassificationLine(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var BatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before the disposition has taken place, allowing the opportunity to extend or replace the functionality.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="prbChanged"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbChanged: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after the disposition has taken place.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="prbChanged"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbChanged: Boolean)
    begin
    end;
}
