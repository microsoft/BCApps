// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;

codeunit 3306 "Payables Agent KPI"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure CountPurchaseInvoiceCreatedByAgent(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PayablesAgentKPI: Record "Payables Agent KPI";
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskId: BigInteger;
    begin
        if Rec.IsTemporary() or (Rec."Document Type" <> Rec."Document Type"::Invoice) then
            exit;
        if not PayablesAgent.IsPayablesAgentSession(AgentTaskId) or (AgentTaskId = 0) then
            exit;
        PayablesAgentKPI.InsertKPIEntry("PA KPI Scenario"::"Purchase Invoices created by Agent");
    end;
}