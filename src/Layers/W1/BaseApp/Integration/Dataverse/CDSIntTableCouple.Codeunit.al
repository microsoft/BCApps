// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;

codeunit 5360 "CDS Int. Table Couple"
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        ConnectionName: Text;
        Handled: Boolean;
    begin
        OnBeforeRun(Rec, Handled);
        if Handled then
            exit;

        ConnectionName := CRMIntegrationTableSynch.InitConnection();
        CRMIntegrationTableSynch.TestConnection();

        PerformScheduledCoupling(Rec);

        CRMIntegrationTableSynch.CloseConnection(ConnectionName);
    end;

    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        NoMatchingCriteriaDefinedErr: Label 'You must specify which fields on the table mapping ''%1'' should be used for match-based coupling.', Comment = '%1 - integration table mapping name';
        NoMatchFoundErr: Label 'Failed to couple %2 record(s), because no unique uncoupled matching entity was found in %1 with the specified matching criteria.', Comment = '%1 - comma-separated list of field names, %2 - A URL, %3 - an integer, number of records';
        NoMatchFoundTelemetryErr: Label 'No matching entity was found for %1 in %3 by matching on following fields: %2.', Locked = true;
        SingleMatchAlreadyCoupledTelemetryErr: Label 'Single matching entity was found for %1 in %3 by matching on following fields: %2, but it is already coupled.', Locked = true;
        MultipleMatchesFoundTelemetryErr: Label 'Multiple matching entities found for %1 in %3 by matching on following fields: %2.', Locked = true;
        NoMatchingCriteriaDefinedTelemetryErr: Label 'User is trying to schedule match based coupling for integration table mapping %1 without having specified the matchin criteria.', Locked = true;
        NoConflictResolutionStrategyDefinedTelemetryErr: Label 'User is trying to schedule match based coupling for integration table mapping %1 without having specified the conflict resolution strategy.', Locked = true;
        SkippingPostCouplingSynchTelemetryUserChoiceMsg: Label 'Skipping post-coupling synchronization for integration table mapping %1, because the user chose not to run it.', Locked = true;
        SkippingPostCouplingSynchTelemetryNoneCoupledMsg: Label 'Skipping post-coupling synchronization for integration table mapping %1, because no records were coupled.', Locked = true;
        StartingPostCouplingSynchTelemetryMsg: Label 'Starting post-coupling synchronization for integration table mapping %1, for %2 coupled records.', Locked = true;
        SchedulingPostCouplingSynchForBatchTelemetryMsg: Label 'Scheduling post-coupling synchronization for integration table mapping %1, for a batch of %2 coupled records.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CouplingMsg: Label 'Coupling records...\\Processing record #1##########', Comment = '#1 place holder for record number';
        MappingNameWithParentTxt: Label '%1 (%2)', Locked = true;
        DataverseOrgURL: Text;

    internal procedure PerformScheduledCoupling(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
    begin
        JobId := IntegrationTableSynch.BeginIntegrationCoupleJob(TableConnectionType::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        if not IsNullGuid(JobId) then begin
            if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then
                CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::FromIntegrationTable);
            if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable] then
                CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::ToIntegrationTable);

            CoupleRecords(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob();

            if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then
                CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
            if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable] then
                CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
    end;

    local procedure CoupleRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempMatchingIntegrationFieldMapping: Record "Integration Field Mapping" temporary;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        EmptyRecordRef: RecordRef;
        MatchingIntegrationRecordFieldRef: FieldRef;
        MatchingLocalFieldRef: FieldRef;
        CoupledToCRMFieldRef: FieldRef;
        IntegrationRecordIdFieldRef: FieldRef;
        IntegrationRecordKeyRef: KeyRef;
        SetMatchingFieldFilterHandled: Boolean;
        MatchingFieldCount: Integer;
        MatchCount: Integer;
        UnmatchedSystemIdsDictionary: Dictionary of [Code[20], List of [Guid]];
        UnmatchedSystemIds: List of [Guid];
        CoupledSystemIds: List of [Guid];
        CoupledCRMIds: List of [Guid];
        LocalRecordSystemId: Guid;
        RecordNumber: Integer;
        Dialog: Dialog;
        TableFilter: Text;
        FilterList: List of [Text];
        MatchPriorityList: List of [Integer];
        MatchPriority: Integer;
    begin
        // collect the matching criteria fields in a temporary record
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Use For Match-Based Coupling", true);
        IntegrationFieldMapping.SetCurrentKey("Match Priority");
        IntegrationFieldMapping.SetAscending("Match Priority", true);
        if IntegrationFieldMapping.FindSet() then
            repeat
                TempMatchingIntegrationFieldMapping.Init();
                TempMatchingIntegrationFieldMapping.TransferFields(IntegrationFieldMapping);
                TempMatchingIntegrationFieldMapping.Insert();
                if not MatchPriorityList.Contains(TempMatchingIntegrationFieldMapping."Match Priority") then
                    MatchPriorityList.Add(TempMatchingIntegrationFieldMapping."Match Priority");
            until IntegrationFieldMapping.Next() = 0
        else begin
            Session.LogMessage('0000EZF', StrSubstNo(NoMatchingCriteriaDefinedTelemetryErr, GetMappingNameWithParent(IntegrationTableMapping)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            IntegrationTableSynch.LogMatchBasedCouplingError(LocalRecordRef, StrSubstNo(NoMatchingCriteriaDefinedErr, IntegrationTableMapping.GetUserFriendlyMappingName()));
            exit;
        end;

        if GuiAllowed() then begin
            Dialog.Open(CouplingMsg);
            Dialog.Update(1, '');
        end;

        // iterate through uncoupled records and for each of them try to find a match in Dataverse
        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
        IntegrationRecordSynch.SplitLocalTableFilter(IntegrationTableMapping, FilterList);
        foreach TableFilter in FilterList do begin
            if TableFilter <> '' then
                LocalRecordRef.SetView(TableFilter);
            if CRMIntegrationManagement.FindCoupledToCRMField(LocalRecordRef, CoupledToCRMFieldRef) then begin
                CoupledToCRMFieldRef.CalcField();
                CoupledToCRMFieldRef.SetRange(false);
            end;
            if LocalRecordRef.FindSet() then
                repeat
                    if GuiAllowed() then begin
                        RecordNumber += 1;
                        Dialog.Update(1, RecordNumber);
                    end;
                    LocalRecordSystemId := LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value();
                    // re-check that the record is uncoupled as it could just be coupled by another job
                    if CRMIntegrationRecord.IsIntegrationIdCoupled(LocalRecordSystemId, LocalRecordRef.Number) then begin
                        Session.LogMessage('0000F7F', GetSingleMatchAlreadyCoupledTelemetryErrorMessage(LocalRecordRef, TempMatchingIntegrationFieldMapping), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        CoupledSystemIds.Add(LocalRecordSystemId)
                    end else begin
                        Clear(IntegrationRecordRef);
                        IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                        IntegrationTableMapping.SetIntRecordRefFilter(IntegrationRecordRef);
                        // this inner loop is looping through a temporary record set with a handful of user-chosen matching fields - not a performance concern as such
                        foreach MatchPriority in MatchPriorityList do
                            if not CoupledSystemIds.Contains(LocalRecordSystemId) then begin
                                MatchingFieldCount := 0;
                                MatchCount := 0;
                                TempMatchingIntegrationFieldMapping.Reset();
                                TempMatchingIntegrationFieldMapping.SetRange("Match Priority", MatchPriority);
                                TempMatchingIntegrationFieldMapping.FindSet();
                                repeat
                                    // initialize the fields that we should match on
                                    MatchingIntegrationRecordFieldRef := IntegrationRecordRef.Field(TempMatchingIntegrationFieldMapping."Integration Table Field No.");
                                    MatchingLocalFieldRef := LocalRecordRef.Field(TempMatchingIntegrationFieldMapping."Field No.");

                                    // raise an event so that custom filtering logic can be implemented (depending on which record and which fields are chosen as the matching field)
                                    SetMatchingFieldFilterHandled := false;
                                    OnBeforeSetMatchingFilter(IntegrationRecordRef, MatchingIntegrationRecordFieldRef, LocalRecordRef, MatchingLocalFieldRef, SetMatchingFieldFilterHandled);

                                    // if nobody implemented custom filtering, apply default filtering logic
                                    // and that is: set the filter on the integration table field with the value of the local field (case sensitive if specified by user)
                                    if not SetMatchingFieldFilterHandled then
                                        case MatchingLocalFieldRef.Type of
                                            FieldType::Code,
                                            FieldType::Text:
                                                if Format(MatchingLocalFieldRef.Value()) <> '' then begin
                                                    if not TempMatchingIntegrationFieldMapping."Case-Sensitive Matching" then
                                                        MatchingIntegrationRecordFieldRef.SetFilter('''@' + Format(MatchingLocalFieldRef.Value()).Replace('''', '''''') + '''')
                                                    else
                                                        MatchingIntegrationRecordFieldRef.SetRange(MatchingLocalFieldRef.Value());
                                                    MatchingFieldCount += 1;
                                                end;
                                            else begin
                                                MatchingIntegrationRecordFieldRef.SetRange(MatchingLocalFieldRef.Value());
                                                MatchingFieldCount += 1;
                                            end;
                                        end;
                                until TempMatchingIntegrationFieldMapping.Next() = 0;

                                // if there is exactly one match, and it is not coupled, couple it. otherwise - log a synch error
                                if (MatchingFieldCount > 0) or SetMatchingFieldFilterHandled then
                                    MatchCount := IntegrationRecordRef.Count();
                                case MatchCount of
                                    0:
                                        begin
                                            Session.LogMessage('0000EZG', GetNoMatchFoundTelemetryErrorMessage(LocalRecordRef, TempMatchingIntegrationFieldMapping), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                                            if not UnmatchedSystemIds.Contains(LocalRecordSystemId) then
                                                UnmatchedSystemIds.Add(LocalRecordSystemId);
                                        end;
                                    1:
                                        begin
                                            IntegrationRecordRef.FindFirst();
                                            if CRMIntegrationRecord.IsCRMRecordRefCoupled(IntegrationRecordRef) then begin
                                                Session.LogMessage('0000EZH', GetSingleMatchAlreadyCoupledTelemetryErrorMessage(LocalRecordRef, TempMatchingIntegrationFieldMapping), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                                                if not UnmatchedSystemIds.Contains(LocalRecordSystemId) then
                                                    UnmatchedSystemIds.Add(LocalRecordSystemId);
                                            end else
                                                if IntegrationTableSynch.Couple(LocalRecordRef, IntegrationRecordRef) then begin
                                                    CoupledSystemIds.Add(LocalRecordSystemId);
                                                    if UnmatchedSystemIds.Contains(LocalRecordSystemId) then
                                                        UnmatchedSystemIds.Remove(LocalRecordSystemId);
                                                    IntegrationRecordKeyRef := IntegrationRecordRef.KeyIndex(1); // Primary Key
                                                    IntegrationRecordIdFieldRef := IntegrationRecordKeyRef.FieldIndex(1);
                                                    CoupledCRMIds.Add(IntegrationRecordIdFieldRef.Value());
                                                end;
                                        end;
                                    else begin
                                        Session.LogMessage('0000EZI', GetMultipleMatchesFoundTelemetryErrorMessage(LocalRecordRef, TempMatchingIntegrationFieldMapping), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                                        if not UnmatchedSystemIds.Contains(LocalRecordSystemId) then
                                            UnmatchedSystemIds.Add(LocalRecordSystemId);
                                    end;
                                end;
                            end;
                    end;
                until LocalRecordRef.Next() = 0;
            if GuiAllowed then
                Dialog.Update(1, RecordNumber);
        end;

        if GuiAllowed then
            Dialog.Close();

        // if the user chose so, create new entities in Dataverse for records that couldn't be matched
        if UnmatchedSystemIds.Count() > 0 then
            if ShouldCreateNewRecordsInCaseOfNoMatch(IntegrationTableMapping) then begin
                UnmatchedSystemIdsDictionary.Add(IntegrationTableMapping.Name, UnmatchedSystemIds);
                CRMIntegrationManagement.CreateNewRecordsInCRM(UnmatchedSystemIdsDictionary);
            end else begin
                IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Fail, UnmatchedSystemIds.Count());
                IntegrationTableSynch.LogSynchError(EmptyRecordRef, EmptyRecordRef, GetNoMatchFoundErrorMessage(UnmatchedSystemIds.Count()), false);
            end;

        // schedule synch job of coupled records, if user chose to do so
        if IntegrationTableMapping."Synch. After Bulk Coupling" then
            SynchronizeCoupledRecords(IntegrationTableMapping, CoupledSystemIds, CoupledCRMIds)
        else
            Session.LogMessage('0000EZJ', StrSubstNo(SkippingPostCouplingSynchTelemetryUserChoiceMsg, GetMappingNameWithParent(IntegrationTableMapping)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure ShouldCreateNewRecordsInCaseOfNoMatch(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        Handled: Boolean;
        ShouldCreateNewRecord: Boolean;
    begin
        OnShouldCreateNewRecordInCaseOfNoMatch(IntegrationTableMapping, ShouldCreateNewRecord, Handled);
        if Handled then
            exit(ShouldCreateNewRecord);

        case IntegrationTableMapping.Name of
            'SALESPEOPLE':
                exit(false);
            'SALESORDER-ORDER':
                exit(CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() and IntegrationTableMapping."Create New in Case of No Match");
            else
                exit(IntegrationTableMapping."Create New in Case of No Match")
        end;
    end;

    local procedure SynchronizeCoupledRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var CoupledSystemIds: List of [Guid]; var CoupledCRMIds: List of [Guid])
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        Direction: Integer;
    begin
        if CoupledSystemIds.Count() = 0 then begin
            Session.LogMessage('0000EZK', StrSubstNo(SkippingPostCouplingSynchTelemetryNoneCoupledMsg, GetMappingNameWithParent(IntegrationTableMapping)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        Session.LogMessage('0000EZL', StrSubstNo(StartingPostCouplingSynchTelemetryMsg, GetMappingNameWithParent(IntegrationTableMapping), CoupledSystemIds.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        Direction := IntegrationTableMapping.Direction;
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
            case IntegrationTableMapping."Update-Conflict Resolution" of
                IntegrationTableMapping."Update-Conflict Resolution"::"None":
                    Session.LogMessage('0000EZM', StrSubstNo(NoConflictResolutionStrategyDefinedTelemetryErr, GetMappingNameWithParent(IntegrationTableMapping)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                IntegrationTableMapping."Update-Conflict Resolution"::"Get Update from Integration":
                    Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
                IntegrationTableMapping."Update-Conflict Resolution"::"Send Update to Integration":
                    Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            end;

        Session.LogMessage('0000EZN', StrSubstNo(SchedulingPostCouplingSynchForBatchTelemetryMsg, GetMappingNameWithParent(IntegrationTableMapping), CoupledSystemIds.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        CRMIntegrationManagement.EnqueueSyncJob(IntegrationTableMapping, CoupledSystemIds, CoupledCRMIds, Direction, true);
    end;

    local procedure GetNoMatchFoundErrorMessage(ErrorCount: Integer): Text
    begin
        exit(StrSubstNo(NoMatchFoundErr, GetDataverseOrgURL(), ErrorCount));
    end;

    local procedure GetNoMatchFoundTelemetryErrorMessage(var LocalRecordRef: RecordRef; var MatchIntegrationFieldMapping: Record "Integration Field Mapping" temporary): Text
    var
        MatchingFieldNameList: Text;
    begin
        MatchingFieldNameList := GetMatchingFieldNameList(LocalRecordRef, MatchIntegrationFieldMapping);
        exit(StrSubstNo(NoMatchFoundTelemetryErr, Format(LocalRecordRef.Field(LocalRecordRef.SystemIdNo).Value()), MatchingFieldNameList, GetDataverseOrgURL()));
    end;

    local procedure GetMultipleMatchesFoundTelemetryErrorMessage(var LocalRecordRef: RecordRef; var MatchIntegrationFieldMapping: Record "Integration Field Mapping" temporary): Text
    var
        MatchingFieldNameList: Text;
    begin
        MatchingFieldNameList := GetMatchingFieldNameList(LocalRecordRef, MatchIntegrationFieldMapping);
        exit(StrSubstNo(MultipleMatchesFoundTelemetryErr, Format(LocalRecordRef.Field(LocalRecordRef.SystemIdNo).Value()), MatchingFieldNameList, GetDataverseOrgURL()));
    end;

    local procedure GetSingleMatchAlreadyCoupledTelemetryErrorMessage(var LocalRecordRef: RecordRef; var MatchIntegrationFieldMapping: Record "Integration Field Mapping" temporary): Text
    var
        MatchingFieldNameList: Text;
    begin
        MatchingFieldNameList := GetMatchingFieldNameList(LocalRecordRef, MatchIntegrationFieldMapping);
        exit(StrSubstNo(SingleMatchAlreadyCoupledTelemetryErr, Format(LocalRecordRef.Field(LocalRecordRef.SystemIdNo).Value()), MatchingFieldNameList, GetDataverseOrgURL()));
    end;

    local procedure GetMappingNameWithParent(var IntegrationTableMapping: Record "Integration Table Mapping"): Text
    begin
        if IntegrationTableMapping."Parent Name" <> '' then
            exit(StrSubstNo(MappingNameWithParentTxt, IntegrationTableMapping.Name, IntegrationTableMapping."Parent Name"));
        exit(IntegrationTableMapping.Name);
    end;

    local procedure GetMatchingFieldNameList(var LocalRecordRef: RecordRef; var MatchIntegrationFieldMapping: Record "Integration Field Mapping" temporary) MatchingFieldNameList: Text
    begin
        MatchIntegrationFieldMapping.FindSet();
        repeat
            if MatchingFieldNameList = '' then
                MatchingFieldNameList := LocalRecordRef.Field(MatchIntegrationFieldMapping."Field No.").Name()
            else
                MatchingFieldNameList += ', ' + LocalRecordRef.Field(MatchIntegrationFieldMapping."Field No.").Name()
        until MatchIntegrationFieldMapping.Next() = 0;
    end;

    local procedure GetDataverseOrgURL(): Text
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if DataverseOrgURL <> '' then
            exit(DataverseOrgURL);

        if CRMConnectionSetup.IsEnabled() then
            DataverseOrgURL := CRMConnectionSetup."Server Address"
        else
            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup."Is Enabled" then
                    DataverseOrgURL := CDSConnectionSetup."Server Address";

        exit(DataverseOrgURL);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(IntegrationTableMapping: Record "Integration Table Mapping"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetMatchingFilter(var IntegrationRecordRef: RecordRef; var MatchingIntegrationRecordFieldRef: FieldRef; var LocalRecordRef: RecordRef; var MatchingLocalFieldRef: FieldRef; var SetMatchingFilterHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShouldCreateNewRecordInCaseOfNoMatch(var IntegrationTableMapping: Record "Integration Table Mapping"; var ShouldCreateNewRecord: Boolean; var Handled: Boolean)
    begin
    end;
}
