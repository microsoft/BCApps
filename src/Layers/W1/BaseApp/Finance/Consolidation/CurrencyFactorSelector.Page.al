// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

page 153 "Currency Factor Selector"
{
    PageType = Card;
    layout
    {
        area(Content)
        {
            field(ExchangeRateAmount; ExchangeRateAmount)
            {
                ApplicationArea = All;
                CaptionClass = ExchangeRateAmountCaption;
                DecimalPlaces = 0 : 15;
                ToolTip = 'Specifies the exchange rate amount in the consolidation currency.';
                trigger OnValidate()
                begin
                    if ExchangeRateAmount = 0 then
                        Error(SpecifiedAmountNonZeroErr);
                end;
            }
            field(RelationalExchangeRateAmount; RelationalExchangeRateAmount)
            {
                ApplicationArea = All;
                CaptionClass = RelationalExchangeRateAmountCaption;
                DecimalPlaces = 0 : 15;
                ToolTip = 'Specifies the exchange rate amount in the currency of the business unit.';
                trigger OnValidate()
                begin
                    if RelationalExchangeRateAmount = 0 then
                        Error(SpecifiedAmountNonZeroErr);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExchangeRateAmountCaption := ExchangeRateAmountLbl;
        if ConsolidationCurrencyCode <> '' then
            ExchangeRateAmountCaption := ExchangeRateAmountCaption + ' (' + ConsolidationCurrencyCode + ')';
        RelationalExchangeRateAmountCaption := RelationalExchangeRateAmountLbl;
        if BusinessUnitCurrencyCode <> '' then
            RelationalExchangeRateAmountCaption := RelationalExchangeRateAmountCaption + ' (' + BusinessUnitCurrencyCode + ')';
    end;

    internal procedure GetCurrencyFactor(): Decimal
    begin
        exit(RelationalExchangeRateAmount / ExchangeRateAmount);
    end;

    internal procedure SetCurrencyFactor(Factor: Decimal)
    begin
        if Factor = 0 then
            Error(SpecifiedAmountNonZeroErr);
        ExchangeRateAmount := 100 / Factor;
        RelationalExchangeRateAmount := 100;
    end;

    internal procedure SetConsolidationCurrencyCode(CurrencyCode: Code[10])
    begin
        ConsolidationCurrencyCode := CurrencyCode;
    end;

    internal procedure SetBusinessUnitCurrencyCode(CurrencyCode: Code[10])
    begin
        BusinessUnitCurrencyCode := CurrencyCode;
    end;

    var
        ExchangeRateAmount, RelationalExchangeRateAmount : Decimal;
        ExchangeRateAmountCaption, RelationalExchangeRateAmountCaption : Text;
        ConsolidationCurrencyCode, BusinessUnitCurrencyCode : Code[10];
        ExchangeRateAmountLbl: Label 'Exchange Rate Amount';
        RelationalExchangeRateAmountLbl: Label 'Relational Exchange Rate Amount';
        SpecifiedAmountNonZeroErr: Label 'The exchange rate amount must be different than zero.';
}
