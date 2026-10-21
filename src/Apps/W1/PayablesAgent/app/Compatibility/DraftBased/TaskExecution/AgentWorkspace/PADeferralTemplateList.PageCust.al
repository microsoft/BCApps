// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.Deferral;

pagecustomization "PA Deferral Template List" customizes "Deferral Template List"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify("Deferral Code")
        {
            Visible = true;
        }
        modify(Description)
        {
            Visible = true;
        }
        modify("No. of Periods")
        {
            Visible = true;
        }
    }
}
