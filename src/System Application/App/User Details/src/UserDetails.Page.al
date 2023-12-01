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
    AboutText = 'View the additional information about users in a list view, which allows for easy searching and filtering.';
    AboutTitle = 'About the users detailed view';
    ApplicationArea = Basic, Suite;
    Caption = 'Users';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Details";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
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
                    ToolTip = 'Specifies the Microsoft account that this user signs into Microsoft 365 or SharePoint Online with.';
                    Visible = IsSaaS;
                }
                field("Authentication Object ID"; Rec."Authentication Object ID")
                {
                    ToolTip = 'Specifies ID assigned to the user in Microsoft Entra.';
                    Visible = IsSaaS;
                }
                // Can be added with "Personalize"
                field("Has SUPER permission set"; Rec."Has SUPER permission set")
                {
                    ToolTip = 'Specifies if the SUPER permission set is assigned to the user.';
                    Visible = false;
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
        UserDetails.Get(Rec);
    end;

    protected var
        IsSaaS: Boolean;
}