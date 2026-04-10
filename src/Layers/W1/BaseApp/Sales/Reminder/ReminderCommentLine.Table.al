// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores user comments attached to reminder and issued reminder documents.
/// </summary>
table 299 "Reminder Comment Line"
{
    Caption = 'Reminder Comment Line';
    DrillDownPageID = "Reminder Comment List";
    LookupPageID = "Reminder Comment List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of document this comment is attached to: reminder or issued reminder.
        /// </summary>
        field(1; Type; Enum "Reminder Comment Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of document the comment is attached to: either Reminder or Issued Reminder.';
        }
        /// <summary>
        /// Specifies the document number of the reminder or issued reminder.
        /// </summary>
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
            TableRelation = if (Type = const(Reminder)) "Reminder Header"
            else
            if (Type = const("Issued Reminder")) "Issued Reminder Header";
        }
        /// <summary>
        /// Specifies the sequential line number for ordering comments within a document.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the date when the comment was created or last modified.
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
        /// Contains the comment text entered by the user.
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
    /// Initializes default values for a new comment line, setting the date to work date if not already set.
    /// </summary>
    procedure SetUpNewLine()
    var
        ReminderCommentLine: Record "Reminder Comment Line";
    begin
        ReminderCommentLine.SetRange(Type, Type);
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.SetRange(Date, WorkDate());
        if not ReminderCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ReminderCommentLine);
    end;

    /// <summary>
    /// Copies all comment lines from one document to another.
    /// </summary>
    /// <param name="FromType">The source document type as integer.</param>
    /// <param name="ToType">The target document type as integer.</param>
    /// <param name="FromNumber">The source document number.</param>
    /// <param name="ToNumber">The target document number.</param>
    procedure CopyComments(FromType: Integer; ToType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        ReminderCommentLine: Record "Reminder Comment Line";
        ReminderCommentLine2: Record "Reminder Comment Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyComments(ReminderCommentLine, ToType, IsHandled, FromType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        ReminderCommentLine.SetRange(Type, FromType);
        ReminderCommentLine.SetRange("No.", FromNumber);
        if ReminderCommentLine.FindSet() then
            repeat
                ReminderCommentLine2 := ReminderCommentLine;
                ReminderCommentLine2.Type := Enum::"Reminder Comment Line Type".FromInteger(ToType);
                ReminderCommentLine2."No." := ToNumber;
                ReminderCommentLine2.Insert();
            until ReminderCommentLine.Next() = 0;
    end;

    /// <summary>
    /// Deletes all comment lines for the specified document.
    /// </summary>
    /// <param name="DocType">The document type to delete comments for.</param>
    /// <param name="DocNo">The document number to delete comments for.</param>
    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    /// <summary>
    /// Opens the Reminder Comment Sheet page for viewing and editing comments.
    /// </summary>
    /// <param name="DocType">Specifies the document type to filter comments.</param>
    /// <param name="DocNo">Specifies the document number to filter comments.</param>
    /// <param name="DocLineNo">Specifies the line number to filter comments.</param>
    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        ReminderCommentSheet: Page "Reminder Comment Sheet";
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        SetRange("Line No.", DocLineNo);
        Clear(ReminderCommentSheet);
        ReminderCommentSheet.SetTableView(Rec);
        ReminderCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ReminderCommentLineRec: Record "Reminder Comment Line"; var ReminderCommentLineFilter: Record "Reminder Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var ReminderCommentLine: Record "Reminder Comment Line"; ToType: Integer; var IsHandled: Boolean; FromType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

