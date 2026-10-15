using Microsoft.Bank.Check;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 134291 "Check Amount Wording Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1.', Comment = '%1 = amount';
        HandleBeforeEvent: Boolean;
        BeforeEventCount: Integer;
        AfterEventCount: Integer;
        AfterEventAmount: Decimal;

    [Test]
    procedure StandardWordingUsesEnglishSessionLanguage()
    var
        NoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] W1 wording uses initialized English labels when no subscriber replaces it.
        Initialize();

        // [GIVEN] A W1 deployment without a localization subscriber and previous text in both lines.
        NoText[1] := 'PREVIOUS FIRST LINE';
        NoText[2] := 'PREVIOUS SECOND LINE';

        // [WHEN] The amount is formatted in an English session.
        FormatAmountText(NoText, 21.25, '');

        // [THEN] Both output lines contain the standard wording.
        VerifyWording(NoText, '**** TWENTY ONE AND 25/100', '', 21.25);
    end;

    [Test]
    procedure HandledBeforeEventReplacesStandardWording()
    var
        CheckAmountWordingTests: Codeunit "Check Amount Wording Tests";
        NoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A subscriber that handles OnBeforeFormatNoText replaces the standard wording.
        Initialize();

        // [GIVEN] A subscriber replacing both output lines.
        CheckAmountWordingTests.SetHandleBeforeEvent(true);
        BindSubscription(CheckAmountWordingTests);

        // [WHEN] The amount is formatted.
        FormatAmountText(NoText, 21.25, '');

        UnbindSubscription(CheckAmountWordingTests);

        // [THEN] Both replacement lines survive and the after event receives the original amount once.
        VerifyWording(NoText, 'HANDLED FIRST LINE', 'HANDLED SECOND LINE', 21.25);
        VerifyEvents(CheckAmountWordingTests, 21.25);
    end;

    [Test]
    procedure UnhandledBeforeEventKeepsStandardWording()
    var
        CheckAmountWordingTests: Codeunit "Check Amount Wording Tests";
        NoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The standard wording is used when OnBeforeFormatNoText is not handled.
        Initialize();

        // [GIVEN] A W1 deployment and a subscriber that leaves the before event unhandled.
        BindSubscription(CheckAmountWordingTests);

        // [WHEN] The amount is formatted in an English session.
        FormatAmountText(NoText, 21.25, '');

        UnbindSubscription(CheckAmountWordingTests);

        // [THEN] Both standard lines survive and the after event retains the fractional remainder.
        VerifyWording(NoText, '**** TWENTY ONE AND 25/100', '', 21.25);
        VerifyEvents(CheckAmountWordingTests, 0.25);
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Check Amount Wording Tests");
        LibrarySetupStorage.Restore();
        GeneralLedgerSetup.Get();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        GeneralLedgerSetup."Amount Rounding Precision" := 0.01;
        GeneralLedgerSetup.Modify();
    end;

    procedure SetHandleBeforeEvent(NewHandleBeforeEvent: Boolean)
    begin
        HandleBeforeEvent := NewHandleBeforeEvent;
    end;

    procedure GetBeforeEventCount(): Integer
    begin
        exit(BeforeEventCount);
    end;

    procedure GetAfterEventCount(): Integer
    begin
        exit(AfterEventCount);
    end;

    procedure GetAfterEventAmount(): Decimal
    begin
        exit(AfterEventAmount);
    end;

    local procedure FormatAmountText(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10])
    var
        OriginalLanguageId: Integer;
        FormattingSucceeded: Boolean;
        FormattingError: Text;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);
        FormattingSucceeded := TryFormatAmountText(NoText, Amount, CurrencyCode);
        FormattingError := GetLastErrorText();
        GlobalLanguage(OriginalLanguageId);

        if not FormattingSucceeded then
            Error(FormattingError);
    end;

    [TryFunction]
    local procedure TryFormatAmountText(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10])
    var
        Check: Report Check;
    begin
        Check.InitTextVariable();
        Check.FormatNoText(NoText, Amount, CurrencyCode);
    end;

    local procedure VerifyWording(NoText: array[2] of Text[80]; ExpectedFirstLine: Text; ExpectedSecondLine: Text; Amount: Decimal)
    begin
        Assert.AreEqual(ExpectedFirstLine, NoText[1], StrSubstNo(UnexpectedAmountTextErr, Amount));
        Assert.AreEqual(ExpectedSecondLine, NoText[2], 'Unexpected second amount text line.');
    end;

    local procedure VerifyEvents(CheckAmountWordingTests: Codeunit "Check Amount Wording Tests"; ExpectedAfterEventAmount: Decimal)
    begin
        Assert.AreEqual(1, CheckAmountWordingTests.GetBeforeEventCount(), 'OnBeforeFormatNoText must be raised once.');
        Assert.AreEqual(1, CheckAmountWordingTests.GetAfterEventCount(), 'OnAfterFormatNoText must be raised once.');
        Assert.AreEqual(ExpectedAfterEventAmount, CheckAmountWordingTests.GetAfterEventAmount(), 'Unexpected amount passed to OnAfterFormatNoText.');
    end;

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnBeforeFormatNoText', '', false, false)]
    local procedure OnBeforeFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
        BeforeEventCount += 1;
        if not HandleBeforeEvent then
            exit;

        Clear(NoText);
        NoText[1] := 'HANDLED FIRST LINE';
        NoText[2] := 'HANDLED SECOND LINE';
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnAfterFormatNoText', '', false, false)]
    local procedure OnAfterFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    begin
        AfterEventCount += 1;
        AfterEventAmount := No;
    end;
}
