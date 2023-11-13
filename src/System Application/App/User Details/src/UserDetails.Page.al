// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment;

/// <summary>
/// Shows detailed user information, such as unique identifiers, information about permission sets etc.
/// </summary>
page 774 "User Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Users';
    PageType = List;
    SourceTable = "User Details";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    AboutTitle = 'About the users detailed view';
    AboutText = 'View the additional information about users in a list view, which allows for easy searching and filtering.';

    layout
    {
        area(content)
        {
            repeater(UserDetailsRepeater)
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
                // Can be added with "Personalize"
                field("Has SUPER permission set"; Rec."Has SUPER permission set")
                {
                    Visible = false;
                    ToolTip = 'Specifies if the SUPER permission set is assigned to the user.';
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

    protected var
        IsSaaS: Boolean;
}