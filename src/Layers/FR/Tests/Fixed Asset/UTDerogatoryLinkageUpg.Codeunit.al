// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134194 "UT Derogatory Linkage Upg."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        SourceDepreciationBookCode: Code[10];
        DerogatoryDepreciationBookCode: Code[10];

#if not CLEAN29
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DisabledFeatureFAJournalUsesOnlyLegacyRelationship()
    var
        DepreciationBook: Record "Depreciation Book";
        LegacyTaxDepreciationBook: Record "Depreciation Book";
        CentralTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        DisableAcceleratedDepreciationFeature();
        CreateDistinctRoutingSetup(
            DepreciationBook, LegacyTaxDepreciationBook, CentralTaxDepreciationBook,
            FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", LegacyTaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", CentralTaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(2, FALedgerEntry.Count(), 'The source and one legacy counterpart must be posted.');
        FALedgerEntry.SetRange("Depreciation Book Code", LegacyTaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'The legacy tax book must receive exactly one counterpart.');
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        FALedgerEntry.SetRange("Depreciation Book Code", CentralTaxDepreciationBook.Code);
        Assert.AreEqual(0, FALedgerEntry.Count(), 'Disabled routing must not invoke the central relationship.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EnabledFeatureFAJournalUsesOnlyCentralRelationship()
    var
        DepreciationBook: Record "Depreciation Book";
        LegacyTaxDepreciationBook: Record "Depreciation Book";
        CentralTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        EnableAcceleratedDepreciationFeature();
        CreateDistinctRoutingSetup(
            DepreciationBook, LegacyTaxDepreciationBook, CentralTaxDepreciationBook,
            FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", LegacyTaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", CentralTaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(2, FALedgerEntry.Count(), 'The source and one central counterpart must be posted.');
        FALedgerEntry.SetRange("Depreciation Book Code", LegacyTaxDepreciationBook.Code);
        Assert.AreEqual(0, FALedgerEntry.Count(), 'Enabled routing must not invoke the legacy relationship.');
        FALedgerEntry.SetRange("Depreciation Book Code", CentralTaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'The central tax book must receive exactly one counterpart.');
        FALedgerEntry.FindFirst();
        Assert.AreNotEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'The central counterpart must be linked.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;
#else
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Clean29FAJournalUsesCentralRelationship()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(2, FALedgerEntry.Count(), 'CLEAN29 must post the source and one central counterpart.');
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'CLEAN29 must use the central relationship.');
        FALedgerEntry.FindFirst();
        Assert.AreNotEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'The CLEAN29 counterpart must be linked.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        CounterpartReversalFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewCounterpartEntryNo: Integer;
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        PostLinkedFAEntry(
            SourceFALedgerEntry, CounterpartFALedgerEntry,
            FixedAsset."No.", DepreciationBook.Code, TaxDepreciationBook.Code);
        CreateFAReversalWithoutCounterpart(
            FAInsertLedgerEntry, SourceFALedgerEntry, CounterpartFALedgerEntry,
            ReversingFALedgerEntry, TaxDepreciationBook, DepreciationBook.Code);

        FAInsertLedgerEntry.InsertFARevEntryForDerog(
            1, NewCounterpartEntryNo, ReversingFALedgerEntry);

        Assert.AreNotEqual(0, NewCounterpartEntryNo, 'The FA overload must return the new counterpart reversal entry number.');
        CounterpartReversalFALedgerEntry.Get(NewCounterpartEntryNo);
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.TestField("Reversed by Entry No.", NewCounterpartEntryNo);
        CounterpartReversalFALedgerEntry.TestField("Reversed Entry No.", CounterpartFALedgerEntry."Entry No.");
        CounterpartReversalFALedgerEntry.TestField(
            "Derogatory Source Entry No.", ReversingFALedgerEntry."Entry No.");
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenanceReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartReversalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewCounterpartEntryNo: Integer;
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        PostLinkedMaintenanceEntry(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FixedAsset."No.", DepreciationBook.Code, TaxDepreciationBook.Code);
        CreateMaintenanceReversalWithoutCounterpart(
            FAInsertLedgerEntry, SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDepreciationBook, DepreciationBook.Code);

        FAInsertLedgerEntry.InsertMaintRevEntryForDerog(
            2, NewCounterpartEntryNo, ReversingMaintenanceLedgerEntry);

        Assert.AreNotEqual(0, NewCounterpartEntryNo, 'The maintenance overload must return the new counterpart reversal entry number.');
        CounterpartReversalMaintenanceLedgerEntry.Get(NewCounterpartEntryNo);
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.TestField("Reversed by Entry No.", NewCounterpartEntryNo);
        CounterpartReversalMaintenanceLedgerEntry.TestField(
            "Reversed Entry No.", CounterpartMaintenanceLedgerEntry."Entry No.");
        CounterpartReversalMaintenanceLedgerEntry.TestField(
            "Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry."Entry No.");
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneratedMirrorDoesNotRunDuplicateBookDispatcher()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        DuplicateDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        DuplicateFAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        DuplicateTemplateName: Code[10];
        DuplicateBatchName: Code[10];
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        CreateDuplicationTarget(DuplicateDepreciationBook, DuplicateTemplateName, DuplicateBatchName);
        CreateFADepreciationBook(FixedAsset."No.", DuplicateDepreciationBook.Code, FAPostingGroup.Code);
        FAJournalLine.Validate("Duplicate in Depreciation Book", DuplicateDepreciationBook.Code);
        FAJournalLine.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        DuplicateFAJournalLine.SetRange("Journal Template Name", DuplicateTemplateName);
        DuplicateFAJournalLine.SetRange("Journal Batch Name", DuplicateBatchName);
        DuplicateFAJournalLine.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(
            1, DuplicateFAJournalLine.Count(),
            'Only the source line may be dispatched to the configured duplication book.');
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'The generated mirror must still post exactly one counterpart.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PublicDerogatoryBuilderRejectsAmbiguousRelationship()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        SecondTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        SourceFAJournalLine: Record "FA Journal Line";
        NewFAJournalLine: Record "FA Journal Line";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
    begin
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        LibraryFixedAsset.CreateDepreciationBook(SecondTaxDepreciationBook);
        SecondTaxDepreciationBook."Derogatory Calc." := DepreciationBook.Code;
        SecondTaxDepreciationBook.Modify();
        SourceFAJournalLine."FA No." := FixedAsset."No.";
        SourceFAJournalLine."Depreciation Book Code" := DepreciationBook.Code;

        asserterror FAJnlPostBatch.MakeDerogatoryFAJnlLine(NewFAJournalLine, SourceFAJournalLine);

        Assert.ExpectedError('More than one derogatory depreciation book is configured for depreciation book');
    end;

#if not CLEAN29
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DisabledFeatureReversalTracksTemporaryConsistencyEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewFAEntryNo: Integer;
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        DisableAcceleratedDepreciationFeature();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FALedgerEntry.FindLast();

        FAInsertLedgerEntry.InsertReverseEntry(0, 1, FALedgerEntry."Entry No.", NewFAEntryNo, 0);

        // The feature-disabled legacy route must still register the reversed entry for the G/L consistency check.
        FAInsertLedgerEntry.CheckFAReverseEntry(FALedgerEntry);
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;
#endif
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NormalBookValueExcludesDerogatoryEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        AcquisitionAmount: Decimal;
        DerogatoryAmount: Decimal;
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        AcquisitionAmount := 1000;
        DerogatoryAmount := 300;
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::Derogatory, -DerogatoryAmount);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields("Book Value");
        Assert.AreEqual(
            AcquisitionAmount, FADepreciationBook."Book Value",
            'The derogatory entry must stay excluded from the normal book value.');
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Derogatory);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("Derogatory Excluded", true);
#if not CLEAN29
        FALedgerEntry.TestField("Exclude Derogatory", true);
#endif
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UniqueFAEntriesAreLinked()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(1, LinkedCount, 'One FA pair must be linked.');
        Assert.AreEqual(0, AmbiguousCount, 'The unique FA pair must not be ambiguous.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReversedFAEntriesAreLinked()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(10, SourceDepreciationBookCode, true, 100, 0);
        CreateFALedgerEntry(11, DerogatoryDepreciationBookCode, true, 200, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryFALedgerEntry.Get(11);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 10);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReversalOfReversalFAEntriesAreLinked()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(20, SourceDepreciationBookCode, true, 0, 100);
        CreateFALedgerEntry(21, DerogatoryDepreciationBookCode, true, 0, 200);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryFALedgerEntry.Get(21);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 20);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquidistantFAEntriesAreMarkedAmbiguous()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(10, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(9, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(11, DerogatoryDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        SourceFALedgerEntry.Get(10);
        SourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        Assert.AreEqual(0, LinkedCount, 'An ambiguous FA pair must not be linked.');
        Assert.AreEqual(1, AmbiguousCount, 'The ambiguous FA source must be counted.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingFAEntryIsNotLinked()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        SourceFALedgerEntry.Get(1);
        SourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", false);
        Assert.AreEqual(0, LinkedCount, 'A missing FA counterpart must not create a link.');
        Assert.AreEqual(1, MissingCount, 'The missing FA counterpart must be counted.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UniqueMaintenanceEntriesAreLinked()
    var
        DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);

        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryMaintenanceLedgerEntry.Get(2);
        DerogatoryMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(1, LinkedCount, 'One maintenance pair must be linked.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingLinkIsNotChangedByRepeatedProcessing()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 1;
        DerogatoryFALedgerEntry.Modify();

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(0, LinkedCount, 'Repeated processing must not create another link.');
    end;

    local procedure InitializeLinkageTestData()
    var
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        FALedgerEntry.DeleteAll();
        MaintenanceLedgerEntry.DeleteAll();
        DepreciationBook.ModifyAll("Derogatory Calc.", '');
        CreateDepreciationBooks();
    end;

    local procedure CreateDepreciationBooks()
    var
        SourceDepreciationBook: Record "Depreciation Book";
        DerogatoryDepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(SourceDepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(DerogatoryDepreciationBook);
        DerogatoryDepreciationBook."Derogatory Calc." := SourceDepreciationBook.Code;
        DerogatoryDepreciationBook.Modify();
        SourceDepreciationBookCode := SourceDepreciationBook.Code;
        DerogatoryDepreciationBookCode := DerogatoryDepreciationBook.Code;
    end;

#if not CLEAN29
    local procedure DisableAcceleratedDepreciationFeature()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if not FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then begin
            FeatureDataUpdateStatus."Feature Key" := AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey();
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus.Insert();
        end;
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
        FeatureDataUpdateStatus.Modify();
        Assert.IsFalse(AcceleratedDeprFeature.IsEnabled(), 'The test requires the legacy feature-disabled route.');
    end;

    local procedure EnableAcceleratedDepreciationFeature()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if not FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then begin
            FeatureDataUpdateStatus."Feature Key" := AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey();
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus.Insert();
        end;
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Enabled;
        FeatureDataUpdateStatus.Modify();
        Assert.IsTrue(AcceleratedDeprFeature.IsEnabled(), 'The test requires the centralized feature-enabled route.');
    end;

    local procedure CreateDistinctRoutingSetup(var DepreciationBook: Record "Depreciation Book"; var LegacyTaxDepreciationBook: Record "Depreciation Book"; var CentralTaxDepreciationBook: Record "Depreciation Book"; var FixedAsset: Record "Fixed Asset"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(LegacyTaxDepreciationBook);
        LegacyTaxDepreciationBook."Derogatory Calculation" := DepreciationBook.Code;
        LegacyTaxDepreciationBook.Modify();
        LibraryFixedAsset.CreateDepreciationBook(CentralTaxDepreciationBook);
        CentralTaxDepreciationBook."Derogatory Calc." := DepreciationBook.Code;
        CentralTaxDepreciationBook.Modify();
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
    end;
#endif

    // "FA Jnl.-Post Batch" commits, and the test framework rejects Commit under TransactionModel::AutoRollback
    // ("Tests cannot call the Commit function if TransactionModel property is set to AutoRollback."). The posting
    // tests therefore run with AutoCommit and restore the shared French feature state deterministically instead.
#if not CLEAN29
    local procedure CaptureFeatureStateIfRequired() PreviousFeatureStatus: Integer
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
            PreviousFeatureStatus := FeatureDataUpdateStatus."Feature Status".AsInteger();
    end;

    local procedure RestoreFeatureStateIfRequired(PreviousFeatureStatus: Integer)
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if not FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
            exit;
        FeatureDataUpdateStatus."Feature Status" := Enum::"Feature Status".FromInteger(PreviousFeatureStatus);
        FeatureDataUpdateStatus.Modify();
    end;
#else
    local procedure CaptureFeatureStateIfRequired() PreviousFeatureStatus: Integer
    begin
        PreviousFeatureStatus := 0;
    end;

    local procedure RestoreFeatureStateIfRequired(PreviousFeatureStatus: Integer)
    begin
        Assert.AreEqual(0, PreviousFeatureStatus, 'CLEAN29 has no French feature state to capture.');
    end;
#endif

    local procedure EnableCentralRoutingIfRequired()
    begin
#if not CLEAN29
        EnableAcceleratedDepreciationFeature();
#endif
    end;

    local procedure CreateCentralRoutingSetup(var DepreciationBook: Record "Depreciation Book"; var TaxDepreciationBook: Record "Depreciation Book"; var FixedAsset: Record "Fixed Asset"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(TaxDepreciationBook);
        TaxDepreciationBook."Derogatory Calc." := DepreciationBook.Code;
        TaxDepreciationBook.Modify();
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
    end;

    local procedure CreateDuplicationTarget(var DuplicateDepreciationBook: Record "Depreciation Book"; var DuplicateTemplateName: Code[10]; var DuplicateBatchName: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DuplicateDepreciationBook);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DuplicateDepreciationBook.Code, '');
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Modify(true);
        DuplicateTemplateName := FAJournalBatch."Journal Template Name";
        DuplicateBatchName := FAJournalBatch.Name;
    end;
    local procedure CreateFixedAssetWithPostingGroup(var FixedAsset: Record "Fixed Asset"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroupCode: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<5Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        CreateFAJournalLine(
            FAJournalLine, FANo, DepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", 100);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        if FAJournalBatch."No. Series" = '' then begin
            FAJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            FAJournalBatch.Modify(true);
        end;
        LibraryERM.CreateFAJournalLine(
            FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name,
            FAJournalLine."Document Type"::" ", FAPostingType, FANo, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure PostLinkedFAEntry(var SourceFALedgerEntry: Record "FA Ledger Entry"; var CounterpartFALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10]; TaxDepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(FAJournalLine, FANo, DepreciationBookCode);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        SourceFALedgerEntry.FindLast();
        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.FindFirst();
    end;

    local procedure PostLinkedMaintenanceEntry(var SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10]; TaxDepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        Maintenance: Record Maintenance;
    begin
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        CreateFAJournalLine(
            FAJournalLine, FANo, DepreciationBookCode,
            FAJournalLine."FA Posting Type"::Maintenance, 100);
        FAJournalLine.Validate("Maintenance Code", Maintenance.Code);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        SourceMaintenanceLedgerEntry.SetRange("FA No.", FANo);
        SourceMaintenanceLedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        SourceMaintenanceLedgerEntry.FindLast();
        CounterpartMaintenanceLedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        CounterpartMaintenanceLedgerEntry.SetRange(
            "Derogatory Source Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.FindFirst();
    end;

    local procedure CreateFAReversalWithoutCounterpart(var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; SourceFALedgerEntry: Record "FA Ledger Entry"; var CounterpartFALedgerEntry: Record "FA Ledger Entry"; var ReversingFALedgerEntry: Record "FA Ledger Entry"; var TaxDepreciationBook: Record "Depreciation Book"; SourceDepreciationBookCode: Code[10])
    var
        NewSourceReversalEntryNo: Integer;
    begin
        CounterpartFALedgerEntry."Derogatory Source Entry No." := 0;
        CounterpartFALedgerEntry.Modify();
        TaxDepreciationBook.Validate("Derogatory Calc.", '');
        TaxDepreciationBook.Modify(true);
        FAInsertLedgerEntry.InsertReverseEntry(
            0, 1, SourceFALedgerEntry."Entry No.", NewSourceReversalEntryNo, 0);
        ReversingFALedgerEntry.Get(NewSourceReversalEntryNo);
        TaxDepreciationBook.Validate("Derogatory Calc.", SourceDepreciationBookCode);
        TaxDepreciationBook.Modify(true);
        CounterpartFALedgerEntry."Derogatory Source Entry No." := SourceFALedgerEntry."Entry No.";
        CounterpartFALedgerEntry.Modify();
    end;

    local procedure CreateMaintenanceReversalWithoutCounterpart(var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var TaxDepreciationBook: Record "Depreciation Book"; SourceDepreciationBookCode: Code[10])
    var
        NewSourceReversalEntryNo: Integer;
    begin
        CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := 0;
        CounterpartMaintenanceLedgerEntry.Modify();
        TaxDepreciationBook.Validate("Derogatory Calc.", '');
        TaxDepreciationBook.Modify(true);
        FAInsertLedgerEntry.InsertReverseEntry(
            0, 2, SourceMaintenanceLedgerEntry."Entry No.", NewSourceReversalEntryNo, 0);
        ReversingMaintenanceLedgerEntry.Get(NewSourceReversalEntryNo);
        TaxDepreciationBook.Validate("Derogatory Calc.", SourceDepreciationBookCode);
        TaxDepreciationBook.Modify(true);
        CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := SourceMaintenanceLedgerEntry."Entry No.";
        CounterpartMaintenanceLedgerEntry.Modify();
    end;

    local procedure CreateFALedgerEntry(EntryNo: Integer; DepreciationBookCode: Code[10]; Reversed: Boolean; ReversedByEntryNo: Integer; ReversedEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := EntryNo;
        FALedgerEntry."FA No." := 'FA';
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
        FALedgerEntry.Amount := 100;
        FALedgerEntry."Document No." := 'DOC';
        FALedgerEntry."FA Posting Date" := WorkDate();
        FALedgerEntry."Posting Date" := WorkDate();
        FALedgerEntry."Document Date" := WorkDate();
        FALedgerEntry.Reversed := Reversed;
        FALedgerEntry."Reversed by Entry No." := ReversedByEntryNo;
        FALedgerEntry."Reversed Entry No." := ReversedEntryNo;
        FALedgerEntry.Insert();
    end;

    local procedure CreateMaintenanceLedgerEntry(EntryNo: Integer; DepreciationBookCode: Code[10])
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry."Entry No." := EntryNo;
        MaintenanceLedgerEntry."FA No." := 'FA';
        MaintenanceLedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        MaintenanceLedgerEntry.Amount := 100;
        MaintenanceLedgerEntry."Document No." := 'DOC';
        MaintenanceLedgerEntry."FA Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Document Date" := WorkDate();
        MaintenanceLedgerEntry.Insert();
    end;
}
