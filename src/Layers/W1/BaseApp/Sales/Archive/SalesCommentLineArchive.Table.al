// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Sales.Comment;

table 5126 "Sales Comment Line Archive"
{
    Caption = 'Sales Comment Line Archive';
    DrillDownPageID = "Sales Archive Comment Sheet";
    LookupPageID = "Sales Archive Comment Sheet";
    DataClassification = CustomerContent;

    fields
    {
#pragma warning disable AS0070
        field(1; "Document Type"; Enum "Sales Comment Document Type")
        {
            Caption = 'Document Type';
        }
#pragma warning restore AS0070
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the version number of the archived document.';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the document line number of the quote or order to which the comment applies.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the line number for the comment.';
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(8; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(9; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        SalesCommentLine: Record "Sales Comment Line Archive";
    begin
        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesCommentLine.SetRange("Version No.", "Version No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        SalesCommentLine.SetRange(Date, WorkDate());
        OnSetUpNewLineOnAfterSetFilters(SalesCommentLine, Rec);
        if not SalesCommentLine.FindFirst() then
            Date := WorkDate();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnAfterSetFilters(var SalesCommentLine: Record "Sales Comment Line Archive"; Rec: Record "Sales Comment Line Archive")
    begin
    end;
}

