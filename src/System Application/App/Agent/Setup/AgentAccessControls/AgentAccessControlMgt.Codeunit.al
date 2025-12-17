// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

codeunit 4322 "Agent Access Control Mgt."
{
    Access = Internal;

    var
        AgentImpl: Codeunit "Agent Impl.";
        AgentUserSecurityID: Guid;
        ShowCompanyField: Boolean;
        ShowCompanyFieldOverride: Boolean;
        GlobalSingleCompanyName: Text[30];

    procedure Initialize(NewAgentUserSecurityID: Guid)
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        ShowCompanyFieldOverride := false;
        UpdateCompanyFieldVisibility();
    end;

    procedure UpdateCompanyFieldVisibility()
    begin
        if not ShowCompanyFieldOverride then
            ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(AgentUserSecurityID, GlobalSingleCompanyName);
    end;

    procedure GetShowCompanyField(): Boolean
    begin
        exit(ShowCompanyField);
    end;

    procedure ToggleShowCompanyField(): Boolean
    begin
        ShowCompanyFieldOverride := true;
        ShowCompanyField := not ShowCompanyField;
        exit(ShowCompanyField);
    end;

    procedure FindUserByName(NewUserName: Text; var UserSecurityID: Guid): Boolean
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

    procedure ShouldConfirmShowCompanyForSingleCompany(): Boolean
    begin
        exit((not ShowCompanyField) and (GlobalSingleCompanyName <> ''));
    end;
}