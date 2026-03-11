// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4338 "Select Agent Access Ctrl Part"
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
                    NotBlank = true;

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
                            VerifyOwnerExists();
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
                    if (not ShowCompanyField) and (GlobalSingleCompanyName <> '') then
                        // A confirmation dialog is raised when the user shows the company field
                        // for an agent that operates in a single company.
                        if not Confirm(ShowSingleCompanyQst, false) then
                            exit;

                    ShowCompanyFieldOverride := true;
                    ShowCompanyField := not ShowCompanyField;
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
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Can Configure Agent" then
            VerifyOwnerExists();
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(HandleCompanyNameOnInsert());
    end;

    internal procedure Initialize(NewAgentUserSecurityId: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentSingleCompany: Boolean;
    begin
        AgentUserSecurityID := NewAgentUserSecurityId;
        Rec.Copy(TempAgentAccessControl, true);

        AgentSingleCompany := AgentImpl.GetAccessControlForSingleCompany(AgentUserSecurityID, GlobalSingleCompanyName);
        if not ShowCompanyFieldOverride then
            ShowCompanyField := not AgentSingleCompany;
    end;

    local procedure HandleCompanyNameOnInsert(): Boolean
    var
        UserSecurityID: Guid;
    begin
        // If UserName is already populated (e.g., when duplicating a row), validate it to set User Security ID.
        if (UserName <> '') and IsNullGuid(Rec."User Security ID") then
            if FindUserByName(UserName, UserSecurityID) then
                Rec."User Security ID" := UserSecurityID;

        if IsNullGuid(Rec."User Security ID") then
            exit(true);

        Rec."Agent User Security ID" := AgentUserSecurityID;

        if (Rec."Company Name" = '') and not ShowCompanyField then
            if (GlobalSingleCompanyName <> '') then
                // Default to the single company used by the agent if the company field is not shown.
                Rec."Company Name" := GlobalSingleCompanyName
            else
#pragma warning disable AA0139
                // Default to the current company used by the agent if the company field is not shown and the agent operates in multiple ones.
                Rec."Company Name" := CompanyName();
#pragma warning restore AA0139

        exit(true);
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

    local procedure ValidateUserName(NewUserName: Text)
    var
        UserSecurityID: Guid;
    begin
        if not FindUserByName(NewUserName, UserSecurityID) then
            exit;

        Rec.Validate("User Security ID", UserSecurityID);
        UpdateGlobalVariables();
    end;

    local procedure FindUserByName(NewUserName: Text; var UserSecurityID: Guid): Boolean
    var
        User: Record User;
        UserGuid: Guid;
    begin
        if Evaluate(UserGuid, NewUserName) then begin
            if not User.Get(UserGuid) then
                exit(false);
            UserSecurityID := User."User Security ID";
            exit(true);
        end;

        User.SetRange("User Name", NewUserName);
        if not User.FindFirst() then begin
            User.SetFilter("User Name", '@*''''' + NewUserName + '''''*');
            if not User.FindFirst() then
                exit(false);
        end;

        UserSecurityID := User."User Security ID";
        exit(true);
    end;

    local procedure VerifyOwnerExists()
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        CurrentUserSecurityID: Guid;
        CurrentCompanyName: Text[30];
        OwnerFound: Boolean;
    begin
        CurrentUserSecurityID := Rec."User Security ID";
        CurrentCompanyName := Rec."Company Name";

        TempAgentAccessControl.Copy(Rec);

        // Check if there's at least one other record with "Can Configure Agent" = true
        Rec.SetRange("Agent User Security ID", AgentUserSecurityID);
        Rec.SetRange("Can Configure Agent", true);

        OwnerFound := false;
        if Rec.FindSet() then
            repeat
                if not ((Rec."User Security ID" = CurrentUserSecurityID) and (Rec."Company Name" = CurrentCompanyName)) then
                    OwnerFound := true;
            until (Rec.Next() = 0) or OwnerFound;

        Rec.Copy(TempAgentAccessControl);
        if not OwnerFound then
            Error(OneOwnerMustBeDefinedForAgentErr);
    end;

    var
        AgentImpl: Codeunit "Agent Impl.";
        AgentUserSecurityID: Guid;
        UserFullName: Text[80];
        UserName: Code[50];
        GlobalSingleCompanyName: Text[30];
        ShowCompanyField: Boolean;
        ShowCompanyFieldOverride: Boolean;
        OneOwnerMustBeDefinedForAgentErr: Label 'One owner must be defined for the agent.';
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign access controls in other companies where the agent is not available.\\Do you want to continue?';
}