// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

page 23 "Cust. Invoice Discounts"
{
    Caption = 'Cust. Invoice Discounts';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Cust. Invoice Disc.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contents of the Invoice Disc. Code field on the customer card.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for invoice discount terms.';
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum amount that the invoice must total for the discount to be granted or the service charge levied. For discounts, only sales lines where the Allow Invoice Disc. field is selected are included in the calculation.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that the customer can receive by buying for at least the minimum amount.';
                }
                field("Service Charge"; Rec."Service Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the service charge that the customer will have to pay on a purchase of at least the amount in the Minimum Amount field.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

