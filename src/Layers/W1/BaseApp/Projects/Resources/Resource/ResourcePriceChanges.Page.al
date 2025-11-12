// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Pricing.Calculation;

page 493 "Resource Price Changes"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Price Changes';
    PageType = List;
    SourceTable = "Resource Price Change";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of resource for which the alternate unit price is valid.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the resource code for which the alternate unit price is valid.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the currency code that the alternate unit price is in.';
                }
                field("Current Unit Price"; Rec."Current Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the alternate unit price of the resource.';
                }
                field("New Unit Price"; Rec."New Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the new unit price that is valid for the selected combination of resource type, resource code, project number, or work type.';
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
                action("Suggest &Res. Price Chg. (Res.)")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Suggest &Res. Price Chg. (Res.)';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'Determine if the unit price for a resource differs from the unit price on its resource card. If the two prices are different, you can use the suggestion to change the alternative unit price for the resource in the Resource Prices window to the price on the resource card. When the batch job has been completed, you can see the result in the Resource Price Changes window.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Res. Price Chg. (Res.)", true, true);
                    end;
                }
                action("Suggest Res. &Price Chg.(Price)")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Suggest Res. &Price Chg.(Price)';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'Determine if the unit price for a resource differs from the unit price on its resource card. If the two prices are different, you can use the suggestion to change the alternative unit price for the resource in the Resource Prices window to the price on the resource card. When the batch job has been completed, you can see the result in the Resource Price Changes window.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Res. Price Chg.(Price)", true, true);
                    end;
                }
                action("I&mplement Res. Price Change")
                {
                    ApplicationArea = Jobs;
                    Caption = 'I&mplement Res. Price Change';
                    Ellipsis = true;
                    Image = Approve;
                    ToolTip = 'Update the alternate prices in the Resource Prices window with the ones in the Resource Price Changes window. Price change suggestions can be created with the Suggest Res. Price Chg.(Price) or the Suggest Res. Price Chg. (Res.) batch job. You can also modify the price change suggestions in the Resource Price Changes window before you implement them.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Implement Res. Price Change", true, true, Rec);
                    end;
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
