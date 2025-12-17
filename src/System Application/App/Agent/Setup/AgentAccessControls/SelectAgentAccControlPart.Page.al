// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4325 "Select Agent Acc. Control Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
    SourceTableTemporary = true;
    Caption = 'Agent Access Control';
    MultipleNewLines = false;
    Extensible = false;
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

                    trigger OnValidate()
                    begin
                        ValidateUserName(UserName);
                    end;
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

                    trigger OnValidate()
                    begin
                        if not Rec."Can Configure Agent" then
                            AgentImpl.VerifyOwnerExists(Rec);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AgentShowHideCompany)
            {
                ApplicationArea = All;
                Caption = 'Show/hide company';
                Image = CompanyInformation;
                ToolTip = 'Show or hide the company name.';

                trigger OnAction()
                begin
                    if AgentAccessControlMgt.ShouldConfirmShowCompanyForSingleCompany() then
                        // A confirmation dialog is raised when the user shows the company field
                        // for an agent that operates in a single company.
                        if not Confirm(ShowSingleCompanyQst, false) then
                            exit;

                    ShowCompanyField := AgentAccessControlMgt.ToggleShowCompanyField();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        if not IsNullGuid(Rec."Agent User Security ID") then begin
            AgentAccessControlMgt.Initialize(Rec."Agent User Security ID");
            ShowCompanyField := AgentAccessControlMgt.GetShowCompanyField();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
        AgentAccessControlMgt.UpdateCompanyFieldVisibility();
        ShowCompanyField := AgentAccessControlMgt.GetShowCompanyField();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        AgentImpl.VerifyOwnerExists(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Ensure the Agent User Security ID is set on new records
        if IsNullGuid(Rec."Agent User Security ID") then
            Rec."Agent User Security ID" := AgentUserSecurityID;

        // Default company name if not showing company field
        if (Rec."Company Name" = '') and not ShowCompanyField then
            Rec."Company Name" := CompanyName();

        // Update GlobalSingleCompanyName if transitioning to multi-company
        if (GlobalSingleCompanyName <> '') and (Rec."Company Name" <> GlobalSingleCompanyName) then
            GlobalSingleCompanyName := '';

        exit(true);
    end;

    local procedure ValidateUserName(NewUserName: Text)
    var
        UserSecurityID: Guid;
    begin
        if not AgentAccessControlMgt.FindUserByName(NewUserName, UserSecurityID) then
            exit;

        Rec.Validate("User Security ID", UserSecurityID);
        UpdateGlobalVariables();
    end;

    local procedure UpdateGlobalVariables()
    var
        User: Record "User";
    begin
        Clear(UserFullName);
        Clear(UserName);

        if IsNullGuid(Rec."User Security ID") then
            exit;

        if not User.Get(Rec."User Security ID") then
            exit;

        UserName := User."User Name";
        UserFullName := User."Full Name";
    end;

    internal procedure SetAgentUserSecurityID(NewAgentUserSecurityID: Guid)
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        AgentAccessControlMgt.Initialize(AgentUserSecurityID);
        UpdateCompanyFieldVisibility();
    end;

    internal procedure SetTempAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        Rec.Copy(TempAgentAccessControl, true);
        UpdateCompanyFieldVisibility();
        CurrPage.Update(false);
    end;

    local procedure UpdateCompanyFieldVisibility()
    begin
        AgentAccessControlMgt.UpdateCompanyFieldVisibility();
        ShowCompanyField := AgentAccessControlMgt.GetShowCompanyField();

        // Track single company name for insert logic
        AgentImpl.TryGetAccessControlForSingleCompany(AgentUserSecurityID, GlobalSingleCompanyName);
    end;

    internal procedure GetTempAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        Rec.Reset();
        if not Rec.FindSet() then
            exit;

        repeat
            TempAgentAccessControl.TransferFields(Rec);
            TempAgentAccessControl.Insert();
        until Rec.Next() = 0;
    end;

    var
        AgentImpl: Codeunit "Agent Impl.";
        AgentAccessControlMgt: Codeunit "Agent Access Control Mgt.";
        UserFullName: Text[80];
        UserName: Code[50];
        AgentUserSecurityID: Guid;
        GlobalSingleCompanyName: Text[30];
        ShowCompanyField: Boolean;
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign access controls in other companies where the agent is not available.\\Do you want to continue?';
}