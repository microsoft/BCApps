// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;

codeunit 6922 "EA Agent Attribution"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = rm;

    internal procedure UpdateConfiguredBy(AgentUserSecurityId: Guid)
    var
        Agent: Record Agent;
    begin
        if Agent.Get(AgentUserSecurityId) then
            Agent.Modify();
    end;
}
