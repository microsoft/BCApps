// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.GeneralLedger.Account;

pagecustomization "PA Chart of Accounts" customizes "Chart of Accounts"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify("No.")
        {
            Visible = true;
        }
        modify(Name)
        {
            Visible = true;
        }
        modify("Account Type")
        {
            Visible = true;
        }
        modify("Direct Posting")
        {
            Visible = true;
        }
    }
}
