// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;

codeunit 5361 "Int. Rec. Couple Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        CoupleRecord(
            IntegrationTableMappingContext, LocalRecordRefContext, IntegrationRecordRefContext,
            SynchActionContext, JobIdContext, IntegrationTableConnectionTypeContext);
        if not IsNullGuid(JobIdContext) then
            Commit();
    end;

    var
        IntegrationTableMappingContext: Record "Integration Table Mapping";
        LocalRecordRefContext: RecordRef;
        IntegrationRecordRefContext: RecordRef;
        LocalRecordModifiedContext: Boolean;
        IntegrationRecordModifiedContext: Boolean;
        IntegrationTableConnectionTypeContext: TableConnectionType;
        JobIdContext: Guid;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        SynchActionContext: Option;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';
        CouplingFailedErr: Label 'Coupling %1 failed because of the following error: %2.', Comment = '%1 = Table Caption, %2 = Error from modify process.';
        UnexpectedRecordStateTxt: Label 'Coupling %1 was skipped because of record state differs from the expected one. Actual state: %2, expected state: %3.', Comment = '%1 = table caption, %2 = actual state, %3 = expected state.';
        UnexpectedSyncActionTxt: Label 'Coupling %1 was skipped because of sync action differs the expected one. Actual action: %2, expected action: %3.', Comment = '%1 = table caption, %2 = actual action, %3 = expected action.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;

    procedure SetContext(IntegrationTableMapping: Record "Integration Table Mapping"; LocalRecordRef: RecordRef; IntegrationRecordRef: RecordRef; SynchAction: Option; LocalRecordModified: Boolean; IntegrationRecordModified: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    begin
        IntegrationTableMappingContext := IntegrationTableMapping;
        LocalRecordRefContext := LocalRecordRef;
        IntegrationRecordRefContext := IntegrationRecordRef;
        SynchActionContext := SynchAction;
        LocalRecordModifiedContext := LocalRecordModified;
        IntegrationRecordModifiedContext := IntegrationRecordModified;
        IntegrationTableConnectionTypeContext := IntegrationTableConnectionType;
        JobIdContext := JobId;
        IsContextInitialized := true;
    end;

    procedure GetContext(var IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var SynchAction: Option; var LocalRecordModified: Boolean; var IntegrationRecordModified: Boolean)
    begin
        CheckContext();
        IntegrationTableMapping := IntegrationTableMappingContext;
        LocalRecordRef := LocalRecordRefContext;
        SynchAction := SynchActionContext;
        LocalRecordModified := LocalRecordModifiedContext;
        IntegrationRecordModified := IntegrationRecordModifiedContext;
        if IntegrationRecordModified then
            IntegrationRecordRef := IntegrationRecordRefContext;
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    local procedure CoupleRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecordState: Option NotFound,Coupled,Uncoupled;
        LocalRecordDeleted: Boolean;
        IntegrationRecordDeleted: Boolean;
    begin
        if SynchAction <> SynchActionType::Couple then begin
            Session.LogMessage('0000EZQ', StrSubstNo(UnexpectedSyncActionTxt, IntegrationRecordRef.Caption(), SynchAction, SynchActionType::Couple), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            SynchAction := SynchActionType::Skip;
            exit;
        end;

        if LocalRecordRef.Number() <> 0 then
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationRecordDeleted, IntegrationTableConnectionType)
        else
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, IntegrationRecordRef, LocalRecordRef, LocalRecordDeleted, IntegrationTableConnectionType);
        if RecordState = RecordState::Coupled then begin
            SynchAction := SynchActionType::Skip;
            Session.LogMessage('0000EZR', StrSubstNo(UnexpectedRecordStateTxt, IntegrationRecordRef.Caption(), RecordState, RecordState::Uncoupled), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        OnBeforeCoupleRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);

        AddIntegrationRecordCoupling(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationTableConnectionType);
        if LocalRecordRef.Number() <> 0 then
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationRecordDeleted, IntegrationTableConnectionType)
        else
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, IntegrationRecordRef, LocalRecordRef, LocalRecordDeleted, IntegrationTableConnectionType);
        if RecordState <> RecordState::Coupled then begin
            SynchAction := SynchActionType::Fail;
            Session.LogMessage('0000EZS', StrSubstNo(UnexpectedRecordStateTxt, IntegrationRecordRef.Caption(), RecordState, RecordState::Coupled), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if SynchAction = SynchActionType::Fail then begin
            OnErrorWhenCouplingRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);
            LogSynchError(
                LocalRecordRef, IntegrationRecordRef,
                StrSubstNo(CouplingFailedErr, IntegrationRecordRef.Caption(), RemoveTrailingDots(GetLastErrorText())), JobId);
            exit;
        end;

        OnAfterCoupleRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);
    end;

    local procedure RemoveTrailingDots(Message: Text): Text
    begin
        exit(DelChr(Message, '>', '.'));
    end;

    local procedure AddIntegrationRecordCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalRecordRef: RecordRef; IntegrationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType): Boolean
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
        DestinationTableID: Integer;
    begin
        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::Dataverse then
            if CRMIntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
                exit(false);

        IntegrationTableUidFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value();
        DestinationTableID := IntegrationTableMapping."Table ID";

        IntegrationRecordManagement.UpdateIntegrationTableCoupling(IntegrationTableConnectionType, IntegrationTableUid, LocalRecordRef);
    end;

    local procedure LogSynchError(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; ErrorMessage: Text; JobId: Guid)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EmptyRecordID: RecordID;
    begin
        if IsNullGuid(JobId) then
            exit;

        if IntegrationRecordRef.Number = 0 then begin
            EmptyRecordID := LocalRecordRef.RecordId();
            Clear(EmptyRecordID);
            IntegrationSynchJobErrors.LogSynchError(JobId, LocalRecordRef.RecordId(), EmptyRecordID, ErrorMessage)
        end else begin
            IntegrationSynchJobErrors.LogSynchError(JobId, LocalRecordRef.RecordId(), IntegrationRecordRef.RecordId(), ErrorMessage);

            // Close destination - it is in error state and can no longer be used.
            IntegrationRecordRef.Close();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorWhenCouplingRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;
}

