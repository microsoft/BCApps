// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays a read-only list of comments attached to finance charge memos.
/// </summary>
page 455 "Fin. Charge Comment List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Fin. Charge Comment Line";

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
        Text001: Label 'Fin. Charge Memo';
#pragma warning restore AA0074

    /// <summary>
    /// Generates a caption for the finance charge comment list page.
    /// </summary>
    /// <param name="FinChrgCommentLine">The finance charge comment line to generate caption for.</param>
    /// <returns>The page caption text.</returns>
    procedure Caption(FinChrgCommentLine: Record "Fin. Charge Comment Line"): Text
    begin
        if FinChrgCommentLine."No." = '' then
            exit(Text000);
        exit(Text001 + ' ' + FinChrgCommentLine."No." + ' ');
    end;
}

