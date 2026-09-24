// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134194 "UT Derogatory Linkage Upg."
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SourceDepreciationBookCode: Code[10];
        DerogatoryDepreciationBookCode: Code[10];
        IsInitialized: Boolean;
        TestBodyCompleted: Boolean;
        TestBodyCompletedErr: Label 'The test body ran to completion.';
        AmbiguousHistoricalCounterpartErr: Label 'The historical derogatory counterpart for source entry %1 cannot be identified uniquely.', Comment = '%1 - source entry number';
        SimulatedMigrationFailureErr: Label 'Simulated failure after accelerated depreciation migration.';
#if not CLEAN30
        SimulatedBodyFailureErr: Label 'Simulated failure after the test body toggled the French feature state.';
#endif

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DisabledFeatureFAJournalUsesOnlyLegacyRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Disabled central routing uses only the legacy FA journal relationship
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] An FA journal is posted with central routing disabled
        asserterror
        begin
            DisabledFeatureFAJournalBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EnabledFeatureFAJournalUsesOnlyCentralRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Enabled central routing uses only the central FA journal relationship
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] An FA journal is posted with central routing enabled
        asserterror
        begin
            EnabledFeatureFAJournalBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;
#else
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Clean30FAJournalUsesCentralRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] CLEAN30 FA journal posting uses the central relationship
        Initialize();

        // [GIVEN] The current feature compatibility state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] An FA journal is posted in CLEAN30
        asserterror begin
            Clean30FAJournalBody();
            CompleteTestBody();
        end;

        // [THEN] The compatibility state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The FA reversal compatibility overload creates a linked counterpart
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] The FA reversal compatibility overload runs
        asserterror
        begin
            FAReversalOverloadBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenanceReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The maintenance reversal compatibility overload creates a linked counterpart
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] The maintenance reversal compatibility overload runs
        asserterror
        begin
            MaintenanceReversalOverloadBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneratedMirrorDoesNotRunDuplicateBookDispatcher()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A generated mirror does not invoke the duplicate-book dispatcher
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] A source configured for mirroring and duplication is posted
        asserterror
        begin
            GeneratedMirrorDuplicationBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The public derogatory builder rejects an ambiguous book relationship
        Initialize();

        // [GIVEN] Two tax books related to the same normal depreciation book
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        LibraryFixedAsset.CreateDepreciationBook(SecondTaxDepreciationBook);
        SecondTaxDepreciationBook."Derogatory Calc." := DepreciationBook.Code;
        SecondTaxDepreciationBook.Modify();
        SourceFAJournalLine."FA No." := FixedAsset."No.";
        SourceFAJournalLine."Depreciation Book Code" := DepreciationBook.Code;

        // [WHEN] The public builder attempts to create a counterpart
        asserterror FAJnlPostBatch.MakeDerogatoryFAJnlLine(NewFAJournalLine, SourceFAJournalLine);

        // [THEN] The ambiguous relationship is reported
        Assert.ExpectedError('More than one derogatory depreciation book is configured for depreciation book');
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DisabledFeatureReversalTracksTemporaryConsistencyEntry()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Disabled central routing tracks temporary FA reversal consistency entries
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] An FA reversal is posted with central routing disabled
        asserterror
        begin
            DisabledFeatureReversalBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;
#endif
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NormalBookValueExcludesDerogatoryEntry()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Normal book value excludes the derogatory counterpart entry
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] Normal book value is calculated after derogatory posting
        asserterror
        begin
            NormalBookValueBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SalvageCounterpartReversalKeepsReversalSourceCode()
    var
        PreviousFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A salvage counterpart reversal keeps its reversal source code
        Initialize();

        // [GIVEN] The current accelerated depreciation feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] A salvage counterpart is reversed
        asserterror
        begin
            SalvageReversalSourceCodeBody();
            CompleteTestBody();
        end;

        // [THEN] The original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedTestBodyRestoresFeatureState()
    var
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
        PreviousFeatureStatus: Integer;
        BaselineFeatureStatus: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A failed test body restores the accelerated depreciation feature state
        Initialize();

        // [GIVEN] A captured feature state and a disabled feature baseline
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        DisableAcceleratedDepreciationFeature();
        Commit();
        BaselineFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] The test body changes feature state and fails
        asserterror
        begin
            SimulatedFailureBody();
            CompleteTestBody();
        end;
        asserterror RestoreFeatureStateAfterTestBody(BaselineFeatureStatus);

        // [THEN] The baseline state survives the rethrown failure
        Assert.IsFalse(
            AcceleratedDeprFeature.IsEnabled(),
            'The failed test body must not leave the toggled French feature state committed.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;
#endif
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A unique FA ledger pair is linked
        Initialize();

        // [GIVEN] One matching source and derogatory FA ledger entry
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The derogatory entry links to the source without ambiguity
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consistent reversed FA ledger pairs are linked
        Initialize();

        // [GIVEN] Matching FA ledger entries in a reversal chain
        InitializeLinkageTestData();
        CreateFALedgerEntry(10, SourceDepreciationBookCode, true, 100, 0);
        CreateFALedgerEntry(11, DerogatoryDepreciationBookCode, true, 200, 0);
        CreateFALedgerEntry(100, SourceDepreciationBookCode, true, 0, 10);
        CreateFALedgerEntry(200, DerogatoryDepreciationBookCode, true, 0, 11);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Both original and reversal counterparts link to their sources
        DerogatoryFALedgerEntry.Get(11);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 10);
        DerogatoryFALedgerEntry.Get(200);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 100);
        Assert.AreEqual(2, LinkedCount, 'Both entries in the consistent FA reversal chain must be linked.');
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] FA reversals of reversals retain their derogatory linkage
        Initialize();

        // [GIVEN] Matching FA entries whose reversal references point to later entries
        InitializeLinkageTestData();
        CreateFALedgerEntry(20, SourceDepreciationBookCode, true, 0, 100);
        CreateFALedgerEntry(21, DerogatoryDepreciationBookCode, true, 0, 200);
        CreateFALedgerEntry(100, SourceDepreciationBookCode, true, 20, 0);
        CreateFALedgerEntry(200, DerogatoryDepreciationBookCode, true, 21, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The derogatory reversal links to the matching source reversal
        DerogatoryFALedgerEntry.Get(21);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 20);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CrossedFAReversalChainsAreNotLinked()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Crossed FA reversal chains are not linked
        Initialize();

        // [GIVEN] Shape-compatible FA entries from different reversal chains
        InitializeLinkageTestData();
        CreateFALedgerEntry(10, 'FA1', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, true, 100, 0);
        CreateFALedgerEntry(11, 'FA1', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, true, 201, 0);
        CreateFALedgerEntry(100, 'FA1', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, true, 0, 10);
        CreateFALedgerEntry(21, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, true, 201, 0);
        CreateFALedgerEntry(201, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, true, 0, 21);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] No cross-chain link is created
        DerogatoryFALedgerEntry.Get(11);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.AreEqual(0, LinkedCount, 'Shape-compatible entries from crossed FA reversal chains must not be linked.');
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Equidistant FA counterparts mark the source as ambiguous
        Initialize();

        // [GIVEN] One FA source with two equally distant matching counterparts
        InitializeLinkageTestData();
        CreateFALedgerEntry(10, 'FA2', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(9, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(11, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The source is ambiguous and remains unlinked
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An FA source without a counterpart remains unlinked
        Initialize();

        // [GIVEN] An FA source entry without a derogatory counterpart
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The source is counted as missing and not ambiguous
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A unique maintenance ledger pair is linked
        Initialize();

        // [GIVEN] One matching source and derogatory maintenance entry
        InitializeLinkageTestData();
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);

        // [WHEN] Maintenance ledger entries are linked
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The derogatory maintenance entry links to its source
        DerogatoryMaintenanceLedgerEntry.Get(2);
        DerogatoryMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(1, LinkedCount, 'One maintenance pair must be linked.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CrossedMaintenanceReversalChainsAreNotLinked()
    var
        DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Crossed maintenance reversal chains are not linked
        Initialize();

        // [GIVEN] Shape-compatible maintenance entries from different reversal chains
        InitializeLinkageTestData();
        CreateMaintenanceLedgerEntry(10, SourceDepreciationBookCode, 'M1', 0, true, 100, 0);
        CreateMaintenanceLedgerEntry(11, DerogatoryDepreciationBookCode, 'M1', 0, true, 201, 0);
        CreateMaintenanceLedgerEntry(100, SourceDepreciationBookCode, 'M1', 0, true, 0, 10);
        CreateMaintenanceLedgerEntry(21, DerogatoryDepreciationBookCode, 'M2', 0, true, 201, 0);
        CreateMaintenanceLedgerEntry(201, DerogatoryDepreciationBookCode, 'M2', 0, true, 0, 21);

        // [WHEN] Maintenance ledger entries are linked
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] No cross-chain link is created
        DerogatoryMaintenanceLedgerEntry.Get(11);
        DerogatoryMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.AreEqual(0, LinkedCount, 'Shape-compatible entries from crossed maintenance reversal chains must not be linked.');
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reprocessing does not change an established FA link
        Initialize();

        // [GIVEN] An FA source and counterpart with an established link
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 1;
        DerogatoryFALedgerEntry.Modify();

        // [WHEN] FA linkage is processed again
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The established link remains and no new link is counted
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(0, LinkedCount, 'Repeated processing must not create another link.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrueRepeatedExecutionMakesNoFurtherChanges()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
        FALedgerEntryCount: Integer;
        MaintenanceLedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeated linkage execution makes no further ledger changes
        Initialize();

        // [GIVEN] Unlinked FA and maintenance source-counterpart pairs
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);
        FALedgerEntryCount := FALedgerEntry.Count();
        MaintenanceLedgerEntryCount := MaintenanceLedgerEntry.Count();

        // [WHEN] FA and maintenance linkage runs twice
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        Assert.AreEqual(
            FALedgerEntryCount, FALedgerEntry.Count(),
            'The first linkage pass must not change the total FA ledger row count.');
        Assert.AreEqual(
            MaintenanceLedgerEntryCount, MaintenanceLedgerEntry.Count(),
            'The first linkage pass must not change the total maintenance ledger row count.');
        LinkedCount := 0;
        AmbiguousCount := 0;
        MissingCount := 0;

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        Assert.AreEqual(
            FALedgerEntryCount, FALedgerEntry.Count(),
            'The repeated linkage pass must not change the total FA ledger row count.');
        Assert.AreEqual(
            MaintenanceLedgerEntryCount, MaintenanceLedgerEntry.Count(),
            'The repeated linkage pass must not change the total maintenance ledger row count.');

        // [THEN] The second pass preserves links, counts, and ledger row counts
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        DerogatoryMaintenanceLedgerEntry.Get(2);
        DerogatoryMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(0, LinkedCount, 'A true second pass must not create another link.');
        Assert.AreEqual(0, AmbiguousCount, 'A true second pass must not change ambiguity markers.');
        Assert.AreEqual(0, MissingCount, 'A true second pass must not recount resolved sources.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LinkageChangesNoAccountingAmounts()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
        SourceFAAmount: Decimal;
        DerogatoryFAAmount: Decimal;
        SourceMaintenanceAmount: Decimal;
        DerogatoryMaintenanceAmount: Decimal;
        FALedgerEntryCount: Integer;
        MaintenanceLedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Linkage changes no FA or maintenance accounting amounts
        Initialize();

        // [GIVEN] FA and maintenance pairs with captured amounts and row counts
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);
        SourceFALedgerEntry.Get(1);
        DerogatoryFALedgerEntry.Get(2);
        SourceMaintenanceLedgerEntry.Get(1);
        DerogatoryMaintenanceLedgerEntry.Get(2);
        SourceFAAmount := SourceFALedgerEntry.Amount;
        DerogatoryFAAmount := DerogatoryFALedgerEntry.Amount;
        SourceMaintenanceAmount := SourceMaintenanceLedgerEntry.Amount;
        DerogatoryMaintenanceAmount := DerogatoryMaintenanceLedgerEntry.Amount;
        FALedgerEntryCount := SourceFALedgerEntry.Count();
        MaintenanceLedgerEntryCount := SourceMaintenanceLedgerEntry.Count();

        // [WHEN] FA and maintenance entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Ledger row counts and accounting amounts remain unchanged
        Assert.AreEqual(
            FALedgerEntryCount, SourceFALedgerEntry.Count(),
            'Linkage must not change the total FA ledger row count.');
        Assert.AreEqual(
            MaintenanceLedgerEntryCount, SourceMaintenanceLedgerEntry.Count(),
            'Linkage must not change the total maintenance ledger row count.');
        SourceFALedgerEntry.Get(1);
        DerogatoryFALedgerEntry.Get(2);
        SourceMaintenanceLedgerEntry.Get(1);
        DerogatoryMaintenanceLedgerEntry.Get(2);
        SourceFALedgerEntry.TestField(Amount, SourceFAAmount);
        DerogatoryFALedgerEntry.TestField(Amount, DerogatoryFAAmount);
        SourceMaintenanceLedgerEntry.TestField(Amount, SourceMaintenanceAmount);
        DerogatoryMaintenanceLedgerEntry.TestField(Amount, DerogatoryMaintenanceAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoSourcesCompetingForOneCandidateAreBothMarkedAmbiguous()
    var
        FirstSourceFALedgerEntry: Record "FA Ledger Entry";
        SecondSourceFALedgerEntry: Record "FA Ledger Entry";
        ContestedCandidateFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] RISK-005 Two sources competing for one counterpart are both ambiguous
        Initialize();

        // [GIVEN] Two otherwise-identical sources that match the same counterpart
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, DerogatoryDepreciationBookCode, false, 0, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Both sources are ambiguous and neither claims the counterpart
        FirstSourceFALedgerEntry.Get(1);
        FirstSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        SecondSourceFALedgerEntry.Get(2);
        SecondSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        ContestedCandidateFALedgerEntry.Get(3);
        ContestedCandidateFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.AreEqual(0, LinkedCount, 'A contested candidate must not create any link.');
        Assert.AreEqual(2, AmbiguousCount, 'Both competing sources must be marked ambiguous.');
        Assert.AreEqual(0, MissingCount, 'A contested source is ambiguous, not missing.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceCodeDistinguishesOtherwiseIdenticalCandidates()
    var
        RightMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        WrongMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Maintenance code distinguishes otherwise identical counterparts
        Initialize();

        // [GIVEN] A closer counterpart with the wrong code and a farther counterpart with the matching code
        InitializeLinkageTestData();
        CreateMaintenanceLedgerEntry(100, SourceDepreciationBookCode, 'MC1');
        CreateMaintenanceLedgerEntry(102, DerogatoryDepreciationBookCode, 'MC2');
        CreateMaintenanceLedgerEntry(250, DerogatoryDepreciationBookCode, 'MC1');

        // [WHEN] Maintenance ledger entries are linked
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Only the counterpart with the matching maintenance code is linked
        RightMaintenanceLedgerEntry.Get(250);
        RightMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 100);
        WrongMaintenanceLedgerEntry.Get(102);
        WrongMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.AreEqual(1, LinkedCount, 'Exactly one maintenance pair must be linked by matching maintenance code.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AutomaticDepreciationSourceWithAcquisitionSiblingIsLinked()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Automatic depreciation links despite an acquisition-cost sibling
        Initialize();

        // [GIVEN] An automatic depreciation source, acquisition sibling, and matching counterpart
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, 'FA', SourceDepreciationBookCode, true, 500, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, 'FA', SourceDepreciationBookCode, false, 500, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(3, 'FA', DerogatoryDepreciationBookCode, false, 500, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The depreciation counterpart links to the depreciation source
        DerogatoryFALedgerEntry.Get(3);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(1, LinkedCount, 'The automatic depreciation source with an Acquisition Cost sibling must be linked.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CanceledAssetIdentityLinksFAEntryToOriginalAssetCounterpart()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A canceled asset identity links to its original FA counterpart
        Initialize();

        // [GIVEN] A source entry and a counterpart canceled from the source fixed asset
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, 'FA1', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateCanceledFALedgerEntry(2, DerogatoryDepreciationBookCode, 'FA1');

        // [WHEN] FA ledger entries are linked
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] The canceled counterpart links through the original fixed asset identity
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(1, LinkedCount, 'A canceled-asset counterpart must resolve identity via "Canceled from FA No.".');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PartialRerunPreservesEstablishedLinksAndLinksNewPairs()
    var
        EstablishedCounterpartFALedgerEntry: Record "FA Ledger Entry";
        NewCounterpartFALedgerEntry: Record "FA Ledger Entry";
        FirstContestSourceFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A partial rerun preserves established links and links new pairs
        Initialize();

        // [GIVEN] One unique pair and one ambiguous source processed on the first pass
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(10, 'FA2', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(9, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(11, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        Assert.AreEqual(1, LinkedCount, 'First pass must link the unique pair.');
        Assert.AreEqual(1, AmbiguousCount, 'First pass must mark the equidistant source ambiguous.');

        // [GIVEN] A new unique pair added after the first pass
        CreateFALedgerEntry(20, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(21, DerogatoryDepreciationBookCode, false, 0, 0);

        LinkedCount := 0;
        AmbiguousCount := 0;
        MissingCount := 0;

        // [WHEN] FA linkage is rerun
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Established outcomes remain and only the new pair is linked
        EstablishedCounterpartFALedgerEntry.Get(2);
        EstablishedCounterpartFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        NewCounterpartFALedgerEntry.Get(21);
        NewCounterpartFALedgerEntry.TestField("Derogatory Source Entry No.", 20);
        FirstContestSourceFALedgerEntry.Get(10);
        FirstContestSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        Assert.AreEqual(1, LinkedCount, 'Second pass must link only the newly added unique pair.');
        Assert.AreEqual(0, AmbiguousCount, 'Second pass must not re-flag an already-ambiguous source.');
        Assert.AreEqual(0, MissingCount, 'Second pass must not miscount an already-resolved source.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FARetryKeepsPreviouslyAmbiguousSourcesAsCompetitors()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unresolved source still competes for a transaction-zero counterpart on retry
        Initialize();

        // [GIVEN] Source S1 matches both T1 in transaction 100 and T0 in transaction zero
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 100,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 100,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(3, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        VerifyLinkageCounts(0, 1, 0, LinkedCount, AmbiguousCount, MissingCount);

        // [GIVEN] New source S2 in transaction 200 can only match T0
        CreateFALedgerEntry(4, FixedAsset."No.", SourceDepreciationBookCode, false, 200,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        Clear(LinkedCount);
        Clear(AmbiguousCount);
        Clear(MissingCount);

        // [WHEN] Linkage is retried without clearing the ambiguity marker on S1
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] S1 and S2 remain ambiguous, neither counterpart is linked, and only S2 is counted
        VerifyAmbiguousFARetry();
        VerifyLinkageCounts(0, 1, 0, LinkedCount, AmbiguousCount, MissingCount);
        Clear(AmbiguousCount);

        // [WHEN] The unchanged graph is processed again
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Existing ambiguous outcomes are preserved without being recounted
        VerifyAmbiguousFARetry();
        VerifyLinkageCounts(0, 0, 0, LinkedCount, AmbiguousCount, MissingCount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceRetryKeepsPreviouslyAmbiguousSourcesAsCompetitors()
    var
        FixedAsset: Record "Fixed Asset";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unresolved maintenance source still competes for a transaction-zero counterpart on retry
        Initialize();

        // [GIVEN] Source S1 matches both T1 in transaction 100 and T0 in transaction zero
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateHistoricalMaintenanceEntry(1, FixedAsset."No.", SourceDepreciationBookCode, 100);
        CreateHistoricalMaintenanceEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, 100);
        CreateHistoricalMaintenanceEntry(3, FixedAsset."No.", DerogatoryDepreciationBookCode, 0);
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        VerifyLinkageCounts(0, 1, 0, LinkedCount, AmbiguousCount, MissingCount);

        // [GIVEN] New source S2 in transaction 200 can only match T0
        CreateHistoricalMaintenanceEntry(4, FixedAsset."No.", SourceDepreciationBookCode, 200);
        Clear(LinkedCount);
        Clear(AmbiguousCount);
        Clear(MissingCount);

        // [WHEN] Linkage is retried without clearing the ambiguity marker on S1
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] S1 and S2 remain ambiguous, neither counterpart is linked, and only S2 is counted
        VerifyAmbiguousMaintenanceRetry();
        VerifyLinkageCounts(0, 1, 0, LinkedCount, AmbiguousCount, MissingCount);
        Clear(AmbiguousCount);

        // [WHEN] The unchanged graph is processed again
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Existing ambiguous outcomes are preserved without being recounted
        VerifyAmbiguousMaintenanceRetry();
        VerifyLinkageCounts(0, 0, 0, LinkedCount, AmbiguousCount, MissingCount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StandaloneLinkageWaitsForAcceleratedDepreciationMigration()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Standalone linkage waits for accelerated depreciation migration
        Initialize();

        // [GIVEN] A configured unlinked pair without the accelerated depreciation migration tag
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();

        // [WHEN] The standalone linkage upgrade runs
        UpgradeDerogatoryLinkage.RunStandaloneUpgrade();

        // [THEN] No linkage data or tags change
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'Standalone linkage must not set the original tag before accelerated depreciation migration.');
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'Standalone linkage must not set the corrective tag before accelerated depreciation migration.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StandaloneLinkageIgnoresPartialTargetRelationships()
    var
        SecondSourceDepreciationBook: Record "Depreciation Book";
        SecondDerogatoryDepreciationBook: Record "Depreciation Book";
        FirstDerogatoryFALedgerEntry: Record "FA Ledger Entry";
        SecondDerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Standalone linkage ignores a partially migrated target configuration
        Initialize();

        // [GIVEN] One W1 relationship and another relationship present only in the legacy field
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateDepreciationBook(SecondSourceDepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(SecondDerogatoryDepreciationBook);
        SetLegacyDerogatoryCalculation(SecondDerogatoryDepreciationBook.Code, SecondSourceDepreciationBook.Code);
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, 'FA2', SecondSourceDepreciationBook.Code, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(4, 'FA2', SecondDerogatoryDepreciationBook.Code, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();

        // [WHEN] The standalone linkage upgrade runs
        UpgradeDerogatoryLinkage.RunStandaloneUpgrade();

        // [THEN] Neither relationship is processed or tagged
        FirstDerogatoryFALedgerEntry.Get(2);
        FirstDerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        SecondDerogatoryFALedgerEntry.Get(4);
        SecondDerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'A partial target configuration must not set the original linkage tag.');
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'A partial target configuration must not set the corrective linkage tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RunAfterRelationshipTransferRepairsExistingOriginalTag()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Sequenced linkage repairs an existing original tag
        Initialize();

        // [GIVEN] An unlinked pair with only the original linkage tag
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        // [WHEN] Sequenced linkage runs
        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

        // [THEN] The corrective rebuild links the pair and completes its tag
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'Sequenced linkage must route an existing original tag through corrective recovery.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunAfterRelationshipTransferLinksAndSetsTagWhenNotYetRun()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Relationship-transfer linkage links entries and sets its upgrade tag
        Initialize();

        // [GIVEN] An unlinked FA pair without the linkage upgrade tag
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();

        // [WHEN] Relationship-transfer linkage runs
        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

        // [THEN] The pair is linked and the upgrade tag is set
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'The linkage upgrade tag must be set after a successful run.');
    end;

#if not CLEAN30
    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FeatureEnableWithIndirectLedgerModifyPermissions()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A feature administrator with only indirect ledger modification can migrate history
        Initialize();

        // [GIVEN] Legacy relationship and exclusion data with unlinked FA and maintenance pairs
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 0,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        FALedgerEntry.Get(1);
        SetMigrationFieldValues(FALedgerEntry.RecordId(), 10800, FALedgerEntry.FieldNo("Derogatory Excluded"), true, false);
        CreateHistoricalMaintenanceEntry(1, FixedAsset."No.", SourceDepreciationBookCode, 0);
        CreateHistoricalMaintenanceEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, 0);
        ClearMigrationTags();
        GetFeatureDataUpdateStatus(FeatureDataUpdateStatus);

        // [GIVEN] Standard non-SUPER FA setup, edit, feature-management, and task-log permissions
        Assert.IsTrue(LibraryLowerPermissions.CanLowerPermission(), 'The test runner must enforce the restrictive permission context.');
        LibraryLowerPermissions.PushPermissionSetWithoutDefaults('D365 FA, Edit');
        LibraryLowerPermissions.AddPermissionSet('D365 FA, Setup');
        LibraryLowerPermissions.AddPermissionSet('D365 Basic');
        LibraryLowerPermissions.AddPermissionSet('Feature Mgt. - Admin');
        LibraryLowerPermissions.AddPermissionSet('Job Queue - Admin');

        // [WHEN] Feature activation migrates the fields and links both ledgers
        AcceleratedDeprFeature.UpdateData(FeatureDataUpdateStatus);
        AcceleratedDeprFeature.AfterUpdate(FeatureDataUpdateStatus);

        // [THEN] The legacy fields, both historical links, and completion tags are persisted
        VerifyMigrationWithIndirectLedgerPermissions();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FeatureEnableMigratesRelationshipBeforeLinkage()
    var
        DepreciationBook: Record "Depreciation Book";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Feature enablement migrates relationships before linking history
        Initialize();

        // [GIVEN] A legacy relationship, matching history, and no migration tags
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        GetFeatureDataUpdateStatus(FeatureDataUpdateStatus);

        // [WHEN] Feature enablement migrates data and the completed upgrade is executed twice
        AcceleratedDeprFeature.UpdateData(FeatureDataUpdateStatus);
        AcceleratedDeprFeature.AfterUpdate(FeatureDataUpdateStatus);
        UpgradeDerogatoryLinkage.RunStandaloneUpgrade();
        UpgradeDerogatoryLinkage.RunStandaloneUpgrade();

        // [THEN] The relationship, link, and completed tag state remain valid
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        DepreciationBook.TestField("Derogatory Calc.", SourceDepreciationBookCode);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), CompanyName()),
            'Feature enablement must set the accelerated depreciation migration tag after success.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'Feature enablement must set the original linkage tag after success.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'The completed standalone recovery state must remain set on repeated execution.');
    end;
#else
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Clean30MigratesRelationshipBeforeLinkage()
    var
        DepreciationBook: Record "Depreciation Book";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeAcceleratedDepr: Codeunit "Upgrade Accelerated Depr.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] CLEAN30 migrates relationships before linking history
        Initialize();

        // [GIVEN] A legacy relationship, matching history, and no migration tags
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();

        // [WHEN] CLEAN30 migration executes twice
        UpgradeAcceleratedDepr.UpgradeAcceleratedDepr();
        UpgradeAcceleratedDepr.UpgradeAcceleratedDepr();

        // [THEN] The relationship and link are migrated once and both tags are set
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        DepreciationBook.TestField("Derogatory Calc.", SourceDepreciationBookCode);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), CompanyName()),
            'CLEAN30 migration must set the accelerated depreciation migration tag after success.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'CLEAN30 migration must set the original linkage tag after success.');
    end;
#endif

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FeatureEnableFailureRollsBackRelationshipLinkAndTags()
    var
        DepreciationBook: Record "Depreciation Book";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A feature-enable failure rolls back relationship transfer and first linkage
        Initialize();

        // [GIVEN] A legacy relationship, matching history, and no migration tags
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        GetFeatureDataUpdateStatus(FeatureDataUpdateStatus);
        Commit();

        // [WHEN] The migration fails after relationship transfer and first linkage
        asserterror RunFeatureMigrationAndFail(FeatureDataUpdateStatus);

        // [THEN] Relationship, linkage metadata, and tags remain retryable
        Assert.ExpectedError(SimulatedMigrationFailureErr);
        Assert.ExpectedErrorCode('Dialog');
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        DepreciationBook.TestField("Derogatory Calc.", '');
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), CompanyName()),
            'A failed feature migration must leave the accelerated depreciation tag clear.');
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'A failed feature migration must roll back the original linkage tag.');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunAfterRelationshipTransferSkipsWhenNoRelationshipIsConfigured()
    var
        DepreciationBook: Record "Depreciation Book";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Relationship-transfer linkage waits for a configured relationship
        Initialize();

        // [GIVEN] An FA pair without a configured derogatory book relationship
        InitializeLinkageTestData();
        DepreciationBook.ModifyAll("Derogatory Calc.", '');
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageUpgradeTagIsCleared();

        // [WHEN] Relationship-transfer linkage runs
        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

        // [THEN] The pair stays unlinked and the upgrade tag stays clear
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'The linkage upgrade tag must not be set when no relationship is configured yet, so a later run can still process it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveUpgradeRebuildsLinksFromConfiguredRelationshipPairs()
    var
        FirstSourceFALedgerEntry: Record "FA Ledger Entry";
        SecondSourceFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] RISK-005 Corrective upgrade rebuilds stale links from configured book pairs
        Initialize();

        // [GIVEN] A stale greedy link where one of two valid sources claimed the counterpart
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(3);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 2;
        DerogatoryFALedgerEntry.Modify();
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        // [WHEN] The corrective upgrade runs
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The stale link is cleared, both sources are ambiguous, and the tag is set
        DerogatoryFALedgerEntry.Get(3);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        FirstSourceFALedgerEntry.Get(1);
        FirstSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        SecondSourceFALedgerEntry.Get(2);
        SecondSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'A successful atomic rebuild must set the corrective upgrade tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveUpgradePreservesAllLedgerInvariants()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        BeforeFALedgerEntry: Record "FA Ledger Entry" temporary;
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        BeforeMaintenanceLedgerEntry: Record "Maintenance Ledger Entry" temporary;
        GLEntry: Record "G/L Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        FALedgerEntryCount: Integer;
        MaintenanceLedgerEntryCount: Integer;
        GLEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Corrective upgrade preserves all FA, maintenance, and G/L ledger invariants
        Initialize();

        // [GIVEN] Established links, new linkable pairs, and snapshots of all ledger data
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();

        CreateFALedgerEntry(1, 'AUTH-FA', SourceDepreciationBookCode, false, 101, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, 'AUTH-FA', DerogatoryDepreciationBookCode, false, 101, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(3, 'UNMATCHED-FA', SourceDepreciationBookCode, false, 101, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(10, 'CORRECT-FA', SourceDepreciationBookCode, false, 102, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(11, 'CORRECT-FA', DerogatoryDepreciationBookCode, false, 102, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        FALedgerEntry.Get(2);
        FALedgerEntry."Derogatory Source Entry No." := 1;
        FALedgerEntry.Modify();

        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode, 'AUTH-MAINT', 201, false, 0, 0);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode, 'AUTH-MAINT', 201, false, 0, 0);
        CreateMaintenanceLedgerEntry(3, SourceDepreciationBookCode, 'NO-MATCH', 201, false, 0, 0);
        CreateMaintenanceLedgerEntry(10, SourceDepreciationBookCode, 'CORR-MAINT', 202, false, 0, 0);
        CreateMaintenanceLedgerEntry(11, DerogatoryDepreciationBookCode, 'CORR-MAINT', 202, false, 0, 0);
        MaintenanceLedgerEntry.Get(2);
        MaintenanceLedgerEntry."Derogatory Source Entry No." := 1;
        MaintenanceLedgerEntry.Modify();

        FALedgerEntryCount := FALedgerEntry.Count();
        MaintenanceLedgerEntryCount := MaintenanceLedgerEntry.Count();
        GLEntryCount := GLEntry.Count();
        SnapshotFALedgerEntriesForComparison(FALedgerEntry, BeforeFALedgerEntry);
        SnapshotMaintenanceLedgerEntriesForComparison(MaintenanceLedgerEntry, BeforeMaintenanceLedgerEntry);
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        // [WHEN] The corrective upgrade runs
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] Only linkage metadata changes and authoritative links remain intact
        Assert.AreEqual(FALedgerEntryCount, FALedgerEntry.Count(), 'The corrective upgrade must not change the FA ledger row count.');
        Assert.AreEqual(MaintenanceLedgerEntryCount, MaintenanceLedgerEntry.Count(), 'The corrective upgrade must not change the maintenance ledger row count.');
        Assert.AreEqual(GLEntryCount, GLEntry.Count(), 'The corrective upgrade must not create or remove G/L entries.');
        AssertFALedgerInvariants(BeforeFALedgerEntry);
        AssertMaintenanceLedgerInvariants(BeforeMaintenanceLedgerEntry);

        FALedgerEntry.Get(2);
        FALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        FALedgerEntry.Get(3);
        FALedgerEntry.TestField("Legacy Derogatory Ambiguous", false);
        FALedgerEntry.Get(11);
        FALedgerEntry.TestField("Derogatory Source Entry No.", 10);
        MaintenanceLedgerEntry.Get(2);
        MaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 1);
        MaintenanceLedgerEntry.Get(3);
        MaintenanceLedgerEntry.TestField("Legacy Derogatory Ambiguous", false);
        MaintenanceLedgerEntry.Get(11);
        MaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 10);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveUpgradeSecondRunMakesNoFurtherChanges()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A second corrective upgrade run makes no further changes
        Initialize();

        // [GIVEN] A completed corrective run followed by a manual link correction
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);

        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 0;
        DerogatoryFALedgerEntry.Modify();

        // [WHEN] The corrective upgrade runs again
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The manual correction remains unchanged
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveUpgradeFailureRollsBackClearedLinks()
    var
        SecondTaxDepreciationBook: Record "Depreciation Book";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A failed corrective upgrade rolls back cleared links and its upgrade tag
        Initialize();

        // [GIVEN] An established link and an ambiguous depreciation book relationship
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 1;
        DerogatoryFALedgerEntry.Modify();
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        LibraryFixedAsset.CreateDepreciationBook(SecondTaxDepreciationBook);
        SecondTaxDepreciationBook."Derogatory Calc." := SourceDepreciationBookCode;
        SecondTaxDepreciationBook.Modify();
        Commit();

        // [WHEN] The corrective upgrade runs
        asserterror UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The failure preserves the link and leaves the corrective tag clear
        Assert.ExpectedError('More than one derogatory depreciation book is configured for depreciation book');
        Assert.ExpectedErrorCode('Dialog');
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()),
            'A failed atomic rebuild must roll back the corrective upgrade tag with the cleared links.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationCopiesAllNonDefaultValues()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Every legacy field, including Date and Boolean values, reaches its W1 destination
        Initialize();

        // [GIVEN] Legacy values differ from all destination values
        // [WHEN] The feature or CLEAN30 migration runs
        // [THEN] All nine field mappings preserve their types and values
        VerifyMigrationFieldValues(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationCopiesDefaultValues()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Blank codes, zero dates and false flags overwrite stale destination values
        Initialize();

        // [GIVEN] Default legacy values and nondefault destination values
        // [WHEN] The feature or CLEAN30 migration runs
        // [THEN] No string filter skips or rejects a default Date or Boolean
        VerifyMigrationFieldValues(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompletedMigrationPreservesW1Changes()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Retrying a completed migration cannot replace subsequent W1 setup changes
        Initialize();

        // [GIVEN] A completed migration followed by a W1 relationship change
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        ClearMigrationTags();
        RunFieldMigration();
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        DepreciationBook."Derogatory Calc." := '';
        DepreciationBook.Modify();

        // [WHEN] The migration is retried
        RunFieldMigration();

        // [THEN] The stale legacy relationship is not copied again
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        Assert.AreEqual('', DepreciationBook."Derogatory Calc.", 'Completed migration must preserve W1 changes.');
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompanyInitializationDoesNotCompleteMigration()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        PerCompanyUpgradeTags: List of [Code[250]];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Creating a company while legacy posting remains available does not complete migration
        Initialize();

        // [GIVEN] Company initialization asks for the tags to prepopulate
        // [WHEN] All per-company subscribers contribute their tags
        UpgradeTag.OnGetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        // [THEN] None of the migration completion tags are registered
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'Field migration must not be pre-completed.');
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()), 'Linkage must not be pre-completed.');
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()), 'Corrective linkage must not be pre-completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FeatureCompletionIsCompanyLocal()
    var
        OtherCompany: Record Company;
        LastErrorText: Text;
        LastErrorCode: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Completing company A leaves company B pending with untouched setup
        Initialize();

        // [GIVEN] A separate empty test company
        OtherCompany.Name := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        OtherCompany.Insert(true);
        Commit();

        // [WHEN] A completes while B is pending
        asserterror VerifyCompanyLocalCompletion(OtherCompany.Name);
        LastErrorText := GetLastErrorText();
        LastErrorCode := GetLastErrorCode();

        // [THEN] The assertions passed and the test company is removed even after a failure
        OtherCompany.Delete(true);
        Assert.AreEqual(TestBodyCompletedErr, LastErrorText, 'Company-local completion failed.');
        Assert.AreEqual('Application_DialogException', LastErrorCode, 'The test body must end with the expected AL error.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyPreflightDoesNotCompleteFutureMigration()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A repeated preflight refreshes its counts and cannot pre-complete later legacy data
        Initialize();

        // [GIVEN] A first nonempty preflight followed by an empty company
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        ClearMigrationTags();
        Assert.IsTrue(AcceleratedDeprFeature.IsDataUpdateRequired(), 'The initial setup requires migration.');
        DepreciationBook.DeleteAll();
        FADepreciationBook.DeleteAll();
        FAPostingGroup.DeleteAll();
        FAReclassJournalLine.DeleteAll();

        // [WHEN] Preflight is repeated on the same feature codeunit
        Assert.IsFalse(AcceleratedDeprFeature.IsDataUpdateRequired(), 'The temporary counts must be refreshed.');

        // [THEN] Completion is still absent, and later legacy setup can be migrated
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'Preflight is not migration completion.');
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        RunFieldMigration();
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        Assert.AreEqual(SourceDepreciationBookCode, DepreciationBook."Derogatory Calc.", 'Later legacy setup must be copied.');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveMigrationFailureRollsBackEverything()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Corrective linkage does not commit an enclosing feature or CLEAN30 migration
        Initialize();

        // [GIVEN] Legacy setup and history with only the original linkage tag
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 0,
            CounterpartFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0,
            CounterpartFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        ClearMigrationTags();
        EnsureDerogatoryLinkageUpgradeTagIsSet();
        Commit();

        // [WHEN] The outer migration fails after corrective linkage succeeds
        asserterror RunFieldMigrationAndFail();

        // [THEN] Both the field copy and corrective linkage are rolled back
        Assert.ExpectedError(SimulatedMigrationFailureErr);
        Assert.ExpectedErrorCode('Dialog');
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        CounterpartFALedgerEntry.Get(2);
        Assert.AreEqual('', DepreciationBook."Derogatory Calc.", 'The relationship copy must roll back.');
        Assert.AreEqual(0, CounterpartFALedgerEntry."Derogatory Source Entry No.", 'Corrective linkage must roll back.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()), 'The preexisting tag must remain.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()), 'Corrective completion must roll back.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'Field migration must remain retryable.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreseededDevelopmentTagsDoNotSkipMigration()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        OldTags: List of [Code[250]];
        OldTag: Code[250];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Tags preseeded by the unreleased implementation cannot skip real migration
        Initialize();

        // [GIVEN] Old development completion tags followed by legacy data
        OldTags.Add('MS-581204-AcceleratedDepreciationUpgradeTag-20260206');
        OldTags.Add('MS-581204-DerogatoryLinkageUpgradeTag-20260730');
        OldTags.Add('MS-581204-DerogatoryLinkageCorrectiveUpgradeTag-20260805');
        EnsureTagsAreSet(OldTags);
        InitializeLegacyRelationshipForMigration(DepreciationBook);
        ClearMigrationTags();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 0,
            CounterpartFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0,
            CounterpartFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);

        // [WHEN] The new migration runs
        RunFieldMigration();

        // [THEN] Legacy data is migrated without deleting any old tag
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        CounterpartFALedgerEntry.Get(2);
        Assert.AreEqual(SourceDepreciationBookCode, DepreciationBook."Derogatory Calc.", 'Old tags must not prevent field migration.');
        Assert.AreEqual(1, CounterpartFALedgerEntry."Derogatory Source Entry No.", 'Old tags must not prevent historical linkage.');
        foreach OldTag in OldTags do
            Assert.IsTrue(UpgradeTag.HasUpgradeTag(OldTag), 'Old tags must not be deleted.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AutomaticDerogatoryAdjustmentMigratesAndReverses()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        CounterpartReversalFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A primary automatic derogatory adjustment links and reverses its historical counterpart
        Initialize();

        // [GIVEN] An automatic adjustment with an acquisition sibling and an unlinked tax entry
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        SourceFALedgerEntry."FA Posting Type" := SourceFALedgerEntry."FA Posting Type"::Derogatory;
        SourceFALedgerEntry."Automatic Entry" := true;
        SourceFALedgerEntry.Modify();
        CounterpartFALedgerEntry."FA Posting Type" := SourceFALedgerEntry."FA Posting Type";
        CounterpartFALedgerEntry.Modify();
        CreateFALedgerEntry(4, SourceFALedgerEntry."FA No.", SourceFALedgerEntry."Depreciation Book Code",
            false, 0, SourceFALedgerEntry."FA Posting Type"::"Acquisition Cost", false, 0, 0);
        ReversingFALedgerEntry."FA Posting Type" := SourceFALedgerEntry."FA Posting Type";
        ReversingFALedgerEntry."Automatic Entry" := true;
        ReversingFALedgerEntry.Modify();
        ClearMigrationTags();

        // [WHEN] Linkage runs and the adjustment is reversed
        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);
        FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] The tax entry and its reversal point to their respective normal-book entries
        CounterpartFALedgerEntry.Get(2);
        CounterpartReversalFALedgerEntry.Get(NewEntryNo);
        Assert.AreEqual(1, CounterpartFALedgerEntry."Derogatory Source Entry No.", 'The automatic primary entry must be linked.');
        Assert.AreEqual(3, CounterpartReversalFALedgerEntry."Derogatory Source Entry No.", 'The reversal must retain source linkage.');
        Assert.AreEqual(-100, CounterpartReversalFALedgerEntry.Amount, 'The counterpart reversal must negate the original amount.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AutomaticDerogatoryWithoutAcquisitionIsNotLinked()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unrelated automatic entry is not classified as an acquisition adjustment
        Initialize();

        // [GIVEN] Matching automatic entries but no acquisition sibling
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, true, 0,
            FALedgerEntry."FA Posting Type"::Derogatory, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, true, 0,
            FALedgerEntry."FA Posting Type"::Derogatory, false, 0, 0);

        // [WHEN] Historical entries are classified
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] No link is fabricated
        FALedgerEntry.Get(2);
        Assert.AreEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'Only primary acquisition adjustments qualify.');
        Assert.AreEqual(0, LinkedCount, 'No automatic primary source was present.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmbiguousAutomaticDepreciationReversalFails()
    var
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked automatic depreciation source cannot silently skip an ambiguous counterpart
        Initialize();

        // [GIVEN] Automatic source S has an acquisition sibling and two historical counterparts
        CreateAmbiguousAutomaticFAFixture(ReversingFALedgerEntry, ReversingFALedgerEntry."FA Posting Type"::Depreciation);

        // [WHEN] The marked automatic entry is reversed
        asserterror FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] Reversal explicitly rejects the ambiguous identity
        VerifyAutomaticFAReversalAmbiguityError(ReversingFALedgerEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmbiguousAutomaticCustom1ReversalFails()
    var
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked automatic Custom 1 source cannot silently skip an ambiguous counterpart
        Initialize();

        // [GIVEN] Automatic source S has an acquisition sibling and two historical counterparts
        CreateAmbiguousAutomaticFAFixture(ReversingFALedgerEntry, ReversingFALedgerEntry."FA Posting Type"::"Custom 1");

        // [WHEN] The marked automatic entry is reversed
        asserterror FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] Reversal explicitly rejects the ambiguous identity
        VerifyAutomaticFAReversalAmbiguityError(ReversingFALedgerEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvedAutomaticDepreciationReversesHistoricalCounterpart()
    var
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked automatic depreciation source reverses its now-unique historical counterpart
        Initialize();

        // [GIVEN] Previously ambiguous source S now has only one available counterpart T
        CreateAmbiguousAutomaticFAFixture(ReversingFALedgerEntry, ReversingFALedgerEntry."FA Posting Type"::Depreciation);
        DuplicateFALedgerEntry.Get(5);
        DuplicateFALedgerEntry.Delete();

        // [WHEN] The marked automatic entry is reversed
        FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] T is reversed and its reversal links to the normal-book reversal
        VerifyAutomaticFAHistoricalReversal(NewEntryNo, ReversingFALedgerEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvedAutomaticCustom1ReversesHistoricalCounterpart()
    var
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A marked automatic Custom 1 source reverses its now-unique historical counterpart
        Initialize();

        // [GIVEN] Previously ambiguous source S now has only one available counterpart T
        CreateAmbiguousAutomaticFAFixture(ReversingFALedgerEntry, ReversingFALedgerEntry."FA Posting Type"::"Custom 1");
        DuplicateFALedgerEntry.Get(5);
        DuplicateFALedgerEntry.Delete();

        // [WHEN] The marked automatic entry is reversed
        FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] T is reversed and its reversal links to the normal-book reversal
        VerifyAutomaticFAHistoricalReversal(NewEntryNo, ReversingFALedgerEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyFAReversalUsesOnlyConfiguredBook()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        UnrelatedDepreciationBook: Record "Depreciation Book";
        UnrelatedFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unrelated book with the same document and amount cannot win legacy fallback
        Initialize();

        // [GIVEN] A unique tax counterpart plus an unrelated-book entry
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        LibraryFixedAsset.CreateDepreciationBook(UnrelatedDepreciationBook);
        UnrelatedFALedgerEntry := CounterpartFALedgerEntry;
        UnrelatedFALedgerEntry."Entry No." := 4;
        UnrelatedFALedgerEntry."Depreciation Book Code" := UnrelatedDepreciationBook.Code;
        UnrelatedFALedgerEntry.Insert();

        // [WHEN] The marked source is reversed
        FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] Only the configured counterpart is reversed
        CounterpartFALedgerEntry.Get(2);
        UnrelatedFALedgerEntry.Get(4);
        Assert.AreEqual(NewEntryNo, CounterpartFALedgerEntry."Reversed by Entry No.", 'The configured book must be selected.');
        Assert.AreEqual(0, UnrelatedFALedgerEntry."Reversed by Entry No.", 'The unrelated entry must remain untouched.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyFAReversalRejectsCompetingSources()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        CompetingFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Two sources sharing one candidate remain ambiguous during reversal
        Initialize();

        // [GIVEN] One candidate is also a match for another unlinked source
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        CompetingFALedgerEntry := SourceFALedgerEntry;
        CompetingFALedgerEntry."Entry No." := 4;
        CompetingFALedgerEntry.Insert();

        // [WHEN] Fallback attempts to claim the candidate
        asserterror FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] Ambiguity is reported rather than resolved by entry order
        Assert.ExpectedError(StrSubstNo(AmbiguousHistoricalCounterpartErr, 1));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyFAReversalRejectsMultipleCandidates()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Multiple equally valid candidates stop legacy reversal
        Initialize();

        // [GIVEN] Two indistinguishable unlinked tax entries
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        DuplicateFALedgerEntry := CounterpartFALedgerEntry;
        DuplicateFALedgerEntry."Entry No." := 4;
        DuplicateFALedgerEntry.Insert();

        // [WHEN] Fallback is attempted
        asserterror FAInsertLedgerEntry.InsertFARevEntryForDerog(1, NewEntryNo, ReversingFALedgerEntry);

        // [THEN] No candidate is guessed
        Assert.ExpectedError(StrSubstNo(AmbiguousHistoricalCounterpartErr, 1));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyMaintenanceReversalMatchesCodeAndAmount()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fallback excludes different maintenance codes and amounts
        Initialize();

        // [GIVEN] One exact candidate and mismatched maintenance entries
        // [WHEN] The marked source is reversed
        // [THEN] Only the exact candidate is reversed
        VerifyLegacyMaintenanceFallback(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyMaintenanceReversalRejectsMissingCandidate()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Mismatched, already linked and already reversed entries are not usable candidates
        Initialize();

        // [GIVEN] No available exact candidate
        // [WHEN] The marked source is reversed
        // [THEN] An explicit ambiguity error is reported
        VerifyLegacyMaintenanceFallback(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CorrectiveUpgradeWithoutOriginalTagPreservesLinks()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Without an original historical cutoff corrective execution cannot clear authoritative links
        Initialize();

        // [GIVEN] An established pair and a competing candidate but no original tag
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        ClearMigrationTags();
        DuplicateFALedgerEntry := CounterpartFALedgerEntry;
        DuplicateFALedgerEntry."Entry No." := 4;
        DuplicateFALedgerEntry.Insert();
        CounterpartFALedgerEntry."Derogatory Source Entry No." := 1;
        CounterpartFALedgerEntry.Modify();

        // [WHEN] Corrective execution is repeated
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The established pair remains authoritative
        CounterpartFALedgerEntry.Get(2);
        DuplicateFALedgerEntry.Get(4);
        Assert.AreEqual(1, CounterpartFALedgerEntry."Derogatory Source Entry No.", 'An established link must not be cleared without a cutoff.');
        Assert.AreEqual(0, DuplicateFALedgerEntry."Derogatory Source Entry No.", 'A retry must not link a second counterpart.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CorrectiveUpgradePreservesLinksNewerThanCutoff()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        HistoricalCutoff: DateTime;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Corrective recovery cannot discard authoritative links posted after original migration
        Initialize();

        // [GIVEN] A completed historical pass and a newer linked pair with a competing candidate
        ClearMigrationTags();
        EnsureDerogatoryLinkageUpgradeTagIsSet();
        Assert.IsTrue(UpgradeTag.GetUpgradeTagTimestamp(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), HistoricalCutoff), 'A historical cutoff is required.');
        Sleep(20);
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        Assert.IsTrue(CounterpartFALedgerEntry.SystemCreatedAt > HistoricalCutoff, 'The fixture must be strictly newer than the cutoff.');
        DuplicateFALedgerEntry := CounterpartFALedgerEntry;
        DuplicateFALedgerEntry."Entry No." := 4;
        DuplicateFALedgerEntry.Insert();
        CounterpartFALedgerEntry."Derogatory Source Entry No." := 1;
        CounterpartFALedgerEntry.Modify();

        // [WHEN] Corrective recovery runs
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The existing link is kept, rather than cleared into ambiguity
        CounterpartFALedgerEntry.Get(2);
        DuplicateFALedgerEntry.Get(4);
        Assert.AreEqual(1, CounterpartFALedgerEntry."Derogatory Source Entry No.", 'Newer links must be retained.');
        Assert.AreEqual(0, DuplicateFALedgerEntry."Derogatory Source Entry No.", 'The competing entry must remain unlinked.');
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LegacySalvageMigrationReversesBothBooks()
    var
        PreviousFeatureStatus: Integer;
        BodyErrorText: Text;
        BodyErrorCode: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Migration links legacy automatic salvage so acquisition reversal reverses both books
        Initialize();

        // [GIVEN] The original company feature state
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();

        // [WHEN] A legacy acquisition with salvage is posted, migrated, and reversed
        asserterror begin
            LegacySalvageMigrationReversalBody();
            CompleteTestBody();
        end;
        BodyErrorText := GetLastErrorText();
        BodyErrorCode := GetLastErrorCode();

        // [THEN] All assertions complete and the original feature state is restored
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
        Assert.AreEqual(TestBodyCompletedErr, BodyErrorText, 'The complete posting, migration, and reversal scenario must succeed.');
        Assert.AreEqual('Dialog', BodyErrorCode, 'Only the deliberate completion error is expected.');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmbiguousAutomaticSalvageRemainsUnlinked()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Automatic salvage with an acquisition sibling still requires a mutually unique counterpart
        Initialize();

        // [GIVEN] An acquisition pair with one normal and two tax salvage companions
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFA(FixedAsset);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 100, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 100, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(3, FixedAsset."No.", SourceDepreciationBookCode, true, 100, Enum::"FA Ledger Entry FA Posting Type"::"Salvage Value", false, 0, 0);
        CreateFALedgerEntry(4, FixedAsset."No.", DerogatoryDepreciationBookCode, true, 100, Enum::"FA Ledger Entry FA Posting Type"::"Salvage Value", false, 0, 0);
        CreateFALedgerEntry(5, FixedAsset."No.", DerogatoryDepreciationBookCode, true, 100, Enum::"FA Ledger Entry FA Posting Type"::"Salvage Value", false, 0, 0);

        // [WHEN] Historical linkage runs
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Only acquisition is linked and the salvage source is marked ambiguous
        VerifyLinkageCounts(1, 1, 0, LinkedCount, AmbiguousCount, MissingCount);
        FALedgerEntry.Get(2);
        Assert.AreEqual(1, FALedgerEntry."Derogatory Source Entry No.", 'The acquisition pair must be linked.');
        FALedgerEntry.Get(3);
        Assert.IsTrue(FALedgerEntry."Legacy Derogatory Ambiguous", 'Contested salvage must retain legacy ambiguity handling.');
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Salvage Value");
        FALedgerEntry.SetFilter("Derogatory Source Entry No.", '<>0');
        Assert.RecordIsEmpty(FALedgerEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CanceledSalvageRequiresOwnAcquisitionSibling()
    var
        FixedAsset: Record "Fixed Asset";
        OtherFixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A canceled asset's acquisition cannot qualify another asset's automatic salvage
        Initialize();

        // [GIVEN] Matching canceled salvage without its own acquisition, and another asset's canceled acquisition
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFA(FixedAsset);
        LibraryFixedAsset.CreateFA(OtherFixedAsset);
        CreateFALedgerEntry(1, OtherFixedAsset."No.", SourceDepreciationBookCode, false, 100, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(2, OtherFixedAsset."No.", DerogatoryDepreciationBookCode, false, 100, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(3, FixedAsset."No.", SourceDepreciationBookCode, true, 100, Enum::"FA Ledger Entry FA Posting Type"::"Salvage Value", false, 0, 0);
        CreateFALedgerEntry(4, FixedAsset."No.", DerogatoryDepreciationBookCode, true, 100, Enum::"FA Ledger Entry FA Posting Type"::"Salvage Value", false, 0, 0);
        CancelFAEntryIdentity(1);
        CancelFAEntryIdentity(2);
        CancelFAEntryIdentity(3);
        CancelFAEntryIdentity(4);

        // [WHEN] Historical linkage runs
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        // [THEN] Only acquisition is eligible and the unrelated salvage remains untouched
        VerifyLinkageCounts(1, 0, 0, LinkedCount, AmbiguousCount, MissingCount);
        FALedgerEntry.Get(3);
        Assert.IsFalse(FALedgerEntry."Legacy Derogatory Ambiguous", 'An ineligible automatic row must not be marked ambiguous.');
        FALedgerEntry.Get(4);
        Assert.AreEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'An unrelated acquisition must not make salvage eligible.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CorrectiveUpgradePreservesReassignedBookHistory()
    var
        NewSourceDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Corrective recovery preserves former-book links while rebuilding the current relationship
        Initialize();

        // [GIVEN] Historical linked FA and maintenance pairs and a tax book reassigned to a new source
        InitializeLinkageTestData();
        ClearMigrationTags();
        LibraryFixedAsset.CreateDepreciationBook(NewSourceDepreciationBook);
        CreateReassignedBookHistory(NewSourceDepreciationBook.Code);
        EnsureDerogatoryLinkageUpgradeTagIsSet();
        TaxDepreciationBook.Get(DerogatoryDepreciationBookCode);
        TaxDepreciationBook.Validate("Derogatory Calc.", NewSourceDepreciationBook.Code);
        TaxDepreciationBook.Modify(true);

        // [WHEN] Corrective recovery runs and is retried
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] Old links remain authoritative and the new source links only to its available counterpart
        FALedgerEntry.Get(2);
        Assert.AreEqual(1, FALedgerEntry."Derogatory Source Entry No.", 'Reassignment must not erase FA history.');
        FALedgerEntry.Get(4);
        Assert.AreEqual(3, FALedgerEntry."Derogatory Source Entry No.", 'The old FA counterpart must not compete with the current pair.');
        MaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(1, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'Reassignment must not erase maintenance history.');
        MaintenanceLedgerEntry.Get(4);
        Assert.AreEqual(3, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The current maintenance pair must still be linked.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()),
            'A successful recovery must complete its company tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OperationalCorrectiveWaitsForCompleteMigration()
    var
        SecondSourceDepreciationBook: Record "Depreciation Book";
        SecondTaxDepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CorrectiveRunner: Codeunit "Derog. Linkage Corrective Run";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Operational repair cannot complete linkage against partially transferred relationships
        Initialize();

        // [GIVEN] One transferred relationship and a second relationship present only in the legacy field
        InitializeLinkageTestData();
        ClearMigrationTags();
        SetLegacyDerogatoryCalculation(DerogatoryDepreciationBookCode, SourceDepreciationBookCode);
        LibraryFixedAsset.CreateDepreciationBook(SecondSourceDepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(SecondTaxDepreciationBook);
        SetLegacyDerogatoryCalculation(SecondTaxDepreciationBook.Code, SecondSourceDepreciationBook.Code);
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateMaintenanceLedgerEntry(1, SecondSourceDepreciationBook.Code);
        CreateMaintenanceLedgerEntry(2, SecondTaxDepreciationBook.Code);
        AssignLedgerFixtureAsset();

        // [WHEN] The operational runner is invoked before field migration
        CorrectiveRunner.Run();

        // [THEN] No pair or linkage tag is changed
        FALedgerEntry.Get(2);
        Assert.AreEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'A partially transferred configuration must not be processed.');
        MaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(0, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The untransferred relationship must remain untouched.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()), 'The original tag must remain absent.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()), 'The corrective tag must remain absent.');

        // [WHEN] Field migration subsequently transfers all relationships
        RunFieldMigration();

        // [THEN] Neither relationship was prematurely skipped by a corrective completion tag
        FALedgerEntry.Get(2);
        Assert.AreEqual(1, FALedgerEntry."Derogatory Source Entry No.", 'Migration must link the first relationship.');
        MaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(1, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'Migration must also link the later relationship.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'Field migration must complete.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OperationalCorrectiveRepairsAfterFieldMigration()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CorrectiveRunner: Codeunit "Derog. Linkage Corrective Run";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The operational runner still repairs historical linkage after the prerequisite completes
        Initialize();

        // [GIVEN] Completed field migration followed by an original-tag-only historical linkage state
        InitializeLinkageTestData();
        ClearMigrationTags();
        SetLegacyDerogatoryCalculation(DerogatoryDepreciationBookCode, SourceDepreciationBookCode);
        RunFieldMigration();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);
        AssignLedgerFixtureAsset();
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        // [WHEN] The operational runner executes
        CorrectiveRunner.Run();

        // [THEN] Both ledger pairs are linked and corrective recovery completes
        FALedgerEntry.Get(2);
        Assert.AreEqual(1, FALedgerEntry."Derogatory Source Entry No.", 'The operational runner must repair FA linkage.');
        MaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(1, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The operational runner must repair maintenance linkage.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()), 'Corrective recovery must complete.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BulkFAMatchingReadsOnlySameAssetCandidates()
    var
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        AssetCount: Integer;
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
        SqlRowsReadBefore: BigInteger;
        SqlRowsRead: BigInteger;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Matching identical posting signatures across active and canceled assets has a linear row-read budget
        Initialize();

        // [GIVEN] Eighty assets covering all active/canceled source and counterpart combinations
        InitializeLinkageTestData();
        AssetCount := 80;
        CreateBulkFAIdentityPairs(AssetCount);
        SqlRowsReadBefore := SessionInformation.SqlRowsRead();

        // [WHEN] Historical FA linkage runs
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        SqlRowsRead := SessionInformation.SqlRowsRead() - SqlRowsReadBefore;

        // [THEN] Every exact pair is linked without retrieving every other asset for each source
        VerifyLinkageCounts(AssetCount, 0, 0, LinkedCount, AmbiguousCount, MissingCount);
        VerifyBulkFAIdentityPairs(AssetCount);
        Assert.IsTrue(
            SqlRowsRead <= 20 * AssetCount + 100,
            StrSubstNo('Matching %1 assets read %2 SQL rows; the linear budget is %3.', AssetCount, SqlRowsRead, 20 * AssetCount + 100));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CorrectiveUpgradeSkipsFormerCounterpartSources()
    var
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Former counterparts neither become sources nor compete after their book changes role
        Initialize();

        // [GIVEN] Book B formerly mirrored A and now supplies C, with preserved links in both ledgers
        InitializeLinkageTestData();
        ClearMigrationTags();
        CreateFormerCounterpartSourceHistory();
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        // [WHEN] Corrective linkage runs
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] Only the genuine source links to C, and the former counterparts remain unchanged
        VerifyFormerCounterpartSourceHistory();

        // [WHEN] Corrective linkage is retried
        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        // [THEN] The same links and ambiguity flags are retained
        VerifyFormerCounterpartSourceHistory();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReversalLinkageRejectsOriginalLinkedToAnotherSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A reversal cannot match through an original already linked to another source
        Initialize();

        // [GIVEN] Matching reversals S and C whose candidate original belongs to another source
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(2, 20);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The preserved original link survives and the conflicting reversal remains unlinked
        VerifyPreservedChainLink(2, 20, 11, 0);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] The same preserved and unlinked entries are retained
        VerifyPreservedChainLink(2, 20, 11, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReversalLinkageRejectsOriginalWithAnotherCounterpart()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unlinked candidate original cannot replace the source original's preserved counterpart
        Initialize();

        // [GIVEN] Matching reversals S and C whose source original already has a different counterpart
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(21, 1);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The preserved original link survives and the conflicting reversal remains unlinked
        VerifyPreservedChainLink(21, 1, 11, 0);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] The same preserved and unlinked entries are retained
        VerifyPreservedChainLink(21, 1, 11, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OriginalLinkageRejectsReversalLinkedToAnotherSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An original cannot match through a reversal already linked to another source
        Initialize();

        // [GIVEN] Matching originals S and C whose candidate reversal belongs to another source
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(11, 30);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The preserved reversal link survives and the conflicting original remains unlinked
        VerifyPreservedChainLink(11, 30, 2, 0);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] The same preserved and unlinked entries are retained
        VerifyPreservedChainLink(11, 30, 2, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OriginalLinkageRejectsReversalWithAnotherCounterpart()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unlinked candidate reversal cannot replace the source reversal's preserved counterpart
        Initialize();

        // [GIVEN] Matching originals S and C whose source reversal already has a different counterpart
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(31, 10);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The preserved reversal link survives and the conflicting original remains unlinked
        VerifyPreservedChainLink(31, 10, 2, 0);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] The same preserved and unlinked entries are retained
        VerifyPreservedChainLink(31, 10, 2, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReversalLinkageAcceptsConsistentOriginalLink()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A preserved original pair still allows its matching reversals to link
        Initialize();

        // [GIVEN] Matching reversals S and C with correctly linked originals
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(2, 1);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The original link is retained and the reversals link to each other
        VerifyPreservedChainLink(2, 1, 11, 10);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] Both established pairs remain unchanged
        VerifyPreservedChainLink(2, 1, 11, 10);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OriginalLinkageAcceptsConsistentReversalLink()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A preserved reversal pair still allows its matching originals to link
        Initialize();

        // [GIVEN] Matching originals S and C with correctly linked reversals
        CreatePreservedReversalChainHistory();
        SetHistoricalLink(11, 10);

        // [WHEN] Historical linkage runs
        RunHistoricalLinkage();

        // [THEN] The reversal link is retained and the originals link to each other
        VerifyPreservedChainLink(11, 10, 2, 1);

        // [WHEN] Historical linkage is retried
        RunHistoricalLinkage();

        // [THEN] Both established pairs remain unchanged
        VerifyPreservedChainLink(11, 10, 2, 1);
    end;

    local procedure Initialize()
    var
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT Derogatory Linkage Upg.");
        LibraryLowerPermissions.SetOutsideO365Scope();
        FALedgerEntry.DeleteAll();
        MaintenanceLedgerEntry.DeleteAll();
        DepreciationBook.ModifyAll("Derogatory Calc.", '');
        EnsureGeneralPostingSetup();
        EnsureFAJournalTemplate();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT Derogatory Linkage Upg.");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT Derogatory Linkage Upg.");
    end;

    local procedure InitializeLegacyRelationshipForMigration(var DerogatoryDepreciationBook: Record "Depreciation Book")
    begin
        InitializeLinkageTestData();
        DerogatoryDepreciationBook.Get(DerogatoryDepreciationBookCode);
        DerogatoryDepreciationBook."Derogatory Calc." := '';
        DerogatoryDepreciationBook.Modify();
        SetLegacyDerogatoryCalculation(DerogatoryDepreciationBook.Code, SourceDepreciationBookCode);
    end;

    local procedure InitializeLinkageTestData()
    begin
        CreateDepreciationBooks();
    end;

    local procedure CreateAmbiguousAutomaticFAFixture(var ReversingFALedgerEntry: Record "FA Ledger Entry"; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        DuplicateFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        SourceFALedgerEntry."Automatic Entry" := true;
        SourceFALedgerEntry."FA Posting Type" := FAPostingType;
        SourceFALedgerEntry.Modify();
        CounterpartFALedgerEntry."FA Posting Type" := FAPostingType;
        CounterpartFALedgerEntry.Modify();
        CreateFALedgerEntry(4, SourceFALedgerEntry."FA No.", SourceDepreciationBookCode, false, 0,
            SourceFALedgerEntry."FA Posting Type"::"Acquisition Cost", false, 0, 0);
        DuplicateFALedgerEntry := CounterpartFALedgerEntry;
        DuplicateFALedgerEntry."Entry No." := 5;
        DuplicateFALedgerEntry.Insert();
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        Assert.IsTrue(SourceFALedgerEntry."Legacy Derogatory Ambiguous", 'Migration must mark the automatic source ambiguous.');
        ReversingFALedgerEntry."Automatic Entry" := true;
        ReversingFALedgerEntry."FA Posting Type" := FAPostingType;
        ReversingFALedgerEntry."Legacy Derogatory Ambiguous" := SourceFALedgerEntry."Legacy Derogatory Ambiguous";
        ReversingFALedgerEntry.Modify();
    end;

    local procedure CreateBulkFAIdentityPairs(AssetCount: Integer)
    var
        FixedAsset: Record "Fixed Asset";
        AssetIndex: Integer;
    begin
        for AssetIndex := 1 to AssetCount do begin
            LibraryFixedAsset.CreateFA(FixedAsset);
            CreateFALedgerEntry(2 * AssetIndex - 1, FixedAsset."No.", SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
            CreateFALedgerEntry(2 * AssetIndex, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
            if (AssetIndex mod 4) in [0, 1] then
                CancelFAEntryIdentity(2 * AssetIndex - 1);
            if (AssetIndex mod 4) in [0, 2] then
                CancelFAEntryIdentity(2 * AssetIndex);
        end;
    end;

    local procedure CreateCanceledFALedgerEntry(EntryNo: Integer; DepreciationBookCode: Code[10]; CanceledFromFANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := EntryNo;
        FALedgerEntry."FA No." := '';
        FALedgerEntry."Canceled from FA No." := CanceledFromFANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
        FALedgerEntry.Amount := 100;
        FALedgerEntry."Document No." := 'DOC';
        FALedgerEntry."FA Posting Date" := WorkDate();
        FALedgerEntry."Posting Date" := WorkDate();
        FALedgerEntry."Document Date" := WorkDate();
        FALedgerEntry.Insert();
    end;

    local procedure CreateCentralRoutingSetup(var DepreciationBook: Record "Depreciation Book"; var TaxDepreciationBook: Record "Depreciation Book"; var FixedAsset: Record "Fixed Asset"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(TaxDepreciationBook);
        TaxDepreciationBook."Derogatory Calc." := DepreciationBook.Code;
        TaxDepreciationBook.Modify();
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
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

#if not CLEAN30
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

    local procedure CreateFALedgerEntry(EntryNo: Integer; FANo: Code[20]; DepreciationBookCode: Code[10]; AutomaticEntry: Boolean; TransactionNo: Integer; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; Reversed: Boolean; ReversedByEntryNo: Integer; ReversedEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := EntryNo;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."Automatic Entry" := AutomaticEntry;
        FALedgerEntry."Transaction No." := TransactionNo;
        FALedgerEntry."FA Posting Type" := FAPostingType;
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

    local procedure CreateFixedAssetWithPostingGroup(var FixedAsset: Record "Fixed Asset"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFormerCounterpartSourceHistory()
    var
        FormerTaxDepreciationBook: Record "Depreciation Book";
        NewTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        OtherFixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateDepreciationBook(NewTaxDepreciationBook);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFixedAsset(OtherFixedAsset);
        CreateHistoricalLinkageEntry(1, FixedAsset."No.", SourceDepreciationBookCode, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(3, FixedAsset."No.", DerogatoryDepreciationBookCode, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(4, FixedAsset."No.", NewTaxDepreciationBook.Code, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(5, OtherFixedAsset."No.", SourceDepreciationBookCode, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(6, OtherFixedAsset."No.", DerogatoryDepreciationBookCode, 0, false, 0, 0);
        CreateHistoricalLinkageEntry(7, OtherFixedAsset."No.", NewTaxDepreciationBook.Code, 0, false, 0, 0);
        SetHistoricalLink(2, 1);
        SetHistoricalLink(6, 5);

        FormerTaxDepreciationBook.Get(DerogatoryDepreciationBookCode);
        FormerTaxDepreciationBook.Validate("Derogatory Calc.", '');
        FormerTaxDepreciationBook.Modify(true);
        NewTaxDepreciationBook.Validate("Derogatory Calc.", FormerTaxDepreciationBook.Code);
        NewTaxDepreciationBook.Modify(true);
    end;

    local procedure CreateHistoricalFAFixture(var SourceFALedgerEntry: Record "FA Ledger Entry"; var CounterpartFALedgerEntry: Record "FA Ledger Entry"; var ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
    begin
        EnableCentralRoutingIfRequired();
        InitializeLinkageTestData();
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", SourceDepreciationBookCode, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", DerogatoryDepreciationBookCode, FAPostingGroup.Code);
        CreateFALedgerEntry(1, FixedAsset."No.", SourceDepreciationBookCode, false, 0,
            SourceFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, false, 0,
            SourceFALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(3, FixedAsset."No.", SourceDepreciationBookCode, false, 0,
            SourceFALedgerEntry."FA Posting Type"::Depreciation, true, 0, 1);
        SourceFALedgerEntry.Get(1);
        CounterpartFALedgerEntry.Get(2);
        ReversingFALedgerEntry.Get(3);
        ReversingFALedgerEntry.Amount := -SourceFALedgerEntry.Amount;
        ReversingFALedgerEntry."Legacy Derogatory Ambiguous" := true;
        ReversingFALedgerEntry.Modify();
    end;

    local procedure CreateHistoricalLinkageEntry(EntryNo: Integer; FANo: Code[20]; DepreciationBookCode: Code[10]; TransactionNo: Integer; Reversed: Boolean; ReversedByEntryNo: Integer; ReversedEntryNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        CreateFALedgerEntry(
            EntryNo, FANo, DepreciationBookCode, false, TransactionNo,
            Enum::"FA Ledger Entry FA Posting Type"::Depreciation, Reversed, ReversedByEntryNo, ReversedEntryNo);
        MaintenanceLedgerEntry."Entry No." := EntryNo;
        MaintenanceLedgerEntry."FA No." := FANo;
        MaintenanceLedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        MaintenanceLedgerEntry.Amount := 100;
        MaintenanceLedgerEntry."Document No." := 'DOC';
        MaintenanceLedgerEntry."FA Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Document Date" := WorkDate();
        MaintenanceLedgerEntry."Transaction No." := TransactionNo;
        MaintenanceLedgerEntry.Reversed := Reversed;
        MaintenanceLedgerEntry."Reversed by Entry No." := ReversedByEntryNo;
        MaintenanceLedgerEntry."Reversed Entry No." := ReversedEntryNo;
        MaintenanceLedgerEntry.Insert();
    end;

    local procedure CreateHistoricalMaintenanceEntry(EntryNo: Integer; FANo: Code[20]; DepreciationBookCode: Code[10]; TransactionNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry."Entry No." := EntryNo;
        MaintenanceLedgerEntry."FA No." := FANo;
        MaintenanceLedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        MaintenanceLedgerEntry."Transaction No." := TransactionNo;
        MaintenanceLedgerEntry.Amount := 100;
        MaintenanceLedgerEntry."Document No." := 'DOC';
        MaintenanceLedgerEntry."FA Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Document Date" := WorkDate();
        MaintenanceLedgerEntry.Insert();
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

    local procedure CreateMaintenanceLedgerEntry(EntryNo: Integer; DepreciationBookCode: Code[10]; MaintenanceCode: Code[10])
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry."Entry No." := EntryNo;
        MaintenanceLedgerEntry."FA No." := 'FA';
        MaintenanceLedgerEntry."Maintenance Code" := MaintenanceCode;
        MaintenanceLedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        MaintenanceLedgerEntry.Amount := 100;
        MaintenanceLedgerEntry."Document No." := 'DOC';
        MaintenanceLedgerEntry."FA Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Posting Date" := WorkDate();
        MaintenanceLedgerEntry."Document Date" := WorkDate();
        MaintenanceLedgerEntry.Insert();
    end;

    local procedure CreateMaintenanceLedgerEntry(EntryNo: Integer; DepreciationBookCode: Code[10]; MaintenanceCode: Code[10]; TransactionNo: Integer; Reversed: Boolean; ReversedByEntryNo: Integer; ReversedEntryNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        CreateMaintenanceLedgerEntry(EntryNo, DepreciationBookCode, MaintenanceCode);
        MaintenanceLedgerEntry.Get(EntryNo);
        MaintenanceLedgerEntry."Transaction No." := TransactionNo;
        MaintenanceLedgerEntry.Reversed := Reversed;
        MaintenanceLedgerEntry."Reversed by Entry No." := ReversedByEntryNo;
        MaintenanceLedgerEntry."Reversed Entry No." := ReversedEntryNo;
        MaintenanceLedgerEntry.Modify();
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

    local procedure CreatePreservedReversalChainHistory()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        InitializeLinkageTestData();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateHistoricalLinkageEntry(1, FixedAsset."No.", SourceDepreciationBookCode, 0, true, 10, 0);
        CreateHistoricalLinkageEntry(2, FixedAsset."No.", DerogatoryDepreciationBookCode, 0, true, 11, 0);
        CreateHistoricalLinkageEntry(10, FixedAsset."No.", SourceDepreciationBookCode, 100, true, 0, 1);
        CreateHistoricalLinkageEntry(11, FixedAsset."No.", DerogatoryDepreciationBookCode, 100, true, 0, 2);
        CreateHistoricalLinkageEntry(20, FixedAsset."No.", SourceDepreciationBookCode, 0, true, 30, 0);
        CreateHistoricalLinkageEntry(21, FixedAsset."No.", DerogatoryDepreciationBookCode, 0, true, 31, 0);
        CreateHistoricalLinkageEntry(30, FixedAsset."No.", SourceDepreciationBookCode, 200, true, 0, 20);
        CreateHistoricalLinkageEntry(31, FixedAsset."No.", DerogatoryDepreciationBookCode, 200, true, 0, 21);
        FALedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        FALedgerEntry.ModifyAll(Amount, -100);
        MaintenanceLedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        MaintenanceLedgerEntry.ModifyAll(Amount, -100);
    end;

    local procedure CreateReassignedBookHistory(NewSourceDepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, NewSourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(4, DerogatoryDepreciationBookCode, false, 0, 0);
        FALedgerEntry.ModifyAll("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.Get(2);
        FALedgerEntry."Derogatory Source Entry No." := 1;
        FALedgerEntry.Modify();
        CreateMaintenanceLedgerEntry(1, SourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(2, DerogatoryDepreciationBookCode);
        CreateMaintenanceLedgerEntry(3, NewSourceDepreciationBookCode);
        CreateMaintenanceLedgerEntry(4, DerogatoryDepreciationBookCode);
        MaintenanceLedgerEntry.Get(2);
        MaintenanceLedgerEntry."Derogatory Source Entry No." := 1;
        MaintenanceLedgerEntry.Modify();
        AssignLedgerFixtureAsset();
    end;

    local procedure AssertFALedgerInvariants(var BeforeFALedgerEntry: Record "FA Ledger Entry" temporary)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        TempFieldToIgnore: Record Field temporary;
        BeforeRecordRef: RecordRef;
        AfterRecordRef: RecordRef;
    begin
        TempFieldToIgnore.TableNo := Database::"FA Ledger Entry";
        TempFieldToIgnore."No." := FALedgerEntry.FieldNo("Derogatory Source Entry No.");
        TempFieldToIgnore.Insert();
        TempFieldToIgnore."No." := FALedgerEntry.FieldNo("Legacy Derogatory Ambiguous");
        TempFieldToIgnore.Insert();

        if BeforeFALedgerEntry.FindSet() then
            repeat
                FALedgerEntry.Get(BeforeFALedgerEntry."Entry No.");
                BeforeRecordRef.GetTable(BeforeFALedgerEntry);
                AfterRecordRef.GetTable(FALedgerEntry);
                Assert.RecordsAreEqualExceptCertainFields(
                    BeforeRecordRef, AfterRecordRef, TempFieldToIgnore,
                    'The corrective upgrade may change only FA linkage metadata.');
            until BeforeFALedgerEntry.Next() = 0;
    end;

    local procedure AssertMaintenanceLedgerInvariants(var BeforeMaintenanceLedgerEntry: Record "Maintenance Ledger Entry" temporary)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TempFieldToIgnore: Record Field temporary;
        BeforeRecordRef: RecordRef;
        AfterRecordRef: RecordRef;
    begin
        TempFieldToIgnore.TableNo := Database::"Maintenance Ledger Entry";
        TempFieldToIgnore."No." := MaintenanceLedgerEntry.FieldNo("Derogatory Source Entry No.");
        TempFieldToIgnore.Insert();
        TempFieldToIgnore."No." := MaintenanceLedgerEntry.FieldNo("Legacy Derogatory Ambiguous");
        TempFieldToIgnore.Insert();

        if BeforeMaintenanceLedgerEntry.FindSet() then
            repeat
                MaintenanceLedgerEntry.Get(BeforeMaintenanceLedgerEntry."Entry No.");
                BeforeRecordRef.GetTable(BeforeMaintenanceLedgerEntry);
                AfterRecordRef.GetTable(MaintenanceLedgerEntry);
                Assert.RecordsAreEqualExceptCertainFields(
                    BeforeRecordRef, AfterRecordRef, TempFieldToIgnore,
                    'The corrective upgrade may change only maintenance linkage metadata.');
            until BeforeMaintenanceLedgerEntry.Next() = 0;
    end;

    local procedure AssignLedgerFixtureAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        LibraryFixedAsset.CreateFA(FixedAsset);
        FALedgerEntry.ModifyAll("FA No.", FixedAsset."No.");
        MaintenanceLedgerEntry.ModifyAll("FA No.", FixedAsset."No.");
    end;

    local procedure CancelFAEntryIdentity(EntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Get(EntryNo);
        FALedgerEntry."Canceled from FA No." := FALedgerEntry."FA No.";
        FALedgerEntry."FA No." := '';
        FALedgerEntry.Modify();
    end;

#if not CLEAN30
    // "FA Jnl.-Post Batch" commits, and the test framework rejects Commit under TransactionModel::AutoRollback
    // ("Tests cannot call the Commit function if TransactionModel property is set to AutoRollback."). The posting
    // tests therefore run with AutoCommit and restore the shared French feature state deterministically instead.
    local procedure CaptureFeatureStateIfRequired() PreviousFeatureStatus: Integer
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
            PreviousFeatureStatus := FeatureDataUpdateStatus."Feature Status".AsInteger()
        else
            PreviousFeatureStatus := GetMissingFeatureStatusValue();
    end;
#else
    local procedure CaptureFeatureStateIfRequired() PreviousFeatureStatus: Integer
    begin
        PreviousFeatureStatus := 0;
    end;
#endif

#if CLEAN30
    local procedure Clean30FAJournalBody()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(2, FALedgerEntry.Count(), 'CLEAN30 must post the source and one central counterpart.');
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'CLEAN30 must use the central relationship.');
        FALedgerEntry.FindFirst();
        Assert.AreNotEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'The CLEAN30 counterpart must be linked.');
    end;
#endif

    local procedure ClearMigrationTags()
    begin
        EnsureAcceleratedDepreciationUpgradeTagIsCleared();
        EnsureDerogatoryLinkageUpgradeTagIsCleared();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
    end;

    // The posting tests mutate company-wide French feature state and "FA Jnl.-Post Batch" commits it. Their
    // body therefore runs inside asserterror - the only AL construct that catches a failing body while still
    // allowing the database writes these tests need - and the sentinel error below ends a successful body.
    local procedure CompleteTestBody()
    begin
        TestBodyCompleted := true;
        Error(TestBodyCompletedErr);
    end;

#if not CLEAN30
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
#endif

#if not CLEAN30
    local procedure DisabledFeatureFAJournalBody()
    var
        DepreciationBook: Record "Depreciation Book";
        LegacyTaxDepreciationBook: Record "Depreciation Book";
        CentralTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
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
    end;
#endif

#if not CLEAN30
    local procedure DisabledFeatureReversalBody()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewFAEntryNo: Integer;
    begin
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
    end;
#endif

#if not CLEAN30
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
#endif

    local procedure EnableCentralRoutingIfRequired()
    begin
#if not CLEAN30
        EnableAcceleratedDepreciationFeature();
#endif
    end;

#if not CLEAN30
    local procedure EnabledFeatureFAJournalBody()
    var
        DepreciationBook: Record "Depreciation Book";
        LegacyTaxDepreciationBook: Record "Depreciation Book";
        CentralTaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
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
    end;
#endif

    local procedure EnsureAcceleratedDepreciationUpgradeTagIsCleared()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), CompanyName()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), CompanyName());
    end;

    local procedure EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName());
    end;

    local procedure EnsureDerogatoryLinkageUpgradeTagIsCleared()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName());
    end;

    local procedure EnsureDerogatoryLinkageUpgradeTagIsSet()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()) then
            UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
    end;

    local procedure EnsureFAJournalTemplate()
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        if not FAJournalTemplate.IsEmpty() then
            exit;

        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure EnsureGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        if not GeneralPostingSetup.IsEmpty() then
            exit;

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(
            GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
    end;

    local procedure EnsureTagsAreSet(Tags: List of [Code[250]])
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tag: Code[250];
    begin
        foreach Tag in Tags do
            if not UpgradeTag.HasUpgradeTag(Tag) then
                UpgradeTag.SetUpgradeTag(Tag);
    end;

    local procedure FAReversalOverloadBody()
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
    begin
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
    end;

    local procedure GeneratedMirrorDuplicationBody()
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
    begin
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
    end;

#if not CLEAN30
    local procedure GetFeatureDataUpdateStatus(var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
            exit;

        FeatureDataUpdateStatus."Feature Key" := AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey();
        FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
        FeatureDataUpdateStatus.Insert();
    end;
#endif

    local procedure GetMissingFeatureStatusValue(): Integer
    begin
        exit(-1);
    end;

#if not CLEAN30
    local procedure LegacySalvageMigrationReversalBody()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        SourceAcquisition: Record "FA Ledger Entry";
        SourceSalvage: Record "FA Ledger Entry";
        TaxSalvage: Record "FA Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewFAEntryNo: Integer;
    begin
        DisableAcceleratedDepreciationFeature();
        ClearMigrationTags();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(TaxDepreciationBook);
        SetLegacyDerogatoryCalculation(TaxDepreciationBook.Code, DepreciationBook.Code);
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", 1000);
        FAJournalLine.Validate("Salvage Value", -100);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        SourceAcquisition.SetRange("FA No.", FixedAsset."No.");
        SourceAcquisition.SetRange("Depreciation Book Code", DepreciationBook.Code);
        SourceAcquisition.SetRange("FA Posting Type", SourceAcquisition."FA Posting Type"::"Acquisition Cost");
        SourceAcquisition.FindFirst();
        SourceSalvage.SetRange("FA No.", FixedAsset."No.");
        SourceSalvage.SetRange("Depreciation Book Code", DepreciationBook.Code);
        SourceSalvage.SetRange("FA Posting Type", SourceSalvage."FA Posting Type"::"Salvage Value");
        SourceSalvage.FindFirst();
        TaxSalvage.SetRange("FA No.", FixedAsset."No.");
        TaxSalvage.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        TaxSalvage.SetRange("FA Posting Type", TaxSalvage."FA Posting Type"::"Salvage Value");
        TaxSalvage.FindFirst();
        Assert.IsTrue(SourceSalvage."Automatic Entry", 'Legacy posting must produce an automatic source salvage entry.');
        Assert.IsTrue(TaxSalvage."Automatic Entry", 'Legacy posting must also produce an automatic tax salvage entry.');
        Assert.AreEqual(0, TaxSalvage."Derogatory Source Entry No.", 'The legacy salvage fixture must start unlinked.');

        RunFieldMigration();
        EnableAcceleratedDepreciationFeature();

        TaxSalvage.Get(TaxSalvage."Entry No.");
        Assert.AreEqual(SourceSalvage."Entry No.", TaxSalvage."Derogatory Source Entry No.", 'Migration must link the automatic salvage companion.');
        FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceAcquisition."Entry No.", NewFAEntryNo, 0);

        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        Assert.AreEqual(8, FALedgerEntry.Count(), 'Both acquisitions and both salvage entries must have reversals.');
        FALedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        Assert.AreEqual(4, FALedgerEntry.Count(), 'Exactly four reversal entries must be created.');
        SourceCodeSetup.Get();
        FALedgerEntry.SetFilter("Source Code", '<>%1', SourceCodeSetup.Reversal);
        Assert.RecordIsEmpty(FALedgerEntry);
        FALedgerEntry.SetRange("Source Code");
        FALedgerEntry.SetRange("Reversed Entry No.");
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FALedgerEntry.CalcSums(Amount);
        Assert.AreEqual(0, FALedgerEntry.Amount, 'Normal acquisition and salvage must be fully reversed.');
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        FALedgerEntry.CalcSums(Amount);
        Assert.AreEqual(0, FALedgerEntry.Amount, 'Tax acquisition and salvage must be fully reversed.');
    end;
#endif

    local procedure MaintenanceReversalOverloadBody()
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
    begin
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
    end;

    local procedure NormalBookValueBody()
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
    begin
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
#if not CLEAN30
        FALedgerEntry.TestField("Exclude Derogatory", true);
#endif
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

    local procedure RestoreFeatureStateAfterTestBody(PreviousFeatureStatus: Integer)
    var
        BodyErrorText: Text;
        BodyCompleted: Boolean;
    begin
        BodyErrorText := GetLastErrorText();
        BodyCompleted := TestBodyCompleted;
        TestBodyCompleted := false;
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
        // The restore must be committed before the body failure is rethrown, because the rethrow rolls the
        // database back to the commit that "FA Jnl.-Post Batch" already made with the toggled state.
        Commit();
        if not BodyCompleted then
            Error(BodyErrorText);
    end;

#if not CLEAN30
    local procedure RestoreFeatureStateIfRequired(PreviousFeatureStatus: Integer)
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        if PreviousFeatureStatus = GetMissingFeatureStatusValue() then begin
            if FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
                FeatureDataUpdateStatus.Delete();
            exit;
        end;

        if not FeatureDataUpdateStatus.Get(AcceleratedDeprFeature.GetAcceleratedDepreciationFeatureKey(), CompanyName()) then
            exit;
        FeatureDataUpdateStatus."Feature Status" := Enum::"Feature Status".FromInteger(PreviousFeatureStatus);
        FeatureDataUpdateStatus.Modify();
    end;
#else
    local procedure RestoreFeatureStateIfRequired(PreviousFeatureStatus: Integer)
    begin
        Assert.AreEqual(0, PreviousFeatureStatus, 'CLEAN30 has no French feature state to capture.');
    end;
#endif

#if not CLEAN30
    local procedure RunFeatureMigrationAndFail(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        AcceleratedDeprFeature.UpdateData(FeatureDataUpdateStatus);
        Error(SimulatedMigrationFailureErr);
    end;
#endif

    local procedure RunFieldMigration()
    var
#if not CLEAN30
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
#else
        UpgradeAcceleratedDepr: Codeunit "Upgrade Accelerated Depr.";
#endif
    begin
#if not CLEAN30
        GetFeatureDataUpdateStatus(FeatureDataUpdateStatus);
        AcceleratedDeprFeature.UpdateData(FeatureDataUpdateStatus);
        AcceleratedDeprFeature.AfterUpdate(FeatureDataUpdateStatus);
#else
        UpgradeAcceleratedDepr.UpgradeAcceleratedDepr();
#endif
    end;

    local procedure RunFieldMigrationAndFail()
    begin
        RunFieldMigration();
        Error(SimulatedMigrationFailureErr);
    end;

    local procedure RunHistoricalLinkage()
    var
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        LinkedCount: Integer;
        AmbiguousCount: Integer;
        MissingCount: Integer;
    begin
        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
    end;

    local procedure SalvageReversalSourceCodeBody()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAJournalLine: Record "FA Journal Line";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        ReversalFALedgerEntry: Record "FA Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewFAEntryNo: Integer;
    begin
        EnableCentralRoutingIfRequired();
        CreateCentralRoutingSetup(DepreciationBook, TaxDepreciationBook, FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBook.Code, FAPostingGroup.Code);
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", 1000);
        FAJournalLine.Validate("Salvage Value", -100);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        SourceFALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        SourceFALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
        SourceFALedgerEntry.SetRange(
            "FA Posting Type", SourceFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        SourceFALedgerEntry.FindFirst();

        FAInsertLedgerEntry.InsertReverseEntry(0, 1, SourceFALedgerEntry."Entry No.", NewFAEntryNo, 0);

        // Every reversal entry, including the tax-book salvage counterpart, must carry the reversal source code.
        SourceCodeSetup.Get();
        ReversalFALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        ReversalFALedgerEntry.SetFilter("Reversed Entry No.", '<>%1', 0);
        Assert.AreEqual(4, ReversalFALedgerEntry.Count(), 'Both books must reverse the acquisition and its salvage companion.');
        ReversalFALedgerEntry.FindSet();
        repeat
            ReversalFALedgerEntry.TestField("Source Code", SourceCodeSetup.Reversal);
        until ReversalFALedgerEntry.Next() = 0;
    end;

    local procedure SetHistoricalLink(EntryNo: Integer; SourceEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        FALedgerEntry.Get(EntryNo);
        FALedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        FALedgerEntry.Modify();
        MaintenanceLedgerEntry.Get(EntryNo);
        MaintenanceLedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        MaintenanceLedgerEntry.Modify();
    end;

    local procedure SetLegacyDerogatoryCalculation(DepreciationBookCode: Code[10]; SourceDepreciationBookCode: Code[10])
    var
        DepreciationBookRecordRef: RecordRef;
        CodeFieldRef: FieldRef;
        LegacyRelationshipFieldRef: FieldRef;
    begin
        DepreciationBookRecordRef.Open(Database::"Depreciation Book");
        CodeFieldRef := DepreciationBookRecordRef.Field(1);
        CodeFieldRef.SetRange(DepreciationBookCode);
        DepreciationBookRecordRef.FindFirst();
        LegacyRelationshipFieldRef := DepreciationBookRecordRef.Field(10800);
        LegacyRelationshipFieldRef.Value := SourceDepreciationBookCode;
        DepreciationBookRecordRef.Modify(false);
    end;

    local procedure SetMigrationFieldValues(RecordId: RecordId; LegacyFieldNo: Integer; DestinationFieldNo: Integer; LegacyValue: Variant; DestinationValue: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Get(RecordId);
        FieldRef := RecordRef.Field(LegacyFieldNo);
        FieldRef.Value := LegacyValue;
        FieldRef := RecordRef.Field(DestinationFieldNo);
        FieldRef.Value := DestinationValue;
        RecordRef.Modify();
    end;

#if not CLEAN30
    local procedure SimulatedFailureBody()
    begin
        EnableAcceleratedDepreciationFeature();
        Commit();
        Error(SimulatedBodyFailureErr);
    end;
#endif

    local procedure SnapshotFALedgerEntriesForComparison(var FALedgerEntry: Record "FA Ledger Entry"; var BeforeFALedgerEntry: Record "FA Ledger Entry" temporary)
    begin
        if FALedgerEntry.FindSet() then
            repeat
                BeforeFALedgerEntry := FALedgerEntry;
                BeforeFALedgerEntry.Insert();
            until FALedgerEntry.Next() = 0;
    end;

    local procedure SnapshotMaintenanceLedgerEntriesForComparison(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var BeforeMaintenanceLedgerEntry: Record "Maintenance Ledger Entry" temporary)
    begin
        if MaintenanceLedgerEntry.FindSet() then
            repeat
                BeforeMaintenanceLedgerEntry := MaintenanceLedgerEntry;
                BeforeMaintenanceLedgerEntry.Insert();
            until MaintenanceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyAmbiguousFARetry()
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Get(1);
        Assert.IsTrue(FALedgerEntry."Legacy Derogatory Ambiguous", 'The original source must remain ambiguous.');
        FALedgerEntry.Get(4);
        Assert.IsTrue(FALedgerEntry."Legacy Derogatory Ambiguous", 'The new source must remain ambiguous while the original source competes.');
        FALedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        FALedgerEntry.SetFilter("Derogatory Source Entry No.", '<>0');
        Assert.RecordIsEmpty(FALedgerEntry);
    end;

    local procedure VerifyAmbiguousMaintenanceRetry()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.Get(1);
        Assert.IsTrue(MaintenanceLedgerEntry."Legacy Derogatory Ambiguous", 'The original source must remain ambiguous.');
        MaintenanceLedgerEntry.Get(4);
        Assert.IsTrue(MaintenanceLedgerEntry."Legacy Derogatory Ambiguous", 'The new source must remain ambiguous while the original source competes.');
        MaintenanceLedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        MaintenanceLedgerEntry.SetFilter("Derogatory Source Entry No.", '<>0');
        Assert.RecordIsEmpty(MaintenanceLedgerEntry);
    end;

    local procedure VerifyAutomaticFAHistoricalReversal(NewEntryNo: Integer; ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        CounterpartReversalFALedgerEntry: Record "FA Ledger Entry";
    begin
        Assert.AreNotEqual(0, NewEntryNo, 'The marked automatic entry must not silently skip its counterpart.');
        CounterpartFALedgerEntry.Get(2);
        CounterpartReversalFALedgerEntry.Get(NewEntryNo);
        Assert.IsTrue(CounterpartFALedgerEntry.Reversed, 'The historical counterpart must be reversed.');
        Assert.AreEqual(NewEntryNo, CounterpartFALedgerEntry."Reversed by Entry No.", 'The counterpart must point to its reversal.');
        Assert.AreEqual(CounterpartFALedgerEntry."Entry No.", CounterpartReversalFALedgerEntry."Reversed Entry No.", 'The reversal must point to the historical counterpart.');
        Assert.AreEqual(ReversingFALedgerEntry."Entry No.", CounterpartReversalFALedgerEntry."Derogatory Source Entry No.", 'The tax reversal must link to the normal reversal.');
        Assert.AreEqual(-CounterpartFALedgerEntry.Amount, CounterpartReversalFALedgerEntry.Amount, 'The reversal must negate the historical amount.');
    end;

    local procedure VerifyAutomaticFAReversalAmbiguityError(ReversingFALedgerEntry: Record "FA Ledger Entry")
    begin
        Assert.ExpectedError(StrSubstNo(AmbiguousHistoricalCounterpartErr, ReversingFALedgerEntry."Reversed Entry No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifyBulkFAIdentityPairs(AssetCount: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        AssetIndex: Integer;
    begin
        for AssetIndex := 1 to AssetCount do begin
            FALedgerEntry.Get(2 * AssetIndex);
            Assert.AreEqual(2 * AssetIndex - 1, FALedgerEntry."Derogatory Source Entry No.", 'Each counterpart must link only to the same active or canceled asset.');
        end;
    end;

#if not CLEAN30
    local procedure VerifyCompanyLocalCompletion(OtherCompanyName: Text[30])
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        OtherFeatureDataUpdateStatus: Record "Feature Data Update Status";
        OtherDepreciationBook: Record "Depreciation Book";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
    begin
        GetFeatureDataUpdateStatus(FeatureDataUpdateStatus);
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete;
        FeatureDataUpdateStatus.Modify();
        if not OtherFeatureDataUpdateStatus.Get(FeatureDataUpdateStatus."Feature Key", OtherCompanyName) then begin
            OtherFeatureDataUpdateStatus."Feature Key" := FeatureDataUpdateStatus."Feature Key";
            OtherFeatureDataUpdateStatus."Company Name" := OtherCompanyName;
            OtherFeatureDataUpdateStatus.Insert();
        end;
        OtherFeatureDataUpdateStatus."Feature Status" := OtherFeatureDataUpdateStatus."Feature Status"::Pending;
        OtherFeatureDataUpdateStatus.Modify();
        OtherDepreciationBook.ChangeCompany(OtherCompanyName);
        OtherDepreciationBook.Code := 'LOCAL';
        OtherDepreciationBook."G/L Integration - Derogatory" := true;
        OtherDepreciationBook.Insert();
        ClearMigrationTags();

        AcceleratedDeprFeature.AfterUpdate(FeatureDataUpdateStatus);

        OtherFeatureDataUpdateStatus.Get(FeatureDataUpdateStatus."Feature Key", OtherCompanyName);
        OtherDepreciationBook.Get('LOCAL');
        Assert.AreEqual(OtherFeatureDataUpdateStatus."Feature Status"::Pending, OtherFeatureDataUpdateStatus."Feature Status", 'Other companies must remain pending.');
        Assert.IsFalse(OtherDepreciationBook."Integration G/L - Derogatory", 'Another company must not be migrated.');
        Assert.IsTrue(OtherDepreciationBook."G/L Integration - Derogatory", 'Another company must retain its legacy setup.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'The current company must acquire the completion tag.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), OtherCompanyName), 'Another company must not acquire the completion tag.');
        Error(TestBodyCompletedErr);
    end;
#endif

    local procedure VerifyFormerCounterpartSourceHistory()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        VerifyHistoricalLink(2, 1);
        VerifyHistoricalLink(6, 5);
        VerifyHistoricalLink(4, 3);
        VerifyHistoricalLink(7, 0);
        FALedgerEntry.SetRange("Legacy Derogatory Ambiguous", true);
        Assert.IsTrue(FALedgerEntry.IsEmpty(), 'Former FA counterparts must not compete with genuine sources.');
        MaintenanceLedgerEntry.SetRange("Legacy Derogatory Ambiguous", true);
        Assert.IsTrue(MaintenanceLedgerEntry.IsEmpty(), 'Former maintenance counterparts must not compete with genuine sources.');
    end;

    local procedure VerifyHistoricalLink(EntryNo: Integer; ExpectedSourceEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        FALedgerEntry.Get(EntryNo);
        Assert.AreEqual(
            ExpectedSourceEntryNo, FALedgerEntry."Derogatory Source Entry No.",
            StrSubstNo('FA entry %1 must respect the preserved source and reversal-chain links.', EntryNo));
        MaintenanceLedgerEntry.Get(EntryNo);
        Assert.AreEqual(
            ExpectedSourceEntryNo, MaintenanceLedgerEntry."Derogatory Source Entry No.",
            StrSubstNo('Maintenance entry %1 must respect the preserved source and reversal-chain links.', EntryNo));
    end;

    local procedure VerifyLegacyMaintenanceFallback(NoUsableCandidate: Boolean)
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        OtherMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        Maintenance: Record Maintenance;
        OtherMaintenance: Record Maintenance;
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        CreateHistoricalFAFixture(SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        LibraryFixedAsset.CreateMaintenance(OtherMaintenance);
        SourceMaintenanceLedgerEntry."Entry No." := 1;
        SourceMaintenanceLedgerEntry."FA No." := SourceFALedgerEntry."FA No.";
        SourceMaintenanceLedgerEntry."Depreciation Book Code" := SourceDepreciationBookCode;
        SourceMaintenanceLedgerEntry."Maintenance Code" := Maintenance.Code;
        SourceMaintenanceLedgerEntry.Amount := 100;
        SourceMaintenanceLedgerEntry."Posting Date" := WorkDate();
        SourceMaintenanceLedgerEntry."FA Posting Date" := WorkDate();
        SourceMaintenanceLedgerEntry."Document Date" := WorkDate();
        SourceMaintenanceLedgerEntry."Document No." := 'DOC';
        SourceMaintenanceLedgerEntry.Insert();
        CounterpartMaintenanceLedgerEntry := SourceMaintenanceLedgerEntry;
        CounterpartMaintenanceLedgerEntry."Entry No." := 2;
        CounterpartMaintenanceLedgerEntry."Depreciation Book Code" := DerogatoryDepreciationBookCode;
        CounterpartMaintenanceLedgerEntry.Insert();
        ReversingMaintenanceLedgerEntry := SourceMaintenanceLedgerEntry;
        ReversingMaintenanceLedgerEntry."Entry No." := 3;
        ReversingMaintenanceLedgerEntry.Amount := -100;
        ReversingMaintenanceLedgerEntry."Reversed Entry No." := 1;
        ReversingMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" := true;
        ReversingMaintenanceLedgerEntry.Insert();
        OtherMaintenanceLedgerEntry := CounterpartMaintenanceLedgerEntry;
        OtherMaintenanceLedgerEntry."Entry No." := 4;
        OtherMaintenanceLedgerEntry."Maintenance Code" := OtherMaintenance.Code;
        OtherMaintenanceLedgerEntry.Insert();
        OtherMaintenanceLedgerEntry."Entry No." := 5;
        OtherMaintenanceLedgerEntry."Maintenance Code" := Maintenance.Code;
        OtherMaintenanceLedgerEntry.Amount := 200;
        OtherMaintenanceLedgerEntry.Insert();

        if NoUsableCandidate then begin
            OtherMaintenanceLedgerEntry := CounterpartMaintenanceLedgerEntry;
            OtherMaintenanceLedgerEntry."Entry No." := 6;
            OtherMaintenanceLedgerEntry.Reversed := true;
            OtherMaintenanceLedgerEntry.Insert();
            OtherMaintenanceLedgerEntry."Entry No." := 7;
            OtherMaintenanceLedgerEntry."Reversed Entry No." := 6;
            OtherMaintenanceLedgerEntry.Amount := -100;
            OtherMaintenanceLedgerEntry.Insert();
            OtherMaintenanceLedgerEntry.Get(6);
            OtherMaintenanceLedgerEntry."Reversed by Entry No." := 7;
            OtherMaintenanceLedgerEntry.Modify();
            OtherMaintenanceLedgerEntry := SourceMaintenanceLedgerEntry;
            OtherMaintenanceLedgerEntry."Entry No." := 8;
            OtherMaintenanceLedgerEntry."Document No." := 'OTHER';
            OtherMaintenanceLedgerEntry.Insert();
            CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := 8;
            CounterpartMaintenanceLedgerEntry.Modify();
            asserterror FAInsertLedgerEntry.InsertMaintRevEntryForDerog(2, NewEntryNo, ReversingMaintenanceLedgerEntry);
            Assert.ExpectedError(StrSubstNo(AmbiguousHistoricalCounterpartErr, 1));
            Assert.ExpectedErrorCode('Dialog');
            exit;
        end;

        FAInsertLedgerEntry.InsertMaintRevEntryForDerog(2, NewEntryNo, ReversingMaintenanceLedgerEntry);
        CounterpartMaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(NewEntryNo, CounterpartMaintenanceLedgerEntry."Reversed by Entry No.", 'Only the exact maintenance candidate may be reversed.');
        OtherMaintenanceLedgerEntry.Get(4);
        Assert.AreEqual(0, OtherMaintenanceLedgerEntry."Reversed by Entry No.", 'Different maintenance code must be excluded.');
        OtherMaintenanceLedgerEntry.Get(5);
        Assert.AreEqual(0, OtherMaintenanceLedgerEntry."Reversed by Entry No.", 'Different maintenance amount must be excluded.');
    end;

    local procedure VerifyLinkageCounts(ExpectedLinkedCount: Integer; ExpectedAmbiguousCount: Integer; ExpectedMissingCount: Integer; LinkedCount: Integer; AmbiguousCount: Integer; MissingCount: Integer)
    begin
        Assert.AreEqual(ExpectedLinkedCount, LinkedCount, 'Unexpected number of new links.');
        Assert.AreEqual(ExpectedAmbiguousCount, AmbiguousCount, 'Only newly ambiguous sources must be counted.');
        Assert.AreEqual(ExpectedMissingCount, MissingCount, 'Unexpected number of missing counterparts.');
    end;

    local procedure VerifyMigrationFieldValues(NonDefaultValues: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        SourceBookCode: Code[10];
        TargetBookCode: Code[10];
        SourceDate: Date;
        TargetDate: Date;
        SourceAccountNos: array[4] of Code[20];
        TargetAccountNos: array[4] of Code[20];
        AccountIndex: Integer;
    begin
        ClearMigrationTags();
        InitializeLinkageTestData();
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        CreateFixedAssetWithPostingGroup(FixedAsset, FAPostingGroup);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FAPostingGroup.Code);
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        CreateFALedgerEntry(1, FixedAsset."No.", DepreciationBook.Code, false, 0,
            FALedgerEntry."FA Posting Type"::Depreciation, false, 0, 0);
        FALedgerEntry.Get(1);
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate);
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
        LibraryFixedAsset.CreateFAReclassJournal(FAReclassJournalLine, FAReclassJournalTemplate.Name, FAReclassJournalBatch.Name);
        if NonDefaultValues then begin
            SourceBookCode := SourceDepreciationBookCode;
            SourceDate := WorkDate();
            for AccountIndex := 1 to ArrayLen(SourceAccountNos) do
                SourceAccountNos[AccountIndex] := LibraryERM.CreateGLAccountNo();
        end else begin
            TargetBookCode := SourceDepreciationBookCode;
            TargetDate := WorkDate();
            for AccountIndex := 1 to ArrayLen(TargetAccountNos) do
                TargetAccountNos[AccountIndex] := LibraryERM.CreateGLAccountNo();
        end;

        SetMigrationFieldValues(DepreciationBook.RecordId(), 10800, DepreciationBook.FieldNo("Derogatory Calc."), SourceBookCode, TargetBookCode);
        SetMigrationFieldValues(DepreciationBook.RecordId(), 10802, DepreciationBook.FieldNo("Integration G/L - Derogatory"), NonDefaultValues, not NonDefaultValues);
        SetMigrationFieldValues(FADepreciationBook.RecordId(), 10801, FADepreciationBook.FieldNo("Last Derogatory"), SourceDate, TargetDate);
        SetMigrationFieldValues(FALedgerEntry.RecordId(), 10800, FALedgerEntry.FieldNo("Derogatory Excluded"), NonDefaultValues, not NonDefaultValues);
        SetMigrationFieldValues(FAPostingGroup.RecordId(), 10800, FAPostingGroup.FieldNo("Derogatory Acc."), SourceAccountNos[1], TargetAccountNos[1]);
        SetMigrationFieldValues(FAPostingGroup.RecordId(), 10801, FAPostingGroup.FieldNo("Derogatory Account (Decrease)"), SourceAccountNos[2], TargetAccountNos[2]);
        SetMigrationFieldValues(FAPostingGroup.RecordId(), 10802, FAPostingGroup.FieldNo("Derog. Bal. Account (Decrease)"), SourceAccountNos[3], TargetAccountNos[3]);
        SetMigrationFieldValues(FAPostingGroup.RecordId(), 10803, FAPostingGroup.FieldNo("Derogatory Expense Acc."), SourceAccountNos[4], TargetAccountNos[4]);
        SetMigrationFieldValues(FAReclassJournalLine.RecordId(), 10800, FAReclassJournalLine.FieldNo("Reclass. Derogatory"), NonDefaultValues, not NonDefaultValues);

        RunFieldMigration();

        DepreciationBook.Get(DepreciationBook.Code);
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FALedgerEntry.Get(1);
        FAPostingGroup.Get(FAPostingGroup.Code);
        FAReclassJournalLine.Get(FAReclassJournalTemplate.Name, FAReclassJournalBatch.Name, FAReclassJournalLine."Line No.");
        Assert.AreEqual(SourceBookCode, DepreciationBook."Derogatory Calc.", 'Relationship mapping is incorrect.');
        Assert.AreEqual(NonDefaultValues, DepreciationBook."Integration G/L - Derogatory", 'Integration flag mapping is incorrect.');
        Assert.AreEqual(SourceDate, FADepreciationBook."Last Derogatory", 'The Date must map to field 5866, not the FlowField.');
        Assert.AreEqual(NonDefaultValues, FALedgerEntry."Derogatory Excluded", 'Exclusion flag mapping is incorrect.');
        Assert.AreEqual(SourceAccountNos[1], FAPostingGroup."Derogatory Acc.", 'Account mapping is incorrect.');
        Assert.AreEqual(SourceAccountNos[2], FAPostingGroup."Derogatory Account (Decrease)", 'Decrease account mapping is incorrect.');
        Assert.AreEqual(SourceAccountNos[3], FAPostingGroup."Derog. Bal. Account (Decrease)", 'Balancing account mapping is incorrect.');
        Assert.AreEqual(SourceAccountNos[4], FAPostingGroup."Derogatory Expense Acc.", 'Expense account mapping is incorrect.');
        Assert.AreEqual(NonDefaultValues, FAReclassJournalLine."Reclass. Derogatory", 'Reclassification flag mapping is incorrect.');
    end;

#if not CLEAN30
    local procedure VerifyMigrationWithIndirectLedgerPermissions()
    var
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        DepreciationBook.Get(DerogatoryDepreciationBookCode);
        Assert.AreEqual(SourceDepreciationBookCode, DepreciationBook."Derogatory Calc.", 'The relationship must be migrated.');
        FALedgerEntry.Get(1);
        Assert.IsTrue(FALedgerEntry."Derogatory Excluded", 'The legacy exclusion flag must be migrated.');
        FALedgerEntry.Get(2);
        Assert.AreEqual(1, FALedgerEntry."Derogatory Source Entry No.", 'The FA counterpart must be linked.');
        MaintenanceLedgerEntry.Get(2);
        Assert.AreEqual(1, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The maintenance counterpart must be linked.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()), 'Field migration must complete.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()), 'Historical linkage must complete.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()), 'Corrective linkage must complete.');
    end;
#endif

    local procedure VerifyPreservedChainLink(PreservedEntryNo: Integer; PreservedSourceEntryNo: Integer; TargetEntryNo: Integer; ExpectedSourceEntryNo: Integer)
    begin
        VerifyHistoricalLink(PreservedEntryNo, PreservedSourceEntryNo);
        VerifyHistoricalLink(TargetEntryNo, ExpectedSourceEntryNo);
    end;


}
