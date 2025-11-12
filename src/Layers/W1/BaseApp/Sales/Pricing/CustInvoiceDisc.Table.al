// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Finance.Currency;

table 19 "Cust. Invoice Disc."
{
    Caption = 'Cust. Invoice Disc.';
    LookupPageID = "Cust. Invoice Discounts";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
        }
        field(3; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Service Charge"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Service Charge';
            MinValue = 0;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
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
    procedure GetRec(NewCode: Code[20]; CurrencyCode: Code[10]; CurrencyDate: Date; BaseAmount: Decimal)
    begin
        GetRecord(NewCode, CurrencyCode, CurrencyDate, BaseAmount);
    end;
#endif

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

