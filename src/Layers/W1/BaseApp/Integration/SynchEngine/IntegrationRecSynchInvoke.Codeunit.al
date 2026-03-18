// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Finance.Dimension;
using Microsoft.Integration.Dataverse;
using System.IO;

codeunit 5345 "Integration Rec. Synch. Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        SynchRecord(
          IntegrationTableMappingContext, SourceRecordRefContext, DestinationRecordRefContext,
          IntegrationRecordSynchContext, SynchActionContext, IgnoreSynchOnlyCoupledRecordsContext,
          JobIdContext, IntegrationTableConnectionTypeContext);
    end;

    var
        IntegrationTableMappingContext: Record "Integration Table Mapping";
        IntegrationRecordSynchContext: Codeunit "Integration Record Synch.";
        SourceRecordRefContext: RecordRef;
        DestinationRecordRefContext: RecordRef;
        IntegrationTableConnectionTypeContext: TableConnectionType;
        JobIdContext: Guid;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        SourceAndDestinationConflictErr: Label 'Cannot update a record in the %2 table. The mapping between %3 field on the %1 table and the %4 field on the %2 table is bi-directional, and one or both values have changed since the last synchronization.', Comment = '%1 = Source record table caption, %2 = destination table caption, %3 = source field caption, %4 = destination field caption';
        ModifyFailedErr: Label 'Modifying %1 failed because of the following error: %2.', Comment = '%1 = Table Caption, %2 = Error from modify process.';
        ModifyFailedSimpleErr: Label 'Modifying %1 failed.', Comment = '%1 = Table Caption';
        ConfigurationTemplateNotFoundErr: Label 'The %1 %2 was not found.', Comment = '%1 = Configuration Template table caption, %2 = Configuration Template Name';
#pragma warning disable AA0470
        CoupledRecordIsDeletedErr: Label 'The %1 record cannot be updated because it is coupled to a deleted record.', Comment = '1% = Source Table Caption';
#pragma warning restore AA0470
        CopyDataErr: Label 'The data could not be updated because of the following error: %1.', Comment = '%1 = Error message from transferdata process.';
        SynchActionContext: Option;
        IgnoreSynchOnlyCoupledRecordsContext: Boolean;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        SyncConflictResolvedTxt: Label 'Synchronization conflict has been resolved as no one changed bidirectional field was detected. Fields modified: %1, additional fields modified: %2.', Locked = true;
        SyncConflictNotResolvedTxt: Label 'Synchronization conflict has not been resolved as a changed bidirectional field was detected. Field mapping: %1, %2, %3 -> %4.', Locked = true;

    procedure SetContext(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationRecordSynch: Codeunit "Integration Record Synch."; SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    begin
        IntegrationTableMappingContext := IntegrationTableMapping;
        IntegrationRecordSynchContext := IntegrationRecordSynch;
        SourceRecordRefContext := SourceRecordRef;
        DestinationRecordRefContext := DestinationRecordRef;
        SynchActionContext := SynchAction;
        IgnoreSynchOnlyCoupledRecordsContext := IgnoreSynchOnlyCoupledRecords;
        IntegrationTableConnectionTypeContext := IntegrationTableConnectionType;
        JobIdContext := JobId;
        IsContextInitialized := true;
    end;

    procedure GetContext(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IntegrationRecordSynch: Codeunit "Integration Record Synch."; var SynchAction: Option)
    begin
        CheckContext();
        IntegrationTableMapping := IntegrationTableMappingContext;
        IntegrationRecordSynch := IntegrationRecordSynchContext;
        SourceRecordRef := SourceRecordRefContext;
        DestinationRecordRef := DestinationRecordRefContext;
        SynchAction := SynchActionContext;
    end;

    procedure WasModifiedAfterLastSynch(IntegrationTableMapping: Record "Integration Table Mapping"; RecordRef: RecordRef): Boolean
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        LastModifiedOn: DateTime;
    begin
        LastModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, RecordRef);
        if IntegrationTableMapping."Integration Table ID" = RecordRef.Number() then
            exit(
              IntegrationRecordManagement.IsModifiedAfterIntegrationTableRecordLastSynch(
                IntegrationTableConnectionTypeContext, RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value(),
                IntegrationTableMapping."Table ID", LastModifiedOn));

        exit(
          IntegrationRecordManagement.IsModifiedAfterRecordLastSynch(
            IntegrationTableConnectionTypeContext, RecordRef, LastModifiedOn));
    end;

    procedure GetRowLastModifiedOn(IntegrationTableMapping: Record "Integration Table Mapping"; FromRecordRef: RecordRef): DateTime
    var
        ModifiedFieldRef: FieldRef;
    begin
        if FromRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then begin
            ModifiedFieldRef := FromRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            exit(ModifiedFieldRef.Value());
        end;

        ModifiedFieldRef := FromRecordRef.Field(FromRecordRef.SystemModifiedAtNo());
        exit(ModifiedFieldRef.Value());
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    local procedure SynchRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IntegrationRecordSynch: Codeunit "Integration Record Synch."; var SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        TempTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        AdditionalFieldsModified: Boolean;
        SourceWasChanged: Boolean;
        WasModified: Boolean;
        IsHandled: Boolean;
        BothModified: Boolean;
        UpdateConflictHandled: Boolean;
        SkipRecord: Boolean;
        RecordState: Option NotFound,Coupled,Decoupled;
        SourceFieldName: Text;
        SourceFieldCaption: Text;
        DestinationFieldName: Text;
        DestinationFieldCaption: Text;
        IsDestinationDeleted: Boolean;
    begin
        // Find the coupled record or prepare a new one
        RecordState :=
          GetCoupledRecord(
            IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, IsDestinationDeleted, JobId, IntegrationTableConnectionType);
        if RecordState = RecordState::NotFound then begin
            if SynchAction = SynchActionType::Fail then
                exit;
            if IsDestinationDeleted or (IntegrationTableMapping."Synch. Only Coupled Records" and not IgnoreSynchOnlyCoupledRecords) then begin
                SynchAction := SynchActionType::Skip;
                exit;
            end;
            PrepareNewDestination(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            SynchAction := SynchActionType::Insert;
        end;

        if SynchAction = SynchActionType::Insert then
            SourceWasChanged := true
        else begin
            OnWasModifiedAfterLastSynch(IntegrationTableConnectionTypeContext, IntegrationTableMapping, SourceRecordRef, SourceWasChanged, IsHandled);
            if not IsHandled then
                SourceWasChanged := WasModifiedAfterLastSynch(IntegrationTableMapping, SourceRecordRef);
            if SynchAction <> SynchActionType::ForceModify then
                if SourceWasChanged then begin
                    if IntegrationTableMapping.GetDirection() = IntegrationTableMapping.Direction::Bidirectional then
                        BothModified := WasModifiedAfterLastSynch(IntegrationTableMapping, DestinationRecordRef);
                end else
                    SynchAction := SynchActionType::IgnoreUnchanged;
        end;

        if not (SynchAction in [SynchActionType::Insert, SynchActionType::Modify, SynchActionType::ForceModify]) then begin
            if SynchAction = SynchActionType::IgnoreUnchanged then
                OnBeforeIgnoreUnchangedRecordHandled(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            exit;
        end;

        if SourceWasChanged or (SynchAction = SynchActionType::ForceModify) then
            TransferFields(
              IntegrationRecordSynch, IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, AdditionalFieldsModified, JobId, BothModified);

        if BothModified then begin
            if IntegrationRecordSynch.GetWasBidirectionalFieldModified() then begin
                IntegrationRecordSynch.GetBidirectionalFieldModifiedContext(TempTempIntegrationFieldMapping);
                OnUpdateConflictDetected(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, UpdateConflictHandled, SkipRecord);
                if not UpdateConflictHandled then begin
                    if not GetFieldNameAndCaption(SourceRecordRef, TempTempIntegrationFieldMapping."Source Field No.", SourceFieldName, SourceFieldCaption) then begin
                        SourceFieldName := Format(TempTempIntegrationFieldMapping."Source Field No.");
                        SourceFieldCaption := SourceFieldName;
                    end;
                    if not GetFieldNameAndCaption(DestinationRecordRef, TempTempIntegrationFieldMapping."Destination Field No.", DestinationFieldName, DestinationFieldCaption) then begin
                        DestinationFieldName := Format(TempTempIntegrationFieldMapping."Destination Field No.");
                        DestinationFieldCaption := DestinationFieldName;
                    end;
                    Session.LogMessage('0000CTC', StrSubstNo(SyncConflictNotResolvedTxt,
                          TempTempIntegrationFieldMapping."No.", TempTempIntegrationFieldMapping."Integration Table Mapping Name",
                          SourceFieldName, DestinationFieldName), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    SynchAction := SynchActionType::Fail;
                    LogSynchError(
                        SourceRecordRef, DestinationRecordRef,
                        StrSubstNo(SourceAndDestinationConflictErr, SourceRecordRef.Caption(), DestinationRecordRef.Caption(), SourceFieldCaption, DestinationFieldCaption), JobId);
                    MarkIntegrationRecordAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, IntegrationTableConnectionType, SynchAction);
                    exit;
                end;
                if SkipRecord then begin
                    SynchAction := SynchActionType::Skip;
                    exit;
                end;
                SynchAction := SynchActionType::ForceModify;
            end;
            Session.LogMessage('0000CTD', StrSubstNo(SyncConflictResolvedTxt, IntegrationRecordSynch.GetWasModified(), AdditionalFieldsModified), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;

        WasModified := IntegrationRecordSynch.GetWasModified() or AdditionalFieldsModified;
        if (SynchAction = SynchActionType::Modify) and (not WasModified) then
            SynchAction := SynchActionType::IgnoreUnchanged;

        case SynchAction of
            SynchActionType::Insert:
                InsertRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, IntegrationTableConnectionType);
            SynchActionType::Modify,
            SynchActionType::ForceModify:
                ModifyRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, IntegrationTableConnectionType, BothModified);
            SynchActionType::IgnoreUnchanged:
                begin
                    UpdateIntegrationRecordCoupling(
                      IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
                    OnAfterUnchangedRecordHandled(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
                    UpdateIntegrationRecordTimestamp(
                      IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId);
                end;
        end;
    end;

    [TryFunction]
    local procedure GetFieldNameAndCaption(RecRef: RecordRef; FieldNo: Integer; var FieldName: Text; var FieldCaption: Text)
    begin
        if RecRef.FieldExist(FieldNo) then begin
            FieldName := RecRef.Field(FieldNo).Name();
            FieldCaption := RecRef.Field(FieldNo).Caption();
        end else begin
            FieldName := Format(FieldNo);
            FieldCaption := FieldName;
        end;
    end;

    local procedure InsertRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        InsertWithSystemId: Boolean;
    begin
        OnBeforeInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, InsertWithSystemId);
        if InsertWithSystemId then
            InsertWithSystemId := CRMIntegrationManagement.IsCRMTable(SourceRecordRef.Number());
        DestinationRecordRef.Insert(true, InsertWithSystemId);
        ApplyConfigTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, JobId, SynchAction);
        OnInsertRecordOnAfterApplyConfigTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
        if SynchAction <> SynchActionType::Fail then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            Commit();
            OnAfterInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            if DestinationRecordRef.Number() = IntegrationTableMapping."Table ID" then
                // refetch the local record as subscribers to the OnAfterInsertRecord above could update it
                if DestinationRecordRef.GetBySystemId(DestinationRecordRef.Field(DestinationRecordRef.SystemIdNo).Value()) then;
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId);
        end;
        Commit();
    end;

    local procedure ModifyRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType; BothModified: Boolean)
    var
        LastError: Text;
        LogError: Text;
    begin
        OnBeforeModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);

        if DestinationRecordRef.Modify(true) then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            OnAfterModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            if DestinationRecordRef.Number() = IntegrationTableMapping."Table ID" then
                // refetch the local record as subscribers to the OnAfterModifyRecord above could update it
                // for example, this is the case while synching customers and vendors
                if DestinationRecordRef.GetBySystemId(DestinationRecordRef.Field(DestinationRecordRef.SystemIdNo).Value()) then;
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId, BothModified);
        end else begin
            LastError := GetLastErrorText();
            OnErrorWhenModifyingRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            SynchAction := SynchActionType::Fail;
            if LastError <> '' then
                LogError := StrSubstNo(ModifyFailedErr, DestinationRecordRef.Caption(), RemoveTrailingDots(LastError))
            else
                LogError := StrSubstNo(ModifyFailedSimpleErr, DestinationRecordRef.Caption());
            LogSynchError(SourceRecordRef, DestinationRecordRef, LogError, JobId);
            MarkIntegrationRecordAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, IntegrationTableConnectionType, SynchAction);
        end;
        Commit();
    end;

    local procedure ApplyConfigTemplate(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; JobId: Guid; var SynchAction: Option)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        ConfigTemplateCode: Code[10];
        Handled: Boolean;
    begin
        OnBeforeDetermineConfigTemplateCode(IntegrationTableMapping, ConfigTemplateCode, Handled);
        if not Handled then
            if DestinationRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then
                ConfigTemplateCode := FindIntTableConfigTemplate(IntegrationTableMapping, SourceRecordRef)
            else
                ConfigTemplateCode := FindTableConfigTemplate(IntegrationTableMapping, SourceRecordRef);
        if ConfigTemplateCode <> '' then begin
            OnBeforeApplyRecordTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, ConfigTemplateCode);

            if ConfigTemplateHeader.Get(ConfigTemplateCode) then begin
                ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, DestinationRecordRef);
                if DestinationRecordRef.Number() <> IntegrationTableMapping."Integration Table ID" then
                    InsertDimensionsFromTemplate(ConfigTemplateHeader, DestinationRecordRef);
                OnAfterApplyRecordTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            end else begin
                SynchAction := SynchActionType::Fail;
                LogSynchError(
                  SourceRecordRef, DestinationRecordRef,
                  StrSubstNo(ConfigurationTemplateNotFoundErr, ConfigTemplateHeader.TableCaption(), ConfigTemplateCode), JobId);
            end;
        end;
    end;

    local procedure InsertDimensionsFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; var DestinationRecordRef: RecordRef)
    var
        DimensionsTemplate: Record "Dimensions Template";
        PrimaryKeyFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := DestinationRecordRef.KeyIndex(1);
        if PrimaryKeyRef.FieldCount() <> 1 then
            exit;

        PrimaryKeyFieldRef := PrimaryKeyRef.FieldIndex(1);
        if PrimaryKeyFieldRef.Type() <> FieldType::Code then
            exit;

        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, CopyStr(Format(PrimaryKeyFieldRef.Value()), 1, 20), DestinationRecordRef.Number);
        DestinationRecordRef.Get(DestinationRecordRef.RecordId());
    end;

    local procedure GetCoupledRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef; var CoupledRecordRef: RecordRef; var SynchAction: Option; var IsDestinationMarkedAsDeleted: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType): Integer
    var
        DeletionConflictHandled: Boolean;
        SetSynchActionHandled: Boolean;
        RecordState: Option NotFound,Coupled,Decoupled;
    begin
        IsDestinationMarkedAsDeleted := false;
        RecordState :=
          FindRecord(
            IntegrationTableMapping, RecordRef, CoupledRecordRef, IsDestinationMarkedAsDeleted, IntegrationTableConnectionType);

        if RecordState <> RecordState::NotFound then
            if not IsDestinationMarkedAsDeleted then begin
                if RecordState = RecordState::Decoupled then
                    SynchAction := SynchActionType::ForceModify;
                if SynchAction <> SynchActionType::ForceModify then
                    SynchAction := SynchActionType::Modify;
                exit(RecordState);
            end;

        if SynchAction <> SynchActionType::ForceModify then
            if RecordState = RecordState::Coupled then begin
                OnDeletionConflictDetected(IntegrationTableMapping, RecordRef, DeletionConflictHandled);
                if not DeletionConflictHandled then
                    OnDeletionConflictDetectedSetRecordStateAndSynchAction(IntegrationTableMapping, RecordRef, CoupledRecordRef, RecordState, SynchAction, DeletionConflictHandled);

                if not DeletionConflictHandled then begin
                    RecordState := RecordState::NotFound;
                    SynchAction := SynchActionType::Fail;
                    LogSynchError(RecordRef, CoupledRecordRef, StrSubstNo(CoupledRecordIsDeletedErr, RecordRef.Caption), JobId);
                    MarkIntegrationRecordAsFailed(IntegrationTableMapping, RecordRef, JobId, IntegrationTableConnectionType, SynchAction);
                end else
                    case IntegrationTableMapping."Deletion-Conflict Resolution" of
                        IntegrationTableMapping."Deletion-Conflict Resolution"::"Restore Records":
                            begin
                                PrepareNewDestination(IntegrationTableMapping, RecordRef, CoupledRecordRef);
                                RecordState := RecordState::Coupled;
                                SynchAction := SynchActionType::Insert;
                            end;

                        IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling":
                            begin
                                RecordState := RecordState::Decoupled;
                                SynchAction := SynchActionType::None;
                            end;

                        IntegrationTableMapping."Deletion-Conflict Resolution"::None:
                            OnDeletionConflictSetSynchAction(IntegrationTableMapping, RecordRef, SynchAction, SetSynchActionHandled);
                    end;
            end;

        exit(RecordState);
    end;

    internal procedure FindRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsDestinationDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType): Integer
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IDFieldRef: FieldRef;
        RecordIDValue: RecordID;
        RecordState: Option NotFound,Coupled,Decoupled;
        RecordFound: Boolean;
        Direction: Option;
    begin
        if IntegrationTableMapping.Direction <> IntegrationTableMapping.Direction::Bidirectional then
            Direction := IntegrationTableMapping.Direction
        else
            if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
                Direction := IntegrationTableMapping.Direction::ToIntegrationTable
            else
                Direction := IntegrationTableMapping.Direction::FromIntegrationTable;

        if Direction = IntegrationTableMapping.Direction::ToIntegrationTable then // NAV -> Integration Table synch
            RecordFound :=
              FindIntegrationTableRecord(
                IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsDestinationDeleted, IntegrationTableConnectionType)
        else begin  // Integration Table -> NAV synch
            IDFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            RecordFound :=
            IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(
                IntegrationTableConnectionType, IDFieldRef.Value, IntegrationTableMapping."Table ID", RecordIDValue);
            if RecordFound then
                IsDestinationDeleted := not DestinationRecordRef.Get(RecordIDValue);
        end;
        if RecordFound then
            exit(RecordState::Coupled);

        // If no explicit coupling is found, attempt to find a match based on user data
        if FindAndCoupleDestinationRecord(
             IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsDestinationDeleted, IntegrationTableConnectionType)
        then
            exit(RecordState::Decoupled);
        exit(RecordState::NotFound);
    end;

    internal procedure FindCoupledRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsDestinationDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType): Integer
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IDFieldRef: FieldRef;
        RecordIDValue: RecordID;
        RecordState: Option NotFound,Coupled,Decoupled;
        RecordFound: Boolean;
    begin
        if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
            RecordFound := FindIntegrationTableRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsDestinationDeleted, IntegrationTableConnectionType)
        else begin
            IDFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            RecordFound := IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(IntegrationTableConnectionType, IDFieldRef.Value, IntegrationTableMapping."Table ID", RecordIDValue);
            if RecordFound then
                IsDestinationDeleted := not DestinationRecordRef.Get(RecordIDValue);
        end;

        if RecordFound then
            exit(RecordState::Coupled);

        exit(RecordState::NotFound);
    end;

    local procedure FindAndCoupleDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType) DestinationFound: Boolean
    begin
        OnFindUncoupledDestinationRecord(
          IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, DestinationIsDeleted, DestinationFound);
        if DestinationFound then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobIdContext);
        end;
    end;

    local procedure FindIntegrationTableRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsDestinationDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType) FoundDestination: Boolean
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IDValueVariant: Variant;
    begin
        FoundDestination :=
          IntegrationRecordManagement.FindIntegrationTableUIdByRecordRef(IntegrationTableConnectionType, SourceRecordRef, IDValueVariant);

        if FoundDestination then
            IsDestinationDeleted := not IntegrationTableMapping.GetRecordRef(IDValueVariant, DestinationRecordRef);
    end;

    procedure PrepareNewDestination(var IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef; var CoupledRecordRef: RecordRef)
    begin
        CoupledRecordRef.Close();

        if RecordRef.Number = IntegrationTableMapping."Table ID" then
            CoupledRecordRef.Open(IntegrationTableMapping."Integration Table ID")
        else
            CoupledRecordRef.Open(IntegrationTableMapping."Table ID");

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

    [Scope('OnPrem')]
    procedure CheckTransferFields(var IntegrationRecordSynch: Codeunit "Integration Record Synch."; IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var FieldsModified: Boolean; var BidirectionalFieldsModified: Boolean)
    var
        CDSTransformationRuleMgt: Codeunit "CDS Transformation Rule Mgt.";
        AdditionalFieldsModified: Boolean;
    begin
        OnBeforeTransferRecordFields(SourceRecordRef, DestinationRecordRef);
        CDSTransformationRuleMgt.ApplyTransformations(SourceRecordRef, DestinationRecordRef, IntegrationTableMapping);
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, true);
        Commit();
        if IntegrationRecordSynch.Run() then begin
            if IntegrationRecordSynch.GetWasModified() then
                FieldsModified := true;
            if IntegrationRecordSynch.GetWasBidirectionalFieldModified() then
                BidirectionalFieldsModified := true;
            if BidirectionalFieldsModified then
                exit;
        end;
        OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsModified, true);
        if AdditionalFieldsModified then
            FieldsModified := true;
    end;

    local procedure TransferFields(var IntegrationRecordSynch: Codeunit "Integration Record Synch."; IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; var AdditionalFieldsModified: Boolean; JobId: Guid; BothModified: Boolean)
    var
        CDSTransformationRuleMgt: Codeunit "CDS Transformation Rule Mgt.";
    begin
        OnBeforeTransferRecordFields(SourceRecordRef, DestinationRecordRef);

        CDSTransformationRuleMgt.ApplyTransformations(SourceRecordRef, DestinationRecordRef, IntegrationTableMapping);
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, SynchAction <> SynchActionType::Insert);
        if IntegrationRecordSynch.Run() then begin
            if BothModified and IntegrationRecordSynch.GetWasBidirectionalFieldModified() then
                exit;
            OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef,
              AdditionalFieldsModified, SynchAction <> SynchActionType::Insert);
        end else begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(
              SourceRecordRef, DestinationRecordRef,
              StrSubstNo(CopyDataErr, RemoveTrailingDots(GetLastErrorText)), JobId);
            MarkIntegrationRecordAsFailed(IntegrationTableMappingContext, SourceRecordRef, JobId, IntegrationTableConnectionTypeContext, SynchAction);
            Commit();
        end;
    end;

    procedure MarkIntegrationRecordAsFailed(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        SynchAction: Option;
    begin
        SynchAction := SynchActionType::Fail;
        MarkIntegrationRecordAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, IntegrationTableConnectionType, SynchAction);
    end;

    procedure MarkIntegrationRecordAsFailed(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; JobId: Guid; IntegrationTableConnectionType: TableConnectionType; ForceMarkAsSkipped: Boolean)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        DirectionToIntTable: Boolean;
    begin
        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::Dataverse then
            if CRMIntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
                exit;

        DirectionToIntTable := IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationRecordManagement.MarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecordRef, DirectionToIntTable, JobId, ForceMarkAsSkipped);
    end;

    procedure MarkIntegrationRecordAsFailed(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; JobId: Guid; IntegrationTableConnectionType: TableConnectionType; var SyncAction: Option)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        DirectionToIntTable: Boolean;
        MarkedAsSkipped: Boolean;
    begin
        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::Dataverse then
            if CRMIntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
                exit;

        DirectionToIntTable := IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable;
        MarkedAsSkipped := SyncAction = SynchActionType::Skip;
        IntegrationRecordManagement.MarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecordRef, DirectionToIntTable, JobId, MarkedAsSkipped);
        if MarkedAsSkipped then
            SyncAction := SynchActionType::Skip;
    end;

    local procedure UpdateIntegrationRecordCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType)
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
        IsHandled: Boolean;
    begin
        OnUpdateIntegrationRecordCoupling(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsHandled, IntegrationTableConnectionType);
        if IsHandled then
            exit;

        if SourceRecordRef.Number() = IntegrationTableMapping."Table ID" then begin
            LocalRecordRef := SourceRecordRef;
            IntegrationRecordRef := DestinationRecordRef;
        end else begin
            LocalRecordRef := DestinationRecordRef;
            IntegrationRecordRef := SourceRecordRef;
        end;

        IntegrationTableUidFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value();

        IntegrationRecordManagement.UpdateIntegrationTableCoupling(
          IntegrationTableConnectionType, IntegrationTableUid, LocalRecordRef);
    end;

    local procedure UpdateIntegrationRecordTimestamp(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType; JobID: Guid)
    begin
        UpdateIntegrationRecordTimestamp(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobID, false);
    end;

    local procedure UpdateIntegrationRecordTimestamp(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType; JobID: Guid; BothModified: Boolean)
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
        IntegrationTableModifiedOn: DateTime;
        LocalTableModifiedOn: DateTime;
        DirectionToIntTable: Boolean;
        IsHandled: Boolean;
    begin
        OnUpdateIntegrationRecordTimestamp(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobID, BothModified, IsHandled);
        if IsHandled then
            exit;

        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::Dataverse then
            if CRMIntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
                exit;

        DirectionToIntTable := SourceRecordRef.Number() = IntegrationTableMapping."Table ID";
        if DirectionToIntTable then begin
            LocalRecordRef := SourceRecordRef;
            IntegrationRecordRef := DestinationRecordRef;
        end else begin
            LocalRecordRef := DestinationRecordRef;
            IntegrationRecordRef := SourceRecordRef;
        end;

        IntegrationTableUidFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value();
        IntegrationTableModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, IntegrationRecordRef);
        LocalTableModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, LocalRecordRef);
        if BothModified then
            // adjust time to let sync in back direction
            if DirectionToIntTable then
                IntegrationTableModifiedOn -= 999
            else
                LocalTableModifiedOn -= 10;

        IntegrationRecordManagement.UpdateIntegrationTableTimestamp(
          IntegrationTableConnectionType, IntegrationTableUid, IntegrationTableModifiedOn,
          LocalRecordRef.Number(), LocalTableModifiedOn, JobID, IntegrationTableMapping.Direction);
        Commit();
    end;

    local procedure RemoveTrailingDots(Message: Text): Text
    begin
        exit(DelChr(Message, '>', '.'));
    end;

    internal procedure FindTableConfigTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef): Code[10]
    var
        TableConfigTemplate: Record "Table Config Template";
        SearchRecordRef: RecordRef;
        SearchFieldRef: FieldRef;
        TableConfigTemplateFilter: Text;
    begin
        if IntegrationTableMapping."Parent Name" <> '' then
            TableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMapping."Parent Name")
        else
            TableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        TableConfigTemplate.SetCurrentKey(Priority);
        TableConfigTemplate.SetAscending(Priority, true);
        if TableConfigTemplate.FindSet() then
            repeat
                TableConfigTemplateFilter := TableConfigTemplate.GetIntegrationTableFilter();
                if TableConfigTemplateFilter = '' then
                    exit(TableConfigTemplate."Table Config Template Code");

                SearchRecordRef.Open(SourceRecordRef.Number);
                SearchRecordRef.SetView(TableConfigTemplateFilter);
                SearchFieldRef := SearchRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
                SearchFieldRef.SetRange(SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value());
                if not SearchRecordRef.IsEmpty() then
                    exit(TableConfigTemplate."Table Config Template Code");
                SearchRecordRef.Close();
            until TableConfigTemplate.Next() = 0;
    end;

    internal procedure FindIntTableConfigTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef): Code[10]
    var
        IntTableConfigTemplate: Record "Int. Table Config Template";
        SearchRecordRef: RecordRef;
        SearchFieldRef: FieldRef;
        IntTableConfigTemplateFilter: Text;
    begin
        if IntegrationTableMapping."Parent Name" <> '' then
            IntTableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMapping."Parent Name")
        else
            IntTableConfigTemplate.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntTableConfigTemplate.SetCurrentKey(Priority);
        IntTableConfigTemplate.SetAscending(Priority, true);
        if IntTableConfigTemplate.FindSet() then
            repeat
                IntTableConfigTemplateFilter := IntTableConfigTemplate.GetTableFilter();
                if IntTableConfigTemplateFilter = '' then
                    exit(IntTableConfigTemplate."Int. Tbl. Config Template Code");

                SearchRecordRef.Open(SourceRecordRef.Number);
                SearchRecordRef.SetView(IntTableConfigTemplateFilter);
                SearchFieldRef := SearchRecordRef.Field(SourceRecordRef.SystemIdNo);
                SearchFieldRef.SetRange(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value());
                if not SearchRecordRef.IsEmpty() then
                    exit(IntTableConfigTemplate."Int. Tbl. Config Template Code");
                SearchRecordRef.Close();
            until IntTableConfigTemplate.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var UpdateConflictHandled: Boolean; var SkipRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletionConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DeletionConflictHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletionConflictSetSynchAction(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var SynchAction: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple; var SetSynchActionHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletionConflictDetectedSetRecordStateAndSynchAction(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var CoupledRecordRef: RecordRef; var RecordState: Option NotFound,Coupled,Decoupled; var SynchAction: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple; var DeletionConflictHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRecordFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean)
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
    local procedure OnErrorWhenModifyingRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var InsertWithSystemId: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyRecordTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var TemplateCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDetermineConfigTemplateCode(IntegrationTableMapping: Record "Integration Table Mapping"; var TemplateCode: Code[10]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyRecordTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUncoupledDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateIntegrationRecordCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsHandled: Boolean; IntegrationTableConnectionType: TableConnectionType)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWasModifiedAfterLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var SourceWasChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateIntegrationRecordTimestamp(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType; JobID: Guid; BothModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIgnoreUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordOnAfterApplyConfigTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordREf; var DestinationRecordRef: RecordRef)
    begin
    end;
}

