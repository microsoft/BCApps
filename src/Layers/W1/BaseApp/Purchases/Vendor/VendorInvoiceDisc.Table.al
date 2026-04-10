// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.Currency;

table 24 "Vendor Invoice Disc."
{
    Caption = 'Vendor Invoice Disc.';
    LookupPageID = "Vend. Invoice Discounts";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the contents of the Invoice Disc. Code field on the vendor card.';
            NotBlank = true;
        }
        field(2; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            ToolTip = 'Specifies the minimum amount that the order must total for the discount to be granted or the service charge levied. For discounts, only purchase lines where the Allow Invoice Disc. field is selected are included in the calculation.';
            MinValue = 0;
        }
        field(3; "Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Discount %';
            ToolTip = 'Specifies the discount percentage that the vendor will grant if your company buys at least the amount in the Minimum Amount field.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Service Charge"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Service Charge';
            ToolTip = 'Specifies the amount of the service charge that the vendor will charge if your company purchases for at least the amount in the Minimum Amount field.';
            MinValue = 0;
        }
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

    procedure GetRec(NewCode: Code[20]; CurrencyCode: Code[10]; CurrencyDate: Date; BaseAmount: Decimal)
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
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
                    Currency.Get(CurrencyCode);
                    "Service Charge" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          CurrencyDate, CurrencyCode,
                          "Service Charge", CurrencyFactor),
                        Currency."Amount Rounding Precision");
                end;
            end else
                Init();
    end;
}

