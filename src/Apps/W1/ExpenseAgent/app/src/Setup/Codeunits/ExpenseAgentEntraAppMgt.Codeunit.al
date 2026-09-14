// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

codeunit 6913 "Expense Agent Entra App Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "AAD Application" = rm,
        tabledata "Access Control" = rimd;

    internal procedure EnableAadApplicationForCurrentCompany()
    begin
        VerifyCurrentUserCanManageExpenseAgent();
        EnableAadApplicationForCurrentCompanyWithoutAuthorization();
    end;

    internal procedure DisableAadApplicationForCurrentCompany()
    begin
        VerifyCanDisableAadApplicationForCurrentCompany();
        DisableAadApplicationForCompany(GetCurrentCompanyName());
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

    internal procedure VerifyCanDisableAadApplicationForCurrentCompany()
    var
        AadApplication: Record "AAD Application";
    begin
        VerifyCurrentUserCanManageExpenseAgent();
        GetAadApplication(AadApplication);
    end;

    local procedure EnableAadApplicationForCurrentCompanyWithoutAuthorization()
    var
        AadApplication: Record "AAD Application";
    begin
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

        AddPermissionForCompany(AadApplication, GetCurrentCompanyName());

        AadApplication.Validate(State, AadApplication.State::Enabled);
        AadApplication.Modify(true);
    end;

    local procedure DisableAadApplicationForCompany(CompanyNameValue: Text[30])
    var
        AadApplication: Record "AAD Application";
        OtherCompanyPermissionExists: Boolean;
    begin
        if not AadApplication.Get(GetAadAppId()) then
            exit;

        OtherCompanyPermissionExists := HasOtherCompanyPermission(AadApplication, CompanyNameValue);
        RemovePermissionForCompany(AadApplication, CompanyNameValue, not OtherCompanyPermissionExists);
        if OtherCompanyPermissionExists then
            exit;
        if AadApplication.State = AadApplication.State::Disabled then
            exit;

        AadApplication.Validate(State, AadApplication.State::Disabled);
        AadApplication.Modify(true);
    end;

    local procedure VerifyCurrentUserCanManageExpenseAgent()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        UserPermissions: Codeunit "User Permissions";
    begin
        GetAgentAdminPermissionSet(AggregatePermissionSet);
        if not UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID")
        then
            Error(AgentAdminPermissionRequiredErr);

        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            Error(AgentAdminPermissionRequiredErr);

        GetExpenseManagementAdminPermissionSet(AggregatePermissionSet);
        if not UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID")
        then
            Error(ExpenseManagementAdminPermissionRequiredErr);

        if not HasSecurityPermission(UserPermissions) then
            Error(SecurityPermissionRequiredErr);

        GetExpenseAgentPermissionSet(AggregatePermissionSet);
        if not UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID")
        then
            Error(ExpenseAgentPermissionRequiredErr);
    end;

    local procedure HasSecurityPermission(UserPermissions: Codeunit "User Permissions"): Boolean
    var
        AccessControl: Record "Access Control";
        NullGuid: Guid;
    begin
        if UserPermissions.IsSuper(UserSecurityId()) then
            exit(true);

        exit(UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            SecurityPermissionSetLbl,
            AccessControl.Scope::System,
            NullGuid));
    end;

    local procedure HasPermissionForCurrentCompany(AadApplication: Record "AAD Application"): Boolean
    begin
        exit(HasPermissionForCompany(AadApplication, GetCurrentCompanyName()));
    end;

    local procedure HasPermissionForCompany(AadApplication: Record "AAD Application"; CompanyNameValue: Text[30]): Boolean
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SetRange("Company Name", CompanyNameValue);
        exit(not AccessControl.IsEmpty());
    end;

    local procedure HasOtherCompanyPermission(AadApplication: Record "AAD Application"; CompanyNameValue: Text[30]): Boolean
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);
        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SecurityFiltering(SecurityFilter::Ignored);
        AccessControl.SetFilter("Company Name", '<>''''&<>%1', CompanyNameValue);
        exit(not AccessControl.IsEmpty());
    end;

    local procedure AddPermissionForCompany(AadApplication: Record "AAD Application"; CompanyNameValue: Text[30])
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if HasPermissionForCompany(AadApplication, CompanyNameValue) then
            exit;

        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        AccessControl.Init();
        AccessControl.Validate("User Security ID", AadApplication."User ID");
        AccessControl.Validate("Role ID", AggregatePermissionSet."Role ID");
        AccessControl.Validate("App ID", AggregatePermissionSet."App ID");
        AccessControl.Validate(Scope, AggregatePermissionSet.Scope);
        AccessControl.Validate("Company Name", CompanyNameValue);
        AccessControl.Insert(true);
    end;

    local procedure RemovePermissionForCompany(AadApplication: Record "AAD Application"; CompanyNameValue: Text[30]; RunTrigger: Boolean)
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);

        SetExpenseAgentPermissionFilters(AccessControl, AadApplication, AggregatePermissionSet);
        AccessControl.SetRange("Company Name", CompanyNameValue);
        AccessControl.DeleteAll(RunTrigger);
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

    local procedure GetExpenseAgentPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        GetPermissionSet(AggregatePermissionSet, ExpenseAgentPermissionSetLbl);
    end;

    local procedure GetAgentAdminPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        BaseApplicationAppId: Guid;
    begin
        Evaluate(BaseApplicationAppId, BaseApplicationAppIdTxt);
        AggregatePermissionSet.Reset();
        AggregatePermissionSet.SetRange("App ID", BaseApplicationAppId);
        AggregatePermissionSet.SetRange("Role ID", AgentAdminPermissionSetLbl);
        if not AggregatePermissionSet.FindFirst() then
            Error(PermissionSetMissingErr, AgentAdminPermissionSetLbl);
    end;

    local procedure GetExpenseManagementAdminPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        GetPermissionSet(AggregatePermissionSet, ExpenseManagementAdminPermissionSetLbl);
    end;

    local procedure GetPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set"; PermissionSetId: Code[20])
    var
        ExpenseAgentAppId: Guid;
    begin
        AggregatePermissionSet.Reset();
        Evaluate(ExpenseAgentAppId, ExpenseAgentAppIdTxt);
        AggregatePermissionSet.SetRange("App ID", ExpenseAgentAppId);
        AggregatePermissionSet.SetRange("Role ID", PermissionSetId);
        if not AggregatePermissionSet.FindFirst() then
            Error(PermissionSetMissingErr, PermissionSetId);
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
        BaseApplicationAppIdTxt: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        AgentAdminPermissionSetLbl: Label 'Agent - Admin', Locked = true;
        ExpenseAgentPermissionSetLbl: Label 'Expense Agent', Locked = true;
        ExpenseManagementAdminPermissionSetLbl: Label 'Expense Mgmt. Admin', Locked = true;
        SecurityPermissionSetLbl: Label 'SECURITY', Locked = true;
        AgentAdminPermissionRequiredErr: Label 'You must be assigned the Agent - Admin permission set to manage the Expense Agent Microsoft Entra application.';
        AadApplicationMissingErr: Label 'The Expense Agent Microsoft Entra application is not configured.';
        ExpenseAgentPermissionRequiredErr: Label 'You must be assigned the Expense Agent permission set to manage the Expense Agent Microsoft Entra application.';
        ExpenseManagementAdminPermissionRequiredErr: Label 'You must be assigned the Expense Management - Admin permission set to manage the Expense Agent Microsoft Entra application.';
        PermissionSetMissingErr: Label 'The %1 permission set is not available.', Comment = '%1 = permission set ID';
        SecurityPermissionRequiredErr: Label 'You must be assigned either the SUPER or SECURITY permission set to manage the Expense Agent Microsoft Entra application.';
}
