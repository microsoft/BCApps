// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Automation;
using System.Utilities;

codeunit 134292 "Check Test Print Tests"
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
        RestrictionDetailsTxt: Label 'Test-print journal line requires approval.';
        CheckInsertCount: Integer;

    [Test]
    procedure TestPrintUsesJournalSourceRecord()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Test printing associates the check with its source journal.
        Initialize();

        // [GIVEN] Bank account B and payment journal line J.
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
        RestrictionObserver: Codeunit "Check Test Print Tests";
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

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Check Test Print Tests");
        LibrarySetupStorage.Restore();
        GeneralLedgerSetup.Get();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        GeneralLedgerSetup."Amount Rounding Precision" := 0.01;
        GeneralLedgerSetup.Modify();
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

    local procedure VerifyRejectedTestPrint(RestrictionObserver: Codeunit "Check Test Print Tests"; BankAccount: Record "Bank Account"; ExpectedJournalSystemId: Guid)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        Assert.AreEqual(1, RestrictionObserver.GetAttemptedCheckEntry(CheckLedgerEntry), 'The report must reach check ledger entry insertion once.');
        VerifyTestPrintEntry(CheckLedgerEntry, ExpectedJournalSystemId);
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        Assert.RecordIsEmpty(CheckLedgerEntry);
        VerifyLastCheckNo(BankAccount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::CheckManagement, 'OnInsertCheckOnBeforeCheckLedgEntryInsert', '', false, false)]
    local procedure CaptureCheckInsertion(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
        CheckInsertCount += 1;
        AttemptedCheckEntry := CheckLedgEntry;
    end;
}
