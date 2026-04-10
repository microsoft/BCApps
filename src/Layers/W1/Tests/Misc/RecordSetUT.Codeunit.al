codeunit 134235 "Record Set UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Record Set] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTablesUT: Codeunit "Library - Tables UT";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        NoOfRecordsPerSet: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingKeyWithSingleField()
    var
        Customer: Record Customer;
        TypeHelper: Codeunit "Type Helper";
        "Key": Text;
    begin
        Initialize();

        // Setup
        // Execute
        Key := TypeHelper.GetKeyAsString(Customer, 1);

        // Verify
        Assert.AreEqual(Customer.FieldName("No."), Key, 'Key string does not match the key');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingKeyWithMultipleFields()
    var
        RecordSetDefinition: Record "Record Set Definition";
        TypeHelper: Codeunit "Type Helper";
        "Key": Text;
        ExpectedKey: Text;
    begin
        Initialize();

        // Setup
        // Execute
        Key := TypeHelper.GetKeyAsString(RecordSetDefinition, 1);

        // Verify
        ExpectedKey :=
          StrSubstNo(
            '%1,%2,%3', RecordSetDefinition.FieldName("Table No."), RecordSetDefinition.FieldName("Set ID"),
            RecordSetDefinition.FieldName("Node ID"));
        Assert.AreEqual(ExpectedKey, Key, 'Key string does not match the key');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingNonExistingKeyRaisesAnError()
    var
        RecordSetDefinition: Record "Record Set Definition";
        TypeHelper: Codeunit "Type Helper";
    begin
        Initialize();

        // Execute and verify
        asserterror TypeHelper.GetKeyAsString(RecordSetDefinition, 1000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingAscending()
    var
        TempCustomer: Record Customer temporary;
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        "Key": Text;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        Key := TypeHelper.GetKeyAsString(TempCustomer, 1);
        RecRef.GetTable(TempCustomer);

        // Execute
        TypeHelper.SortRecordRef(RecRef, Key, true);

        // Verify
        TempCustomer.FindFirst();
        Assert.AreEqual(TempCustomer.RecordId, RecRef.RecordId, 'Record was not sorted ascending');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingDescending()
    var
        TempCustomer: Record Customer temporary;
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        "Key": Text;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        Key := TypeHelper.GetKeyAsString(TempCustomer, 1);
        RecRef.GetTable(TempCustomer);

        // Execute
        TypeHelper.SortRecordRef(RecRef, Key, false);

        // Verify
        TempCustomer.FindLast();
        Assert.AreEqual(TempCustomer.RecordId, RecRef.RecordId, 'Record was not sorted descending');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingOnBlankRecordSetDoesNoRaiseAnError()
    var
        TempCustomer: Record Customer temporary;
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        "Key": Text;
    begin
        Initialize();

        // Setup
        TempCustomer.Init();
        Key := TypeHelper.GetKeyAsString(TempCustomer, 1);
        RecRef.GetTable(TempCustomer);

        // Execute
        TypeHelper.SortRecordRef(RecRef, Key, false);

        // Verify
        Assert.IsFalse(TempCustomer.FindLast(), 'No records should exist');
        Assert.IsTrue(StrPos(RecRef.GetView(), 'Descending') > 0, 'Record was not sorted descending');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingOnBlankValueRaisesAnError()
    var
        TempCustomer: Record Customer temporary;
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        TypeHelper.GetKeyAsString(TempCustomer, 1);
        RecRef.GetTable(TempCustomer);

        // Execute and Verify
        asserterror TypeHelper.SortRecordRef(RecRef, '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingSingleEntryRecordSet()
    var
        TempCustomer: Record Customer temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, 1);

        // Execute
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingMultipleEntryRecordsSet()
    var
        TempCustomer: Record Customer temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);

        // Execute
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingSingleEntryRecordSetDifferentTableExist()
    var
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, 1);
        CreateTestItems(TempItem, 1);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Execute
        ItemSetID := RecordSetManagement.SaveSetSingleTable(TempItem);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingMultipleEntryRecordsSetDifferentTableExist()
    var
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Execute
        ItemSetID := RecordSetManagement.SaveSetSingleTable(TempItem);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingMixedTablesRecordSetsSingleRecord()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, 1, 1);

        // Execute
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingMixedTablesRecordSetsMultipleRecords()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet / 2);

        // Execute
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingSaveSetTwiceOnSameSet()
    var
        TempCustomer: Record Customer temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NewSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Execute
        NewSetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
        Assert.AreEqual(NewSetID, SetID, 'Create set ID should return same set ID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingSaveSetTwiceOnSameSetMultipleSetsPresent()
    var
        TempCustomer: Record Customer temporary;
        TempSecondSetCustomer: Record Customer temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NewSetID: Integer;
        SecondSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        CreateTestCustomers(TempSecondSetCustomer, 1);
        SecondSetID := RecordSetManagement.SaveSetSingleTable(TempSecondSetCustomer);

        // Execute
        NewSetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);

        // Verify
        VerifySetWasSavedCorrectly(SetID, TempCustomer);
        Assert.AreEqual(NewSetID, SetID, 'Create set ID should return same set ID');

        // Execute
        NewSetID := RecordSetManagement.SaveSetSingleTable(TempSecondSetCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempSecondSetCustomer);
        Assert.AreEqual(NewSetID, SecondSetID, 'Create set ID should return same set ID for second set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingSaveSetTwiceOnSameSetMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NewSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet - 2);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        // Execute
        NewSetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        // Verify
        Assert.AreEqual(NewSetID, SetID, 'Create set ID should return same set ID');
        VerifySetWasSavedCorrectly(SetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingFirstElementFromSetCreatesNewSet()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        // Execute
        TempNewCustomer.FindFirst();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingLastElementFromSetCreatesNewSet()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        // Execute
        TempNewCustomer.FindLast();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(
          FirstSetRecordTreeCount, TotalSetTreeCount, 'No new nodes should be created should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingSecondLastElementFromSetCreatesNewSet()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        // Execute
        TempNewCustomer.FindLast();
        TempNewCustomer.Next(-1);
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount + 1, TotalSetTreeCount, 'A leaf should be added to the second last element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingElementFromTheMilldeOfTheSetCreatesNewSet()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        // Execute
        TempNewCustomer.FindFirst();
        TempNewCustomer.Next();
        TempNewCustomer.Next();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 3, TotalSetTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingFirstElementFromSetCreatesNewSetMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
        SecondSetTreeCount: Integer;
        ItemSetDefinitionCount: Integer;
        ItemSetRecordTreeCount: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        CreateSetAndCountEntries(TempItem, ItemSetID, ItemSetDefinitionCount, TotalSetTreeCount);
        ItemSetRecordTreeCount := TotalSetTreeCount - FirstSetRecordTreeCount;
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        // Execute
        TempNewCustomer.FindFirst();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        SecondSetTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 1, SecondSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingLastElementFromSetCreatesNewSetMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
        SecondSetTreeCount: Integer;
        ItemSetDefinitionCount: Integer;
        ItemSetRecordTreeCount: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);

        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);
        CreateSetAndCountEntries(TempItem, ItemSetID, ItemSetDefinitionCount, TotalSetTreeCount);
        ItemSetRecordTreeCount := TotalSetTreeCount - FirstSetRecordTreeCount;

        // Execute
        TempNewCustomer.FindLast();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        SecondSetTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;
        Assert.AreEqual(
          FirstSetRecordTreeCount, SecondSetTreeCount, 'No new nodes should be created');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingElementFromTheMilldeOfTheSetCreatesNewSetMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
        SecondSetTreeCount: Integer;
        ItemSetDefinitionCount: Integer;
        ItemSetRecordTreeCount: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);

        CreateSetAndCountEntries(TempItem, ItemSetID, ItemSetDefinitionCount, ItemSetRecordTreeCount);
        CreateSetAndCountEntries(TempCustomer, FirstSetID, FirstSetRecordDefinitionCount, TotalSetTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);
        FirstSetRecordTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;

        // Execute
        TempNewCustomer.FindFirst();
        TempNewCustomer.Next(2);
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);
        SecondSetTreeCount := TotalSetTreeCount - ItemSetDefinitionCount;

        // Verify
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 3, SecondSetTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingFirstElementFromSetCreatesNewSetMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet / 2);
        CreateSetAndCountEntries(TempRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        // Execute
        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindFirst();
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingLastElementFromSetCreatesNewSetMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet / 2, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        // Execute
        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindLast();
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(
          FirstSetRecordTreeCount, TotalSetTreeCount, 'No new nodes should be created should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingElementFromTheMilldeOfTheSetCreatesNewSetMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        // Execute
        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindFirst();
        TempNewRecordSetBuffer.Next(2);
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount - 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 3, TotalSetTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempNewRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheBeginning()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindFirst();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 + 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheMiddle()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindFirst();
        TempNewCustomer.Next(2);
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 1, TotalSetTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheEnd()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindLast();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount + 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheBeginningMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        ItemSetID: Integer;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        SecondSetRecordTreeCount: Integer;
        TotalSetTreeCount: Integer;
        ItemDefinitionCount: Integer;
        ItemSetRecordTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempItem, ItemSetID, ItemDefinitionCount, ItemSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindFirst();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, TotalSetTreeCount);
        FirstSetRecordTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);
        SecondSetRecordTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;

        // Verify
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(
          FirstSetRecordTreeCount * 2 + 1, SecondSetRecordTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheMiddleMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        ItemSetID: Integer;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        SecondSetRecordTreeCount: Integer;
        TotalSetTreeCount: Integer;
        ItemDefinitionCount: Integer;
        ItemSetRecordTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        CreateSetAndCountEntries(TempItem, ItemSetID, ItemDefinitionCount, ItemSetRecordTreeCount);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindFirst();
        TempNewCustomer.Next();
        TempNewCustomer.Next();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, TotalSetTreeCount);
        FirstSetRecordTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);
        SecondSetRecordTreeCount := TotalSetTreeCount - ItemSetRecordTreeCount;

        // Verify
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(
          FirstSetRecordTreeCount * 2 - 1, SecondSetRecordTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheEndMultipleTables()
    var
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        RecordSetManagement: Codeunit "Record Set Management";
        ItemSetID: Integer;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        ItemSetID := RecordSetManagement.SaveSetSingleTable(TempItem);
        DuplicateCustomerSet(TempCustomer, TempNewCustomer);

        TempNewCustomer.FindLast();
        TempNewCustomer.Delete();
        CreateSetAndCountEntries(TempNewCustomer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempCustomer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        VerifySetWasSavedCorrectly(ItemSetID, TempItem);
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount + 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewCustomer);
        VerifySetWasSavedCorrectly(SecondSetID, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheBeginningMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindFirst();
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 + 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheMiddleMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindFirst();
        TempNewRecordSetBuffer.Next(2);
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount * 2 - 1, TotalSetTreeCount, 'New tree should be created starting from third element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingElementAtTheEndMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempNewRecordSetBuffer: Record "Record Set Buffer" temporary;
        FirstSetID: Integer;
        SecondSetID: Integer;
        FirstSetRecordDefinitionCount: Integer;
        FirstSetRecordTreeCount: Integer;
        SecondSetDefinitionCount: Integer;
        TotalSetTreeCount: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        DuplicateServiceConnectionSet(TempRecordSetBuffer, TempNewRecordSetBuffer);

        SortAscending(TempNewRecordSetBuffer);
        TempNewRecordSetBuffer.FindLast();
        TempNewRecordSetBuffer.Delete();
        CreateSetAndCountEntries(TempNewRecordSetBuffer, FirstSetID, FirstSetRecordDefinitionCount, FirstSetRecordTreeCount);

        // Execute
        CreateSetAndCountEntries(TempRecordSetBuffer, SecondSetID, SecondSetDefinitionCount, TotalSetTreeCount);

        // Verify
        Assert.AreEqual(FirstSetRecordDefinitionCount + 1, SecondSetDefinitionCount, 'Second Record Set should have one entry less');
        Assert.AreEqual(FirstSetRecordTreeCount + 1, TotalSetTreeCount, 'New tree should be created starting from second element');
        Assert.AreNotEqual(FirstSetID, SecondSetID, 'New set ID should be created');
        VerifySetWasSavedCorrectly(FirstSetID, TempNewRecordSetBuffer);
        VerifySetWasSavedCorrectly(SecondSetID, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingNonExistingSetReturnsBlankValue()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetManagement: Codeunit "Record Set Management";
        NonExistingSetID: Integer;
    begin
        Initialize();

        // Setup
        RecordSetDefinition.SetRange("Table No.", DATABASE::Customer);
        NonExistingSetID := 10;
        if RecordSetDefinition.FindLast() then;
        NonExistingSetID := RecordSetDefinition."Set ID" + 1;

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, NonExistingSetID);

        // Verify
        Assert.AreEqual(0, TempRecordSetBuffer.Count, 'Blank set should be returned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingNonExistingSetReturnsBlankValueMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetManagement: Codeunit "Record Set Management";
        NonExistingSetID: Integer;
    begin
        Initialize();

        // Setup
        RecordSetDefinition.SetRange("Table No.", DATABASE::"Service Connection");
        NonExistingSetID := 10;
        if RecordSetDefinition.FindLast() then;
        NonExistingSetID := RecordSetDefinition."Set ID" + 1;

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, NonExistingSetID);

        // Verify
        Assert.AreEqual(0, TempRecordSetBuffer.Count, 'Blank set should be returned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSet()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        DummyCustomer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := DummyCustomer.Count();

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers, DummyCustomer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetMultipleTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempItemRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
        NumberOfItems: Integer;
        ItemSetID: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);

        ItemSetID := RecordSetManagement.SaveSetSingleTable(TempItem);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := DummyCustomer.Count();
        NumberOfItems := DummyItem.Count();

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);
        RecordSetManagement.GetSet(TempItemRecordSetBuffer, ItemSetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempItemRecordSetBuffer, TempItem);
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers, DummyCustomer.Count, 'Number of records should not change');
        Assert.AreEqual(NumberOfItems, DummyItem.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetMixedTables()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadedRecordSetBuffer: Record "Record Set Buffer" temporary;
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
        NumberOfItems: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);

        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfCustomers := DummyCustomer.Count();
        NumberOfItems := DummyItem.Count();

        // Execute
        RecordSetManagement.GetSet(TempLoadedRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempLoadedRecordSetBuffer, TempRecordSetBuffer);
        Assert.AreEqual(NumberOfCustomers, DummyCustomer.Count, 'Number of records should not change');
        Assert.AreEqual(NumberOfItems, DummyItem.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromBegining()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := Customer.Count();
        DeleteCustomer(TempCustomer, 1, TempDeletedCustomerRecordSetBuffer);

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromMiddle()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        NumberOfCustomers := Customer.Count();
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        DeleteCustomer(TempCustomer, NoOfRecordsPerSet - 1, TempDeletedCustomerRecordSetBuffer);

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not chang after getting a set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromEnd()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        NumberOfCustomers := Customer.Count();
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        DeleteCustomer(TempCustomer, NoOfRecordsPerSet, TempDeletedCustomerRecordSetBuffer);

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletingMultipleRecords()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := Customer.Count();
        DeleteCustomer(TempCustomer, 1, TempDeletedCustomerRecordSetBuffer);
        DeleteCustomer(TempCustomer, 2, TempDeletedCustomerRecordSetBuffer);
        DeleteCustomer(TempCustomer, 5, TempDeletedCustomerRecordSetBuffer);
        DeleteCustomer(TempCustomer, 9, TempDeletedCustomerRecordSetBuffer);
        DeleteCustomer(TempCustomer, NoOfRecordsPerSet, TempDeletedCustomerRecordSetBuffer);

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 5, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempRecordSetBuffer, TempCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromBeginingMixedTable()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfCustomers := Customer.Count();

        SortAscending(TempRecordSetBuffer);
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        Customer.Delete();
        TempRecordSetBuffer.Delete();

        // Execute
        RecordSetManagement.GetSet(TempLoadRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempLoadRecordSetBuffer, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromMiddleMixedTable()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfCustomers := Customer.Count();

        SortAscending(TempRecordSetBuffer);
        TempRecordSetBuffer.Next(4);
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        Customer.Delete();
        TempRecordSetBuffer.Delete();

        // Execute
        RecordSetManagement.GetSet(TempLoadRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempLoadRecordSetBuffer, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromEndMixedTable()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadRecordSetBuffer: Record "Record Set Buffer" temporary;
        Item: Record Item;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfItems: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfItems := Item.Count();

        SortAscending(TempRecordSetBuffer);
        TempRecordSetBuffer.FindLast();
        Item.Get(TempRecordSetBuffer."Value RecordID");
        Item.Delete();
        TempRecordSetBuffer.Delete();

        // Execute
        RecordSetManagement.GetSet(TempLoadRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfItems - 1, Item.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempLoadRecordSetBuffer, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingExistingSetAfterDeletionFromMultipleMixedTable()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfCustomers := Customer.Count();

        SortAscending(TempRecordSetBuffer);
        TempRecordSetBuffer.FindFirst();
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        Customer.Delete();
        TempRecordSetBuffer.Delete();

        TempRecordSetBuffer.Next(3);
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        TempRecordSetBuffer.Delete();
        Customer.Delete();

        TempRecordSetBuffer.Next();
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        TempRecordSetBuffer.Delete();
        Customer.Delete();

        // Execute
        RecordSetManagement.GetSet(TempLoadRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(NumberOfCustomers - 3, Customer.Count, 'Number of records should not chang after getting a set');
        VerifySetWasLoadedCorrectly(TempLoadRecordSetBuffer, TempRecordSetBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingEmptySetAfterDeletion()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, 1);
        NumberOfCustomers := Customer.Count();
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        DeleteCustomer(TempCustomer, 1, TempDeletedCustomerRecordSetBuffer);

        // Execute
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        // Verify
        Assert.AreEqual(0, TempRecordSetBuffer.Count, 'No records should be fetch');
        Assert.AreEqual(NumberOfCustomers - 1, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingSetAfterRenamingFirstRecord()
    var
        TempCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempItemRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempItem: Record Item temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        ItemSetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        CreateTestItems(TempItem, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        ItemSetID := RecordSetManagement.SaveSetSingleTable(TempItem);
        NumberOfCustomers := Customer.Count();

        TempCustomer.FindFirst();
        RenameCustomer(TempCustomer, xRecRef, RecRef);

        // Execute
        RecordSetManagement.RenameRecord(RecRef, xRecRef);
        RecordSetManagement.GetSet(TempCustomerRecordSetBuffer, SetID);
        RecordSetManagement.GetSet(TempItemRecordSetBuffer, ItemSetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempCustomerRecordSetBuffer, TempCustomer);
        VerifySetWasLoadedCorrectly(TempItemRecordSetBuffer, TempItem);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingSetAfterRenamingLastRecord()
    var
        TempCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := Customer.Count();

        TempCustomer.FindLast();
        RenameCustomer(TempCustomer, xRecRef, RecRef);

        // Execute
        RecordSetManagement.RenameRecord(RecRef, xRecRef);
        RecordSetManagement.GetSet(TempCustomerRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempCustomerRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingSetAfterRenamingMixedRecords()
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempLoadedRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateMixedTablesTestItems(TempRecordSetBuffer, NoOfRecordsPerSet, NoOfRecordsPerSet);
        SortAscending(TempRecordSetBuffer);
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);
        NumberOfCustomers := Customer.Count();

        TempRecordSetBuffer.FindFirst();
        TempRecordSetBuffer.Next();
        Customer.Get(TempRecordSetBuffer."Value RecordID");
        TempCustomer.Copy(Customer);
        TempCustomer.Insert();
        RenameCustomer(TempCustomer, xRecRef, RecRef);
        TempRecordSetBuffer."Value RecordID" := RecRef.RecordId;
        TempRecordSetBuffer.Modify();

        // Execute
        RecordSetManagement.RenameRecord(RecRef, xRecRef);
        RecordSetManagement.GetSet(TempLoadedRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempLoadedRecordSetBuffer, TempRecordSetBuffer);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingSetAfterRenamingRecordsInTheMiddle()
    var
        TempCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := Customer.Count();

        TempCustomer.FindFirst();
        TempCustomer.Next();
        TempCustomer.Next();
        RenameCustomer(TempCustomer, xRecRef, RecRef);

        // Execute
        RecordSetManagement.RenameRecord(RecRef, xRecRef);

        TempCustomer.Next();
        RenameCustomer(TempCustomer, xRecRef, RecRef);
        RecordSetManagement.RenameRecord(RecRef, xRecRef);
        RecordSetManagement.GetSet(TempCustomerRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempCustomerRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingSetAfterRenamingRecordAndRenamingBack()
    var
        TempCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempOldCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        NumberOfCustomers: Integer;
        ExistingNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        NumberOfCustomers := Customer.Count();

        DuplicateCustomerSet(TempCustomer, TempOldCustomer);

        TempCustomer.FindFirst();
        ExistingNo := TempCustomer."No.";
        RenameCustomer(TempCustomer, xRecRef, RecRef);
        RecordSetManagement.RenameRecord(RecRef, xRecRef);

        // Execute
        xRecRef := RecRef.Duplicate();
        RecRef.Rename(ExistingNo);
        RecordSetManagement.RenameRecord(RecRef, xRecRef);
        RecordSetManagement.GetSet(TempCustomerRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempCustomerRecordSetBuffer, TempOldCustomer);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingTheRecordWhenItIsNotPartOfTheSet()
    var
        TempCustomerRecordSetBuffer: Record "Record Set Buffer" temporary;
        TempCustomer: Record Customer temporary;
        TempNewCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        SetID: Integer;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        SetID := RecordSetManagement.SaveSetSingleTable(TempCustomer);
        CreateTestCustomers(TempNewCustomer, 1);
        NumberOfCustomers := Customer.Count();
        RenameCustomer(TempNewCustomer, xRecRef, RecRef);

        // Execute
        RecordSetManagement.RenameRecord(xRecRef, RecRef);
        RecordSetManagement.GetSet(TempCustomerRecordSetBuffer, SetID);

        // Verify
        VerifySetWasLoadedCorrectly(TempCustomerRecordSetBuffer, TempCustomer);
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingTheRecordWhenNoSetsArePresent()
    var
        TempCustomer: Record Customer temporary;
        Customer: Record Customer;
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetTree: Record "Record Set Tree";
        RecordSetManagement: Codeunit "Record Set Management";
        xRecRef: RecordRef;
        RecRef: RecordRef;
        NumberOfCustomers: Integer;
    begin
        Initialize();

        // Setup
        CreateTestCustomers(TempCustomer, NoOfRecordsPerSet);
        RecordSetManagement.SaveSetSingleTable(TempCustomer);

        NumberOfCustomers := Customer.Count();
        RenameCustomer(TempCustomer, xRecRef, RecRef);

        // Execute
        RecordSetDefinition.DeleteAll();
        RecordSetTree.DeleteAll();
        RecordSetManagement.RenameRecord(xRecRef, RecRef);

        // Verify
        Assert.AreEqual(NumberOfCustomers, Customer.Count, 'Number of records should not change');
        Assert.AreEqual(0, RecordSetDefinition.Count, 'No records should be created');
        Assert.AreEqual(0, RecordSetTree.Count, 'No records should be created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByDescription_Negative()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By Description]
        // [SCENARIO 203978] COD 703 "Find Record Management".FindRecordByDescription() returns an empty result for the empty search text or Type differs from the source Type
        Initialize();

        MockItem('TEST_ITEM', 'TEST_ITEM', '');

        VerifyFindRecordByDescription(Type::" ", '', 0, '');
        VerifyFindRecordByDescription(Type::" ", 'TEST_ITEM', 0, '');
        VerifyFindRecordByDescription(Type::"G/L Account", 'TEST_ITEM', 0, '');
        VerifyFindRecordByDescription(Type::"Fixed Asset", 'TEST_ITEM', 0, '');
        VerifyFindRecordByDescription(Type::Resource, 'TEST_ITEM', 0, '');
        VerifyFindRecordByDescription(Type::"Charge (Item)", 'TEST_ITEM', 0, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByDescription()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By Description]
        // [SCENARIO 203978] COD 703 "Find Record Management".FindRecordByDescription() finds a record with exact/starting with/containing/similar description
        Initialize();

        for Type := Type::" " to Type::"Charge (Item)" do begin
            // "No."       "Description"
            // AX          ""
            // BX          CX
            // CX          BX
            // AXY         BXY
            // AXYBXY      BXYCXY
            // AXYBXYCXY   BXYCXYDXY
            // BXYCXY      CXYDXY
            // CXY         DXY
            MockRecord(Type);

            // exact "No."
            VerifyFindRecordByDescription(Type, 'ax', 1, 'AX');
            VerifyFindRecordByDescription(Type, 'bx', 1, 'BX');
            VerifyFindRecordByDescription(Type, 'cx', 1, 'CX');
            VerifyFindRecordByDescription(Type, 'axy', 1, 'AXY');
            VerifyFindRecordByDescription(Type, 'cxy', 1, 'CXY');
            VerifyFindRecordByDescription(Type, 'axybxy', 1, 'AXYBXY');
            VerifyFindRecordByDescription(Type, 'bxycxy', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'axybxycxy', 1, 'AXYBXYCXY');

            // first exact "Description"
            VerifyFindRecordByDescription(Type, 'bxy', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'dxy', 1, 'CXY');
            VerifyFindRecordByDescription(Type, 'cxydxy', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxydxy', 1, 'AXYBXYCXY');

            // first exact "Description" with unknown symbols
            VerifyFindRecordByDescription(Type, 'bx''cx''', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'cxy''''', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'bx''cx''dx''', 1, 'AXYBXYCXY');

            // first "No."/"Description" starting with
            VerifyFindRecordByDescription(Type, 'axybx', 1, 'AXYBXY');
            VerifyFindRecordByDescription(Type, 'bxycx', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'cxydx', 1, 'BXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxydx', 1, 'AXYBXYCXY');

            // first "No."/"Description" containing
            VerifyFindRecordByDescription(Type, 'ybxy', 2, 'AXYBXY|AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'ycxy', 3, 'AXYBXY|AXYBXYCXY|BXYCXY');
            VerifyFindRecordByDescription(Type, 'ydxy', 2, 'AXYBXYCXY|BXYCXY');
            VerifyFindRecordByDescription(Type, 'ybxycx', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'ycxydx', 1, 'AXYBXYCXY');

            // last similar "Description"
            VerifyFindRecordByDescription(Type, 'Zxycxydxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bZycxydxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxZcxydxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxyZxydxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycZydxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxZdxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxyZxy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxydZy', 1, 'AXYBXYCXY');
            VerifyFindRecordByDescription(Type, 'bxycxydxZ', 1, 'AXYBXYCXY');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByDescription_ItemBaseUOMField()
    var
        NoString: Text;
        DescriptionString: Text;
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        i: Integer;
    begin
        // [FEATURE] [Find Record By Description] [Item]
        // [SCENARIO 203978] COD 703 "Find Record Management".FindRecordByDescription() finds an Item looking into "Base Unit of Measure" field
        Initialize();

        Type := Type::Item;
        NoString := 'AXBX,AXBXCX,BXCX,CX';
        DescriptionString := 'BXCX,BXCXDX,CXDX,DX';
        for i := 1 to 4 do
            MockItem(SelectStr(i, NoString), '', SelectStr(i, DescriptionString));
        // "No." "Base Unit of Measure"
        // AXBX       BXCX
        // AXBXCX     BXCXDX
        // BXCX       CXDX
        // CX         DX

        // first "Base Unit of Measure" containing
        VerifyFindRecordByDescription(Type, 'cxdx', 2, 'AXBXCX|BXCX');
        VerifyFindRecordByDescription(Type, 'cx''''', 2, 'AXBXCX|BXCX');
        VerifyFindRecordByDescription(Type, 'bxcxdx', 1, 'AXBXCX');
        VerifyFindRecordByDescription(Type, 'b''c''d''', 1, 'AXBXCX');
        VerifyFindRecordByDescription(Type, 'cxd', 2, 'AXBXCX|BXCX');
        VerifyFindRecordByDescription(Type, 'bxcxd', 1, 'AXBXCX');
        VerifyFindRecordByDescription(Type, 'xcx', 3, 'AXBX|AXBXCX|BXCX');
        VerifyFindRecordByDescription(Type, 'xcxd', 1, 'AXBXCX');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByNo_Negative()
    var
        GLAccount: Record "G/L Account";
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        SearchString: Text;
    begin
        // [FEATURE] [Find Record By No]
        // [SCENARIO 215821] COD 703 "Find Record Management".FindNoFromTypedValue() returns search string for the negative search result
        Initialize();

        SearchString := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(GLAccount."No."), 0);
        VerifyFindRecordByNo(Type::" ", SearchString, SearchString);
        VerifyFindRecordByNo(Type::"G/L Account", SearchString, SearchString);
        VerifyFindRecordByNo(Type::"Fixed Asset", SearchString, SearchString);
        VerifyFindRecordByNo(Type::Resource, SearchString, SearchString);
        VerifyFindRecordByNo(Type::"Charge (Item)", SearchString, SearchString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByNo()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By No]
        // [SCENARIO 215821] COD 703 "Find Record Management".FindNoFromTypedValue() finds a record with exact/starting with/containing/similar "No."/"Description" field value
        Initialize();

        for Type := Type::" " to Type::"Charge (Item)" do begin
            // "No." "Description"
            // AX          ""
            // BX          CX
            // CX          BX
            // AXY         BXY
            // AXYBXY      BXYCXY
            // AXYBXYCXY   BXYCXYDXY
            // BXYCXY      CXYDXY
            // CXY         DXY
            MockRecord(Type);

            // exact "No."
            VerifyFindRecordByNo(Type, 'ax', 'AX');
            VerifyFindRecordByNo(Type, 'bx', 'BX');
            VerifyFindRecordByNo(Type, 'cx', 'CX');
            VerifyFindRecordByNo(Type, 'axy', 'AXY');
            VerifyFindRecordByNo(Type, 'cxy', 'CXY');
            VerifyFindRecordByNo(Type, 'axybxy', 'AXYBXY');
            VerifyFindRecordByNo(Type, 'bxycxy', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'axybxycxy', 'AXYBXYCXY');

            // first exact "Description"
            VerifyFindRecordByNo(Type, 'bxy', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'dxy', 'CXY');
            VerifyFindRecordByNo(Type, 'cxydxy', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxydxy', 'AXYBXYCXY');

            // first exact "Description" with unknown symbols
            VerifyFindRecordByNo(Type, 'bx''cx''', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'cxy''''', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'bx''cx''dx''', 'AXYBXYCXY');

            // first "No."/"Description" starting with
            VerifyFindRecordByNo(Type, 'axybx', 'AXYBXY');
            VerifyFindRecordByNo(Type, 'bxycx', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'cxydx', 'BXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxydx', 'AXYBXYCXY');

            // first "No."/"Description" containing
            VerifyFindRecordByNo(Type, 'ybxycx', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'ycxydx', 'AXYBXYCXY');

            // last similar "Description"
            VerifyFindRecordByNo(Type, 'Zxycxydxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bZycxydxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxZcxydxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxyZxydxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxycZydxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxZdxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxyZxy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxydZy', 'AXYBXYCXY');
            VerifyFindRecordByNo(Type, 'bxycxydxZ', 'AXYBXYCXY');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByNo_GLAccountFilters()
    var
        GLAccount: Record "G/L Account";
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By No]
        // [SCENARIO 215821] COD 703 "Find Record Management".FindNoFromTypedValue() finds only G/L Account with filters ("Direct Posting" = TRUE, Blocked = FALSE, "Account Type" = Posting)
        // [SCENARIO 215821] when called with UseDefaultFilters = TRUE
        Initialize();

        MockGLAccount('_TEST_GL_ACC_NO1_', '', false, GLAccount."Account Type"::Posting, false);
        MockGLAccount('_TEST_GL_ACC_NO2_', '', true, GLAccount."Account Type"::Heading, false);
        MockGLAccount('_TEST_GL_ACC_NO3_', '', true, GLAccount."Account Type"::Posting, true);

        MockGLAccount('_TEST_GL_ACC_NO4_', '', true, GLAccount."Account Type"::Posting, false);

        MockGLAccount('_TEST_GL_ACC_NO5_', '', false, GLAccount."Account Type"::Posting, false);
        MockGLAccount('_TEST_GL_ACC_NO6_', '', true, GLAccount."Account Type"::Heading, false);
        MockGLAccount('_TEST_GL_ACC_NO7_', '', true, GLAccount."Account Type"::Posting, true);

        VerifyFindRecordByNo(Type::"G/L Account", '_test_gl_acc_', '_TEST_GL_ACC_NO4_');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByNo_GLAccountWithoutFilters()
    var
        GLAccount: Record "G/L Account";
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By No]
        // [SCENARIO 215821] COD 703 "Find Record Management".FindNoFromTypedValue() finds any G/L Account without filters
        // [SCENARIO 215821] when called with UseDefaultFilters = FALSE
        Initialize();

        MockGLAccount('_TEST_GL_ACC_NO1_', '', false, GLAccount."Account Type"::Posting, false);
        MockGLAccount('_TEST_GL_ACC_NO2_', '', true, GLAccount."Account Type"::Heading, false);
        MockGLAccount('_TEST_GL_ACC_NO3_', '', true, GLAccount."Account Type"::Posting, true);
        MockGLAccount('_TEST_GL_ACC_NO4_', '', true, GLAccount."Account Type"::Posting, false);

        VerifyFindRecordByNoWithoutDefaultFilters(Type::"G/L Account", '_test_gl_acc_no1', '_TEST_GL_ACC_NO1_');
        VerifyFindRecordByNoWithoutDefaultFilters(Type::"G/L Account", '_test_gl_acc_no2', '_TEST_GL_ACC_NO2_');
        VerifyFindRecordByNoWithoutDefaultFilters(Type::"G/L Account", '_test_gl_acc_no3', '_TEST_GL_ACC_NO3_');
        VerifyFindRecordByNoWithoutDefaultFilters(Type::"G/L Account", '_test_gl_acc_no4', '_TEST_GL_ACC_NO4_');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByNo_Asterisk()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By No]
        // [SCENARIO 225605] COD 703 "Find Record Management".FindNoFromTypedValue() finds an Item "70011" (instead of "1100") by search value "*11"
        Initialize();

        Type := Type::Item;
        MockItem('TEST_ITEM', '', '');
        MockItem('TEST_ITEM_TEST', '', '');
        VerifyFindRecordByDescription(Type, '*TEST', 1, 'TEST_ITEM');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindRecordByDescription_LogicalFilterChars()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [Find Record By Description]
        // [SCENARIO 225605] COD 703 "Find Record Management".FindRecordByDescription() finds an Item with Description "&&&&"/"||||"/"(())"
        // [SCENARIO 252065]
        Initialize();

        Type := Type::Item;
        MockItem('TEST_ITEM1', 'Black & White', '');
        MockItem('TEST_ITEM2', 'Black|White', '');
        MockItem('TEST_ITEM3', 'Good Joke(s)', '');
        VerifyFindRecordByDescription(Type, 'black & white', 1, 'TEST_ITEM1');
        VerifyFindRecordByDescription(Type, 'LACK|whit', 1, 'TEST_ITEM2');
        VerifyFindRecordByDescription(Type, 'Good*(s)', 1, 'TEST_ITEM3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgs_FindNoFromTypedValue()
    var
        Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 234103] COD 703 "Find Record Management".FindNoFromTypedValue finds Item."No." = "A1" with SearchString = "A" for Item."No." field.
        Initialize();

        Type := Type::Item;

        MockItem('A11', 'A22', '');
        MockItem('A22', 'A11', '');
        MockItem('B33', '', '');
        MockItem('B44', '', '');
        MockItem('C55', '', '');
        MockItem('C66', '', '');

        VerifyFindRecordByNo(Type, 'A', 'A11');
        VerifyFindRecordByNo(Type, 'A2', 'A22');
        VerifyFindRecordByNo(Type, 'B3', 'B33');
        VerifyFindRecordByNo(Type, 'B4', 'B44');
        VerifyFindRecordByNo(Type, 'C5', 'C55');
        VerifyFindRecordByNo(Type, 'C6', 'C66');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_GetIntFieldValues()
    var
        GLEntry: Record "G/L Entry";
        FindRecordManagement: Codeunit "Find Record Management";
        RecRef: RecordRef;
        IntFields: list of [Integer];
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GetIntFieldValues() returns the list of Integer field values
        Initialize();

        // [GIVEN] G/L Entry, where "Entry No." = 1, "Transaction No." = 2, Amount = 10.0, "Reversed Entry No." = 3
        GLEntry."Entry No." := 1;
        GLEntry."Transaction No." := 2;
        GLEntry.Amount := 10;
        GLEntry."Reversed Entry No." := 3;

        // [GIVEN] The list of fields to return: "Entry No.", "Transaction No.", Amount, "Reversed Entry No."
        IntFields.Add(GLEntry.FieldNo("Entry No."));
        IntFields.Add(GLEntry.FieldNo("Transaction No."));
        IntFields.Add(GLEntry.FieldNo(Amount)); // is not integer
        IntFields.Add(GLEntry.FieldNo("Reversed Entry No."));

        // [WHEN] Run GetIntFieldValues()
        RecRef.GetTable(GLEntry);
        FindRecordManagement.GetIntFieldValues(RecRef, IntFields);

        // [THEN] Returned: 1, 2, 0 (as Amount is not Integer),3
        Assert.AreEqual(1, IntFields.Get(1), 'Entry No.');
        Assert.AreEqual(2, IntFields.Get(2), 'Transaction No.');
        Assert.AreEqual(0, IntFields.Get(3), 'Amount');
        Assert.AreEqual(3, IntFields.Get(4), 'Reversed Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_GetIntFieldValues_FlowField()
    var
        Customer: Record Customer;
        ShiptoAddress: Record "Ship-to Address";
        FindRecordManagement: Codeunit "Find Record Management";
        RecRef: RecordRef;
        IntFields: list of [Integer];
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GetIntFieldValues() returns the Integer flowfield value
        Initialize();

        // [GIVEN] Customer, where "No. of Ship-to Addresses" = 1
        Customer."No." := 'X';
        ShiptoAddress.DeleteAll();
        ShiptoAddress."Customer No." := Customer."No.";
        ShiptoAddress.Insert();

        // [GIVEN] The list of fields to return: "No. of Ship-to Addresses"
        IntFields.Add(Customer.FieldNo("No. of Ship-to Addresses"));

        // [WHEN] Run GetIntFieldValues()
        RecRef.GetTable(Customer);
        FindRecordManagement.GetIntFieldValues(RecRef, IntFields);

        // [THEN] Returned: 1
        Assert.AreEqual(1, IntFields.Get(1), 'No. of Ship-to Addresses');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_GetIntFieldValue_FlowField()
    var
        Customer: Record Customer;
        ShiptoAddress: Record "Ship-to Address";
        FindRecordManagement: Codeunit "Find Record Management";
        RecRef: RecordRef;
        IntField: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GetIntFieldValue() returns the Integer value
        Initialize();

        // [GIVEN] Customer, where "No. of Ship-to Addresses" = 1
        Customer."No." := 'X';
        ShiptoAddress.DeleteAll();
        ShiptoAddress."Customer No." := Customer."No.";
        ShiptoAddress.Insert();

        // [WHEN] Run GetIntFieldValue() for "No. of Ship-to Addresses"
        RecRef.GetTable(Customer);
        IntField := FindRecordManagement.GetIntFieldValue(RecRef, Customer.FieldNo("No. of Ship-to Addresses"));

        // [THEN] Returned: 1
        Assert.AreEqual(1, IntField, 'No. of Ship-to Addresses');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindLastEntryIgnoringSecurityFilter()
    var
        GLEntry: Record "G/L Entry";
        FindRecordManagement: Codeunit "Find Record Management";
        RecRef: RecordRef;
        xSecurityFilter: SecurityFilter;
        ExpectedLastEntryNo: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] FindLastEntryIgnoringSecurityFilter() reposition RecRef to last entry and keeps SecurityFiltering
        Initialize();

        // [GIVEN] GLEntry record variable with SecurityFilter::Validated, last "entry No." is 'X'
        Assert.IsTrue(GLEntry.FindLast(), 'empty G/L Entry table');
        ExpectedLastEntryNo := GLEntry."Entry No.";
        xSecurityFilter := GLEntry.SecurityFiltering();
        // [GIVEN] GLEntry, where "Entry No." is 1
        GLEntry.FindFirst();

        // [WHEN] Run FindLastEntryIgnoringSecurityFilter() for GLEntry
        RecRef.GetTable(GLEntry);
        Assert.IsTrue(FindRecordManagement.FindLastEntryIgnoringSecurityFilter(RecRef), 'Record not found');

        // [THEN] GLEntry."Entry No." is 'X'
        Assert.AreEqual(
            ExpectedLastEntryNo,
            FindRecordManagement.GetIntFieldValue(RecRef, GLEntry.FieldNo("Entry No.")), 'Entry No.');
        // [THEN] GLEntry record variable with SecurityFilter::Validated,
        Assert.IsTrue(xSecurityFilter = RecRef.SecurityFiltering, 'RecRef.SecurityFiltering is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRecordMgt_FindLastEntryIgnoringSecurityFilter_Filtered()
    var
        GLEntry: Record "G/L Entry";
        FindRecordManagement: Codeunit "Find Record Management";
        RecRef: RecordRef;
        ExpectedLastEntryNo: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] FindLastEntryIgnoringSecurityFilter() reposition RecRef to last entry considering current filters
        Initialize();

        // [GIVEN] GLEntry record variable with SecurityFilter::Validated, last "entry No." is 'X'
        Assert.IsTrue(GLEntry.FindLast(), 'empty G/L Entry table');
        ExpectedLastEntryNo := GLEntry."Entry No.";
        // [GIVEN] GLEntry, where "Entry No." is 1, filter "Entry No." in [1..(X-1)]
        GLEntry.FindFirst();
        GLEntry.SetRange("Entry No.", 1, ExpectedLastEntryNo - 1);

        // [WHEN] Run FindLastEntryIgnoringSecurityFilter() for GLEntry
        RecRef.GetTable(GLEntry);
        Assert.IsTrue(FindRecordManagement.FindLastEntryIgnoringSecurityFilter(RecRef), 'Record not found');

        // [THEN] GLEntry."Entry No." is 'X' - 1
        Assert.AreEqual(
            ExpectedLastEntryNo - 1,
            FindRecordManagement.GetIntFieldValue(RecRef, GLEntry.FieldNo("Entry No.")), 'Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntry_GetLastEntryNo()
    var
        GLEntry: Record "G/L Entry";
        ExpectedLastEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GLEntry.GetLastEntryNo() returns the last entry number ignoring filters
        Initialize();

        // [GIVEN] GLEntry, last "Entry No." is 'X'
        Assert.IsTrue(GLEntry.FindLast(), 'empty G/L Entry table');
        GLEntry."Entry No." += 1;
        GLEntry.Insert();
        ExpectedLastEntryNo := GLEntry."Entry No.";
        // [GIVEN] GLEntry, where "Entry No." is 1 and filter "Entry No." = '1'
        GLEntry.FindFirst();
        GLEntry.SetRange("Entry No.", GLEntry."Entry No.");
        // [WHEN] run GLEntry.GetLastEntryNo()
        LastEntryNo := GLEntry.GetLastEntryNo();
        // [THEN] returned 'X'
        Assert.AreEqual(ExpectedLastEntryNo, LastEntryNo, 'Wrong last entry no.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntry_GetLastEntryNo_TemporaryTable()
    var
        GLEntry: Record "G/L Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        ExpectedLastEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GLEntry.GetLastEntryNo() returns the last entry number of the temporary table
        Initialize();

        // [GIVEN] GLEntry, where last entry is 'X'
        GLEntry.FindLast();
        ExpectedLastEntryNo := GLEntry."Entry No." - 1;
        // [GIVEN] temporary GLEntry, last "Entry No." is 'X - 1'
        TempGLEntry."Entry No." := 1;
        TempGLEntry.Insert();
        TempGLEntry."Entry No." := ExpectedLastEntryNo;
        TempGLEntry.Insert();
        // [GIVEN] temporary GLEntry, where "Entry No." is 1
        TempGLEntry.FindFirst();

        // [WHEN] run GLEntry.GetLastEntryNo()
        LastEntryNo := TempGLEntry.GetLastEntryNo();

        // [THEN] returned 'X - 1'
        Assert.AreEqual(ExpectedLastEntryNo, LastEntryNo, 'Wrong last entry no.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntry_GetLastEntry()
    var
        GLEntry: Record "G/L Entry";
        ExpectedLastEntryNo: Integer;
        ExpectedLastTransactionNo: Integer;
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        // [FEATURE] [Find Record Management]
        // [SCENARIO 333173] GLEntry.GetLastEntry() returns the last entry and last transaction numbers
        Initialize();

        // [GIVEN] GLEntry, last "Entry No." is 'X'
        Assert.IsTrue(GLEntry.FindLast(), 'empty G/L Entry table');
        ExpectedLastEntryNo := GLEntry."Entry No.";
        ExpectedLastTransactionNo := GLEntry."Transaction No.";
        // [GIVEN] GLEntry, where "Entry No." is 1
        GLEntry.FindFirst();
        // [WHEN] run GLEntry.GetLastEntry()
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
        // [THEN] returned 'X'
        Assert.AreEqual(ExpectedLastEntryNo, LastEntryNo, 'Wrong last entry no.');
        Assert.AreEqual(ExpectedLastTransactionNo, LastTransactionNo, 'Wrong last transaction entry no.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCodeLengthOfBusinessUnit()
    var
        DimensionCodeBuffer: Record "Dimension Code Buffer";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Business Unit"."Code" must be equal to length of "Dimension Code Buffer"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          DimensionCodeBuffer, DimensionCodeBuffer.FieldNo(Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNameLengthOfBusinessUnit()
    var
        DimensionCodeBuffer: Record "Dimension Code Buffer";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Business Unit"."Name" must be equal to length of "Dimension Code Buffer"."Name"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Name),
          DimensionCodeBuffer, DimensionCodeBuffer.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitFilterLengthOfGLAccount()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "G/L Account"."Business Unit Filter" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          GLAccount, GLAccount.FieldNo("Business Unit Filter"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfGLEntry()
    var
        GLEntry: Record "G/L Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "G/L Entry"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          GLEntry, GLEntry.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerPostingGroupLengthOfCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Cust. Ledger Entry"."Customer Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          CustLedgerEntry, CustLedgerEntry.FieldNo("Customer Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorPostingGroupLengthOfVendorLedgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Vendor Ledger Entry"."Vendor Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          VendorLedgerEntry, VendorLedgerEntry.FieldNo("Vendor Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfAnalysisViewEntry()
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Analysis View Entry"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          AnalysisViewEntry, AnalysisViewEntry.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfAnalysisViewBudgetEntry()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Analysis View Budget Entry"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          AnalysisViewBudgetEntry, AnalysisViewBudgetEntry.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitFilterLengthOfGLAccountAnalysisView()
    var
        GLAccountAnalysisView: Record "G/L Account (Analysis View)";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "G/L Account (Analysis View)"."Business Unit Filter" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          GLAccountAnalysisView, GLAccountAnalysisView.FieldNo("Business Unit Filter"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCVPostingGroupLengthOfCVLedgerEntryBuffer()
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "CV Ledger Entry Buffer"."CV Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          CVLedgerEntryBuffer, CVLedgerEntryBuffer.FieldNo("CV Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfEntryNoAmountBuffer()
    var
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Entry No. Amount Buffer"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          EntryNoAmountBuffer, EntryNoAmountBuffer.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFAPostingGroupLengthOfFALedgerEntry()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "FA Ledger Entry"."FA Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          FALedgerEntry, FALedgerEntry.FieldNo("FA Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFAPostingGroupLengthOfFAJournalLine()
    var
        FAJournalLine: Record "FA Journal Line";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "FA Journal Line"."FA Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          FAJournalLine, FAJournalLine.FieldNo("FA Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFAPostingGroupLengthOfMaintenanceLedgerEntry()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Maintenance Ledger Entry"."FA Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          MaintenanceLedgerEntry, MaintenanceLedgerEntry.FieldNo("FA Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfStandardGeneralJournalLine()
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Standard General Journal Line"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          StandardGeneralJournalLine, StandardGeneralJournalLine.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingGroupLengthOfGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Gen. Journal Line"."Posting Group" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          GenJournalLine, GenJournalLine.FieldNo("Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitFilterLengthOfAccScheduleLine()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Acc. Schedule Line"."Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          AccScheduleLine, AccScheduleLine.FieldNo("Business Unit Filter"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessUnitCodeLengthOfGLBudgetEntry()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "G/L Budget Entry"."Business Unit Code" must be equal to length of "Business Unit"."Code"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          BusinessUnit, BusinessUnit.FieldNo(Code),
          GLBudgetEntry, GLBudgetEntry.FieldNo("Business Unit Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNameLengthOfDataExchMapping()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        NewName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Length of "Data Exch. Mapping"."Name" must be equal to 250
        Initialize();

        NewName := LibraryUtility.GenerateRandomText(250);
        DataExchMapping.Name := CopyStr(NewName, 1, MaxStrLen(DataExchMapping.Name));
        DataExchMapping.TestField(Name, NewName);
    end;

    local procedure Initialize()
    var
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetTree: Record "Record Set Tree";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Record Set UT");
        RecordSetDefinition.DeleteAll();
        RecordSetTree.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Record Set UT");

        NoOfRecordsPerSet := 10;
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Record Set UT");
    end;

    local procedure CreateMixedTablesTestItems(var TempRecordSetBuffer: Record "Record Set Buffer" temporary; NumberOfCustomers: Integer; NumberOfItems: Integer)
    var
        TempItem: Record Item temporary;
        TempCustomer: Record Customer temporary;
    begin
        CreateTestItems(TempItem, NumberOfItems);
        CreateTestCustomers(TempCustomer, NumberOfCustomers);

        ConvertToRecordSetBuffer(TempRecordSetBuffer, TempItem);
        ConvertToRecordSetBuffer(TempRecordSetBuffer, TempCustomer);
    end;

    local procedure CreateTestItems(var TempItem: Record Item temporary; NumberOfRecords: Integer)
    var
        Item: Record Item;
        I: Integer;
    begin
        TempItem.DeleteAll();
        for I := 1 to NumberOfRecords do begin
            Clear(TempItem);
            LibraryInventory.CreateItem(Item);
            TempItem := Item;
            TempItem.Insert();
        end;
    end;

    local procedure CreateTestCustomers(var TempCustomer: Record Customer temporary; NumberOfRecords: Integer)
    var
        Customer: Record Customer;
        I: Integer;
    begin
        TempCustomer.DeleteAll();
        for I := 1 to NumberOfRecords do begin
            Clear(TempCustomer);
            LibrarySales.CreateCustomer(Customer);
            TempCustomer := Customer;
            TempCustomer.Insert();
        end;
    end;

    local procedure DuplicateCustomerSet(var TempCustomer: Record Customer temporary; var NewTempCustomer: Record Customer temporary)
    begin
        TempCustomer.Reset();
        NewTempCustomer.Reset();
        NewTempCustomer.DeleteAll();

        TempCustomer.FindFirst();
        repeat
            NewTempCustomer := TempCustomer;
            NewTempCustomer.Insert();
        until TempCustomer.Next() = 0;
    end;

    local procedure DuplicateServiceConnectionSet(var TempRecordSetBuffer: Record "Record Set Buffer" temporary; var TempNewRecordSetBuffer: Record "Record Set Buffer" temporary)
    begin
        TempRecordSetBuffer.Reset();
        TempNewRecordSetBuffer.Reset();
        TempNewRecordSetBuffer.DeleteAll();

        TempRecordSetBuffer.FindFirst();
        repeat
            TempNewRecordSetBuffer := TempRecordSetBuffer;
            TempNewRecordSetBuffer.Insert();
        until TempRecordSetBuffer.Next() = 0;
    end;

    local procedure DeleteCustomer(var TempCustomer: Record Customer temporary; DeleteIndex: Integer; var TempDeletedCustomerRecordSetBuffer: Record "Record Set Buffer" temporary)
    var
        Customer: Record Customer;
        LastNo: Integer;
    begin
        TempCustomer.Reset();
        TempCustomer.FindFirst();
        if DeleteIndex > 1 then
            TempCustomer.Next(DeleteIndex - 1);

        LastNo := 0;
        if TempDeletedCustomerRecordSetBuffer.FindLast() then
            LastNo := TempDeletedCustomerRecordSetBuffer.No;

        Clear(TempDeletedCustomerRecordSetBuffer);
        TempDeletedCustomerRecordSetBuffer.No := LastNo + 1;
        TempDeletedCustomerRecordSetBuffer."Value RecordID" := TempCustomer.RecordId;
        TempDeletedCustomerRecordSetBuffer.Insert();
        TempCustomer.Delete();

        Customer.Get(TempCustomer.RecordId);
        Customer.Delete();
    end;

    local procedure RenameCustomer(var TempCustomer: Record Customer temporary; var xRecRef: RecordRef; var RecRef: RecordRef)
    var
        NewCustomer: Record Customer;
        Customer: Record Customer;
        NewNo: Code[20];
    begin
        LibrarySales.CreateCustomer(NewCustomer);
        NewNo := NewCustomer."No.";
        NewCustomer.Delete();

        Customer.Get(TempCustomer.RecordId);
        xRecRef.GetTable(Customer);
        Customer.Rename(NewNo);
        TempCustomer.Delete();
        TempCustomer.Copy(Customer);
        TempCustomer.Insert();

        RecRef.GetTable(Customer);
    end;

    local procedure CreateSetAndCountEntries(RecordVariant: Variant; var SetID: Integer; var RecordSetDefinitionCount: Integer; var RecordSetTreeCount: Integer)
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetTree: Record "Record Set Tree";
        RecordSetManagement: Codeunit "Record Set Management";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        ConvertToRecordSetBuffer(TempRecordSetBuffer, RecordVariant);
        TempRecordSetBuffer.FindFirst();
        SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        DataTypeManagement.GetRecordRef(RecordVariant, RecRef);
        RecordSetDefinition.SetRange("Set ID", SetID);
        RecordSetDefinitionCount := RecordSetDefinition.Count();
        RecordSetTreeCount := RecordSetTree.Count();
    end;

    local procedure MockRecord(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)")
    var
        GLAccount: Record "G/L Account";
        NoString: Text;
        DescriptionString: Text;
        i: Integer;
    begin
        NoString := 'AX,BX,CX,AXY,AXYBXY,AXYBXYCXY,BXYCXY,CXY';
        DescriptionString := ',CX,BX,BXY,BXYCXY,BXYCXYDXY,CXYDXY,DXY';
        case Type of
            Type::"Charge (Item)":
                for i := 1 to 8 do
                    MockItemCharge(SelectStr(i, NoString), SelectStr(i, DescriptionString));
            Type::"Fixed Asset":
                for i := 1 to 8 do
                    MockFixedAsset(SelectStr(i, NoString), SelectStr(i, DescriptionString));
            Type::"G/L Account":
                for i := 1 to 8 do
                    MockGLAccount(SelectStr(i, NoString), SelectStr(i, DescriptionString), true, GLAccount."Account Type"::Posting, false);
            Type::Item:
                for i := 1 to 8 do
                    MockItem(SelectStr(i, NoString), SelectStr(i, DescriptionString), '');
            Type::Resource:
                for i := 1 to 8 do
                    MockResource(SelectStr(i, NoString), SelectStr(i, DescriptionString));
            Type::" ":
                for i := 1 to 8 do
                    MockStandardText(SelectStr(i, NoString), SelectStr(i, DescriptionString));
        end;
    end;

    local procedure MockItem(NewNo: Code[20]; NewDescription: Text[50]; BaseUnitOfMeasure: Code[10])
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := NewNo;
        Item.Description := NewDescription;
        Item."Base Unit of Measure" := BaseUnitOfMeasure;
        Item.Insert();
    end;

    local procedure MockGLAccount(NewNo: Code[20]; NewName: Text[50]; DirectPosting: Boolean; AccountType: Enum "G/L Account Type"; NewBlockedValue: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := NewNo;
        GLAccount.Name := NewName;
        GLAccount."Direct Posting" := DirectPosting;
        GLAccount."Account Type" := AccountType;
        GLAccount.Blocked := NewBlockedValue;
        GLAccount.Insert();
    end;

    local procedure MockResource(NewNo: Code[20]; NewName: Text[50])
    var
        Resource: Record Resource;
    begin
        Resource.Init();
        Resource."No." := NewNo;
        Resource.Name := NewName;
        Resource.Insert();
    end;

    local procedure MockItemCharge(NewNo: Code[20]; NewDescription: Text[50])
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Init();
        ItemCharge."No." := NewNo;
        ItemCharge.Description := NewDescription;
        ItemCharge.Insert();
    end;

    local procedure MockFixedAsset(NewNo: Code[20]; NewDescription: Text[50])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Init();
        FixedAsset."No." := NewNo;
        FixedAsset.Description := NewDescription;
        FixedAsset.Insert();
    end;

    local procedure MockStandardText(NewCode: Code[20]; NewDescription: Text[50])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := NewCode;
        StandardText.Description := NewDescription;
        StandardText.Insert();
    end;

    local procedure VerifySetWasSavedCorrectly(SetID: Integer; ExpectedRecordsVariant: Variant)
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetDefinition: Record "Record Set Definition";
        RecordSetTree: Record "Record Set Tree";
        SetRecordRef: RecordRef;
    begin
        ConvertToRecordSetBuffer(TempRecordSetBuffer, ExpectedRecordsVariant);
        SortAscending(TempRecordSetBuffer);

        RecordSetDefinition.SetRange("Set ID", SetID);
        RecordSetDefinition.SetAutoCalcFields(Value);

        Assert.AreEqual(
          TempRecordSetBuffer.Count, RecordSetDefinition.Count, 'Wrong number of records in the Record Set Definition Table');

        repeat
            SetRecordRef.Get(TempRecordSetBuffer."Value RecordID");
            RecordSetTree.SetRange("Table No.", SetRecordRef.Number);
            RecordSetTree.SetRange(Value, SetRecordRef.RecordId);
            RecordSetTree.SetRange("Parent Node ID", RecordSetTree."Node ID");
            Assert.IsTrue(RecordSetTree.FindFirst(), 'Could not find the value in the Record Set Tree table');
            Assert.IsTrue(
              RecordSetDefinition.Get(RecordSetTree."Table No.", SetID, RecordSetTree."Node ID"),
              'Could not find the value in the Record Set Definiton Table');
            Assert.AreEqual(
              Format(RecordSetDefinition.Value), Format(TempRecordSetBuffer."Value RecordID"),
              'Wrong record was referenced from Record Set Definition Table');
        until TempRecordSetBuffer.Next() = 0;
    end;

    local procedure VerifySetWasLoadedCorrectly(var TempActualRecordSetBuffer: Record "Record Set Buffer" temporary; ExpectedRecordSet: Variant)
    var
        TempExpectedRecordSetBuffer: Record "Record Set Buffer" temporary;
    begin
        ConvertToRecordSetBuffer(TempExpectedRecordSetBuffer, ExpectedRecordSet);
        SortAscending(TempExpectedRecordSetBuffer);

        Assert.AreEqual(TempActualRecordSetBuffer.Count, TempExpectedRecordSetBuffer.Count, 'Wrong number of rows found');

        TempActualRecordSetBuffer.FindFirst();
        TempExpectedRecordSetBuffer.FindFirst();

        repeat
            Assert.AreEqual(
              Format(TempActualRecordSetBuffer."Value RecordID"), Format(TempExpectedRecordSetBuffer."Value RecordID"),
              'Wrong record was referenced');
            TempActualRecordSetBuffer.Next();
        until TempExpectedRecordSetBuffer.Next() = 0;
    end;

    local procedure VerifyFindRecordByDescription(Type: Option; SearchText: Text; ExpectedCount: Integer; ExpectedResult: Text)
    var
        FindRecordMgt: Codeunit "Find Record Management";
        Result: Text;
    begin
        Assert.AreEqual(
          ExpectedCount,
          FindRecordMgt.FindRecordByDescription(Result, Type, SearchText),
          'Wrong record count result from TypeHelper.FindRecordByDescription()');
        Assert.AreEqual(ExpectedResult, Result, 'Wrong result from TypeHelper.FindRecordByDescription()');
    end;

    local procedure VerifyFindRecordByNo(Type: Option; SearchText: Text; ExpectedResult: Text)
    var
        GLAccount: Record "G/L Account";
        FindRecordMgt: Codeunit "Find Record Management";
    begin
        Assert.AreEqual(
          ExpectedResult,
          FindRecordMgt.FindNoFromTypedValue(Type, CopyStr(SearchText, 1, MaxStrLen(GLAccount."No.")), true),
          'Wrong record find result from TypeHelper.FindNoFromTypedValue()');
    end;

    local procedure VerifyFindRecordByNoWithoutDefaultFilters(Type: Option; SearchText: Text; ExpectedResult: Text)
    var
        GLAccount: Record "G/L Account";
        FindRecordMgt: Codeunit "Find Record Management";
    begin
        Assert.AreEqual(
          ExpectedResult,
          FindRecordMgt.FindNoFromTypedValue(Type, CopyStr(SearchText, 1, MaxStrLen(GLAccount."No.")), false),
          'Wrong record find result from TypeHelper.FindNoFromTypedValue()');
    end;

    local procedure ConvertToRecordSetBuffer(var TempRecordSetBuffer: Record "Record Set Buffer" temporary; VariantRecordSet: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SetRecordRef: RecordRef;
        CurrentKey: Integer;
    begin
        DataTypeManagement.GetRecordRef(VariantRecordSet, SetRecordRef);
        if SetRecordRef.Number = DATABASE::"Record Set Buffer" then begin
            TempRecordSetBuffer.Copy(VariantRecordSet, true);
            exit;
        end;

        SetRecordRef.FindSet();
        repeat
            CurrentKey := TempRecordSetBuffer.No;
            Clear(TempRecordSetBuffer);
            TempRecordSetBuffer.No := CurrentKey + 1;
            TempRecordSetBuffer."Value RecordID" := SetRecordRef.RecordId;
            TempRecordSetBuffer.Insert();
        until SetRecordRef.Next() = 0;
    end;

    local procedure SortAscending(var TempRecordSetBuffer: Record "Record Set Buffer" temporary)
    begin
        TempRecordSetBuffer.SetCurrentKey("Value RecordID");
        TempRecordSetBuffer.Ascending(true);
        TempRecordSetBuffer.FindSet();
    end;
}

