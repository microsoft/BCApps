// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

table 330 "Currency Exchange Rate"
{
    Caption = 'Currency Exchange Rate';
    DataCaptionFields = "Currency Code";
    DrillDownPageID = "Currency Exchange Rates";
    LookupPageID = "Currency Exchange Rates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = "Relational Currency Code" then
                    Error(
                      Text000, FieldCaption("Currency Code"), FieldCaption("Relational Currency Code"));
            end;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(3; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                TestField("Exchange Rate Amount");
            end;
        }
        field(4; "Adjustment Exch. Rate Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Adjustment Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                TestField("Adjustment Exch. Rate Amount");
            end;
        }
        field(5; "Relational Currency Code"; Code[10])
        {
            Caption = 'Relational Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = "Relational Currency Code" then
                    Error(
                      Text000, FieldCaption("Currency Code"), FieldCaption("Relational Currency Code"));
            end;
        }
        field(6; "Relational Exch. Rate Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Relational Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                TestField("Relational Exch. Rate Amount");
            end;
        }
        field(7; "Fix Exchange Rate Amount"; Enum "Fix Exch. Rate Amount Type")
        {
            Caption = 'Fix Exchange Rate Amount';
        }
        field(8; "Relational Adjmt Exch Rate Amt"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Relational Adjmt Exch Rate Amt';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                TestField("Relational Adjmt Exch Rate Amt");
            end;
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CurrencyExchRate2: array[2] of Record "Currency Exchange Rate";
        CurrencyExchRate3: array[3] of Record "Currency Exchange Rate";
        RelExchangeRateAmt: Decimal;
        ExchangeRateAmt: Decimal;
        RelCurrencyCode: Code[10];
        FixExchangeRateAmt: Enum "Fix Exch. Rate Amount Type";
        CurrencyFactor: Decimal;
        UseAdjmtAmounts: Boolean;
        CurrencyCode2: array[2] of Code[10];
        Date2: array[2] of Date;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The currency code in the %1 field and the %2 field cannot be the same.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ExchangeAmtLCYToFCY(Date: Date; CurrencyCode: Code[10]; Amount: Decimal; Factor: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(Amount);
        FindCurrency(Date, CurrencyCode, 1);
        TestField("Exchange Rate Amount");
        TestField("Relational Exch. Rate Amount");
        if "Relational Currency Code" = '' then
            if "Fix Exchange Rate Amount" = "Fix Exchange Rate Amount"::Both then
                Amount := (Amount / "Relational Exch. Rate Amount") * "Exchange Rate Amount"
            else
                Amount := Amount * Factor
        else begin
            RelExchangeRateAmt := "Relational Exch. Rate Amount";
            ExchangeRateAmt := "Exchange Rate Amount";
            RelCurrencyCode := "Relational Currency Code";
            FixExchangeRateAmt := "Fix Exchange Rate Amount";
            FindCurrency(Date, RelCurrencyCode, 2);
            TestField("Exchange Rate Amount");
            TestField("Relational Exch. Rate Amount");
            case FixExchangeRateAmt of
                "Fix Exchange Rate Amount"::"Relational Currency":
                    ExchangeRateAmt :=
                      (Factor * RelExchangeRateAmt * "Relational Exch. Rate Amount") /
                      "Exchange Rate Amount";
                "Fix Exchange Rate Amount"::Currency:
                    RelExchangeRateAmt :=
                      (ExchangeRateAmt * "Exchange Rate Amount") /
                      (Factor * "Relational Exch. Rate Amount");
                "Fix Exchange Rate Amount"::Both:
                    case "Fix Exchange Rate Amount" of
                        "Fix Exchange Rate Amount"::"Relational Currency":
                            "Exchange Rate Amount" :=
                              (Factor * RelExchangeRateAmt * "Relational Exch. Rate Amount") /
                              ExchangeRateAmt;
                        "Fix Exchange Rate Amount"::Currency:
                            "Relational Exch. Rate Amount" :=
                              (ExchangeRateAmt * "Exchange Rate Amount") /
                              (Factor * RelExchangeRateAmt);
                    end;
            end;
            Amount := (Amount / RelExchangeRateAmt) * ExchangeRateAmt;
            Amount := (Amount / "Relational Exch. Rate Amount") * "Exchange Rate Amount";
        end;
        exit(Amount);
    end;

    procedure ExchangeAmtFCYToLCY(Date: Date; CurrencyCode: Code[10]; Amount: Decimal; Factor: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(Amount);
        FindCurrency(Date, CurrencyCode, 1);
        if not UseAdjmtAmounts then begin
            TestField("Exchange Rate Amount");
            TestField("Relational Exch. Rate Amount");
        end else begin
            TestField("Adjustment Exch. Rate Amount");
            TestField("Relational Adjmt Exch Rate Amt");
            "Exchange Rate Amount" := "Adjustment Exch. Rate Amount";
            "Relational Exch. Rate Amount" := "Relational Adjmt Exch Rate Amt";
            OnExchangeAmtFCYToLCYOnAfterSetRelationalExchRateAmount(Rec);
        end;
        if "Relational Currency Code" = '' then
            if "Fix Exchange Rate Amount" = "Fix Exchange Rate Amount"::Both then
                Amount := (Amount / "Exchange Rate Amount") * "Relational Exch. Rate Amount"
            else
                Amount := Amount / Factor
        else begin
            RelExchangeRateAmt := "Relational Exch. Rate Amount";
            ExchangeRateAmt := "Exchange Rate Amount";
            RelCurrencyCode := "Relational Currency Code";
            FixExchangeRateAmt := "Fix Exchange Rate Amount";
            FindCurrency(Date, RelCurrencyCode, 2);
            if not UseAdjmtAmounts then begin
                TestField("Exchange Rate Amount");
                TestField("Relational Exch. Rate Amount");
            end else begin
                TestField("Adjustment Exch. Rate Amount");
                TestField("Relational Adjmt Exch Rate Amt");
                "Exchange Rate Amount" := "Adjustment Exch. Rate Amount";
                "Relational Exch. Rate Amount" := "Relational Adjmt Exch Rate Amt";
                OnExchangeAmtFCYToLCYOnAfterSetRelationalExchRateAmount(Rec);
            end;
            case FixExchangeRateAmt of
                "Fix Exchange Rate Amount"::"Relational Currency":
                    ExchangeRateAmt :=
                      (RelExchangeRateAmt * "Relational Exch. Rate Amount") /
                      ("Exchange Rate Amount" * Factor);
                "Fix Exchange Rate Amount"::Currency:
                    RelExchangeRateAmt :=
                      ((Factor * ExchangeRateAmt * "Exchange Rate Amount") /
                       "Relational Exch. Rate Amount");
                "Fix Exchange Rate Amount"::Both:
                    case "Fix Exchange Rate Amount" of
                        "Fix Exchange Rate Amount"::"Relational Currency":
                            "Exchange Rate Amount" :=
                              (RelExchangeRateAmt * "Relational Exch. Rate Amount") /
                              (ExchangeRateAmt * Factor);
                        "Fix Exchange Rate Amount"::Currency:
                            "Relational Exch. Rate Amount" :=
                              ((Factor * ExchangeRateAmt * "Exchange Rate Amount") /
                               RelExchangeRateAmt);
                        "Fix Exchange Rate Amount"::Both:
                            begin
                                Amount := (Amount / ExchangeRateAmt) * RelExchangeRateAmt;
                                Amount := (Amount / "Exchange Rate Amount") * "Relational Exch. Rate Amount";
                                exit(Amount);
                            end;
                    end;
            end;
            Amount := (Amount / RelExchangeRateAmt) * ExchangeRateAmt;
            Amount := (Amount / "Relational Exch. Rate Amount") * "Exchange Rate Amount";
        end;
        exit(Amount);
    end;

    procedure ExchangeRate(Date: Date; CurrencyCode: Code[10]): Decimal
    begin
        if CurrencyCode = '' then
            exit(1);
        FindCurrency(Date, CurrencyCode, 1);
        if not UseAdjmtAmounts then begin
            TestField("Exchange Rate Amount");
            TestField("Relational Exch. Rate Amount");
        end else begin
            TestField("Adjustment Exch. Rate Amount");
            TestField("Relational Adjmt Exch Rate Amt");
            "Exchange Rate Amount" := "Adjustment Exch. Rate Amount";
            "Relational Exch. Rate Amount" := "Relational Adjmt Exch Rate Amt";
            OnExchangeRateOnAfterSetRelationalExchRateAmount(Rec);
        end;
        RelExchangeRateAmt := "Relational Exch. Rate Amount";
        ExchangeRateAmt := "Exchange Rate Amount";
        RelCurrencyCode := "Relational Currency Code";
        if "Relational Currency Code" = '' then
            CurrencyFactor := "Exchange Rate Amount" / "Relational Exch. Rate Amount"
        else begin
            FindCurrency(Date, RelCurrencyCode, 2);
            if not UseAdjmtAmounts then begin
                TestField("Exchange Rate Amount");
                TestField("Relational Exch. Rate Amount");
            end else begin
                TestField("Adjustment Exch. Rate Amount");
                TestField("Relational Adjmt Exch Rate Amt");
                "Exchange Rate Amount" := "Adjustment Exch. Rate Amount";
                "Relational Exch. Rate Amount" := "Relational Adjmt Exch Rate Amt";
                OnExchangeRateOnAfterSetRelationalExchRateAmount(Rec);
            end;
            CurrencyFactor := (ExchangeRateAmt * "Exchange Rate Amount") / (RelExchangeRateAmt * "Relational Exch. Rate Amount");
        end;
        exit(CurrencyFactor);
    end;

    procedure ExchangeAmtLCYToFCYOnlyFactor(Amount: Decimal; Factor: Decimal): Decimal
    begin
        Amount := Factor * Amount;
        exit(Amount);
    end;

    procedure ExchangeAmtFCYToLCYAdjmt(Date: Date; CurrencyCode: Code[10]; Amount: Decimal; Factor: Decimal): Decimal
    begin
        UseAdjmtAmounts := true;
        exit(ExchangeAmtFCYToLCY(Date, CurrencyCode, Amount, Factor));
    end;

    procedure ExchangeRateAdjmt(Date: Date; CurrencyCode: Code[10]): Decimal
    begin
        UseAdjmtAmounts := true;
        exit(ExchangeRate(Date, CurrencyCode));
    end;

    procedure ExchangeAmount(Amount: Decimal; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; UsePostingDate: Date): Decimal
    var
        ToCurrency: Record Currency;
    begin
        if (FromCurrencyCode = ToCurrencyCode) or (Amount = 0) then
            exit(Amount);

        Amount :=
          ExchangeAmtFCYToFCY(
            UsePostingDate, FromCurrencyCode, ToCurrencyCode, Amount);

        if ToCurrencyCode <> '' then begin
            ToCurrency.Get(ToCurrencyCode);
            Amount := Round(Amount, ToCurrency."Amount Rounding Precision");
        end else
            Amount := Round(Amount);

        exit(Amount);
    end;

    procedure FindCurrency(Date: Date; CurrencyCode: Code[10]; CacheNo: Integer)
    var
        ShouldUseCache: Boolean;
    begin
        ShouldUseCache := (CurrencyCode2[CacheNo] = CurrencyCode) and (Date2[CacheNo] = Date);
        OnFindCurrencyOnAfterCalcShouldUseCache(Rec, CacheNo, ShouldUseCache);
        if ShouldUseCache then
            Rec := CurrencyExchRate2[CacheNo]
        else begin
            if Date = 0D then
                Date := WorkDate();
            CurrencyExchRate2[CacheNo].SetRange("Currency Code", CurrencyCode);
            CurrencyExchRate2[CacheNo].SetRange("Starting Date", 0D, Date);
            OnFindCurrencyOnAfterCurrencyExchRate2SetFilters(CurrencyExchRate2[CacheNo], CurrencyCode, Date, Rec);
            CurrencyExchRate2[CacheNo].FindLast();
            Rec := CurrencyExchRate2[CacheNo];
            CurrencyCode2[CacheNo] := CurrencyCode;
            Date2[CacheNo] := Date;
        end;
        OnAfterFindCurrency(Rec, CurrencyExchRate2, Date, CurrencyCode, CacheNo);
    end;

    procedure ExchangeAmtFCYToFCY(Date: Date; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; Amount: Decimal): Decimal
    begin
        if FromCurrencyCode = ToCurrencyCode then
            exit(Amount);
        if ToCurrencyCode = '' then begin
            FindCurrency2(Date, FromCurrencyCode, 1);
            if CurrencyExchRate3[1]."Relational Currency Code" = '' then
                exit(
                  (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
                  CurrencyExchRate3[1]."Relational Exch. Rate Amount");

            FindCurrency2(Date, CurrencyExchRate3[1]."Relational Currency Code", 3);
            Amount :=
              ((Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
               CurrencyExchRate3[1]."Relational Exch. Rate Amount");
            exit(
              (Amount / CurrencyExchRate3[3]."Exchange Rate Amount") *
              CurrencyExchRate3[3]."Relational Exch. Rate Amount");
        end;
        if FromCurrencyCode = '' then begin
            FindCurrency2(Date, ToCurrencyCode, 2);
            if CurrencyExchRate3[2]."Relational Currency Code" = '' then
                exit(
                  (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
                  CurrencyExchRate3[2]."Exchange Rate Amount");

            FindCurrency2(Date, CurrencyExchRate3[2]."Relational Currency Code", 3);
            Amount :=
              ((Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
               CurrencyExchRate3[2]."Exchange Rate Amount");
            exit(
              (Amount / CurrencyExchRate3[3]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[3]."Exchange Rate Amount");
        end;
        FindCurrency2(Date, FromCurrencyCode, 1);
        FindCurrency2(Date, ToCurrencyCode, 2);
        if CurrencyExchRate3[1]."Currency Code" = CurrencyExchRate3[2]."Relational Currency Code" then
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        if CurrencyExchRate3[1]."Relational Currency Code" = CurrencyExchRate3[2]."Currency Code" then
            exit(
              (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
              CurrencyExchRate3[1]."Relational Exch. Rate Amount");

        if CurrencyExchRate3[1]."Relational Currency Code" = CurrencyExchRate3[2]."Relational Currency Code" then begin
            Amount :=
              ((Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
               CurrencyExchRate3[1]."Relational Exch. Rate Amount");
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
        if (CurrencyExchRate3[1]."Relational Currency Code" = '') and
           (CurrencyExchRate3[2]."Relational Currency Code" <> '')
        then begin
            FindCurrency2(Date, CurrencyExchRate3[2]."Relational Currency Code", 3);
            Amount :=
              (Amount * CurrencyExchRate3[1]."Relational Exch. Rate Amount") /
              CurrencyExchRate3[1]."Exchange Rate Amount";
            Amount :=
              (Amount / CurrencyExchRate3[3]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[3]."Exchange Rate Amount";
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
        if (CurrencyExchRate3[1]."Relational Currency Code" <> '') and
           (CurrencyExchRate3[2]."Relational Currency Code" = '')
        then begin
            FindCurrency2(Date, CurrencyExchRate3[1]."Relational Currency Code", 3);
            Amount :=
              (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
              CurrencyExchRate3[1]."Relational Exch. Rate Amount";
            Amount :=
              (Amount / CurrencyExchRate3[3]."Exchange Rate Amount") *
              CurrencyExchRate3[3]."Relational Exch. Rate Amount";
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
    end;

    local procedure FindCurrency2(Date: Date; CurrencyCode: Code[10]; Number: Integer)
    begin
        if Date = 0D then
            Date := WorkDate();
        CurrencyExchRate3[Number].SetRange("Currency Code", CurrencyCode);
        CurrencyExchRate3[Number].SetRange("Starting Date", 0D, Date);
        OnFindCurrency2OnAfterCurrencyExchRate3SetFilters(CurrencyExchRate3[Number], CurrencyCode, Date, Rec);
        CurrencyExchRate3[Number].FindLast();
        CurrencyExchRate3[Number].TestField("Exchange Rate Amount");
        CurrencyExchRate3[Number].TestField("Relational Exch. Rate Amount");
    end;

    procedure ApplnExchangeAmtFCYToFCY(Date: Date; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; Amount: Decimal; var ExchRateFound: Boolean): Decimal
    begin
        if FromCurrencyCode = ToCurrencyCode then
            exit(Amount);
        if ToCurrencyCode = '' then begin
            ExchRateFound := FindApplnCurrency(Date, FromCurrencyCode, 1);
            if not ExchRateFound then
                exit(0);

            if CurrencyExchRate3[1]."Relational Currency Code" = '' then
                exit(
                  (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
                  CurrencyExchRate3[1]."Relational Exch. Rate Amount");

            ExchRateFound := FindApplnCurrency(Date, CurrencyExchRate3[1]."Relational Currency Code", 3);
            if not ExchRateFound then
                exit(0);

            Amount :=
              (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
              CurrencyExchRate3[1]."Relational Exch. Rate Amount";
            exit(
              (Amount / CurrencyExchRate3[3]."Exchange Rate Amount") *
              CurrencyExchRate3[3]."Relational Exch. Rate Amount");
        end;
        if FromCurrencyCode = '' then begin
            ExchRateFound := FindApplnCurrency(Date, ToCurrencyCode, 2);
            if not ExchRateFound then
                exit(0);

            if CurrencyExchRate3[2]."Relational Currency Code" = '' then
                exit(
                  (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
                  CurrencyExchRate3[2]."Exchange Rate Amount");

            ExchRateFound := FindApplnCurrency(Date, CurrencyExchRate3[2]."Relational Currency Code", 3);
            if not ExchRateFound then
                exit(0);

            Amount :=
              ((Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
               CurrencyExchRate3[2]."Exchange Rate Amount");
            exit(
              (Amount / CurrencyExchRate3[3]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[3]."Exchange Rate Amount");
        end;
        ExchRateFound := FindApplnCurrency(Date, FromCurrencyCode, 1);
        if not ExchRateFound then
            exit(0);

        ExchRateFound := FindApplnCurrency(Date, ToCurrencyCode, 2);
        if not ExchRateFound then
            exit(0);

        if CurrencyExchRate3[1]."Currency Code" = CurrencyExchRate3[2]."Relational Currency Code" then
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        if CurrencyExchRate3[1]."Relational Currency Code" = CurrencyExchRate3[2]."Currency Code" then
            exit(
              (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
              CurrencyExchRate3[1]."Relational Exch. Rate Amount");

        if CurrencyExchRate3[1]."Relational Currency Code" = CurrencyExchRate3[2]."Relational Currency Code" then begin
            Amount :=
              ((Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
               CurrencyExchRate3[1]."Relational Exch. Rate Amount");
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
        if (CurrencyExchRate3[1]."Relational Currency Code" = '') and
           (CurrencyExchRate3[2]."Relational Currency Code" <> '')
        then begin
            ExchRateFound := FindApplnCurrency(Date, CurrencyExchRate3[2]."Relational Currency Code", 3);
            if not ExchRateFound then
                exit(0);

            Amount :=
              (Amount * CurrencyExchRate3[1]."Relational Exch. Rate Amount") /
              CurrencyExchRate3[1]."Exchange Rate Amount";
            Amount :=
              (Amount / CurrencyExchRate3[3]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[3]."Exchange Rate Amount";
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
        if (CurrencyExchRate3[1]."Relational Currency Code" <> '') and
           (CurrencyExchRate3[2]."Relational Currency Code" = '')
        then begin
            ExchRateFound := FindApplnCurrency(Date, CurrencyExchRate3[1]."Relational Currency Code", 3);
            if not ExchRateFound then
                exit(0);

            Amount :=
              (Amount / CurrencyExchRate3[1]."Exchange Rate Amount") *
              CurrencyExchRate3[1]."Relational Exch. Rate Amount";
            Amount :=
              (Amount / CurrencyExchRate3[3]."Exchange Rate Amount") *
              CurrencyExchRate3[3]."Relational Exch. Rate Amount";
            exit(
              (Amount / CurrencyExchRate3[2]."Relational Exch. Rate Amount") *
              CurrencyExchRate3[2]."Exchange Rate Amount");
        end;
    end;

    local procedure FindApplnCurrency(Date: Date; CurrencyCode: Code[10]; Number: Integer): Boolean
    begin
        CurrencyExchRate3[Number].SetRange("Currency Code", CurrencyCode);
        CurrencyExchRate3[Number].SetRange("Starting Date", 0D, Date);
        if not CurrencyExchRate3[Number].FindLast() then
            exit(false);

        CurrencyExchRate3[Number].TestField("Exchange Rate Amount");
        CurrencyExchRate3[Number].TestField("Relational Exch. Rate Amount");
        exit(true);
    end;

    procedure GetCurrentCurrencyFactor(CurrencyCode: Code[10]): Decimal
    begin
        SetRange("Currency Code", CurrencyCode);
        if FindLast() then
            if "Relational Exch. Rate Amount" <> 0 then
                exit("Exchange Rate Amount" / "Relational Exch. Rate Amount");
    end;

    procedure GetLastestExchangeRate(CurrencyCode: Code[10]; var Date: Date; var Amt: Decimal)
    begin
        Date := 0D;
        Amt := 0;
        SetRange("Currency Code", CurrencyCode);
        if FindLast() then begin
            Date := "Starting Date";
            if "Exchange Rate Amount" <> 0 then
                Amt := "Relational Exch. Rate Amount" / "Exchange Rate Amount";
        end;
    end;

    procedure CurrencyExchangeRateExist(CurrencyCode: Code[10]; Date: Date): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", 0D, Date);
        exit(not CurrencyExchangeRate.IsEmpty);
    end;

    procedure SetCurrentCurrencyFactor(CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    var
        RateForTodayExists: Boolean;
    begin
        "Currency Code" := CurrencyCode;
        TestField("Currency Code");
        RateForTodayExists := Get(CurrencyCode, Today);
        "Exchange Rate Amount" := 1;
        "Relational Exch. Rate Amount" := 1 / CurrencyFactor;
        "Adjustment Exch. Rate Amount" := "Exchange Rate Amount";
        "Relational Adjmt Exch Rate Amt" := "Relational Exch. Rate Amount";
        if RateForTodayExists then begin
            "Relational Currency Code" := '';
            Modify();
        end else begin
            "Starting Date" := Today;
            Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindCurrency(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var CurrencyExchangeRateArray: array[2] of Record "Currency Exchange Rate"; Date: Date; CurrencyCode: Code[10]; CacheNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExchangeAmtFCYToLCYOnAfterSetRelationalExchRateAmount(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCurrencyOnAfterCalcShouldUseCache(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CacheNo: Integer; var ShouldUseCache: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCurrencyOnAfterCurrencyExchRate2SetFilters(var CurrencyExchRate2: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; Date: Date; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExchangeRateOnAfterSetRelationalExchRateAmount(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCurrency2OnAfterCurrencyExchRate3SetFilters(var CurrencyExchRate3: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; Date: Date; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;
}
