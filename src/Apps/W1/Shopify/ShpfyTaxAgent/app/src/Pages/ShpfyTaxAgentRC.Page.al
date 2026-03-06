// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// Role Center for the Shopify Tax Matching Agent.
/// Provides navigation actions for all pages the agent needs to access.
/// </summary>
page 30473 "Shpfy Tax Agent RC"
{
    PageType = RoleCenter;
    Caption = 'Shopify Tax Agent', Locked = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    actions
    {
        area(Processing)
        {
            action(ShopifyOrders)
            {
                ApplicationArea = All;
                Caption = 'Shopify Orders';
                ToolTip = 'Open the list of Shopify orders.';
                RunObject = page "Shpfy Orders";
            }
            action(TaxJurisdictions)
            {
                ApplicationArea = All;
                Caption = 'Tax Jurisdictions';
                ToolTip = 'Open the Tax Jurisdictions list.';
                RunObject = page "Tax Jurisdictions";
            }
            action(TaxAreaList)
            {
                ApplicationArea = All;
                Caption = 'Tax Area List';
                ToolTip = 'Open the Tax Area list.';
                RunObject = page "Tax Area List";
            }
            action(ShopifyShops)
            {
                ApplicationArea = All;
                Caption = 'Shopify Shops';
                ToolTip = 'Open the Shopify Shops list.';
                RunObject = page "Shpfy Shops";
            }
        }
    }
}
