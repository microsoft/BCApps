// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;

table 50155 "BC14CompanyAdditionalSettings"
{
    ReplicateData = false;
    DataPerCompany = false;
    Description = 'Additional Company settings for a BC14 migration';

    fields
    {
        field(1; Name; Text[30])
        {
            TableRelation = "Hybrid Company".Name;
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; "Migrate Receivables Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(3; "Migrate Payables Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(4; "Migrate Inventory Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(5; "Migrate GL Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(6; "Data Migration Started"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = false;
            Caption = 'Data Migration Started';
        }
        field(7; "Data Migration Started At"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Data Migration Started At';
        }
        field(50; "Skip Posting Journal Batches"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = false;
            Caption = 'Skip Posting Journal Batches';
        }
        field(60; Replicate; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Hybrid Company".Replicate where(Name = field(Name)));
            Caption = 'Replicate';
        }
        field(61; ProcessesAreRunning; Boolean)
        {
            InitValue = false;
            DataClassification = SystemMetadata;
            Caption = 'Processes Are Running';
        }
    }

    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

    procedure GetSingleInstance()
    var
        CurrentCompanyName: Text;
    begin
        CurrentCompanyName := CompanyName();

        if Name = CurrentCompanyName then
            exit;

        if not Rec.Get(CurrentCompanyName) then begin
            Rec.Name := CopyStr(CurrentCompanyName, 1, MaxStrLen(Rec.Name));
            Rec.Insert();
        end;
    end;

    procedure GetGLModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate GL Module");
    end;

    procedure GetPayablesModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Payables Module");
    end;

    procedure GetReceivablesModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Receivables Module");
    end;

    procedure GetInventoryModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Inventory Module");
    end;

    procedure IsDataMigrationStarted(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Data Migration Started");
    end;

    procedure SetDataMigrationStarted()
    begin
        GetSingleInstance();
        if not Rec."Data Migration Started" then begin
            Rec."Data Migration Started" := true;
            Rec."Data Migration Started At" := CurrentDateTime();
            Rec.Modify();
        end;
    end;

    procedure GetSkipPostingJournalBatches(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Skip Posting Journal Batches");
    end;
}
