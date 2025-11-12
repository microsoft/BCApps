// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Comment;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;

table 5208 "Human Resource Comment Line"
{
    Caption = 'Human Resource Comment Line';
    DataCaptionFields = "No.";
    DrillDownPageID = "Human Resource Comment List";
    LookupPageID = "Human Resource Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Human Resources Comment Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Table Name" = const(Employee)) Employee."No."
            else
            if ("Table Name" = const("Alternative Address")) "Alternative Address"."Employee No."
            else
            if ("Table Name" = const("Employee Qualification")) "Employee Qualification"."Employee No."
            else
            if ("Table Name" = const("Misc. Article Information")) "Misc. Article Information"."Employee No."
            else
            if ("Table Name" = const("Confidential Information")) "Confidential Information"."Employee No."
            else
            if ("Table Name" = const("Employee Absence")) "Employee Absence"."Employee No."
            else
            if ("Table Name" = const("Employee Relative")) "Employee Relative"."Employee No.";
        }
        field(3; "Table Line No."; Integer)
        {
            Caption = 'Table Line No.';
        }
        field(4; "Alternative Address Code"; Code[10])
        {
            Caption = 'Alternative Address Code';
            TableRelation = if ("Table Name" = const("Alternative Address")) "Alternative Address".Code where("Employee No." = field("No."));
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; Date; Date)
        {
            Caption = 'Date';
        }
        field(8; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(9; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Table Line No.", "Alternative Address Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        HumanResCommentLine: Record "Human Resource Comment Line";
    begin
        HumanResCommentLine := Rec;
        HumanResCommentLine.SetRecFilter();
        HumanResCommentLine.SetRange("Line No.");
        HumanResCommentLine.SetRange(Date, WorkDate());
        if not HumanResCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, HumanResCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var HumanResourceCommentLineRec: Record "Human Resource Comment Line"; var HumanResourceCommentLineFilter: Record "Human Resource Comment Line")
    begin
    end;
}

