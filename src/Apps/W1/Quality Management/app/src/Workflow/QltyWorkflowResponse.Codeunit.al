// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;
using System.Automation;
using System.Reflection;

/// <summary>
/// This codeunit deals with the handling of workflow responses
/// </summary>
codeunit 20424 "Qlty. Workflow Response"
{
    Permissions = tabledata "Workflow Step Instance" = r;

    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        DocumentTypeLbl: Label 'Move';
        UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr: Label 'Unable to change location of the inventory from test %1 from location %2 to %3 because %2 is directed pick and put-away, you can only change bins with the same location.', Comment = '%1=the test, %2=from location, %3=to location';

    /// <summary>
    /// Note: The method signature for OnExecuteWorkflowResponse has changed at some point between BC 16 and BC 18.
    /// If you get "Operation not supported" then the event method changed.
    /// </summary>
    /// <param name="ResponseExecuted"></param>
    /// <param name="Variant"></param>
    /// <param name="xVariant"></param>
    /// <param name="ResponseWorkflowStepInstance"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', true, true)]
    local procedure HandleOnExecuteWorkflowResponse(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowResponse: Record "Workflow Response";
        ForOriginalWorkflowStepArgument: Record "Workflow Step Argument";
        ApprovalEntry: Record "Approval Entry";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Test2QualityOrder: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        OriginalWorkflowStep: Record "Workflow Step";
        Location: Record Location;
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        ReactionTrkngQltyDispChangeTracking: Codeunit "Qlty. Disp. Change Tracking";
        QltyDispNegAdjustInv: Codeunit "Qlty. Disp. Neg. Adjust Inv.";
        QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
        QltyDispWarehousePutAway: Codeunit "Qlty. Disp. Warehouse Put-away";
        QltyDispTransfer: Codeunit "Qlty. Disp. Transfer";
        QltyDispPurchaseReturn: Codeunit "Qlty. Disp. Purchase Return";
        QltyDispMoveWorksheet: Codeunit "Qlty. Disp. Move Worksheet";
        QltyDispInternalMove: Codeunit "Qlty. Disp. Internal Move";
        QltyDispMoveWhseReclass: Codeunit "Qlty. Disp. Move Whse.Reclass.";
        QltyDispMoveItemReclass: Codeunit "Qlty. Disp. Move Item Reclass.";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        PrimaryRecordRefInWorkflow: RecordRef;
        Peek: Text;
        ValueToSet: Text;
        TableFilter: Text;
        Handled: Boolean;
    begin
        if not QltyWorkflowSetup.IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        Peek := ResponseWorkflowStepInstance."Function Name";
        if not Peek.StartsWith(QltyWorkflowSetup.GetQualityInspectionPrefix()) then
            exit;

        if not DataTypeManagement.GetRecordRef(Variant, PrimaryRecordRefInWorkflow) then;

        if PrimaryRecordRefInWorkflow.Number() = Database::"Approval Entry" then begin
            PrimaryRecordRefInWorkflow.SetTable(ApprovalEntry);
            PrimaryRecordRefInWorkflow := ApprovalEntry."Record ID to Approve".GetRecord();
        end;

        case PrimaryRecordRefInWorkflow.Number() of
            Database::"Qlty. Inspection Test Header":
                begin
                    PrimaryRecordRefInWorkflow.SetTable(Test2QualityOrder);
                    Test2QualityOrder.SetRecFilter();
                    if Test2QualityOrder.Count() <> 1 then begin
                        QltyInspectionTestHeader.SetFilter("No.", Test2QualityOrder.GetFilter("No."));
                        QltyInspectionTestHeader.SetFilter("Retest No.", Test2QualityOrder.GetFilter("Retest No."));
                    end else
                        QltyInspectionTestHeader.Copy(Test2QualityOrder);

                    QltyInspectionTestHeader.FindFirst();
                    QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
                    QltyInspectionTestLine.SetRange("Retest No.", QltyInspectionTestHeader."Retest No.");
                    if QltyInspectionTestLine.FindLast() then;
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    PrimaryRecordRefInWorkflow.SetTable(QltyInspectionTestLine);
                    QltyInspectionTestLine.SetRecFilter();
                    QltyInspectionTestLine.FindFirst();
                    if QltyInspectionTestHeader.Get(QltyInspectionTestLine."Test No.", QltyInspectionTestLine."Retest No.") then
                        QltyInspectionTestHeader.SetRecFilter();
                end;
        end;

        OriginalWorkflowStep.SetRange("Workflow Code", ResponseWorkflowStepInstance."Workflow Code");
        OriginalWorkflowStep.SetRange(ID, ResponseWorkflowStepInstance."Workflow Step ID");
        OriginalWorkflowStep.SetRange("Function Name", ResponseWorkflowStepInstance."Function Name");
        OriginalWorkflowStep.SetRange("Sequence No.", ResponseWorkflowStepInstance."Sequence No.");
        OriginalWorkflowStep.SetRange("Type", ResponseWorkflowStepInstance."Type");
        if OriginalWorkflowStep.FindFirst() then
            if ForOriginalWorkflowStepArgument.Get(OriginalWorkflowStep.Argument) then;

        OnWorkflowHandleOnExecuteWorkflowResponseAfterFindRelatedRecord(ResponseExecuted, Variant, xVariant, ResponseWorkflowStepInstance, PrimaryRecordRefInWorkflow, Handled);
        if Handled then
            exit;

        if PrimaryRecordRefInWorkflow.Number() = Database::"Qlty. Inspection Test Header" then
            ClearTestStatusFilterIfRequired(ResponseWorkflowStepInstance, PrimaryRecordRefInWorkflow);

        if WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name") then
            case WorkflowResponse."Function Name" of
                QltyWorkflowSetup.GetWorkflowResponseCreateTest():
                    begin
                        if QltyInspectionTestCreate.CreateTest(PrimaryRecordRefInWorkflow, GuiAllowed()) then
                            QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

                        ResponseExecuted := true;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseFinishTest():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyInspectionTestHeader.FinishTest();
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseReopenTest():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyInspectionTestHeader.ReopenTest();
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseCreateRetest():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyInspectionTestHeader.CreateReTest();
                            ResponseExecuted := true;
                        end;
                    end;

                QltyWorkflowSetup.GetWorkflowResponseBlockLot():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetLotBlockState(QltyInspectionTestHeader, true);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseBlockSerial():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetSerialBlockState(QltyInspectionTestHeader, true);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseBlockPackage():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetPackageBlockState(QltyInspectionTestHeader, true);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseUnBlockLot():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetLotBlockState(QltyInspectionTestHeader, false);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseUnBlockSerial():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetSerialBlockState(QltyInspectionTestHeader, false);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseUnBlockPackage():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            QltyItemTracking.SetPackageBlockState(QltyInspectionTestHeader, false);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseMoveInventory():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

                            if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
                                if GuiAllowed() then
                                    QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
                                ResponseExecuted := true;
                                exit;
                            end;

                            repeat
                                Clear(Location);
                                if TempQuantityToActQltyDispositionBuffer."Location Filter" <> '' then
                                    Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

                                if Location."Directed Put-away and Pick" then begin
                                    if (TempQuantityToActQltyDispositionBuffer."New Location Code" <> '') and (TempQuantityToActQltyDispositionBuffer."New Location Code" <> TempQuantityToActQltyDispositionBuffer."Location Filter") then
                                        Error(UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr, QltyInspectionTestHeader."No.", TempQuantityToActQltyDispositionBuffer."Location Filter", TempQuantityToActQltyDispositionBuffer."New Location Code");
                                    if GetStepConfigurationValueAsBoolean(ForOriginalWorkflowStepArgument, GetWellKnownUseMoveSheet()) then
                                        QltyDispMoveWorksheet.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer)
                                    else
                                        QltyDispMoveWhseReclass.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer)
                                end else
                                    if GetStepConfigurationValueAsBoolean(ForOriginalWorkflowStepArgument, GetWellKnownUseMoveSheet()) then
                                        QltyDispInternalMove.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer)
                                    else
                                        QltyDispMoveItemReclass.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer);
                            until TempQuantityToActQltyDispositionBuffer.Next() = 0;
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseSetTestValue():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            ValueToSet := GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyValueExpression());
                            if ValueToSet.Contains('[') or ValueToSet.Contains('{') then
                                ValueToSet := QltyExpressionMgmt.EvaluateTextExpression(ValueToSet, QltyInspectionTestHeader, QltyInspectionTestLine, true);

                            QltyInspectionTestHeader.SetTestValue(GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyField()), ValueToSet);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            ValueToSet := GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyValueExpression());
                            if ValueToSet.Contains('[') or ValueToSet.Contains('{') then
                                ValueToSet := QltyExpressionMgmt.EvaluateTextExpression(ValueToSet, QltyInspectionTestHeader, QltyInspectionTestLine, true);

                            TableFilter := GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyDatabaseTableFilter());
                            if TableFilter.Contains('[') or TableFilter.Contains('{') then
                                TableFilter := QltyExpressionMgmt.EvaluateTextExpression(TableFilter, QltyInspectionTestHeader, QltyInspectionTestLine, true);

                            QltyMiscHelpers.SetTableValue(GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyDatabaseTable()), TableFilter, GetStepConfigurationValue(ForOriginalWorkflowStepArgument, GetWellKnownKeyField()), ValueToSet, true);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseInternalPutAway():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            if GetStepConfigurationValueAsBoolean(ForOriginalWorkflowStepArgument, GetWellKnownCreatePutAway()) then
                                QltyDispWarehousePutAway.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer)
                            else
                                QltyDispInternalPutAway.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            QltyDispNegAdjustInv.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);

                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            ReactionTrkngQltyDispChangeTracking.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseCreateTransfer():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            QltyDispTransfer.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);
                            ResponseExecuted := true;
                        end;
                    end;
                QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn():
                    begin
                        EnsureTestHeaderIsLoaded(QltyInspectionTestHeader, PrimaryRecordRefInWorkflow);

                        if QltyInspectionTestHeader."No." <> '' then begin
                            InitDispositionBufferFromWorkflowStepArgument(TempInstructionQltyDispositionBuffer, QltyInspectionTestHeader, QltyInspectionTestLine, ForOriginalWorkflowStepArgument);

                            QltyDispPurchaseReturn.PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);
                            ResponseExecuted := true;
                        end;
                    end;
            end;
    end;

    local procedure EnsureTestHeaderIsLoaded(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; PrimaryRecordRefInWorkflow: RecordRef)
    begin
        if QltyInspectionTestHeader."No." = '' then
            QltyInspectionTestHeader.GetMostRecentTestFor(PrimaryRecordRefInWorkflow);
    end;

    /// <summary>
    /// Gets the step configuration value as a decimal for the given key.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <returns></returns>
    procedure GetStepConfigurationValueAsDecimal(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultDecimal: Decimal
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        if Evaluate(ResultDecimal, StepConfigurationValue) then;
    end;

    /// <summary>
    /// Gets the step configuration value as a boolean for the given key.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <returns></returns>
    procedure GetStepConfigurationValueAsBoolean(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultBoolean: Boolean
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        if Evaluate(ResultBoolean, StepConfigurationValue) then;
    end;

    /// <summary>
    /// Gets the step configuration value as Code[10] for the given key.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <returns></returns>
    procedure GetStepConfigurationValueAsCode10(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultCode: Code[10]
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        ResultCode := CopyStr(StepConfigurationValue, 1, MaxStrLen(ResultCode));
    end;

    /// <summary>
    /// Gets the step configuration value as Code[20] for the given key.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <returns></returns>
    procedure GetStepConfigurationValueAsCode20(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultCode: Code[20]
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        ResultCode := CopyStr(StepConfigurationValue, 1, MaxStrLen(ResultCode));
    end;

    /// <summary>
    /// Returns the configuration value for a given key.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <returns></returns>
    procedure GetStepConfigurationValue(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text): Text
    var
        CustomQltyExpressConfigValue: Record "Qlty. Express Config. Value";
    begin
        if not CustomQltyExpressConfigValue.ReadPermission() then
            exit;

        CustomQltyExpressConfigValue.SetRange("Table ID", Database::"Workflow Step Argument");
        CustomQltyExpressConfigValue.SetRange("Record ID", WorkflowStepArgument.RecordId());
        CustomQltyExpressConfigValue.SetRange("Template Key", CopyStr(CurrentKey, 1, MaxStrLen(CustomQltyExpressConfigValue."Template Key")));
        if CustomQltyExpressConfigValue.FindFirst() then;
        exit(CustomQltyExpressConfigValue.Value);
    end;

    /// <summary>
    /// Sets a decimal step argument configuration value.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <param name="Value"></param>
    procedure SetStepConfigurationValueAsDecimal(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Decimal)
    begin
        SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, Format(Value, 0, 9));
    end;

    /// <summary>
    /// Sets a boolean step argument configuration value.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <param name="Value"></param>
    procedure SetStepConfigurationValueAsBoolean(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Boolean)
    begin
        SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, Format(Value, 0, 9));
    end;

    /// <summary>
    /// Sets a step argument configuration value.
    /// </summary>
    /// <param name="WorkflowStepArgument"></param>
    /// <param name="CurrentKey"></param>
    /// <param name="Value"></param>
    procedure SetStepConfigurationValue(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Text)
    var
        CustomQltyExpressConfigValue: Record "Qlty. Express Config. Value";
    begin
        if not CustomQltyExpressConfigValue.ReadPermission() then
            exit;

        CustomQltyExpressConfigValue.SetRange("Table ID", Database::"Workflow Step Argument");
        CustomQltyExpressConfigValue.SetRange("Record ID", WorkflowStepArgument.RecordId());
        CustomQltyExpressConfigValue.SetRange("Template Key", CopyStr(CurrentKey, 1, MaxStrLen(CustomQltyExpressConfigValue."Template Key")));
        if not CustomQltyExpressConfigValue.FindFirst() then begin
            CustomQltyExpressConfigValue."Table ID" := Database::"Workflow Step Argument";
            CustomQltyExpressConfigValue."Record ID" := WorkflowStepArgument.RecordId();
            CustomQltyExpressConfigValue."Template Key" := CopyStr(CurrentKey, 1, MaxStrLen(CustomQltyExpressConfigValue."Template Key"));
            CustomQltyExpressConfigValue.Insert();
        end;
        CustomQltyExpressConfigValue.Value := CopyStr(Value, 1, MaxStrLen(CustomQltyExpressConfigValue.Value));
        CustomQltyExpressConfigValue.Modify();
    end;
    /// <summary>
    /// Gets the step configuration value as a Code[50].
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <returns>Value as Code[50]</returns>
    procedure GetStepConfigurationValueAsCode50(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultCode: Code[50]
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        ResultCode := CopyStr(StepConfigurationValue, 1, MaxStrLen(ResultCode));
    end;

    /// <summary>
    /// Gets the step configuration value as a date.
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <returns>Value as Date</returns>
    procedure GetStepConfigurationValueAsDate(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) ResultDate: Date
    var
        StepConfigurationValue: Text;
    begin
        StepConfigurationValue := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        Evaluate(ResultDate, StepConfigurationValue);
    end;

    /// <summary>
    /// Sets the step configuration value as a date compatible text value.
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <returns>Value as Date</returns>
    procedure SetStepConfigurationValueAsDate(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; DateValue: Date)
    begin
        SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, Format(DateValue, 0, 9));
    end;

    /// <summary>
    /// Returns the key for a location
    /// Typically used for target location/destination location/new location
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyLocation(): Text
    begin
        exit('LOCATION');
    end;

    /// <summary>
    /// Returns the key for a bin
    /// Typically used for target bin/destination bin/new bin.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyBin(): Text
    begin
        exit('BIN');
    end;

    /// <summary>
    /// Returns the key for a quantity.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyQuantity(): Text
    begin
        exit('QUANTITY');
    end;

    /// <summary>
    /// Returns the key for posting immediately or not.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownPostImmediately(): Text
    begin
        exit('POSTAFTER');
    end;

    /// <summary>
    /// Returns the key for a flag to move the entire lot/serial
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownMoveAll(): Text
    begin
        exit('MOVEALL');
    end;

    /// <summary>
    /// Returns the key for a source location filter
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownSourceLocationFilter(): Text
    begin
        exit('SRCLOCFILTER');
    end;

    /// <summary>
    /// Returns the key for a source bin filter
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownSourceBinFilter(): Text
    begin
        exit('SRCBINFILTER');
    end;

    /// <summary>
    /// Returns the key for a put-away choice.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownCreatePutAway(): Text
    begin
        exit('PUTAWAY');
    end;

    /// <summary>
    /// Returns the key for a field
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyField(): Text
    begin
        exit('FIELD');
    end;

    /// <summary>
    /// Returns the key for a value expression
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyValueExpression(): Text
    begin
        exit('VALUEEXPR');
    end;

    /// <summary>
    /// Returns the key for a database table 
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyDatabaseTable(): Text
    begin
        exit('DBTBLNAME');
    end;

    /// <summary>
    /// Returns the key for a database table filter.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownKeyDatabaseTableFilter(): Text
    begin
        exit('DBTBLFLTREXPR');
    end;

    /// <summary>
    /// Returns the key value for adjustment posting behavior.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownAdjPostingBehavior(): Text
    begin
        exit('ADJPOSTBEHAVIOR');
    end;

    /// <summary>
    /// Returns the key value for whether or not to use the movement worksheet
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownUseMoveSheet(): Text
    begin
        exit('USEMOVESHEET');
    end;

    /// <summary>
    /// Returns the key value for new lot no.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownNewLotNo(): Text
    begin
        exit('NEWLOTNO');
    end;

    /// <summary>
    /// Returns the key value for new serial no.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownNewSerialNo(): Text
    begin
        exit('NEWSERIALNO');
    end;

    /// <summary>
    /// Returns the key value for new package no.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownNewPackageNo(): Text
    begin
        exit('NEWPACKAGENO');
    end;

    /// <summary>
    /// Returns the key value for new expiration date.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownNewExpDate(): Text
    begin
        exit('NEWEXPDATE');
    end;

    /// <summary>
    /// Returns the key value for reason code.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownReasonCode(): Text
    begin
        exit('REASONCODE');
    end;

    /// <summary>
    /// Returns the key value for direct transfer.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownDirectTransfer(): Text
    begin
        exit('DIRECTTRANSFER');
    end;

    /// <summary>
    /// Returns the key value for the in-transit code.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownInTransit(): Text
    begin
        exit('INTRANSIT');
    end;
    /// <summary>
    /// Returns the key value for the external doc. no.
    /// </summary>
    /// <returns></returns>
    procedure GetWellKnownExternalDocNo(): Text
    begin
        exit('EXTERNALDOCNO');
    end;

    /// <summary>
    /// Gets the step configuration value as an Qlty. Move Behavior Enum.
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <returns>Qlty. Move Behavior Enum</returns>
    procedure GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"
    var
        Value: Text;
    begin
        Value := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        case Value of
            'SPECIFIC', '', 'false':
                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
            'TRACKED':
                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
            'SAMPLETOTAL':
                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
            'SAMPLEREJECT':
                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
            'SAMPLEPASS':
                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
            'true':
                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
        end;
    end;

    procedure SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior")
    begin
        case QltyQuantityBehavior of
            QltyQuantityBehavior::"Specific Quantity":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'SPECIFIC');
            QltyQuantityBehavior::"Item Tracked Quantity":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'TRACKED');
            QltyQuantityBehavior::"Sample Quantity":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'SAMPLETOTAL');
            QltyQuantityBehavior::"Failed Quantity":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'SAMPLEREJECT');
            QltyQuantityBehavior::"Passed Quantity":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'SAMPLEPASS');
        end;
    end;

    /// <summary>
    ///Gets the step configuration value as an Qlty. Item Adj. Post Behavior Enum.
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <returns>Qlty. Item Adj. Post Behavior Enum</returns>
    procedure GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text) QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior"
    var
        Value: Text;
    begin
        Value := GetStepConfigurationValue(WorkflowStepArgument, CurrentKey);
        case Value of
            'EntryOnly':
                QltyItemAdjPostBehavior := QltyItemAdjPostBehavior::"Prepare only";
            'Post':
                QltyItemAdjPostBehavior := QltyItemAdjPostBehavior::Post;
        end;
    end;

    /// <summary>
    /// Uses an Qlty. Item Adj. Post Behavior Enum to set a Workflow Step Argument key/value.
    /// </summary>
    /// <param name="WorkflowStepArgument">Workflow Step Argument</param>
    /// <param name="CurrentKey">Configuration Key</param>
    /// <param name="CurrentEnum">Qlty. Item Adj. Post Behavior Enum</param>
    procedure SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; CurrentEnum: Enum "Qlty. Item Adj. Post Behavior")
    begin
        case CurrentEnum of
            CurrentEnum::"Prepare only":
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'EntryOnly');
            CurrentEnum::Post:
                SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, 'Post');
        end;
    end;

    local procedure InitDispositionBufferFromWorkflowStepArgument(var TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var WorkflowStepArgument: Record "Workflow Step Argument")
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        Temp: Text;
    begin
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := GetStepConfigurationValueAsDecimal(WorkflowStepArgument, GetWellKnownKeyQuantity());

        Temp := GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownNewLotNo());
        if Temp.Contains('[') or Temp.Contains('{') then
            Temp := QltyExpressionMgmt.EvaluateTextExpression(Temp, QltyInspectionTestHeader, QltyInspectionTestLine, true);
        TempQltyDispositionBuffer."New Lot No." := CopyStr(Temp, 1, MaxStrLen(TempQltyDispositionBuffer."New Lot No."));

        Temp := GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownNewSerialNo());
        if Temp.Contains('[') or Temp.Contains('{') then
            Temp := QltyExpressionMgmt.EvaluateTextExpression(Temp, QltyInspectionTestHeader, QltyInspectionTestLine, true);
        TempQltyDispositionBuffer."New Serial No." := CopyStr(Temp, 1, MaxStrLen(TempQltyDispositionBuffer."New Serial No."));

        Temp := GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownNewPackageNo());
        if Temp.Contains('[') or Temp.Contains('{') then
            Temp := QltyExpressionMgmt.EvaluateTextExpression(Temp, QltyInspectionTestHeader, QltyInspectionTestLine, true);
        TempQltyDispositionBuffer."New Package No." := CopyStr(Temp, 1, MaxStrLen(TempQltyDispositionBuffer."New Package No."));

        TempQltyDispositionBuffer."New Expiration Date" := GetStepConfigurationValueAsDate(WorkflowStepArgument, GetWellKnownNewExpDate());

        TempQltyDispositionBuffer."Quantity Behavior" := GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, GetWellKnownMoveAll());

        TempQltyDispositionBuffer."Qty. To Handle (Base)" := GetStepConfigurationValueAsDecimal(WorkflowStepArgument, GetWellKnownKeyQuantity());

        TempQltyDispositionBuffer."Location Filter" := CopyStr(GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownSourceLocationFilter()), 1, MaxStrLen(TempQltyDispositionBuffer."Location Filter"));

        TempQltyDispositionBuffer."Bin Filter" := CopyStr(GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownSourceBinFilter()), 1, MaxStrLen(TempQltyDispositionBuffer."Bin Filter"));

        TempQltyDispositionBuffer."New Location Code" := GetStepConfigurationValueAsCode10(WorkflowStepArgument, GetWellKnownKeyLocation());

        TempQltyDispositionBuffer."New Bin Code" := GetStepConfigurationValueAsCode20(WorkflowStepArgument, GetWellKnownKeyBin());

        TempQltyDispositionBuffer."In-Transit Location Code" := GetStepConfigurationValueAsCode10(WorkflowStepArgument, GetWellKnownInTransit());

        if GetStepConfigurationValueAsBoolean(WorkflowStepArgument, GetWellKnownPostImmediately()) then
            TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;

        TempQltyDispositionBuffer."Reason Code" := GetStepConfigurationValueAsCode10(WorkflowStepArgument, GetWellKnownReasonCode());

        Temp := GetStepConfigurationValue(WorkflowStepArgument, GetWellKnownExternalDocNo());
        if Temp.Contains('[') or Temp.Contains('{') then
            Temp := QltyExpressionMgmt.EvaluateTextExpression(Temp, QltyInspectionTestHeader, QltyInspectionTestLine, true);
        TempQltyDispositionBuffer."External Document No." := CopyStr(Temp, 1, MaxStrLen(TempQltyDispositionBuffer."External Document No."));
    end;

    local procedure ClearTestStatusFilterIfRequired(ResponseWorkflowStepInstance: Record "Workflow Step Instance"; var RecordRef: RecordRef)
    var
        WorkflowStep: Record "Workflow Step";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyWorkflowSetup2: Codeunit "Qlty. Workflow Setup";
        FieldRef: FieldRef;
        FilterGroupIterator: Integer;
    begin
        FieldRef := RecordRef.Field(QltyInspectionTestHeader.FieldNo(Status));
        if FieldRef.GetFilter() = '' then
            exit;

        if ResponseWorkflowStepInstance."Previous Workflow Step ID" = 0 then
            exit;
        WorkflowStep.Get(ResponseWorkflowStepInstance."Workflow Code", ResponseWorkflowStepInstance."Previous Workflow Step ID");
        if not (WorkflowStep."Previous Workflow Step ID" = 0) then
            repeat
                WorkflowStep.Get(ResponseWorkflowStepInstance."Workflow Code", WorkflowStep."Previous Workflow Step ID");
            until WorkflowStep."Previous Workflow Step ID" = 0;
        if not ((WorkflowStep."Function Name" = QltyWorkflowSetup2.GetTestFinishedEvent()) or (WorkflowStep."Function Name" = QltyWorkflowSetup2.GetTestReopensEvent())) then
            exit;

        FilterGroupIterator := 4;
        repeat
            RecordRef.FilterGroup(FilterGroupIterator);

            FieldRef := RecordRef.Field(QltyInspectionTestHeader.FieldNo(Status));
            FieldRef.SetRange();

            FilterGroupIterator -= 1;
        until FilterGroupIterator < 0;
    end;

    /// <summary>
    /// OnWorkflowHandleOnExecuteWorkflowResponseAfterFindRelatedRecord occurs after the system has found the related record for the workflow step.
    /// </summary>
    /// <param name="ResponseExecuted">VAR Boolean.</param>
    /// <param name="pVariant">VAR Variant.</param>
    /// <param name="pxVariant">Variant.</param>
    /// <param name="ResponseWorkflowStepInstance">Record "Workflow Step Instance".</param>
    /// <param name="TargetRecordRef">VAR recordref.</param>
    /// <param name="Handled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnWorkflowHandleOnExecuteWorkflowResponseAfterFindRelatedRecord(var ResponseExecuted: Boolean; var pVariant: Variant; pxVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance"; var TargetRecordRef: recordref; var Handled: Boolean)
    begin
    end;
}
