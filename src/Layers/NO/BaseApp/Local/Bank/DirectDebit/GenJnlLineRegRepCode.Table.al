// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;

table 10608 "Gen. Jnl. Line Reg. Rep. Code"
{
    Caption = 'Gen. Jnl. Line Reg. Rep. Code';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Reg. Code"; Code[10])
        {
            Caption = 'Reg. Code';
            TableRelation = "Regulatory Reporting Code";
        }
        field(5; "Reg. Code Description"; Text[35])
        {
            CalcFormula = lookup("Regulatory Reporting Code".Description where(Code = field("Reg. Code")));
            Caption = 'Reg. Code Description';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.", "Reg. Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure SetFilterForGenJournalLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SetRange("Line No.", GenJournalLine."Line No.");
    end;
}

