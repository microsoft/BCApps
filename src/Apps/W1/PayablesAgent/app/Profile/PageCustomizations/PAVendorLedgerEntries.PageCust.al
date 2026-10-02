// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Payables;

pagecustomization "PA Vendor Ledger Entries" customizes "Vendor Ledger Entries"
{
    ClearActions = true;
    ClearLayout = true;
    ClearViews = true;
    DeleteAllowed = false;

    layout
    {
        modify("Posting Date")
        {
            Visible = true;
        }
        modify("Document Type")
        {
            Visible = true;
        }
        modify("Document No.")
        {
            Visible = true;
        }
        modify("External Document No.")
        {
            Visible = true;
        }
        modify(Description)
        {
            Visible = true;
        }
        modify("Currency Code")
        {
            Visible = true;
        }
        modify(Amount)
        {
            Visible = true;
        }
        modify("Remaining Amount")
        {
            Visible = true;
        }
        modify("Due Date")
        {
            Visible = true;
        }
    }
}
