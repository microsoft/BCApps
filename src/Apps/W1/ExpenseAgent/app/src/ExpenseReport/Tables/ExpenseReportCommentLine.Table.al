// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6901 "Expense Report Comment Line"
{
    Access = Internal;
    Caption = 'Expense Comment Line';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Report Comment Sheet";
    ReplicateData = false;

    fields
    {
        field(1; "Document Type"; Enum "Exp. Report Comment Doc. Type")
        {
            Caption = 'Document Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Date"; Date)
        {
            Caption = 'Date';
        }
        field(5; "Comment"; Text[80])
        {
            Caption = 'Comment';
        }
        field(6; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(PK; "Document Type", "No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure SetUpNewLine()
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
    begin
        ExpenseReportCommentLine.SetRange("Document Type", "Document Type");
        ExpenseReportCommentLine.SetRange("No.", "No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", "Document Line No.");
        ExpenseReportCommentLine.SetRange(Date, WorkDate());
        if ExpenseReportCommentLine.IsEmpty() then
            Date := WorkDate();
    end;

    procedure DeleteComments(ExpenseReportDocType: Enum "Exp. Report Comment Doc. Type"; DocNo: Code[20])
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
    begin
        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportDocType);
        ExpenseReportCommentLine.SetRange("No.", DocNo);
        ExpenseReportCommentLine.DeleteAll();
    end;

    procedure CopyComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseReportCommentLine2: Record "Expense Report Comment Line";
    begin
        ExpenseReportCommentLine.SetRange("Document Type", FromDocumentType);
        ExpenseReportCommentLine.SetRange("No.", FromNumber);
        if ExpenseReportCommentLine.FindSet() then
            repeat
                ExpenseReportCommentLine2 := ExpenseReportCommentLine;
                ExpenseReportCommentLine2."Document Type" := Enum::"Exp. Report Comment Doc. Type".FromInteger(ToDocumentType);
                ExpenseReportCommentLine2."No." := ToNumber;
                ExpenseReportCommentLine2.Insert();
            until ExpenseReportCommentLine.Next() = 0;
    end;
}