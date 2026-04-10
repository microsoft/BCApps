// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Provides the standard consolidation method using the core Consolidate codeunit.
/// Implements the default consolidation processing logic for business unit data integration.
/// </summary>
codeunit 434 "Default Consolidation Method" implements "Consolidation Method"
{
    /// <summary>
    /// Executes consolidation processing for a business unit using standard consolidation logic.
    /// Retrieves consolidation data and runs the core Consolidate codeunit for processing.
    /// </summary>
    /// <param name="ConsolidationProcess">Consolidation Process record defining consolidation parameters</param>
    /// <param name="BusinessUnit">Business Unit being consolidated</param>
    /// <param name="BusUnitConsolidationData">Business Unit Consolidation Data containing imported data for processing</param>
    procedure Consolidate(ConsolidationProcess: Record "Consolidation Process"; BusinessUnit: Record "Business Unit"; var BusUnitConsolidationData: Record "Bus. Unit Consolidation Data");
    var
        ConsolidateData: Codeunit Consolidate;
    begin
        BusUnitConsolidationData.GetConsolidate(ConsolidateData);
        ConsolidateData.Run(BusinessUnit);
    end;
}
