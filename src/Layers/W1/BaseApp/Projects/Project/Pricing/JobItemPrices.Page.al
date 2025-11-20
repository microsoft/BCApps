// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

using Microsoft.Pricing.Calculation;

page 1012 "Job Item Prices"
{
    Caption = 'Project Item Prices';
    PageType = List;
    SourceTable = "Job Item Price";

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
                    ToolTip = 'Specifies the number of the project task if the item price should only apply to a specific project task.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the item that this price applies to. Choose the field to see the available items.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant code if the price that you are setting up should apply to a specific variant of the item.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the default currency code that is defined for a project. Project item prices will only be used if the currency code for the project item is the same as the currency code set for the project.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Unit Cost Factor"; Rec."Unit Cost Factor")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a project-specific line discount percent that applies to this line. This is useful, for example, if you want invoice lines for the project to show a discount percent.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the item you have entered in the Item No. field.';
                }
                field("Apply Job Discount"; Rec."Apply Job Discount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the check box for this field if the project-specific discount percent for this item should apply to the project. The default line discount for the line that is defined is included when project entries are created, but you can modify this value.';
                    Visible = false;
                }
                field("Apply Job Price"; Rec."Apply Job Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the project-specific price or unit cost factor for this item should apply to the project. The default project price that is defined is included when project-related entries are created, but you can modify this value.';
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
