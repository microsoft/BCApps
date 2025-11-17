// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using System.Automation;
using System.Security.AccessControl;

/// <summary>
/// This codeunit deals with setup integration events, and other setup related to Business Central workflows.
/// No processing occurs in this codeunit, but anything related to the setup and template of available events and responses will be here.
/// </summary>
codeunit 20423 "Qlty. Workflow Setup"
{
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyPrefixTok: Label 'QLTY-', Locked = true;
        TestFinishesEventTok: Label 'QLTY-E-FINISH-1', Locked = true;
        TestReopensEventTok: Label 'QLTY-E-REOPEN-1', Locked = true;
        TestCreatedEventTok: Label 'QLTY-E-CREATE-1', Locked = true;
        TestHasChangedEventTok: Label 'QLTY-E-CHANGE-1', Locked = true;
        QITestRejectWorkflowEventTok: Label 'QLTY-A-RJCT-1', locked = true;
        QITestDelegateWorkflowEventTok: Label 'QLTY-A-DLGT-1', locked = true;
        QITestApproveWorkflowEventTok: Label 'QLTY-A-APPR-1', locked = true;
        QMWorkflowResponseCreateTestTok: Label 'QLTY-R-CREATE-1', Locked = true;
        QMWorkflowResponseFinishTestTok: Label 'QLTY-R-FINISH-1', Locked = true;
        QMWorkflowResponseReopenTestTok: Label 'QLTY-R-REOPEN-1', Locked = true;
        QMWorkflowResponseCreateRetestTok: Label 'QLTY-R-RETEST-1', Locked = true;
        QMWorkflowResponseBlockLotTok: Label 'QLTY-R-BLCKLOT-1', Locked = true;
        QMWorkflowResponseUnBlockLotTok: Label 'QLTY-R-UBLCKLOT-1', Locked = true;
        QMWorkflowResponseBlockSerialTok: Label 'QLTY-R-BLCKSERIAL-1', Locked = true;
        QMWorkflowResponseUnBlockSerialTok: Label 'QLTY-R-UBLCKSERIAL-1', Locked = true;
        QMWorkflowResponseBlockPackageTok: Label 'QLTY-R-BLCKPKG-1', Locked = true;
        QMWorkflowResponseUnBlockPackageTok: Label 'QLTY-R-UBLCKPKG-1', Locked = true;
        QMWorkflowResponseMoveInventoryTok: Label 'QLTY-R-MOVE-1', Locked = true;
        QMWorkflowResponseQuarantineLicensePlateTok: Label 'QLTY-R-QLP-1', Locked = true;
        QMWorkflowResponseUnQuarantineLicensePlateTok: Label 'QLTY-R-UQLP-1', Locked = true;
        QMWorkflowResponseInternalPutAwayTok: Label 'QLTY-R-IPUT-1', Locked = true;
        QMWorkflowResponseSetDatabaseValueTok: Label 'QLTY-R-SDB-1', Locked = true;
        QMWorkflowResponseAdjInventoryTok: Label 'QLTY-R-ADJ-1', Locked = true;
        QMWorkflowResponseChangeItemTrackingTok: Label 'QLTY-R-ITEMTRACK-1', Locked = true;
        QMWorkflowResponseCreateTransferTok: Label 'QLTY-R-TRANSFER-1', Locked = true;
        QMWorkflowResponseCreatePurchaseReturnTok: Label 'QLTY-R-PURRETURN-1', Locked = true;
        QMWorkflowEventDescriptionAQualityInspectionTestHasChangedLbl: Label 'A Quality Inspection Test has changed', Locked = true;
        QMWorkflowEventDescriptionAQualityInspectionTestHasBeenCreatedLbl: Label 'A Quality Inspection Test is created', Locked = true;
        QMWorkflowEventDescriptionAQualityInspectionTestHasBeenFinishedLbl: Label 'A Quality Inspection Test is finished', Locked = true;
        QMWorkflowEventDescriptionAQualityInspectionTestHasBeenReopenedLbl: Label 'A Quality Inspection Test is reopened', Locked = true;
        QMWorkflowResponseDescriptionCreateAQualityInspectionTestLbl: Label 'Create a Quality Inspection Test', Locked = true;
        QMWorkflowResponseDescriptionFinishTheQualityInspectionTestLbl: Label 'Finish the Quality Inspection Test', Locked = true;
        QMWorkflowResponseDescriptionReopenTheQualityInspectionTestLbl: Label 'Reopen the Quality Inspection Test', Locked = true;
        QMWorkflowResponseDescriptionCreateReTestLbl: Label 'Create Retest', Locked = true;
        QMWorkflowResponseDescriptionBlockLotLbl: Label 'Block Lot in the Test', Locked = true;
        QMWorkflowResponseDescriptionBlockSerialLbl: Label 'Block Serial in the Test', Locked = true;
        QMWorkflowResponseDescriptionBlockPackageLbl: Label 'Block Package in the Test', Locked = true;
        QMWorkflowResponseDescriptionUnBlockLotLbl: Label 'Un-Block Lot in the Test', Locked = true;
        QMWorkflowResponseDescriptionUnBlockSerialLbl: Label 'Un-Block Serial in the Test', Locked = true;
        QMWorkflowResponseDescriptionUnBlockPackageLbl: Label 'Un-Block Package in the Test', Locked = true;
        QMWorkflowResponseDescriptionMoveInventoryLbl: Label 'Move Inventory from Test', Locked = true;
        QMWorkflowResponseDescriptionCreateInternalPutAwayLbl: Label 'Create an Internal Put-away', Locked = true;
        QMWorkflowResponseDescriptionSetDatabaseValueLbl: Label 'Set Database Value', Locked = true;
        QMWorkflowResponseDescriptionCreateNegativeAdjustmentLbl: Label 'Create a Negative Adjustment', Locked = true;
        QMWorkflowResponseDescriptionChangeItemTrackingInformationLbl: Label 'Change Item Tracking Information', Locked = true;
        QMWorkflowResponseDescriptionCreateTransferOrderLbl: Label 'Create Transfer Order', Locked = true;
        QMWorkflowResponseDescriptionCreatePurchaseReturnOrderLbl: Label 'Create Purchase Return', Locked = true;
        QMWorkflowDescriptionOptionalSuffixLbl: Label ' - Foundation', Locked = true;

    /// <summary>
    /// IsWorkflowIntegrationEnabledAndSufficientPermission returns true if workflow integration is enabled and the current user has sufficient permission to use it.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsWorkflowIntegrationEnabledAndSufficientPermission(): Boolean
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit(false);

        exit(QltyManagementSetup."Workflow Integration Enabled");
    end;

    /// <summary>
    /// Returns the token for a workflow response to create a test.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseCreateTest(): Text
    begin
        exit(QMWorkflowResponseCreateTestTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to finish a test
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseFinishTest(): Text
    begin
        exit(QMWorkflowResponseFinishTestTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to re-open a test
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseReopenTest(): Text
    begin
        exit(QMWorkflowResponseReopenTestTok);
    end;

    procedure GetWorkflowResponseCreateRetest(): Text
    begin
        exit(QMWorkflowResponseCreateRetestTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a lot
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseBlockLot(): Text
    begin
        exit(QMWorkflowResponseBlockLotTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a serial
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseBlockSerial(): Text
    begin
        exit(QMWorkflowResponseBlockSerialTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to block a package
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseBlockPackage(): Text
    begin
        exit(QMWorkflowResponseBlockPackageTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to unblock a lot
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseUnBlockLot(): Text
    begin
        exit(QMWorkflowResponseUnBlockLotTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to unblock a serial
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseUnBlockSerial(): Text
    begin
        exit(QMWorkflowResponseUnBlockSerialTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to unblock a package
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseUnBlockPackage(): Text
    begin
        exit(QMWorkflowResponseUnBlockPackageTok);
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
    procedure GetWorkflowResponseQuarantineLicensePlate(): Text
    begin
        exit(QMWorkflowResponseQuarantineLicensePlateTok);
    end;

    /// <summary>
    /// Returns the token for a workflow response to un-quarantine a license plate.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkflowResponseUnQuarantineLicensePlate(): Text
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
    procedure GetWorkflowResponseSetDatabaseValue(): Text
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
    procedure GetWorkflowResponseChangeItemTracking(): Text
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
    procedure GetQualityInspectionPrefix(): Text
    begin
        exit(QltyPrefixTok);
    end;

    /// <summary>
    /// The token for the event when a test has been created.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestCreatedEvent(): Code[128]
    begin
        exit(TestCreatedEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been changed.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestHasChangedEvent(): Code[128]
    begin
        exit(TestHasChangedEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been finished.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestFinishedEvent(): Code[128]
    begin
        exit(TestFinishesEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been re-opened.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestReopensEvent(): Code[128]
    begin
        exit(TestReopensEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been rejected in an approval.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestRejectEventTok(): Code[128]
    begin
        exit(QITestRejectWorkflowEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been approved in an approval system.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestApproveEventTok(): Code[128]
    begin
        exit(QITestApproveWorkflowEventTok);
    end;

    /// <summary>
    /// The token for the event when a test has been delegated in an approval.
    /// </summary>
    /// <returns>Return value of type Code[128].</returns>
    procedure GetTestDelegateEventTok(): Code[128]
    begin
        exit(QITestDelegateWorkflowEventTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowTableRelationsToLibrary()
    begin
        if not IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        AddEmployeeUserRelationships();
    end;

    local procedure AddEmployeeUserRelationships()
    var
        User: Record User;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(Database::"User", User.FieldNo("User Name"), Database::"Qlty. Inspection Test Header", QltyInspectionTestHeader.FieldNo("Assigned User ID"));
        WorkflowSetup.InsertTableRelation(Database::"Qlty. Inspection Test Header", QltyInspectionTestHeader.FieldNo("No."), database::"Approval Entry", ApprovalEntry.FieldNo("Document No."));
        WorkflowSetup.InsertTableRelation(Database::"Qlty. Inspection Test Line", QltyInspectionTestLine.FieldNo("Test No."), database::"Approval Entry", ApprovalEntry.FieldNo("Document No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowEventsToLibrary()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        OptionalSuffix: Text;
    begin
        if not IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        WorkflowEvent.SetFilter("Function Name", QltyPrefixTok + '*');
        WorkflowEvent.DeleteAll(false);

        WorkflowEvent.Reset();
        WorkflowEvent.SetRange(Description, QMWorkflowEventDescriptionAQualityInspectionTestHasChangedLbl);
        if not WorkflowEvent.IsEmpty() then
            OptionalSuffix := QMWorkflowDescriptionOptionalSuffixLbl;

        WorkflowEventHandling.AddEventToLibrary(GetTestHasChangedEvent(), Database::"Qlty. Inspection Test Header", QMWorkflowEventDescriptionAQualityInspectionTestHasChangedLbl + OptionalSuffix, 0, true);
        WorkflowEventHandling.AddEventToLibrary(GetTestCreatedEvent(), Database::"Qlty. Inspection Test Header", QMWorkflowEventDescriptionAQualityInspectionTestHasBeenCreatedLbl + OptionalSuffix, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetTestFinishedEvent(), Database::"Qlty. Inspection Test Header", QMWorkflowEventDescriptionAQualityInspectionTestHasBeenFinishedLbl + OptionalSuffix, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetTestReopensEvent(), Database::"Qlty. Inspection Test Header", QMWorkflowEventDescriptionAQualityInspectionTestHasBeenReopenedLbl + OptionalSuffix, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', true, true)]
    local procedure HandleOnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if not IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        case EventFunctionName of
            'RUNWORKFLOWONAPPROVEAPPROVALREQUEST',
            'RUNWORKFLOWONREJECTAPPROVALREQUEST',
            'RUNWORKFLOWONDELEGATEAPPROVALREQUEST',
            QITestRejectWorkflowEventTok,
            QITestDelegateWorkflowEventTok,
            QITestApproveWorkflowEventTok:
                begin
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetTestFinishedEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetTestReopensEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetTestCreatedEvent());
                    WorkflowEventHandling.AddEventPredecessor(EventFunctionName, GetTestHasChangedEvent());
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
        if not IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        FunctionName := ResponseFunctionName;

        QualityEventIds.Add(GetTestCreatedEvent());
        QualityEventIds.Add(GetTestFinishedEvent());
        QualityEventIds.Add(GetTestHasChangedEvent());
        QualityEventIds.Add(GetTestReopensEvent());

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
        if not IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        WorkflowResponse.SetFilter("Function Name", QltyPrefixTok + '*');
        if WorkflowResponse.FindSet() then
            repeat
                WorkflowResponse.MakeDependentOnAllEvents();
            until WorkflowResponse.Next() = 0;

        WorkflowResponse.DeleteAll(false);
        WorkflowResponse.Reset();
        WorkflowResponse.SetRange(Description, QMWorkflowResponseDescriptionCreateAQualityInspectionTestLbl);
        if not WorkflowResponse.IsEmpty() then
            OptionalSuffix := QMWorkflowDescriptionOptionalSuffixLbl;

        QualityEventIds.Add(GetTestCreatedEvent());
        QualityEventIds.Add(GetTestFinishedEvent());
        QualityEventIds.Add(GetTestHasChangedEvent());
        QualityEventIds.Add(GetTestReopensEvent());

        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreateTest(), 1, 128), 0, QMWorkflowResponseDescriptionCreateAQualityInspectionTestLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreateTest(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreateTest(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseFinishTest(), 1, 128), 0, QMWorkflowResponseDescriptionFinishTheQualityInspectionTestLbl + OptionalSuffix, CopyStr(GetWorkflowResponseFinishTest(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseFinishTest(), 1, 128));

        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseReopenTest(), 1, 128), 0, QMWorkflowResponseDescriptionReopenTheQualityInspectionTestLbl + OptionalSuffix, CopyStr(GetWorkflowResponseReopenTest(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseReopenTest(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseCreateRetest(), 1, 128), 0, QMWorkflowResponseDescriptionCreateReTestLbl + OptionalSuffix, CopyStr(GetWorkflowResponseCreateRetest(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseCreateRetest(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseBlockLot(), 1, 128), 0, QMWorkflowResponseDescriptionBlockLotLbl + OptionalSuffix, CopyStr(GetWorkflowResponseBlockLot(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseBlockLot(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseBlockSerial(), 1, 128), 0, QMWorkflowResponseDescriptionBlockSerialLbl + OptionalSuffix, CopyStr(GetWorkflowResponseBlockSerial(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseBlockSerial(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnBlockLot(), 1, 128), 0, QMWorkflowResponseDescriptionUnBlockLotLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnBlockLot(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnBlockLot(), 1, 128));
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnBlockSerial(), 1, 128), 0, QMWorkflowResponseDescriptionUnBlockSerialLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnBlockSerial(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnBlockSerial(), 1, 128));

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
        WorkflowResponseHandling.AddResponseToLibrary(CopyStr(GetWorkflowResponseUnBlockPackage(), 1, 128), 0, QMWorkflowResponseDescriptionUnBlockPackageLbl + OptionalSuffix, CopyStr(GetWorkflowResponseUnBlockPackage(), 1, 20));
        QualityResponseIdsToAdd.Add(CopyStr(GetWorkflowResponseUnBlockPackage(), 1, 128));
        foreach QualityResponse in QualityResponseIdsToAdd do
            foreach QualityEvent in QualityEventIds do
                WorkflowResponseHandling.AddResponsePredecessor(CopyStr(QualityResponse, 1, 128), CopyStr(QualityEvent, 1, 128));
    end;
}
