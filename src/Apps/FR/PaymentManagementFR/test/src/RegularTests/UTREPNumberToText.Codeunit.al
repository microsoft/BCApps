// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using System.TestLibraries.Utilities;

codeunit 144042 "UT REP Number To Text"
{
    // [FEATURE] [Language] [UT] [Check]
    // The French amount wording is provided by Payment Management FR through the Check report event.
    // The expected texts rely on the untranslated labels of the app, only the number grammar is verified.

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    var
        Assert: Codeunit Assert;
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1 in language %2.', Comment = '%1 = amount, %2 = language ID';

    [Test]
    procedure FrenchNumberGrammar()
    begin
        // [SCENARIO 653674] French number grammar is applied to the check amount in a French session.
        VerifyFrenchAmountText(21, '**** TWENTY AND ONE EUROS');
        VerifyFrenchAmountText(71, '**** SIXTY AND ELEVEN EUROS');
        VerifyFrenchAmountText(80, '**** EIGHTYS EUROS');
        VerifyFrenchAmountText(81, '**** EIGHTY ONE EUROS');
        VerifyFrenchAmountText(91, '**** EIGHTY ELEVEN EUROS');
        VerifyFrenchAmountText(100, '**** HUNDRED EUROS');
        VerifyFrenchAmountText(200, '**** TWO HUNDREDS EUROS');
        VerifyFrenchAmountText(201, '**** TWO HUNDRED ONE EUROS');
        VerifyFrenchAmountText(1000, '**** THOUSAND EUROS');
        VerifyFrenchAmountText(1001, '**** THOUSAND ONE EUROS');
        VerifyFrenchAmountText(2000, '**** TWO THOUSAND EUROS');
        VerifyFrenchAmountText(1000000, '**** ONE MILLION EUROS');
        VerifyFrenchAmountText(2000000, '**** TWO MILLIONS EUROS');
    end;

    [Test]
    procedure FrenchEuroAndCentWording()
    begin
        // [SCENARIO 653674] Euro and cent wording is applied to the check amount in a French session.
        VerifyFrenchAmountText(0, '**** ZERO EUROS');
        VerifyFrenchAmountText(1, '**** ONE EUROS');
        VerifyFrenchAmountText(1.01, '**** ONE EUROS ONE CENT');
        VerifyFrenchAmountText(1.02, '**** ONE EUROS TWO CENTS');
    end;

    [Test]
    procedure AllFrenchLanguagesUseFrenchWording()
    var
        LanguageId: Integer;
    begin
        // [SCENARIO 653674] Standard, Belgian, Swiss and Canadian French sessions use the French wording.
        foreach LanguageId in FrenchLanguageIds() do
            Assert.AreEqual(
                '**** TWO HUNDREDS EUROS',
                FormatAmountText(200, '', LanguageId),
                StrSubstNo(UnexpectedAmountTextErr, 200, LanguageId));
    end;

    [Test]
    procedure NonFrenchLanguageUsesHundredths()
    begin
        // [SCENARIO 653674] Other languages keep the international wording with hundredths.
        Assert.AreEqual(
            '**** TWENTY ONE AND 25/100',
            FormatAmountText(21.25, '', 1033),
            StrSubstNo(UnexpectedAmountTextErr, 21.25, 1033));
        Assert.AreEqual(
            '**** TWENTY ONE AND 25/100 USD',
            FormatAmountText(21.25, 'USD', 1033),
            StrSubstNo(UnexpectedAmountTextErr, 21.25, 1033));
    end;

    [Test]
    procedure FrenchExplicitCurrencyWording()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO 653674] Explicit currencies use the currency description, and only FRF prints cents.
        CreateCurrency(Currency, 'FRF', 'Franc');
        Assert.AreEqual(
            '**** ONE FRANC TWO CENTS',
            FormatAmountText(1.02, Currency.Code, 1036),
            StrSubstNo(UnexpectedAmountTextErr, 1.02, 1036));

        CreateCurrency(Currency, 'TESTFR', 'Test Currency');
        Assert.AreEqual(
            '**** ONE TEST CURRENCY TWO',
            FormatAmountText(1.02, Currency.Code, 1036),
            StrSubstNo(UnexpectedAmountTextErr, 1.02, 1036));
    end;

    [Test]
    procedure LongAmountTextIsSplitInTwoLines()
    var
        NoText: array[2] of Text[80];
    begin
        // [SCENARIO 653674] A long amount text is split into the two lines of the check.
        FormatAmount(NoText, 999999.99, '', 1036);

        Assert.AreNotEqual('', NoText[2], StrSubstNo(UnexpectedAmountTextErr, 999999.99, 1036));
    end;

    local procedure VerifyFrenchAmountText(Amount: Decimal; ExpectedAmountText: Text)
    begin
        Assert.AreEqual(
            ExpectedAmountText,
            FormatAmountText(Amount, '', 1036),
            StrSubstNo(UnexpectedAmountTextErr, Amount, 1036));
    end;

    local procedure FrenchLanguageIds() LanguageIds: List of [Integer]
    begin
        LanguageIds.Add(1036);
        LanguageIds.Add(2060);
        LanguageIds.Add(3084);
        LanguageIds.Add(4108);
    end;

    local procedure FormatAmountText(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer): Text
    var
        NoText: array[2] of Text[80];
    begin
        FormatAmount(NoText, Amount, CurrencyCode, LanguageId);

        if NoText[2] = '' then
            exit(NoText[1]);
        exit(NoText[1] + ' ' + NoText[2]);
    end;

    local procedure FormatAmount(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer)
    var
        Check: Report Check;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Check.FormatNoText(NoText, Amount, CurrencyCode);
        GlobalLanguage(OriginalLanguageId);
    end;

    local procedure CreateCurrency(var Currency: Record Currency; CurrencyCode: Code[10]; Description: Text[30])
    begin
        if Currency.Get(CurrencyCode) then
            Currency.Delete();

        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Description := Description;
        Currency.Insert();
    end;
}
