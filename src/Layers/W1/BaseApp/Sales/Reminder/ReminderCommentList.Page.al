// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays a read-only list of comments associated with a reminder or issued reminder document.
/// </summary>
page 443 "Reminder Comment List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Reminder Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'untitled', Comment = 'it is a caption for empty page';
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

