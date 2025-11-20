// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Reflection;

table 5332 "Coupling Record Buffer"
{
    Caption = 'Coupling Record Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "NAV Name"; Text[250])
        {
            Caption = 'NAV Name';
            DataClassification = SystemMetadata;
        }
        field(2; "CRM Name"; Text[250])
        {
            Caption = 'CRM Name';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                LookUpCRMName();
            end;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
                CRMOptionMapping: Record "CRM Option Mapping";
            begin
                if "Is Option" then begin
                    if FindCRMOptionByName("CRM Name", "CRM Table ID") then begin
                        if "Saved CRM Option Id" <> "CRM Option Id" then
                            CRMOptionMapping.AssertCRMOptionIdCanBeMapped("NAV Record ID", "CRM Option Id");
                    end else
                        Error(NoSuchCRMRecordErr, "CRM Name", CRMProductName.CDSServiceName());
                end else
                    if FindCRMRecordByName("CRM Name") then begin
                        if "Saved CRM ID" <> "CRM ID" then
                            CRMIntegrationRecord.AssertRecordIDCanBeCoupled("NAV Record ID", "CRM ID");
                        CalcCRMName();
                    end else
                        Error(NoSuchCRMRecordErr, "CRM Name", CRMProductName.CDSServiceName());
            end;
        }
        field(3; "NAV Table ID"; Integer)
        {
            Caption = 'NAV Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                IntegrationTableMapping: Record "Integration Table Mapping";
            begin
                IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                IntegrationTableMapping.SetRange("Table ID", "NAV Table ID");
                IntegrationTableMapping.SetRange("Delete After Synchronization", false);
                if IntegrationTableMapping.FindFirst() then
                    "CRM Table Name" := IntegrationTableMapping.Name
                else
                    "CRM Table Name" := '';
            end;
        }
        field(4; "CRM Table ID"; Integer)
        {
            Caption = 'CRM Table ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Sync Action"; Option)
        {
            Caption = 'Sync Action';
            DataClassification = SystemMetadata;
            OptionCaption = 'Do Not Synchronize,To Integration Table,From Integration Table';
            OptionMembers = "Do Not Synchronize","To Integration Table","From Integration Table";
        }
        field(8; "NAV Record ID"; RecordID)
        {
            Caption = 'NAV Record ID';
            DataClassification = CustomerContent;
        }
        field(9; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CalcCRMName();
            end;
        }
        field(10; "Create New"; Boolean)
        {
            Caption = 'Create New';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                NullGUID: Guid;
            begin
                if "Create New" then begin
                    "Saved Sync Action" := "Sync Action";
                    "Saved CRM ID" := "CRM ID";
                    "Saved CRM Option Id" := "CRM Option Id";
                    Validate("Sync Action", "Sync Action"::"To Integration Table");
                    Clear(NullGUID);
                    if not "Is Option" then
                        Validate("CRM ID", NullGUID)
                    else
                        Validate("CRM Option Id", 0);
                end else begin
                    Validate("Sync Action", "Saved Sync Action");
                    if not "Is Option" then
                        Validate("CRM ID", "Saved CRM ID")
                    else
                        Validate("CRM Option Id", "Saved CRM Option Id");
                end;
            end;
        }
        field(11; "Saved Sync Action"; Option)
        {
            Caption = 'Saved Sync Action';
            DataClassification = SystemMetadata;
            OptionCaption = 'Do Not Synchronize,To Integration Table,From Integration Table';
            OptionMembers = "Do Not Synchronize","To Integration Table","From Integration Table";
        }
        field(12; "Saved CRM ID"; Guid)
        {
            Caption = 'Saved CRM ID';
            DataClassification = SystemMetadata;
        }
        field(13; "CRM Table Name"; Code[20])
        {
            Caption = 'CRM Table Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(14; "CRM Option Id"; Integer)
        {
            Caption = 'CRM Option Id';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CalcCRMName()
            end;
        }
        field(15; "Saved CRM Option Id"; Integer)
        {
            Caption = 'Saved CRM Option Id';
            DataClassification = SystemMetadata;
        }
        field(16; "Is Option"; Boolean)
        {
            Caption = 'Is Option';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "NAV Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMProductName: Codeunit "CRM Product Name";

        InitialSynchDisabledErr: Label 'No initial synchronization direction was specified because initial synchronization was disabled.';
        NoSuchCRMRecordErr: Label 'A record with the name %1 does not exist in %2.', Comment = '%1 = The record name entered by the user, %2 = Dataverse service name';

    procedure Initialize(NAVRecordID: RecordID; IsOption: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordRef: RecordRef;
    begin
        RecordRef := NAVRecordID.GetRecord();
        RecordRef.Find();

        Init();
        Validate("NAV Table ID", NAVRecordID.TableNo);
        "NAV Record ID" := NAVRecordID;
        "NAV Name" := NameValue(RecordRef);
        "Is Option" := IsOption;
        "CRM Table ID" := CRMSetupDefaults.GetCRMTableNo("NAV Table ID");
        if not IsOption then begin
            if CRMSetupDefaults.GetDefaultDirection("NAV Table ID") = IntegrationTableMapping.Direction::FromIntegrationTable then
                Validate("Sync Action", "Sync Action"::"From Integration Table")
            else
                Validate("Sync Action", "Sync Action"::"To Integration Table");

            if FindCRMId() then
                if CalcCRMName() then begin
                    Validate("Sync Action", "Sync Action"::"Do Not Synchronize");
                    "Saved CRM ID" := "CRM ID";
                end;
        end else begin
            if IntegrationTableMapping.FindMappingForTable(RecordRef.Number) then
                if IntegrationTableMapping.GetDirection() = IntegrationTableMapping.Direction::FromIntegrationTable then
                    Validate("Sync Action", "Sync Action"::"From Integration Table")
                else
                    Validate("Sync Action", "Sync Action"::"To Integration Table");
            if FindCRMOptionId() then begin
                Validate("Sync Action", "Sync Action"::"Do Not Synchronize");
                "Saved CRM Option Id" := "CRM Option Id";
            end;
        end;
    end;

    procedure Initialize(NAVRecordID: RecordID)
    begin
        Initialize(NAVRecordID, false);
    end;

    local procedure FindCRMId(): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.FindIDFromRecordID("NAV Record ID", "CRM ID"))
    end;

    local procedure FindCRMOptionId(): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Record ID", Rec."NAV Record ID");
        if CRMOptionMapping.FindFirst() then begin
            Rec."CRM Option Id" := CRMOptionMapping."Option Value";
            Rec."CRM Name" := CRMOptionMapping."Option Value Caption";
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindCRMRecordByName(var CRMName: Text[250]): Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Found: Boolean;
    begin
        RecordRef.Open("CRM Table ID");
        FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo("CRM Table ID"));
        FieldRef.SetRange(CRMName);
        if RecordRef.FindFirst() then
            Found := true
        else begin
            RecordRef.CurrentKeyIndex(2); // "Name" key should be the second key in a CRM table
            FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo("CRM Table ID"));
            FieldRef.SetFilter("CRM Name" + '*');
            if RecordRef.FindFirst() then
                Found := true;
        end;
        if Found then begin
            CRMName := NameValue(RecordRef);
            "CRM ID" := PrimaryKeyValue(RecordRef);
        end;
        RecordRef.Close();
        exit(Found);
    end;

    local procedure FindCRMOptionByName(var CRMName: Text[250]; CRMTableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EntityName: Text;
        FieldName: Text;
        OptionId: Integer;
        Found: Boolean;
        Handled: Boolean;
        OptionSetMetadataDictionary: Dictionary of [Integer, Text];
    begin
        OnFindCRMOptionByName(CRMTableId, EntityName, FieldName, Handled);
        if not Handled then begin
            if TableMetadata.Get(Database::"CRM Account") then
                EntityName := TableMetadata.ExternalName
            else
                exit(Found);
            case CRMTableId of
                Database::"CRM Payment Terms":
                    FieldName := 'paymenttermscode';
                Database::"CRM Freight Terms":
                    FieldName := 'address1_freighttermscode';
                Database::"CRM Shipping Method":
                    FieldName := 'address1_shippingmethodcode';
            end;
        end;
        OptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(EntityName, FieldName);
        foreach OptionId in OptionSetMetadataDictionary.Keys() do
            if OptionSetMetadataDictionary.Get(OptionId).StartsWith(CRMName) then begin
                CRMName := CopyStr(OptionSetMetadataDictionary.Get(OptionId), 1, MaxStrLen(CRMName));
                "CRM Option Id" := OptionId;
                Found := true;
                break;
            end;
        exit(Found);
    end;

    procedure LookUpCRMName()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if "Is Option" then begin
            if LookupCRMTables.LookupOptions("CRM Table ID", "NAV Table ID", "Saved CRM Option Id", "CRM Option Id", "CRM Name") then
                if "Saved CRM Option Id" <> "CRM Option Id" then
                    CRMOptionMapping.AssertCRMOptionIdCanBeMapped("NAV Record ID", "CRM Option Id")
        end else
            if LookupCRMTables.Lookup("CRM Table ID", "NAV Table ID", "Saved CRM ID", "CRM ID") then begin
                if "Saved CRM ID" <> "CRM ID" then
                    CRMIntegrationRecord.AssertRecordIDCanBeCoupled("NAV Record ID", "CRM ID");
                CalcCRMName();
            end;
    end;

    local procedure CalcCRMName() Found: Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        RecordRef: RecordRef;
    begin
        if not "Is Option" then begin
            RecordRef.Open("CRM Table ID");
            Found := FindCRMRecRefByPK(RecordRef, "CRM ID");
            if Found then
                "CRM Name" := NameValue(RecordRef)
            else
                "CRM Name" := '';
            RecordRef.Close();
        end else begin
            if "CRM Option Id" = 0 then begin
                "CRM Name" := '';
                exit;
            end;
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Table ID", "NAV Table ID");
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            if IntegrationTableMapping.FindFirst() then begin
                CRMIntegrationTableSynch.LoadCRMOption(RecordRef, IntegrationTableMapping);
                if FindCRMRecRefByOptionId(RecordRef, "CRM Option Id") then
                    "CRM Name" := CRMOptionMapping.GetRecordRefOptionValue(RecordRef)
                else
                    "CRM Name" := '';
            end;
        end;
    end;

    procedure GetInitialSynchronizationDirection(): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if "Sync Action" = "Sync Action"::"Do Not Synchronize" then
            Error(InitialSynchDisabledErr);

        if "Sync Action" = "Sync Action"::"To Integration Table" then
            exit(IntegrationTableMapping.Direction::ToIntegrationTable);

        exit(IntegrationTableMapping.Direction::FromIntegrationTable);
    end;

    procedure GetPerformInitialSynchronization(): Boolean
    begin
        exit("Sync Action" <> "Sync Action"::"Do Not Synchronize");
    end;

    local procedure NameValue(RecordRef: RecordRef): Text[250]
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo(RecordRef.Number));
        exit(CopyStr(Format(FieldRef.Value), 1, MaxStrLen("CRM Name")));
    end;

    local procedure PrimaryKeyValue(RecordRef: RecordRef): Guid
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        exit(FieldRef.Value);
    end;

    local procedure FindCRMRecRefByPK(var RecordRef: RecordRef; CRMId: Guid): Boolean
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        FieldRef.SetRange(CRMId);
        exit(RecordRef.FindFirst());
    end;

    local procedure FindCRMRecRefByOptionId(var RecordRef: RecordRef; CRMOptionId: Integer): Boolean
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        FieldRef.SetRange(CRMOptionId);
        exit(RecordRef.FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCRMOptionByName(CRMTableID: Integer; var EntityName: Text; var FieldName: Text; var Handled: Boolean)
    begin
    end;
}

