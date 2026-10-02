// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;

pagecustomization "PA Purchase Credit Memo" customizes "Purchase Credit Memo"
{
    ClearActions = true;
    ClearLayout = true;

    layout
    {
        modify("Vendor Cr. Memo No.")
        {
            Visible = true;
            Editable = false;
        }
        modify(Status)
        {
            Visible = true;
            Editable = false;
        }
        modify("Applies-to Doc. Type")
        {
            Visible = true;
            Editable = false;
        }
        modify("Applies-to Doc. No.")
        {
            Visible = true;
            Editable = false;
        }
    }
}
