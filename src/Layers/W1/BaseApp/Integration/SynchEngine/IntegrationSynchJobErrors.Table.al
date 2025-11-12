// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;
using System.Reflection;

table 5339 "Integration Synch. Job Errors"
{
    Caption = 'Integration Synch. Job Errors';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Synch. Job ID"; Guid)
        {
            Caption = 'Integration Synch. Job ID';
            TableRelation = "Integration Synch. Job".ID;
        }
        field(3; "Source Record ID"; RecordID)
        {
            Caption = 'Source Record ID';
            DataClassification = CustomerContent;
        }
        field(4; "Destination Record ID"; RecordID)
        {
            Caption = 'Destination Record ID';
            DataClassification = CustomerContent;
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(6; "Date/Time"; DateTime)
        {
            Caption = 'Date/Time';
        }
        field(7; "Exception Detail"; BLOB)
        {
            Caption = 'Exception Detail';
        }
        field(8; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Integration Synch. Job ID", "Date/Time")
        {
        }
        key(Key3; "Date/Time", "Integration Synch. Job ID")
        {
        }
        key(Key4; "Integration Synch. Job ID")
        {
        }
        key(Key5; "Destination Record ID", "Integration Synch. Job ID")
        {
        }
        key(Key6; "Source Record ID", "Integration Synch. Job ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DeleteEntriesQst: Label 'Are you sure that you want to delete the %1 entries?', Comment = '%1 = Integration Synch. Job Errors caption';

    procedure DeleteEntries(DaysOld: Integer)
    begin
        if not Confirm(StrSubstNo(DeleteEntriesQst, TableCaption)) then
            exit;

        SetFilter("Date/Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
        DeleteAll();
        SetRange("Date/Time");
    end;

    procedure LogSynchError(IntegrationSynchJobId: Guid; SourceRecordId: RecordID; DestinationRecordId: RecordID; ErrorMessage: Text)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        StackTraceOutStream: OutStream;
    begin
        IntegrationSynchJobErrors.Init();
        IntegrationSynchJobErrors."Integration Synch. Job ID" := IntegrationSynchJobId;
        IntegrationSynchJobErrors."Source Record ID" := SourceRecordId;
        IntegrationSynchJobErrors."Destination Record ID" := DestinationRecordId;
        IntegrationSynchJobErrors."Date/Time" := CurrentDateTime;
        IntegrationSynchJobErrors.Message := CopyStr(ErrorMessage, 1, MaxStrLen(IntegrationSynchJobErrors.Message));
        IntegrationSynchJobErrors."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(IntegrationSynchJobErrors."Error Message"));
        IntegrationSynchJobErrors."Exception Detail".CreateOutStream(StackTraceOutStream);
        StackTraceOutStream.Write(GetLastErrorCallstack);
        IntegrationSynchJobErrors.Insert(true);
        OnAfterLogSynchError(Rec);
    end;

    procedure SetDataIntegrationUIElementsVisible(var DataIntegrationCuesVisible: Boolean)
    begin
        OnIsDataIntegrationEnabled(DataIntegrationCuesVisible);
    end;

    procedure ForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    begin
        OnForceSynchronizeDataIntegration(LocalRecordID, SynchronizeHandled);
    end;

    [Scope('OnPrem')]
    procedure ForceSynchronizeDataIntegration(var LocalRecordIdList: List of [RecordId]; var SynchronizeHandled: Boolean)
    begin
        OnForceSynchronizeRecords(LocalRecordIdList, SynchronizeHandled);
    end;

    [Scope('OnPrem')]
    procedure DeleteCouplings()
    begin
        DeleteCouplings(Rec);
    end;

    local procedure DeleteCouplings(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        if CollectLocalRecords(IntegrationSynchJobErrors, TempCRMSynchConflictBuffer) then
            UncoupleLocalRecords(TempCRMSynchConflictBuffer);
    end;

    local procedure CollectLocalRecords(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"; var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary): Boolean
    var
        LocalRecordRef: RecordRef;
        LocalRecordId: RecordId;
        LocalSystemId: Guid;
        RecordCount: Integer;
        RecordIdDictionary: Dictionary of [RecordId, Boolean];
    begin
        if not IntegrationSynchJobErrors.FindSet() then
            exit(false);

        RecordCount := 0;
        repeat
            if GetLocalRecordId(IntegrationSynchJobErrors, LocalRecordId) then
                if not RecordIdDictionary.ContainsKey(LocalRecordId) then begin
                    LocalRecordRef.Close();
                    LocalRecordRef.Open(LocalRecordId.TableNo());
                    if LocalRecordRef.Get(LocalRecordId) then begin
                        LocalSystemId := LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value();
                        if not IsNullGuid(LocalSystemId) then begin
                            TempCRMSynchConflictBuffer."Entry No." := RecordCount + 1;
                            TempCRMSynchConflictBuffer."Table ID" := LocalRecordId.TableNo();
                            TempCRMSynchConflictBuffer."Integration ID" := LocalSystemId;
                            TempCRMSynchConflictBuffer.Insert();
                            RecordCount += 1;
                        end;
                    end;
                end;
        until IntegrationSynchJobErrors.Next() = 0;
        exit(RecordCount > 0);
    end;

    local procedure UncoupleLocalRecords(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary)
    var
        LocalTableID: Integer;
        PrevLocalTableID: Integer;
        LocalIdList: List of [Guid];
    begin
        TempCRMSynchConflictBuffer.SetCurrentKey("Table ID");
        if not TempCRMSynchConflictBuffer.FindSet() then
            exit;

        PrevLocalTableID := 0;
        repeat
            LocalTableID := TempCRMSynchConflictBuffer."Table ID";
            if LocalTableID <> PrevLocalTableID then begin
                if PrevLocalTableID <> 0 then begin
                    UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
                    LocalIdList.RemoveRange(1, LocalIdList.Count());
                end;
                PrevLocalTableID := TempCRMSynchConflictBuffer."Table ID";
            end;
            LocalIdList.Add(TempCRMSynchConflictBuffer."Integration ID");
        until TempCRMSynchConflictBuffer.Next() = 0;
        UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
    end;

    local procedure UncoupleLocalRecords(LocalTableId: Integer; var LocalIdList: List of [Guid])
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if LocalTableId = 0 then
            exit;
        if LocalIdList.Count() = 0 then
            exit;
        CRMIntegrationManagement.RemoveCoupling(LocalTableId, LocalIdList);
    end;

    local procedure GetLocalRecordId(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"; var LocalRecordID: RecordID): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        LocalRecordID := IntegrationSynchJobErrors."Source Record ID";
        if LocalRecordID.TableNo() = 0 then
            exit(false);

        if not TableMetadata.Get(LocalRecordID.TableNo()) then
            exit(false);

        if TableMetadata.TableType = TableMetadata.TableType::Normal then
            exit(true);

        LocalRecordID := IntegrationSynchJobErrors."Destination Record ID";
        if LocalRecordID.TableNo() = 0 then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDataIntegrationEnabled(var IsIntegrationEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnForceSynchronizeRecords(var LocalRecordIdList: List of [RecordId]; var SynchronizeHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogSynchError(IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    begin
    end;
}

