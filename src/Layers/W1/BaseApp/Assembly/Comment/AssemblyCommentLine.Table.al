// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Comment;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;

table 906 "Assembly Comment Line"
{
    Caption = 'Assembly Comment Line';
    DrillDownPageID = "Assembly Comment Sheet";
    LookupPageID = "Assembly Comment Sheet";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Assembly Comment Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            NotBlank = true;
            TableRelation = if ("Document Type" = filter("Posted Assembly")) "Posted Assembly Header"."No."
            else
            "Assembly Header"."No." where("Document Type" = field("Document Type"));
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(11; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Date = 0D then
            Date := WorkDate();
    end;

    procedure SetupNewLine()
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", "Document Type");
        AssemblyCommentLine.SetRange("Document No.", "Document No.");
        AssemblyCommentLine.SetRange("Document Line No.", "Document Line No.");
        AssemblyCommentLine.SetRange("Line No.", "Line No.");
        AssemblyCommentLine.SetRange(Date, WorkDate());
        if not AssemblyCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, AssemblyCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var AssemblyCommentLineRec: Record "Assembly Comment Line"; var AssemblyCommentLineFilter: Record "Assembly Comment Line")
    begin
    end;
}

