// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Bank.Reconciliation;

pagecustomization "PA Text-to-Account Mapping" customizes "Text-to-Account Mapping"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify("Mapping Text")
        {
            Visible = true;
        }
        modify("Debit Acc. No.")
        {
            Visible = true;
        }
    }
}
