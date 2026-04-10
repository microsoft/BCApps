// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Implements consolidation data import from subsidiary companies through direct database connections.
/// Orchestrates database-based data retrieval for traditional on-premises and hybrid consolidation scenarios.
/// </summary>
/// <remarks>
/// Classic database-based consolidation import leveraging direct database connectivity to subsidiary systems.
/// Integrates with Import Consolidation from DB report for actual data extraction and processing.
/// Alternative to API-based consolidation for on-premises scenarios with direct database access.
/// Extensibility: Interface implementation allows for custom database import providers.
/// </remarks>
codeunit 116 "Import Consolidation from DB" implements "Import Consolidation Data"
{
    /// <summary>
    /// Imports consolidation data for a specific business unit from database source.
    /// Executes database import report and transfers consolidation data to business unit record.
    /// </summary>
    /// <param name="ConsolidationProcess">Consolidation Process record containing import parameters</param>
    /// <param name="BusinessUnit">Business Unit record for data import target</param>
    /// <param name="BusUnitConsolidationData">Bus. Unit Consolidation Data record to receive imported data</param>
    procedure ImportConsolidationDataForBusinessUnit(ConsolidationProcess: Record "Consolidation Process"; BusinessUnit: Record "Business Unit"; var BusUnitConsolidationData: Record "Bus. Unit Consolidation Data")
    var
        ImportConsolidationFromDB: Report "Import Consolidation from DB";
        Consolidate: Codeunit Consolidate;
    begin
        ImportConsolidationFromDB.SetConsolidationProcessParameters(ConsolidationProcess, BusinessUnit);
        ImportConsolidationFromDB.Execute('');
        ImportConsolidationFromDB.GetConsolidate(Consolidate);
        BusUnitConsolidationData.SetConsolidate(Consolidate);
    end;
}
