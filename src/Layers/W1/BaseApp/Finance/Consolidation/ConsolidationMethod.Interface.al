// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

interface "Consolidation Method"
{
    Access = Public;
    /// <summary>
    /// This procedure is called for each business unit in the consolidation process. It should consolidate (insert the appropriate GL Entries in the consolidation company) with the information in the BusUnitConsolidationData temporary record.
    /// When this procedure is called BusUnitConsolidationData contains the data imported from the business unit (ImportConsolidationData interface), it contains the "Consolidate" codeunit which contains the data to be consolidated.
    /// </summary>
    /// <param name="ConsolidationProcess"></param>
    /// <param name="BusinessUnit"></param>
    /// <param name="BusUnitConsolidationData"></param>
    procedure Consolidate(ConsolidationProcess: Record "Consolidation Process"; BusinessUnit: Record "Business Unit"; var BusUnitConsolidationData: Record "Bus. Unit Consolidation Data");
}
