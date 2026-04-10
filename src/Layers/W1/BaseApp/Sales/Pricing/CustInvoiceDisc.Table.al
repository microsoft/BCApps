// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Finance.Currency;

/// <summary>
/// Stores customer invoice discount terms including minimum amounts, discount percentages, and service charges by currency.
/// </summary>
table 19 "Cust. Invoice Disc."
{
    Caption = 'Cust. Invoice Disc.';
    LookupPageID = "Cust. Invoice Discounts";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number or customer discount group code that the invoice discount applies to.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the contents of the Invoice Disc. Code field on the customer card.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the minimum invoice amount required to qualify for the invoice discount.
        /// </summary>
        field(2; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            ToolTip = 'Specifies the minimum amount that the invoice must total for the discount to be granted or the service charge levied. For discounts, only sales lines where the Allow Invoice Disc. field is selected are included in the calculation.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the discount percentage applied to the invoice when the minimum amount is met.
        /// </summary>
        field(3; "Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Discount %';
            ToolTip = 'Specifies the discount percentage that the customer can receive by buying for at least the minimum amount.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies a service charge amount added to the invoice when the invoice discount is applied.
        /// </summary>
        field(4; "Service Charge"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Service Charge';
            ToolTip = 'Specifies the amount of the service charge that the customer will have to pay on a purchase of at least the amount in the Minimum Amount field.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the currency code for the minimum amount and service charge. A blank value indicates the local currency.
        /// </summary>
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code for invoice discount terms.';
            TableRelation = Currency;
        }
    }

    keys
    {
        key(Key1; "Code", "Currency Code", "Minimum Amount")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN27
    [Obsolete('Replaced by W1 procedure GetRecord()', '27.0')]
    /// <summary>
    /// Gets the customer invoice discount record based on the specified criteria.
    /// </summary>
    /// <param name="NewCode">The customer invoice discount code.</param>
    /// <param name="CurrencyCode">The currency code.</param>
    /// <param name="CurrencyDate">The date for currency conversion.</param>
    /// <param name="BaseAmount">The base amount to find the applicable discount.</param>
    procedure GetRec(NewCode: Code[20]; CurrencyCode: Code[10]; CurrencyDate: Date; BaseAmount: Decimal)
    begin
        GetRecord(NewCode, CurrencyCode, CurrencyDate, BaseAmount);
    end;
#endif

    /// <summary>
    /// Gets the customer invoice discount record based on the specified criteria, handling currency conversion if needed.
    /// </summary>
    /// <param name="NewCode">The customer invoice discount code.</param>
    /// <param name="CurrencyCode">The currency code.</param>
    /// <param name="CurrencyDate">The date for currency conversion.</param>
    /// <param name="BaseAmount">The base amount to find the applicable discount.</param>
    /// <returns>True if a customer invoice discount record was found, otherwise false.</returns>
    procedure GetRecord(NewCode: Code[20]; CurrencyCode: Code[10]; CurrencyDate: Date; BaseAmount: Decimal) CustInvDiscFound: Boolean
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        OnBeforeGetRec(Rec, NewCode, CurrencyCode, CurrencyDate, BaseAmount);

        SetRange(Code, NewCode);
        SetRange("Currency Code", CurrencyCode);
        SetRange("Minimum Amount", 0, BaseAmount);
        if not Find('+') then
            if CurrencyCode <> '' then begin
                CurrencyFactor := CurrExchRate.ExchangeRate(CurrencyDate, CurrencyCode);
                SetRange("Currency Code", '');
                SetRange(
                  "Minimum Amount", 0,
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    CurrencyDate, CurrencyCode,
                    BaseAmount, CurrencyFactor));
                if not Find('+') then
                    Init()
                else begin
                    CustInvDiscFound := true;
                    Currency.Get(CurrencyCode);
                    "Service Charge" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          CurrencyDate, CurrencyCode,
                          "Service Charge", CurrencyFactor),
                        Currency."Amount Rounding Precision");
                end;
            end else
                Init()
        else
            CustInvDiscFound := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRec(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var NewCode: Code[20]; var CurrencyCode: Code[10]; var CurrencyDate: Date; var BaseAmount: Decimal)
    begin
    end;
}

