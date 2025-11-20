// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Projects.Project.Job;

table 1018 "Job WIP Buffer"
{
    Caption = 'Project WIP Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Enum "Job WIP Buffer Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; "WIP Entry Amount"; Decimal)
        {
            Caption = 'WIP Entry Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(5; "Bal. G/L Account No."; Code[20])
        {
            Caption = 'Bal. G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(6; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            Editable = false;
            NotBlank = true;
            TableRelation = Job;
        }
        field(8; "Job Complete"; Boolean)
        {
            Caption = 'Project Complete';
            DataClassification = SystemMetadata;
        }
        field(9; "Job WIP Total Entry No."; Integer)
        {
            Caption = 'Project WIP Total Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Job WIP Total";
        }
        field(22; Reverse; Boolean)
        {
            Caption = 'Reverse';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(23; "WIP Posting Method Used"; Option)
        {
            Caption = 'WIP Posting Method Used';
            DataClassification = SystemMetadata;
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(71; "Dim Combination ID"; Integer)
        {
            Caption = 'Dim Combination ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job WIP Total Entry No.", Type, "Posting Group", "Dim Combination ID", Reverse, "G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

