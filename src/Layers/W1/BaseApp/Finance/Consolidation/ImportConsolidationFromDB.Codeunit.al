// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

codeunit 116 "Import Consolidation from DB" implements "Import Consolidation Data"
{
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
