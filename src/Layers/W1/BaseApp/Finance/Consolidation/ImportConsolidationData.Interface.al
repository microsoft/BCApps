// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Interface defining contract for importing consolidation data from various sources.
/// Provides standardized method for business unit consolidation data retrieval from different providers.
/// </summary>
/// <remarks>
/// Extensibility interface enabling custom consolidation data import providers (database, API, file).
/// Implemented by consolidation import codeunits to provide unified data import functionality.
/// Supports multiple consolidation data sources through consistent interface pattern.
/// </remarks>
interface "Import Consolidation Data"
{
    Access = Public;
    /// <summary>
    /// Import the business unit consolidation data for the given consolidation process and business unit. The imported data should be stored in the BusUnitConsolidationData temporary record.
    /// </summary>
    /// <param name="ConsolidationProcess"></param>
    /// <param name="BusinessUnit"></param>
    /// <param name="BusUnitConsolidationData"></param>
    procedure ImportConsolidationDataForBusinessUnit(ConsolidationProcess: Record "Consolidation Process"; BusinessUnit: Record "Business Unit"; var BusUnitConsolidationData: Record "Bus. Unit Consolidation Data");
}
