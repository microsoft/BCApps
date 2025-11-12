// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

using Microsoft.Pricing.Calculation;
page 1011 "Job Resource Prices"
{
    Caption = 'Project Resource Prices';
    PageType = List;
    SourceTable = "Job Resource Price";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the project task if the resource price should only apply to a specific project task.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the price that you are setting up for the project should apply to a resource, to a resource group, or to all resources and resource groups.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the resource or resource group that this price applies to. The No. must correspond to your selection in the Type field.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the currency of the sales price if the price that you have set up in this line is in a foreign currency. Choose the field to see the available currency codes.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Unit Cost Factor"; Rec."Unit Cost Factor")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the unit cost factor. If you have agreed with you customer that he should pay for certain resource usage by cost value plus a certain percent value to cover your overhead expenses, you can set up a unit cost factor in this field.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a line discount percent that applies to this resource, or resource group. This is useful, for example if you want invoice lines for the project to show a discount percent.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the resource, or resource group, you have entered in the Code field.';
                }
                field("Apply Job Discount"; Rec."Apply Job Discount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether to apply a discount to the project. Select this field if the discount percent for this resource or resource group should apply to the project, even if the discount percent is zero.';
                    Visible = false;
                }
                field("Apply Job Price"; Rec."Apply Job Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the price for this resource, or resource group, should apply to the project, even if the price is zero.';
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
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
    end;
}
