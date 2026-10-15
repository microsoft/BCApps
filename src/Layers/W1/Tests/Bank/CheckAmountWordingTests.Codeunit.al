namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Automation;
using System.Utilities;

codeunit 134291 "Check Amount Wording Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        AttemptedCheckEntry: Record "Check Ledger Entry";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1.', Comment = '%1 = amount';
        RestrictionDetailsTxt: Label 'Test-print journal line requires approval.';
        HandleBeforeEvent: Boolean;
        BeforeEventCount: Integer;
        AfterEventCount: Integer;
        AfterEventAmount: Decimal;
        CheckInsertCount: Integer;

    [Test]
    procedure TestPrintUsesJournalSourceRecord()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Test printing associates the check with its source journal without a localization subscriber.
        Initialize();

        // [GIVEN] Bank account B and payment journal line J in a W1 deployment without the FR app.
        CreateTestPrintJournalLine(BankAccount, GenJournalLine);
        Commit();

        // [WHEN] The Check report executes its test-print path without a bound subscriber.
        RunTestPrint(BankAccount, GenJournalLine);

        // [THEN] The test-print entry references J and B keeps its last check number.
        VerifyTestPrint(BankAccount, GenJournalLine.SystemId);
    end;

    [Test]
    procedure TestPrintRejectsRestrictedJournalLine()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        RestrictionObserver: Codeunit "Check Amount Wording Tests";
        ExpectedRestrictionError: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Test printing enforces journal usage restrictions when inserting the check entry.
        Initialize();

        // [GIVEN] Journal line J is restricted and an observer captures the attempted check insertion.
        CreateTestPrintJournalLine(BankAccount, GenJournalLine);
        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictionDetailsTxt);
        Commit();
        ExpectedRestrictionError := GetJournalRestrictionError(GenJournalLine);
        BindSubscription(RestrictionObserver);

        // [WHEN] The Check report attempts to test print J.
        asserterror RunTestPrint(BankAccount, GenJournalLine);

        // [THEN] The journal restriction, not report preflight, rejects the test-print insertion.
        Assert.ExpectedError(ExpectedRestrictionError);
        Assert.ExpectedErrorCode('Dialog');
        UnbindSubscription(RestrictionObserver);
        VerifyRejectedTestPrint(RestrictionObserver, BankAccount, GenJournalLine.SystemId);
    end;

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

    procedure GetAttemptedCheckEntry(var CheckLedgerEntry: Record "Check Ledger Entry"): Integer
    begin
        CheckLedgerEntry := AttemptedCheckEntry;
        exit(CheckInsertCount);
    end;

    local procedure CreateTestPrintJournalLine(var BankAccount: Record "Bank Account"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", '100');
        BankAccount.Modify(true);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), 100);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
        GenJournalLine.SetRecFilter();
    end;

    local procedure RunTestPrint(BankAccount: Record "Bank Account"; GenJournalLine: Record "Gen. Journal Line")
    var
        Check: Report Check;
        TempBlob: Codeunit "Temp Blob";
        OutputStream: OutStream;
    begin
        Check.SetTableView(GenJournalLine);
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, true, false);
        TempBlob.CreateOutStream(OutputStream);
        Check.SaveAs('', ReportFormat::Xml, OutputStream);
    end;

    local procedure VerifyTestPrint(BankAccount: Record "Bank Account"; ExpectedJournalSystemId: Guid)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        Assert.RecordCount(CheckLedgerEntry, 1);
        CheckLedgerEntry.FindFirst();
        VerifyTestPrintEntry(CheckLedgerEntry, ExpectedJournalSystemId);
        VerifyLastCheckNo(BankAccount);
    end;

    local procedure VerifyTestPrintEntry(CheckLedgerEntry: Record "Check Ledger Entry"; ExpectedJournalSystemId: Guid)
    begin
        Assert.AreEqual(CheckLedgerEntry."Entry Status"::"Test Print", CheckLedgerEntry."Entry Status", 'Expected a test-print check ledger entry.');
        Assert.AreEqual(ExpectedJournalSystemId, CheckLedgerEntry."Print Gen Jnl Line SystemId", 'Test printing must preserve the source journal association.');
    end;

    local procedure VerifyLastCheckNo(BankAccount: Record "Bank Account")
    var
        LastCheckNo: Code[20];
    begin
        LastCheckNo := BankAccount."Last Check No.";
        BankAccount.Get(BankAccount."No.");
        Assert.AreEqual(LastCheckNo, BankAccount."Last Check No.", 'Test printing must not advance the last check number.');
    end;

    local procedure GetJournalRestrictionError(GenJournalLine: Record "Gen. Journal Line"): Text
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        asserterror RecordRestrictionMgt.CheckRecordHasUsageRestrictions(GenJournalLine);
        Assert.ExpectedError(RestrictionDetailsTxt);
        Assert.ExpectedErrorCode('Dialog');
        exit(GetLastErrorText());
    end;

    local procedure VerifyRejectedTestPrint(RestrictionObserver: Codeunit "Check Amount Wording Tests"; BankAccount: Record "Bank Account"; ExpectedJournalSystemId: Guid)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        Assert.AreEqual(1, RestrictionObserver.GetAttemptedCheckEntry(CheckLedgerEntry), 'The report must reach check ledger entry insertion once.');
        VerifyTestPrintEntry(CheckLedgerEntry, ExpectedJournalSystemId);
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        Assert.RecordIsEmpty(CheckLedgerEntry);
        VerifyLastCheckNo(BankAccount);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::CheckManagement, 'OnInsertCheckOnBeforeCheckLedgEntryInsert', '', false, false)]
    local procedure CaptureCheckInsertion(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
        CheckInsertCount += 1;
        AttemptedCheckEntry := CheckLedgEntry;
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
