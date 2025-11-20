// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

table 953 "Time Sheet Comment Line"
{
    Caption = 'Time Sheet Comment Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
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
        key(Key1; "No.", "Time Sheet Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
    begin
        TimeSheetCommentLine.SetRange("No.", "No.");
        TimeSheetCommentLine.SetRange("Time Sheet Line No.", "Time Sheet Line No.");
        TimeSheetCommentLine.SetRange(Date, WorkDate());
        if TimeSheetCommentLine.IsEmpty() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, TimeSheetCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var TimeSheetCommentLineRec: Record "Time Sheet Comment Line"; var TimeSheetCommentLineFilter: Record "Time Sheet Comment Line")
    begin
    end;
}

