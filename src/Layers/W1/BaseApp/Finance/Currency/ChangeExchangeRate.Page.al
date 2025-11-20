// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;

page 511 "Change Exchange Rate"
{
    Caption = 'Change Exchange Rate';
    DataCaptionExpression = DynamicDataCaption;
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrencyCode; CurrencyCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    Editable = CurrencyCodeEditable;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field(CurrentExchRate; CurrentExchRate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate Amount';
                    DecimalPlaces = 1 : 6;
                    Editable = CurrentExchRateEditable;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line. This field is used in combination with the Relational Exchange Rate Amount field.';

                    trigger OnValidate()
                    begin
                        if CurrentExchRate <= 0 then
                            Error(Text000);
                        if RefCurrencyCode = '' then
                            CurrencyFactor := CurrentExchRate / RefExchRate
                        else
                            CurrencyFactor := (CurrentExchRate * CurrentExchRate2) / (RefExchRate * RefExchRate2);
                    end;
                }
                field(RefExchRate; RefExchRate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Relational Exch. Rate Amount';
                    DecimalPlaces = 1 : 6;
                    Editable = RefExchRateEditable;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line. This field is used in combination with the Exchange Rate Amount field.';

                    trigger OnValidate()
                    begin
                        if RefExchRate <= 0 then
                            Error(Text000);
                        if RefCurrencyCode = '' then
                            CurrencyFactor := CurrentExchRate / RefExchRate
                        else
                            CurrencyFactor := (CurrentExchRate * CurrentExchRate2) / (RefExchRate * RefExchRate2);
                    end;
                }
                field(RefCurrencyCode; ShowCurrencyCode(RefCurrencyCode, true))
                {
                    ApplicationArea = Suite;
                    Caption = 'Relational Currency Code';
                    Editable = RefCurrencyCodeEditable;
                    ToolTip = 'Specifies how you want to set up the two currencies, one of the currencies can be LCY, for which you want to register exchange rates.';
                }
                field(CurrencyCode2; CurrencyCode2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    Editable = CurrencyCode2Editable;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field(CurrentExchRate2; CurrentExchRate2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate Amount';
                    DecimalPlaces = 1 : 6;
                    Editable = CurrentExchRate2Editable;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line. This field is used in combination with the Relational Exchange Rate Amount field.';

                    trigger OnValidate()
                    begin
                        if CurrentExchRate2 <= 0 then
                            Error(Text000);
                        CurrencyFactor := (CurrentExchRate * CurrentExchRate2) / (RefExchRate * RefExchRate2);
                    end;
                }
                field(RefExchRate2; RefExchRate2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Relational Exch. Rate Amount';
                    DecimalPlaces = 1 : 6;
                    Editable = RefExchRate2Editable;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line. This field is used in combination with the Exchange Rate Amount field.';

                    trigger OnValidate()
                    begin
                        if RefExchRate2 <= 0 then
                            Error(Text000);
                        CurrencyFactor := (CurrentExchRate * CurrentExchRate2) / (RefExchRate * RefExchRate2);
                    end;
                }
                field(RefCurrencyCode2; ShowCurrencyCode(RefCurrencyCode2, RefCurrencyCode <> ''))
                {
                    ApplicationArea = Suite;
                    Caption = 'Relational Currency Code';
                    Editable = RefCurrencyCode2Editable;
                    ToolTip = 'Specifies how you want to set up the two currencies, one of the currencies can be LCY, for which you want to register exchange rates.';
                }
                field(UseExchRate; UseExchRate)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Use FA Add.-Curr Exch. Rate';
                    Editable = UseExchRateEditable;
                    MultiLine = true;
                    ToolTip = 'Specifies the exchange rate of the additional reporting currency for a fixed asset, if you post in an additional reporting currency and use the Fixed Assets application area.';
                    Visible = true;

                    trigger OnValidate()
                    begin
                        if UseExchRate then begin
                            CurrencyCode3 := CurrencyCode4;
                            CurrencyFactor := CurrExchRate.ExchangeRate(Date2, CurrencyCode3);
                            InitForm();
                        end else begin
                            CurrencyCode := '';
                            CurrentExchRate := 0;
                            RefExchRate := 0;
                            RefCurrencyCode := '';
                            CurrencyCode2 := '';
                            CurrentExchRate2 := 0;
                            RefExchRate2 := 0;
                            RefCurrencyCode2 := '';
                            CurrentExchRateEditable := false;
                            RefExchRateEditable := false;
                            CurrentExchRate2Editable := false;
                            RefExchRate2Editable := false
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        RefExchRate2Editable := true;
        CurrentExchRate2Editable := true;
        RefExchRateEditable := true;
        CurrentExchRateEditable := true;
        GLSetup.Get();
    end;

    trigger OnOpenPage()
    begin
        InitForm();
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        CurrencyCode2: Code[10];
        CurrentExchRate: Decimal;
        CurrentExchRate2: Decimal;
        RefExchRate: Decimal;
        RefExchRate2: Decimal;
        RefCurrencyCode: Code[10];
        RefCurrencyCode2: Code[10];
        CurrencyCode3: Code[10];
        CurrencyFactor: Decimal;
        Fix: Enum "Fix Exch. Rate Amount Type";
        Fix2: Enum "Fix Exch. Rate Amount Type";
        UseExchRate: Boolean;
        DynamicDataCaption: Text[50];
        CurrencyCode4: Code[10];
        Date2: Date;
        Date3: Date;
        FAUsed: Boolean;
        CurrentExchRateEditable: Boolean;
        RefExchRateEditable: Boolean;
        CurrentExchRate2Editable: Boolean;
        RefExchRate2Editable: Boolean;
        UseExchRateEditable: Boolean;
        CurrencyCodeEditable: Boolean;
        RefCurrencyCodeEditable: Boolean;
        CurrencyCode2Editable: Boolean;
        RefCurrencyCode2Editable: Boolean;

#pragma warning disable AA0074
        Text000: Label 'The value must be greater than 0.';
        Text001: Label 'The %1 field is not set up properly in the Currency Exchange Rates window. For %2 or the currency set up in the %3 field, the %1 field should be set to both.', Comment = '%1 Caption for  "Fix Exchange Rate Amount" %2 a currencu code %3 Caption for "Relational Currency Code"';
#pragma warning restore AA0074

    protected var
        CurrencyCode: Code[10];

    procedure SetParameter(NewCurrencyCode: Code[10]; NewFactor: Decimal; Date: Date)
    begin
        CurrencyCode3 := NewCurrencyCode;
        CurrencyFactor := NewFactor;
        Date3 := Date;
        UseExchRate := false;
        FAUsed := false;
    end;

    procedure GetParameter(): Decimal
    begin
        if UseExchRate or not FAUsed then
            exit(CurrencyFactor);

        exit(0);
    end;

    procedure SetParameterFA(NewFactor: Decimal; CurrencyCode: Code[10]; Date: Date)
    begin
        if NewFactor = 0 then begin
            CurrencyFactor := 1;
            UseExchRate := false;
        end else begin
            CurrencyFactor := NewFactor;
            UseExchRate := true;
            CurrencyCode3 := CurrencyCode;
        end;
        UseExchRateEditable := true;
        FAUsed := true;
        CurrencyCode4 := CurrencyCode;
        Date2 := Date;
        Date3 := Date;
    end;

    procedure SetCaption(DataCaption: Text[50])
    begin
        DynamicDataCaption := DataCaption;
    end;

    procedure InitForm()
    begin
        if CurrencyCode3 = '' then begin
            CurrencyCodeEditable := false;
            CurrentExchRateEditable := false;
            RefExchRateEditable := false;
            RefCurrencyCodeEditable := false;
            CurrencyCode2Editable := false;
            CurrentExchRate2Editable := false;
            RefExchRate2Editable := false;
            RefCurrencyCode2Editable := false;
            exit;
        end;

        CurrExchRate.SetRange("Currency Code", CurrencyCode3);
        CurrExchRate.SetRange("Starting Date", 0D, Date3);
        CurrExchRate.FindLast();
        CurrencyCode := CurrExchRate."Currency Code";
        CurrentExchRate := CurrExchRate."Exchange Rate Amount";
        RefExchRate := CurrExchRate."Relational Exch. Rate Amount";
        RefCurrencyCode := CurrExchRate."Relational Currency Code";
        Fix := CurrExchRate."Fix Exchange Rate Amount";
        CurrExchRate.SetRange("Currency Code", RefCurrencyCode);
        CurrExchRate.SetRange("Starting Date", 0D, Date3);
        if CurrExchRate.FindLast() then begin
            CurrencyCode2 := CurrExchRate."Currency Code";
            CurrentExchRate2 := CurrExchRate."Exchange Rate Amount";
            RefExchRate2 := CurrExchRate."Relational Exch. Rate Amount";
            RefCurrencyCode2 := CurrExchRate."Relational Currency Code";
            Fix2 := CurrExchRate."Fix Exchange Rate Amount";
        end;

        case Fix of
            CurrExchRate."Fix Exchange Rate Amount"::Currency:
                begin
                    CurrentExchRateEditable := false;
                    RefExchRateEditable := true;
                    if RefCurrencyCode = '' then
                        RefExchRate := CurrentExchRate / CurrencyFactor
                    else
                        RefExchRate := (CurrentExchRate * CurrentExchRate2) / (CurrencyFactor * RefExchRate2);
                end;
            CurrExchRate."Fix Exchange Rate Amount"::"Relational Currency":
                begin
                    CurrentExchRateEditable := true;
                    RefExchRateEditable := false;
                    if RefCurrencyCode = '' then
                        CurrentExchRate := CurrencyFactor * RefExchRate
                    else
                        CurrentExchRate := (RefExchRate * RefExchRate2 * CurrencyFactor) / CurrentExchRate2;
                end;
            CurrExchRate."Fix Exchange Rate Amount"::Both:
                begin
                    CurrentExchRateEditable := false;
                    RefExchRateEditable := false;
                end;
        end;

        if RefCurrencyCode <> '' then begin
            if (Fix <> CurrExchRate."Fix Exchange Rate Amount"::Both) and (Fix2 <> CurrExchRate."Fix Exchange Rate Amount"::Both) then
                Error(Text001, CurrExchRate.FieldCaption(CurrExchRate."Fix Exchange Rate Amount"), CurrencyCode, CurrExchRate.FieldCaption(CurrExchRate."Relational Currency Code"));
            case Fix2 of
                CurrExchRate."Fix Exchange Rate Amount"::Currency:
                    begin
                        CurrentExchRate2Editable := false;
                        RefExchRate2Editable := true;
                        RefExchRate2 := (CurrentExchRate * CurrentExchRate2) / (CurrencyFactor * RefExchRate);
                    end;
                CurrExchRate."Fix Exchange Rate Amount"::"Relational Currency":
                    begin
                        CurrentExchRate2Editable := true;
                        RefExchRate2Editable := false;
                        CurrentExchRate2 := (CurrencyFactor * RefExchRate * RefExchRate2) / CurrentExchRate;
                    end;
                CurrExchRate."Fix Exchange Rate Amount"::Both:
                    begin
                        CurrentExchRate2Editable := false;
                        RefExchRate2Editable := false;
                    end;
            end;
        end else begin
            CurrencyCode2Editable := false;
            CurrentExchRate2Editable := false;
            RefExchRate2Editable := false;
            RefCurrencyCode2Editable := false;
            if CurrencyCode = '' then begin
                CurrencyCodeEditable := false;
                CurrentExchRateEditable := false;
                RefExchRateEditable := false;
                RefCurrencyCodeEditable := false;
            end;
        end;
    end;

    local procedure ShowCurrencyCode(ShowCurrency: Code[10]; DoShow: Boolean): Code[10]
    begin
        if not DoShow then
            exit('');
        if ShowCurrency = '' then
            exit(GLSetup."LCY Code");

        exit(ShowCurrency);
    end;
}

