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
    Extensible = false;
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
                    TempAgentAccessControl: Record "Agent Access Control" temporary;
                    AgentImpl: Codeunit "Agent Impl.";
                    SelectAgentAccessControl: Page "Select Agent Access Control";
                begin
                    CopyAgentAccessControlToBuffer(Rec."Agent User Security ID", TempAgentAccessControl);

                    SelectAgentAccessControl.Initialize(Rec."Agent User Security ID", TempAgentAccessControl);
                    if SelectAgentAccessControl.RunModal() = Action::OK then begin
                        SelectAgentAccessControl.GetTempAgentAccessControl(TempAgentAccessControl);
                        AgentImpl.UpdateAgentAccessControl(Rec."Agent User Security ID", TempAgentAccessControl);
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
        User: Record "User";
        AgentImpl: Codeunit "Agent Impl.";
        GlobalSingleCompanyName: Text[30];
    begin
        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not AgentImpl.GetAccessControlForSingleCompany(Rec."Agent User Security ID", GlobalSingleCompanyName);
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

    local procedure CopyAgentAccessControlToBuffer(UserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        AgentAccessControl.SetRange("Agent User Security ID", UserSecurityID);
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
}