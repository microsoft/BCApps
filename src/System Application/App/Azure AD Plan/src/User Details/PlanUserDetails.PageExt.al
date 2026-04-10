// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

using System.Security.User;

/// <summary>
/// A page extension that adds details about plans to the User Details page
/// </summary>
pageextension 774 "Plan User Details" extends "User Details"
{
    Editable = false;

    layout
    {
        addbefore("Has SUPER permission set")
        {
            field("User Plans"; Rec."User Plans")
            {
                Visible = IsSaaS;
                ToolTip = 'Specifies the licenses that are assigned to the user.';
                ApplicationArea = Basic, Suite;
            }
            // Below are fields that can be added with "Personalize"
            field("Is Delegated"; Rec."Is Delegated")
            {
                Visible = false;
                ToolTip = 'Specifies if the user is a delegated admin or delegated helpdesk.';
                ApplicationArea = Basic, Suite;
            }
            field("Has Essential Or Premium Plan"; Rec."Has Essential Or Premium Plan")
            {
                Visible = false;
                ToolTip = 'Specifies if the use has an Essential or Premium license.';
                ApplicationArea = Basic, Suite;
            }
            field("Has M365 Plan"; Rec."Has M365 Plan")
            {
                Visible = false;
                ToolTip = 'Specifies if the use has the Microsoft 365 license.';
                ApplicationArea = Basic, Suite;
            }
        }
    }

    views
    {
        addafter(ActiveUsers)
        {
            view(EssentialOrPremiumUsers)
            {
                Caption = 'Users with Essential or Premium license';
                Filters = where("Has Essential Or Premium Plan" = const(true));
                Visible = IsSaaS;
            }
            view(DelegatedUsers)
            {
                Caption = 'Delegated users';
                Filters = where("Is Delegated" = const(true));
                Visible = IsSaaS;
            }
            view(M365Users)
            {
                Caption = 'Users with Microsoft 365 license';
                Filters = where("Has M365 Plan" = const(true));
                Visible = IsSaaS;
            }
        }
    }
}