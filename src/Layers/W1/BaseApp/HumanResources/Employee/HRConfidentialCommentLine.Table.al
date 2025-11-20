// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Setup;

table 5219 "HR Confidential Comment Line"
{
    Caption = 'HR Confidential Comment Line';
    DataCaptionFields = "No.";
    DrillDownPageID = "HR Confidential Comment List";
    LookupPageID = "HR Confidential Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Confidential Information';
            OptionMembers = "Confidential Information";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = Employee;
        }
        field(3; "Code"; Code[10])
        {
            Caption = 'Code';
            TableRelation = Confidential.Code;
        }
        field(4; "Table Line No."; Integer)
        {
            Caption = 'Table Line No.';
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; Date; Date)
        {
            Caption = 'Date';
        }
        field(9; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Code", "Table Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        HRConfCommentLine: Record "HR Confidential Comment Line";
    begin
        HRConfCommentLine := Rec;
        HRConfCommentLine.SetRecFilter();
        HRConfCommentLine.SetRange("Line No.");
        HRConfCommentLine.SetRange(Date, WorkDate());
        if not HRConfCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, HRConfCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var HRConfidentialCommentLineRec: Record "HR Confidential Comment Line"; var HRConfidentialCommentLineFilter: Record "HR Confidential Comment Line")
    begin
    end;
}

