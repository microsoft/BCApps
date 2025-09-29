// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;
using System.Security.User;
using System.Environment;
using System.Environment.Configuration;

pageextension 4318 "Agent User Subform" extends "User Subform"
{
    layout
    {
        modify(Company)
        {
            Visible = (not IsAgent) or ShowCompanyField;
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(AgentShowHideCompany)
            {
                ApplicationArea = All;
                Caption = 'Show/hide company';
                Enabled = IsAgent;
                Image = CompanyInformation;
                Visible = IsAgent;
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

    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if (IsAgent and (GlobalSingleCompanyName <> '')) then begin
            if (Rec."Company Name" = '') and not ShowCompanyField then
                // Default the company name for the inserted record when all these conditions are met:
                // 1. The agent operates in a single company,
                // 2. The company name is not explicit specified,
                // 3. The user didn't toggle to view the company name field on permissions.
                Rec."Company Name" := GlobalSingleCompanyName;

            if (Rec."Company Name" <> GlobalSingleCompanyName) then
                // The agent used to operation in a single company, but operates in multiple ones now.
                // Ideally, other scenarios should also trigger an update (delete, modify), but insert
                // was identified as the main one.
                GlobalSingleCompanyName := '';
        end;
    end;

    local procedure UpdateGlobalVariables()
    var
        User: Record User;
    begin
        if User.Get(Rec."User Security ID") then
            IsAgent := User."License Type" = User."License Type"::Agent
        else
            IsAgent := false;

        if not ShowCompanyFieldOverride then begin
            ShowCompanyField := not AccessControlForSingleCompany(GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    local procedure AccessControlForSingleCompany(var SingleCompanyName: Text[30]): Boolean
    var
        TempCompany: Record Company temporary;
        UserSettings: Codeunit "User Settings";
    begin
        if not IsAgent then
            exit(false);

        UserSettings.GetAllowedCompaniesForUser(Rec."User Security ID", TempCompany);
        if TempCompany.Count() <> 1 then
            exit(false);

        SingleCompanyName := TempCompany.Name;
        exit(true);
    end;

    var
        IsAgent: Boolean;
        ShowCompanyField: Boolean;
        ShowCompanyFieldOverride: Boolean;
        GlobalSingleCompanyName: Text[30];
        ShowSingleCompanyQst: Label 'This agent currently has permissions in only one company. By showing the Company field, you will be able to assign permissions in other companies, making the agent available there. The agent may not have been designed to work cross companies.\\Do you want to continue?';
}