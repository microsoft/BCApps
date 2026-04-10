// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Manages additional reporting currency functionality for parallel currency reporting.
/// Provides calculation and conversion services for maintaining financial data
/// in both local currency and an additional reporting currency simultaneously.
/// </summary>
/// <remarks>
/// Integrates with General Ledger Setup to support dual-currency reporting requirements.
/// Used primarily for statutory reporting in multinational organizations where
/// financial statements must be presented in multiple currencies.
/// </remarks>
codeunit 5837 "Additional-Currency Management"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        GLSetupRead: Boolean;
        CurrencyRead: Boolean;

    local procedure InitCodeunit(): Boolean
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        if GLSetup."Additional Reporting Currency" = '' then
            exit;
        if not CurrencyRead then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Unit-Amount Rounding Precision");
            Currency.TestField("Amount Rounding Precision");
            CurrencyRead := true;
        end;
        exit(true);
    end;

    /// <summary>
    /// Calculates amount in additional reporting currency using current exchange rates.
    /// Converts local currency amounts to additional currency for parallel reporting.
    /// </summary>
    /// <param name="Amount">The amount in local currency to be converted.</param>
    /// <param name="PostingDate">The posting date for exchange rate lookup.</param>
    /// <param name="IsUnitAmount">Set to true if converting unit amounts (uses unit-amount rounding precision).</param>
    /// <returns>The converted amount in additional reporting currency, properly rounded.</returns>
    procedure CalcACYAmt(Amount: Decimal; PostingDate: Date; IsUnitAmount: Boolean): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if not InitCodeunit() then
            exit;
        exit(
          RoundACYAmt(
            CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency", Amount,
              CurrExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency")),
            IsUnitAmount));
    end;

    /// <summary>
    /// Rounds additional currency amounts using appropriate precision settings.
    /// Applies currency-specific rounding rules for amounts in additional reporting currency.
    /// </summary>
    /// <param name="UnroundedACYAmt">The unrounded amount in additional currency.</param>
    /// <param name="IsUnitAmount">Set to true for unit amounts (uses unit-amount rounding), false for regular amounts.</param>
    /// <returns>The properly rounded amount according to additional currency precision settings.</returns>
    procedure RoundACYAmt(UnroundedACYAmt: Decimal; IsUnitAmount: Boolean): Decimal
    var
        RndgPrec: Decimal;
    begin
        if not InitCodeunit() then
            exit;
        if IsUnitAmount then
            RndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            RndgPrec := Currency."Amount Rounding Precision";
        exit(Round(UnroundedACYAmt, RndgPrec));
    end;
}

