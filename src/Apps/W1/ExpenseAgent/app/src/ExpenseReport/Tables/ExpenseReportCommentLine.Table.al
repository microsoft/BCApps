// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Stores comment lines for expense reports and posted expense reports.
/// </summary>
table 6901 "Expense Report Comment Line"
{
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

    /// <summary>
    /// Initializes a new comment line by setting the date to the work date if no other comment line for the same document line exists on that date.
    /// </summary>
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

    /// <summary>
    /// Deletes all comment lines for the specified document.
    /// </summary>
    /// <param name="ExpenseReportDocType">The type of the document whose comments are deleted.</param>
    /// <param name="DocNo">The number of the document whose comments are deleted.</param>
    procedure DeleteComments(ExpenseReportDocType: Enum "Exp. Report Comment Doc. Type"; DocNo: Code[20])
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
    begin
        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportDocType);
        ExpenseReportCommentLine.SetRange("No.", DocNo);
        ExpenseReportCommentLine.DeleteAll();
    end;

    /// <summary>
    /// Copies all comment lines from one document to another document.
    /// </summary>
    /// <param name="FromDocumentType">The document type to copy the comment lines from.</param>
    /// <param name="ToDocumentType">The document type to copy the comment lines to.</param>
    /// <param name="FromNumber">The number of the document to copy the comment lines from.</param>
    /// <param name="ToNumber">The number of the document to copy the comment lines to.</param>
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