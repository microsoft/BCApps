codeunit 134291 "Check Amount Wording Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1.', Comment = '%1 = amount';
        FormatEventEnabled: Boolean;
        FormatEventCallCount: Integer;
        FormatEventAmount: Decimal;

    [Test]
    [Scope('OnPrem')]
    procedure FrenchAmountWordingPreservesNumberGrammar()
    begin
        AssertFrenchGrammar(21, '**** TWENTY AND ONE EUROS');
        AssertFrenchGrammar(71, '**** SIXTY AND ELEVEN EUROS');
        AssertFrenchGrammar(80, '**** EIGHTYS EUROS');
        AssertFrenchGrammar(81, '**** EIGHTY ONE EUROS');
        AssertFrenchGrammar(91, '**** EIGHTY ELEVEN EUROS');
        AssertFrenchGrammar(100, '**** HUNDRED EUROS');
        AssertFrenchGrammar(200, '**** TWO HUNDREDS EUROS');
        AssertFrenchGrammar(201, '**** TWO HUNDRED ONE EUROS');
        AssertFrenchGrammar(1000, '**** THOUSAND EUROS');
        AssertFrenchGrammar(1001, '**** THOUSAND ONE EUROS');
        AssertFrenchGrammar(2000, '**** TWO THOUSAND EUROS');
        AssertFrenchGrammar(1000000, '**** ONE MILLION EUROS');
        AssertFrenchGrammar(2000000, '**** TWO MILLIONS EUROS');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FrenchAmountWordingPreservesEuroAndCentWording()
    var
        AmountText: Text;
    begin
        AmountText := FormatFrenchAmount(0, '', 1033);
        Assert.IsTrue(StrPos(AmountText, ' EUROS') > 0, StrSubstNo(UnexpectedAmountTextErr, 0));
        Assert.AreNotEqual('**** EUROS', AmountText, StrSubstNo(UnexpectedAmountTextErr, 0));
        AssertFrenchGrammar(1, '**** ONE EUROS');
        AssertFrenchGrammar(2, '**** TWO EUROS');
        AssertFrenchGrammar(1.01, '**** ONE EUROS ONE CENT');
        AssertFrenchGrammar(1.02, '**** ONE EUROS TWO CENTS');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FrenchLocalesUseFrenchNumberGrammar()
    var
        FrenchLanguageIds: array[4] of Integer;
        Amounts: array[4] of Decimal;
        AmountIndex: Integer;
        Index: Integer;
    begin
        FrenchLanguageIds[1] := 1036;
        FrenchLanguageIds[2] := 2060;
        FrenchLanguageIds[3] := 3084;
        FrenchLanguageIds[4] := 4108;
        Amounts[1] := 21;
        Amounts[2] := 200;
        Amounts[3] := 1000;
        Amounts[4] := 2000000;

        for Index := 1 to ArrayLen(FrenchLanguageIds) do
            for AmountIndex := 1 to ArrayLen(Amounts) do
                Assert.AreEqual(
                    FormatFrenchAmount(Amounts[AmountIndex], '', FrenchLanguageIds[Index]),
                    FormatAmount(Amounts[AmountIndex], '', FrenchLanguageIds[Index]),
                    StrSubstNo(UnexpectedAmountTextErr, Amounts[AmountIndex]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonFrenchAmountWordingPreservesW1Format()
    begin
        Assert.AreEqual(
            '**** TWENTY ONE AND 25/100',
            FormatAmount(21.25, '', 1033),
            StrSubstNo(UnexpectedAmountTextErr, 21.25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FrenchAmountWordingPreservesExplicitCurrencyBehavior()
    var
        Currency: Record Currency;
    begin
        CreateCurrency(Currency, 'FRF', 'FRANC');
        Assert.AreEqual(
            '**** ONE FRANC TWO CENTS',
            FormatFrenchAmount(1.02, Currency.Code, 1033),
            StrSubstNo(UnexpectedAmountTextErr, 1.02));

        CreateCurrency(Currency, 'TEST', 'TEST CURRENCY');
        Assert.AreEqual(
            '**** ONE TEST CURRENCY TWO',
            FormatFrenchAmount(1.02, Currency.Code, 1033),
            StrSubstNo(UnexpectedAmountTextErr, 1.02));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountWordingSplitsLongTextAcrossTwoLines()
    var
        NoText: array[2] of Text[80];
    begin
        FormatFrenchAmount(999999.99, '', 1033, NoText);

        Assert.AreNotEqual('', NoText[2], StrSubstNo(UnexpectedAmountTextErr, 999999.99));
        Assert.IsTrue(StrLen(NoText[1]) <= MaxStrLen(NoText[1]), StrSubstNo(UnexpectedAmountTextErr, 999999.99));
        Assert.IsTrue(StrLen(NoText[2]) <= MaxStrLen(NoText[2]), StrSubstNo(UnexpectedAmountTextErr, 999999.99));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextEventRemainsMutableAndReceivesOriginalAmount()
    var
        CheckAmountWordingTests: Codeunit "Check Amount Wording Tests";
        AmountText: Text;
    begin
        CheckAmountWordingTests.EnableFormatEvent();
        BindSubscription(CheckAmountWordingTests);

        AmountText := FormatAmount(21.25, '', 1033);

        UnbindSubscription(CheckAmountWordingTests);
        Assert.AreEqual('EVENT OVERRIDE', AmountText, StrSubstNo(UnexpectedAmountTextErr, 21.25));
        Assert.AreEqual(1, CheckAmountWordingTests.GetFormatEventCallCount(), 'The event must be raised exactly once.');
        Assert.AreEqual(21.25, CheckAmountWordingTests.GetFormatEventAmount(), 'The event must receive the original amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPreviewUsesFrenchAmountWording()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckPreview: TestPage "Check Preview";
        ExpectedAmountText: Text;
        OriginalLanguageId: Integer;
    begin
        CreateGenJournalLine(GenJournalLine, 21);
        OriginalLanguageId := GlobalLanguage;
        GlobalLanguage(1036);
        ExpectedAmountText := FormatFrenchAmount(21, '', 1036);

        CheckPreview.OpenView();
        CheckPreview.Filter.SetFilter("Document No.", GenJournalLine."Document No.");
        CheckPreview.AmountText.AssertEquals(ExpectedAmountText);
        CheckPreview.Close();

        GlobalLanguage(OriginalLanguageId);
    end;

    procedure EnableFormatEvent()
    begin
        FormatEventEnabled := true;
    end;

    procedure GetFormatEventCallCount(): Integer
    begin
        exit(FormatEventCallCount);
    end;

    procedure GetFormatEventAmount(): Decimal
    begin
        exit(FormatEventAmount);
    end;

    local procedure AssertFrenchGrammar(Amount: Decimal; ExpectedAmountText: Text)
    begin
        Assert.AreEqual(
            ExpectedAmountText,
            FormatFrenchAmount(Amount, '', 1033),
            StrSubstNo(UnexpectedAmountTextErr, Amount));
    end;

    local procedure FormatAmount(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer): Text
    var
        NoText: array[2] of Text[80];
    begin
        FormatAmount(Amount, CurrencyCode, LanguageId, NoText);

        if NoText[2] = '' then
            exit(NoText[1]);

        exit(NoText[1] + ' ' + NoText[2]);
    end;

    local procedure FormatAmount(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer; var NoText: array[2] of Text[80])
    var
        Check: Report Check;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage;
        GlobalLanguage(LanguageId);

        Check.InitTextVariable();
        Check.FormatNoText(NoText, Amount, CurrencyCode);

        GlobalLanguage(OriginalLanguageId);
    end;

    local procedure FormatFrenchAmount(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer): Text
    var
        NoText: array[2] of Text[80];
    begin
        FormatFrenchAmount(Amount, CurrencyCode, LanguageId, NoText);

        if NoText[2] = '' then
            exit(NoText[1]);

        exit(NoText[1] + ' ' + NoText[2]);
    end;

    local procedure FormatFrenchAmount(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer; var NoText: array[2] of Text[80])
    var
        Check: Report Check;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage;
        GlobalLanguage(LanguageId);

        Check.InitTextVariable();
        Check.FormatNoTextFR(NoText, Amount, CurrencyCode);

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

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := 'CHECK';
        GenJournalLine."Journal Batch Name" := 'CHECK';
        GenJournalLine."Line No." := 10000;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document No." := 'CHECK-WORDING';
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine.Description := 'Check wording test';
        GenJournalLine.Amount := Amount;
        GenJournalLine.Insert();
    end;

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnAfterFormatNoText', '', false, false)]
    local procedure CheckOnAfterFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    begin
        if not FormatEventEnabled then
            exit;

        FormatEventCallCount += 1;
        FormatEventAmount := No;
        NoText[1] := 'EVENT OVERRIDE';
        Clear(NoText[2]);
    end;
}
