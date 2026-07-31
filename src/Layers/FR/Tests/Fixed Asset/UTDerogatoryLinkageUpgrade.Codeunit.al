// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134167 "UT Derogatory Linkage Upg."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(1, 'NORMAL', false, 0, 0);
        CreateFALedgerEntry(2, 'TAX', false, 0, 0);

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(10, 'NORMAL', true, 100, 0);
        CreateFALedgerEntry(11, 'TAX', true, 200, 0);

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(20, 'NORMAL', true, 0, 100);
        CreateFALedgerEntry(21, 'TAX', true, 0, 200);

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(10, 'NORMAL', false, 0, 0);
        CreateFALedgerEntry(9, 'TAX', false, 0, 0);
        CreateFALedgerEntry(11, 'TAX', false, 0, 0);

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(1, 'NORMAL', false, 0, 0);

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
        CreateDepreciationBooks();
        CreateMaintenanceLedgerEntry(1, 'NORMAL');
        CreateMaintenanceLedgerEntry(2, 'TAX');

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
        CreateDepreciationBooks();
        CreateFALedgerEntry(1, 'NORMAL', false, 0, 0);
        CreateFALedgerEntry(2, 'TAX', false, 0, 0);
        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := 1;
        DerogatoryFALedgerEntry.Modify();

        UpgradeDerogatoryLinkage.LinkFALedgerEntries(LinkedCount, AmbiguousCount, MissingCount);

        DerogatoryFALedgerEntry.Get(2);
        DerogatoryFALedgerEntry.TestField("Derogatory Source Entry No.", 1);
        Assert.AreEqual(0, LinkedCount, 'Repeated processing must not create another link.');
    end;

    local procedure CreateDepreciationBooks()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := 'NORMAL';
        DepreciationBook.Insert();
        DepreciationBook.Code := 'TAX';
        DepreciationBook."Derogatory Calc." := 'NORMAL';
        DepreciationBook.Insert();
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
