// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 28 "Vend. Invoice Discounts"
{
    Caption = 'Vend. Invoice Discounts';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Vendor Invoice Disc.";

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
                    ToolTip = 'Specifies the contents of the Invoice Disc. Code field on the vendor card.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for invoice discount terms.';
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the minimum amount that the order must total for the discount to be granted or the service charge levied. For discounts, only purchase lines where the Allow Invoice Disc. field is selected are included in the calculation.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount percentage that the vendor will grant if your company buys at least the amount in the Minimum Amount field.';
                }
                field("Service Charge"; Rec."Service Charge")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount of the service charge that the vendor will charge if your company purchases for at least the amount in the Minimum Amount field.';
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

