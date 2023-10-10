// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment;

page 774 "User Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Details';
    PageType = List;
    SourceTable = "User Details";
    SourceTableTemporary = true;
    Editable = false;

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