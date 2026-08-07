// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;

pagecustomization "PA Hist. Purchase Lines" customizes "E-Doc. Historical Lines List"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify(Description)
        {
            Visible = true;
        }
        modify("No.")
        {
            Visible = true;
        }
        modify(Type)
        {
            Visible = true;
        }
        modify("Buy-from Vendor No.")
        {
            Visible = true;
        }
        modify("Allocation Account No.")
        {
            Visible = true;
        }
        modify("Deferral Code")
        {
            Visible = true;
        }
    }
}
