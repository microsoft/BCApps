// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Adds the "On Hold" column to the Shopify Orders list page.
/// This allows filtering for orders awaiting tax matching by the agent.
/// </summary>
pageextension 30472 "Shpfy Tax Orders" extends "Shpfy Orders"
{
    layout
    {
        addafter(Closed)
        {
            field("On Hold"; Rec."On Hold")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies if the order is on hold pending tax matching by the Shopify Tax Agent.';
            }
        }
    }
}
