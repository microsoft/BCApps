// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

codeunit 6913 "Expense Agent Entra App Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure EnableAadApplicationForCurrentCompany()
    var
        AadApplication: Record "AAD Application";
    begin
        EnsureCurrentUserCanManageExpenseAgent();
        GetAadApplication(AadApplication);

        // Enabling creates the application user. Disable it again before changing permissions.
        if AadApplication.State <> AadApplication.State::Enabled then begin
            AadApplication.Validate(State, AadApplication.State::Enabled);
            AadApplication.Modify(true);
        end;

        if HasPermissionForCurrentCompany(AadApplication) then
            exit;

        AadApplication.Validate(State, AadApplication.State::Disabled);
        AadApplication.Modify(true);

        AddPermissionForCurrentCompany(AadApplication);

        AadApplication.Validate(State, AadApplication.State::Enabled);
        AadApplication.Modify(true);
    end;

    internal procedure DisableAadApplicationForCurrentCompany()
    var
        AadApplication: Record "AAD Application";
        HasOtherCompanyPermission: Boolean;
    begin
        EnsureCurrentUserCanManageExpenseAgent();
        GetAadApplication(AadApplication);

        HasOtherCompanyPermission := HasExpenseAgentPermissionForOtherCompany(AadApplication);
        RemovePermissionForCurrentCompany(AadApplication);
        if HasOtherCompanyPermission then
            exit;
        if AadApplication.State = AadApplication.State::Disabled then
            exit;

        AadApplication.Validate(State, AadApplication.State::Disabled);
        AadApplication.Modify(true);
    end;

    internal procedure IsCurrentUserExpenseAgent(): Boolean
    var
        AadApplication: Record "AAD Application";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit(true);

        if not AadApplication.Get(GetAadAppId()) then
            exit(false);

        exit(AadApplication."User ID" = UserSecurityId());
    end;

    internal procedure GetEnabledExpenseAgentUserId(): Guid
    var
        AadApplication: Record "AAD Application";
    begin
        AadApplication.Get(GetAadAppId());
        AadApplication.TestField(State, AadApplication.State::Enabled);

        exit(AadApplication."User ID");
    end;

    internal procedure GetAadAppId(): Text
    begin
        exit(ExpenseAgentAadAppIdTxt);
    end;

    local procedure HasPermissionForCurrentCompany(AadApplication: Record "AAD Application"): Boolean
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SetFilter("Company Name", '%1|''''', GetCurrentCompanyName());
        exit(not AccessControl.IsEmpty());
    end;

    local procedure HasExpenseAgentPermissionForOtherCompany(AadApplication: Record "AAD Application"): Boolean
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SetFilter("Company Name", '<>%1', GetCurrentCompanyName());
        exit(not AccessControl.IsEmpty());
    end;

    local procedure AddPermissionForCurrentCompany(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        AccessControl.Init();
        AccessControl.Validate("User Security ID", AadApplication."User ID");
        AccessControl.Validate("Role ID", AggregatePermissionSet."Role ID");
        AccessControl.Validate("App ID", AggregatePermissionSet."App ID");
        AccessControl.Validate(Scope, AggregatePermissionSet.Scope);
        AccessControl.Validate("Company Name", GetCurrentCompanyName());
        AccessControl.Insert(true);
    end;

    local procedure RemovePermissionForCurrentCompany(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SetRange("Company Name", GetCurrentCompanyName());
        AccessControl.DeleteAll(true);
    end;

    local procedure GetAadApplication(var AadApplication: Record "AAD Application")
    begin
        if not AadApplication.Get(GetAadAppId()) then
            Error(AadApplicationMissingErr);
    end;

    local procedure GetCurrentCompanyName(): Text[30]
    begin
        exit(CopyStr(CompanyName(), 1, 30));
    end;

    local procedure EnsureCurrentUserCanManageExpenseAgent()
    var
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            Error(NotAuthorizedToManageExpenseAgentErr);
    end;

    local procedure GetExpenseAgentPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        ExpenseAgentAppId: Guid;
    begin
        Evaluate(ExpenseAgentAppId, ExpenseAgentAppIdTxt);
        AggregatePermissionSet.SetRange("App ID", ExpenseAgentAppId);
        AggregatePermissionSet.SetRange("Role ID", ExpenseAgentPermissionSetLbl);
        if not AggregatePermissionSet.FindFirst() then
            Error(ExpenseAgentPermissionSetMissingErr);
    end;

    local procedure SetExpenseAgentPermissionFilters(var AccessControl: Record "Access Control"; AadApplication: Record "AAD Application"; AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.SetRange("Role ID", AggregatePermissionSet."Role ID");
        AccessControl.SetRange(Scope, AggregatePermissionSet.Scope);
        AccessControl.SetRange("App ID", AggregatePermissionSet."App ID");
    end;

    var
        ExpenseAgentAadAppIdTxt: Label 'ee1eb5fd-719b-44f2-97d0-0efd34bc4148', Locked = true;
        ExpenseAgentAppIdTxt: Label '66efe10c-8033-403b-a86d-77c0887178ba', Locked = true;
        ExpenseAgentPermissionSetLbl: Label 'Expense Agent', Locked = true;
        AadApplicationMissingErr: Label 'The Expense Agent Microsoft Entra application is not configured.';
        ExpenseAgentPermissionSetMissingErr: Label 'The Expense Agent permission set is not available.';
        NotAuthorizedToManageExpenseAgentErr: Label 'You do not have permission to manage the Expense Agent.';
}
