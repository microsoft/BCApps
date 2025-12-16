// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4321 "Select Agent Access Control"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
    SourceTableTemporary = true;
    Caption = 'Select users to manage tasks and configure the agent';
    MultipleNewLines = false;
    Extensible = false;
    DataCaptionExpression = '';
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
                        CurrPage.Update(true);
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
                    Caption = 'Can configure';
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
                    if (not ShowCompanyField and (GlobalSingleCompanyName <> '')) then
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

    trigger OnAfterGetRecord() // Same
    begin
        UpdateGlobalVariables();
    end;

    trigger OnAfterGetCurrRecord() // Same
    begin
        UpdateGlobalVariables();
    end;

    trigger OnDeleteRecord(): Boolean // Similar, because this is temp table
    begin
        VerifyOwnerExists();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean// Same
    begin
        if (GlobalSingleCompanyName <> '') then begin
            if (Rec."Company Name" = '') and not ShowCompanyField then
                // Default the company name for the inserted record when all these conditions are met:
                // 1. The agent operates in a single company,
                // 2. The company name is not explicit specified,
                // 3. The user didn't toggle to view the company name field on access controls.
                Rec."Company Name" := GlobalSingleCompanyName;

            if (Rec."Company Name" <> GlobalSingleCompanyName) then
                // The agent used to operate in a single company, but operates in multiple ones now.
                // Ideally, other scenarios should also trigger an update (delete, modify), but insert
                // was identified as the main one.
                GlobalSingleCompanyName := '';
        end;
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Agent User Security ID") <> '' then
            Evaluate(AgentUserSecurityID, Rec.GetFilter("Agent User Security ID"));

        if Rec.Count() = 0 then
            AgentImpl.InsertCurrentOwner(Rec."Agent User Security ID", Rec);

        UpdateGlobalVariables();
    end;

    local procedure ValidateUserName(NewUserName: Text)
    var
        User: Record "User";
        UserGuid: Guid;
    begin
        if Evaluate(UserGuid, NewUserName) then begin
            User.Get(UserGuid);
            UpdateUser(User."User Security ID");
            UpdateGlobalVariables();
            exit;
        end;

        User.SetRange("User Name", NewUserName);
        if not User.FindFirst() then begin
            User.SetFilter("User Name", '@*''''' + NewUserName + '''''*');
            User.FindFirst();
        end;

        UpdateUser(User."User Security ID");
        UpdateGlobalVariables();
    end;

    local procedure UpdateUser(NewUserID: Guid) // Similar, because this is temp table
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        RecordExists: Boolean;
    begin
        RecordExists := Rec.Find();

        if RecordExists then begin
            TempAgentAccessControl.Copy(Rec);
            Rec.Delete();
            Rec.Copy(TempAgentAccessControl);
        end;

        Rec."User Security ID" := NewUserID;
        Rec."Agent User Security ID" := AgentUserSecurityID;
        Rec.Insert(true);
        VerifyOwnerExists();
    end;

    local procedure UpdateGlobalVariables() // Same 
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

        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(AgentUserSecurityID, GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    local procedure VerifyOwnerExists()
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
    begin
        TempAgentAccessControl.Copy(Rec);
        Rec.SetFilter("Can Configure Agent", '%1', true);
        Rec.SetFilter("User Security ID", '<>%1', Rec."User Security ID");
        if Rec.IsEmpty() then begin
            Rec.Copy(TempAgentAccessControl);
            Error(OneOwnerMustBeDefinedForAgentErr);
        end;

        Rec.Copy(TempAgentAccessControl);
    end;

    var
        AgentImpl: Codeunit "Agent Impl.";
        UserFullName: Text[80];
        UserName: Code[50];
        AgentUserSecurityID: Guid;
        ShowCompanyField, ShowCompanyFieldOverride : Boolean;
        GlobalSingleCompanyName: Text[30];
        OneOwnerMustBeDefinedForAgentErr: Label 'One owner must be defined for the agent.';
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign access controls in other companies where the agent is not available.\\Do you want to continue?';
}