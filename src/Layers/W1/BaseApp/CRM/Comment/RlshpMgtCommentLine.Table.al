// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Comment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;

table 5061 "Rlshp. Mgt. Comment Line"
{
    Caption = 'Rlshp. Mgt. Comment Line';
    DataClassification = CustomerContent;
    DrillDownPageID = "Rlshp. Mgt. Comment List";
    LookupPageID = "Rlshp. Mgt. Comment List";

    fields
    {
        field(1; "Table Name"; Enum "Rlshp. Mgt. Comment Line Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Table Name" = const(Contact)) Contact
            else
            if ("Table Name" = const(Campaign)) Campaign
            else
            if ("Table Name" = const("To-do")) "To-do"
            else
            if ("Table Name" = const("Web Source")) "Web Source"
            else
            if ("Table Name" = const("Sales Cycle")) "Sales Cycle"
            else
            if ("Table Name" = const("Sales Cycle Stage")) "Sales Cycle Stage"
            else
            if ("Table Name" = const(Opportunity)) Opportunity;
        }
        field(3; "Sub No."; Integer)
        {
            Caption = 'Sub No.';
            TableRelation = if ("Table Name" = const("Sales Cycle Stage")) "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("No."));
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
        field(8; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Sub No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    procedure SetUpNewLine()
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        RlshpMgtCommentLine.SetRange("Table Name", "Table Name");
        RlshpMgtCommentLine.SetRange("No.", "No.");
        RlshpMgtCommentLine.SetRange("Sub No.", "Sub No.");
        RlshpMgtCommentLine.SetRange(Date, WorkDate());
        if not RlshpMgtCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, RlshpMgtCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var RlshpMgtCommentLineRec: Record "Rlshp. Mgt. Comment Line"; var RlshpMgtCommentLineFilter: Record "Rlshp. Mgt. Comment Line")
    begin
    end;
}

