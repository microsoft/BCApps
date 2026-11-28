// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Customer Templates (ID 30108).
/// </summary>
page 30108 "Shpfy Customer Templates"
{
    Caption = 'Shopify Customer Setup by Country/Region';
    PageType = List;
    SourceTable = "Shpfy Customer Template";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(CountryCode; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Country Code.';
                }
                field(CustomerTemplCode; Rec."Customer Templ. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Template Code';
                    ToolTip = 'Specifies the customer template used for Shopify customers from this country or region. This template is also used for Shopify companies from this country or region when no company template is configured.';
                }
                field(CompanyTemplCode; Rec."Company Templ. Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer template used for Shopify companies from this country or region. Leave blank to use the company template from the Shopify Shop Card or, if that field is also blank, the customer template settings.';
                }
                field(FixCustomerNo; Rec."Default Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default customer for this country when not creating a customer for each webshop user.';
                }
            }

            part(TaxArea; "Shpfy Tax Areas")
            {
                ApplicationArea = All;
                Caption = 'Tax Areas';
                SubPageLink = "Country/Region Code" = field("Country/Region Code");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Import)
            {
                ApplicationArea = All;
                Caption = 'Import countries and counties';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Import the countries from Shopify where products are sold together with the taxes defined for the relevant company.';

                trigger OnAction()
                var
                    Shop: Record "Shpfy Shop";
                    Sync: Codeunit "Shpfy Background Syncs";
                begin
                    Shop.Get(Rec.GetFilter("Shop Code"));
                    Shop.SetRecFilter();
                    Sync.CountrySync(Shop);
                end;
            }
        }
    }
}