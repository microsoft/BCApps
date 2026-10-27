// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3304 "Payables Agent KPI"
{
    Extensible = false;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Is Aggregate"; Boolean)
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the values in this record are aggregate values.';
        }
        field(3; "KPI Scenario"; Enum "PA KPI Scenario")
        {
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the KPI scenario that this record is related to.';
        }
        field(4; Count; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Specifies the count associated to this KPI entry.';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    procedure InsertKPIEntry(KPIScenario: Enum "PA KPI Scenario")
    var
        AggregateKPI: Record "Payables Agent KPI";
        KPIEntry: Record "Payables Agent KPI";
    begin
        AggregateKPI.LockTable();
        AggregateKPI.SetRange("Is Aggregate", true);
        AggregateKPI.SetRange("KPI Scenario", KPIScenario);
        if AggregateKPI.FindFirst() then begin
            AggregateKPI.Count += 1;
            AggregateKPI.Modify();
        end else begin
            AggregateKPI."Is Aggregate" := true;
            AggregateKPI."KPI Scenario" := KPIScenario;
            AggregateKPI.Count := 1;
            AggregateKPI.Insert();
        end;

        KPIEntry.Count := 1;
        KPIEntry."KPI Scenario" := KPIScenario;
        KPIEntry."Is Aggregate" := false;
        KPIEntry.Insert();
    end;

    procedure GetAggregateKPI(KPIScenario: Enum "PA KPI Scenario") AggregateKPI: Record "Payables Agent KPI"
    begin
        AggregateKPI.SetRange("Is Aggregate", true);
        AggregateKPI.SetRange("KPI Scenario", KPIScenario);
        if AggregateKPI.FindFirst() then;
    end;
}