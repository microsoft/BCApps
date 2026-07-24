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
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        SelectionFilter: Record "Sustainability Ledger Entry";
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
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        SelectionFilter: Record "Sustainability Ledger Entry";
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
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        SelectionFilter: Record "Sustainability Ledger Entry";
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

    // --- Helper Procedures ---

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
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
