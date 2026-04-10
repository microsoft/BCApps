// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Pricing.Calculation;

/// <summary>
/// Provides a workspace for preparing and reviewing sales price changes before applying them.
/// </summary>
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
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Description"; Rec."Sales Description")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Current Unit Price"; Rec."Current Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("New Unit Price"; Rec."New Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
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
