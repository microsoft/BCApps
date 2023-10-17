// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment;

page 774 "User Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Users';
    PageType = List;
    SourceTable = "User Details";
    SourceTableTemporary = true;
    Editable = false;
    AboutTitle = 'About the users detailed view';
    AboutText = 'View the additional information about users, such as assigned licenses and unique identifiers. The information is provided in a list view, which allows for easy searching and filtering.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; Rec."User Name")
                {
                    ToolTip = 'Specifies the user''s name.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(State; Rec.State)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the user can access companies in the current environment.';
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the user''s email address.';
                }
                field("User Plans"; Rec."User Plans")
                {
                    Visible = IsSaaS;
                    ToolTip = 'Specifies the licenses that are assigned to the user.';
                }
                field("User Security ID"; Rec."User Security ID")
                {
                    ToolTip = 'Specifies an ID that uniquely identifies the user.';
                }
                field("Telemetry User ID"; Rec."Telemetry User ID")
                {
                    ToolTip = 'Specifies a telemetry ID which can be used for troubleshooting purposes.';
                }
                field("Authentication Email"; Rec."Authentication Email")
                {
                    ExtendedDatatype = EMail;
                    Visible = IsSaaS;
                    ToolTip = 'Specifies the Microsoft account that this user signs into Microsoft 365 or SharePoint Online with.';
                }
                field("Authentication Object ID"; Rec."Authentication Object ID")
                {
                    Visible = IsSaaS;
                    ToolTip = 'Specifies ID assigned to the user in Microsoft Entra.';
                }
                // Below are fields that can be added with "Personalize"
                field("Has SUPER permission set"; Rec."Has SUPER permission set")
                {
                    Visible = false;
                    ToolTip = 'Specifies if the SUPER permission set is assigned to the user.';
                }
                field("Is Delegated"; Rec."Is Delegated")
                {
                    Visible = false;
                    ToolTip = 'Specifies if the user is a delegated admin or delegated helpdesk.';
                }
                field("Has Essential Or Premium Plan"; Rec."Has Essential Or Premium Plan")
                {
                    Visible = false;
                    ToolTip = 'Specifies if the use has an Essential or Premium license.';
                }
                field("Has M365 Plan"; Rec."Has M365 Plan")
                {
                    Visible = false;
                    ToolTip = 'Specifies if the use has the Microsoft 365 license.';
                }
            }
        }
    }

    views
    {
        view(ActiveUsers)
        {
            Caption = 'Active users';
            Filters = where(State = const(Enabled));
        }
        view(ActiveEssentialOrPremiumUsers)
        {
            Caption = 'Active users with Essential or Premium license';
            Filters = where(State = const(Enabled), "Has Essential Or Premium Plan" = const(true));
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
        view(SuperUsers)
        {
            Caption = 'Users with SUPER permission set';
            Filters = where("Has SUPER permission set" = const(true));
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        UserDetails: Codeunit "User Details";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
        UserDetails.GetUserDetails(Rec);
    end;

    var
        IsSaaS: Boolean;
}