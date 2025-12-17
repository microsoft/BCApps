// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4320 "View Agent Access Control"
{
    Caption = 'Agent Access Control';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(UserName; UserName)
                {
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the User that can access the agent.';
                    TableRelation = User where("License Type" = filter(<> Application & <> "Windows Group" & <> Agent));
                }
                field(UserFullName; UserFullName)
                {
                    Caption = 'User Full Name';
                    ToolTip = 'Specifies the Full Name of the User that can access the agent.';
                    Editable = false;
                }
                field(Company; Rec."Company Name")
                {
                    Caption = 'Company';
                    ToolTip = 'Specifies the company in which the user has access to the agent.';
                    Visible = ShowCompanyField;
                }
                field(CanConfigureAgent; Rec."Can Configure Agent")
                {
                    Caption = 'Can Configure';
                    Tooltip = 'Specifies whether the user can configure the agent.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditUserAccess)
            {
                ApplicationArea = All;
                Caption = 'Edit user access';
                Image = Edit;
                ToolTip = 'Edit the users that can access this agent.';

                trigger OnAction()
                var
                    Agent: Record Agent;
                    TempAgentAccessControl: Record "Agent Access Control" temporary;
                    SelectAgentAccessControl: Page "Select Agent Access Control";
                begin
                    if not Agent.Get(Rec."Agent User Security ID") then
                        exit;

                    if Agent.State <> Agent.State::Disabled then
                        if not Confirm(DeactivateAgentToEditAccessQst, false) then
                            exit
                        else begin
                            Agent.State := Agent.State::Disabled;
                            Agent.Modify(true);
                            Commit();
                        end;

                    CopyAgentAccessControlToBuffer(Rec."Agent User Security ID", TempAgentAccessControl);

                    SelectAgentAccessControl.Load(TempAgentAccessControl);
                    SelectAgentAccessControl.SetAgentUserSecurityID(Rec."Agent User Security ID");
                    SelectAgentAccessControl.RunModal();
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
        User: Record "User";
        AgentImpl: Codeunit "Agent Impl.";
        GlobalSingleCompanyName: Text[30];
    begin
        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(Rec."User Security ID", GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;

        Clear(UserFullName);
        Clear(UserName);

        if IsNullGuid(Rec."User Security ID") then
            exit;

        if not User.Get(Rec."User Security ID") then
            exit;

        UserName := User."User Name";
        UserFullName := User."Full Name";
    end;

    local procedure CopyAgentAccessControlToBuffer(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        AgentAccessControl.SetRange("Agent User Security ID", AgentUserSecurityID);
        if not AgentAccessControl.FindSet() then
            exit;

        repeat
            Clear(TempAgentAccessControl);
            TempAgentAccessControl.TransferFields(AgentAccessControl);
            TempAgentAccessControl.Insert();
        until AgentAccessControl.Next() = 0;
    end;

    var
        UserFullName: Text[80];
        UserName: Code[50];
        ShowCompanyField, ShowCompanyFieldOverride : Boolean;
        DeactivateAgentToEditAccessQst: Label 'Access control can only be edited for inactive agents. Do you want to make the agent inactive now?';
}