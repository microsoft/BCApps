// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

codeunit 6913 "Expense Agent Entra App Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure HasPermissionForCurrentCompany(AadApplication: Record "AAD Application"): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        SetExpenseAgentPermissionFilters(AccessControl, AadApplication);
        AccessControl.SetRange("Company Name", CompanyName());
        exit(not AccessControl.IsEmpty());
    end;

    internal procedure HasAnyPermission(AadApplication: Record "AAD Application"): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        SetExpenseAgentPermissionFilters(AccessControl, AadApplication);
        exit(not AccessControl.IsEmpty());
    end;

    internal procedure AddPermissionForCurrentCompany(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", ExpenseAgentPermissionSetLbl);
        if not AggregatePermissionSet.FindFirst() then
            exit;

        AccessControl.Init();
        AccessControl.Validate("User Security ID", AadApplication."User ID");
        AccessControl.Validate("Role ID", ExpenseAgentPermissionSetLbl);
        AccessControl.Validate("App ID", AggregatePermissionSet."App ID");
        AccessControl.Validate("Company Name", CompanyName());
        AccessControl.Insert(true);
    end;

    internal procedure RemovePermissionForCurrentCompany(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
    begin
        SetExpenseAgentPermissionFilters(AccessControl, AadApplication);
        AccessControl.SetRange("Company Name", CompanyName());
        AccessControl.DeleteAll(true);
    end;

    internal procedure EnableAadApplicationForCurrentCompany()
    var
        AadApplication: Record "AAD Application";
    begin
        if not GetAadApplication(AadApplication) then
            exit;

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
    begin
        if not GetAadApplication(AadApplication) then
            exit;

        RemovePermissionForCurrentCompany(AadApplication);
        if HasAnyPermission(AadApplication) then
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

    local procedure GetAadApplication(var AadApplication: Record "AAD Application"): Boolean
    begin
        AadApplication.SetRange("Client Id", GetAadAppId());
        exit(AadApplication.FindFirst());
    end;

    local procedure SetExpenseAgentPermissionFilters(var AccessControl: Record "Access Control"; AadApplication: Record "AAD Application")
    begin
        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.SetRange("Role ID", ExpenseAgentPermissionSetLbl);
    end;

    var
        ExpenseAgentAadAppIdTxt: Label 'ee1eb5fd-719b-44f2-97d0-0efd34bc4148', Locked = true;
        ExpenseAgentPermissionSetLbl: Label 'Expense Agent', Locked = true;
}
