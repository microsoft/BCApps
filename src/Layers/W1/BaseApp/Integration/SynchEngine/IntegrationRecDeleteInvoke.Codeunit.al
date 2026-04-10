// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

codeunit 5347 "Integration Rec. Delete Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        DeleteRecord(IntegrationTableMappingContext, DestinationRecordRefContext, SynchActionContext,
          JobIdContext);
    end;

    var
        IntegrationTableMappingContext: Record "Integration Table Mapping";
        DestinationRecordRefContext: RecordRef;
        JobIdContext: Guid;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        SynchActionContext: Option;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';

    procedure SetContext(IntegrationTableMapping: Record "Integration Table Mapping"; DestinationRecordRef: RecordRef; SynchAction: Option; JobId: Guid)
    begin
        IntegrationTableMappingContext := IntegrationTableMapping;
        DestinationRecordRefContext := DestinationRecordRef;
        SynchActionContext := SynchAction;
        JobIdContext := JobId;
        IsContextInitialized := true;
    end;

    procedure GetContext(var IntegrationTableMapping: Record "Integration Table Mapping"; var DestinationRecordRef: RecordRef; var SynchAction: Option)
    begin
        CheckContext();
        IntegrationTableMapping := IntegrationTableMappingContext;
        DestinationRecordRef := DestinationRecordRefContext;
        SynchAction := SynchActionContext;
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    local procedure DeleteRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var DestinationRecordRef: RecordRef; SynchAction: Option; JobId: Guid)
    begin
        if SynchAction = SynchActionType::Fail then
            exit;

        if SynchAction <> SynchActionType::Delete then
            exit;

        OnBeforeDeleteRecord(IntegrationTableMapping, DestinationRecordRef);

        if not DestinationRecordRef.Delete() then
            LogSynchError(DestinationRecordRef, GetLastErrorText, JobId);

        OnAfterDeleteRecord(IntegrationTableMapping, DestinationRecordRef);
        Commit();
    end;

    local procedure LogSynchError(var DestinationRecordRef: RecordRef; ErrorMessage: Text; JobId: Guid)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EmptyRecordID: RecordID;
    begin
        Evaluate(EmptyRecordID, '');
        if DestinationRecordRef.Number <> 0 then begin
            IntegrationSynchJobErrors.LogSynchError(JobId, EmptyRecordID, DestinationRecordRef.RecordId, ErrorMessage);
            // Close destination - it is in error state and can no longer be used.
            DestinationRecordRef.Close();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var DestinationRecordRef: RecordRef)
    begin
    end;
}

