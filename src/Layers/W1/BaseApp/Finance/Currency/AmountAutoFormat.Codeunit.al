// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 347 "Amount Auto Format"
{
    Permissions = tabledata "General Ledger Setup" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        GLSetupRead: Boolean;
        CurrencyCodeFormatPrefixTxt: Label '<C,%1>', Locked = true;
        CurrencySymbolPrefixTxt: Label '%1 ', Locked = true;
        CurrencySymbolPostFixTxt: Label ' %1', Locked = true;
        PrecisionFormatTxt: Label '<Precision,%1><Standard Format,0>', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTypes(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        if Resolved then
            exit;

        if not GetGLSetup() then
            exit;

        Resolved := true;
        case AutoFormatType of
            AutoFormatType::AmountFormat:
                Result := GetAmountFormat(AutoFormatExpr, GeneralLedgerSetup."Show Currency");
            AutoFormatType::UnitAmountFormat:
                Result := GetUnitAmountFormat(AutoFormatExpr, GeneralLedgerSetup."Show Currency");
            AutoFormatType::AmountFormatNoSymbol:
                Result := GetAmountFormat(AutoFormatExpr, enum::"Show Currency"::Never);
            AutoFormatType::UnitAmountFormatNoSymbol:
                Result := GetUnitAmountFormat(AutoFormatExpr, enum::"Show Currency"::Never);
            AutoFormatType::CurrencySymbolFormat:
                Result := GetCustomFormat(AutoFormatExpr, enum::"Show Currency"::"LCY and FCY Symbol");
            else
                Resolved := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnReadRounding', '', false, false)]
    local procedure ReadRounding(var AmountRoundingPrecision: Decimal)
    begin
        GetGLSetup();
        AmountRoundingPrecision := GeneralLedgerSetup."Amount Rounding Precision";
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResetGlobalsOnGLSetupDelete()
    begin
        ClearGlobals();
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure ResetGlobalsOnGLSetupInsert()
    begin
        ClearGlobals();
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGlobalsOnGLSetupModify()
    begin
        ClearGlobals();
    end;

    [EventSubscriber(ObjectType::Table, Database::Currency, 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResetGlobalsOnCurrencyDelete()
    begin
        ClearGlobals();
    end;

    [EventSubscriber(ObjectType::Table, Database::Currency, 'OnAfterInsertEvent', '', false, false)]
    local procedure ResetGlobalsOnCurrencyInsert()
    begin
        ClearGlobals();
    end;

    [EventSubscriber(ObjectType::Table, Database::Currency, 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGlobalsOnCurrencyModify()
    begin
        ClearGlobals();
    end;

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GeneralLedgerSetup.Get();
        exit(GLSetupRead);
    end;

    local procedure GetAmountFormat(AutoFormatExpr: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        if AutoFormatExpr = '' then // LCY
            exit(GetLCYAmountFormat('', ShowCurrency));
        if GetCurrency(CopyStr(AutoFormatExpr, 1, 10)) then // FCY
            exit(GetFCYAmountFormat('', ShowCurrency));
        // Default
        exit(StrSubstNo(PrecisionFormatTxt, GeneralLedgerSetup."Amount Decimal Places"));
    end;

    local procedure GetUnitAmountFormat(AutoFormatExpr: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        if AutoFormatExpr = '' then // LCY
            exit(GetLCYUnitAmountFormat('', ShowCurrency));
        if GetCurrency(CopyStr(AutoFormatExpr, 1, 10)) then // FCY
            exit(GetFCYUnitAmountFormat('', ShowCurrency));
        // Default
        exit(StrSubstNo(PrecisionFormatTxt, GeneralLedgerSetup."Unit-Amount Decimal Places"));
    end;

    local procedure GetLCYAmountFormat(AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        exit(GetLCYFormat(GeneralLedgerSetup."Amount Decimal Places", AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetLCYUnitAmountFormat(AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        exit(GetLCYFormat(GeneralLedgerSetup."Unit-Amount Decimal Places", AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetLCYFormat(DecimalPlaces: Text[5]; AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency") AutoFormatExpression: Text[80]
    begin
        AutoFormatExpression := StrSubstNo(PrecisionFormatTxt, DecimalPlaces);

        case ShowCurrency of
            enum::"Show Currency"::Never, enum::"Show Currency"::"FCY Symbol Only", enum::"Show Currency"::"FCY Currency Code Only":
                ;
            enum::"Show Currency"::"LCY and FCY Symbol":
                AddCurrencySymbol(AutoFormatExpression, GeneralLedgerSetup.GetCurrencySymbol(), GeneralLedgerSetup."Currency Symbol Position");
            enum::"Show Currency"::"LCY and FCY Currency Code":
                AddCurrencySymbol(AutoFormatExpression, GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Currency Symbol Position");
        end;

        PrefixCurrencyCodeFormatString(AutoFormatExpression, GeneralLedgerSetup."LCY Code", AutoFormatPrefixedText);
    end;

    local procedure GetFCYAmountFormat(AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        exit(GetFCYFormat(Currency."Amount Decimal Places", AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetFCYUnitAmountFormat(AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        exit(GetFCYFormat(Currency."Unit-Amount Decimal Places", AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetFCYFormat(DecimalPlaces: Text[5]; AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency") AutoFormatExpression: Text[80]
    begin
        AutoFormatExpression := StrSubstNo(PrecisionFormatTxt, DecimalPlaces);

        case ShowCurrency of
            enum::"Show Currency"::Never:
                ;
            enum::"Show Currency"::"FCY Symbol Only", enum::"Show Currency"::"LCY and FCY Symbol":
                AddCurrencySymbol(AutoFormatExpression, Currency.GetCurrencySymbol(), Currency."Currency Symbol Position");
            enum::"Show Currency"::"FCY Currency Code Only", enum::"Show Currency"::"LCY and FCY Currency Code":
                AddCurrencySymbol(AutoFormatExpression, Currency."ISO Code", Currency."Currency Symbol Position");
        end;

        PrefixCurrencyCodeFormatString(AutoFormatExpression, Currency."ISO Code", AutoFormatPrefixedText);
    end;

    local procedure AddCurrencySymbol(var AutoFormatExpression: Text[80]; CurrencySymbol: Text[10]; SymbolPosition: Enum "Currency Symbol Position")
    begin
        case SymbolPosition of
            enum::"Currency Symbol Position"::"Before Amount":
                AutoFormatExpression := StrSubstNo(CurrencySymbolPrefixTxt, CurrencySymbol) + AutoFormatExpression;
            enum::"Currency Symbol Position"::"After Amount":
                AutoFormatExpression := AutoFormatExpression + StrSubstNo(CurrencySymbolPostfixTxt, CurrencySymbol);
        end;
    end;

    local procedure PrefixCurrencyCodeFormatString(var AutoFormatExpression: Text[80]; CurrencyCode: Code[10]; AutoFormatPrefixedText: Text[80])
    begin
        AutoFormatExpression := CopyStr(StrSubstNo(CurrencyCodeFormatPrefixTxt, CurrencyCode) + AutoFormatPrefixedText + AutoFormatExpression, 1, 80);
    end;

    local procedure GetCustomFormat(AutoFormatExpr: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    var
        FormatSubtype: Text;
        AutoFormatCurrencyCode: Text[80];
        AutoFormatPrefixedText: Text[80];
    begin
        FormatSubtype := SelectStr(1, AutoFormatExpr);
        if FormatSubtype in ['1', '2'] then begin
            GetCurrencyCodeAndPrefixedText(AutoFormatExpr, AutoFormatCurrencyCode, AutoFormatPrefixedText);
            case FormatSubtype of
                '1':
                    exit(GetCustomAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText, ShowCurrency));
                '2':
                    exit(GetCustomUnitAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText, ShowCurrency));
            end;
        end else
            exit(AutoFormatExpr);
    end;

    local procedure GetCustomAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        // todo: how to handle AutoFormatPrefixedText
        if AutoFormatCurrencyCode = '' then
            exit(GetLCYAmountFormat(AutoFormatPrefixedText, ShowCurrency));
        if GetCurrencyAndAmount(AutoFormatCurrencyCode) then
            exit(GetFCYAmountFormat(AutoFormatPrefixedText, ShowCurrency));
        exit(GetLCYAmountFormat(AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetCustomUnitAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]; ShowCurrency: Enum "Show Currency"): Text[80]
    begin
        // todo: how to handle AutoFormatPrefixedText
        if AutoFormatCurrencyCode = '' then
            exit(GetLCYUnitAmountFormat(AutoFormatPrefixedText, ShowCurrency));
        if GetCurrencyAndUnitAmount(AutoFormatCurrencyCode) then
            exit(GetFCYUnitAmountFormat(AutoFormatPrefixedText, ShowCurrency));
        exit(GetLCYUnitAmountFormat(AutoFormatPrefixedText, ShowCurrency));
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]): Boolean
    begin
        if CurrencyCode = Currency.Code then
            exit(true);
        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
            exit(true);
        end;
        exit(Currency.Get(CurrencyCode));
    end;

    local procedure GetCurrencyAndAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyAndUnitAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Unit-Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyCodeAndPrefixedText(AutoFormatExpr: Text[80]; var AutoFormatCurrencyCode: Text[80]; var AutoFormatPrefixedText: Text[80])
    var
        NumCommasInAutoFormatExpr: Integer;
    begin
        NumCommasInAutoFormatExpr := StrLen(AutoFormatExpr) - StrLen(DelChr(AutoFormatExpr, '=', ','));
        if NumCommasInAutoFormatExpr >= 1 then
            AutoFormatCurrencyCode := CopyStr(SelectStr(2, AutoFormatExpr), 1, 80);
        if NumCommasInAutoFormatExpr >= 2 then
            AutoFormatPrefixedText := CopyStr(SelectStr(3, AutoFormatExpr), 1, 80);
        if AutoFormatPrefixedText <> '' then
            AutoFormatPrefixedText := CopyStr(AutoFormatPrefixedText + ' ', 1, 80);
    end;

    procedure ClearGlobals()
    begin
        ClearAll();
        Clear(GeneralLedgerSetup);
        Clear(Currency);
    end;
}