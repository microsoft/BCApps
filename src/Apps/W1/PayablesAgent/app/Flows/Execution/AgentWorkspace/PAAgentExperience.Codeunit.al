// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

codeunit 3335 "PA Agent Experience"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

#if DEVELOPMENT
    var
        DevelopmentSettings: Codeunit "PA Development Settings";
#endif

    internal procedure IsActive(): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskId: BigInteger;
    begin
        if PayablesAgent.IsPayablesAgentSession(AgentTaskId) then
            exit(true);
#if DEVELOPMENT
        exit(DevelopmentSettings.SimulateAgentExperience());
#else
        exit(false);
#endif
    end;
}
