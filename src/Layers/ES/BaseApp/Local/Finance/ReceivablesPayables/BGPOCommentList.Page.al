// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 7000024 "BG/PO Comment List"
{
    Caption = 'BG/PO Comment List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "BG/PO Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("BG/PO No."; Rec."BG/PO No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bill group/payment order in which the comment line is included.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the comment was entered.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment text to include in the comment line for the bill group/payment order.';
                }
            }
        }
    }

    actions
    {
    }
}

