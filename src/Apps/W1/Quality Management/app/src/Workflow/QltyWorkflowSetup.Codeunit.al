// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.QualityManagement.Document;
using System.Automation;
using System.Security.AccessControl;

/// <summary>
/// This codeunit deals with setup integration events, and other setup related to Business Central workflows.
/// No processing occurs in this codeunit, but anything related to the setup and template of available events and responses will be here.
/// </summary>
codeunit 20423 "Qlty. Workflow Setup"
{
    var
        QltyPrefixTok: Label 'QLTY-', Locked = true;
        InspectionFinishesEventTok: Label 'QLTY-E-FINISH-1', Locked = true;
        InspectionReopenedEventTok: Label 'QLTY-E-REOPEN-1', Locked = true;
        InspectionCreatedEventTok: Label 'QLTY-E-CREATE-1', Locked = true;
        InspectionHasChangedEventTok: Label 'QLTY-E-CHANGE-1', Locked = true;
        QltyInspectionRejectWorkflowEventTok: Label 'QLTY-A-RJCT-1', locked = true;
        QltyInspectionDelegateWorkflowEventTok: Label 'QLTY-A-DLGT-1', locked = true;
        QltyInspectionApproveWorkflowEventTok: Label 'QLTY-A-APPR-1', locked = true;
        QMWorkflowResponseCreateInspectionTok: Label 'QLTY-R-CREATE-1', Locked = true;
        QMWorkflowResponseFinishInspectionTok: Label 'QLTY-R-FINISH-1', Locked = true;
        QMWorkflowResponseReopenInspectionTok: Label 'QLTY-R-REOPEN-1', Locked = true;
        QMWorkflowResponseCreateReinspectionTok: Label 'QLTY-R-REINSPECT-1', Locked = true;
        QMWorkflowResponseBlockLotTok: Label 'QLTY-R-BLCKLOT-1', Locked = true;
        QMWorkflowResponseUnblockLotTok: Label 'QLTY-R-UBLCKLOT-1', Locked = true;
        QMWorkflowResponseBlockSerialTok: Label 'QLTY-R-BLCKSERIAL-1', Locked = true;
        QMWorkflowResponseUnblockSerialTok: Label 'QLTY-R-UBLCKSERIAL-1', Locked = true;
        QMWorkflowResponseBlockPackageTok: Label 'QLTY-R-BLCKPKG-1', Locked = true;
        QMWorkflowResponseUnblockPackageTok: Label 'QLTY-R-UBLCKPKG-1', Locked = true;
        QMWorkflowResponseMoveInventoryTok: Label 'QLTY-R-MOVE-1', Locked = true;
        QMWorkflowResponseQuarantineLicensePlateTok: Label 'QLTY-R-QLP-1', Locked = true;
        QMWorkflowResponseUnQuarantineLicensePlateTok: Label 'QLTY-R-UQLP-1', Locked = true;
        QMWorkflowResponseInternalPutAwayTok: Label 'QLTY-R-IPUT-1', Locked = true;
        QMWorkflowResponseSetDatabaseValueTok: Label 'QLTY-R-SDB-1', Locked = true;
        QMWorkflowResponseAdjInventoryTok: Label 'QLTY-R-ADJ-1', Locked = true;
        QMWorkflowResponseChangeItemTrackingTok: Label 'QLTY-R-ITEMTRACK-1', Locked = true;
        QMWorkflowResponseCreateTransferTok: Label 'QLTY-R-TRANSFER-1', Locked = true;
        QMWorkflowResponseCreatePurchaseReturnTok: Label 'QLTY-R-PURRETURN-1', Locked = true;
        QMWorkflowEventDescriptionAQltyInspectionHasChangedLbl: Label 'A Quality Inspection has changed', Locked = true;
        QMWorkflowEventDescriptionAQltyInspectionHasBeenCreatedLbl: Label 'A Quality Inspection is created', Locked = true;
        QMWorkflowEventDescriptionAQltyInspectionHasBeenFinishedLbl: Label 'A Quality Inspection is finished', Locked = true;
        QMWorkflowEventDescriptionAQltyInspectionHasBeenReopenedLbl: Label 'A Quality Inspection is reopened', Locked = true;
        QMWorkflowResponseDescriptionCreateAQltyInspectionLbl: Label 'Create a Quality Inspection', Locked = true;
        QMWorkflowResponseDescriptionFinishTheQltyInspectionLbl: Label 'Finish the Quality Inspection', Locked = true;
        QMWorkflowResponseDescriptionReopenTheQltyInspectionLbl: Label 'Reopen the Quality Inspection', Locked = true;
        QMWorkflowResponseDescriptionCreateReinspectionLbl: Label 'Create Re-inspection', Locked = true;
        QMWorkflowResponseDescriptionBlockLotLbl: Label 'Block Lot in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionBlockSerialLbl: Label 'Block Serial in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionBlockPackageLbl: Label 'Block Package in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionUnblockLotLbl: Label 'Unblock Lot in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionUnblockSerialLbl: Label 'Unblock Serial in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionUnblockPackageLbl: Label 'Unblock Package in the Inspection', Locked = true;
        QMWorkflowResponseDescriptionMoveInventoryLbl: Label 'Move Inventory from Inspection', Locked = true;
        QMWorkflowResponseDescriptionCreateInternalPutAwayLbl: Label 'Create an Internal Put-away', Locked = true;
        QMWorkflowResponseDescriptionSetDatabaseValueLbl: Label 'Set Database Value', Locked = true;
        QMWorkflowResponseDescriptionCreateNegativeAdjustmentLbl: Label 'Create a Negative Adjustment', Locked = true;
        QMWorkflowResponseDescriptionChangeItemTrackingInformationLbl: Label 'Change Item Tracking Information', Locked = true;
        QMWorkflowResponseDescriptionCreateTransferOrderLbl: Label 'Create Transfer Order', Locked = true;
        QMWorkflowResponseDescriptionCreatePurchaseReturnOrderLbl: Label 'Create Purchase Return', Locked = true;
        QMWorkflowDescriptionOptionalSuffixLbl: Label ' - Foundation', Locked = true;

    /// <summary>
    /// Returns the token for a workflow response to create an inspection.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseCreateInspection(): Text
    begin
        exit(QMWorkflowResponseCreateInspectionTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to finish an inspection
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseFinishInspection(): Text
    begin
        exit(QMWorkflowResponseFinishInspectionTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to re-open an inspection
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseReopenInspection(): Text
    begin
        exit(QMWorkflowResponseReopenInspectionTok);
    end;

    internal procedure GetWorkflowResponseCreateReinspection(): Text
    begin
        exit(QMWorkflowResponseCreateReinspectionTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a lot
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseBlockLot(): Text
    begin
        exit(QMWorkflowResponseBlockLotTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a serial
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseBlockSerial(): Text
    begin
        exit(QMWorkflowResponseBlockSerialTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a package
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseBlockPackage(): Text
    begin
        exit(QMWorkflowResponseBlockPackageTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to Unblock a lot
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseUnblockLot(): Text
    begin
        exit(QMWorkflowResponseUnblockLotTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to Unblock a serial
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseUnblockSerial(): Text
    begin
        exit(QMWorkflowResponseUnblockSerialTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to Unblock a package
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseUnblockPackage(): Text
    begin
        exit(QMWorkflowResponseUnblockPackageTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to move inventory
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseMoveInventory(): Text
    begin
        exit(QMWorkflowResponseMoveInventoryTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to quarantine a license plate
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseQuarantineLicensePlate(): Text
    begin
        exit(QMWorkflowResponseQuarantineLicensePlateTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to un-quarantine a license plate.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseUnQuarantineLicensePlate(): Text
    begin
        exit(QMWorkflowResponseUnQuarantineLicensePlateTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to create an internal put-away.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseInternalPutAway(): Text
    begin
        exit(QMWorkflowResponseInternalPutAwayTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to set a database value
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetWorkflowResponseSetDatabaseValue(): Text
    begin
        exit(QMWorkflowResponseSetDatabaseValueTok);
    end;

    /// <summary>
    ///Returns the token for a workflow response to create a inventory adjustment
    /// </summary>
    /// <returns></returns>
    procedure GetWorkflowResponseInventoryAdjustment(): Text
    begin
        exit(QMWorkflowResponseAdjInventoryTok);
    end;

    /// <summary>
    ///Returns the token for a workflow response to change item tracking
    /// </summary>
    /// <returns></returns>
    internal procedure GetWorkflowResponseChangeItemTracking(): Text
    begin
        exit(QMWorkflowResponseChangeItemTrackingTok);
    end;

    /// <summary>
    ///Returns the token for a workflow response to create a transfer
    /// </summary>
    /// <returns></returns>
    procedure GetWorkflowResponseCreateTransfer(): Text
    begin
        exit(QMWorkflowResponseCreateTransferTok);
    end;

    /// <summary>
    ///Returns the token for a workflow response to create a purchase return
    /// </summary>
    /// <returns></returns>
    procedure GetWorkflowResponseCreatePurchaseReturn(): Text
    begin
        exit(QMWorkflowResponseCreatePurchaseReturnTok);
    end;

    /// <summary>
    /// Returns the generic quality inspection workflow prefix.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetQualityInspectionPrefix(): Text
    begin
        exit(QltyPrefixTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been created.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    internal procedure GetInspectionCreatedEvent(): Code[128]
    begin
        exit(InspectionCreatedEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been changed.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetInspectionHasChangedEvent(): Code[128]
    begin
        exit(InspectionHasChangedEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been finished.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetInspectionFinishedEvent(): Code[128]
    begin
        exit(InspectionFinishesEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been re-opened.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetInspectionReopenedEvent(): Code[128]
    begin
        exit(InspectionReopenedEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been rejected in an approval.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    internal procedure GetInspectionRejectEventTok(): Code[128]
    begin
        exit(QltyInspectionRejectWorkflowEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been approved in an approval system.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    internal procedure GetInspectionApproveEventTok(): Code[128]
    begin
        exit(QltyInspectionApproveWorkflowEventTok);
    end;

    /// <summary>
    /// The token for the event when an inspection has been delegated in an approval.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    internal procedure GetInspectionDelegateEventTok(): Code[128]
    begin
        exit(QltyInspectionDelegateWorkflowEventTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowTableRelationsToLibrary()
    begin
        AddEmployeeUserRelationships();
    end;

    local procedure AddEmployeeUserRelationships()
    var
        User: Record User;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(Database::"User", User.FieldNo("User Name"), Database::"Qlty. Inspection Header", QltyInspectionHeader.FieldNo("Assigned User ID"));
        WorkflowSetup.InsertTableRelation(Database::"Qlty. Inspection Header", QltyInspectionHeader.FieldNo("No."), database::"Approval Entry", ApprovalEntry.FieldNo("Document No."));
        WorkflowSetup.InsertTableRelation(Database::"Qlty. Inspection Line", QltyInspectionLine.FieldNo("Inspection No."), database::"Approval Entry", ApprovalEntry.FieldNo("Document No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowEventsToLibrary()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        OptionalSuffix: Text;
    begin
        WorkflowEvent.SetFilter("Function Name", QltyPrefixTok + '*');
        WorkflowEvent.DeleteAll(false);

        WorkflowEvent.Reset();
        WorkflowEvent.SetRange(Description, QMWorkflowEventDescriptionAQltyInspectionHasChangedLbl);
        if not WorkflowEvent.IsEmpty() then
            OptionalSuffix := QMWorkflowDescriptionOptionalSuffixLbl;

        WorkflowEventHandling.AddEventToLibrary(GetInspectionHasChangedEvent(), Database::"Qlty. Inspection Header", QMWorkflowEventDescriptionAQltyInspectionHasChangedLbl + OptionalSuffix, 0, true);
        WorkflowEventHandling.AddEventToLibrary(GetInspectionCreatedEvent(), Database::"Qlty. Inspection Header", QMWorkflowEventDescriptionAQltyInspectionHasBeenCreatedLbl + OptionalSuffix, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetInspectionFinishedEvent(), Database::"Qlty. Inspection Header", QMWorkflowEventDescriptionAQltyInspectionHasBeenFinishedLbl + OptionalSuffix, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetInspectionReopenedEvent(), Database::"Qlty. Inspection Header", QMWorkflowEventDescriptionAQltyInspectionHasBeenReopenedLbl + OptionalSuffix, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            'RUNWORKFLOWONAPPROVEAPPROVALREQUEST',
            'RUNWORKFLOWONREJECTAPPROVALREQUEST',
            'RUNWORKFLOWONDELEGATEAPPROVALREQUEST',
            QltyInspectionRejectWorkflowEventTok,
            QltyInspectionDelegateWorkflowEventTok,
            QltyInspectionApproveWorkflowEventTok:
                begin
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetInspectionFinishedEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetInspectionReopenedEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetInspectionCreatedEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetInspectionHasChangedEvent());
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        FunctionName: Text;
        QualityEventIds: List of [Text];
        QualityEvent: Text;
    begin
        FunctionName := ResponseFunctionName;

        QualityEventIds.Add(GetInspectionCreatedEvent());
        QualityEventIds.Add(GetInspectionFinishedEvent());
        QualityEventIds.Add(GetInspectionHasChangedEvent());
        QualityEventIds.Add(GetInspectionReopenedEvent());

        if FunctionName.StartsWith(GetQualityInspectionPrefix()) then
            foreach QualityEvent in QualityEventIds do
                WorkflowResponseHandling.AddResponsePredecessor(ResponseFunctionName, CopyStr(QualityEvent, 1, 128));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowResponsesToLibrary()
    var
        WorkflowResponse: Record "Workflow Response";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        QualityEventIds: List of [Text];
        QualityResponseIdsToAdd: List of [Text];
        QualityEvent: Text;
        QualityResponse: Text;
        OptionalSuffix: Text;
    begin
        WorkflowResponse.SetFilter("Function Name", QltyPrefixTok + '*');
        if WorkflowResponse.FindSet() then
            repeat
                WorkflowResponse.MakeDependentOnAllEvents();
            until WorkflowResponse.Next() = 0;

        WorkflowResponse.DeleteAll(false);
        WorkflowResponse.Reset();
        WorkflowResponse.SetRange(Description, QMWorkflowResponseDescriptionCreateAQltyInspectionLbl);
        if not WorkflowResponse.IsEmpty() then
            OptionalSuffix := QMWorkflowDescriptionOptionalSuffixLbl;

        QualityEventIds.Add(GetInspectionCreatedEvent());
        QualityEventIds.Add(GetInspectionFinishedEvent());
        QualityEventIds.Add(GetInspectionHasChangedEvent());
        QualityEventIds.Add(GetInspectionReopenedEvent());

        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreateInspection(), 1, 128), 0, QMWorkflowResponseDescriptionCreateAQltyInspectionLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreateInspection(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreateInspection(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseFinishInspection(), 1, 128), 0, QMWorkflowResponseDescriptionFinishTheQltyInspectionLbl + OptionalSuffix, CopyStr(GetWorkflowResponseFinishInspection(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseFinishInspection(), 1, 128));

        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseReopenInspection(), 1, 128), 0, QMWorkflowResponseDescriptionReopenTheQltyInspectionLbl + OptionalSuffix, CopyStr(GetWorkflowResponseReopenInspection(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseReopenInspection(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreateReinspection(), 1, 128), 0, QMWorkflowResponseDescriptionCreateReinspectionLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreateReinspection(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreateReinspection(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseBlockLot(), 1, 128), 0, QMWorkflowResponseDescriptionBlockLotLbl + OptionalSuffix, CopyStr(GetWorkflowResponseBlockLot(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseBlockLot(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseBlockSerial(), 1, 128), 0, QMWorkflowResponseDescriptionBlockSerialLbl + OptionalSuffix, CopyStr(GetWorkflowResponseBlockSerial(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseBlockSerial(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnblockLot(), 1, 128), 0, QMWorkflowResponseDescriptionUnblockLotLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnblockLot(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnblockLot(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnblockSerial(), 1, 128), 0, QMWorkflowResponseDescriptionUnblockSerialLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnblockSerial(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnblockSerial(), 1, 128));

        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseMoveInventory(), 1, 128), 0, QMWorkflowResponseDescriptionMoveInventoryLbl + OptionalSuffix, CopyStr(GetWorkflowResponseMoveInventory(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseMoveInventory(), 1, 128));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnQuarantineLicensePlate(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseInternalPutAway(), 1, 128), 0, QMWorkflowResponseDescriptionCreateInternalPutAwayLbl + OptionalSuffix, CopyStr(GetWorkflowResponseInternalPutAway(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseInternalPutAway(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseSetDatabaseValue(), 1, 128), 0, QMWorkflowResponseDescriptionSetDatabaseValueLbl + OptionalSuffix, CopyStr(GetWorkflowResponseSetDatabaseValue(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseSetDatabaseValue(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseInventoryAdjustment(), 1, 128), 0, QMWorkflowResponseDescriptionCreateNegativeAdjustmentLbl + OptionalSuffix, CopyStr(GetWorkflowResponseInventoryAdjustment(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseInventoryAdjustment(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseChangeItemTracking(), 1, 128), 0, QMWorkflowResponseDescriptionChangeItemTrackingInformationLbl + OptionalSuffix, CopyStr(GetWorkflowResponseChangeItemTracking(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseChangeItemTracking(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreateTransfer(), 1, 128), 0, QMWorkflowResponseDescriptionCreateTransferOrderLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreateTransfer(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreateTransfer(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreatePurchaseReturn(), 1, 128), 0, QMWorkflowResponseDescriptionCreatePurchaseReturnOrderLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreatePurchaseReturn(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreatePurchaseReturn(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseBlockPackage(), 1, 128), 0, QMWorkflowResponseDescriptionBlockPackageLbl + OptionalSuffix, CopyStr(GetWorkflowResponseBlockPackage(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseBlockPackage(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnblockPackage(), 1, 128), 0, QMWorkflowResponseDescriptionUnblockPackageLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnblockPackage(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnblockPackage(), 1, 128));
        foreach QualityResponse in QualityResponseIdsToAdd do
            foreach QualityEvent in QualityEventIds do
                WorkflowResponseHandling.AddResponsePredecessor(CopyStr(QualityResponse, 1, 128), CopyStr(QualityEvent, 1, 128));
    end;
}
