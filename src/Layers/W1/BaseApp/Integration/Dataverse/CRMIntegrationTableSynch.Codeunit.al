// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Reflection;
using System.Threading;
using System.Utilities;

codeunit 5340 "CRM Integration Table Synch."
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        "Field": Record "Field";
        OriginalJobQueueEntry: Record "Job Queue Entry";
        ConnectionName: Text;
        LatestModifiedOn: array[2] of DateTime;
        isHandled: Boolean;
        PrevStatus: Option;
        MappingName: Code[20];
    begin
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        ConnectionName := InitConnection();
        TestConnection();

        if Rec."Int. Table UID Field Type" = Field.Type::Option then
            SynchOption(Rec)
        else begin
            Rec.SetOriginalJobQueueEntryOnHold(OriginalJobQueueEntry, PrevStatus);
            if Rec.Direction in [Rec.Direction::ToIntegrationTable, Rec.Direction::Bidirectional] then
                LatestModifiedOn[DateType::Local] := PerformScheduledSynchToIntegrationTable(Rec);
            if Rec.Direction in [Rec.Direction::FromIntegrationTable, Rec.Direction::Bidirectional] then
                LatestModifiedOn[DateType::Integration] := PerformScheduledSynchFromIntegrationTable(Rec);
            MappingName := Rec.Name;
            if not Rec.Find() then
                Session.LogMessage('0000GAP', StrSubstNo(UnableToFindMappingErr, MappingName), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
            else begin
                LocalUpdateTableMappingModifiedOn(Rec, LatestModifiedOn);
                Rec.SetOriginalJobQueueEntryStatus(OriginalJobQueueEntry, PrevStatus);
            end;
        end;

        CloseConnection(ConnectionName);
    end;

    var
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        CRMProductName: Codeunit "CRM Product Name";
        TypeHelper: Codeunit "Type Helper";
        MappedFieldDictionary: Dictionary of [Text, Boolean];
        SupportedSourceType: Option ,RecordID,GUID;
        DateType: Option ,Integration,Local;
        OutOfMapFilter: Boolean;
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        RecordNotFoundErr: Label 'Cannot find %1 record %2.', Comment = '%1 = Source table caption, %2 = The lookup value when searching for the source record';
        SourceRecordIsNotInMappingErr: Label 'Cannot find the mapping %2 in table %1.', Comment = '%1 Integration Table Mapping caption, %2 Integration Table Mapping Name';
        CannotDetermineSourceOriginErr: Label 'Cannot determine the source origin: %1.', Comment = '%1 the value of the source id';
        SynchronizeEmptySetErr: Label 'Attempted to synchronize an empty set of records.';
        NoMappingErr: Label 'No mapping is set for %1.', Comment = '%1=Table Caption';
        ModifiedByFieldMustBeGUIDErr: Label 'The field %1 in the table %2 must be of type GUID.', Comment = '%1 - a field name, %2 - a table name';
        OptionMappingCannotBeBidirectionalErr: Label 'Option mappings can only synchronize from integration table or to integration table.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        ClearCacheTxt: Label 'Clear cache.', Locked = true;
        CopyRecordRefFailedTxt: Label 'Copy record reference failed. Dataverse ID: %1', Locked = true, Comment = '%1 - Dataverse record id';
        UnableToFindMappingErr: Label 'Unable to find Integration Table Mapping %1', Locked = true, Comment = '%1 - Mapping name';
        FieldKeyTxt: Label '%1-%2', Locked = true;

    internal procedure InitConnection() ConnectionName: Text
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        initConnectionHandled: Boolean;
    begin
        CRMIntegrationManagement.OnInitCDSConnection(ConnectionName, initConnectionHandled);
        if initConnectionHandled then
            exit(ConnectionName);

        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        ConnectionName := Format(CreateGuid());

        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        ClearCache();
    end;

    local procedure GetIntegrationUserId(): Guid
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationUserId: Guid;
        handled: Boolean;
    begin
        CRMIntegrationManagement.OnGetCDSIntegrationUserId(IntegrationUserId, handled);
        if handled then
            exit(IntegrationUserId);

        exit(CRMConnectionSetup.GetIntegrationUserID());
    end;

    internal procedure TestConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        testConnectionHandled: Boolean;
    begin
        CRMIntegrationManagement.OnTestCDSConnection(testConnectionHandled);
        if not testConnectionHandled then
            if not CRMConnectionSetup.TryReadSystemUsers() then
                Error(GetLastErrorText);
    end;

    internal procedure CloseConnection(ConnectionName: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        closeConnectionHandled: Boolean;
    begin
        ClearCache();

        CRMIntegrationManagement.OnCloseCDSConnection(ConnectionName, closeConnectionHandled);
        if closeConnectionHandled then
            exit;

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure ClearCache()
    begin
        Session.LogMessage('0000CM6', ClearCacheTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        CRMIntTableSubscriber.ClearCache();
        Clear(CRMIntTableSubscriber);
    end;

    local procedure IsModifiedByFilterNeeded(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        IsHandled: Boolean;
        IsNeeded: Boolean;
    begin
        OnIsModifiedByFilterNeeded(IntegrationTableMapping, IsHandled, IsNeeded);
        if IsHandled then
            exit(IsNeeded);

        if IntegrationTableMapping."Delete After Synchronization" then
            exit(false);

        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
            exit(not HasUnidirectionalFieldMappingFromIntegrationTable(IntegrationTableMapping));
        exit(false);
    end;

    local procedure FindModifiedCRMRecords(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean])
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        CRMRecordRef: RecordRef;
        CRMID: Guid;
        ModifiedByFilterNeeded: Boolean;
        TableFilter: Text;
        FilterList: List of [Text];
    begin
        ModifiedByFilterNeeded := IsModifiedByFilterNeeded(IntegrationTableMapping);
        IntegrationRecordSynch.SplitIntegrationTableFilter(IntegrationTableMapping, FilterList);
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        foreach TableFilter in FilterList do begin
            SetIntRecordRefFilter(CRMRecordRef, TableFilter, ModifiedByFilterNeeded, IntegrationTableMapping);
            if CRMRecordRef.FindSet() then
                repeat
                    CRMID := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
                    if not FailedNotSkippedIdDictionary.ContainsKey(CRMID) then
                        if not TryCopyRecordReference(IntegrationTableMapping, CRMRecordRef, TempCRMRecordRef, false) then
                            Session.LogMessage('0000ECC', StrSubstNo(CopyRecordRefFailedTxt, CRMID), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                until CRMRecordRef.Next() = 0;
        end;
        CRMRecordRef.Close();
    end;

    [TryFunction]
    local procedure TryCopyRecordReference(var IntegrationTableMapping: Record "Integration Table Mapping"; FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    begin
        CopyRecordReference(IntegrationTableMapping, FromRec, ToRec, ValidateOnInsert);
    end;

    local procedure CopyRecordReference(var IntegrationTableMapping: Record "Integration Table Mapping"; FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        FromField: FieldRef;
        ToField: FieldRef;
        Counter: Integer;
    begin
        if FromRec.Number <> ToRec.Number then
            exit;

        ToRec.Init();
        for Counter := 1 to FromRec.FieldCount do begin
            FromField := FromRec.FieldIndex(Counter);
            if FromField.Type <> FieldType::TableFilter then
                if FromField.Type <> FieldType::Blob then begin
                    ToField := ToRec.Field(FromField.Number);
                    ToField.Value := FromField.Value();
                end else
                    if IsFieldMapped(IntegrationTableMapping, FromRec.Number(), FromField.Number()) then begin
                        ToField := ToRec.Field(FromField.Number);
                        TempBlob.FromFieldRef(FromField);
                        TempBlob.ToFieldRef(ToField);
                    end;
        end;
        ToRec.Insert(ValidateOnInsert);
    end;

    local procedure IsFieldMapped(var IntegrationTableMapping: Record "Integration Table Mapping"; TableNo: Integer; FieldNo: Integer): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        FieldKey: Text;
        IsMapped: Boolean;
    begin
        FieldKey := StrSubstNo(FieldKeyTxt, TableNo, FieldNo);
        if not MappedFieldDictionary.ContainsKey(FieldKey) then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            if TableNo = IntegrationTableMapping."Integration Table ID" then
                IntegrationFieldMapping.SetRange("Integration Table Field No.", FieldNo)
            else
                IntegrationFieldMapping.SetRange("Field No.", FieldNo);
            IsMapped := not IntegrationFieldMapping.IsEmpty();
            MappedFieldDictionary.Add(FieldKey, IsMapped);
        end;
        exit(MappedFieldDictionary.Get(FieldKey));
    end;

    local procedure SetIntRecordRefFilter(var IntRecordRef: RecordRef; TableFilter: Text; ModifiedByFilterNeeded: Boolean; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        ModifiedOnFieldRef: FieldRef;
        ModifyByFieldRef: FieldRef;
        ModifyByFieldNo: Integer;
    begin
        if TableFilter <> '' then
            IntRecordRef.SetView(TableFilter);

        if IntegrationTableMapping."Synch. Modified On Filter" <> 0DT then begin
            ModifiedOnFieldRef := IntRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            ModifiedOnFieldRef.SetFilter('>%1', IntegrationTableMapping."Synch. Modified On Filter" - 999);
        end;

        if ModifiedByFilterNeeded then begin
            ModifyByFieldNo := GetModifyByFieldNo(IntegrationTableMapping."Integration Table ID");
            ModifyByFieldRef := IntRecordRef.Field(ModifyByFieldNo);
            if ModifyByFieldRef.Type <> FieldType::GUID then
                Error(ModifiedByFieldMustBeGUIDErr, ModifyByFieldRef.Name, IntRecordRef.Name);
            ModifyByFieldRef.SetFilter('<>%1', GetIntegrationUserId())
        end;
    end;

    local procedure FindFailedNotSkippedCRMRecords(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary; var CRMIDDictionary: Dictionary of [Guid, Boolean]): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        CRMRecordRef: RecordRef;
        CRMTableView: Text;
        CRMIDFilter: Text;
        Found: Boolean;
        CRMIDFilterList: List of [Text];
    begin
        CRMTableView := IntegrationTableMapping.GetIntegrationTableFilter();
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        CRMRecordRef.SetView(CRMTableView);
        CRMIDFilter := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").GetFilter();
        CRMRecordRef.Close();
        if CRMIDFilter <> '' then
            exit(false); // Ignore failed not synched records if going to synch records selected by CRMID

        TempCRMIntegrationRecord.SetRange(Skipped, false);
        TempCRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. Result", TempCRMIntegrationRecord."Last Synch. Result"::Failure);
        if TempCRMIntegrationRecord.FindSet() then begin
            repeat
                if not CRMIDDictionary.ContainsKey(TempCRMIntegrationRecord."CRM ID") then
                    CRMIDDictionary.Add(TempCRMIntegrationRecord."CRM ID", true);
            until TempCRMIntegrationRecord.Next() = 0;
            IntegrationRecordSynch.GetIdFilterList(CRMIDDictionary, CRMIDFilterList);
            Found := CacheFilteredCRMRecords(CRMIDFilterList, IntegrationTableMapping, TempCRMRecordRef);
        end;
        TempCRMIntegrationRecord.SetRange(Skipped);
        TempCRMIntegrationRecord.SetRange("Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. Result");
        exit(Found);
    end;

    local procedure CacheFilteredCRMRecords(var CRMIDFilterList: List of [Text]; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMRecordRef: RecordRef): Boolean
    var
        CRMRecordRef: RecordRef;
        CRMIDFilter: Text;
        Cached: Boolean;
    begin
        foreach CRMIDFilter in CRMIDFilterList do
            if CRMIDFilter <> '' then begin
                CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").SetFilter(CRMIDFilter);
                if CRMRecordRef.FindSet() then
                    repeat
                        CopyRecordReference(IntegrationTableMapping, CRMRecordRef, TempCRMRecordRef, false);
                        Cached := true;
                    until CRMRecordRef.Next() = 0;
                CRMRecordRef.Close();
            end;
        exit(Cached);
    end;

    local procedure CacheFilteredCRMTable(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
    begin
        TempCRMRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
        FindFailedNotSkippedCRMRecords(TempCRMRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord, FailedNotSkippedIdDictionary);
        FindModifiedCRMRecords(TempCRMRecordRef, IntegrationTableMapping, FailedNotSkippedIdDictionary);
    end;

    local procedure HasUnidirectionalFieldMappingFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::FromIntegrationTable);
        IntegrationFieldMapping.SetFilter("Integration Table Field No.", '>0');
        IntegrationFieldMapping.SetFilter(Status, '<>%1', IntegrationFieldMapping.Status::Disabled);
        exit(not IntegrationFieldMapping.IsEmpty());
    end;

    procedure GetOutOfMapFilter(): Boolean
    begin
        exit(OutOfMapFilter);
    end;

    local procedure GetSourceRecordRef(IntegrationTableMapping: Record "Integration Table Mapping"; SourceID: Variant; var RecordRef: RecordRef): Boolean
    var
        RecordID: RecordID;
        CRMID: Guid;
    begin
        case GetSourceType(SourceID) of
            SupportedSourceType::RecordID:
                begin
                    RecordID := SourceID;
                    if RecordID.TableNo = 0 then
                        Error(CannotDetermineSourceOriginErr, SourceID);
                    if not (RecordID.TableNo = IntegrationTableMapping."Table ID") then
                        Error(SourceRecordIsNotInMappingErr, IntegrationTableMapping.TableCaption(), IntegrationTableMapping.Name);
                    if not RecordRef.Get(RecordID) then
                        Error(RecordNotFoundErr, RecordRef.Caption, Format(RecordID, 0, 1));
                    exit(IntegrationTableMapping.FindFilteredRec(RecordRef, OutOfMapFilter));
                end;
            SupportedSourceType::GUID:
                begin
                    CRMID := SourceID;
                    if IsNullGuid(CRMID) then
                        Error(CannotDetermineSourceOriginErr, SourceID);
                    if not IntegrationTableMapping.GetRecordRef(CRMID, RecordRef) then
                        Error(RecordNotFoundErr, IntegrationTableMapping.GetExtendedIntegrationTableCaption(), CRMID);
                    exit(IntegrationTableMapping.FindFilteredRec(RecordRef, OutOfMapFilter));
                end;
            else
                Error(CannotDetermineSourceOriginErr, SourceID);
        end;
    end;

    local procedure GetSourceType(Source: Variant): Integer
    begin
        if Source.IsRecordId then
            exit(SupportedSourceType::RecordID);
        if Source.IsGuid then
            exit(SupportedSourceType::GUID);
        exit(0);
    end;

    local procedure FindFailedNotSkippedLocalRecords(var SystemIdDictionary: Dictionary of [Guid, Boolean]; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary): Boolean
    var
        LocalRecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        LocalTableView: Text;
        I: Integer;
        NoFilterOnPK: Boolean;
    begin
        LocalTableView := IntegrationTableMapping.GetTableFilter();
        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
        LocalRecordRef.SetView(LocalTableView);

        if LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).GetFilter() <> '' then
            exit(false); // Ignore failed not synched records if going to synch records selected by systemId

        PrimaryKeyRef := LocalRecordRef.KeyIndex(1);
        for I := 1 to PrimaryKeyRef.FieldCount() do
            if LocalRecordRef.Field(PrimaryKeyRef.FieldIndex(I).Number()).GetFilter() = '' then begin
                NoFilterOnPK := true;
                break;
            end;
        if not NoFilterOnPK then
            exit(false); // Ignore failed not synched records if going to synch records selected by primary key

        TempCRMIntegrationRecord.SetRange(Skipped, false);
        TempCRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. CRM Result", TempCRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        if TempCRMIntegrationRecord.FindSet() then
            repeat
                if not SystemIdDictionary.ContainsKey(TempCRMIntegrationRecord."Integration ID") then
                    SystemIdDictionary.Add(TempCRMIntegrationRecord."Integration ID", true);
            until TempCRMIntegrationRecord.Next() = 0;
        TempCRMIntegrationRecord.SetRange(Skipped);
        TempCRMIntegrationRecord.SetRange("Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. CRM Result");
        exit(SystemIdDictionary.Count() > 0);
    end;

    local procedure FindFailedNotSkippedLocalRecords(var SystemIdDictionary: Dictionary of [Guid, Boolean]; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMOptionMapping: Record "CRM Option Mapping" temporary): Boolean
    var
        LocalRecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        CurrSystemId: Guid;
        LocalTableView: Text;
        I: Integer;
        NoFilterOnPK: Boolean;
    begin
        LocalTableView := IntegrationTableMapping.GetTableFilter();
        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
        LocalRecordRef.SetView(LocalTableView);

        if LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).GetFilter() <> '' then
            exit(false); // Ignore failed not synched records if going to synch records selected by systemId

        PrimaryKeyRef := LocalRecordRef.KeyIndex(1);
        for I := 1 to PrimaryKeyRef.FieldCount() do
            if LocalRecordRef.Field(PrimaryKeyRef.FieldIndex(I).Number()).GetFilter() = '' then begin
                NoFilterOnPK := true;
                break;
            end;
        if not NoFilterOnPK then
            exit(false); // Ignore failed not synched records if going to synch records selected by primary key

        TempCRMOptionMapping.SetRange(Skipped, false);
        TempCRMOptionMapping.SetRange("Table ID", IntegrationTableMapping."Table ID");
        TempCRMOptionMapping.SetRange("Last Synch. CRM Result", TempCRMOptionMapping."Last Synch. CRM Result"::Failure);
        if TempCRMOptionMapping.FindSet() then
            repeat
                if LocalRecordRef.Get(TempCRMOptionMapping."Record ID") then begin
                    CurrSystemId := LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value();
                    if not SystemIdDictionary.ContainsKey(CurrSystemId) then
                        SystemIdDictionary.Add(CurrSystemId, true);
                end;
            until TempCRMOptionMapping.Next() = 0;
        TempCRMOptionMapping.SetRange(Skipped);
        TempCRMOptionMapping.SetRange("Table ID");
        TempCRMOptionMapping.SetRange("Last Synch. CRM Result");
        exit(SystemIdDictionary.Count() > 0);
    end;

    procedure SynchOption(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField(
             IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", Field)
        then
            if Field.Type = Field.Type::Option then
                SynchOptions(IntegrationTableMapping);
    end;

    procedure SynchRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceID: Variant; ForceModify: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean) JobID: Guid
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        FromRecordRef: RecordRef;
        ToRecordRef: RecordRef;
    begin
        if GetSourceRecordRef(IntegrationTableMapping, SourceID, FromRecordRef) then begin // sets the global OutOfMapFilter
            JobID := IntegrationTableSynch.BeginIntegrationSynchJob(TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, FromRecordRef.Number);
            if not IsNullGuid(JobID) then begin
                IntegrationTableSynch.Synchronize(FromRecordRef, ToRecordRef, ForceModify, IgnoreSynchOnlyCoupledRecords);
                IntegrationTableSynch.EndIntegrationSynchJob();
            end;
        end;
    end;

    procedure SynchRecordsToIntegrationTable(var RecordsToSynchRecordRef: RecordRef; IgnoreChanges: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean) JobID: Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        IntegrationRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeSynchRecordsToIntegrationTable(RecordsToSynchRecordRef, IgnoreChanges, IgnoreSynchOnlyCoupledRecords, IsHandled);
        if IsHandled then
            exit;

        if not IntegrationTableMapping.FindMappingForTable(RecordsToSynchRecordRef.Number) then
            Error(NoMappingErr, RecordsToSynchRecordRef.Name);

        RecordsToSynchRecordRef.Ascending(false);
        if not RecordsToSynchRecordRef.FindSet() then
            Error(SynchronizeEmptySetErr);

        JobID :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, RecordsToSynchRecordRef.Number);
        if not IsNullGuid(JobID) then begin
            repeat
                IntegrationTableSynch.Synchronize(RecordsToSynchRecordRef, IntegrationRecordRef, IgnoreChanges, IgnoreSynchOnlyCoupledRecords)
            until RecordsToSynchRecordRef.Next() = 0;
            IntegrationTableSynch.EndIntegrationSynchJob();
        end;
    end;

    procedure SynchRecordsFromIntegrationTable(var RecordsToSynchRecordRef: RecordRef; SourceTableNo: Integer; IgnoreChanges: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean) JobID: Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        IntegrationRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeSynchRecordsFromIntegrationTable(RecordsToSynchRecordRef, SourceTableNo, IgnoreChanges, IgnoreSynchOnlyCoupledRecords, IsHandled);
        if IsHandled then
            exit;

        if not IntegrationTableMapping.FindMapping(SourceTableNo, RecordsToSynchRecordRef.Number) then
            Error(NoMappingErr, RecordsToSynchRecordRef.Name);

        RecordsToSynchRecordRef.Ascending(false);
        if not RecordsToSynchRecordRef.FindSet() then
            Error(SynchronizeEmptySetErr);

        JobID :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, RecordsToSynchRecordRef.Number);
        if not IsNullGuid(JobID) then begin
            repeat
                IntegrationTableSynch.Synchronize(RecordsToSynchRecordRef, IntegrationRecordRef, IgnoreChanges, IgnoreSynchOnlyCoupledRecords)
            until RecordsToSynchRecordRef.Next() = 0;
            IntegrationTableSynch.EndIntegrationSynchJob();
        end;
    end;

    local procedure SynchNAVTableToCRM(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestLocalModifiedOn: DateTime
    var
        IntTableManualSubscribers: Codeunit "Int. Table Manual Subscribers";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        SourceRecordRef: RecordRef;
        RecordSystemId: Guid;
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
        FilterList: List of [Text];
        TableFilter: Text;
    begin
        BindSubscription(IntTableManualSubscribers);
        LatestLocalModifiedOn := 0DT;
        IntegrationRecordSynch.SplitLocalTableFilter(IntegrationTableMapping, FilterList);
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);

        SourceRecordRef.Open(IntegrationTableMapping."Table ID");
        if FindFailedNotSkippedLocalRecords(FailedNotSkippedIdDictionary, IntegrationTableMapping, TempCRMIntegrationRecord) then
            foreach RecordSystemId in FailedNotSkippedIdDictionary.Keys() do
                if SourceRecordRef.GetBySystemId(RecordSystemId) then
                    SyncNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestLocalModifiedOn);

        foreach TableFilter in FilterList do
            if IntegrationRecordSynch.FindModifiedLocalRecords(SourceRecordRef, TableFilter, IntegrationTableMapping) then
                repeat
                    RecordSystemId := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
                    if not FailedNotSkippedIdDictionary.ContainsKey(RecordSystemId) then
                        SyncNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestLocalModifiedOn);
                until SourceRecordRef.Next() = 0;

        OnSynchNAVTableToCRMOnBeforeCheckLatestModifiedOn(SourceRecordRef, IntegrationTableMapping);
        SourceRecordRef.Close();
        UnbindSubscription(IntTableManualSubscribers);
    end;

    procedure SyncNAVRecordToCRM(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary; var LatestLocalModifiedOn: DateTime)
    var
        DestinationRecordRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
        LocalModifiedOn: DateTime;
    begin
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        IgnoreRecord := false;
        OnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
        if not IgnoreRecord then begin
            SystemIdFieldRef := SourceRecordRef.Field(SourceRecordRef.SystemIdNo);
            if not TempCRMIntegrationRecord.IsIntegrationIdCoupled(SystemIdFieldRef.Value(), SourceRecordRef.Number) then
                IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
            if not IgnoreRecord then
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, ForceModify, false);
        end;
        // collect latest modified time across all local records including not synched
        LocalModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
        if LocalModifiedOn > LatestLocalModifiedOn then
            LatestLocalModifiedOn := LocalModifiedOn;
    end;

    local procedure SynchCRMTableToNAV(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var SourceRecordRef: RecordRef) LatestIntegrationModifiedOn: DateTime
    var
        IntTableManualSubscribers: Codeunit "Int. Table Manual Subscribers";
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        DestinationRecordRef: RecordRef;
        CloneSourceRecordRef: RecordRef;
        IntegrationModifiedOn: DateTime;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
    begin
        BindSubscription(IntTableManualSubscribers);
        LatestIntegrationModifiedOn := 0DT;
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
        CacheFilteredCRMTable(SourceRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord);
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if SourceRecordRef.FindSet() then
            repeat
                CloneSourceRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
                CopyRecordReference(IntegrationTableMapping, SourceRecordRef, CloneSourceRecordRef, false);
                IgnoreRecord := false;
                OnQueryPostFilterIgnoreRecord(CloneSourceRecordRef, IgnoreRecord);
                if not IgnoreRecord then begin
                    if TempCRMIntegrationRecord.IsCRMRecordRefCoupled(CloneSourceRecordRef) then
                        TempCRMIntegrationRecord.Delete()
                    else
                        IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
                    if not IgnoreRecord then
                        IntegrationTableSynch.Synchronize(CloneSourceRecordRef, DestinationRecordRef, ForceModify, false);
                end;
                // collect latest modified time across all integration records including not synched
                IntegrationModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, CloneSourceRecordRef);
                if IntegrationModifiedOn > LatestIntegrationModifiedOn then
                    LatestIntegrationModifiedOn := IntegrationModifiedOn;
                CloneSourceRecordRef.Close();
            until SourceRecordRef.Next() = 0;
        UnbindSubscription(IntTableManualSubscribers);
    end;

    local procedure GetModifyByFieldNo(CRMTableID: Integer): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, CRMTableID);
        Field.SetRange(FieldName, 'ModifiedBy'); // All CRM tables should have "ModifiedBy" field
        Field.FindFirst();
        exit(Field."No.");
    end;

    local procedure PerformScheduledSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestLocalModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
        JobCreationTime: DateTime;
    begin
        JobCreationTime := CurrentDateTime();
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::ToIntegrationTable);
            LatestLocalModifiedOn := SynchNAVTableToCRM(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob();
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
        if LatestLocalModifiedOn > JobCreationTime then
            LatestLocalModifiedOn := JobCreationTime;
    end;

    local procedure PerformScheduledSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestIntegrationModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        JobId: Guid;
        JobCreationTime: DateTime;
    begin
        JobCreationTime := CurrentDateTime();
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::FromIntegrationTable);
            LatestIntegrationModifiedOn := SynchCRMTableToNAV(IntegrationTableMapping, IntegrationTableSynch, SourceRecordRef);
            IntegrationTableSynch.EndIntegrationSynchJob();
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
        if LatestIntegrationModifiedOn > JobCreationTime then
            LatestIntegrationModifiedOn := JobCreationTime;
    end;

    local procedure LocalUpdateTableMappingModifiedOn(var IntegrationTableMapping: Record "Integration Table Mapping"; LatestModifiedOn: array[2] of DateTime)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTableMappingModifiedOn(IntegrationTableMapping, LatestModifiedOn, IsHandled);
        if IsHandled then
            exit;

        IntegrationTableMapping.UpdateTableMappingModifiedOn(LatestModifiedOn);
    end;

    internal procedure CreateCRMIntegrationRecordClone(ForTable: Integer; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        TempCRMIntegrationRecord.Reset();
        TempCRMIntegrationRecord.DeleteAll();

        CRMIntegrationManagement.RepairBrokenCouplings();
        CRMIntegrationRecord.SetRange("Table ID", ForTable);
        if not CRMIntegrationRecord.FindSet() then
            exit;

        repeat
            TempCRMIntegrationRecord.Copy(CRMIntegrationRecord, false);
            TempCRMIntegrationRecord.Insert();
        until CRMIntegrationRecord.Next() = 0;
    end;

    local procedure SynchOptions(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        OriginalJobQueueEntry: Record "Job Queue Entry";
        LatestModifiedOn: array[2] of DateTime;
        PrevStatus: Option;
    begin
        IntegrationTableMapping.SetOriginalJobQueueEntryOnHold(OriginalJobQueueEntry, PrevStatus);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
            Error(OptionMappingCannotBeBidirectionalErr);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable then
            LatestModifiedOn[DateType::Local] := PerformScheduledOptionSynchToIntegrationTable(IntegrationTableMapping);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
            LatestModifiedOn[DateType::Integration] := PerformScheduledOptionSynchFromIntegrationTable(IntegrationTableMapping);
        LocalUpdateTableMappingModifiedOn(IntegrationTableMapping, LatestModifiedOn);
        IntegrationTableMapping.SetOriginalJobQueueEntryStatus(OriginalJobQueueEntry, PrevStatus);
    end;

    local procedure PerformScheduledOptionSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestIntegrationModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
        JobCreationTime: DateTime;
    begin
        JobCreationTime := CurrentDateTime();
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::FromIntegrationTable);
            LatestIntegrationModifiedOn := SynchCRMOptionToNAV(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob();
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
        if LatestIntegrationModifiedOn > JobCreationTime then
            LatestIntegrationModifiedOn := JobCreationTime;
    end;

    local procedure PerformScheduledOptionSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestIntegrationModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
        JobCreationTime: DateTime;
    begin
        JobCreationTime := CurrentDateTime();
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::ToIntegrationTable);
            LatestIntegrationModifiedOn := SynchCRMOptionFromNAV(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob();
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
        if LatestIntegrationModifiedOn > JobCreationTime then
            LatestIntegrationModifiedOn := JobCreationTime;
    end;

    local procedure CacheFilteredCRMOptions(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMRecordRef: RecordRef;
        CRMOptionFieldRef: FieldRef;
        CRMTableView: Text;
        CRMOptionIdFilter: Text;
        CRMOption: Text;
        CRMOptions: List of [Text];
        OptionDictionary: Dictionary of [Text, Integer];
        i: Integer;
    begin
        LoadCRMOption(TempCRMRecordRef, IntegrationTableMapping);

        CRMTableView := IntegrationTableMapping.GetIntegrationTableFilter();
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        CRMRecordRef.SetView(CRMTableView);
        CRMOptionFieldRef := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        CRMOptionIdFilter := CRMOptionFieldRef.GetFilter();
        CRMRecordRef.Close();
        if CRMOptionIdFilter <> '' then begin
            for i := 1 to CRMOptionFieldRef.EnumValueCount() do
                OptionDictionary.Add(CRMOptionFieldRef.GetEnumValueCaption(i), CRMOptionFieldRef.GetEnumValueOrdinal(i));

            CRMOptions := CRMOptionIdFilter.Replace('(', '').Replace(')', '').Split('|');
            foreach CRMOption in CRMOptions do
                if OptionDictionary.ContainsKey(CRMOption) then
                    CRMOptionIdFilter := CRMOptionIdFilter.Replace(CRMOption, Format(OptionDictionary.Get(CRMOption)));

            TempCRMRecordRef.Field(TempCRMRecordRef.KeyIndex(1).FieldIndex(1).Number).SetFilter(CRMOptionIdFilter);
        end;
    end;

    [Scope('OnPrem')]
    procedure LoadCRMOption(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMPaymentTerms: Record "CRM Payment Terms";
        CRMFreightTerms: Record "CRM Freight Terms";
        CRMShippingMethod: Record "CRM Shipping Method";
    begin
        case IntegrationTableMapping."Table ID" of
            Database::"Payment Terms":
                begin
                    CRMPaymentTerms.Load();
                    TempCRMRecordRef.GetTable(CRMPaymentTerms);
                end;
            Database::"Shipment Method":
                begin
                    CRMFreightTerms.Load();
                    TempCRMRecordRef.GetTable(CRMFreightTerms);
                end;
            Database::"Shipping Agent":
                begin
                    CRMShippingMethod.Load();
                    TempCRMRecordRef.GetTable(CRMShippingMethod);
                end;
        end;
        OnLoadCRMOption(TempCRMRecordRef, IntegrationTableMapping);
    end;

    local procedure SynchCRMOptionToNAV(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestIntegrationModifiedOn: DateTime
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        DestinationRecordRef: RecordRef;
        SourceRecordRef: RecordRef;
        ForceModify: Boolean;
        IgnoreRecord: Boolean;
    begin
        LatestIntegrationModifiedOn := 0DT;
        CacheFilteredCRMOptions(SourceRecordRef, IntegrationTableMapping);
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if SourceRecordRef.FindSet() then
            repeat
                IgnoreRecord := false;
                if not CRMOptionMapping.IsCRMRecordRefMapped(SourceRecordRef, CRMOptionMapping) then
                    if IntegrationTableMapping."Synch. Only Coupled Records" then
                        IgnoreRecord := true;
                if not IgnoreRecord then begin
                    IntegrationTableSynch.SynchronizeOption(SourceRecordRef, DestinationRecordRef, ForceModify, false);
                    LatestIntegrationModifiedOn := CurrentDateTime();
                end;
            until SourceRecordRef.Next() = 0;
    end;

    local procedure SynchCRMOptionFromNAV(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestLocalModifiedOn: DateTime
    var
        TempCRMOptionMapping: Record "CRM Option Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecordRef: RecordRef;
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
        FilterList: List of [Text];
        RecordSystemId: Guid;
        TableFilter: Text;
    begin
        LatestLocalModifiedOn := 0DT;
        IntegrationRecordSynch.SplitLocalTableFilter(IntegrationTableMapping, FilterList);

        SourceRecordRef.Open(IntegrationTableMapping."Table ID");
        if FindFailedNotSkippedLocalRecords(FailedNotSkippedIdDictionary, IntegrationTableMapping, TempCRMOptionMapping) then
            foreach RecordSystemId in FailedNotSkippedIdDictionary.Keys() do
                if SourceRecordRef.GetBySystemId(RecordSystemId) then
                    SyncNAVOptionToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, LatestLocalModifiedOn);

        foreach TableFilter in FilterList do
            if IntegrationRecordSynch.FindModifiedLocalRecords(SourceRecordRef, TableFilter, IntegrationTableMapping) then
                repeat
                    RecordSystemId := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
                    if not FailedNotSkippedIdDictionary.ContainsKey(RecordSystemId) then
                        SyncNAVOptionToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, LatestLocalModifiedOn);
                until SourceRecordRef.Next() = 0;

        SourceRecordRef.Close();
    end;

    local procedure SyncNAVOptionToCRM(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var LatestLocalModifiedOn: DateTime)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        DestinationRecordRef: RecordRef;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
        LocalModifiedOn: DateTime;
    begin
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        IgnoreRecord := false;
        if not IgnoreRecord then begin
            CRMOptionMapping.SetRange("Record ID", SourceRecordRef.RecordId);
            if CRMOptionMapping.IsEmpty() then
                IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
            if not IgnoreRecord then
                IntegrationTableSynch.SynchronizeOption(SourceRecordRef, DestinationRecordRef, ForceModify, false);
        end;
        // collect latest modified time across all local records including not synched
        LocalModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
        if LocalModifiedOn > LatestLocalModifiedOn then
            LatestLocalModifiedOn := LocalModifiedOn;
    end;

    [Scope('OnPrem')]
    procedure GetMaxNumberOfConditions(): Integer
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        Handled: Boolean;
        MaxNumberOfConditions: Integer;
    begin
        OnGetMaxNumberOfConditions(Handled, MaxNumberOfConditions);
        if Handled then
            exit(IntegrationRecordSynch.GetMaxNumberOfConditions());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTableMappingModifiedOn(var IntegrationTableMapping: Record "Integration Table Mapping"; ModifiedOn: array[2] of DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchNAVTableToCRMOnBeforeCheckLatestModifiedOn(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxNumberOfConditions(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCRMOption(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsModifiedByFilterNeeded(var IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean; var IsNeeded: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchRecordsFromIntegrationTable(var RecordsToSynchRecordRef: RecordRef; SourceTableNo: Integer; IgnoreChanges: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchRecordsToIntegrationTable(var RecordsToSynchRecordRef: RecordRef; IgnoreChanges: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean);
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    local procedure IgnoreCompanyContactOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        Contact: Record Contact;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number = DATABASE::Contact then begin
            if CRMSynchHelper.IsContactTypeCheckIgnored() then
                exit;
            SourceRecordRef.SetTable(Contact);
            if Contact.Type = Contact.Type::Company then
                IgnoreRecord := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyJobQueueEntry(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        if Rec.IsTemporary() then
            exit;

        CRMFullSynchReviewLine.OnBeforeModifyJobQueueEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job", 'OnCanBeRemoved', '', false, false)]
    local procedure OnSynchJobEntryCanBeRemoved(IntegrationSynchJob: Record "Integration Synch. Job"; var AllowRemoval: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if AllowRemoval then
            exit;

        CRMIntegrationRecord.SetRange(Skipped, true);
        CRMIntegrationRecord.SetRange("Last Synch. Job ID", IntegrationSynchJob.ID);
        if CRMIntegrationRecord.IsEmpty() then begin
            CRMIntegrationRecord.SetRange("Last Synch. Job ID");
            CRMIntegrationRecord.SetRange("Last Synch. CRM Job ID", IntegrationSynchJob.ID);
            if CRMIntegrationRecord.IsEmpty() then
                AllowRemoval := true;
        end;
    end;
}

