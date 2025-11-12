// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Reflection;

table 5374 "CRM Synch. Conflict Buffer"
{
    Caption = 'CRM Synch. Conflict Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
                RecRef: RecordRef;
                RecId: RecordId;
            begin
                CRMIntegrationRecord."Integration ID" := "Integration ID";
                CRMIntegrationRecord."Table ID" := "Table ID";
                if CRMIntegrationRecord.FindRecordId(RecId) then begin
                    "Record ID" := RecId;
                    Description := CopyStr(GetRecDescription(), 1, MaxStrLen(Description));
                    "Record Exists" := RecRef.Get("Record ID");
                end;
            end;
        }
        field(3; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
                IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                IntegrationTableMapping: Record "Integration Table Mapping";
                CRMSetupDefaults: Codeunit "CRM Setup Defaults";
                RecRef: RecordRef;
                FieldRef: FieldRef;
                TableID: Integer;
                IsHandled: Boolean;
            begin
                if CRMIntegrationRecord.FindByCRMID("CRM ID") then begin
                    if CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors) then begin
                        "Error Message" := IntegrationSynchJobErrors.Message;
                        "Failed On" := IntegrationSynchJobErrors."Date/Time";
                    end;
                    TableID := CRMIntegrationRecord.GetTableID();

                    IsHandled := false;
                    OnValidateCRMIDOnBeforeGetCRMIntegrationRecord(TableID, Rec, IsHandled);
                    if not IsHandled then
                        if TableID <> 0 then begin
                            "Int. Table ID" := CRMSetupDefaults.GetCRMTableNo(TableID);
                            if CRMIntegrationRecord.GetCRMRecordRef("Int. Table ID", RecRef) then begin
                                FieldRef := RecRef.Field(CRMSetupDefaults.GetNameFieldNo(RecRef.Number));
                                "Int. Record ID" := RecRef.RecordId;
                                "Int. Description" := FieldRef.Value();
                                "Int. Record Exists" := true;

                                IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                                IntegrationTableMapping.SetRange("Table ID", "Table ID");
                                if IntegrationTableMapping.FindFirst() then begin
                                    FieldRef := RecRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
                                    "Int. Modified On" := FieldRef.Value();
                                end;
                                RecRef.Close();
                            end;
                        end;
                end;
            end;
        }
        field(4; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                "Table Name" := GetTableCaption();
            end;
        }
        field(5; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                CRMOptionMapping: Record "CRM Option Mapping";
                RecRef: RecordRef;
            begin
                CRMOptionMapping.SetRange("Record ID", "Record ID");
                if not CRMOptionMapping.IsEmpty() then begin
                    "Record Exists" := RecRef.Get("Record ID");
                    if "Record Exists" then begin
                        "Record ID" := RecRef.RecordId;
                        "Integration ID" := RecRef.Field(RecRef.SystemIdNo()).Value();
                        Description := CopyStr(GetRecDescription(), 1, MaxStrLen(Description));
                    end;
                end;
            end;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(8; "Modified On"; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
        }
        field(9; "Int. Table ID"; Integer)
        {
            Caption = 'Int. Table ID';
            DataClassification = SystemMetadata;
        }
        field(10; "Int. Record ID"; RecordID)
        {
            Caption = 'Int. Record ID';
            DataClassification = CustomerContent;
        }
        field(11; "Int. Description"; Text[250])
        {
            Caption = 'Int. Description';
            DataClassification = SystemMetadata;
        }
        field(12; "Int. Modified On"; DateTime)
        {
            Caption = 'Int. Modified On';
            DataClassification = SystemMetadata;
        }
        field(13; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(14; "Failed On"; DateTime)
        {
            Caption = 'Failed On';
            DataClassification = SystemMetadata;
        }
        field(16; "Record Exists"; Boolean)
        {
            Caption = 'Record Exists';
            DataClassification = SystemMetadata;
        }
        field(17; "Int. Record Exists"; Boolean)
        {
            Caption = 'Int. Record Exists';
            DataClassification = SystemMetadata;
        }
        field(18; "CRM Option Id"; Integer)
        {
            Caption = 'CRM Option Id';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMOptionMapping: Record "CRM Option Mapping";
                IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                IntegrationTableMapping: Record "Integration Table Mapping";
                CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
                RecRef: RecordRef;
            begin
                if IntegrationTableMapping.FindMappingForTable("Table ID") then
                    if CRMOptionMapping.FindRecordID(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", "CRM Option Id") then begin
                        if CRMOptionMapping.GetLatestError(IntegrationSynchJobErrors) then begin
                            "Error Message" := IntegrationSynchJobErrors.Message;
                            "Failed On" := IntegrationSynchJobErrors."Date/Time";
                        end;
                        "Int. Table ID" := IntegrationTableMapping."Integration Table ID";
                        CRMIntegrationTableSynch.LoadCRMOption(RecRef, IntegrationTableMapping);
                        RecRef.Field(RecRef.KeyIndex(1).FieldIndex(1).Number).SetRange("CRM Option Id");
                        if RecRef.FindFirst() then begin
                            "Int. Description" := CRMOptionMapping.GetRecordRefOptionValue(RecRef);
                            "Int. Record Exists" := true;
                            RecRef.Close();
                        end;
                    end;
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NoPermissionToDeleteInCRMErr: Label 'You do not have permission to delete entities in Dynamics 365 Sales.';

    procedure DeleteCoupledRecords()
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        if TempCRMSynchConflictBuffer.FindSet() then
            repeat
                TempCRMSynchConflictBuffer.DeleteCoupledRecord();
            until TempCRMSynchConflictBuffer.Next() = 0;
    end;

    procedure DeleteCoupledRecord()
    begin
        if IsOneRecordDeleted() then
            if "Record Exists" then
                DeleteCoupledRecInNAV()
            else
                DeleteCoupledRecInCRM();
    end;

    local procedure DeleteCoupledRecInCRM()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByCRMID("CRM ID") then begin
            if CRMIntegrationRecord.GetCRMRecordRef("Int. Table ID", RecRef) then
                if not TryToDeleteCRMRecord(RecRef) then
                    Error(NoPermissionToDeleteInCRMErr);
            if CRMIntegrationRecord.Delete(true) then
                Delete();
        end;
    end;

    local procedure DeleteCoupledRecInNAV()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByRecordID("Record ID") then begin
            RecRef.Get("Record ID");
            RecRef.Delete(true);
            if CRMIntegrationRecord.Delete(true) then
                Delete();
        end;
    end;

    procedure DeleteCouplings()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMOptionMapping: Record "CRM Option Mapping";
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        LocalRecordRef: RecordRef;
        LocalIdList: List of [Guid];
        IntegrationIdList: List of [Guid];
        LocalTableID: Integer;
        PrevLocalTableID: Integer;
        IntegrationTableID: Integer;
        PrevIntegrationTableID: Integer;
        LocalId: Guid;
        IntegrationId: Guid;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        TempCRMSynchConflictBuffer.SetCurrentKey("Table ID");
        if not TempCRMSynchConflictBuffer.FindSet() then
            exit;

        PrevLocalTableID := 0;
        PrevIntegrationTableID := 0;
        repeat
            if TempCRMSynchConflictBuffer."CRM Option Id" <> 0 then begin
                if TempCRMSynchConflictBuffer."Record Exists" then begin
                    LocalRecordRef.Open(TempCRMSynchConflictBuffer."Table ID");
                    LocalRecordRef.Get(TempCRMSynchConflictBuffer."Record ID");
                    CRMOptionMapping.SetRange("Record ID", LocalRecordRef.RecordId);
                    if CRMOptionMapping.FindFirst() then
                        CRMOptionMapping.Delete();
                    LocalRecordRef.Close();
                end;
            end else begin
                LocalTableID := TempCRMSynchConflictBuffer."Table ID";
                IntegrationTableID := TempCRMSynchConflictBuffer."Int. Table ID";
                if LocalTableID <> PrevLocalTableID then begin
                    if PrevLocalTableID <> 0 then begin
                        UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
                        UncoupleIntegrationRecords(PrevLocalTableID, PrevIntegrationTableID, IntegrationIdList);
                        LocalIdList.RemoveRange(1, LocalIdList.Count());
                        IntegrationIdList.RemoveRange(1, IntegrationIdList.Count());
                        LocalRecordRef.Close();
                    end;
                    LocalRecordRef.Open(TempCRMSynchConflictBuffer."Table ID");
                    PrevLocalTableID := TempCRMSynchConflictBuffer."Table ID";
                    PrevIntegrationTableID := TempCRMSynchConflictBuffer."Int. Table ID";
                end;
                if TempCRMSynchConflictBuffer."Record Exists" then begin
                    if LocalRecordRef.Get(TempCRMSynchConflictBuffer."Record ID") then begin
                        LocalId := LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value();
                        if not IsNullGuid(LocalId) then
                            LocalIdList.Add(LocalId);
                    end;
                end else begin
                    IntegrationId := TempCRMSynchConflictBuffer."CRM ID";
                    if TempCRMSynchConflictBuffer."Int. Record Exists" then begin
                        if not IsNullGuid(IntegrationId) then
                            IntegrationIdList.Add(IntegrationId);
                    end else
                        CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationId, PrevLocalTableID);
                end;
            end;
        until TempCRMSynchConflictBuffer.Next() = 0;
        UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
        UncoupleIntegrationRecords(PrevLocalTableID, IntegrationTableID, IntegrationIdList);
        TempCRMSynchConflictBuffer.DeleteAll();
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

    local procedure UncoupleIntegrationRecords(LocalTableId: Integer; IntegrationTableId: Integer; var IntegrationIdList: List of [Guid])
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if LocalTableId = 0 then
            exit;
        if IntegrationTableId = 0 then
            exit;
        if IntegrationIdList.Count() = 0 then
            exit;
        CRMIntegrationManagement.RemoveCoupling(LocalTableId, IntegrationTableId, IntegrationIdList);
    end;

    procedure DeleteCoupling()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        RecId: RecordId;
    begin
        if "Record Exists" then begin
            CRMIntegrationRecord."Integration ID" := "Integration ID";
            CRMIntegrationRecord."Table ID" := "Table ID";
            CRMIntegrationRecord.FindRecordId(RecId);
            CRMCouplingManagement.RemoveCouplingWithTracking(RecId, TempCRMIntegrationRecord);
        end else
            CRMCouplingManagement.RemoveCouplingWithTracking("Table ID", "Int. Table ID", "CRM ID", TempCRMIntegrationRecord);
        TempCRMIntegrationRecord.SetRecFilter();
        UpdateSourceTable(TempCRMIntegrationRecord);
    end;

    procedure Fill(var CRMIntegrationRecord: Record "CRM Integration Record"): Integer
    var
        TempCRMOptionMapping: Record "CRM Option Mapping" temporary;
    begin
        exit(Fill(CRMIntegrationRecord, TempCRMOptionMapping));
    end;


    procedure Fill(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping"): Integer
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        cnt: Integer;
        TableIdFilter: Text;
    begin
        DeleteAll();
        CRMIntegrationManagement.RepairBrokenCouplings(true);
        CRMIntegrationRecord.SetCurrentKey(Skipped, "Table ID");
        CRMOptionMapping.SetCurrentKey(Skipped, "Table ID");
        TableIdFilter := CRMIntegrationRecord.GetFilter("Table ID");
        if TableIdFilter = '' then
            CRMIntegrationRecord.SetFilter("Table ID", '<>0');
        if CRMIntegrationRecord.FindSet() then
            repeat
                cnt += 1;
                "Entry No." += 1;
                InitFromCRMIntegrationRecord(CRMIntegrationRecord);
                if DoesOneRecordExist() then
                    Insert()
                else
                    CRMIntegrationRecord.Delete();
            until ((CRMIntegrationRecord.Next() = 0) or (cnt = 100));
        if cnt < 100 then
            if CRMOptionMapping.FindSet() then
                repeat
                    cnt += 1;
                    "Entry No." += 1;
                    InitFromCRMOptionMapping(CRMOptionMapping);
                    if DoesOneRecordExist() then
                        Insert()
                    else
                        CRMOptionMapping.Delete();
                until ((CRMOptionMapping.Next() = 0) or (cnt = 100));
        exit(cnt);
    end;

    procedure GetRecDescription() Result: Text
    var
        RecRef: RecordRef;
        PKFilter: Text;
        Delimiter: Text;
        Pos: Integer;
    begin
        if RecRef.Get("Record ID") then begin
            RecRef.SetRecFilter();
            PKFilter := RecRef.GetView();
            repeat
                Pos := StrPos(PKFilter, '=FILTER(');
                if Pos <> 0 then begin
                    PKFilter := CopyStr(PKFilter, Pos + 8);
                    Result += Delimiter + CopyStr(PKFilter, 1, StrPos(PKFilter, ')') - 1);
                    Delimiter := ',';
                end;
            until Pos = 0;
        end;
    end;

    local procedure GetTableCaption(): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if "Table ID" <> 0 then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table ID") then
                exit(AllObjWithCaption."Object Caption");
    end;

    procedure InitFromCRMIntegrationRecord(CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        Init();

        Validate("Table ID", CRMIntegrationRecord."Table ID");
        Validate("Integration ID", CRMIntegrationRecord."Integration ID");
        Validate("CRM ID", CRMIntegrationRecord."CRM ID");
    end;

    procedure InitFromCRMOptionMapping(CRMOptionMapping: Record "CRM Option Mapping")
    begin
        Init();

        Validate("Table ID", CRMOptionMapping."Table ID");
        Validate("Record ID", CRMOptionMapping."Record ID");
        Validate("CRM Option Id", CRMOptionMapping."Option Value");
    end;

    procedure IsOneRecordDeleted(): Boolean
    begin
        exit("Record Exists" xor "Int. Record Exists");
    end;

    procedure DoBothRecordsExist(): Boolean
    begin
        exit("Record Exists" and "Int. Record Exists");
    end;

    procedure DoesOneRecordExist(): Boolean
    begin
        exit("Record Exists" or "Int. Record Exists");
    end;

    procedure RestoreDeletedRecords()
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]];
        CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]];
    begin
        CollectDeletedRecords(TempCRMSynchConflictBuffer, LocalIdListDictionary, CRMIdListDictionary);
        DeleteCouplings(TempCRMSynchConflictBuffer, LocalIdListDictionary, CRMIdListDictionary);
        CRMIntegrationManagement.CreateNewRecords(LocalIdListDictionary, CRMIdListDictionary);
    end;

    local procedure CollectDeletedRecords(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]]; var CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        MappingDictionary: Dictionary of [Integer, Code[20]];
        LocalIdList: List of [Guid];
        CRMIdList: List of [Guid];
        MappingName: Code[20];
        LocalTableId: Integer;
        CRMTableId: Integer;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        if not TempCRMSynchConflictBuffer.FindSet() then
            exit;

        repeat
            if TempCRMSynchConflictBuffer.IsOneRecordDeleted() then begin
                LocalTableId := TempCRMSynchConflictBuffer."Table ID";
                CRMTableId := TempCRMSynchConflictBuffer."Int. Table ID";
                if not MappingDictionary.ContainsKey(LocalTableId) then
                    if IntegrationTableMapping.FindMapping(LocalTableId, CRMTableId) then begin
                        MappingName := IntegrationTableMapping.Name;
                        MappingDictionary.Add(LocalTableId, MappingName);
                    end;
                if MappingDictionary.Get(LocalTableId, MappingName) then
                    if TempCRMSynchConflictBuffer."Record Exists" then begin
                        if not LocalIdListDictionary.ContainsKey(MappingName) then begin
                            Clear(LocalIdList);
                            LocalIdListDictionary.Add(MappingName, LocalIdList);
                        end;
                        LocalIdList := LocalIdListDictionary.Get(MappingName);
                        LocalIdList.Add(TempCRMSynchConflictBuffer."Integration ID")
                    end else begin
                        if not CRMIdListDictionary.ContainsKey(MappingName) then begin
                            Clear(CRMIdList);
                            CRMIdListDictionary.Add(MappingName, CRMIdList);
                        end;
                        CRMIdList := CRMIdListDictionary.Get(MappingName);
                        CRMIdList.Add(TempCRMSynchConflictBuffer."CRM ID");
                    end;
            end;
        until TempCRMSynchConflictBuffer.Next() = 0;
    end;

    local procedure DeleteCouplings(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]]; var CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    begin
        DeleteCouplingsForLocalRecords(TempCRMSynchConflictBuffer, LocalIdListDictionary);
        DeleteCouplingsForCRMRecords(TempCRMSynchConflictBuffer, CRMIdListDictionary);
    end;

    local procedure DeleteCouplingsForLocalRecords(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempCopyCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        MappingList: List of [Code[20]];
        LocalIdList: List of [Guid];
        IdFilterList: List of [Text];
        IdFilter: Text;
        MappingName: Code[20];
    begin
        MappingList := LocalIdListDictionary.Keys();
        foreach MappingName in MappingList do begin
            LocalIdList := LocalIdListDictionary.Get(MappingName);
            IntegrationRecordSynch.GetIdFilterList(LocalIdList, IdFilterList);
            foreach IdFilter in IdFilterList do
                if IdFilter <> '' then begin
                    CRMIntegrationRecord.SetFilter("Integration ID", IdFilter);
                    CRMIntegrationRecord.DeleteAll();
                    TempCopyCRMSynchConflictBuffer.Copy(TempCRMSynchConflictBuffer, true);
                    TempCopyCRMSynchConflictBuffer.SetFilter("Integration ID", IdFilter);
                    TempCopyCRMSynchConflictBuffer.DeleteAll();
                end;
        end;
    end;

    local procedure DeleteCouplingsForCRMRecords(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; var CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempCopyCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        MappingList: List of [Code[20]];
        CRMIdList: List of [Guid];
        IdFilterList: List of [Text];
        MappingName: Code[20];
        IdFilter: Text;
    begin
        MappingList := CRMIdListDictionary.Keys();
        foreach MappingName in MappingList do begin
            CRMIdList := CRMIdListDictionary.Get(MappingName);
            IntegrationRecordSynch.GetIdFilterList(CRMIdList, IdFilterList);
            foreach IdFilter in IdFilterList do
                if IdFilter <> '' then begin
                    CRMIntegrationRecord.SetFilter("CRM ID", IdFilter);
                    CRMIntegrationRecord.DeleteAll();
                    TempCopyCRMSynchConflictBuffer.Copy(TempCRMSynchConflictBuffer, true);
                    TempCopyCRMSynchConflictBuffer.SetFilter("CRM ID", IdFilter);
                    TempCopyCRMSynchConflictBuffer.DeleteAll();
                end;
        end;
    end;

    procedure SetSelectionFilter(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        SetSelectionFilter(CRMIntegrationRecord, CRMOptionMapping);
    end;

    procedure SetSelectionFilter(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping")
    begin
        SetRange("Record Exists", true);
        SetRange("Int. Record Exists", true);
        if FindSet() then
            repeat
                if CRMIntegrationRecord.Get("CRM ID", "Integration ID") then
                    CRMIntegrationRecord.Mark(true)
                else begin
                    CRMOptionMapping.SetRange("Record ID", "Record ID");
                    if CRMOptionMapping.FindFirst() then
                        CRMOptionMapping.Mark(true);
                end;
            until Next() = 0;
        CRMIntegrationRecord.MarkedOnly(true);
        CRMOptionMapping.MarkedOnly(true);
    end;

    [TryFunction]
    local procedure TryToDeleteCRMRecord(var RecRef: RecordRef)
    begin
        RecRef.Delete(true);
    end;

    procedure UpdateSourceTable(var CRMIntegrationRecord: Record "CRM Integration Record"): Integer
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        exit(UpdateSourceTable(CRMIntegrationRecord, CRMOptionMapping));
    end;

    procedure UpdateSourceTable(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping"): Integer
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        CRMOptionMapping.SetRange("Record ID", "Record ID");
        if not CRMIntegrationRecord.Get("CRM ID", "Integration ID") and not CRMOptionMapping.FindFirst() then
            Delete();
        CRMOptionMapping.SetRange("Record ID");
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        CRMIntegrationRecord.SetRange(Skipped, false);
        if CRMIntegrationRecord.FindSet() then
            repeat
                TempCRMSynchConflictBuffer.SetRange("CRM ID", CRMIntegrationRecord."CRM ID");
                TempCRMSynchConflictBuffer.SetRange("Integration ID", CRMIntegrationRecord."Integration ID");
                TempCRMSynchConflictBuffer.DeleteAll();
            until CRMIntegrationRecord.Next() = 0;
        TempCRMSynchConflictBuffer.Reset();
        CRMOptionMapping.SetRange(Skipped, false);
        if CRMOptionMapping.FindSet() then
            repeat
                TempCRMSynchConflictBuffer.SetRange("CRM Option Id", CRMOptionMapping."Option Value");
                TempCRMSynchConflictBuffer.SetRange("Record ID", CRMOptionMapping."Record ID");
                TempCRMSynchConflictBuffer.DeleteAll();
            until CRMOptionMapping.Next() = 0;
        exit(Count);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCRMIDOnBeforeGetCRMIntegrationRecord(TableID: Integer; var CRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer"; var IsHandled: Boolean)
    begin
    end;
}

