// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.PutAway;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Request;

/// <summary>
/// This codeunit is responsible for the reaction of creating Warehouse put-aways.
/// This will create warehouse internal put-aways as an interim step.
/// </summary>
codeunit 20453 "Qlty. Disp. Warehouse Put-away" implements "Qlty. Disposition"
{
    EventSubscriberInstance = Manual;

    var
        CreatedWarehouseActivityHeader: Code[20];
        DocumentTypeLbl: Label 'Warehouse Put-Away';

    /// <summary>
    /// Create a warehouse put-away(s) from the supplied inspection.
    /// It's possible that multiple put-away's could be created if the lot is in multiple bins, but the typical scenario would be
    /// one internal put-away.
    /// You must be in a directed pick and put location, and you must be using lot warehouse tracking to use this feature.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to put away.</param>
    /// <param name="OptionalSpecificQuantity">The specific base quantity to put away when required by the quantity behavior.</param>
    /// <param name="OptionalSourceLocationFilter">An optional source location filter.</param>
    /// <param name="OptionalSourceBinFilter">An optional source bin filter.</param>
    /// <param name="QltyQuantityBehavior">The rule used to determine the put-away quantity.</param>
    /// <returns>True if a warehouse put-away document was created; otherwise, false.</returns>
    internal procedure PerformDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior") DidSomething: Boolean
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Warehouse Put-away";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := OptionalSpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(OptionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(OptionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        exit(PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    /// <summary>
    /// Creates warehouse put-away documents through released internal put-away documents.
    /// It's possible that multiple put-away's could be created if the lot is in multiple bins, but the typical scenario would be one internal put-away.
    /// You must be in a directed pick and put location, and you must be using lot warehouse tracking to use this feature.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to put away.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions containing source filters and quantity.</param>
    /// <returns>True if a warehouse put-away document was created; otherwise, false.</returns>
    procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        TempCreatedBufferWhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header" temporary;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        PutAwayWarehouseActivityHeader: Record "Warehouse Activity Header";
        PutAwayFromWhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Internal Put-away";
        QltyDispInternalPutAway.SetSuppressNotifications(true);
        QltyDispInternalPutAway.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);

        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Warehouse Put-away";

        QltyDispInternalPutAway.GetCreatedWarehouseInternalPutAwayHeaderBuffer(TempCreatedBufferWhseInternalPutAwayHeader);
        TempCreatedBufferWhseInternalPutAwayHeader.Reset();
        TempCreatedBufferWhseInternalPutAwayHeader.FindSet();
        repeat
            Clear(CreatedWarehouseActivityHeader);

            if WhseInternalPutAwayHeader.Get(TempCreatedBufferWhseInternalPutAwayHeader."No.") then begin
                PutAwayFromWhseSourceCreateDocument.SetWhseInternalPutAway(WhseInternalPutAwayHeader);
                PutAwayFromWhseSourceCreateDocument.SetHideValidationDialog(true);
                PutAwayFromWhseSourceCreateDocument.UseRequestPage(false);
                BindSubscription(this);
                PutAwayFromWhseSourceCreateDocument.Run();
                UnbindSubscription(this);
                Clear(PutAwayWarehouseActivityHeader);
                DidSomething := PutAwayWarehouseActivityHeader.Get(PutAwayWarehouseActivityHeader.Type::"Put-away", CreatedWarehouseActivityHeader);

                if DidSomething then
                    QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl, PutAwayWarehouseActivityHeader."No.", PutAwayWarehouseActivityHeader);
            end;
        until TempCreatedBufferWhseInternalPutAwayHeader.Next() = 0;
        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    #region Event Subscribers

    /// <summary>
    /// Captures the last warehouse activity number created by the warehouse source report.
    /// </summary>
    /// <param name="FirstActivityNo">The first warehouse activity number created by the report.</param>
    /// <param name="LastActivityNo">The last warehouse activity number created by the report.</param>
    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnAfterPostReport', '', true, true)]
    local procedure HandleOnAfterPostReport(FirstActivityNo: Code[20]; LastActivityNo: Code[20])
    begin
        CreatedWarehouseActivityHeader := LastActivityNo;
    end;

    #endregion Event Subscribers
}
