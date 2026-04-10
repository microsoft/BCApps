codeunit 132533 "Backup Management Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Backup Management]
        Initialized := false;
    end;

    var
        BackupMgt: Codeunit "Backup Management";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Initialized: Boolean;
        BackupName: Label 'Backup-Restore Test';
        SelfDescribingValue: Label 'Self-describing value';
        MaxBackupError: Label 'Cannot create more than %1 backups.';
        UnExpectedErrorError: Label 'Unexpected error';
        TableEmptyError: Label '%1 table cannot be empty.';
        RestoreError: Label '%1 not restored.';
        RestoreInsertionError: Label '%1 should have been removed.';
        BackupExistsError: Label 'Backup %1 already exists.';
        BackupNotFoundError: Label 'Could not find backup %1.';
        BackupOverwrittenError: Label '%1 backup should have stayed the same.';
        BackupDeletionError: Label 'Backup %1 should not exist.';
        TableDeletionError: Label '%1 table should be empty.';

    [Normal]
    local procedure Initialize()
    var
        i: Integer;
    begin
        BackupMgt.DeleteAll();
        if Initialized then
            exit;

        // every test codeunit needs to call DefaultFixture
        BackupMgt.DefaultFixture();

        BackupMgt.DeleteAllData();
        for i := 1 to 5 do begin
            CreateItem();
            CreateCustomer();
        end;

        Commit();
        Initialized := true
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaxBackupsTest()
    var
        i: Integer;
    begin
        // Test the limit on the number of backups

        // Setup
        Initialize();

        // Exercise
        for i := 1 to MaxUserBackups() do
            BackupMgt.BackupTable(Format(i), DATABASE::Item);
        BackupMgt.DeleteBackup('1');
        BackupMgt.BackupTable('1', DATABASE::Item);

        // Exercise, Verify
        asserterror BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Assert.AreEqual(GetLastErrorText, StrSubstNo(MaxBackupError, MaxUserBackups()), UnExpectedErrorError)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestorePersistentBackup()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that a persistent backup is reloaded in-memory

        // Setup
        Initialize();
        ItemCount := Item.Count();
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.DeleteAll();
        // Delete only the in-memory backups
        BackupMgt.DeleteAll();

        // Exercise, verify
        asserterror BackupMgt.RestoreDatabase(BackupName);
        Assert.AreEqual(StrSubstNo(BackupNotFoundError, BackupName), GetLastErrorText, UnExpectedErrorError);

        // Teardown: clean up the (persistent) backup again
        BackupMgt.DeleteBackup(BackupName)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreModificationTest()
    var
        Item: Record Item;
        ItemDescription: Text[1000];
    begin
        // Test that a modified record is restored by a database restore

        // Setup
        Initialize();
        Assert.IsTrue(Item.FindSet(), StrSubstNo(TableEmptyError, 'Item'));
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemDescription := Item.Description;

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.Description := SelfDescribingValue;
        Item.Modify();
        Item.Get(Item."No.");
        BackupMgt.RestoreDatabase(BackupName);

        // Verify
        Item.Get(Item."No.");
        Assert.AreEqual(ItemDescription, Item.Description, StrSubstNo(RestoreError, 'Item.Description'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreDeletionTest()
    var
        Item: Record Item;
        ItemNo: Code[10];
    begin
        // Test that a deleted record is restored by a database restore

        // Setup
        Initialize();
        Assert.IsTrue(Item.FindSet(), StrSubstNo(TableEmptyError, 'Item'));
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemNo := Item."No.";
        Item.Description := SelfDescribingValue;
        Item.Modify();

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.Delete();
        BackupMgt.RestoreDatabase(BackupName);

        // Verify
        Item.Get(ItemNo);
        Assert.AreEqual(Format(SelfDescribingValue), Item.Description, StrSubstNo(RestoreError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreDeletionAllTest()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that a deleted table is restored by a database restore

        // Setup
        Initialize();
        ItemCount := Item.Count();
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.DeleteAll();
        BackupMgt.RestoreDatabase(BackupName);

        // Verify
        Assert.AreEqual(ItemCount, Item.Count, StrSubstNo(RestoreError, 'All items'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreInsertionTest()
    var
        Item: Record Item;
    begin
        // Test that an insertion is undone by a database restore

        // Setup
        Initialize();
        if Item.Get('TEST') then
            Item.Delete();

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.Init();
        Item."No." := 'TEST';
        Item.Insert();
        BackupMgt.RestoreDatabase(BackupName);

        // Verify
        Assert.IsFalse(Item.Get('TEST'), StrSubstNo(RestoreInsertionError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupExistsErrorTest()
    begin
        // Test that no two backups with the same name can be created

        // Setup
        Initialize();

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);

        // Exercise, Verify
        asserterror BackupMgt.BackupDatabase(BackupName);

        // Verify
        Assert.AreEqual(StrSubstNo(BackupExistsError, BackupName), GetLastErrorText, UnExpectedErrorError)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreNotExistsErrorTest()
    begin
        // Test that attempting to restore a non-existent database backup gives an error.

        // Setup
        Initialize();

        // Exercise, Verify
        asserterror BackupMgt.RestoreDatabase(BackupName);

        // Verify
        Assert.AreEqual(StrSubstNo(BackupNotFoundError, BackupName), GetLastErrorText, UnExpectedErrorError)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableModificationTest()
    var
        Item: Record Item;
        ItemDescription: Text[1000];
    begin
        // Test that a record modification is undone by a table restore

        // Setup
        Initialize();
        Assert.IsTrue(Item.FindSet(), StrSubstNo(TableEmptyError, 'Item'));
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemDescription := Item.Description;

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.Description := SelfDescribingValue;
        Item.Modify();
        Item.Get(Item."No.");
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Item.Get(Item."No.");
        Assert.AreEqual(ItemDescription, Item.Description, StrSubstNo(RestoreError, 'Item.Description'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableDeletionTest()
    var
        Item: Record Item;
        ItemNo: Code[10];
    begin
        // Test that a record deletion is undone by a table restore

        // Setup
        Initialize();
        Assert.IsTrue(Item.FindSet(), StrSubstNo(TableEmptyError, 'Item'));
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemNo := Item."No.";
        Item.Description := SelfDescribingValue;
        Item.Modify();

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.Delete();
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Item.Get(ItemNo);
        Assert.AreEqual(Format(SelfDescribingValue), Item.Description, StrSubstNo(RestoreError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableDeletionAllTes()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that a table deletion is undone by a table restore.

        // Setup
        Initialize();
        ItemCount := Item.Count();
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.DeleteAll();
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.AreEqual(ItemCount, Item.Count, StrSubstNo(RestoreError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableInsertionTest()
    var
        Item: Record Item;
    begin
        // Test that a record insertion is undone by a table restore

        // Setup
        Initialize();
        if Item.Get('Test') then
            Item.Delete();

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.Init();
        Item."No." := 'TEST';
        Item.Insert();
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.IsFalse(Item.Get('TEST'), StrSubstNo(RestoreInsertionError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableFromDBBackupTest()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that a single table can be restored from a full database backup.

        // Setup
        Initialize();
        ItemCount := Item.Count();
        Assert.IsFalse(Item.IsEmpty, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupDatabase(BackupName);
        Item.DeleteAll();
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.AreEqual(ItemCount, Item.Count, StrSubstNo(RestoreError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupTableExistingBackupTest()
    var
        Item: Record Item;
        Customer: Record Customer;
        ItemCount: Integer;
        CustomerCount: Integer;
    begin
        // Test that a table backup can be added to an existing database backup

        // Setup
        Initialize();
        ItemCount := Item.Count();
        CustomerCount := Customer.Count();
        Assert.AreNotEqual(0, CustomerCount, StrSubstNo(TableEmptyError, 'Customer'));
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.BackupTable(BackupName, DATABASE::Customer);
        Item.DeleteAll();
        Customer.DeleteAll();
        Assert.IsTrue(Customer.IsEmpty, 'Customer should be empty.');
        Assert.IsTrue(Item.IsEmpty, 'Item should be empty.');
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);
        BackupMgt.RestoreTable(BackupName, DATABASE::Customer);

        // Verify
        Assert.AreEqual(CustomerCount, Customer.Count, 'Not all Customers restored.');
        Assert.AreEqual(ItemCount, Item.Count, 'Not all Items restored.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupTableTwiceTest()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that the second time a table is backed up, the first backup is not overwritten

        // Setup
        Initialize();
        if Item.Get('TEST') then
            Item.Delete();
        ItemCount := Item.Count();
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.Init();
        Item."No." := 'TEST';
        Item.Description := SelfDescribingValue;
        Item.Insert();
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.AreEqual(ItemCount, Item.Count, StrSubstNo(BackupOverwrittenError, 'Item'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupDeleteBackupTableTest()
    var
        Item: Record Item;
        ItemCount: Integer;
    begin
        // Test that an empty table backup will be overwritten

        // Setup
        Initialize();
        if Item.Get('TEST') then
            Item.Delete();
        ItemCount := Item.Count();
        Assert.AreNotEqual(0, ItemCount, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable('Temp', DATABASE::Item);
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.DeleteTable(BackupName, DATABASE::Item);
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);
        Item.Init();
        Item."No." := 'TEST';
        Item.Description := SelfDescribingValue;
        Item.Insert();
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        Item.DeleteAll();
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.AreEqual(1, Item.Count, StrSubstNo(RestoreError, 'Item'));

        // Tear down
        BackupMgt.RestoreTable('Temp', DATABASE::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableNoBackupErrorTest()
    begin
        // Test that attempting to restore a table from a non-existing backup gives an error

        // Setup
        Initialize();

        // Exercise, Verify
        asserterror BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.AreEqual(StrSubstNo(BackupNotFoundError, BackupName), GetLastErrorText, UnExpectedErrorError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestoreTableEmptyTest()
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        // Test that restoring a non-existing table backup results in an empty table

        // Setup
        Initialize();
        Assert.IsFalse(Item.IsEmpty, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable('Temp', DATABASE::Item);
        Assert.IsFalse(Customer.IsEmpty, StrSubstNo(TableEmptyError, 'Customer'));
        BackupMgt.BackupTable(BackupName, DATABASE::Customer);
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.IsTrue(Item.IsEmpty, StrSubstNo(RestoreError, 'Item'));

        // Tear down
        BackupMgt.RestoreTable('Temp', DATABASE::Item)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllBackupsTest()
    begin
        // Test that all database backups are deleted

        // Setup
        Initialize();

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.BackupTable(BackupName + '2', DATABASE::Item);
        BackupMgt.DeleteAll();

        // Verify
        Assert.IsFalse(BackupMgt.BackupExists(BackupName), StrSubstNo(BackupDeletionError, BackupName));
        Assert.IsFalse(BackupMgt.BackupExists(BackupName + '2'), StrSubstNo(BackupDeletionError, BackupName + '2'))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteBackupTest()
    begin
        // Test that a database backup is deleted

        // Setup
        Initialize();

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.DeleteBackup(BackupName);

        // Verify
        Assert.IsFalse(BackupMgt.BackupExists(BackupName), StrSubstNo(BackupDeletionError, BackupName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTableBackupTest()
    var
        Item: Record Item;
    begin
        // Test that a table backup is deleted

        // Setup
        Initialize();
        Assert.IsFalse(Item.IsEmpty, StrSubstNo(TableEmptyError, 'Item'));

        // Exercise
        BackupMgt.BackupTable(BackupName, DATABASE::Item);
        BackupMgt.DeleteTable(BackupName, DATABASE::Item);
        BackupMgt.RestoreTable(BackupName, DATABASE::Item);

        // Verify
        Assert.IsTrue(Item.IsEmpty, StrSubstNo(TableDeletionError, 'Item'))
    end;

    [Normal]
    local procedure CreateItem()
    var
        Item: Record Item;
        ItemNo: Code[10];
    begin
        repeat
            ItemNo := Format(LibraryRandom.RandInt(100))
        until not Item.Get(ItemNo);

        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item.Insert();
    end;

    [Normal]
    local procedure CreateCustomer()
    var
        Customer: Record Customer;
        CustomerNo: Code[10];
    begin
        repeat
            CustomerNo := Format(LibraryRandom.RandInt(100))
        until not Customer.Get(CustomerNo);

        Customer."No." := CustomerNo;
        Customer.Insert();
    end;

    [Normal]
    local procedure MaxUserBackups(): Integer
    begin
        exit(5)
    end;
}

