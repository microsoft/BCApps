// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

pagecustomization "PA EDoc Purchase Draft Subform" customizes "E-Doc. Purchase Draft Subform"
{
    ClearActions = true;
    ClearLayout = true;

    layout
    {
        modify(Description)
        {
            Visible = true;
        }
        modify(Quantity)
        {
            Visible = true;
        }
        modify(OrderMatched)
        {
            Visible = true;
        }
        modify("Line Type")
        {
            Visible = true;
        }
        modify("No.")
        {
            Visible = true;
        }
        modify("Item Reference No.")
        {
            Visible = true;
        }
        modify("Deferral Code")
        {
            Visible = true;
        }
        modify("Unit Of Measure")
        {
            Visible = true;
        }
    }
    actions
    {
        modify(MatchToOrderLine)
        {
            Visible = true;
        }
        modify(LookupItemReferences)
        {
            Visible = true;
        }
        modify(OpenTextToAccountMappings)
        {
            Visible = true;
        }
        modify(OpenHistoricalPurchaseLines)
        {
            Visible = true;
        }
        modify(OpenChartOfAccounts)
        {
            Visible = true;
        }
        modify(OpenItems)
        {
            Visible = true;
        }
        modify(OpenDeferralTemplates)
        {
            Visible = true;
        }
    }
}