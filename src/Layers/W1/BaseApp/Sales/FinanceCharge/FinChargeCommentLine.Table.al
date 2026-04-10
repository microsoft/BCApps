// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Stores comment lines for finance charge memos and issued finance charge memos.
/// </summary>
table 306 "Fin. Charge Comment Line"
{
    Caption = 'Fin. Charge Comment Line';
    DrillDownPageID = "Fin. Charge Comment List";
    LookupPageID = "Fin. Charge Comment List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies whether the comment is for a finance charge memo or an issued finance charge memo.
        /// </summary>
        field(1; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of document the comment is attached to: either Finance Charge Memo or Issued Finance Charge Memo.';
            OptionCaption = 'Finance Charge Memo,Issued Finance Charge Memo';
            OptionMembers = "Finance Charge Memo","Issued Finance Charge Memo";
        }
        /// <summary>
        /// Specifies the document number of the finance charge memo this comment belongs to.
        /// </summary>
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
            TableRelation = if (Type = const("Finance Charge Memo")) "Finance Charge Memo Header"
            else
            if (Type = const("Issued Finance Charge Memo")) "Issued Fin. Charge Memo Header";
        }
        /// <summary>
        /// Specifies the sequential line number of the comment within the document.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the date when the comment was created.
        /// </summary>
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date the comment was created.';
        }
        /// <summary>
        /// Specifies an optional code to categorize or identify the comment.
        /// </summary>
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the comment.';
        }
        /// <summary>
        /// Contains the text of the comment for the finance charge memo.
        /// </summary>
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself.';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Initializes a new comment line with the current work date if no comment exists for today.
    /// </summary>
    procedure SetUpNewLine()
    var
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
    begin
        FinChrgCommentLine.SetRange(Type, Type);
        FinChrgCommentLine.SetRange("No.", "No.");
        FinChrgCommentLine.SetRange(Date, WorkDate());
        if not FinChrgCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, FinChrgCommentLine);
    end;

    /// <summary>
    /// Copies all comment lines from one finance charge document to another.
    /// </summary>
    /// <param name="FromType">Specifies the source document type.</param>
    /// <param name="ToType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    procedure CopyComments(FromType: Integer; ToType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        FinChrgCommentLine2: Record "Fin. Charge Comment Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyComments(FinChrgCommentLine, ToType, IsHandled, FromType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        FinChrgCommentLine.SetRange(Type, FromType);
        FinChrgCommentLine.SetRange("No.", FromNumber);
        if FinChrgCommentLine.FindSet() then
            repeat
                FinChrgCommentLine2 := FinChrgCommentLine;
                FinChrgCommentLine2.Type := ToType;
                FinChrgCommentLine2."No." := ToNumber;
                FinChrgCommentLine2.Insert();
            until FinChrgCommentLine.Next() = 0;
    end;

    /// <summary>
    /// Deletes all comment lines for the specified document type and number.
    /// </summary>
    /// <param name="DocType">Specifies the document type of comments to delete.</param>
    /// <param name="DocNo">Specifies the document number of comments to delete.</param>
    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    /// <summary>
    /// Opens the Finance Charge Comment Sheet page for viewing and editing comments.
    /// </summary>
    /// <param name="DocType">Specifies the document type to filter comments.</param>
    /// <param name="DocNo">Specifies the document number to filter comments.</param>
    /// <param name="DocLineNo">Specifies the line number to filter comments.</param>
    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        FinChargeCommentSheet: Page "Fin. Charge Comment Sheet";
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        SetRange("Line No.", DocLineNo);
        Clear(FinChargeCommentSheet);
        FinChargeCommentSheet.SetTableView(Rec);
        FinChargeCommentSheet.RunModal();
    end;

    /// <summary>
    /// Raised after a new comment line is initialized.
    /// </summary>
    /// <param name="FinChargeCommentLineRec">Specifies the new comment line being initialized.</param>
    /// <param name="FinChargeCommentLineFilter">Specifies the filtered comment line used to check for existing records.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var FinChargeCommentLineRec: Record "Fin. Charge Comment Line"; var FinChargeCommentLineFilter: Record "Fin. Charge Comment Line")
    begin
    end;

    /// <summary>
    /// Raised before comments are copied from one document to another.
    /// </summary>
    /// <param name="FinChargeCommentLine">Specifies the comment line record.</param>
    /// <param name="ToType">Specifies the target document type.</param>
    /// <param name="IsHandled">Set to true to skip the default comment copy process.</param>
    /// <param name="FromType">Specifies the source document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var FinChargeCommentLine: Record "Fin. Charge Comment Line"; ToType: Integer; var IsHandled: Boolean; FromType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

