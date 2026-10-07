// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

pagecustomization "Business Manager Evaluation RC" customizes "Business Manager Role Center"
{
    layout
    {
        modify(Control9)
        {
            Visible = false;
        }

        modify("User Tasks Activities")
        {
            Visible = false;
        }

        modify(Emails)
        {
            Visible = false;
        }

        modify(ApprovalsActivities)
        {
            Visible = false;
        }

        modify(Control46)
        {
            Visible = false;
        }

        modify("Favorite Accounts")
        {
            Visible = false;
        }
    }

    actions
    {
    }
}
