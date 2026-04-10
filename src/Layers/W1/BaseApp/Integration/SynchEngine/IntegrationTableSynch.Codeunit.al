// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;

codeunit 5335 "Integration Table Synch."
{

    trigger OnRun()
    begin
    end;

    var
        CurrentIntegrationSynchJob: Record "Integration Synch. Job";
        CurrentIntegrationTableMapping: Record "Integration Table Mapping";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationTableConnectionType: TableConnectionType;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        SynchJobType: Option Synchronization,Ucoupling,Coupling;
        JobState: Option Ready,Created,"In Progress";
        JobQueueLogEntryNo: Integer;

        IntegrationTableMappingHasNoMappedFieldsErr: Label 'There are no field mapping rows for the %2 %3 in the %1 table.', Comment = '%1="Integration Field Mapping" table caption, %2="Integration Field Mapping.Integration Table Mapping Name" field caption, %3 Integration Table Mapping value';
        UnableToDetectSynchDirectionErr: Label 'The synchronization direction cannot be determined.';
        MappingDoesNotAllowDirectionErr: Label 'The %1 %2 is not configured for %3 synchronization.', Comment = '%1 = Integration Table Mapping caption, %2 Integration Table Mapping Name, %3 = the calculated synch. direction (FromIntegrationTable|ToIntegrationTable)';
        InvalidStateErr: Label 'The synchronization process is in a state that is not valid.';
        DirectionChangeIsNotSupportedErr: Label 'You cannot change the synchronization direction after a job has started.';
#pragma warning disable AA0470
        TablesDoNotMatchMappingErr: Label 'Source table %1 and destination table %2 do not match integration table mapping %3.', Comment = '%1,%2 - tables Ids; %2 - name of the mapping.';
#pragma warning restore AA0470

    procedure BeginIntegrationSynchJob(ConnectionType: TableConnectionType; var IntegrationTableMapping: Record "Integration Table Mapping"; SourceTableID: Integer) JobID: Guid
    begin
        exit(BeginIntegrationSynchJob(ConnectionType, IntegrationTableMapping, SourceTableID, SynchJobType::Synchronization));
    end;

    procedure BeginIntegrationUncoupleJob(ConnectionType: TableConnectionType; var IntegrationTableMapping: Record "Integration Table Mapping"; SourceTableID: Integer) JobID: Guid
    begin
        exit(BeginIntegrationSynchJob(ConnectionType, IntegrationTableMapping, SourceTableID, SynchJobType::Ucoupling));
    end;

    procedure BeginIntegrationCoupleJob(ConnectionType: TableConnectionType; var IntegrationTableMapping: Record "Integration Table Mapping"; SourceTableID: Integer) JobID: Guid
    begin
        exit(BeginIntegrationSynchJob(ConnectionType, IntegrationTableMapping, SourceTableID, SynchJobType::Coupling));
    end;

    local procedure BeginIntegrationSynchJob(ConnectionType: TableConnectionType; var IntegrationTableMapping: Record "Integration Table Mapping"; SourceTableID: Integer; JobType: Option) JobID: Guid
    var
        DirectionIsDefined: Boolean;
        ErrorMessage: Text;
    begin
        EnsureState(JobState::Ready);

        Clear(CurrentIntegrationSynchJob);
        Clear(CurrentIntegrationTableMapping);

        IntegrationTableConnectionType := ConnectionType;
        CurrentIntegrationTableMapping := IntegrationTableMapping;
        JobQueueLogEntryNo := IntegrationTableMapping.GetJobLogEntryNo();
        if JobType = SynchJobType::Synchronization then
            DirectionIsDefined := DetermineSynchDirection(SourceTableID, ErrorMessage)
        else
            DirectionIsDefined := true;

        JobID := InitIntegrationSynchJob(JobType);
        if not IsNullGuid(JobID) then begin
            JobState := JobState::Created;
            OnAfterInitSynchJob(IntegrationTableConnectionType, IntegrationTableMapping."Integration Table ID");
            if not DirectionIsDefined then
                FinishIntegrationSynchJob(ErrorMessage);
        end;
    end;

    procedure BeginIntegrationSynchJobLoging(ConnectionType: TableConnectionType; CodeunitID: Integer; JobLogEntryNo: Integer; TableID: Integer) JobID: Guid
    begin
        EnsureState(JobState::Ready);

        Clear(CurrentIntegrationSynchJob);
        Clear(CurrentIntegrationTableMapping);

        IntegrationTableConnectionType := ConnectionType;
        JobQueueLogEntryNo := JobLogEntryNo;
        CurrentIntegrationTableMapping."Table ID" := TableID;
        CurrentIntegrationTableMapping.Name := Format(CodeunitID);
        CurrentIntegrationTableMapping.Direction := CurrentIntegrationTableMapping.Direction::ToIntegrationTable;

        JobID := InitIntegrationSynchJob(SynchJobType::Synchronization);
        if not IsNullGuid(JobID) then begin
            JobState := JobState::Created;
            OnAfterInitSynchJob(IntegrationTableConnectionType, CurrentIntegrationTableMapping."Integration Table ID");
        end;
    end;

    procedure CheckTransferFields(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var FieldsModified: Boolean; var BidirectionalFieldsModified: Boolean)
    var
        TempTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        Direction: Option;
        EmptyGuid: Guid;
    begin
        OnBeforeCheckTransferFields(SourceRecordRef, DestinationRecordRef, FieldsModified, BidirectionalFieldsModified);
        if BidirectionalFieldsModified then
            exit;

        if SourceRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then
            Direction := IntegrationTableMapping.Direction::FromIntegrationTable
        else
            Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        BuildTempIntegrationFieldMapping(IntegrationTableMapping, Direction, TempTempIntegrationFieldMapping);
        IntegrationRecordSynch.SetFieldMapping(TempTempIntegrationFieldMapping);
        IntegrationRecSynchInvoke.SetContext(
          IntegrationTableMapping, SourceRecordRef, DestinationRecordRef,
          IntegrationRecordSynch, SynchActionType::ForceModify, false, EmptyGuid,
          IntegrationTableConnectionType);
        IntegrationRecSynchInvoke.CheckTransferFields(IntegrationRecordSynch, IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, FieldsModified, BidirectionalFieldsModified);
    end;

    procedure Synchronize(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ForceModify: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        SynchAction: Option;
        IsHandled: Boolean;
    begin
        OnBeforeSynchronize(SourceRecordRef, DestinationRecordRef, ForceModify, IgnoreSynchOnlyCoupledRecords, IsHandled);
        if IsHandled then
            exit(true);

        if not DoesSourceMatchMapping(SourceRecordRef.Number) then begin
            FinishIntegrationSynchJob(
              StrSubstNo(
                TablesDoNotMatchMappingErr, SourceRecordRef.Number, DestinationRecordRef.Number, CurrentIntegrationTableMapping.GetName()));
            exit(false);
        end;

        EnsureState(JobState::Created);
        // Ready to synch.
        Commit();

        // First synch. fixes direction
        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);

            BuildTempIntegrationFieldMapping(
              CurrentIntegrationTableMapping, CurrentIntegrationTableMapping.Direction, TempIntegrationFieldMapping);
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        if ForceModify then
            SynchAction := SynchActionType::ForceModify
        else
            SynchAction := SynchActionType::Skip;

        if SourceRecordRef.Count <> 0 then begin
            if IsRecordSkipped(SourceRecordRef, CurrentIntegrationTableMapping.Direction = CurrentIntegrationTableMapping.Direction::ToIntegrationTable) then
                SynchAction := SynchActionType::Skip
            else begin
                IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
                IntegrationRecSynchInvoke.SetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef,
                  IntegrationRecordSynch, SynchAction, IgnoreSynchOnlyCoupledRecords, CurrentIntegrationSynchJob.ID,
                  IntegrationTableConnectionType);
                if not IntegrationRecSynchInvoke.Run() then begin
                    SynchAction := SynchActionType::Fail;
                    LogSynchError(SourceRecordRef, DestinationRecordRef, GetLastErrorText(), false);
                    IntegrationRecSynchInvoke.MarkIntegrationRecordAsFailed(
                      CurrentIntegrationTableMapping, SourceRecordRef, CurrentIntegrationSynchJob.ID, IntegrationTableConnectionType, SynchAction);
                    IncrementSynchJobCounters(SynchAction);
                    exit(false);
                end;
                IntegrationRecSynchInvoke.GetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationRecordSynch, SynchAction);
            end;
            IncrementSynchJobCounters(SynchAction);
        end;

        exit(true);
    end;

    procedure Uncouple(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        IntRecUncoupleInvoke: Codeunit "Int. Rec. Uncouple Invoke";
        SynchAction: Option;
        LocalRecordModified: Boolean;
        IntegrationRecordModified: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUncouple(LocalRecordRef, IntegrationRecordRef, IsHandled);
        if IsHandled then
            exit(true);

        EnsureState(JobState::Created);
        Commit();

        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);
            TempIntegrationFieldMapping.Reset();
            TempIntegrationFieldMapping.DeleteAll();
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        SynchAction := SynchActionType::Uncouple;

        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping); // set empty field mapping
        IntRecUncoupleInvoke.SetContext(
            CurrentIntegrationTableMapping, LocalRecordRef, IntegrationRecordRef,
            SynchAction, LocalRecordModified, IntegrationRecordModified, CurrentIntegrationSynchJob.ID, IntegrationTableConnectionType);
        if not IntRecUncoupleInvoke.Run() then begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(LocalRecordRef, IntegrationRecordRef, GetLastErrorText());
            exit(false);
        end;
        IntRecUncoupleInvoke.GetContext(
            CurrentIntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified);
        if LocalRecordModified or IntegrationRecordModified then
            IncrementSynchJobCounters(SynchActionType::Modify);
        IncrementSynchJobCounters(SynchAction);

        exit(true);
    end;

    procedure Couple(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        IntRecCoupleInvoke: Codeunit "Int. Rec. Couple Invoke";
        SynchAction: Option;
        LocalRecordModified: Boolean;
        IntegrationRecordModified: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCouple(LocalRecordRef, IntegrationRecordRef, IsHandled);
        if IsHandled then
            exit(true);

        EnsureState(JobState::Created);
        Commit();

        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);
            TempIntegrationFieldMapping.Reset();
            TempIntegrationFieldMapping.DeleteAll();
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        SynchAction := SynchActionType::Couple;

        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping); // set empty field mapping
        IntRecCoupleInvoke.SetContext(
            CurrentIntegrationTableMapping, LocalRecordRef, IntegrationRecordRef,
            SynchAction, LocalRecordModified, IntegrationRecordModified, CurrentIntegrationSynchJob.ID, IntegrationTableConnectionType);
        if not IntRecCoupleInvoke.Run() then begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(LocalRecordRef, IntegrationRecordRef, GetLastErrorText());
            exit(false);
        end;
        IntRecCoupleInvoke.GetContext(
            CurrentIntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified);
        if LocalRecordModified or IntegrationRecordModified then
            IncrementSynchJobCounters(SynchActionType::Modify);
        IncrementSynchJobCounters(SynchAction);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CoupleOption(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        SynchAction: Option;
    begin
        EnsureState(JobState::Created);
        Commit();

        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);
            TempIntegrationFieldMapping.Reset();
            TempIntegrationFieldMapping.DeleteAll();
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        SynchAction := SynchActionType::Couple;

        if not CRMOptionMapping.InsertRecord(LocalRecordRef.RecordId, CRMOptionMapping.GetRecordRefOptionId(IntegrationRecordRef), CRMOptionMapping.GetRecordRefOptionValue(IntegrationRecordRef)) then begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(LocalRecordRef, IntegrationRecordRef, GetLastErrorText());
            exit(false);
        end;

        IncrementSynchJobCounters(SynchAction);
        exit(true);
    end;

    procedure LogMatchBasedCouplingError(var LocalRecordRef: RecordRef; ErrorMessage: Text)
    var
        IntegrationRecordRef: RecordRef;
    begin
        EnsureState(JobState::Created);
        Commit();

        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);
            TempIntegrationFieldMapping.Reset();
            TempIntegrationFieldMapping.DeleteAll();
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        LogSynchError(LocalRecordRef, IntegrationRecordRef, ErrorMessage);
    end;

    procedure Delete(RecRef: RecordRef): Boolean
    var
        IntegrationRecDeleteInvoke: Codeunit "Integration Rec. Delete Invoke";
        SynchDirection: Option;
        SynchAction: Option;
    begin
        EnsureState(JobState::Created);

        JobState := JobState::"In Progress";
        case RecRef.Number of
            CurrentIntegrationTableMapping."Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::FromIntegrationTable;
            CurrentIntegrationTableMapping."Integration Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::ToIntegrationTable;
        end;
        CurrentIntegrationSynchJob.Modify(true);
        Commit();
        SynchAction := SynchActionType::Delete;

        IntegrationRecDeleteInvoke.SetContext(
          CurrentIntegrationTableMapping, RecRef,
          SynchAction, CurrentIntegrationSynchJob.ID);
        if not IntegrationRecDeleteInvoke.Run() then begin
            LogSynchError(RecRef, RecRef, GetLastErrorText);
            exit(false);
        end;
        IntegrationRecDeleteInvoke.GetContext(
          CurrentIntegrationTableMapping, RecRef, SynchAction);

        IncrementSynchJobCounters(SynchAction);

        exit(true);
    end;

    procedure EndIntegrationSynchJob(): Guid
    begin
        exit(EndIntegrationSynchJobWithMsg(''));
    end;

    procedure EndIntegrationSynchJobWithMsg(FinalMessage: Text): Guid
    begin
        if CurrentIntegrationSynchJob."Finish Date/Time" = 0DT then
            FinishIntegrationSynchJob(FinalMessage);

        JobState := JobState::Ready;
        exit(CurrentIntegrationSynchJob.ID);
    end;

    procedure GetRowLastModifiedOn(IntegrationTableMapping: Record "Integration Table Mapping"; FromRecordRef: RecordRef): DateTime
    var
        ModifiedFieldRef: FieldRef;
    begin
        if FromRecordRef.Number = IntegrationTableMapping."Integration Table ID" then begin
            ModifiedFieldRef := FromRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            exit(ModifiedFieldRef.Value);
        end;

        if FromRecordRef.Number() = IntegrationTableMapping."Table ID" then begin
            ModifiedFieldRef := FromRecordRef.Field(FromRecordRef.SystemModifiedAtNo());
            exit(ModifiedFieldRef.Value);
        end;

        exit(0DT);
    end;

    local procedure EnsureState(RequiredState: Option)
    begin
        if (JobState = JobState::"In Progress") and (RequiredState = JobState::Created) then
            exit;

        if RequiredState <> JobState then
            Error(InvalidStateErr);
    end;

    local procedure DetermineSynchDirection(TableID: Integer; var ErrorMessage: Text): Boolean
    var
        DummyIntegrationTableMapping: Record "Integration Table Mapping";
        SynchDirection: Option;
        IsHandled: Boolean;
    begin
        ErrorMessage := '';
        OnDetermineSynchDirection(CurrentIntegrationTableMapping, TableID, ErrorMessage, IsHandled);
        if IsHandled then
            exit(ErrorMessage = '');

        case TableID of
            CurrentIntegrationTableMapping."Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::ToIntegrationTable;
            CurrentIntegrationTableMapping."Integration Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::FromIntegrationTable;
            else begin
                ErrorMessage := UnableToDetectSynchDirectionErr;
                exit(false);
            end;
        end;

        if not (CurrentIntegrationTableMapping.Direction in [SynchDirection, CurrentIntegrationTableMapping.Direction::Bidirectional]) then begin
            DummyIntegrationTableMapping.Direction := SynchDirection;
            ErrorMessage :=
              StrSubstNo(
                MappingDoesNotAllowDirectionErr, CurrentIntegrationTableMapping.TableCaption(), CurrentIntegrationTableMapping.Name,
                DummyIntegrationTableMapping.Direction);
            exit(false);
        end;

        CurrentIntegrationTableMapping.Direction := SynchDirection;
        exit(true);
    end;

    local procedure InitIntegrationSynchJob(JobType: Option): Guid
    var
        JobID: Guid;
    begin
        JobID := CreateIntegrationSynchJobEntry(JobType);
        Commit();
        exit(JobID);
    end;

    local procedure FinishIntegrationSynchJob(FinalMessage: Text)
    begin
        if FinalMessage <> '' then
            CurrentIntegrationSynchJob.Message := CopyStr(FinalMessage, 1, MaxStrLen(CurrentIntegrationSynchJob.Message));
        CurrentIntegrationSynchJob."Finish Date/Time" := CurrentDateTime;
        CurrentIntegrationSynchJob.Modify(true);
        Commit();
    end;

    local procedure CreateIntegrationSynchJobEntry(JobType: Option) JobID: Guid
    begin
        if IsNullGuid(CurrentIntegrationSynchJob.ID) then
            JobID := InsertIntegrationSynchJobEntry(JobType)
        else
            if CurrentIntegrationSynchJob.IsEmpty() then
                JobID := InsertIntegrationSynchJobEntry(JobType);
    end;

    local procedure InsertIntegrationSynchJobEntry(JobType: Option): Guid
    begin
        CurrentIntegrationSynchJob.Reset();
        CurrentIntegrationSynchJob.Init();
        CurrentIntegrationSynchJob.ID := CreateGuid();
        CurrentIntegrationSynchJob."Start Date/Time" := CurrentDateTime;
        CurrentIntegrationSynchJob."Integration Table Mapping Name" := CurrentIntegrationTableMapping.GetName();
        CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
        CurrentIntegrationSynchJob."Job Queue Log Entry No." := JobQueueLogEntryNo;
        CurrentIntegrationSynchJob.Type := JobType;
        CurrentIntegrationSynchJob.Insert(true);
        Commit();
        exit(CurrentIntegrationSynchJob.ID);
    end;

    local procedure BuildTempIntegrationFieldMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; SynchDirection: Option; var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetFilter(Direction, '%1|%2', SynchDirection, IntegrationFieldMapping.Direction::Bidirectional);
        IntegrationFieldMapping.SetFilter(Status, '<>%1', IntegrationFieldMapping.Status::Disabled);
        if IntegrationFieldMapping.IsEmpty() then
            Error(
              IntegrationTableMappingHasNoMappedFieldsErr, IntegrationFieldMapping.TableCaption(),
              IntegrationFieldMapping.FieldCaption("Integration Table Mapping Name"), IntegrationTableMapping.Name);

        TempIntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.FindSet();
        repeat
            TempIntegrationFieldMapping.Init();
            TempIntegrationFieldMapping."No." := IntegrationFieldMapping."No.";
            TempIntegrationFieldMapping."Integration Table Mapping Name" := IntegrationFieldMapping."Integration Table Mapping Name";
            TempIntegrationFieldMapping."Constant Value" := IntegrationFieldMapping."Constant Value";
            TempIntegrationFieldMapping."Not Null" := IntegrationFieldMapping."Not Null";
            if SynchDirection = IntegrationTableMapping.Direction::ToIntegrationTable then begin
                TempIntegrationFieldMapping."Source Field No." := IntegrationFieldMapping."Field No.";
                TempIntegrationFieldMapping."Destination Field No." := IntegrationFieldMapping."Integration Table Field No.";
                TempIntegrationFieldMapping."Validate Destination Field" := IntegrationFieldMapping."Validate Integration Table Fld";
            end else begin
                TempIntegrationFieldMapping."Source Field No." := IntegrationFieldMapping."Integration Table Field No.";
                TempIntegrationFieldMapping."Destination Field No." := IntegrationFieldMapping."Field No.";
                TempIntegrationFieldMapping."Validate Destination Field" := IntegrationFieldMapping."Validate Field";
            end;
            TempIntegrationFieldMapping.Bidirectional := IntegrationFieldMapping.Direction = IntegrationFieldMapping.Direction::Bidirectional;
            TempIntegrationFieldMapping.Insert();
        until IntegrationFieldMapping.Next() = 0;
    end;

    procedure LogSynchError(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ErrorMessage: Text): Guid
    begin
        exit(LogSynchError(SourceRecordRef, DestinationRecordRef, ErrorMessage, true));
    end;

    procedure LogSynchError(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ErrorMessage: Text; UpdateCounter: Boolean): Guid
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SourceRecordID: RecordID;
        DestinationRecordID: RecordID;
    begin
        if UpdateCounter then
            IncrementSynchJobCounters(SynchActionType::Fail);
        if DestinationRecordRef.Number <> 0 then
            DestinationRecordID := DestinationRecordRef.RecordId;
        if SourceRecordRef.Number <> 0 then
            SourceRecordID := SourceRecordRef.RecordId;

        IntegrationSynchJobErrors.LogSynchError(
          CurrentIntegrationSynchJob.ID, SourceRecordID, DestinationRecordID, ErrorMessage);
        exit(CurrentIntegrationSynchJob.ID);
    end;

    procedure IncrementSynchJobCounters(SynchAction: Option)
    begin
        UpdateSynchJobCounters(SynchAction, 1)
    end;

    procedure UpdateSynchJobCounters(SynchAction: Option; Counter: Integer)
    begin
        if Counter = 0 then
            exit;
        case SynchAction of
            SynchActionType::Insert:
                CurrentIntegrationSynchJob.Inserted += Counter;
            SynchActionType::Modify, SynchActionType::ForceModify:
                CurrentIntegrationSynchJob.Modified += Counter;
            SynchActionType::IgnoreUnchanged:
                CurrentIntegrationSynchJob.Unchanged += Counter;
            SynchActionType::Skip:
                CurrentIntegrationSynchJob.Skipped += Counter;
            SynchActionType::Fail:
                CurrentIntegrationSynchJob.Failed += Counter;
            SynchActionType::Delete:
                CurrentIntegrationSynchJob.Deleted += Counter;
            SynchActionType::Uncouple:
                CurrentIntegrationSynchJob.Uncoupled += Counter;
            SynchActionType::Couple:
                CurrentIntegrationSynchJob.Coupled += Counter;
            else
                exit
        end;
        CurrentIntegrationSynchJob.Modify();
        Commit();
    end;

    local procedure DoesSourceMatchMapping(SourceTableID: Integer): Boolean
    begin
        case CurrentIntegrationTableMapping.Direction of
            CurrentIntegrationTableMapping.Direction::ToIntegrationTable:
                exit(SourceTableID = CurrentIntegrationTableMapping."Table ID");
            CurrentIntegrationTableMapping.Direction::FromIntegrationTable:
                exit(SourceTableID = CurrentIntegrationTableMapping."Integration Table ID");
        end;
    end;

    local procedure IsRecordSkipped(RecRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
    begin
        exit(IntegrationRecordManagement.IsIntegrationRecordSkipped(IntegrationTableConnectionType, RecRef, DirectionToIntTable));
    end;

    procedure SynchronizeOption(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ForceModify: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean): Boolean
    var
        IntOptionSynchInvoke: Codeunit "Int. Option Synch. Invoke";
        SynchAction: Option;
        IsHandled: Boolean;
    begin
        OnBeforeSynchronizeOption(SourceRecordRef, DestinationRecordRef, ForceModify, IgnoreSynchOnlyCoupledRecords, IsHandled);
        if IsHandled then
            exit(true);

        EnsureState(JobState::Created);
        // Ready to synch.
        Commit();

        // First synch. fixes direction
        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        if ForceModify then
            SynchAction := SynchActionType::ForceModify
        else
            SynchAction := SynchActionType::Skip;

        if SourceRecordRef.Count <> 0 then begin
            if IsOptionSkipped(SourceRecordRef, SourceRecordRef.Number() = CurrentIntegrationTableMapping."Table ID") then
                SynchAction := SynchActionType::Skip
            else begin
                IntOptionSynchInvoke.SetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, IgnoreSynchOnlyCoupledRecords, CurrentIntegrationSynchJob.ID);
                if not IntOptionSynchInvoke.Run() then begin
                    SynchAction := SynchActionType::Fail;
                    LogSynchError(SourceRecordRef, DestinationRecordRef, GetLastErrorText(), false);
                    IntOptionSynchInvoke.MarkOptionMappingAsFailed(
                      CurrentIntegrationTableMapping, SourceRecordRef, CurrentIntegrationSynchJob.ID, SynchAction);
                    IncrementSynchJobCounters(SynchAction);
                    exit(false);
                end;
                IntOptionSynchInvoke.GetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction);
            end;
            IncrementSynchJobCounters(SynchAction);
        end;

        exit(true);
    end;

    local procedure IsOptionSkipped(RecRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        exit(CRMOptionMapping.IsOptionMappingSkipped(RecRef, DirectionToIntTable));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronize(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var ForceModify: Boolean; var IgnoreSynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizeOption(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var ForceModify: Boolean; var IgnoreSynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var FieldsModified: Boolean; var BidirectionalFieldsModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUncouple(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCouple(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    procedure OnAfterInitSynchJob(ConnectionType: TableConnectionType; IntegrationTableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDetermineSynchDirection(var CurrentIntegrationTableMapping: Record "Integration Table Mapping"; var TableID: Integer; var ErrorMessage: Text; var IsHandled: Boolean)
    begin
    end;
}

