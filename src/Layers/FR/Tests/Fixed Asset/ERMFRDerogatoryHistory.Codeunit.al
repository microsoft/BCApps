codeunit 144048 "ERM FR Derogatory History"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AmbiguousHistoryErr: Label 'cannot be identified uniquely';

    [Test]
    procedure MissingFAHistoryFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked FA source without historical candidates cannot be reversed.
        Initialize();

        // [GIVEN] A marked source "S" has no historical counterpart.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        CounterpartEntry.Delete();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Matching fails without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure MultipleFAHistoryFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        ExtraEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Two matching historical FA candidates are ambiguous.
        Initialize();

        // [GIVEN] A marked source "S" has two matching historical counterparts.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := CounterpartEntry;
        ExtraEntry."Entry No." += 1;
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Ambiguous matching fails without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure CompetingFASourceFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        ExtraEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unlinked competing FA source prevents historical matching.
        Initialize();

        // [GIVEN] Two unlinked sources "S1" and "S2" match the same historical counterpart.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := SourceEntry;
        ExtraEntry."Entry No." := CounterpartEntry."Entry No." + 1;
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] Reversing "S1" attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Competing sources prevent reversal without changing entries or registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure ZeroTransactionFAHistoryFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        ExtraEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A zero-transaction FA candidate cannot disambiguate sources across transactions.
        Initialize();

        // [GIVEN] Sources "S1" and "S2" in different transactions match a zero-transaction counterpart.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := SourceEntry;
        ExtraEntry."Entry No." := CounterpartEntry."Entry No." + 1;
        ExtraEntry."Transaction No." += 1;
        CounterpartEntry."Transaction No." := 0;
        CounterpartEntry.Modify();
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] Reversing "S1" attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] The unknown transaction cannot disambiguate the source, and no entries or registers change.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure ReversedFAHistoryFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Already reversed FA history is not an available candidate.
        Initialize();

        // [GIVEN] The historical counterpart of marked source "S" is already reversed.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        CounterpartEntry.Reversed := true;
        CounterpartEntry."Reversed by Entry No." := SourceEntry."Entry No.";
        CounterpartEntry.Modify();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Reversed history is rejected without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure UnlinkedFAReversalOfReversalFailsAtomically()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A reversal chain must not fall back to unrelated unlinked FA history.
        Initialize();

        // [GIVEN] Marked source "S" is itself a reversal without a persisted counterpart link.
        CreateFAHistoryPair(SourceEntry, CounterpartEntry);
        SourceEntry."Reversed Entry No." := CounterpartEntry."Entry No.";
        SourceEntry.Modify();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := FALedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] The unlinked reversal chain is rejected without changing entries or registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, FALedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure MissingMaintenanceHistoryFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked maintenance source without historical candidates cannot be reversed.
        Initialize();

        // [GIVEN] A marked source "S" has no historical counterpart.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        CounterpartEntry.Delete();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Matching fails without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure MultipleMaintenanceHistoryFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        ExtraEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Two matching historical maintenance candidates are ambiguous.
        Initialize();

        // [GIVEN] A marked source "S" has two matching historical counterparts.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := CounterpartEntry;
        ExtraEntry."Entry No." += 1;
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Ambiguous matching fails without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure CompetingMaintenanceSourceFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        ExtraEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unlinked competing maintenance source prevents historical matching.
        Initialize();

        // [GIVEN] Two unlinked sources "S1" and "S2" match the same historical counterpart.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := SourceEntry;
        ExtraEntry."Entry No." := CounterpartEntry."Entry No." + 1;
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] Reversing "S1" attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Competing sources prevent reversal without changing entries or registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure ZeroTransactionMaintenanceHistoryFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        ExtraEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A zero-transaction maintenance candidate cannot disambiguate sources across transactions.
        Initialize();

        // [GIVEN] Sources "S1" and "S2" in different transactions match a zero-transaction counterpart.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        ExtraEntry := SourceEntry;
        ExtraEntry."Entry No." := CounterpartEntry."Entry No." + 1;
        ExtraEntry."Transaction No." += 1;
        CounterpartEntry."Transaction No." := 0;
        CounterpartEntry.Modify();
        ExtraEntry.Insert();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] Reversing "S1" attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] The unknown transaction cannot disambiguate the source, and no entries or registers change.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure ReversedMaintenanceHistoryFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Already reversed maintenance history is not an available candidate.
        Initialize();

        // [GIVEN] The historical counterpart of marked source "S" is already reversed.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        CounterpartEntry.Reversed := true;
        CounterpartEntry."Reversed by Entry No." := SourceEntry."Entry No.";
        CounterpartEntry.Modify();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] Reversed history is rejected without changing the source or adding entries and registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    [Test]
    procedure UnlinkedMaintenanceReversalOfReversalFailsAtomically()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FARegister: Record "FA Register";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        SourceBefore: Text;
        EntryCount: Integer;
        RegisterCount: Integer;
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A reversal chain must not fall back to unrelated unlinked maintenance history.
        Initialize();

        // [GIVEN] Marked source "S" is itself a reversal without a persisted counterpart link.
        CreateMaintenanceHistoryPair(SourceEntry, CounterpartEntry);
        SourceEntry."Reversed Entry No." := CounterpartEntry."Entry No.";
        SourceEntry.Modify();
        Commit();
        SourceBefore := Format(SourceEntry);
        EntryCount := MaintenanceLedgerEntry.Count();
        RegisterCount := FARegister.Count();
        EnableFeatureInReversalTransaction();

        // [WHEN] The source reversal attempts historical matching.
        asserterror FAInsertLedgerEntry.InsertReverseEntry(0, 2, SourceEntry."Entry No.", NewEntryNo, 0);

        // [THEN] The unlinked reversal chain is rejected without changing entries or registers.
        Assert.ExpectedError(AmbiguousHistoryErr);
        Assert.ExpectedErrorCode('Dialog');
        SourceEntry.Get(SourceEntry."Entry No.");
        Assert.AreEqual(SourceBefore, Format(SourceEntry), 'The rejected source must be unchanged.');
        Assert.AreEqual(EntryCount, MaintenanceLedgerEntry.Count(), 'Rejected matching must not insert ledger entries.');
        Assert.AreEqual(RegisterCount, FARegister.Count(), 'Rejected matching must not insert registers.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM FR Derogatory History");
    end;

    local procedure EnableFeatureInReversalTransaction()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if not FeatureDataUpdateStatus.Get('AcceleratedDepreciation', CompanyName()) then begin
            FeatureDataUpdateStatus."Feature Key" := 'AcceleratedDepreciation';
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus.Insert();
        end;
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Enabled;
        FeatureDataUpdateStatus.Modify();
    end;

    local procedure CreateHistoricalBooks(var FixedAsset: Record "Fixed Asset"; var SourceBook: Record "Depreciation Book"; var CounterpartBook: Record "Depreciation Book")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(SourceBook);
        LibraryFixedAsset.CreateDepreciationBook(CounterpartBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", SourceBook.Code);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", CounterpartBook.Code);
    end;

    local procedure CreateFAHistoryPair(var SourceEntry: Record "FA Ledger Entry"; var CounterpartEntry: Record "FA Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        SourceBook: Record "Depreciation Book";
        CounterpartBook: Record "Depreciation Book";
        LastEntry: Record "FA Ledger Entry";
    begin
        CreateHistoricalBooks(FixedAsset, SourceBook, CounterpartBook);
        SourceEntry."Entry No." := LastEntry.GetLastEntryNo() + 1;
        SourceEntry."FA No." := FixedAsset."No.";
        SourceEntry."Depreciation Book Code" := SourceBook.Code;
        SourceEntry."FA Posting Group" := FixedAsset."FA Posting Group";
        SourceEntry."FA Posting Date" := WorkDate();
        SourceEntry."Posting Date" := WorkDate();
        SourceEntry."Document No." := 'HISTORY';
        SourceEntry."Transaction No." := 100;
        SourceEntry.Amount := 100;
        SourceEntry."Legacy Derogatory Ambiguous" := true;
        SourceEntry.Insert();
        CounterpartEntry := SourceEntry;
        CounterpartEntry."Entry No." += 1;
        CounterpartEntry."Depreciation Book Code" := CounterpartBook.Code;
        CounterpartEntry."Legacy Derogatory Ambiguous" := false;
        CounterpartEntry.Insert();
    end;

    local procedure CreateMaintenanceHistoryPair(var SourceEntry: Record "Maintenance Ledger Entry"; var CounterpartEntry: Record "Maintenance Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        SourceBook: Record "Depreciation Book";
        CounterpartBook: Record "Depreciation Book";
        LastEntry: Record "Maintenance Ledger Entry";
    begin
        CreateHistoricalBooks(FixedAsset, SourceBook, CounterpartBook);
        SourceEntry."Entry No." := LastEntry.GetLastEntryNo() + 1;
        SourceEntry."FA No." := FixedAsset."No.";
        SourceEntry."Depreciation Book Code" := SourceBook.Code;
        SourceEntry."FA Posting Group" := FixedAsset."FA Posting Group";
        SourceEntry."FA Posting Date" := WorkDate();
        SourceEntry."Posting Date" := WorkDate();
        SourceEntry."Document No." := 'HISTORY';
        SourceEntry."Transaction No." := 100;
        SourceEntry.Amount := 100;
        SourceEntry."Legacy Derogatory Ambiguous" := true;
        SourceEntry.Insert();
        CounterpartEntry := SourceEntry;
        CounterpartEntry."Entry No." += 1;
        CounterpartEntry."Depreciation Book Code" := CounterpartBook.Code;
        CounterpartEntry."Legacy Derogatory Ambiguous" := false;
        CounterpartEntry.Insert();
    end;
}
