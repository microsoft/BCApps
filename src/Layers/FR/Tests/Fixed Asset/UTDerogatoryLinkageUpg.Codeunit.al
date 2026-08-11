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
        TestBodyCompleted: Boolean;
        TestBodyCompletedErr: Label 'The test body ran to completion.';
#if not CLEAN29
        SimulatedBodyFailureErr: Label 'Simulated failure after the test body toggled the French feature state.';
#endif

#if not CLEAN29
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DisabledFeatureFAJournalUsesOnlyLegacyRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            DisabledFeatureFAJournalBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

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

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EnabledFeatureFAJournalUsesOnlyCentralRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            EnabledFeatureFAJournalBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

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
#else
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Clean29FAJournalUsesCentralRelationship()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            Clean29FAJournalBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

    local procedure Clean29FAJournalBody()
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
        Assert.AreEqual(2, FALedgerEntry.Count(), 'CLEAN29 must post the source and one central counterpart.');
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBook.Code);
        Assert.AreEqual(1, FALedgerEntry.Count(), 'CLEAN29 must use the central relationship.');
        FALedgerEntry.FindFirst();
        Assert.AreNotEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'The CLEAN29 counterpart must be linked.');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            FAReversalOverloadBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
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

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenanceReversalCompatibilityOverloadCreatesLinkedCounterpart()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            MaintenanceReversalOverloadBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

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

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneratedMirrorDoesNotRunDuplicateBookDispatcher()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            GeneratedMirrorDuplicationBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
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
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            DisabledFeatureReversalBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
    end;

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
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NormalBookValueExcludesDerogatoryEntry()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            NormalBookValueBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
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
#if not CLEAN29
        FALedgerEntry.TestField("Exclude Derogatory", true);
#endif
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SalvageCounterpartReversalKeepsReversalSourceCode()
    var
        PreviousFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        asserterror begin
            SalvageReversalSourceCodeBody();
            CompleteTestBody();
        end;
        RestoreFeatureStateAfterTestBody(PreviousFeatureStatus);
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

#if not CLEAN29
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedTestBodyRestoresFeatureState()
    var
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
        PreviousFeatureStatus: Integer;
        BaselineFeatureStatus: Integer;
    begin
        PreviousFeatureStatus := CaptureFeatureStateIfRequired();
        DisableAcceleratedDepreciationFeature();
        Commit();
        BaselineFeatureStatus := CaptureFeatureStateIfRequired();

        asserterror begin
            SimulatedFailureBody();
            CompleteTestBody();
        end;
        asserterror RestoreFeatureStateAfterTestBody(BaselineFeatureStatus);

        // The rethrown body failure must not take the restored feature state with it.
        Assert.IsFalse(
            AcceleratedDeprFeature.IsEnabled(),
            'The failed test body must not leave the toggled French feature state committed.');
        RestoreFeatureStateIfRequired(PreviousFeatureStatus);
    end;

    local procedure SimulatedFailureBody()
    begin
        EnableAcceleratedDepreciationFeature();
        Commit();
        Error(SimulatedBodyFailureErr);
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
        CreateFALedgerEntry(10, 'FA2', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(9, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(11, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

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
        // RISK-005 regression: two otherwise-identical sources both uniquely match the SAME single candidate.
        // Entry-number-proximity tie-breaking must never let whichever source is processed first "win" the link.
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, DerogatoryDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

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
        // The wrong-maintenance-code candidate is deliberately CLOSER in entry number than the right one, so any
        // proximity-based tie-break would wrongly prefer it. Only an explicit "Maintenance Code" match may be used.
        InitializeLinkageTestData();
        CreateMaintenanceLedgerEntry(100, SourceDepreciationBookCode, 'MC1');
        CreateMaintenanceLedgerEntry(102, DerogatoryDepreciationBookCode, 'MC2');
        CreateMaintenanceLedgerEntry(250, DerogatoryDepreciationBookCode, 'MC1');

        UpgradeDerogatoryLinkage.LinkMaintenanceLedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

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
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, 'FA', SourceDepreciationBookCode, true, 500, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(2, 'FA', SourceDepreciationBookCode, false, 500, Enum::"FA Ledger Entry FA Posting Type"::"Acquisition Cost", false, 0, 0);
        CreateFALedgerEntry(3, 'FA', DerogatoryDepreciationBookCode, false, 500, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

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
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, 'FA1', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateCanceledFALedgerEntry(2, DerogatoryDepreciationBookCode, 'FA1');

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

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
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(10, 'FA2', SourceDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(9, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);
        CreateFALedgerEntry(11, 'FA2', DerogatoryDepreciationBookCode, false, 0, Enum::"FA Ledger Entry FA Posting Type"::Depreciation, false, 0, 0);

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);
        Assert.AreEqual(1, LinkedCount, 'First pass must link the unique pair.');
        Assert.AreEqual(1, AmbiguousCount, 'First pass must mark the equidistant source ambiguous.');

        CreateFALedgerEntry(20, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(21, DerogatoryDepreciationBookCode, false, 0, 0);

        LinkedCount := 0;
        AmbiguousCount := 0;
        MissingCount := 0;

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

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
    procedure RunAfterRelationshipTransferSkipsWhenUpgradeTagAlreadySet()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageUpgradeTagIsSet();

        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
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
        InitializeLinkageTestData();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageUpgradeTagIsCleared();

        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()),
            'The linkage upgrade tag must be set after a successful run.');
    end;

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
        InitializeLinkageTestData();
        DepreciationBook.ModifyAll("Derogatory Calc.", '');
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        EnsureDerogatoryLinkageUpgradeTagIsCleared();

        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false);

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
    begin
        // Simulate a stale outcome left by the pre-fix greedy algorithm (RISK-005): source 2 falsely "won" a link to
        // candidate 3 even though source 1 is an equally valid match, and source 1 was never flagged ambiguous.
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(3, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(3);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 2;
        DerogatoryFALedgerEntry.Modify();

        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        DerogatoryFALedgerEntry.Get(3);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        FirstSourceFALedgerEntry.Get(1);
        FirstSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
        SecondSourceFALedgerEntry.Get(2);
        SecondSourceFALedgerEntry.TestField("Legacy Derogatory Ambiguous", true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CorrectiveUpgradeSecondRunMakesNoFurtherChanges()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);

        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);

        // Simulate a manual correction made after the corrective run; a second run must not touch it again.
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 0;
        DerogatoryFALedgerEntry.Modify();

        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

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
    begin
        InitializeLinkageTestData();
        EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared();
        CreateFALedgerEntry(1, SourceDepreciationBookCode, false, 0, 0);
        CreateFALedgerEntry(2, DerogatoryDepreciationBookCode, false, 0, 0);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 1;
        DerogatoryFALedgerEntry.Modify();

        // Corrupt the relationship setup so it becomes ambiguous: a second derogatory book also targets the source book.
        LibraryFixedAsset.CreateDepreciationBook(SecondTaxDepreciationBook);
        SecondTaxDepreciationBook."Derogatory Calc." := SourceDepreciationBookCode;
        SecondTaxDepreciationBook.Modify();

        asserterror UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();

        Assert.ExpectedError('More than one derogatory depreciation book is configured for depreciation book');
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
    end;

    local procedure EnsureDerogatoryLinkageUpgradeTagIsSet()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), CompanyName()) then
            UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
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

    local procedure EnsureDerogatoryLinkageCorrectiveUpgradeTagIsCleared()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag(), CompanyName());
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

    // The posting tests mutate company-wide French feature state and "FA Jnl.-Post Batch" commits it. Their
    // body therefore runs inside asserterror - the only AL construct that catches a failing body while still
    // allowing the database writes these tests need - and the sentinel error below ends a successful body.
    local procedure CompleteTestBody()
    begin
        TestBodyCompleted := true;
        Error(TestBodyCompletedErr);
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
}
