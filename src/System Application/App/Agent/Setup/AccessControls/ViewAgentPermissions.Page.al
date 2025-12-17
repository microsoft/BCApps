// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

page 4334 "View Agent Permissions"
{
    ApplicationArea = All;
    Caption = 'Agent Permission Sets';
    PageType = ListPart;
    SourceTable = "Access Control";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Agent Permissions';
                field(PermissionSet; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of a security role that has been assigned to this Windows login in the current database.';
                    Style = Unfavorable;
                    StyleExpr = PermissionSetNotFound;
                }
                field(Description; Rec."Role Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the security role that has been given to this Windows login in the current database.';
                }
                field(Company; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the name of the company that this role is limited to for this Windows login.';
                    Visible = ShowCompanyField;
                }
                field(ExtensionName; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(PermissionScope; PermissionScope)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Scope';
                    Editable = false;
                    ToolTip = 'Specifies the scope of the permission set.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditPermissions)
            {
                ApplicationArea = All;
                Caption = 'Edit agent permissions';
                Image = Edit;
                ToolTip = 'Edit the permission sets assigned to this agent.';

                trigger OnAction()
                var
                    Agent: Record Agent;
                    TempAccessControl: Record "Access Control" temporary;
                    TempModifiedAccessControl: Record "Access Control" temporary;
                    SelectAgentPermissions: Page "Select Agent Permissions";
                begin
                    if not Agent.Get(Rec."User Security ID") then
                        exit;

                    if Agent.State <> Agent.State::Disabled then
                        if not Confirm(DeactivateAgentToEditPermissionsQst, false) then
                            exit
                        else begin
                            Agent.State := Agent.State::Disabled;
                            Agent.Modify(true);
                            Commit();
                        end;

                    CopyAccessControlToBuffer(Rec."User Security ID", TempAccessControl);

                    SelectAgentPermissions.SetTempAccessControl(TempAccessControl);
                    if SelectAgentPermissions.RunModal() = Action::OK then begin
                        SelectAgentPermissions.GetTempAccessControl(TempModifiedAccessControl);
                        SaveAccessControl(Rec."User Security ID", TempModifiedAccessControl);
                    end;

                    CurrPage.Update(false);
                end;
            }

            action(AgentShowHideCompany)
            {
                ApplicationArea = All;
                Caption = 'Show/hide company';
                Image = CompanyInformation;
                ToolTip = 'Show or hide the company name.';

                trigger OnAction()
                begin
                    ShowCompanyFieldOverride := true;
                    ShowCompanyField := not ShowCompanyField;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AgentImpl: Codeunit "Agent Impl.";
        GlobalSingleCompanyName: Text[30];
    begin
        PermissionScope := Format(Rec.Scope);

        PermissionSetNotFound := false;
        if not (Rec."Role ID" in ['SUPER', 'SECURITY']) then
            PermissionSetNotFound := not AggregatePermissionSet.Get(Rec.Scope, Rec."App ID", Rec."Role ID");

        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(Rec."User Security ID", GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    local procedure CopyAccessControlToBuffer(UserSecurityID: Guid; var TempAccessControl: Record "Access Control" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        TempAccessControl.Reset();
        TempAccessControl.DeleteAll();

        AccessControl.SetRange("User Security ID", UserSecurityID);
        if not AccessControl.FindSet() then
            exit;

        repeat
            Clear(TempAccessControl);
            TempAccessControl.TransferFields(AccessControl);
            TempAccessControl.Insert();
        until AccessControl.Next() = 0;
    end;

    local procedure SaveAccessControl(UserSecurityID: Guid; var TempModifiedAccessControl: Record "Access Control" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        // Delete all existing access control records for the agent
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.DeleteAll();

        // Insert the modified records
        TempModifiedAccessControl.Reset();
        if not TempModifiedAccessControl.FindSet() then
            exit;

        repeat
            Clear(AccessControl);
            AccessControl.TransferFields(TempModifiedAccessControl);
            AccessControl.Insert();
        until TempModifiedAccessControl.Next() = 0;
    end;

    var
        ShowCompanyField: Boolean;
        ShowCompanyFieldOverride: Boolean;
        PermissionScope: Text;
        PermissionSetNotFound: Boolean;
        DeactivateAgentToEditPermissionsQst: Label 'Permissions can only be edited for inactive agents. Do you want to make the agent inactive now?';
}