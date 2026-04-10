// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

table 5123 "Inter. Log Entry Comment Line"
{
    Caption = 'Inter. Log Entry Comment Line';
    DataClassification = CustomerContent;
    DrillDownPageID = "Inter. Log Entry Comment List";
    LookupPageID = "Inter. Log Entry Comment List";
    ReplicateData = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
            TableRelation = "Interaction Log Entry"."Entry No.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date on which the comment was created.';
        }
        field(6; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the comment.';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself. You can enter a maximum of 80 characters, both numbers and letters.';
        }
        field(8; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Line No.")
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
        InteractionCommentLine: Record "Inter. Log Entry Comment Line";
    begin
        InteractionCommentLine.SetRange("Entry No.", "Entry No.");
        InteractionCommentLine.SetRange(Date, WorkDate());
        if not InteractionCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, InteractionCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var InterLogEntryCommentLineRec: Record "Inter. Log Entry Comment Line"; var InterLogEntryCommentLineFilter: Record "Inter. Log Entry Comment Line")
    begin
    end;
}

