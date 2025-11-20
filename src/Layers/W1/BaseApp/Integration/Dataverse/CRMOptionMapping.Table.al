// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Reflection;

table 5334 "CRM Option Mapping"
{
    Caption = 'CRM Option Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(2; "Option Value"; Integer)
        {
            Caption = 'Option Value';
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(4; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
        }
        field(5; "Integration Field ID"; Integer)
        {
            Caption = 'Integration Field ID';
        }
        field(6; "Option Value Caption"; Text[250])
        {
            Caption = 'Option Value Caption';
        }
#pragma warning disable AS0044	
        field(7; "Last Synch. Result"; Option)
        {
            Caption = 'Last Synch. Result';
            OptionCaption = ' ,Success,Failure';
            OptionMembers = " ",Success,Failure;
        }
#pragma warning restore AS0044
        field(8; Skipped; Boolean)
        {
            Caption = 'Skipped';
        }
        field(9; "Last Synch. Job ID"; Guid)
        {
            Caption = 'Last Synch. Job ID';
        }
#pragma warning disable AS0044
        field(10; "Last Synch. CRM Result"; Option)
        {
            Caption = 'Last Synch. CRM Result';
            OptionCaption = ' ,Success,Failure';
            OptionMembers = " ",Success,Failure;
        }
#pragma warning restore AS0044
        field(11; "Last Synch. CRM Job ID"; Guid)
        {
            Caption = 'Last Synch. CRM Job ID';
        }
        field(12; "Last Synch. Modified On"; DateTime)
        {
            Caption = 'Last Synch. Modified On';
        }
    }

    keys
    {
        key(Key1; "Record ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration Table ID", "Integration Field ID", "Option Value")
        {
        }
        key(Key3; Skipped)
        {
        }
    }

    fieldgroups
    {
    }

    var
        AlreadyMappedErr: Label 'Cannot couple %1 to this %2 record, because the %2 record is already coupled.', Comment = '%1 ID of the record, %2 = Dataverse service name';

    procedure FindRecordID(IntegrationTableID: Integer; IntegrationFieldID: Integer; OptionValue: Integer): Boolean
    begin
        Reset();
        SetRange("Integration Table ID", IntegrationTableID);
        SetRange("Integration Field ID", IntegrationFieldID);
        SetRange("Option Value", OptionValue);
        exit(FindFirst());
    end;

    procedure GetRecordKeyValue(): Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        RecordRef.Get("Record ID");
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        exit(Format(FieldRef.Value));
    end;

    procedure AssertCRMOptionIdCanBeMapped(NAVRecordID: RecordId; CRMOptionId: Integer)
    var
        CRMProductName: Codeunit "CRM Product Name";
    begin
        Reset();
        SetRange("Table ID", NAVRecordID.TableNo());
        SetRange("Option Value", CRMOptionId);
        if FindFirst() then
            Error(AlreadyMappedErr, Format(NAVRecordID, 0, 1), CRMProductName.CDSServiceName());
    end;

    procedure InsertRecord(NAVRecordID: RecordId; CRMOptionId: Integer; CRMOptionValue: Text[250]): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Reset();
        Init();
        "Record ID" := NAVRecordID;
        "Option Value" := CRMOptionId;
        "Option Value Caption" := CRMOptionValue;
        "Table ID" := NAVRecordID.TableNo();
        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, NAVRecordID.TableNo());
        "Integration Table ID" := IntegrationTableMapping."Integration Table ID";
        "Integration Field ID" := IntegrationTableMapping."Integration Table UID Fld. No.";
        exit(Insert(true));
    end;

    procedure IsCRMRecordRefMapped(CRMRecordRef: RecordRef; var CRMOptionMapping: Record "CRM Option Mapping"): Boolean
    var
        CRMAccount: Record "CRM Account";
        CRMPaymentTerms: Record "CRM Payment Terms";
        CRMFreightTerms: Record "CRM Freight Terms";
        CRMShippingMethod: Record "CRM Shipping Method";
        Handled: Boolean;
    begin
        CRMOptionMapping.Reset();
        OnIsCRMRecordRefMapped(CRMRecordRef, CRMOptionMapping, Handled);
        if Handled then
            exit(CRMOptionMapping.FindFirst());

        case
            CRMRecordRef.Number of
            Database::"CRM Payment Terms":
                begin
                    CRMOptionMapping.SetRange("Integration Table ID", Database::"CRM Account");
                    CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(PaymentTermsCodeEnum));
                    CRMOptionMapping.SetRange("Option Value", CRMRecordRef.Field(CRMPaymentTerms.FieldNo("Option Id")).Value());
                end;
            Database::"CRM Freight Terms":
                begin
                    CRMOptionMapping.SetRange("Integration Table ID", Database::"CRM Account");
                    CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum));
                    CRMOptionMapping.SetRange("Option Value", CRMRecordRef.Field(CRMFreightTerms.FieldNo("Option Id")).Value());
                end;
            Database::"CRM Shipping Method":
                begin
                    CRMOptionMapping.SetRange("Integration Table ID", Database::"CRM Account");
                    CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum));
                    CRMOptionMapping.SetRange("Option Value", CRMRecordRef.Field(CRMShippingMethod.FieldNo("Option Id")).Value());
                end;
            else
                exit(false);
        end;
        exit(CRMOptionMapping.FindFirst());
    end;

    procedure IsOptionMappingSkipped(RecRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    begin
        if DirectionToIntTable then begin
            Rec.SetRange("Record ID", RecRef.RecordId);
            if Rec.FindFirst() then
                exit(Rec.Skipped);
        end else
            if IsCRMRecordRefMapped(RecRef, Rec) then
                exit(Rec.Skipped);
    end;

    procedure MarkLastSynchAsFailure(SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobId: Guid; var MarkedAsSkipped: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Found: Boolean;
    begin
        if DirectionToIntTable then begin
            SetRange("Record ID", SourceRecRef.RecordId);
            Found := FindFirst();
        end else
            Found := IsCRMRecordRefMapped(SourceRecRef, Rec);

        if Found then begin
            if MarkedAsSkipped then
                Skipped := true;
            if DirectionToIntTable then begin
                if (not Skipped) and ("Last Synch. CRM Result" = "Last Synch. CRM Result"::Failure) then
                    Skipped := CRMIntegrationRecord.IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. CRM Job ID", JobId);
                "Last Synch. CRM Job ID" := JobId;
                "Last Synch. CRM Result" := "Last Synch. CRM Result"::Failure;
            end else begin
                if (not Skipped) and ("Last Synch. Result" = "Last Synch. Result"::Failure) then
                    Skipped := CRMIntegrationRecord.IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. Job ID", JobId);
                "Last Synch. Job ID" := JobId;
                "Last Synch. Result" := "Last Synch. Result"::Failure;
            end;
            if Skipped then
                MarkedAsSkipped := true;
            Modify(true);
        end;
    end;

    procedure UpdateOptionMapping(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; JobId: Guid)
    var
        CRMProductName: Codeunit "CRM Product Name";
        IntOptionSynchInvoke: Codeunit "Int. Option Synch. Invoke";
        LastModifiedOn: DateTime;
    begin
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            if IsCRMRecordRefMapped(SourceRecordRef, Rec) then begin
                if Rec."Record ID" <> DestinationRecordRef.RecordId then
                    Error(AlreadyMappedErr, DestinationRecordRef.RecordId, CRMProductName.CDSServiceName());

                Rec."Last Synch. Job ID" := JobId;
                Rec."Last Synch. Result" := "Last Synch. Result"::Success;
                Rec."Option Value Caption" := GetRecordRefOptionValue(SourceRecordRef);
            end else
                if InsertRecord(DestinationRecordRef.RecordId, GetRecordRefOptionId(SourceRecordRef), GetRecordRefOptionValue(SourceRecordRef)) then begin
                    Rec."Last Synch. Job ID" := JobId;
                    Rec."Last Synch. Result" := "Last Synch. Result"::Success;
                end;
        end else begin
            Rec.SetRange("Record ID", SourceRecordRef.RecordId);
            if Rec.FindFirst() then begin
                if Rec."Option Value" <> GetRecordRefOptionId(DestinationRecordRef) then
                    Error(AlreadyMappedErr, GetRecordRefOptionValue(DestinationRecordRef), CRMProductName.CDSServiceName());

                Rec."Last Synch. CRM Job ID" := JobId;
                Rec."Last Synch. CRM Result" := "Last Synch. CRM Result"::Success;
                Rec."Option Value Caption" := GetRecordRefOptionValue(DestinationRecordRef);
            end else
                if InsertRecord(SourceRecordRef.RecordId, GetRecordRefOptionId(DestinationRecordRef), GetRecordRefOptionValue(DestinationRecordRef)) then begin
                    Rec."Last Synch. CRM Job ID" := JobId;
                    Rec."Last Synch. CRM Result" := "Last Synch. CRM Result"::Success;
                end;
            LastModifiedOn := IntOptionSynchInvoke.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
            if LastModifiedOn > Rec."Last Synch. Modified On" then
                Rec."Last Synch. Modified On" := LastModifiedOn;
        end;
        Rec.Modify(true);
    end;

    procedure GetRecordRefOptionId(RecRef: RecordRef): Integer
    begin
        exit(RecRef.Field(1).Value());
    end;

    procedure GetRecordRefOptionValue(RecRef: RecordRef): Text[250]
    begin
        exit(RecRef.Field(2).Value());
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
            exit(GetErrorForJobID("Last Synch. Job ID", IntegrationSynchJobErrors));
    end;

    internal procedure GetMetadataInfo(RecRef: RecordRef; var EntityName: Text; var FieldName: Text)
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(Database::"CRM Account") then
            EntityName := TableMetadata.ExternalName;

        case RecRef.Number() of
            Database::"CRM Payment Terms":
                FieldName := 'paymenttermscode';
            Database::"CRM Freight Terms":
                FieldName := 'address1_freighttermscode';
            Database::"CRM Shipping Method":
                FieldName := 'address1_shippingmethodcode';
        end;

        OnGetMetadataInfo(RecRef, EntityName, FieldName);
    end;

    internal procedure GetDocumentMetadataInfo(RecRef: RecordRef; DocumentType: Option "Order","Quote","Invoice"; var EntityName: Text; var FieldName: Text)
    var
        TableMetadata: Record "Table Metadata";
    begin
        case DocumentType of
            DocumentType::Order:
                if TableMetadata.Get(Database::"CRM Salesorder") then
                    EntityName := TableMetadata.ExternalName;
            DocumentType::Quote:
                if TableMetadata.Get(Database::"CRM Quote") then
                    EntityName := TableMetadata.ExternalName;
            DocumentType::Invoice:
                if TableMetadata.Get(Database::"CRM Invoice") then
                    EntityName := TableMetadata.ExternalName;
        end;

        case RecRef.Number() of
            Database::"CRM Payment Terms":
                FieldName := 'paymenttermscode';
            Database::"CRM Freight Terms":
                if DocumentType <> DocumentType::Invoice then
                    FieldName := 'freighttermscode';
            Database::"CRM Shipping Method":
                FieldName := 'shippingmethodcode';
        end;
    end;

    local procedure GetErrorForJobID(JobID: Guid; var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if IntegrationSynchJob.Get(JobID) then
            if IntegrationSynchJob."Synch. Direction" = IntegrationSynchJob."Synch. Direction"::FromIntegrationTable then
                exit(IntegrationSynchJob.GetErrorForRecordID("Record ID", IntegrationSynchJobErrors));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCRMRecordRefMapped(CRMRecordRef: RecordRef; var CRMOptionMapping: Record "CRM Option Mapping"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMetadataInfo(CRMRecordRef: RecordRef; var EntityName: Text; var FieldName: Text)
    begin
    end;
}

