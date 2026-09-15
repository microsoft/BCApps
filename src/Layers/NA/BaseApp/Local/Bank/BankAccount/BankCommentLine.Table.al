// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Deposit;
using Microsoft.Bank.Reconciliation;

table 10122 "Bank Comment Line"
{
    Caption = 'Bank Comment Line';
    DrillDownPageID = "Bank Comment List";
    LookupPageID = "Bank Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Bank Rec.,Posted Bank Rec.,Deposit,Posted Deposit';
            OptionMembers = "Bank Rec.","Posted Bank Rec.",Deposit,"Posted Deposit";
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation =
            if ("Table Name" = const("Posted Bank Rec.")) "Posted Bank Rec. Header"."Statement No." where("Bank Account No." = field("Bank Account No."))
            else
            if ("Table Name" = const("Posted Deposit")) "Posted Deposit Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Bank Account No.", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        CommentLine: Record "Bank Comment Line";
    begin
        CommentLine.SetRange("Table Name", "Table Name");
        CommentLine.SetRange("Bank Account No.", "Bank Account No.");
        CommentLine.SetRange("No.", "No.");
        if not CommentLine.FindFirst() then
            Date := WorkDate();
    end;
}

