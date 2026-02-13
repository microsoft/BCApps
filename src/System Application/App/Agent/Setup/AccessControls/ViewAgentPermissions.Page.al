// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4334 "View Agent Permissions"
{
    ApplicationArea = All;
    Caption = 'Agent Permission Sets';
    PageType = ListPart;
    SourceTable = "Access Control";
    Editable = false;
    Extensible = false;
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
                    TempAccessControlBuffer: Record "Access Control Buffer" temporary;
                    AgentImpl: Codeunit "Agent Impl.";
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

                    CopyAccessControlToBuffer(Rec."User Security ID", TempAccessControlBuffer);

                    SelectAgentPermissions.Initialize(Rec."User Security ID", TempAccessControlBuffer);
                    if SelectAgentPermissions.RunModal() = Action::OK then begin
                        SelectAgentPermissions.GetTempAccessControlBuffer(TempAccessControlBuffer);
                        AgentImpl.AssignPermissionSets(Rec."User Security ID", TempAccessControlBuffer);
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
            ShowCompanyField := not AgentImpl.GetAccessControlForSingleCompany(Rec."User Security ID", GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    local procedure CopyAccessControlToBuffer(UserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        TempAccessControlBuffer.Reset();
        TempAccessControlBuffer.DeleteAll();

        AccessControl.SetRange("User Security ID", UserSecurityID);
        if not AccessControl.FindSet() then
            exit;

        repeat
            Clear(TempAccessControlBuffer);
            TempAccessControlBuffer."Company Name" := AccessControl."Company Name";
            TempAccessControlBuffer.Scope := AccessControl.Scope;
            TempAccessControlBuffer."App ID" := AccessControl."App ID";
            TempAccessControlBuffer."Role ID" := AccessControl."Role ID";
            TempAccessControlBuffer.Insert();
        until AccessControl.Next() = 0;
    end;

    var
        ShowCompanyField: Boolean;
        ShowCompanyFieldOverride: Boolean;
        PermissionScope: Text;
        PermissionSetNotFound: Boolean;
        DeactivateAgentToEditPermissionsQst: Label 'Permissions can only be edited for inactive agents. Do you want to make the agent inactive now?';
}