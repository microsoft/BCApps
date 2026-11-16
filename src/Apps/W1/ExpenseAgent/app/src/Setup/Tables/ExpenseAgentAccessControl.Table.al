// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.Security.AccessControl;

/// <summary>
/// Table that manages access control permissions for the Expense Agent.
/// </summary>
/// <remarks>
/// This table defines which users have permission to access and configure the Expense Agent.
/// Essential for implementing role-based security for agent management, ensuring that only authorized
/// users can interact with and modify agent configurations.
/// </remarks>
table 6943 "Expense Agent Access Control"
{
    Caption = 'Expense Agent Access Control';
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        /// <summary>
        /// System ID linking to the Expense Agent Setup record.
        /// </summary>
        field(1; "Setup System ID"; Guid)
        {
            Caption = 'Setup System ID';
            TableRelation = "Expense Agent Setup".SystemId;
            ToolTip = 'Specifies the Expense Agent Setup record this access control belongs to.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The security ID of the user who is granted access to the agent.
        /// </summary>
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            TableRelation = "User"."User Security ID";
            ToolTip = 'Specifies the User Security ID of the user associated with this agent.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The authentication email address of the user.
        /// </summary>
        field(3; "Authentication Email"; Text[250])
        {
            Caption = 'Authentication Email';
            ToolTip = 'Specifies the authentication email address of the user.';
            FieldClass = FlowField;
            CalcFormula = lookup(User."Authentication Email" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
        /// <summary>
        /// Indicates whether the user has permission to configure and modify the agent settings.
        /// </summary>
        field(4; "Can Configure Agent"; Boolean)
        {
            Caption = 'Can Configure Agent';
            ToolTip = 'Specifies whether the user can configure this agent.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not Rec."Can Configure Agent" then
                    VerifyOwnerExists();
            end;
        }
        /// <summary>
        /// Indicates whether the user can work on behalf of other expense users.
        /// </summary>
        field(5; "Can Work on Behalf"; Boolean)
        {
            Caption = 'Can Work on Behalf';
            ToolTip = 'Specifies whether the user can work on behalf of other expense users.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ExpenseAgentAccessControl: Record "Expense Agent Access Control";
                AgentSystemPermissions: Codeunit "Agent System Permissions";
            begin
                if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
                    Error(NotAuthorizedToViewSetupErr);
                ExpenseAgentAccessControl.SetRange("Can Work on Behalf", true);
                if not "Can Work on Behalf" then begin
                    if ExpenseAgentAccessControl.IsEmpty() then
                        Error(AtLastOneMustHaveAccessErr);
                end else begin
                    ExpenseAgentAccessControl.SetFilter("User Security ID", '<>%1', Rec."User Security ID");
                    if ExpenseAgentAccessControl.FindFirst() then begin
                        ExpenseAgentAccessControl."Can Work on Behalf" := false;
                        ExpenseAgentAccessControl.Modify();
                    end;
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Setup System ID", "User Security ID")
        {
            Clustered = true;
        }
    }

    var
        NotAuthorizedToViewSetupErr: Label 'You do not have permission to view the Expense Agent setup. Contact your administrator to be granted agent management rights.';
        AtLastOneMustHaveAccessErr: Label 'At least one user must be able to work on behalf of others.';
        OneOwnerMustBeDefinedErr: Label 'At least one user must be able to configure the Expense Agent.';

    trigger OnDelete()
    begin
        if Rec."Can Configure Agent" then
            VerifyOwnerExists();
    end;

    local procedure VerifyOwnerExists()
    var
        TempExpenseAgentAccessControl: Record "Expense Agent Access Control" temporary;
        CurrentUserSecurityID: Guid;
        OwnerFound: Boolean;
    begin
        CurrentUserSecurityID := Rec."User Security ID";

        TempExpenseAgentAccessControl.Copy(Rec);

        // Check if there's at least one other record with "Can Configure Agent" = true
        Rec.SetRange("Can Configure Agent", true);

        OwnerFound := false;
        if Rec.FindSet() then
            repeat
                if Rec."User Security ID" <> CurrentUserSecurityID then
                    OwnerFound := true;
            until (Rec.Next() = 0) or OwnerFound;

        Rec.Copy(TempExpenseAgentAccessControl);
        if not OwnerFound then
            Error(OneOwnerMustBeDefinedErr);
    end;

    procedure GetByUserSecurityID(UserID: Guid): Boolean
    begin
        Rec.SetRange("User Security ID", UserID);
        exit(Rec.FindFirst());
    end;
}
