// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;
using System.Reflection;

codeunit 5357 "Int. Rec. Uncouple Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        UncoupleRecord(
            IntegrationTableMappingContext, LocalRecordRefContext, IntegrationRecordRefContext,
            SynchActionContext, LocalRecordModifiedContext, IntegrationRecordModifiedContext,
            JobIdContext, IntegrationTableConnectionTypeContext);
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
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple;
        SynchActionContext: Option;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';
        UncoupleFailedErr: Label 'Uncoupling %1 failed because of the following error: %2.', Comment = '%1 = Table Caption, %2 = Error from modify process.';
        UnexpectedRecordStateTxt: Label 'Uncoupling %1 was skipped because of record state differs from the expected one. Actual state: %2, expected state: %3.', Locked = true;
        UnexpectedSyncActionTxt: Label 'Uncoupling %1 was skipped because of sync action differs the expected one. Actual action: %2, expected action: %3.', Locked = true;
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
        IntegrationRecordRef := IntegrationRecordRefContext;
        SynchAction := SynchActionContext;
        LocalRecordModified := LocalRecordModifiedContext;
        IntegrationRecordModified := IntegrationRecordModifiedContext;
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    local procedure UncoupleRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var SynchAction: Option; var LocalRecordModified: Boolean; var IntegrationRecordModified: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecordState: Option NotFound,Coupled,Uncoupled;
        LocalRecordDeleted: Boolean;
        IntegrationRecordDeleted: Boolean;
        IntegrationRecordLastModifiedTime: DateTime;
    begin
        if SynchAction <> SynchActionType::Uncouple then begin
            SynchAction := SynchActionType::Skip;
            Session.LogMessage('0000DEB', StrSubstNo(UnexpectedSyncActionTxt, GetTableCaption(IntegrationTableMapping."Integration Table ID"), SynchAction, SynchActionType::Skip), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if LocalRecordRef.Number() <> 0 then
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationRecordDeleted, IntegrationTableConnectionType)
        else
            RecordState := IntegrationRecSynchInvoke.FindCoupledRecord(IntegrationTableMapping, IntegrationRecordRef, LocalRecordRef, LocalRecordDeleted, IntegrationTableConnectionType);
        if RecordState <> RecordState::Coupled then begin
            SynchAction := SynchActionType::Skip;
            Session.LogMessage('0000DEC', StrSubstNo(UnexpectedRecordStateTxt, GetTableCaption(IntegrationTableMapping."Integration Table ID"), RecordState, RecordState::Coupled), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if not IntegrationRecordDeleted then
                if IntegrationRecordRef.Number() <> 0 then
                    IntegrationRecordLastModifiedTime := GetIntegrationRecordLastModifiedTime(IntegrationTableMapping, IntegrationRecordRef);

        OnBeforeUncoupleRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);

        if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::FromIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if not LocalRecordDeleted then
                if LocalRecordRef.Number() <> 0 then
                    if LocalRecordRef.IsDirty() then
                        if LocalRecordRef.Modify(true) then
                            LocalRecordModified := true
                        else
                            SynchAction := SynchActionType::Fail;

        if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if not IntegrationRecordDeleted then
                if IntegrationRecordRef.Number() <> 0 then
                    if not IntegrationRecordRef.IsDirty() then
                        IntegrationRecordModified := GetIntegrationRecordLastModifiedTime(IntegrationTableMapping, IntegrationRecordRef) > IntegrationRecordLastModifiedTime
                    else
                        if IntegrationRecordRef.Modify(true) then
                            IntegrationRecordModified := true
                        else
                            SynchAction := SynchActionType::Fail;

        if SynchAction = SynchActionType::Fail then begin
            OnErrorWhenUncouplingRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);
            LogSynchError(
                LocalRecordRef, IntegrationRecordRef,
                StrSubstNo(UncoupleFailedErr, GetTableCaption(IntegrationTableMapping."Integration Table ID"), RemoveTrailingDots(GetLastErrorText())), JobId);
            exit;
        end;

        if not RemoveIntegrationRecordCoupling(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationTableConnectionType) then
            SynchAction := SynchActionType::"None";
        OnAfterUncoupleRecord(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef);
    end;

    local procedure RemoveIntegrationRecordCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalRecordRef: RecordRef; IntegrationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType): Boolean
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
        DestinationTableID: Integer;
        Removed: Boolean;
        IsHandled: Boolean;
    begin
        OnRemoveIntegrationTableCoupling(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, IntegrationTableConnectionType, IsHandled, Removed);
        if IsHandled then
            exit(Removed);

        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::Dataverse then
            if CRMIntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
                exit(false);

        IntegrationTableUidFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value();
        DestinationTableID := IntegrationTableMapping."Table ID";

        IntegrationRecordManagement.RemoveIntegrationTableCoupling(
          IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, LocalRecordRef, Removed);
        exit(Removed);
    end;

    procedure GetIntegrationRecordLastModifiedTime(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationRecordRef: RecordRef): DateTime
    var
        ModifiedFieldRef: FieldRef;
    begin
        ModifiedFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
        exit(ModifiedFieldRef.Value());
    end;

    local procedure RemoveTrailingDots(Message: Text): Text
    begin
        exit(DelChr(Message, '>', '.'));
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

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.Caption);
        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorWhenUncouplingRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveIntegrationTableCoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var IntegrationTableConnectionType: TableConnectionType; var IsHandled: Boolean; var Removed: Boolean)
    begin
    end;
}

