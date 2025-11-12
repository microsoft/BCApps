// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Pricing.Calculation;

page 7023 "Sales Price Worksheet"
{
    AdditionalSearchTerms = 'special price,alternate price';
    ApplicationArea = Suite;
    Caption = 'Sales Price Worksheet';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Sales Price Worksheet";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the item can be sold at the sales price.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the sales price agreement ends.';
                }
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sale that the price is based on, such as All Customers or Campaign.';
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Sales Type code.';
                }
                field("Sales Description"; Rec."Sales Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the sales type, such as Campaign, on the worksheet line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the sales price.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which sales prices are being changed or set up.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the item on the worksheet line.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum sales quantity that must be met to warrant the sales price.';
                }
                field("Current Unit Price"; Rec."Current Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit price of the item.';
                }
                field("New Unit Price"; Rec."New Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new unit price that is valid for the selected combination of Sales Code, Currency Code and/or Starting Date.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the sales price includes VAT.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the VAT business posting group of customers for whom the sales prices will apply.';
                    Visible = false;
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a line discount will be calculated when the sales price is offered.';
                    Visible = false;
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest &Item Price on Wksh.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest &Item Price on Wksh.';
                    Ellipsis = true;
                    Image = SuggestItemPrice;
                    ToolTip = 'Create suggestions for changing the agreed item unit prices for your sales prices in the Sales Prices window on the basis of the unit price on the item cards. When the batch job has completed, you can see the result in the Sales Price Worksheet window. You can also use the Suggest Sales Price on Wksh. batch job to create suggestions for new sales prices.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Item Price on Wksh.", true, true);
                    end;
                }
                action("Suggest &Sales Price on Wksh.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest &Sales Price on Wksh.';
                    Ellipsis = true;
                    Image = SuggestSalesPrice;
                    ToolTip = 'Create suggestions for changing the agreed item unit prices for your sales prices in the Sales Prices window on the basis of the unit price on the item cards. When the batch job has completed, you can see the result in the Sales Price Worksheet window. You can also use the Suggest Sales Price on Wksh. batch job to create suggestions for new sales prices.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Sales Price on Wksh.", true, true);
                    end;
                }
                action("I&mplement Price Change")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I&mplement Price Change';
                    Ellipsis = true;
                    Image = ImplementPriceChange;
                    Scope = Repeater;
                    ToolTip = 'Update the alternate prices in the Sales Prices window with the ones in the Sales Price Worksheet window.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Implement Price Change", true, true, Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Suggest &Item Price on Wksh._Promoted"; "Suggest &Item Price on Wksh.")
                {
                }
                actionref("Suggest &Sales Price on Wksh._Promoted"; "Suggest &Sales Price on Wksh.")
                {
                }
                actionref("I&mplement Price Change_Promoted"; "I&mplement Price Change")
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
    end;
}
