// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Comment;

page 67 "Sales Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionFields = "Document Type", "No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Sales Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Comments;
                    Visible = false;
                }
                field("Print On Quote"; Rec."Print On Quote")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line to print on the sales quote document.';
                    Visible = false;
                }
                field("Print On Pick Ticket"; Rec."Print On Pick Ticket")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on the pick ticket document.';
                    Visible = false;
                }
                field("Print On Order Confirmation"; Rec."Print On Order Confirmation")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on the sales order document.';
                    Visible = false;
                }
                field("Print On Shipment"; Rec."Print On Shipment")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales shipment document.';
                    Visible = false;
                }
                field("Print On Invoice"; Rec."Print On Invoice")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales invoice document.';
                    Visible = false;
                }
                field("Print On Credit Memo"; Rec."Print On Credit Memo")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales credit memo document.';
                    Visible = false;
                }
                field("Print On Return Authorization"; Rec."Print On Return Authorization")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on return authorizations.';
                    Visible = false;
                }
                field("Print On Return Receipt"; Rec."Print On Return Receipt")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on return receipts.';
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
}

