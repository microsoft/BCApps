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
                    ToolTip = 'Specifies a code for the service cost.';
                }
                field("Cost Type"; Rec."Cost Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service cost.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the general ledger account number to which the service cost will be posted.';
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service zone, to which travel applies if the Cost Type is Travel.';
                }
                field("Default Quantity"; Rec."Default Quantity")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default quantity that is copied to the service lines containing this service cost.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Default Unit Cost"; Rec."Default Unit Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default unit cost that is copied to the service lines containing this service cost.';
                }
                field("Default Unit Price"; Rec."Default Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default unit price of the cost that is copied to the service lines containing this service cost.';
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

