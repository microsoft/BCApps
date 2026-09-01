namespace Microsoft.Test.Sustainability;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;

codeunit 148222 "Sust. Reversal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sustainability] [Reverse Transaction]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySustainability: Codeunit "Library - Sustainability";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    procedure ReverseSimpleSustEntry()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        OriginalEntryNo: Integer;
        OriginalCO2: Decimal;
    begin
        // [SCENARIO] Reverse a simple sustainability journal entry and verify emission values are negated
        // [GIVEN] A posted Sustainability Ledger Entry from a journal
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        OriginalEntryNo := SustLedgEntry."Entry No.";
        OriginalCO2 := SustLedgEntry."Emission CO2";

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The original entry is marked as reversed
        SustLedgEntry.Get(OriginalEntryNo);
        Assert.IsTrue(SustLedgEntry."Reversed", 'Original entry should be marked as Reversed.');
        Assert.AreNotEqual(0, SustLedgEntry."Reversed by Entry No.", 'Reversed by Entry No. should be populated.');

        // [THEN] A new reversal entry exists with negated values
        VerifyReversalEntry(SustLedgEntry."Reversed by Entry No.", OriginalEntryNo, -OriginalCO2);
    end;

    [Test]
    procedure ReverseEntryNegatesAllEmissionFields()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] All emission fields (CO2, CH4, N2O, CO2e, Carbon Fee, Water, Waste, Energy) are negated
        // [GIVEN] A sustainability entry with all emission fields populated
        Initialize();
        CreateSustLedgerEntryWithAllFields(SustLedgEntry);

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry has all emission fields negated
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");

        Assert.AreEqual(-SustLedgEntry."Emission CO2", ReversalEntry."Emission CO2", 'CO2 should be negated but values changed');
        Assert.AreEqual(-SustLedgEntry."Emission CH4", ReversalEntry."Emission CH4", 'CH4 should be negated but values changed');
        Assert.AreEqual(-SustLedgEntry."Emission N2O", ReversalEntry."Emission N2O", 'N2O should be negated but values changed');
        Assert.AreEqual(-SustLedgEntry."CO2e Emission", ReversalEntry."CO2e Emission", 'CO2e should be negated but values changed');
        Assert.AreEqual(-SustLedgEntry."Carbon Fee", ReversalEntry."Carbon Fee", 'Carbon Fee should be negated but values changed');
        Assert.AreEqual(-SustLedgEntry."Water Intensity", ReversalEntry."Water Intensity", 'Water Intensity should be negated');
        Assert.AreEqual(-SustLedgEntry."Discharged Into Water", ReversalEntry."Discharged Into Water", 'Discharged Into Water should be negated');
        Assert.AreEqual(-SustLedgEntry."Waste Intensity", ReversalEntry."Waste Intensity", 'Waste Intensity should be negated');
        Assert.AreEqual(-SustLedgEntry."Energy Consumption", ReversalEntry."Energy Consumption", 'Energy Consumption should be negated');
    end;

    [Test]
    procedure ReverseAlreadyReversedEntryThrowsError()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Attempting to reverse an already-reversed entry should throw an error
        // [GIVEN] A sustainability entry that is already reversed
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        SustLedgEntry."Reversed" := true;
        SustLedgEntry."Reversed by Entry No." := SustLedgEntry."Entry No." + 1;
        SustLedgEntry.Modify();

        // [WHEN] The user tries to reverse it again
        // [THEN] An error is thrown
        asserterror SustEntryReverseMgt.ReverseEntry(SustLedgEntry);
        Assert.ExpectedError('has already been reversed');
    end;

    [Test]
    procedure ReverseDocumentPostedEntryThrowsError()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Entries posted from documents (Journal Template Name = '') cannot be reversed
        // [GIVEN] A sustainability entry posted from a purchase document (empty Journal Template Name)
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, '', '');

        // [WHEN] The user tries to reverse it
        // [THEN] An error is thrown telling to use corrective document
        asserterror SustEntryReverseMgt.ReverseEntry(SustLedgEntry);
        Assert.ExpectedError('posted from a document');
    end;

    [Test]
    procedure ReverseBlockedAccountThrowsError()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Reversal mirrors posting and cannot reverse into a blocked account
        // [GIVEN] A sustainability entry whose account has since been blocked
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        SustainabilityAccount.Get(SustLedgEntry."Account No.");
        SustainabilityAccount.Validate(Blocked, true);
        SustainabilityAccount.Modify(true);

        // [WHEN] The user tries to reverse it
        // [THEN] An error is thrown because the account is blocked
        asserterror SustEntryReverseMgt.ReverseEntry(SustLedgEntry);
        Assert.ExpectedError('Blocked');
    end;

    [Test]
    procedure ReverseNonDirectPostingAccountThrowsError()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Reversal mirrors posting and cannot reverse into an account that no longer allows direct posting
        // [GIVEN] A sustainability entry whose account no longer allows direct posting
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        SustainabilityAccount.Get(SustLedgEntry."Account No.");
        SustainabilityAccount.Validate("Direct Posting", false);
        SustainabilityAccount.Modify(true);

        // [WHEN] The user tries to reverse it
        // [THEN] An error is thrown because direct posting is not allowed
        asserterror SustEntryReverseMgt.ReverseEntry(SustLedgEntry);
        Assert.ExpectedError('Direct Posting');
    end;

    [Test]
    procedure ReverseGeneralJournalEntryIsAllowed()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Entries posted from General Journal (Template Name = 'GENERAL') can be reversed
        // [GIVEN] A sustainability entry posted from General Journal
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'GENERAL', 'DEFAULT');

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The entry is successfully reversed
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        Assert.IsTrue(SustLedgEntry."Reversed", 'General Journal entry should be reversible.');
    end;

    [Test]
    procedure ReversalEntryIsAlsoMarkedReversed()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] The reversal entry itself should be marked as Reversed (so it cannot be reversed again)
        // [GIVEN] A posted sustainability entry
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry is also marked as reversed
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");
        Assert.IsTrue(ReversalEntry."Reversed", 'Reversal entry should be marked as Reversed.');
        Assert.AreEqual(SustLedgEntry."Entry No.", ReversalEntry."Reversed Entry No.",
            'Reversal entry should point back to original entry.');
    end;

    [Test]
    procedure ReversalPreservesDocumentNo()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] The reversal entry should keep the same Document No. as the original
        // [GIVEN] A posted sustainability entry with a Document No.
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry has the same Document No.
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");
        Assert.AreEqual(SustLedgEntry."Document No.", ReversalEntry."Document No.",
            'Reversal entry should have same Document No. as original.');
    end;

    [Test]
    procedure ReversalPreservesPostingDate()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        OriginalPostingDate: Date;
    begin
        // [SCENARIO] The reversal entry should post on the original entry's posting date (matches G/L Reverse), not WorkDate
        // [GIVEN] A posted sustainability entry with a posting date different from WorkDate
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        OriginalPostingDate := CalcDate('<-1M>', WorkDate());
        SustLedgEntry."Posting Date" := OriginalPostingDate;
        SustLedgEntry.Modify();

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry has the same Posting Date as the original
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");
        Assert.AreEqual(OriginalPostingDate, ReversalEntry."Posting Date",
            'Reversal entry should post on the original entry''s posting date.');
    end;

    [Test]
    procedure ReversalStampsUserId()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] The reversal entry should stamp the current User ID (matches Sustainability posting and G/L Reverse)
        // [GIVEN] A posted sustainability entry
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry has the current User ID stamped
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(ReversalEntry."User ID")), ReversalEntry."User ID",
            'Reversal entry should stamp the current User ID.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ReverseMultipleEntriesConfirmYes()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustLedgEntry2: Record "Sustainability Ledger Entry";
        SelectionFilter: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Reversing multiple selected entries when user confirms Yes
        // [GIVEN] Two sustainability entries from journal
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        CreateSustLedgerEntry(SustLedgEntry2, 'SUSTJNL', 'DEFAULT');

        // [WHEN] Both entries are selected and reversed with confirmation
        SelectionFilter.SetFilter("Entry No.", '%1|%2', SustLedgEntry."Entry No.", SustLedgEntry2."Entry No.");
        SustEntryReverseMgt.ReverseEntries(SelectionFilter);

        // [THEN] Both entries are reversed
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        SustLedgEntry2.Get(SustLedgEntry2."Entry No.");
        Assert.IsTrue(SustLedgEntry."Reversed", 'First entry should be reversed.');
        Assert.IsTrue(SustLedgEntry2."Reversed", 'Second entry should be reversed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReverseMultipleEntriesConfirmNo()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SelectionFilter: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] Reversing entries when user declines confirmation should leave entries unchanged
        // [GIVEN] A sustainability entry from journal
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');

        // [WHEN] Reversal is attempted but user says No
        SelectionFilter.SetFilter("Entry No.", '%1', SustLedgEntry."Entry No.");
        SustEntryReverseMgt.ReverseEntries(SelectionFilter);

        // [THEN] Entry is not reversed
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        Assert.IsFalse(SustLedgEntry."Reversed", 'Entry should not be reversed when user declines.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ReverseMultipleWithOneAlreadyReversedThrowsError()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustLedgEntry2: Record "Sustainability Ledger Entry";
        SelectionFilter: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [SCENARIO] If any entry in the selection is already reversed, all-or-nothing validation should fail
        // [GIVEN] Two entries - one already reversed, one not
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        CreateSustLedgerEntry(SustLedgEntry2, 'SUSTJNL', 'DEFAULT');
        SustLedgEntry2."Reversed" := true;
        SustLedgEntry2.Modify();

        // [WHEN] Both are selected for reversal
        SelectionFilter.SetFilter("Entry No.", '%1|%2', SustLedgEntry."Entry No.", SustLedgEntry2."Entry No.");

        // [THEN] Error is thrown (all-or-nothing validation fails on the reversed entry)
        asserterror SustEntryReverseMgt.ReverseEntries(SelectionFilter);
        Assert.ExpectedError('has already been reversed');
    end;

    [Test]
    procedure ReverseCollectedEntryRemovesGLEntryRelations()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        FirstGLEntryNo, SecondGLEntryNo, OriginalEntryNo : Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reversing a sustainability entry deletes the links to the general ledger entries it consumed.
        // [GIVEN] A sustainability ledger entry that is linked to two collected G/L entries "G1" and "G2"
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        OriginalEntryNo := SustLedgEntry."Entry No.";
        FirstGLEntryNo := PostGLEntry(1000);
        SecondGLEntryNo := PostGLEntry(500);
        LinkGLEntryToSustEntry(FirstGLEntryNo, OriginalEntryNo);
        LinkGLEntryToSustEntry(SecondGLEntryNo, OriginalEntryNo);

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] No relation record remains for the reversed entry
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", OriginalEntryNo);
        Assert.RecordIsEmpty(SustGLSustLedgerRel);
    end;

    [Test]
    procedure ReverseCollectedEntryClearsGLEntryCollectedMarker()
    var
        GLEntry: Record "G/L Entry";
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        GLEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reversing a sustainability entry makes the general ledger entries it consumed collectable again.
        // [GIVEN] A sustainability ledger entry that is linked to a collected G/L entry "G1" flagged as collected
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        GLEntryNo := PostGLEntry(1000);
        LinkGLEntryToSustEntry(GLEntryNo, SustLedgEntry."Entry No.");
        GLEntry.Get(GLEntryNo);
        Assert.IsTrue(GLEntry."Sust. Collected", 'The G/L entry should be flagged as collected after it was linked.');

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The collected flag of "G1" is cleared
        GLEntry.Get(GLEntryNo);
        Assert.IsFalse(GLEntry."Sust. Collected", 'The G/L entry should be collectable again after the reversal.');
    end;

    [Test]
    procedure ReverseKeepsGLEntryCollectedWhenAnotherEntryStillLinked()
    var
        GLEntry: Record "G/L Entry";
        FirstSustLedgEntry: Record "Sustainability Ledger Entry";
        SecondSustLedgEntry: Record "Sustainability Ledger Entry";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        GLEntryNo, FirstEntryNo, SecondEntryNo : Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A general ledger entry stays consumed as long as at least one sustainability entry still links to it.
        // [GIVEN] G/L entry "G1" linked to sustainability entries "S1" and "S2"
        Initialize();
        CreateSustLedgerEntry(FirstSustLedgEntry, 'SUSTJNL', 'DEFAULT');
        FirstEntryNo := FirstSustLedgEntry."Entry No.";
        CreateSustLedgerEntry(SecondSustLedgEntry, 'SUSTJNL', 'DEFAULT');
        SecondEntryNo := SecondSustLedgEntry."Entry No.";
        GLEntryNo := PostGLEntry(1000);
        LinkGLEntryToSustEntry(GLEntryNo, FirstEntryNo);
        LinkGLEntryToSustEntry(GLEntryNo, SecondEntryNo);

        // [WHEN] "S1" is reversed
        SustEntryReverseMgt.ReverseEntry(FirstSustLedgEntry);

        // [THEN] The links of "S1" are removed, the link of "S2" remains and "G1" is still flagged as collected
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", FirstEntryNo);
        Assert.RecordIsEmpty(SustGLSustLedgerRel);
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", SecondEntryNo);
        Assert.RecordCount(SustGLSustLedgerRel, 1);
        GLEntry.Get(GLEntryNo);
        Assert.IsTrue(GLEntry."Sust. Collected", 'The G/L entry must stay collected while another sustainability entry links to it.');
    end;

    [Test]
    procedure ReversalEntryHasNoCollectionInformation()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        ReversalEntry: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The reversal entry does not claim to have collected general ledger entries.
        // [GIVEN] A sustainability ledger entry with Collected from G/L Entries set and a collection period
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        SustLedgEntry."Collected from G/L Entries" := true;
        SustLedgEntry."Collect From Date" := WorkDate();
        SustLedgEntry."Collect To Date" := WorkDate() + 30;
        SustLedgEntry.Modify();

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The reversal entry has the collection flag cleared and both collection dates empty
        SustLedgEntry.Get(SustLedgEntry."Entry No.");
        ReversalEntry.Get(SustLedgEntry."Reversed by Entry No.");
        Assert.IsFalse(ReversalEntry."Collected from G/L Entries", 'The reversal entry must not be marked as collected from G/L.');
        Assert.AreEqual(0D, ReversalEntry."Collect From Date", 'The reversal entry must not carry a collection start date.');
        Assert.AreEqual(0D, ReversalEntry."Collect To Date", 'The reversal entry must not carry a collection end date.');
    end;

    [Test]
    procedure ReverseEntryWithoutRelationsSucceeds()
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        OriginalEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reversing an entry that never collected general ledger entries is unaffected by the relation cleanup.
        // [GIVEN] A sustainability ledger entry that has no relation records
        Initialize();
        CreateSustLedgerEntry(SustLedgEntry, 'SUSTJNL', 'DEFAULT');
        OriginalEntryNo := SustLedgEntry."Entry No.";

        // [WHEN] The entry is reversed
        SustEntryReverseMgt.ReverseEntry(SustLedgEntry);

        // [THEN] The entry is reversed and no relation record exists for it
        SustLedgEntry.Get(OriginalEntryNo);
        Assert.IsTrue(SustLedgEntry."Reversed", 'The entry should be reversed.');
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", OriginalEntryNo);
        Assert.RecordIsEmpty(SustGLSustLedgerRel);
    end;

    // --- Helper Procedures ---

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sust. Reversal Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sust. Reversal Tests");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sust. Reversal Tests");
    end;

    local procedure GetReadyToPostAccountNo(): Code[20]
    var
        SustainabilityAccount: Record "Sustainability Account";
    begin
        // Reuse an existing ready-to-post account so the fixed codes created by the
        // library helper are not inserted twice within the same test transaction.
        SustainabilityAccount.SetRange("Account Type", SustainabilityAccount."Account Type"::Posting);
        SustainabilityAccount.SetRange(Blocked, false);
        SustainabilityAccount.SetRange("Direct Posting", true);
        SustainabilityAccount.SetFilter(Category, '<>%1', '');
        SustainabilityAccount.SetFilter(Subcategory, '<>%1', '');
        if SustainabilityAccount.FindFirst() then
            exit(SustainabilityAccount."No.");

        SustainabilityAccount := LibrarySustainability.GetAReadyToPostAccount();
        exit(SustainabilityAccount."No.");
    end;

    local procedure CreateSustLedgerEntry(var SustLedgEntry: Record "Sustainability Ledger Entry"; JournalTemplateName: Code[10]; BatchName: Code[10])
    var
        NextEntryNo: Integer;
    begin
        SustLedgEntry.SetCurrentKey("Entry No.");
        if SustLedgEntry.FindLast() then
            NextEntryNo := SustLedgEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        SustLedgEntry.Init();
        SustLedgEntry."Entry No." := NextEntryNo;
        SustLedgEntry."Account No." := GetReadyToPostAccountNo();
        SustLedgEntry."Posting Date" := WorkDate();
        SustLedgEntry."Document No." := CopyStr(Format(CreateGuid()), 1, 20);
        SustLedgEntry."Journal Template Name" := JournalTemplateName;
        SustLedgEntry."Journal Batch Name" := BatchName;
        SustLedgEntry."Emission CO2" := 42.5;
        SustLedgEntry."Emission CH4" := 3.2;
        SustLedgEntry."Emission N2O" := 1.1;
        SustLedgEntry."CO2e Emission" := 42.5 + 3.2 * 25 + 1.1 * 298;
        SustLedgEntry."Carbon Fee" := 15.75;
        SustLedgEntry.Insert(false);
    end;

    local procedure CreateSustLedgerEntryWithAllFields(var SustLedgEntry: Record "Sustainability Ledger Entry")
    var
        NextEntryNo: Integer;
    begin
        SustLedgEntry.SetCurrentKey("Entry No.");
        if SustLedgEntry.FindLast() then
            NextEntryNo := SustLedgEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        SustLedgEntry.Init();
        SustLedgEntry."Entry No." := NextEntryNo;
        SustLedgEntry."Account No." := GetReadyToPostAccountNo();
        SustLedgEntry."Posting Date" := WorkDate();
        SustLedgEntry."Document No." := CopyStr(Format(CreateGuid()), 1, 20);
        SustLedgEntry."Journal Template Name" := 'SUSTJNL';
        SustLedgEntry."Journal Batch Name" := 'DEFAULT';
        SustLedgEntry."Emission CO2" := 55.0;
        SustLedgEntry."Emission CH4" := 7.3;
        SustLedgEntry."Emission N2O" := 2.8;
        SustLedgEntry."CO2e Emission" := 120.0;
        SustLedgEntry."Carbon Fee" := 25.5;
        SustLedgEntry."Water Intensity" := 30.0;
        SustLedgEntry."Discharged Into Water" := 18.5;
        SustLedgEntry."Waste Intensity" := 12.0;
        SustLedgEntry."Energy Consumption" := 450.0;
        SustLedgEntry.Insert(false);
    end;

    local procedure VerifyReversalEntry(ReversalEntryNo: Integer; OriginalEntryNo: Integer; ExpectedCO2: Decimal)
    var
        ReversalEntry: Record "Sustainability Ledger Entry";
    begin
        ReversalEntry.Get(ReversalEntryNo);
        Assert.AreEqual(ExpectedCO2, ReversalEntry."Emission CO2", 'CO2 should be negated.');
        Assert.IsTrue(ReversalEntry."Reversed", 'Reversal entry should be marked as Reversed.');
        Assert.AreEqual(OriginalEntryNo, ReversalEntry."Reversed Entry No.",
            'Reversal entry should reference original entry.');
    end;

    local procedure PostGLEntry(EntryAmount: Decimal): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJournalTemplateCode: Code[10];
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        GenJournalTemplateCode := LibraryERM.SelectGenJnlTemplate();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateCode);
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
            GenJournalLine, GenJournalTemplateCode, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), EntryAmount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure LinkGLEntryToSustEntry(GLEntryNo: Integer; SustLedgerEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        GLEntry.Get(GLEntryNo);
        SustainabilityAccount.Get(GetReadyToPostAccountNo());
        SustGLSustLedgerRel.CreateRelation(GLEntry, SustLedgerEntryNo, SustainabilityAccount.Category);
    end;

    // --- Handler Functions ---

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Consume the success message
    end;
}
