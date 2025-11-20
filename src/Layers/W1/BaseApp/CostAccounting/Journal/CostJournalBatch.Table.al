// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

using Microsoft.CostAccounting.Account;
using Microsoft.Foundation.AuditCodes;

table 1102 "Cost Journal Batch"
{
    Caption = 'Cost Journal Batch';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = false;
            TableRelation = "Cost Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(9; "Bal. Cost Type No."; Code[20])
        {
            Caption = 'Bal. Cost Type No.';
            TableRelation = "Cost Type";

            trigger OnValidate()
            begin
                if CostType.Get("Bal. Cost Type No.") then begin
                    CostType.TestField(Blocked, false);
                    CostType.TestField(Type, CostType.Type::"Cost Type");
                    "Bal. Cost Center Code" := CostType."Cost Center Code";
                    "Bal. Cost Object Code" := CostType."Cost Object Code";
                end;
            end;
        }
        field(10; "Bal. Cost Center Code"; Code[20])
        {
            Caption = 'Bal. Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(11; "Bal. Cost Object Code"; Code[20])
        {
            Caption = 'Bal. Cost Object Code';
            TableRelation = "Cost Object";
        }
        field(12; "Delete after Posting"; Boolean)
        {
            Caption = 'Delete after Posting';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CostJnlLine: Record "Cost Journal Line";
    begin
        CostJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        CostJnlLine.SetRange("Journal Batch Name", Name);
        CostJnlLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        CostJnlTemplate: Record "Cost Journal Template";
    begin
        LockTable();
        TestField(Name);
        CostJnlTemplate.Get("Journal Template Name");
    end;

    var
        CostType: Record "Cost Type";
}

