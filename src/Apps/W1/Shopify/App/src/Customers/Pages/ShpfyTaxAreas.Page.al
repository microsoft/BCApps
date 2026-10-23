// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Tax Areas (ID 30109).
/// </summary>
page 30109 "Shpfy Tax Areas"
{
    Caption = 'Shopify Tax Areas';
    PageType = ListPart;
    SourceTable = "Shpfy Tax Area";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("County Code"; Rec."County Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of sub-regions for a county, such as provinces or states.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sub-regions for a county, such as provinces or states.';
                }
                field(TaxAreaCode; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax area applicable to the state.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Tax Liable field.';
                }
                field(VATBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the VAT business posting group to use when the country/region and county in the default customer address exactly match this tax area. If no default address exists, the first address determines the match. For a new customer, a nonblank value overrides the VAT business posting group from the Customer/Company Template Code setup. When synchronization can update an existing mapped customer, a nonblank value replaces the current value. Leave this field blank to keep the value from the template or existing customer.';
                }
            }
        }
    }
}