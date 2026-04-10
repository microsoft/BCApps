// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;

codeunit 5364 "Int. Option Synch. Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        SynchOption(
          IntegrationTableMappingContext, SourceRecordRefContext, DestinationRecordRefContext,
          SynchActionContext, IgnoreSynchOnlyCoupledRecordsContext, JobIdContext);
    end;

    var
        IntegrationTableMappingContext: Record "Integration Table Mapping";
        SourceRecordRefContext: RecordRef;
        DestinationRecordRefContext: RecordRef;
        JobIdContext: Guid;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        ModifyFailedErr: Label 'Modifying %1 failed because of the following error: %2.', Comment = '%1 = Table Caption, %2 = Error from modify process.';
        ModifyFailedSimpleErr: Label 'Modifying %1 failed.', Comment = '%1 = Table Caption';
        CoupledRecordIsDeletedErr: Label 'The %1 record cannot be updated because it is coupled to a deleted record.', Comment = '%1 = Source Table Caption';
        CopyDataErr: Label 'The data could not be updated because of the following error: %1.', Comment = '%1 = Error message from transferdata process.';
        SynchActionContext: Option;
        IgnoreSynchOnlyCoupledRecordsContext: Boolean;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';

    procedure SetContext(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid)
    begin
        IntegrationTableMappingContext := IntegrationTableMapping;
        SourceRecordRefContext := SourceRecordRef;
        DestinationRecordRefContext := DestinationRecordRef;
        SynchActionContext := SynchAction;
        IgnoreSynchOnlyCoupledRecordsContext := IgnoreSynchOnlyCoupledRecords;
        JobIdContext := JobId;
        IsContextInitialized := true;
    end;

    procedure GetContext(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option)
    begin
        CheckContext();
        IntegrationTableMapping := IntegrationTableMappingContext;
        SourceRecordRef := SourceRecordRefContext;
        DestinationRecordRef := DestinationRecordRefContext;
        SynchAction := SynchActionContext;
    end;

    procedure WasModifiedAfterLastSynch(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        DestinationFieldRef: FieldRef;
        LastModifiedOn: DateTime;
    begin
        if IntegrationTableMapping."Table ID" = SourceRecordRef.Number() then begin
            LastModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
            exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordRef, LastModifiedOn));
        end else begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            if IntegrationFieldMapping.FindFirst() then begin
                DestinationFieldRef := DestinationRecordRef.Field(IntegrationFieldMapping."Field No.");
                exit(UpperCase(Format(DestinationFieldRef.Value())) <> UpperCase(CopyStr(CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef), 1, DestinationFieldRef.Length)));
            end;
        end;
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    procedure GetRowLastModifiedOn(IntegrationTableMapping: Record "Integration Table Mapping"; FromRecordRef: RecordRef): DateTime
    var
        ModifiedFieldRef: FieldRef;
    begin
        ModifiedFieldRef := FromRecordRef.Field(FromRecordRef.SystemModifiedAtNo());
        exit(ModifiedFieldRef.Value());
    end;

    local procedure SynchOption(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid)
    var
        SourceWasChanged: Boolean;
        RecordState: Option NotFound,Coupled,Decoupled;
        IsDestinationDeleted: Boolean;
        NewPK: Variant;
    begin
        // Find the mapped record or prepare a new one
        RecordState := GetMappedRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, IsDestinationDeleted, JobId);
        if RecordState = RecordState::NotFound then begin
            if SynchAction = SynchActionType::Fail then
                exit;
            if IsDestinationDeleted or (IntegrationTableMapping."Synch. Only Coupled Records" and not IgnoreSynchOnlyCoupledRecords) then begin
                SynchAction := SynchActionType::Skip;
                exit;
            end;
            PrepareNewDestination(IntegrationTableMapping, DestinationRecordRef);
            SynchAction := SynchActionType::Insert;
        end;

        if SynchAction = SynchActionType::Insert then
            SourceWasChanged := true
        else begin
            SourceWasChanged := WasModifiedAfterLastSynch(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            if SynchAction <> SynchActionType::ForceModify then
                if not SourceWasChanged then
                    SynchAction := SynchActionType::IgnoreUnchanged;
        end;

        if not (SynchAction in [SynchActionType::Insert, SynchActionType::Modify, SynchActionType::ForceModify]) then
            exit;

        if SourceWasChanged or (SynchAction = SynchActionType::ForceModify) then
            TransferFields(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, NewPK);

        case SynchAction of
            SynchActionType::Insert:
                InsertRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId);
            SynchActionType::Modify,
            SynchActionType::ForceModify:
                ModifyRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, NewPK);
        end;
    end;

    local procedure InsertRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        NewOptionId: Integer;
    begin
        OnBeforeInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
            DestinationRecordRef.Insert(true)
        else begin
            NewOptionId := InsertCRMOption(DestinationRecordRef);
            DestinationRecordRef.Field(1).Value := NewOptionId;
        end;

        if SynchAction <> SynchActionType::Fail then begin
            CRMOptionMapping.UpdateOptionMapping(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, JobId);

            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
                OnAfterInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
                if DestinationRecordRef.Number() = IntegrationTableMapping."Table ID" then
                    // refetch the local record as subscribers to the OnAfterInsertRecord above could update it
                    DestinationRecordRef.GetBySystemId(DestinationRecordRef.Field(DestinationRecordRef.SystemIdNo).Value());
            end;
            OnAfterInsertOption(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
        end;
        Commit();
    end;

    local procedure InsertCRMOption(DestinationRecordRef: RecordRef): Integer
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EntityName: Text;
        FieldName: Text;
    begin
        CRMOptionMapping.GetMetadataInfo(DestinationRecordRef, EntityName, FieldName);
        exit(CDSIntegrationMgt.InsertOptionSetMetadata(EntityName, FieldName, CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef)));
    end;

    local procedure ModifyRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; NewPK: Variant)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        LastError: Text;
        LogError: Text;
        Failed: Boolean;
    begin
        OnBeforeModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
            if DestinationRecordRef.Rename(NewPK) then begin
                CRMOptionMapping.UpdateOptionMapping(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, JobId);
                OnAfterModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
                if DestinationRecordRef.Number() = IntegrationTableMapping."Table ID" then
                    // refetch the local record as subscribers to the OnAfterModifyRecord above could update it
                    DestinationRecordRef.GetBySystemId(DestinationRecordRef.Field(DestinationRecordRef.SystemIdNo).Value());
            end else
                Failed := true
        else
            if ModifyCRMOption(DestinationRecordRef) then
                CRMOptionMapping.UpdateOptionMapping(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, JobId)
            else
                Failed := true;

        OnAfterModifyOption(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);

        if Failed then begin
            LastError := GetLastErrorText();
            OnErrorWhenModifyingRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            SynchAction := SynchActionType::Fail;
            if LastError <> '' then
                LogError := StrSubstNo(ModifyFailedErr, DestinationRecordRef.Caption(), RemoveTrailingDots(LastError))
            else
                LogError := StrSubstNo(ModifyFailedSimpleErr, DestinationRecordRef.Caption());
            LogSynchError(SourceRecordRef, DestinationRecordRef, LogError, JobId);
            MarkOptionMappingAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, SynchAction);
        end;
        Commit();
    end;

    [TryFunction]
    local procedure ModifyCRMOption(DestinationRecordRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EntityName: Text;
        FieldName: Text;
    begin
        CRMOptionMapping.GetMetadataInfo(DestinationRecordRef, EntityName, FieldName);
        CDSIntegrationMgt.UpdateOptionSetMetadata(EntityName, FieldName, CRMOptionMapping.GetRecordRefOptionId(DestinationRecordRef), CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef));
    end;

    local procedure GetMappedRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef; var CoupledRecordRef: RecordRef; var SynchAction: Option; var IsDestinationMarkedAsDeleted: Boolean; JobId: Guid): Integer
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        DeletionConflictHandled: Boolean;
        RecordState: Option NotFound,Coupled,Decoupled;
    begin
        IsDestinationMarkedAsDeleted := false;
        if RecordRef.Number = IntegrationTableMapping."Table ID" then begin
            CRMOptionMapping.SetRange("Record ID", RecordRef.RecordId);
            if CRMOptionMapping.FindFirst() then begin
                RecordState := RecordState::Coupled;
                CRMIntegrationTableSynch.LoadCRMOption(CoupledRecordRef, IntegrationTableMapping);
                CoupledRecordRef.Field(CoupledRecordRef.KeyIndex(1).FieldIndex(1).Number).SetRange(CRMOptionMapping."Option Value");
                IsDestinationMarkedAsDeleted := not CoupledRecordRef.FindFirst();
            end else
                RecordState := RecordState::NotFound;
        end else
            if CRMOptionMapping.IsCRMRecordRefMapped(RecordRef, CRMOptionMapping) then begin
                RecordState := RecordState::Coupled;
                IsDestinationMarkedAsDeleted := not CoupledRecordRef.Get(CRMOptionMapping."Record ID")
            end else
                RecordState := RecordState::NotFound;

        if RecordState <> RecordState::NotFound then
            if not IsDestinationMarkedAsDeleted then begin
                if SynchAction <> SynchActionType::ForceModify then
                    SynchAction := SynchActionType::Modify;
                exit(RecordState);
            end;

        if SynchAction <> SynchActionType::ForceModify then
            if RecordState = RecordState::Coupled then begin
                OnDeletionConflictDetected(IntegrationTableMapping, RecordRef, DeletionConflictHandled);
                if not DeletionConflictHandled then begin
                    RecordState := RecordState::NotFound;
                    SynchAction := SynchActionType::Fail;
                    LogSynchError(RecordRef, CoupledRecordRef, StrSubstNo(CoupledRecordIsDeletedErr, RecordRef.Caption), JobId);
                    MarkOptionMappingAsFailed(IntegrationTableMapping, RecordRef, JobId, SynchAction);
                end else
                    case IntegrationTableMapping."Deletion-Conflict Resolution" of
                        IntegrationTableMapping."Deletion-Conflict Resolution"::"Restore Records":
                            begin
                                PrepareNewDestination(IntegrationTableMapping, CoupledRecordRef);
                                RecordState := RecordState::Coupled;
                                SynchAction := SynchActionType::Insert;
                            end;

                        IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling":
                            begin
                                RecordState := RecordState::Decoupled;
                                SynchAction := SynchActionType::None;
                            end;
                    end;
            end;

        exit(RecordState);
    end;

    local procedure PrepareNewDestination(var IntegrationTableMapping: Record "Integration Table Mapping"; var CoupledRecordRef: RecordRef)
    begin
        CoupledRecordRef.Close();
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
            CoupledRecordRef.Open(IntegrationTableMapping."Table ID")
        else begin
            case IntegrationTableMapping."Table ID" of
                Database::"Payment Terms":
                    CoupledRecordRef.Open(Database::"CRM Payment Terms");
                Database::"Shipment Method":
                    CoupledRecordRef.Open(Database::"CRM Freight Terms");
                Database::"Shipping Agent":
                    CoupledRecordRef.Open(Database::"CRM Shipping Method");
            end;
            OnPrepareNewDestination(IntegrationTableMapping, CoupledRecordRef);
        end;
        CoupledRecordRef.Init();
    end;

    local procedure LogSynchError(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ErrorMessage: Text; JobId: Guid)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EmptyRecordID: RecordID;
    begin
        if DestinationRecordRef.Number = 0 then begin
            EmptyRecordID := SourceRecordRef.RecordId();
            Clear(EmptyRecordID);
            IntegrationSynchJobErrors.LogSynchError(JobId, SourceRecordRef.RecordId(), EmptyRecordID, ErrorMessage)
        end else begin
            IntegrationSynchJobErrors.LogSynchError(JobId, SourceRecordRef.RecordId(), DestinationRecordRef.RecordId(), ErrorMessage);

            // Close destination - it is in error state and can no longer be used.
            DestinationRecordRef.Close();
        end;
    end;

    local procedure TransferFields(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; var NewPK: Variant)
    begin
        OnBeforeTransferRecordFields(SourceRecordRef, DestinationRecordRef);

        if not TransferField(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, NewPK) then begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(
              SourceRecordRef, DestinationRecordRef,
              StrSubstNo(CopyDataErr, RemoveTrailingDots(GetLastErrorText)), JobId);
            MarkOptionMappingAsFailed(IntegrationTableMappingContext, SourceRecordRef, JobId, SynchAction);
            Commit();
        end;
    end;

    [TryFunction]
    local procedure TransferField(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SyncAction: Option; var NewPK: Variant)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        DestinationFieldRef: FieldRef;
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        if IntegrationFieldMapping.FindFirst() then
            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
                DestinationFieldRef := DestinationRecordRef.Field(IntegrationFieldMapping."Field No.");
                if not (SyncAction in [SynchActionType::Modify, SynchActionType::ForceModify]) then begin
                    DestinationFieldRef.Value := CopyStr(CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef), 1, DestinationFieldRef.Length);
                    if IntegrationFieldMapping."Validate Field" then
                        DestinationFieldRef.Validate();
                end else
                    NewPK := CopyStr(CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef), 1, DestinationFieldRef.Length);
            end else begin
                DestinationFieldRef := DestinationRecordRef.Field(2);
                DestinationFieldRef.Value := SourceRecordRef.Field(IntegrationFieldMapping."Field No.");
            end;
    end;

    procedure MarkOptionMappingAsFailed(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; JobId: Guid; var SyncAction: Option)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        DirectionToIntTable: Boolean;
        MarkedAsSkipped: Boolean;
    begin
        DirectionToIntTable := IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable;
        MarkedAsSkipped := SyncAction = SynchActionType::Skip;

        CRMOptionMapping.MarkLastSynchAsFailure(SourceRecordRef, DirectionToIntTable, JobId, MarkedAsSkipped);
        if MarkedAsSkipped then
            SyncAction := SynchActionType::Skip;
    end;

    local procedure RemoveTrailingDots(Message: Text): Text
    begin
        exit(DelChr(Message, '>', '.'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletionConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DeletionConflictHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyOption(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorWhenModifyingRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOption(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareNewDestination(IntegrationTableMapping: Record "Integration Table Mapping"; var CoupledRecordRef: RecordRef)
    begin
    end;
}

