// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Provides an editable worksheet for entering and managing comments on finance charge memos.
/// </summary>
page 454 "Fin. Charge Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Fin. Charge Comment Line";

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
        Text001: Label 'Fin. Charge Memo';
#pragma warning restore AA0074

    /// <summary>
    /// Generates a caption for the finance charge comment sheet page.
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

