// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.User;
using System.Security.AccessControl;

pageextension 4318 "Agent User Subfrom" extends "User Subform"
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

                trigger OnAction()
                begin
                    ShowCompanyOverride := true;
                    ShowCompanyField := not ShowCompanyField;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if (IsAgent and (Rec."Company Name" = '') and (GlobalSingleCompanyName <> '') and not ShowCompanyField) then
            // If the company name is not specified, the agent operates in single company,
            // and the user didn't toggle to view the company names, default the inserted record
            // to the single known company name.
            Rec."Company Name" := GlobalSingleCompanyName;
    end;

    local procedure UpdateGlobalVariables()
    var
        User: Record User;
    begin
        if User.Get(Rec."User Security ID") then
            IsAgent := User."License Type" = User."License Type"::Agent
        else
            IsAgent := false;

        // var UserSettings: Codeunit "User Settings";
        // UserSettings.GetAllowedCompaniesForCurrentUser(Rec);
        if not ShowCompanyOverride then begin
            ShowCompanyField := not AccessControlForSingleCompany(GlobalSingleCompanyName);
            CurrPage.Update(false);
        end;
    end;

    local procedure AccessControlForSingleCompany(var SingleCompanyName: Text[30]): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        if not IsAgent then
            exit(false);

        AccessControl.SetRange("User Security ID", Rec."User Security ID");
        if not AccessControl.FindFirst() then
            exit(false);

        SingleCompanyName := AccessControl."Company Name";
        if SingleCompanyName = '' then
            // The agent has access to all companies.
            exit(false);

        while AccessControl.Next() <> 0 do begin
            if SingleCompanyName <> AccessControl."Company Name" then begin
                SingleCompanyName := '';
                exit(false);
            end;
        end;

        exit(true);
    end;

    var
        IsAgent: Boolean;
        ShowCompanyField: Boolean;
        ShowCompanyOverride: Boolean;
        GlobalSingleCompanyName: Text[30];
}