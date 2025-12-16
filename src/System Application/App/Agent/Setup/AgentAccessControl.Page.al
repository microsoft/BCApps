// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4320 "Agent Access Control"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
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

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
    end;

    trigger OnAfterGetRecord() // Same
    begin
        UpdateGlobalVariables();
    end;

    trigger OnAfterGetCurrRecord() // Same
    begin
        UpdateGlobalVariables();
    end;

    trigger OnDeleteRecord(): Boolean // Similar, because this is not temp table
    begin
        AgentImpl.VerifyOwnerExists(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean // Same
    begin
        if (Rec."Company Name" = '') and not ShowCompanyField then
            // If the company field is not displayed, default to the current company.
            // If the user is displaying the company field, respect what they entered.
            Rec."Company Name" := CompanyName();

        if (GlobalSingleCompanyName <> '') and (Rec."Company Name" <> GlobalSingleCompanyName) then
            // The agent used to operate in a single company, but operates in multiple ones now.
            // Ideally, other scenarios should also trigger an update (delete, modify), but insert
            // was identified as the main one.
            GlobalSingleCompanyName := '';
    end;

    local procedure ValidateUserName(NewUserName: Text) // Same
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

    local procedure UpdateUser(NewUserID: Guid)// Similar, because this is not temp table
    var
        RecordExists: Boolean;
    begin
        RecordExists := Rec.Find();

        if RecordExists then
            Error(CannotUpdateUserErr);

        Rec."User Security ID" := NewUserID;
        Rec.Insert(true);
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
            ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(Rec."Agent User Security ID", GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    var
        AgentImpl: Codeunit "Agent Impl.";
        UserFullName: Text[80];
        UserName: Code[50];
        ShowCompanyField, ShowCompanyFieldOverride : Boolean;
        GlobalSingleCompanyName: Text[30];
        CannotUpdateUserErr: Label 'You cannot change the User. Delete and create the entry again.';
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign access controls in other companies where the agent is not available.\\Do you want to continue?';
}