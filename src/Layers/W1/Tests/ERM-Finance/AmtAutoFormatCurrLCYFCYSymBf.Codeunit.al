// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Test.Text;
using System.TestLibraries.Utilities;

codeunit 134843 AmtAutoFormatCurrLCYFCYSymBf
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Any: Codeunit "Any";
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoFormatShowLCYFCYSymbolOnlyBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYandFCYSymbol();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        RequestSessionUpdate();
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure XmlFormatOmitsCurrencySymbolsBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [SCENARIO 625894] XML formatting omits currency symbols before amounts without rounding the stored values.
        // [GIVEN] LCY and FCY currency symbols are shown before amounts with five-decimal precision.
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYAndFCYSymbol();
        GeneralLedgerSetup."Currency Symbol Position" := GeneralLedgerSetup."Currency Symbol Position"::"Before Amount";
        GeneralLedgerSetup."Amount Decimal Places" := '0:5';
        GeneralLedgerSetup."Unit-Amount Decimal Places" := '0:5';
        GeneralLedgerSetup.Modify();
        Currency := CreateFCYCurrency(Enum::"Currency Symbol Position"::"Before Amount");
        Currency."Amount Decimal Places" := '0:5';
        Currency."Unit-Amount Decimal Places" := '0:5';
        Currency.Modify();
        RequestSessionUpdate();

        // [GIVEN] Positive and negative LCY and FCY amounts with five decimal places.
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);
        AmountAutoFormatCurrency.Case1LCY := 1234.56789;
        AmountAutoFormatCurrency.Case2LCY := -1234.56789;
        AmountAutoFormatCurrency.Case1FCY := 1234.56789;
        AmountAutoFormatCurrency.Case2FCY := -1234.56789;
        AmountAutoFormatCurrency.Modify();

        // [WHEN] The amounts are displayed on a page and formatted using XML format 9.
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);
        // [THEN] Page formatting includes the configured currency symbols.
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'Page formatting must still include the LCY symbol.');
        Assert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'Page formatting must still include the FCY symbol.');
        AmountAutoFormatCurrencyTestPage.Close();

        // [THEN] XML formatting omits symbols without losing signs or decimal precision.
        Assert.AreEqual('1234.56789', Format(AmountAutoFormatCurrency.Case1LCY, 0, 9), 'XML formatting of an LCY amount must omit the currency symbol and preserve precision.');
        Assert.AreEqual('-1234.56789', Format(AmountAutoFormatCurrency.Case2LCY, 0, 9), 'XML formatting of an LCY unit amount must omit the currency symbol and preserve the sign and precision.');
        Assert.AreEqual('1234.56789', Format(AmountAutoFormatCurrency.Case1FCY, 0, 9), 'XML formatting of an FCY amount must omit the currency symbol and preserve precision.');
        Assert.AreEqual('-1234.56789', Format(AmountAutoFormatCurrency.Case2FCY, 0, 9), 'XML formatting of an FCY unit amount must omit the currency symbol and preserve the sign and precision.');
        AmountAutoFormatCurrency.Case1FCY := 0;
        Assert.AreEqual('0', Format(AmountAutoFormatCurrency.Case1FCY, 0, 9), 'XML formatting of a zero FCY amount must omit the currency symbol.');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure ResetSetup_NotATest()
    begin
        // if a test fails, it leaves the General Ledger Setup in an unknown state. Other tests can't handle showing the currency, so this fake test is to ensure te setup is reset so failures appear here only and not in other unrelated tests.
        SetShowCurrencyNever();
        RequestSessionUpdate();
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then
            GeneralLedgerSetup."LCY Code" := 'LCY';
        if GeneralLedgerSetup."Local Currency Symbol" = '' then
            GeneralLedgerSetup."Local Currency Symbol" := '~';
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyNever() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::Never;
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyLCYAndFCYSymbol() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::"LCY and FCY Symbol";
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateAmountFormatCurrencyTestRecord(CurrencyCode: Code[10]) AmountAutoFormatCurrency: Record "Amount AutoFormat Currency"
    begin
        AmountAutoFormatCurrency.DeleteAll();
        AmountAutoFormatCurrency.Case1LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case2LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case4LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case5LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case1FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case2FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case4FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case5FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency."Currency Code" := CurrencyCode;
        AmountAutoFormatCurrency.Insert(true);
    end;

    local procedure CreateFCYCurrency(CurrencySymbolPosition: Enum "Currency Symbol Position") Currency: Record "Currency"
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRounding());
        Currency.Symbol := '$';
        Currency."Currency Symbol Position" := CurrencySymbolPosition;
        Currency."ISO Code" := 'ABC';
        Currency.Modify(true);
    end;

    local procedure FormatValue(value: Decimal; DecimalPlaces: Text[5]; CurrencyText: Text[10]; CurrencySymbolPosition: Enum "Currency Symbol Position") Result: Text[30]
    begin
#pragma warning disable AA0217
        if CurrencyText = '' then
            exit(Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)));
        case CurrencySymbolPosition of
            CurrencySymbolPosition::"Before Amount":
                Result := StrSubstNo('%2 %1', Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)), CurrencyText);
            CurrencySymbolPosition::"After Amount":
                Result := StrSubstNo('%1 %2', Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)), CurrencyText);
        end;
#pragma warning restore AA0217
    end;

    local procedure RequestSessionUpdate()
    var
        SessionSettings: SessionSettings;
    begin
        Commit();
        SessionSettings.RequestSessionUpdate(false);
    end;

    [SessionSettingsHandler]
    procedure SessionSettingsHandler(var SessionSettings: SessionSettings): Boolean
    begin
        exit(true);
    end;
}
