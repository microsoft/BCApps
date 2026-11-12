// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6988 "Expense API Currency Helper"
{
    Access = Internal;
    SingleInstance = true;

    var
        CachedLCYCode: Code[10];
        IsCached: Boolean;

    /// <summary>
    /// Returns the LCY code from General Ledger Setup when the stored currency code is blank.
    /// </summary>
    /// <param name="CurrencyCode">Currency code read from the underlying record.</param>
    /// <returns>Blank-aware currency code to expose via API.</returns>
    internal procedure GetCurrencyCodeForAPI(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(GetLCYCode());
    end;

    /// <summary>
    /// Converts an incoming API currency code to the internal representation, where LCY is stored as blank.
    /// </summary>
    /// <param name="CurrencyCode">Currency code provided by the API consumer.</param>
    /// <returns>Blank for LCY codes; otherwise the original currency code.</returns>
    internal procedure GetCurrencyCodeFromAPI(CurrencyCode: Code[10]): Code[10]
    var
        LCYCode: Code[10];
    begin
        if CurrencyCode = '' then
            exit('');

        LCYCode := GetLCYCode();
        if (LCYCode <> '') and (LCYCode = CurrencyCode) then
            exit('');

        exit(CurrencyCode);
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if IsCached then
            exit(CachedLCYCode);

        if GeneralLedgerSetup.Get() then begin
            CachedLCYCode := GeneralLedgerSetup."LCY Code";
            IsCached := true;
            exit(CachedLCYCode);
        end;
    end;
}
