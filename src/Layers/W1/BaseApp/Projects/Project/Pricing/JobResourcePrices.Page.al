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
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Cost Factor"; Rec."Unit Cost Factor")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Apply Job Discount"; Rec."Apply Job Discount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Apply Job Price"; Rec."Apply Job Price")
                {
                    ApplicationArea = Jobs;
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
