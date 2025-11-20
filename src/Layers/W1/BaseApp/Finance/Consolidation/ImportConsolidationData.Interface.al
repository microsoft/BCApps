// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

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
