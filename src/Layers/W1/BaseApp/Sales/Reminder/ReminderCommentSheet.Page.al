// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Provides an editable interface for adding and managing comments on reminder documents.
/// </summary>
page 442 "Reminder Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Reminder Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'untitled';
        Text001: Label 'Reminder';
#pragma warning restore AA0074

    /// <summary>
    /// Gets the page caption text based on the reminder comment line.
    /// </summary>
    /// <param name="ReminderCommentLine">The reminder comment line to generate caption for.</param>
    /// <returns>The caption text for the page.</returns>
    procedure Caption(ReminderCommentLine: Record "Reminder Comment Line"): Text
    begin
        if ReminderCommentLine."No." = '' then
            exit(Text000);
        exit(Text001 + ' ' + ReminderCommentLine."No." + ' ');
    end;
}

