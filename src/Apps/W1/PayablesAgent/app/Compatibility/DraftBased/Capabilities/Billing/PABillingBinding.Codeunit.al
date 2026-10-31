// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Environment.Configuration;

codeunit 3334 "PA Billing Binding"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;

    var
        PABilling: Codeunit "PA Billing";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterInitialization, '', false, false)]
    local procedure RegisterSubscribersOnAfterLogin()
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        PayablesAgentSessionID: BigInteger;
    begin
        if not PayablesAgent.IsPayablesAgentSession(PayablesAgentSessionID) then
            exit;

        // Agent login must fail if we cannot register agent subscribers or if there are too many unpaid entries
        BindSubscription(PABilling);
    end;
}