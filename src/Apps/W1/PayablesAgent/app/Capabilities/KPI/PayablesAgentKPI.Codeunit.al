// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;


codeunit 3306 "Payables Agent KPI"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure InsertKPIEntry(KPIScenario: Enum "PA KPI Scenario")
    var
        PayablesAgentKPI: Record "Payables Agent KPI";
    begin
        PayablesAgentKPI.LockTable();
        PayablesAgentKPI.SetRange("Is Aggregate", true);
        PayablesAgentKPI.SetRange("KPI Scenario", KPIScenario);
        if PayablesAgentKPI.FindFirst() then begin
            PayablesAgentKPI.Count += 1;
            PayablesAgentKPI.Modify();
        end else begin
            PayablesAgentKPI."Is Aggregate" := true;
            PayablesAgentKPI."KPI Scenario" := KPIScenario;
            PayablesAgentKPI.Count := 1;
            PayablesAgentKPI.Insert();
        end;

        Clear(PayablesAgentKPI);
        PayablesAgentKPI.Count := 1;
        PayablesAgentKPI."KPI Scenario" := KPIScenario;
        PayablesAgentKPI."Is Aggregate" := false;
        PayablesAgentKPI.Insert();
    end;

    procedure GetAggregateKPI(KPIScenario: Enum "PA KPI Scenario") PayablesAgentKPI: Record "Payables Agent KPI"
    begin
        PayablesAgentKPI.SetRange("Is Aggregate", true);
        PayablesAgentKPI.SetRange("KPI Scenario", KPIScenario);
        if PayablesAgentKPI.FindFirst() then;
    end;

}