codeunit 134291 "Check Amount Wording Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1.', Comment = '%1 = amount';
        HandleBeforeEvent: Boolean;
        BeforeEventCount: Integer;
        AfterEventCount: Integer;
        AfterEventAmount: Decimal;

    [Test]
    procedure StandardWordingIgnoresSessionLanguage()
    begin
        // [SCENARIO 653674] The standard W1 wording does not depend on the session language.
        Assert.AreEqual('**** TWENTY ONE AND 25/100', FormatAmountText(21.25, '', 1033), StrSubstNo(UnexpectedAmountTextErr, 21.25));
        Assert.AreEqual('**** TWENTY ONE AND 25/100', FormatAmountText(21.25, '', 1036), StrSubstNo(UnexpectedAmountTextErr, 21.25));
    end;

    [Test]
    procedure HandledBeforeEventReplacesStandardWording()
    var
        CheckAmountWordingTests: Codeunit "Check Amount Wording Tests";
        NoText: array[2] of Text[80];
        Check: Report Check;
    begin
        // [SCENARIO 653674] A subscriber that handles OnBeforeFormatNoText replaces the standard wording.
        CheckAmountWordingTests.SetHandleBeforeEvent(true);
        BindSubscription(CheckAmountWordingTests);

        Check.FormatNoText(NoText, 21.25, '');

        UnbindSubscription(CheckAmountWordingTests);
        Assert.AreEqual('HANDLED', NoText[1], StrSubstNo(UnexpectedAmountTextErr, 21.25));
        Assert.AreEqual(1, CheckAmountWordingTests.GetBeforeEventCount(), 'OnBeforeFormatNoText must be raised once.');
        Assert.AreEqual(1, CheckAmountWordingTests.GetAfterEventCount(), 'OnAfterFormatNoText must be raised once.');
        Assert.AreEqual(21.25, CheckAmountWordingTests.GetAfterEventAmount(), 'OnAfterFormatNoText must receive the original amount.');
    end;

    [Test]
    procedure UnhandledBeforeEventKeepsStandardWording()
    var
        CheckAmountWordingTests: Codeunit "Check Amount Wording Tests";
        NoText: array[2] of Text[80];
        Check: Report Check;
    begin
        // [SCENARIO 653674] The standard wording is used when OnBeforeFormatNoText is not handled.
        BindSubscription(CheckAmountWordingTests);

        Check.FormatNoText(NoText, 21.25, '');

        UnbindSubscription(CheckAmountWordingTests);
        Assert.AreEqual('**** TWENTY ONE AND 25/100', NoText[1], StrSubstNo(UnexpectedAmountTextErr, 21.25));
        Assert.AreEqual(1, CheckAmountWordingTests.GetBeforeEventCount(), 'OnBeforeFormatNoText must be raised once.');
        Assert.AreEqual(1, CheckAmountWordingTests.GetAfterEventCount(), 'OnAfterFormatNoText must be raised once.');
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

    local procedure FormatAmountText(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer): Text
    var
        Check: Report Check;
        NoText: array[2] of Text[80];
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Check.FormatNoText(NoText, Amount, CurrencyCode);
        GlobalLanguage(OriginalLanguageId);

        exit(NoText[1]);
    end;

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnBeforeFormatNoText', '', false, false)]
    local procedure OnBeforeFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
        BeforeEventCount += 1;
        if not HandleBeforeEvent then
            exit;

        Clear(NoText);
        NoText[1] := 'HANDLED';
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnAfterFormatNoText', '', false, false)]
    local procedure OnAfterFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    begin
        AfterEventCount += 1;
        AfterEventAmount := No;
    end;
}
