// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

page 5910 "Service Costs"
{
    ApplicationArea = Service;
    Caption = 'Service Costs';
    PageType = List;
    SourceTable = "Service Cost";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                }
                field("Cost Type"; Rec."Cost Type")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                }
                field("Default Quantity"; Rec."Default Quantity")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field("Default Unit Cost"; Rec."Default Unit Cost")
                {
                    ApplicationArea = Service;
                }
                field("Default Unit Price"; Rec."Default Unit Price")
                {
                    ApplicationArea = Service;
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
        area(Navigation)
        {
            action(SalesPriceLists)
            {
                ApplicationArea = Service;
                Caption = 'Sales Prices';
                Image = SalesPrices;
                Visible = ExtendedPriceEnabled;
                ToolTip = 'View or edit prices and discounts for the service cost.';

                trigger OnAction()
                var
                    AmountType: Enum "Price Amount Type";
                    PriceType: Enum "Price Type";
                begin
                    Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SalesPriceLists_Promoted; SalesPriceLists)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;
}

