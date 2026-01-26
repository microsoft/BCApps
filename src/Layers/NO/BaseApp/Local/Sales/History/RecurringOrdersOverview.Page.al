// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Document;

page 15000303 "Recurring Orders Overview"
{
    Caption = 'Recurring Orders Overview';
    PageType = List;
    SourceTable = "Sales Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer that products on the order are sold to.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that products on the order are sold to.';
                }
                field("Recurring Group Code"; Rec."Recurring Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the recurring group code associated with the sales header.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Recurring")
            {
                Caption = '&Recurring';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Blanket Sales Order";
                    RunPageOnRec = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
            }
        }
    }
}

