// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.AI;
using System.Environment;

codeunit 6993 "Expense Agent API Validation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentNotEnabledErr: Label 'Expense Agent is not enabled. Please contact your administrator.';
        CapabilityNotEnabledErr: Label 'The "%1" capability is not enabled. Please contact your administrator to enable the capability.', Comment = '%1 = a capability name, such as Expense Agent';

    procedure VerifyAgentAccess()
    begin
        VerifyAgentAccess(false);
    end;

    procedure VerifyAgentAccess(SkipEnableAgentCheck: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit;

        if not SkipEnableAgentCheck then begin
            if not ExpenseAgentSetup.FindFirst() then
                Error(AgentNotEnabledErr);

            if not ExpenseAgentSetup."Enable Agent" then
                Error(AgentNotEnabledErr);
        end;

        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent", true) then
            Error(CapabilityNotEnabledErr, Enum::"Copilot Capability"::"Expense Agent");
    end;

    procedure IsCurrentUserExpenseAgent(): Boolean
    var
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        exit(ExpenseAgentEntraApp.IsCurrentUserExpenseAgent());
    end;

    [TryFunction]
    internal procedure TryGetExpenseAgentUserId(var ExpenseAgentUserId: Guid)
    var
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        ExpenseAgentUserId := ExpenseAgentEntraApp.GetEnabledExpenseAgentUserId();
    end;
}
