// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Security.AccessControl;

/// <summary>
/// Fetches user details information stored across multiple other tables.
/// </summary>
table 774 "User Details"
{
    Caption = 'User Details';
    TableType = Temporary;
    DataClassification = SystemMetadata; // temporary table
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    // Keeping field IDs aligned with the User table, so that transfer fields would work if at some point a page would switch source table from User to User Details
    fields
    {
        /// <summary>
        /// An ID that uniquely identifies the user.
        /// </summary>
        field(1; "User Security ID"; Guid)
        {
        }
        /// <summary>
        /// User's name.
        /// </summary>
        field(2; "User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// User's full name.
        /// </summary>
        field(3; "Full Name"; Text[80])
        {
            CalcFormula = lookup(User."Full Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// Specifies whether the user can access companies in the current environment.
        /// </summary>
        field(4; State; Option)
        {
            OptionCaption = 'Active,Inactive';
            OptionMembers = Enabled,Disabled;
            CalcFormula = lookup(User.State where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// The authentication email of the user.
        /// </summary>
        field(11; "Authentication Email"; Text[250])
        {
            CalcFormula = lookup(User."Authentication Email" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// The contact email of the user.
        /// </summary>
        field(14; "Contact Email"; Text[250])
        {
            CalcFormula = lookup(User."Contact Email" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// An ID that uniquely identifies the user for the purposes of sending telemetry.
        /// </summary>
        field(21; "Telemetry User ID"; Guid)
        {
            Caption = 'Telemetry ID';
            CalcFormula = lookup("User Property"."Telemetry User ID" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// An ID assigned to the user in Microsoft Entra.
        /// </summary>
        field(22; "Authentication Object ID"; Text[80])
        {
            Caption = 'Entra Object ID';
            CalcFormula = lookup("User Property"."Authentication Object ID" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// True if the user SUPER permission set in any company, false otherwise.
        /// </summary>
        field(23; "Has SUPER permission set"; Boolean)
        {
            CalcFormula = exist("Access Control" where("User Security ID" = field("User Security ID"),
                                                  "Role ID" = const('SUPER'),
                                                  Scope = const(System),
                                                  "App ID" = const('{00000000-0000-0000-0000-000000000000}')));
            Editable = false;
            FieldClass = FlowField;
            Access = Internal;
        }
        /// <summary>
        /// A semicolon-separated list of user's plan names
        /// </summary>
        field(24; "User Plans"; Text[2048])
        {
            Caption = 'User Licenses';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has Delegated Admin or Delegated Helpdesk plans, false otherwise.
        /// </summary>
        field(25; "Is Delegated"; Boolean)
        {
            Access = Internal;
        }
        /// <summary>
        /// True if the user has a Microsoft 365 plan, false otherwise.
        /// </summary>
        field(26; "Has M365 Plan"; Boolean)
        {
            Caption = 'Has Microsoft 365 license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user an Essential, false otherwise.
        /// </summary>
        field(27; "Has Essential Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has a Premium plan, false otherwise.
        /// </summary>
        field(28; "Has Premium Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has any "full" licenses, such as Essential or Premium, false otherwise.
        /// </summary>
        field(29; "Has Essential Or Premium Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "User Name")
        {
        }
    }
}