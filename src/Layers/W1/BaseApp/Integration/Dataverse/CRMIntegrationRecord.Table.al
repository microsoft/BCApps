// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Reflection;

table 5331 "CRM Integration Record"
{
    Caption = 'CRM Integration Record';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            Description = 'An ID of a record in Microsoft Dynamics CRM';

            trigger OnValidate()
            begin
                Clear("Last Synch. CRM Job ID");
                "Last Synch. CRM Modified On" := 0DT;
                "Last Synch. CRM Result" := "Last Synch. CRM Result"::" ";
                Skipped := false;
            end;
        }
        field(3; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';

            trigger OnValidate()
            begin
                Clear("Last Synch. Job ID");
                "Last Synch. Modified On" := 0DT;
                "Last Synch. Result" := "Last Synch. Result"::" ";
                Skipped := false;
            end;
        }
        field(4; "Last Synch. Modified On"; DateTime)
        {
            Caption = 'Last Synch. Modified On';
        }
        field(5; "Last Synch. CRM Modified On"; DateTime)
        {
            Caption = 'Last Synch. CRM Modified On';
        }
        field(6; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                CheckTableID();
            end;
        }
#pragma warning disable AS0044
        field(7; "Last Synch. Result"; Option)
        {
            Caption = 'Last Synch. Result';
            OptionCaption = ' ,Success,Failure';
            OptionMembers = " ",Success,Failure;
        }
        field(8; "Last Synch. CRM Result"; Option)
        {
            Caption = 'Last Synch. CRM Result';
            OptionCaption = ' ,Success,Failure';
            OptionMembers = " ",Success,Failure;
        }
#pragma warning restore AS0044
        field(9; "Last Synch. Job ID"; Guid)
        {
            Caption = 'Last Synch. Job ID';
        }
        field(10; "Last Synch. CRM Job ID"; Guid)
        {
            Caption = 'Last Synch. CRM Job ID';
        }
        field(11; Skipped; Boolean)
        {
            Caption = 'Skipped';
            Editable = false;

            trigger OnValidate()
            begin
                if not Skipped then
                    if "Table ID" = Database::Customer then
                        "Statistics Uploaded" := false;
            end;
        }
        field(13; "Statistics Uploaded"; Boolean)
        {
            Caption = 'Statistics Uploaded';
        }
        field(14; "Archived Sales Order"; Boolean)
        {
            Caption = 'Archived Sales Order';
            Editable = false;
        }
        field(15; "Archived Sales Order Updated"; Boolean)
        {
            Caption = 'Archived Sales Order Updated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "CRM ID", "Integration ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration ID")
        {
        }
        key(Key3; "Last Synch. Modified On", "Integration ID")
        {
        }
        key(Key4; "Last Synch. CRM Modified On", "CRM ID")
        {
        }
        key(Key5; Skipped, "Table ID")
        {
        }
        key(Key6; "Table ID")
        {
        }
        key(Key7; "Statistics Uploaded", Skipped, "Table ID")
        {
        }
        key(Key8; "Integration ID", "Statistics Uploaded", Skipped, "Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckTableID();
    end;

    trigger OnDelete()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if Rec."Table ID" = Database::"Sales Header" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                if SalesHeader.GetBySystemId(Rec."Integration ID") then begin
                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    if SalesLine.FindSet() then
                        repeat
                            CRMIntegrationRecord.SetRange("Integration ID", SalesLine.SystemId);
                            CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Line");
                            if CRMIntegrationRecord.FindFirst() then
                                CRMIntegrationRecord.Delete();
                        until SalesLine.Next() = 0;
                end;
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

#pragma warning disable AA0470
        IntegrationRecordNotFoundErr: Label 'The integration record for entity %1 was not found.';
#pragma warning restore AA0470
        CRMIdAlreadyMappedErr: Label 'Cannot couple %1 to this %3 record, because the %3 record is already coupled to %2.', Comment = '%1 ID of the record, %2 ID of the already mapped record, %3 = Dataverse service name';
        RecordRefAlreadyMappedErr: Label 'Cannot couple %1 to this %3 record, because the %3 record is already coupled to %2.', Comment = '%1 ID of the record, %2 ID of the already mapped record, %3 = table caption';
        RecordIdAlreadyMappedErr: Label 'Cannot couple the %2 record to %1, because %1 is already coupled to another %2 record.', Comment = '%1 ID from the record, %2 ID of the already mapped record';
        ZeroTableIdErr: Label 'Table ID must be specified.';
        ZeroTableIdTxt: Label 'Table ID is zero in CRM Integration Record. System ID: %1, CRM ID: %2', Locked = true;
        FixedTableIdTxt: Label 'Table ID has been fixed in CRM Integration Record. New Table ID: %1, System ID: %2, CRM ID: %3', Locked = true;
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;

    local procedure CheckTableID()
    begin
        if "Table ID" = 0 then
            if not IsNullGuid("Integration ID") then
                if not IsTemporary() then
                    Error(ZeroTableIdErr);
    end;

    [Scope('OnPrem')]
    procedure GetTableID(): Integer
    begin
        if "Table ID" <> 0 then
            exit("Table ID");

        if IsNullGuid("Integration ID") then
            exit(0);

        if RepairTableIdByLocalRecord() then
            exit("Table ID");

        Session.LogMessage('0000DQ9', StrSubstNo(ZeroTableIdTxt, "Integration ID", "CRM ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        exit(0);
    end;

    internal procedure RepairTableIdByLocalRecord(): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if "Table ID" <> 0 then
            exit(true);

        if IsNullGuid("Integration ID") then
            exit(true);

        if FindMappingByLocalRecordId(IntegrationTableMapping) then begin
            "Table ID" := IntegrationTableMapping."Table ID";
            Modify();
            Session.LogMessage('0000DQ7', StrSubstNo(FixedTableIdTxt, "Table ID", "Integration ID", "CRM ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            exit(true);
        end;

        exit(false);
    end;

    internal procedure RepairTableIdByCRMRecord(): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if "Table ID" <> 0 then
            exit(true);

        if IsNullGuid("Integration ID") then
            exit(true);

        if FindMappingByCRMRecordId(IntegrationTableMapping) then
            if IntegrationTableMapping."Table ID" <> 0 then begin
                "Table ID" := IntegrationTableMapping."Table ID";
                Modify();
                Session.LogMessage('0000DQ8', StrSubstNo(FixedTableIdTxt, "Table ID", "Integration ID", "CRM ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                exit(true);
            end;

        exit(false);
    end;

    local procedure FindMappingByLocalRecordId(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        LocalRecordRef: RecordRef;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter("Table ID", '<>0');
        if IntegrationTableMapping.FindSet() then
            repeat
                LocalRecordRef.Close();
                LocalRecordRef.Open(IntegrationTableMapping."Table ID");
                if LocalRecordRef.GetBySystemId("Integration ID") then
                    exit(true);
            until IntegrationTableMapping.Next() = 0;
        exit(false);
    end;

    local procedure FindMappingByCRMRecordId(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        CRMRecordRef: RecordRef;
        CRMIdFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
        CRMTableView: Text;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter("Integration Table ID", '<>0');
        if IntegrationTableMapping.FindSet() then
            repeat
                CRMRecordRef.Close();
                CRMTableView := IntegrationTableMapping.GetIntegrationTableFilter();
                CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                PrimaryKeyRef := CRMRecordRef.KeyIndex(1);
                CRMIdFieldRef := PrimaryKeyRef.FieldIndex(1);
                CRMRecordRef.SetView(CRMTableView);
                CRMIdFieldRef.SetRange("CRM ID");
                if not CRMRecordRef.IsEmpty() then
                    exit(true);
            until IntegrationTableMapping.Next() = 0;
        exit(false);
    end;

    local procedure GetCRMIdFromRecRef(CRMRecordRef: RecordRef): Guid
    var
        CRMIdFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := CRMRecordRef.KeyIndex(1);
        CRMIdFieldRef := PrimaryKeyRef.FieldIndex(1);
        exit(CRMIdFieldRef.Value);
    end;

    procedure GetCRMRecordID(IntegrationTableID: Integer; var CRMRecID: RecordID) Found: Boolean
    var
        RecRef: RecordRef;
    begin
        Found := GetCRMRecordRef(IntegrationTableID, RecRef);
        CRMRecID := RecRef.RecordId;
        RecRef.Close();
    end;

    procedure GetCRMRecordRef(IntegrationTableID: Integer; var RecRef: RecordRef): Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        if IntegrationTableID = 0 then
            exit(false);

        RecRef.Open(IntegrationTableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange("CRM ID");
        exit(RecRef.FindFirst());
    end;

    procedure GetLatestJobIDFilter(): Text
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if IsNullGuid("Last Synch. Job ID") and IsNullGuid("Last Synch. CRM Job ID") then
            exit('');
        IntegrationSynchJob.SetFilter(ID, '%1|%2', "Last Synch. Job ID", "Last Synch. CRM Job ID");
        exit(IntegrationSynchJob.GetFilter(ID));
    end;

    procedure GetLatestError(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    begin
        if not IsNullGuid("Last Synch. CRM Job ID") then
            exit(GetErrorForJobID("Last Synch. CRM Job ID", IntegrationSynchJobErrors));
        if not IsNullGuid("Last Synch. Job ID") then
            exit(GetErrorForJobID("Last Synch. Job ID", IntegrationSynchJobErrors))
    end;

    local procedure GetErrorForJobID(JobID: Guid; var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMRecId: RecordID;
        RecId: RecordId;
    begin
        if IntegrationSynchJob.Get(JobID) then
            case IntegrationSynchJob."Synch. Direction" of
                IntegrationSynchJob."Synch. Direction"::ToIntegrationTable:
                    if FindRecordId(RecId) then
                        exit(IntegrationSynchJob.GetErrorForRecordID(RecId, IntegrationSynchJobErrors));
                IntegrationSynchJob."Synch. Direction"::FromIntegrationTable:
                    if IntegrationTableMapping.Get(IntegrationSynchJob."Integration Table Mapping Name") then
                        if GetCRMRecordID(IntegrationTableMapping."Integration Table ID", CRMRecId) then
                            exit(IntegrationSynchJob.GetErrorForRecordID(CRMRecId, IntegrationSynchJobErrors));
            end;
    end;

    procedure InsertRecord(CRMID: Guid; SysId: Guid; TableId: Integer)
    begin
        Reset();
        Init();
        "CRM ID" := CRMID;
        "Integration ID" := SysId;
        "Table ID" := TableId;
        Insert(true);
    end;

    procedure IsCRMRecordRefCoupled(CRMRecordRef: RecordRef): Boolean
    begin
        exit(FindByCRMID(GetCRMIdFromRecRef(CRMRecordRef)));
    end;

    procedure IsIntegrationIdCoupled(IntegrationID: Guid; TableId: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(FindRowFromIntegrationID(IntegrationID, TableId, CRMIntegrationRecord));
    end;

    procedure IsRecordCoupled(DestinationRecordID: RecordID): Boolean
    var
        CRMId: Guid;
    begin
        exit(FindIDFromRecordID(DestinationRecordID, CRMId));
    end;

    procedure FindByCRMID(CRMID: Guid): Boolean
    begin
        Reset();
        SetRange("CRM ID", CRMID);
        exit(FindFirst());
    end;

    procedure FindValidByCRMID(CRMID: Guid) Found: Boolean
    var
        RecRef: RecordRef;
        RecId: RecordId;
    begin
        Clear("CRM ID");
        Reset();
        SetRange("CRM ID", CRMID);
        if FindFirst() then
            if FindRecordId(RecId) then
                Found := RecRef.Get(RecId);
    end;

    procedure FindRecordId(var RecId: RecordId): Boolean
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        EmptyRecId: RecordId;
        FoundRecId: RecordId;
        TableId: Integer;
    begin
        TableId := GetTableID();
        if TableId = 0 then
            exit(false);

        RecRef.Open(TableId);
        FldRef := RecRef.FIELD(RecRef.SystemIdNo());
        FldRef.SetRange("Integration ID");
        if RecRef.FindFirst() then
            FoundRecId := RecRef.RecordId();

        if FoundRecId <> EmptyRecId then
            RecId := FoundRecId;

        exit(FoundRecId <> EmptyRecId);
    end;

    procedure FindSystemIdByRecordId(var SysId: Guid; RecId: RecordId): Boolean
    var
        RecRef: RecordRef;
    begin
        if not RecRef.Get(RecId) then
            exit(false);

        exit(FindSystemIdByRecordRef(SysId, RecRef));
    end;

    procedure FindSystemIdByRecordRef(var SysId: Guid; RecordRef: RecordRef): Boolean
    begin
        if RecordRef.Number() = 0 then
            exit(false);

        SysId := RecordRef.Field(RecordRef.SystemIdNo()).Value();
        exit(not IsNullGuid(SysId));
    end;

    procedure FindByRecordID(RecID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromRecordID(RecID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            exit(true);
        end;
    end;

    procedure FindValidByRecordID(RecID: RecordID; IntegrationTableID: Integer) Found: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMRecId: RecordID;
    begin
        Clear("CRM ID");
        if FindRowFromRecordID(RecID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            Found := GetCRMRecordID(IntegrationTableID, CRMRecId);
        end;
    end;

    procedure FindRecordIDFromID(SourceCRMID: Guid; DestinationTableID: Integer; var DestinationRecordId: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecId: RecordId;
    begin
        if FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then begin
            if CRMIntegrationRecord.FindRecordId(RecId) then
                DestinationRecordId := RecId;
            exit(true);
        end;
    end;

    procedure FindIDFromRecordID(SourceRecordID: RecordID; var DestinationCRMID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromRecordID(SourceRecordID, CRMIntegrationRecord) then begin
            DestinationCRMID := CRMIntegrationRecord."CRM ID";
            exit(true);
        end;
    end;

    procedure FindIDFromRecordRef(SourceRecordRef: RecordRef; var DestinationCRMID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromRecordRef(SourceRecordRef, CRMIntegrationRecord) then begin
            DestinationCRMID := CRMIntegrationRecord."CRM ID";
            exit(true);
        end;
    end;

    local procedure FindIntegrationIDFromCRMID(SourceCRMID: Guid; DestinationTableID: Integer; var DestinationIntegrationID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then begin
            DestinationIntegrationID := CRMIntegrationRecord."Integration ID";
            exit(true);
        end;
    end;

    procedure CoupleCRMIDToRecordID(CRMID: Guid; RecordID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationRecord2: Record "CRM Integration Record";
        ErrCRMID: Guid;
        SysId: Guid;
    begin
        if not FindSystemIdByRecordId(SysId, RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        // Find coupling between CRMID and TableNo
        if not FindRowFromCRMID(CRMID, RecordID.TableNo, CRMIntegrationRecord) then
            // Find rogue coupling beteen CRMID and table 0
            if not FindRowFromCRMID(CRMID, 0, CRMIntegrationRecord) then begin
                // Find other coupling to the record
                if CRMIntegrationRecord2.FindIDFromRecordID(RecordID, ErrCRMID) then
                    Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));

                CRMIntegrationRecord.InsertRecord(CRMID, SysId, RecordID.TableNo);
                exit;
            end;

        // Update Integration ID
        if CRMIntegrationRecord."Integration ID" <> SysId then begin
            if CRMIntegrationRecord2.FindIDFromRecordID(RecordID, ErrCRMID) then
                Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));
            CRMIntegrationRecord.SetNewIntegrationId(SysId);
        end;
    end;

    procedure CoupleCRMIDToRecordRef(CRMID: Guid; RecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationRecord2: Record "CRM Integration Record";
        ErrCRMID: Guid;
        SysId: Guid;
    begin
        if not FindSystemIdByRecordRef(SysId, RecordRef) then
            Error(IntegrationRecordNotFoundErr, Format(RecordRef.RecordId(), 0, 1));

        // Find coupling between CRMID and TableNo
        if not FindRowFromCRMID(CRMID, RecordRef.Number(), CRMIntegrationRecord) then
            // Find rogue coupling beteen CRMID and table 0
            if not FindRowFromCRMID(CRMID, 0, CRMIntegrationRecord) then begin
                // Find other coupling to the record
                if CRMIntegrationRecord2.FindIDFromRecordRef(RecordRef, ErrCRMID) then
                    Error(RecordRefAlreadyMappedErr, CRMId, ErrCRMID, RecordRef.Caption());

                CRMIntegrationRecord.InsertRecord(CRMID, SysId, RecordRef.Number());
                exit;
            end;

        // Update Integration ID
        if CRMIntegrationRecord."Integration ID" <> SysId then begin
            if CRMIntegrationRecord2.FindIDFromRecordRef(RecordRef, ErrCRMID) then
                Error(RecordRefAlreadyMappedErr, CRMId, ErrCRMID, RecordRef.Caption());
            CRMIntegrationRecord.SetNewIntegrationId(SysId);
        end;
    end;

    procedure CoupleRecordIdToCRMID(RecordID: RecordID; CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        IntegrationID: Guid;
    begin
        RecRef.Get(RecordID);
        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo);
        IntegrationID := SystemIdFieldRef.Value();
        if not FindRowFromIntegrationID(IntegrationID, RecRef.Number, CRMIntegrationRecord) then begin
            AssertRecordIDCanBeCoupled(RecordID, CRMID);
            CRMIntegrationRecord.InsertRecord(CRMID, IntegrationID, RecRef.Number);
        end else
            if CRMIntegrationRecord."CRM ID" <> CRMID then begin
                AssertRecordIDCanBeCoupled(RecordID, CRMID);
                CRMIntegrationRecord.SetNewCRMId(CRMID);
            end;
    end;

    procedure RemoveCouplingToRecord(RecordID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SysId: Guid;
    begin
        if not FindSystemIdByRecordId(SysId, RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        if FindRowFromIntegrationID(SysId, RecordID.TableNo, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            CRMIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure RemoveCouplingToRecord(RecordRef: RecordRef): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SysId: Guid;
    begin
        if not FindSystemIdByRecordRef(SysId, RecordRef) then
            Error(IntegrationRecordNotFoundErr, RecordRef.Field(RecordRef.SystemIdNo()).Value());

        if FindRowFromIntegrationID(SysId, RecordRef.Number, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            CRMIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure RemoveCouplingToCRMID(CRMID: Guid; DestinationTableID: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            CRMIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure SetNewCRMId(CRMId: Guid)
    begin
        Delete();
        Validate("CRM ID", CRMId);
        Insert();
    end;

    procedure SetNewIntegrationId(IntegrationId: Guid)
    begin
        Delete();
        Validate("Integration ID", IntegrationId);
        Insert();
    end;

    procedure AssertRecordIDCanBeCoupled(RecordID: RecordID; CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ErrRecordID: RecordID;
        ErrIntegrationID: Guid;
    begin
        if FindIntegrationIDFromCRMID(CRMID, RecordID.TableNo, ErrIntegrationID) then
            if not UncoupleCRMIDIfRecordDeleted(RecordID.TableNo, ErrIntegrationID) then begin
                CRMIntegrationRecord.FindRecordIDFromID(CRMID, RecordID.TableNo, ErrRecordID);
                Error(CRMIdAlreadyMappedErr, Format(RecordID, 0, 1), ErrRecordID, CRMProductName.CDSServiceName());
            end;
    end;

    procedure SetLastSynchResultFailed(SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobId: Guid)
    var
        MarkedAsSkipped: Boolean;
    begin
        SetLastSynchResultFailed(SourceRecRef, DirectionToIntTable, JobId, MarkedAsSkipped);
    end;

    procedure SetLastSynchResultFailed(SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobId: Guid; var MarkedAsSkipped: Boolean)
    var
        Found: Boolean;
    begin
        if DirectionToIntTable then
            Found := FindByRecordID(SourceRecRef.RecordId)
        else
            Found := FindByCRMID(GetCRMIdFromRecRef(SourceRecRef));
        if Found then begin
            if MarkedAsSkipped then
                Skipped := true;
            if DirectionToIntTable then begin
                if (not Skipped) and ("Last Synch. CRM Result" = "Last Synch. CRM Result"::Failure) then
                    Skipped := IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. CRM Job ID", JobId);
                "Last Synch. CRM Job ID" := JobId;
                "Last Synch. CRM Result" := "Last Synch. CRM Result"::Failure
            end else begin
                if (not Skipped) and ("Last Synch. Result" = "Last Synch. Result"::Failure) then
                    Skipped := IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. Job ID", JobId);
                "Last Synch. Job ID" := JobId;
                "Last Synch. Result" := "Last Synch. Result"::Failure;
            end;
            if Skipped then
                MarkedAsSkipped := true;
            Modify(true);
        end;
    end;

    procedure IsSkipped(SourceRecordRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    var
        Found: Boolean;
    begin
        if DirectionToIntTable then
            Found := FindByRecordID(SourceRecordRef.RecordId())
        else
            Found := FindByCRMID(GetCRMIdFromRecRef(SourceRecordRef));
        exit(Skipped);
    end;

    procedure SetLastSynchModifiedOns(SourceCRMID: Guid; DestinationTableID: Integer; CRMLastModifiedOn: DateTime; LastModifiedOn: DateTime; JobId: Guid; Direction: Option)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if not FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then
            exit;

        case Direction of
            IntegrationTableMapping.Direction::FromIntegrationTable:
                begin
                    CRMIntegrationRecord."Last Synch. Job ID" := JobId;
                    CRMIntegrationRecord."Last Synch. Result" := "Last Synch. Result"::Success;
                end;
            IntegrationTableMapping.Direction::ToIntegrationTable:
                begin
                    CRMIntegrationRecord."Last Synch. CRM Job ID" := JobId;
                    CRMIntegrationRecord."Last Synch. CRM Result" := "Last Synch. CRM Result"::Success;
                end;
        end;
        if LastModifiedOn > CRMIntegrationRecord."Last Synch. Modified On" then
            CRMIntegrationRecord."Last Synch. Modified On" := LastModifiedOn;
        if CRMLastModifiedOn > CRMIntegrationRecord."Last Synch. CRM Modified On" then
            CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMLastModifiedOn;
        CRMIntegrationRecord.Modify(true);
    end;

    procedure SetLastSynchCRMModifiedOn(CRMID: Guid; DestinationTableID: Integer; CRMLastModifiedOn: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then begin
            if CRMLastModifiedOn > CRMIntegrationRecord."Last Synch. CRM Modified On" then
                CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMLastModifiedOn;
            CRMIntegrationRecord.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsSameFailureRepeatedTwice(RecRef: RecordRef; LastJobID: Guid; NewJobID: Guid): Boolean
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        LastError: Text;
        NewError: Text;
    begin
        if IsNullGuid(LastJobID) or IsNullGuid(NewJobID) then
            exit(false);
        if IntegrationSynchJob.Get(LastJobID) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRef.RecordId, IntegrationSynchJobErrors) then
                LastError := IntegrationSynchJobErrors.Message;
        if IntegrationSynchJob.Get(NewJobID) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRef.RecordId, IntegrationSynchJobErrors) then
                NewError := IntegrationSynchJobErrors.Message;
        exit((LastError = NewError) and (NewError <> ''));
    end;

    procedure IsModifiedAfterLastSynchonizedCRMRecord(CRMID: Guid; DestinationTableID: Integer; CurrentModifiedOn: DateTime) IsModified: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TypeHelper: Codeunit "Type Helper";
        Handled: Boolean;
    begin
        OnBeforeIsModifiedAfterLastSynchronizedCRMRecord(CRMID, DestinationTableID, CurrentModifiedOn, IsModified, Handled);
        if Handled then
            exit(IsModified);

        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then begin
            if (CRMIntegrationRecord."Last Synch. Result" = CRMIntegrationRecord."Last Synch. Result"::Failure) and (CRMIntegrationRecord.Skipped = false) then
                exit(true);
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMIntegrationRecord."Last Synch. CRM Modified On") > 0);
        end;
    end;

    procedure IsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime) IsModified: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TypeHelper: Codeunit "Type Helper";
        Handled: Boolean;
    begin
        OnBeforeIsModifiedAfterLastSynchronizedRecord(RecordID, CurrentModifiedOn, IsModified, Handled);
        if Handled then
            exit(IsModified);

        if FindRowFromRecordID(RecordID, CRMIntegrationRecord) then begin
            if (CRMIntegrationRecord."Last Synch. CRM Result" = CRMIntegrationRecord."Last Synch. CRM Result"::Failure) and (CRMIntegrationRecord.Skipped = false) then
                exit(true);
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMIntegrationRecord."Last Synch. Modified On") > 0);
        end;
    end;

    procedure IsModifiedAfterLastSynchronizedRecord(RecordRef: RecordRef; CurrentModifiedOn: DateTime) IsModified: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMOptionMapping: Record "CRM Option Mapping";
        TypeHelper: Codeunit "Type Helper";
        Handled: Boolean;
    begin
        if RecordRef.Number() = 0 then
            exit(false);

        if IsNullGuid(RecordRef.Field(RecordRef.SystemIdNo()).Value()) then
            exit(false);

        OnBeforeIsModifiedAfterLastSynchronizedRecord(RecordRef.RecordId(), CurrentModifiedOn, IsModified, Handled);
        if Handled then
            exit(IsModified);

        if FindRowFromRecordRef(RecordRef, CRMIntegrationRecord) then begin
            if (CRMIntegrationRecord."Last Synch. CRM Result" = CRMIntegrationRecord."Last Synch. CRM Result"::Failure) and (CRMIntegrationRecord.Skipped = false) then
                exit(true);
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMIntegrationRecord."Last Synch. Modified On") > 0);
        end;

        CRMOptionMapping.SetRange("Record ID", RecordRef.RecordId);
        if CRMOptionMapping.FindFirst() then begin
            if (CRMOptionMapping."Last Synch. CRM Result" = CRMOptionMapping."Last Synch. CRM Result"::Failure) and (CRMOptionMapping.Skipped = false) then
                exit(true);
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMOptionMapping."Last Synch. Modified On") > 0);
        end;
    end;

    local procedure UncoupleCRMIDIfRecordDeleted(TableId: Integer; IntegrationId: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecId: RecordId;
    begin
        CRMIntegrationRecord."Table ID" := TableId;
        CRMIntegrationRecord."Integration ID" := IntegrationId;
        if not CRMIntegrationRecord.FindRecordId(RecId) then begin
            if FindRowFromIntegrationID(IntegrationId, TableId, CRMIntegrationRecord) then
                CRMIntegrationRecord.Delete();
            exit(true);
        end;
    end;

    procedure DeleteIfRecordDeleted(CRMID: Guid; DestinationTableID: Integer): Boolean
    var
        IntegrationID: Guid;
    begin
        if FindIntegrationIDFromCRMID(CRMID, DestinationTableID, IntegrationID) then
            exit(UncoupleCRMIDIfRecordDeleted(DestinationTableID, IntegrationID));
    end;

    local procedure FindRowFromRecordID(SourceRecordID: RecordID; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    var
        SysId: Guid;
    begin
        if FindSystemIdByRecordId(SysId, SourceRecordID) then
            exit(FindRowFromIntegrationID(SysId, SourceRecordID.TableNo, CRMIntegrationRecord));
    end;

    local procedure FindRowFromRecordRef(SourceRecordRef: RecordRef; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    var
        SysId: Guid;
    begin
        if FindSystemIdByRecordRef(SysId, SourceRecordRef) then
            exit(FindRowFromIntegrationID(SysId, SourceRecordRef.Number, CRMIntegrationRecord));
    end;

    local procedure FindRowFromCRMID(CRMID: Guid; DestinationTableID: Integer; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    begin
        CRMIntegrationRecord.SetRange("CRM ID", CRMID);
        if DestinationTableID <> 0 then
            CRMIntegrationRecord.SetFilter("Table ID", Format(DestinationTableID));
        exit(CRMIntegrationRecord.FindFirst());
    end;

    local procedure FindRowFromIntegrationID(IntegrationID: Guid; TableID: Integer; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    begin
        CRMIntegrationRecord.SetCurrentKey("Integration ID", "Table ID");
        CRMIntegrationRecord.SetFilter("Integration ID", IntegrationID);
        CRMIntegrationRecord.SetRange("Table ID", TableID);
        exit(CRMIntegrationRecord.FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsModifiedAfterLastSynchronizedCRMRecord(CRMID: Guid; DestinationTableID: Integer; CurrentModifiedOn: DateTime; var IsModified: Boolean; var Handled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime; var IsModified: Boolean; var Handled: Boolean);
    begin
    end;
}
