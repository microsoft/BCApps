// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 130 "Consolidation Currency"
{
    /// <summary>
    /// Launches a configuration modal for the currency exchange rates used in the next consolidation for a BusinessUnit.
    /// Changes in this modal will be changed in the provided BusinessUnit, but no changes will be saved to the database.
    /// </summary>
    /// <param name="BusinessUnit">Business Unit to configure</param>
    procedure ConfigureBusinessUnitCurrencies(var BusinessUnit: Record "Business Unit")
    var
        SetupBusinessUnitCurrency: Page "Setup Business Unit Currency";
    begin
        ConfigureBusinessUnitCurrencies(SetupBusinessUnitCurrency, BusinessUnit);
    end;

    /// <summary>
    /// Launches a configuration modal for the currency exchange rates used in the ConsolidationProcess specified for a BusinessUnit.
    /// Changes in this modal will be changed in the provided BusinessUnit, but no changes will be saved to the database.
    /// </summary>
    /// <param name="BusinessUnit"></param>
    /// <param name="ConsolidationProcess"></param>
    procedure ConfigureBusinessUnitCurrencies(var BusinessUnit: Record "Business Unit"; ConsolidationProcess: Record "Consolidation Process")
    var
        SetupBusinessUnitCurrency: Page "Setup Business Unit Currency";
    begin
        SetupBusinessUnitCurrency.SetConsolidationProcess(ConsolidationProcess);
        ConfigureBusinessUnitCurrencies(SetupBusinessUnitCurrency, BusinessUnit);
    end;

    internal procedure GetConsolidationCompanyCurrencyCode(ConsolidationProcess: Record "Consolidation Process"): Code[10]
    begin
        if ConsolidationProcess."Parent Currency Code" <> '' then
            exit(ConsolidationProcess."Parent Currency Code");
        exit(GetCurrentCompanyCurrencyCode());
    end;

    internal procedure GetCurrentCompanyCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure ConfigureBusinessUnitCurrencies(var SetupBusinessUnitCurrency: Page "Setup Business Unit Currency"; var BusinessUnit: Record "Business Unit")
    begin
        SetupBusinessUnitCurrency.SetBusinessUnit(BusinessUnit);
        SetupBusinessUnitCurrency.LookupMode(true);
        if SetupBusinessUnitCurrency.RunModal() <> Action::LookupOK then
            exit;
        BusinessUnit."Income Currency Factor" := SetupBusinessUnitCurrency.GetIncomeCurrencyFactor();
        BusinessUnit.TestField("Income Currency Factor");
        BusinessUnit."Balance Currency Factor" := SetupBusinessUnitCurrency.GetBalanceCurrencyFactor();
        BusinessUnit.TestField("Balance Currency Factor");
        BusinessUnit."Last Balance Currency Factor" := SetupBusinessUnitCurrency.GetLastBalanceCurrencyFactor();
        BusinessUnit.TestField("Last Balance Currency Factor");
        BusinessUnit."Currency Exchange Rate Table" := SetupBusinessUnitCurrency.GetCurrencyExchangeRateTable();
    end;

}
