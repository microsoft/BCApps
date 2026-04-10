// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Comment;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;

table 842 "Cash Flow Account Comment"
{
    Caption = 'Cash Flow Account Comment';
    DrillDownPageID = "Cash Flow Comment List";
    LookupPageID = "Cash Flow Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Cash Flow Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Table Name" = const("Cash Flow Forecast")) "Cash Flow Forecast"
            else
            if ("Table Name" = const("Cash Flow Account")) "Cash Flow Account";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        CFAccountComment: Record "Cash Flow Account Comment";
    begin
        CFAccountComment.SetRange("Table Name", "Table Name");
        CFAccountComment.SetRange("No.", "No.");
        if not CFAccountComment.FindFirst() then
            Date := WorkDate();
    end;
}

