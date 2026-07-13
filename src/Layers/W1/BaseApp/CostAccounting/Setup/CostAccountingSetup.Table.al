// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Setup;

using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Dimension;

table 1108 "Cost Accounting Setup"
{
    Caption = 'Cost Accounting Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Cost Accounting Setup";
    LookupPageID = "Cost Accounting Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Starting Date for G/L Transfer"; Date)
        {
            Caption = 'Starting Date for G/L Transfer';

            trigger OnValidate()
            begin
                CostRegister.SetRange(Source, CostRegister.Source::"Transfer from G/L");
                if CostRegister.FindFirst() then
                    Error(StartingDateCannotBeDefinedErr, CostRegister."No.");
            end;
        }
        field(3; "Align G/L Account"; Option)
        {
            Caption = 'Align G/L Account';
            OptionCaption = 'No Alignment,Automatic,Prompt';
            OptionMembers = "No Alignment",Automatic,Prompt;
        }
        field(4; "Align Cost Center Dimension"; Option)
        {
            Caption = 'Align Cost Center Dimension';
            OptionCaption = 'No Alignment,Automatic,Prompt';
            OptionMembers = "No Alignment",Automatic,Prompt;
        }
        field(5; "Align Cost Object Dimension"; Option)
        {
            Caption = 'Align Cost Object Dimension';
            OptionCaption = 'No Alignment,Automatic,Prompt';
            OptionMembers = "No Alignment",Automatic,Prompt;
        }
        field(20; "Last Allocation ID"; Code[10])
        {
            Caption = 'Last Allocation ID';
            InitValue = '001';
        }
        field(30; "Last Allocation Doc. No."; Code[20])
        {
            Caption = 'Last Allocation Doc. No.';
            InitValue = 'AL0001';
        }
        field(100; "Auto Transfer from G/L"; Boolean)
        {
            Caption = 'Auto Transfer from G/L';

            trigger OnValidate()
            var
                TransferGlEntriesToCA: Codeunit "Transfer GL Entries to CA";
            begin
                if "Auto Transfer from G/L" then begin
                    Modify();
                    TransferGlEntriesToCA.GetGLEntries();
                end;
            end;
        }
        field(120; "Check G/L Postings"; Boolean)
        {
            Caption = 'Check G/L Postings';
        }
        field(205; "Cost Center Dimension"; Code[20])
        {
            Caption = 'Cost Center Dimension';
            TableRelation = Dimension;
        }
        field(206; "Cost Object Dimension"; Code[20])
        {
            Caption = 'Cost Object Dimension';
            TableRelation = Dimension;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CostRegister: Record "Cost Register";
#pragma warning disable AA0470
        StartingDateCannotBeDefinedErr: Label 'The starting date can no longer be defined. According to Register No. %1, general ledger entries have already been transferred to Cost Accounting.';
#pragma warning restore AA0470
}

