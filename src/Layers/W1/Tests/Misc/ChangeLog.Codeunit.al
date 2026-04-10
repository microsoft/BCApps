codeunit 139031 "Change Log"
{
    Permissions = TableData "Change Log Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Change Log]
    end;

    var
        ChangeLogManagement: Codeunit "Change Log Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPermissions: Codeunit "Library - Permissions";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        OldChangeLogActivated: Boolean;
        ParseShouldSucceedErr: Label 'Parsing failed, which should have succeeded.';
        ParseShouldFailErr: Label 'Parsing succeeded, but should have failed.';
        BadParsedValueErr: Label 'Parsing gave an unexpected value.';
        LogOption: Option " ","Some Fields","All Fields";
        TypeOfChangeOption: Option Insertion,Modification,Deletion;
        GlobalTableNo: Integer;
        GlobalFieldNo: array[3] of Integer;
        GlobalExtraFieldNo: array[4] of Integer;
        ActivateChangeLogQst: Label 'Turning on the Change Log might slow things down, especially if you are monitoring entities that often change. Do you want to log changes?';
        RestartSessionQst: Label 'Changes are displayed on the Change Log Entries page after the user''s session has restarted. Do you want to restart the session now?';
        RunWithoutFilterQst: Label 'You have not defined a date filter. Do you want to continue?';
        NothingToDeleteErr: Label 'There are no entries within the filter.';
        DeletedMsg: Label 'The selected entries were deleted.';

    local procedure Initialize()
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        ChangeLogInit();
        NoSeriesSetup();

        // Lazy Setup.
        if isInitialized then
            exit;

        // Required dummy logging
        GlobalTableNo := DATABASE::"CV Ledger Entry Buffer";
        GlobalFieldNo[1] := CVLedgerEntryBuffer.FieldNo("Entry No.");
        GlobalFieldNo[2] := CVLedgerEntryBuffer.FieldNo("Document Type");
        GlobalFieldNo[3] := CVLedgerEntryBuffer.FieldNo("Applies-to Doc. Type");
        GlobalExtraFieldNo[1] := CVLedgerEntryBuffer.FieldNo(Open);
        GlobalExtraFieldNo[2] := CVLedgerEntryBuffer.FieldNo(Amount);
        GlobalExtraFieldNo[3] := CVLedgerEntryBuffer.FieldNo(Description);
        GlobalExtraFieldNo[4] := CVLedgerEntryBuffer.FieldNo("CV No.");
        DummyLog();

        isInitialized := true;
        Commit();
    end;

    local procedure TearDown()
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        SetChangeLogSetup(OldChangeLogActivated);
        CVLedgerEntryBuffer.DeleteAll();
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryInventory.NoSeriesSetup(InventorySetup);
    end;

    local procedure ChangeLogInit()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogSetupField.Reset();
        ChangeLogSetupField.DeleteAll();

        ChangeLogSetupTable.Reset();
        ChangeLogSetupTable.DeleteAll();

        ChangeLogEntry.Reset();
        ChangeLogEntry.DeleteAll();

        OldChangeLogActivated := SetChangeLogSetup(true);
        ChangeLogManagement.InitChangeLog();
    end;

    local procedure SetChangeLogSetup(ChangeLogActivated: Boolean): Boolean
    var
        ChangeLogSetup: Record "Change Log Setup";
        OldValue: Boolean;
    begin
        OldValue := false;

        if ChangeLogSetup.Get() then begin
            OldValue := ChangeLogSetup."Change Log Activated";
            ChangeLogSetup.Validate("Change Log Activated", ChangeLogActivated);
            ChangeLogSetup.Modify(true);
        end else begin
            ChangeLogSetup.Validate("Change Log Activated", ChangeLogActivated);
            ChangeLogSetup.Insert(true);
        end;

        exit(OldValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ActivateChangeLogConfirm()
    var
        ChangeLogSetup: Record "Change Log Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ChangeLogSetupPage: TestPage "Change Log Setup";
    begin
        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetChangeLogSetup(false);

        // Exercise
        ChangeLogSetupPage.OpenEdit();
        ChangeLogSetupPage."Change Log Activated".SetValue(true);
        ChangeLogSetupPage.Close();

        // Verify
        ChangeLogSetup.Get();
        Assert.IsTrue(ChangeLogSetup."Change Log Activated", 'Change Log was not activated.');

        // Tear down
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure ActivateChangeLogDontConfirm()
    var
        ChangeLogSetup: Record "Change Log Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ChangeLogSetupPage: TestPage "Change Log Setup";
    begin
        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetChangeLogSetup(false);

        // Exercise
        ChangeLogSetupPage.OpenEdit();
        ChangeLogSetupPage."Change Log Activated".SetValue(true);
        ChangeLogSetupPage.Close();

        // Verify
        ChangeLogSetup.Get();
        Assert.IsFalse(ChangeLogSetup."Change Log Activated", 'Change Log was activated.');

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAllFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // Exercise
        CreateAndLogInsert(RecRef);

        // Verify
        AssertAllFields(RecRef, TypeOfChangeOption::Insertion);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAllFieldsNoLogTemp()
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // Exercise
        TempItem.Validate("No.", '');
        TempItem.Insert(true);
        RecRef.GetTable(TempItem);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAllFieldsNoLogOnInsert()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"All Fields", LogOption::"All Fields");

        // Exercise
        CreateAndLogInsert(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertSomeFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::" ", LogOption::" ");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], true, false, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], true, false, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], true, false, false);

        // Exercise
        CreateAndLogInsert(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 3);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[1], TypeOfChangeOption::Insertion);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[2], TypeOfChangeOption::Insertion);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[3], TypeOfChangeOption::Insertion);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertSomeFieldsNoLogOnInsert()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"Some Fields", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], true, false, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], true, false, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], true, false, false);

        // Exercise
        CreateAndLogInsert(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertSomeFieldsNoInsertLogOnFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::"Some Fields", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, true, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], false, true, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], false, true, true);

        // Exercise
        CreateAndLogInsert(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertChangeLogMaxLengthField()
    var
        ChangeLogEntry: Record "Change Log Entry";
        TestTableWithLargeField: Record "Test Table with large field";
        RecRef: RecordRef;
        LocalTableNo: Integer;
    begin
        Initialize();

        LocalTableNo := DATABASE::"Test Table with large field";
        SetTableForChangeLog(LocalTableNo, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // Exercise: Setting the field value to max length.
        TestTableWithLargeField.Init();
        TestTableWithLargeField.PK := 1;
        TestTableWithLargeField.Description :=
          CopyStr(LibraryRandom.RandText(MaxStrLen(TestTableWithLargeField.Description)),
            1, MaxStrLen(TestTableWithLargeField.Description));
        TestTableWithLargeField.Insert(true);
        RecRef.GetTable(TestTableWithLargeField);

        // Verify: Check if the values are correctly logged in ChangeLogEntry
        ChangeLogEntry.SetRange("Table No.", LocalTableNo);
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Insertion);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", RecRef.GetPosition(false));
        ChangeLogEntry.SetRange("Field No.", TestTableWithLargeField.FieldNo(Description));

        Assert.RecordCount(ChangeLogEntry, 1);
        ChangeLogEntry.FindFirst();
        Assert.AreEqual(TestTableWithLargeField.Description,
          ChangeLogEntry."New Value",
          'ChangelogEntry should have correct value for field: New Value.');

        ChangeLogEntry.DeleteAll();
        TestTableWithLargeField.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::" ", LogOption::"All Fields");

        // Exercise
        CreateDeleteAndLogDelete(RecRef);

        // Verify
        AssertAllFields(RecRef, TypeOfChangeOption::Deletion);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllFieldsNoLogTemp()
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(DATABASE::Item, LogOption::" ", LogOption::" ", LogOption::"All Fields");

        // Exercise
        TempItem.Validate("No.", '');
        TempItem.Insert(true);
        RecRef.GetTable(TempItem);
        TempItem.Delete(true);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllFieldsNoLogOnDelete()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"All Fields", LogOption::"All Fields", LogOption::" ");

        // Exercise
        CreateDeleteAndLogDelete(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSomeFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::" ", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], false, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], false, false, true);

        // Exercise
        CreateDeleteAndLogDelete(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 3);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[1], TypeOfChangeOption::Deletion);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[2], TypeOfChangeOption::Deletion);
        AssertEntry(RecRef, RecRef, GlobalFieldNo[3], TypeOfChangeOption::Deletion);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSomeFieldsNoLogOnDeletedField()
    var
        Contact: Record Contact;
        RecRef: RecordRef;
        ObsoleteFieldID: Integer;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(DATABASE::Contact, LogOption::" ", LogOption::" ", LogOption::"Some Fields");
        ObsoleteFieldID := 720; // "Coupled to CRM"
        SetFieldsForChangeLog(DATABASE::Contact, ObsoleteFieldID, false, false, true);
        LibraryMarketing.CreateCompanyContact(Contact);
        RecRef.GetTable(Contact);

        // Exercise;
        Contact.Delete(true);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSomeFieldsNoLogOnDelete()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::"Some Fields", LogOption::" ");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], false, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], false, false, true);

        // Exercise
        CreateDeleteAndLogDelete(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSomeFieldsNoDeleteLogOnFields()
    var
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::"Some Fields", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], true, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[2], true, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[3], true, true, false);

        // Exercise
        CreateDeleteAndLogDelete(RecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Deletion, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyAllFields()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"All Fields", LogOption::" ");

        // Exercise - modify one field and check when option is log all fields
        CreateModifyAndLogModify(RecRef, xRecRef);

        Commit();
        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 5); // including modified flag
        AssertEntry(RecRef, xRecRef, GlobalFieldNo[2], TypeOfChangeOption::Modification);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[1], TypeOfChangeOption::Modification);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[2], TypeOfChangeOption::Modification);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[3], TypeOfChangeOption::Modification);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyAllFieldsNoLogTmp()
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(DATABASE::Item, LogOption::" ", LogOption::"All Fields", LogOption::" ");

        // Exercise - modify one field and check when option is log all fields
        TempItem.Validate("No.", '');
        TempItem.Insert(true);
        TempItem.Validate("Replenishment System", TempItem."Replenishment System"::Assembly);
        TempItem.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        RecRef.GetTable(TempItem);
        TempItem.Modify(true);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyAllFieldsNoLogOnModify()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"All Fields", LogOption::" ", LogOption::"All Fields");

        // Exercise - modify one field and check when option is log all fields
        CreateModifyAndLogModify(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifySomeFields()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"Some Fields", LogOption::" ");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[2], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[3], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[1], false, true, false);

        // Exercise
        CreateModifyAndLogModify(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 3);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[2], TypeOfChangeOption::Modification);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[3], TypeOfChangeOption::Modification);
        AssertEntry(RecRef, xRecRef, GlobalExtraFieldNo[1], TypeOfChangeOption::Modification);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifySomeFieldsNoLogOnModifiedField()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"Some Fields", LogOption::" ");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[4], false, true, false);

        // Exercise
        CreateModifyAndLogModify(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifySomeFieldsNoLogOnModify()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::" ", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[2], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[3], false, true, false);

        // Exercise
        CreateModifyAndLogModify(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifySomeFieldsNoModifyLogOnFields()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::"Some Fields", LogOption::"Some Fields", LogOption::"Some Fields");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], true, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[2], true, false, true);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[3], true, false, true);

        // Exercise
        CreateModifyAndLogModify(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameAllFields()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"All Fields", LogOption::" ");

        // Exercise - modify one field and check when option is log all fields
        CreateRenameAndLogRename(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 1);
        AssertEntry(RecRef, xRecRef, GlobalFieldNo[1], TypeOfChangeOption::Modification);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameSomeFields()
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::"Some Fields", LogOption::" ");
        SetFieldsForChangeLog(GlobalTableNo, GlobalFieldNo[1], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[2], false, true, false);
        SetFieldsForChangeLog(GlobalTableNo, GlobalExtraFieldNo[3], false, true, false);

        // Exercise
        CreateRenameAndLogRename(RecRef, xRecRef);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 1);
        AssertEntry(RecRef, xRecRef, GlobalFieldNo[1], TypeOfChangeOption::Modification);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameTempNoLog()
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
        NewNo: Code[20];
        OldNo: Code[20];
    begin
        // Setup
        Initialize();
        SetTableForChangeLog(DATABASE::Item, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // Exercise
        TempItem.Validate("No.", '');
        TempItem.Insert(true);
        NewNo := CopyStr(LibraryUtility.GenerateRandomCode(TempItem.FieldNo("No."), DATABASE::Item), 1, 20);
        OldNo := TempItem."No.";
        TempItem."No." := NewNo;
        RecRef.GetTable(TempItem);
        TempItem.Get(OldNo);
        TempItem.Rename(NewNo);

        // Verify
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Modification, 0);

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadChangeLogEntryForDeletedTable()
    var
        ChangeLogEntry: Record "Change Log Entry";
        TableNo: Integer;
        FieldNo: Integer;
        NewValue: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376549] Change Log Entry can be read for deleted tables
        Initialize();
        TableNo := LibraryRandom.RandIntInRange(1000000, 2000000);
        FieldNo := LibraryRandom.RandIntInRange(1000000, 2000000);

        // [GIVEN] Change Log Entry for TableNo = 1000000 (not exist), FieldNo = 1, New Value = 'TEST'
        MockTableForChangeLog(TableNo);
        NewValue := LibraryUtility.GenerateGUID();
        MockChangeLogEntry(ChangeLogEntry, TableNo, FieldNo, NewValue);

        // [WHEN] Read Change Log Entry: TAB 405 "Change Log Entry".GetLocalNewValue()
        // [THEN] Returned value = 'TEST'
        Assert.AreEqual(NewValue, ChangeLogEntry.GetLocalNewValue(), ChangeLogEntry.FieldCaption("New Value"));

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadChangeLogEntryForDeletedTableField()
    var
        ChangeLogEntry: Record "Change Log Entry";
        TableNo: Integer;
        FieldNo: Integer;
        NewValue: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376549] Change Log Entry can be read for deleted table fields
        Initialize();
        TableNo := DATABASE::Item;
        FieldNo := LibraryRandom.RandIntInRange(1000000, 2000000);

        // [GIVEN] Change Log Entry for TableNo = 27 ("Item"), FieldNo = 1000000 (not exist), New Value = 'TEST'
        MockTableForChangeLog(TableNo);
        NewValue := LibraryUtility.GenerateGUID();
        MockChangeLogEntry(ChangeLogEntry, TableNo, FieldNo, NewValue);

        // [WHEN] Read Change Log Entry: TAB 405 "Change Log Entry".GetLocalNewValue()
        // [THEN] Returned value = 'TEST'
        Assert.AreEqual(NewValue, ChangeLogEntry.GetLocalNewValue(), ChangeLogEntry.FieldCaption("New Value"));

        // Tear down
        TearDown();
    end;

    [Normal]
    local procedure AssertAllFields(RecRef: RecordRef; TypeOfChange: Option Insertion,Modification,Deletion)
    var
        i: Integer;
    begin
        Assert.IsFalse(TypeOfChange = TypeOfChange::Modification, 'Don''t use this function for modifications. Only insert and delete');

        for i := 1 to RecRef.FieldCount do
            // When compare, ignore complex fields and unchanged
            if IsNormalField(RecRef.FieldIndex(i)) and HasValue(RecRef.FieldIndex(i)) then
                AssertEntry(RecRef, RecRef, RecRef.FieldIndex(i).Number, TypeOfChange);
    end;

    local procedure AssertEntry(RecRef: RecordRef; xRecRef: RecordRef; FieldNo: Integer; TypeOfChange: Option Insertion,Modification,Deletion)
    var
        ChangeLogEntry: Record "Change Log Entry";
        AffectedRecRef: RecordRef;
    begin
        Commit();
        ChangeLogEntry.SetRange("Table No.", RecRef.Number);
        ChangeLogEntry.SetRange("Type of Change", TypeOfChange);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", RecRef.GetPosition(false));
        ChangeLogEntry.SetRange("Field No.", RecRef.Field(FieldNo).Number);

        case TypeOfChange of
            TypeOfChange::Insertion:
                begin
                    ChangeLogEntry.SetRange("Old Value", '');
                    ChangeLogEntry.SetRange("New Value", Format(RecRef.Field(FieldNo).Value, 0, 9));
                end;
            TypeOfChange::Modification:
                begin
                    ChangeLogEntry.SetRange("Old Value", Format(xRecRef.Field(FieldNo).Value, 0, 9));
                    ChangeLogEntry.SetRange("New Value", Format(RecRef.Field(FieldNo).Value, 0, 9));
                end;
            TypeOfChange::Deletion:
                begin
                    ChangeLogEntry.SetRange("Old Value", Format(RecRef.Field(FieldNo).Value, 0, 9));
                    ChangeLogEntry.SetRange("New Value", '');
                end;
        end;

        Assert.AreEqual(1, ChangeLogEntry.Count, 'Exected one ChangeLogEntry within the filter:' + ChangeLogEntry.GetFilters);

        if not ChangeLogEntry.FindFirst() then
            exit;

        Assert.AreNotEqual('', ChangeLogEntry.GetFullPrimaryKeyFriendlyName(), 'PrimaryKeyFriendlyName should not be blank.');

        ChangeLogEntry.TestField("Record ID");
        case TypeOfChange of
            TypeOfChange::Insertion, TypeOfChange::Modification:
                AffectedRecRef.Get(ChangeLogEntry."Record ID");
            TypeOfChange::Deletion:
                asserterror AffectedRecRef.Get(ChangeLogEntry."Record ID");
        end;
    end;

    local procedure AssertNoOfEntriesForPK(RecordRef: RecordRef; TypeOfChange: Option Insertion,Modification,Deletion; NoOfEntries: Integer)
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", RecordRef.Number);
        ChangeLogEntry.SetRange("Type of Change", TypeOfChange);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", RecordRef.GetPosition(false));
        Assert.AreEqual(
          NoOfEntries, ChangeLogEntry.Count,
          'Exected ' + Format(NoOfEntries) + ' ChangeLogEntry within the filter:' + ChangeLogEntry.GetFilters);
    end;

    local procedure CreateItem(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    var
        LastEntryNo: Integer;
    begin
        if CVLedgerEntryBuffer.FindLast() then
            LastEntryNo := CVLedgerEntryBuffer."Entry No.";
        CVLedgerEntryBuffer.Init();
        CVLedgerEntryBuffer."Entry No." := LastEntryNo + 1;
        CVLedgerEntryBuffer."Posting Date" := WorkDate();
        CVLedgerEntryBuffer.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CVLedgerEntryBuffer.Description)), 1, MaxStrLen(CVLedgerEntryBuffer.Description));
        CVLedgerEntryBuffer.Open := true;
        CVLedgerEntryBuffer.Insert();
    end;

    local procedure CreateAndLogInsert(var RecRef: RecordRef)
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        CreateItem(CVLedgerEntryBuffer);
        RecRef.GetTable(CVLedgerEntryBuffer);
    end;

    local procedure CreateModifyAndLogModify(var RecRef: RecordRef; var xRecRef: RecordRef)
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        CreateItem(CVLedgerEntryBuffer);
        Sleep(1000);
        xRecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Amount := LibraryRandom.RandDec(10, 2);
        CVLedgerEntryBuffer.Description :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CVLedgerEntryBuffer.Description)), 1, MaxStrLen(CVLedgerEntryBuffer.Description));
        CVLedgerEntryBuffer.Open := false;
        CVLedgerEntryBuffer."Document Type" := CVLedgerEntryBuffer."Document Type"::Invoice;
        CVLedgerEntryBuffer."Posting Date" += 1;
        RecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Modify(true);
    end;

    local procedure CreateDeleteAndLogDelete(var RecRef: RecordRef)
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        CreateItem(CVLedgerEntryBuffer);
        RecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Delete(true);
    end;

    local procedure CreateRenameAndLogRename(var RecRef: RecordRef; var xRecRef: RecordRef)
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        NewNo: Integer;
        OldNo: Integer;
    begin
        CreateItem(CVLedgerEntryBuffer);
        Sleep(1000);
        xRecRef.GetTable(CVLedgerEntryBuffer);
        NewNo := CVLedgerEntryBuffer."Entry No." + 1;
        OldNo := CVLedgerEntryBuffer."Entry No.";
        CVLedgerEntryBuffer."Entry No." := NewNo;
        CVLedgerEntryBuffer."Posting Date" += 1;
        RecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Get(OldNo);
        CVLedgerEntryBuffer.Rename(NewNo);
    end;

    local procedure MockChangeLogEntry(var ChangeLogEntry: Record "Change Log Entry"; NewTableNoValue: Integer; NewFieldNoValue: Integer; NewValue: Text)
    begin
        ChangeLogEntry.Init();
        ChangeLogEntry."Entry No." := LibraryUtility.GetNewRecNo(ChangeLogEntry, ChangeLogEntry.FieldNo("Entry No."));
        ChangeLogEntry."Table No." := NewTableNoValue;
        ChangeLogEntry."Field No." := NewFieldNoValue;
        ChangeLogEntry."Record ID" := ChangeLogEntry.RecordId;
        ChangeLogEntry."New Value" := CopyStr(NewValue, 1, MaxStrLen(ChangeLogEntry."New Value"));
        ChangeLogEntry.Insert();
    end;

    local procedure MockTableForChangeLog(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := TableNo;
        ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"All Fields";
        ChangeLogSetupTable."Log Modification" := ChangeLogSetupTable."Log Modification"::"All Fields";
        ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"All Fields";
        ChangeLogSetupTable.Insert();
    end;

    local procedure DummyLog()
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        RecRef: RecordRef;
    begin
        // initialize change log
        ChangeLogInit();

        // This function is to set the change log - due to design first time it logs double for the record in "subject" - use as blank dummy log in beggining
        SetTableForChangeLog(GlobalTableNo, LogOption::" ", LogOption::" ", LogOption::" ");

        // Insert
        CreateItem(CVLedgerEntryBuffer);
        RecRef.GetTable(CVLedgerEntryBuffer);

        // Modify
        CVLedgerEntryBuffer.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(CVLedgerEntryBuffer.Description)));
        RecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Modify(true);

        // Delete
        RecRef.GetTable(CVLedgerEntryBuffer);
        CVLedgerEntryBuffer.Delete();

        // re-initialize change log
        ChangeLogInit();
    end;

    local procedure HasValue(FieldRef: FieldRef): Boolean
    var
        FieldHasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FieldRef.Type of
            FieldType::Boolean:
                FieldHasValue := FieldRef.Value();
            FieldType::Option:
                FieldHasValue := true;
            FieldType::Integer:
                begin
                    Int := FieldRef.Value();
                    FieldHasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FieldRef.Value();
                    FieldHasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FieldRef.Value();
                    FieldHasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FieldRef.Value();
                    FieldHasValue := T <> 0T;
                end;
            FieldType::BLOB:
                FieldHasValue := false;
            else
                FieldHasValue := Format(FieldRef.Value) <> '';
        end;

        exit(FieldHasValue);
    end;

    local procedure IsNormalField(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.Class = FieldClass::Normal)
    end;

    local procedure SetFieldsForChangeLog(TableNo: Integer; FieldNo: Integer; LogInsertion: Boolean; LogModification: Boolean; LogDeletion: Boolean)
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        LibraryERM.CreateChangeLogField(ChangeLogSetupField, TableNo, FieldNo);
        ChangeLogSetupField.Validate("Log Insertion", LogInsertion);
        ChangeLogSetupField.Validate("Log Modification", LogModification);
        ChangeLogSetupField.Validate("Log Deletion", LogDeletion);
        ChangeLogSetupField.Modify(true);
    end;

    local procedure SetTableForChangeLog(TableNo: Integer; LogInsertion: Option " ","Some Fields","All Fields"; LogModification: Option " ","Some Fields","All Fields"; LogDeletion: Option " ","Some Fields","All Fields")
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        LibraryERM.CreateChangeLogTable(ChangeLogSetupTable, TableNo);
        ChangeLogSetupTable.Validate("Log Insertion", LogInsertion);
        ChangeLogSetupTable.Validate("Log Modification", LogModification);
        ChangeLogSetupTable.Validate("Log Deletion", LogDeletion);
        ChangeLogSetupTable.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueDate()
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
    begin
        TempItem.Init();

        // Year 1932
        TempItem."Last Date Modified" := DMY2Date(31, 12, 1932);
        TempItem.Insert();

        RecRef.GetTable(TempItem);
        AssertFormatValue(RecRef, 62, '1932-12-31');

        // Year 2032
        TempItem."Last Date Modified" := DMY2Date(31, 12, 2032);
        TempItem.Modify();
        RecRef.GetTable(TempItem);
        AssertFormatValue(RecRef, 62, '2032-12-31');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueTime()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
    begin
        TempToDo.Init();
        TempToDo."Start Time" := 235900T;
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 28, '23:59:00');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueDateTime()
    var
        TempJobLedgerEntry: Record "Job Ledger Entry" temporary;
        RecRef: RecordRef;
        DateTimeOffset: DotNet DateTimeOffset;
        OffsetFromUtc: Duration;
    begin
        OffsetFromUtc := DateTimeOffset.Parse('2032-12-31T23:59:00Z').ToLocalTime().Offset;

        TempJobLedgerEntry.Init();
        TempJobLedgerEntry."DateTime Adjusted" := CreateDateTime(19321231D, 235900T) + OffsetFromUtc;
        TempJobLedgerEntry.Insert();

        RecRef.GetTable(TempJobLedgerEntry);
        AssertFormatValue(RecRef, 1029, '1932-12-31T23:59:00Z');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueDuration()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
        Duration: Duration;
    begin
        TempToDo.Init();

        Duration := CreateDateTime(20090505D, 133001T) - CreateDateTime(20090101D, 080000T);

        TempToDo.Duration := Duration;
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 29, 'P124DT4H30M1.0S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueDecimal()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
    begin
        TempToDo.Init();
        TempToDo."Unit Cost (LCY)" := 11111.22;
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 41, '11111.22');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueBoolean()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
    begin
        TempToDo.Init();
        TempToDo.Closed := true;
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 13, 'true');

        TempToDo.Closed := false;
        TempToDo.Modify();
        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 13, 'false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueOption()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
    begin
        TempToDo.Init();
        TempToDo.Type := TempToDo.Type::"Phone Call";
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 8, Format(TempToDo.Type::"Phone Call", 0, 9));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatValueXmlText()
    var
        TempToDo: Record "To-do" temporary;
        RecRef: RecordRef;
        TempChar: Char;
    begin
        TempToDo.Init();
        TempToDo.Description := '<xmlnode attr="1">value</xmlnode>';
        TempToDo.Insert();

        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 12, '<xmlnode attr="1">value</xmlnode>');

        // Special character
        TempChar := 211;
        TempToDo.Description := Format(TempChar);
        TempToDo.Modify();
        RecRef.GetTable(TempToDo);
        AssertFormatValue(RecRef, 12, Format(TempChar));
    end;

    local procedure AssertFormatValue(RecRef: RecordRef; FieldId: Integer; ExpectedValue: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldId);
        Assert.AreEqual(ExpectedValue, Format(FieldRef, 0, 9), 'FormatValue returned an unexpected value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefOption()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        CultureNeutralValue: Text;
    begin
        CultureNeutralValue := Format(GLSetup."Local Address Format"::"City+Post Code", 0, 9);

        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Local Address Format"));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef(CultureNeutralValue, FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(GLSetup."Local Address Format"::"City+Post Code", FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefInteger()
    var
        GLEntry: Record "G/L Entry";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"G/L Entry");
        FieldRef := RecRef.Field(GLEntry.FieldNo("Entry No."));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('1234', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(1234, FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefDecimal()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Inv. Rounding Precision (LCY)"));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('1234.5', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(1234.5, FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefDate()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Allow Posting From"));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('2032-12-31', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(20321231D, FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('32-12-31', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefTime()
    var
        ChangeLogEntry: Record "Change Log Entry";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Change Log Entry");
        FieldRef := RecRef.Field(ChangeLogEntry.FieldNo(Time));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('23:59:00', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(235900T, FieldRef.Value, BadParsedValueErr);
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('23:59:59', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(235959T, FieldRef.Value, BadParsedValueErr);
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('23:59:00.01', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(235900.010T, FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('2359', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefDateTime()
    var
        ChangeLogEntry: Record "Change Log Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        DateTimeOffset: DotNet DateTimeOffset;
        TmpDateTime: DateTime;
        OffsetFromUtc: Duration;
    begin
        RecRef.Open(DATABASE::"Change Log Entry");
        FieldRef := RecRef.Field(ChangeLogEntry.FieldNo("Date and Time"));

        OffsetFromUtc := DateTimeOffset.Parse('2032-12-31T23:59:00Z').ToLocalTime().Offset;
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('2032-12-31T23:59:00Z', FieldRef), ParseShouldSucceedErr);
        TmpDateTime := FieldRef.Value();
        TmpDateTime := TmpDateTime - OffsetFromUtc;
        Assert.AreEqual(235900T, DT2Time(TmpDateTime), BadParsedValueErr);
        Assert.AreEqual(20321231D, DT2Date(TmpDateTime), BadParsedValueErr);

        OffsetFromUtc := DateTimeOffset.Parse('2032-12-31T23:59:00').ToLocalTime().Offset;
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('2032-12-31T23:59:00', FieldRef), ParseShouldSucceedErr);
        TmpDateTime := FieldRef.Value();
        TmpDateTime := TmpDateTime - OffsetFromUtc;
        Assert.AreEqual(235900T, DT2Time(TmpDateTime), BadParsedValueErr);
        Assert.AreEqual(20321231D, DT2Date(TmpDateTime), BadParsedValueErr);

        OffsetFromUtc := DateTimeOffset.Parse('2032-06-30T23:59:00Z').ToLocalTime().Offset;
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('2032-06-30T23:59:00Z', FieldRef), ParseShouldSucceedErr);
        TmpDateTime := FieldRef.Value();
        TmpDateTime := TmpDateTime - OffsetFromUtc;
        Assert.AreEqual(235900T, DT2Time(TmpDateTime), BadParsedValueErr);
        Assert.AreEqual(20320630D, DT2Date(TmpDateTime), BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefBoolean()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Register Time"));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('True', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(true, FieldRef.Value, BadParsedValueErr);

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('False', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual(false, FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('Yes', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('No', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('32-12-31', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefBigInteger()
    var
        ChangeLogEntry: Record "Change Log Entry";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        TmpBigInteger: BigInteger;
    begin
        RecRef.Open(DATABASE::"Change Log Entry");
        FieldRef := RecRef.Field(ChangeLogEntry.FieldNo("Entry No."));

        // Too big for a 32-bit integer
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('5000000000', FieldRef), ParseShouldSucceedErr);
        TmpBigInteger := FieldRef.Value();
        Assert.IsTrue(5000000000.0 = TmpBigInteger, BadParsedValueErr);

        // Max and min NAV literal value
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('999999999999999', FieldRef), ParseShouldSucceedErr);
        TmpBigInteger := FieldRef.Value();
        Assert.IsTrue(999999999999999.0 = TmpBigInteger, BadParsedValueErr);
        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('-999999999999999', FieldRef), ParseShouldSucceedErr);
        TmpBigInteger := FieldRef.Value();
        Assert.IsTrue(-999999999999999.0 = TmpBigInteger, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('50000000000000000000', FieldRef), ParseShouldSucceedErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('12D', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefGUID()
    var
        JobQueueEntry: Record "Job Queue Entry";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        TmpGuid: Guid;
    begin
        RecRef.Open(DATABASE::"Job Queue Entry");
        FieldRef := RecRef.Field(JobQueueEntry.FieldNo(ID));

        Assert.IsTrue(
          ChangeLogManagement.EvaluateTextToFieldRef('43CA7638-EA6E-45A0-AF8D-414C1D46A012', FieldRef),
          ParseShouldSucceedErr);
        TmpGuid := FieldRef.Value();
        Assert.IsTrue('43CA7638-EA6E-45A0-AF8D-414C1D46A012' = TmpGuid, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefCode()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Bank Account Nos."));

        Assert.IsTrue(
          ChangeLogManagement.EvaluateTextToFieldRef(GLSetup."Bank Account Nos.", FieldRef),
          ParseShouldSucceedErr);
        Assert.AreEqual(GLSetup."Bank Account Nos.", FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('TooLongCode0123456789', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefText()
    var
        GLEntry: Record "G/L Entry";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"G/L Entry");
        FieldRef := RecRef.Field(GLEntry.FieldNo(Description));

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('Test text', FieldRef), ParseShouldSucceedErr);
        Assert.AreEqual('Test text', FieldRef.Value, BadParsedValueErr);

        Assert.IsFalse(
          ChangeLogManagement.EvaluateTextToFieldRef(
            'TooLongText123456789012345678901234567890123456789012345678901234567890123456789012345678900123456789001234567890',
            FieldRef),
          ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefDateFormula()
    var
        GLSetup: Record "General Ledger Setup";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        TmpDateFormula: DateFormula;
        TmpDateFormulaParsed: DateFormula;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Payment Discount Grace Period"));

        Evaluate(TmpDateFormula, '<+1Y>');

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('+1Y', FieldRef), ParseShouldSucceedErr);
        TmpDateFormulaParsed := FieldRef.Value();
        Assert.IsTrue(TmpDateFormula = TmpDateFormulaParsed, BadParsedValueErr);

        Assert.IsFalse(
          ChangeLogManagement.EvaluateTextToFieldRef('Long Long Time Ago In a galaxy far away', FieldRef),
          ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateTextToFieldRefDuration()
    var
        ToDo: Record "To-do";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        TmpDuration: Duration;
        TmpDurationParsed: Duration;
    begin
        ToDo.Init();
        ToDo.Date := DMY2Date(1, 1, 2000);
        RecRef.GetTable(ToDo);
        FieldRef := RecRef.Field(ToDo.FieldNo(Duration));

        TmpDuration := CreateDateTime(20000101D, 080000T) - CreateDateTime(20000101D, 000000T);

        Assert.IsTrue(ChangeLogManagement.EvaluateTextToFieldRef('P0DT8H0M0.0S', FieldRef), ParseShouldSucceedErr);
        TmpDurationParsed := FieldRef.Value();
        Assert.IsTrue(TmpDuration = TmpDurationParsed, BadParsedValueErr);

        Assert.IsFalse(ChangeLogManagement.EvaluateTextToFieldRef('abc', FieldRef), ParseShouldFailErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsActionOnLotNoInformationCardDoesNotCreateOnInsertLogEntries()
    var
        LotNoInformation: Record "Lot No. Information";
        RecRef: RecordRef;
        LotNoInformationCard: TestPage "Lot No. Information Card";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381315] Entries should not be added to Change Log when Item Tracking Comments is opened from Lot No. Information Card
        Initialize();

        // [GIVEN] Insert option is activated in Change Log Setup for Lot No. Information table
        SetTableForChangeLog(DATABASE::"Lot No. Information", LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // [GIVEN] Lot No. Information with Item = "X" and 3 entries in Change Log
        LibraryInventory.CreateLotNoInformation(LotNoInformation, LibraryInventory.CreateItemNo(), '', LibraryUtility.GenerateGUID());
        RecRef.GetTable(LotNoInformation);
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 3);

        // [WHEN] Open Item Tracking Comments from Lot No. Information Card for Item "X"
        LotNoInformationCard.OpenView();
        LotNoInformationCard.GotoRecord(LotNoInformation);
        ItemTrackingComments.Trap();
        LotNoInformationCard.Comment.Invoke();
        ItemTrackingComments.Close();

        // [THEN] No additional entries records created in Change Log Entries for Lot No. Information with Item = "X"
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 3);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsActionOnLotNoInformationListDoesNotCreateOnInsertLogEntries()
    var
        LotNoInformation: Record "Lot No. Information";
        RecRef: RecordRef;
        LotNoInformationList: TestPage "Lot No. Information List";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381315] Entries should not be added to Change Log when Item Tracking Comments is opened from Lot No. Information List
        Initialize();

        // [GIVEN] Insert option is activated in Change Log Setup for Lot No. Information table
        SetTableForChangeLog(DATABASE::"Lot No. Information", LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // [GIVEN] Lot No. Information with Item = "X" and 3 entries in Change Log
        LibraryInventory.CreateLotNoInformation(LotNoInformation, LibraryInventory.CreateItemNo(), '', LibraryUtility.GenerateGUID());
        RecRef.GetTable(LotNoInformation);
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 3);

        // [WHEN] Open Item Tracking Comments from Lot No. Information List for Item "X"
        LotNoInformationList.OpenView();
        LotNoInformationList.GotoRecord(LotNoInformation);
        ItemTrackingComments.Trap();
        LotNoInformationList.Comment.Invoke();
        ItemTrackingComments.Close();

        // [THEN] No additional entries records created in Change Log Entries for Lot No. Information with Item = "X"
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 3);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsActionOnSerialNoInformationCardDoesNotCreateOnInsertLogEntries()
    var
        SerialNoInformation: Record "Serial No. Information";
        RecRef: RecordRef;
        SerialNoInformationCard: TestPage "Serial No. Information Card";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381315] Entries should not be added to Change Log when Item Tracking Comments is opened from Serial No. Information Card
        Initialize();

        // [GIVEN] Insert option is activated in Change Log Setup for Serial No. Information table
        SetTableForChangeLog(DATABASE::"Serial No. Information", LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // [GIVEN] Serial No. Information with Item = "X" and 2 entries in Change Log
        LibraryInventory.CreateSerialNoInformation(SerialNoInformation, LibraryInventory.CreateItemNo(), '', LibraryUtility.GenerateGUID());
        RecRef.GetTable(SerialNoInformation);
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 2);

        // [WHEN] Open Item Tracking Comments from Serial No. Information Card for Item "X"
        SerialNoInformationCard.OpenView();
        SerialNoInformationCard.GotoRecord(SerialNoInformation);
        ItemTrackingComments.Trap();
        SerialNoInformationCard.Comment.Invoke();
        ItemTrackingComments.Close();

        // [THEN] No additional entries records created in Change Log Entries for Serial No. Information with Item = "X"
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 2);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsActionOnSerialNoInformationListDoesNotCreateOnInsertLogEntries()
    var
        SerialNoInformation: Record "Serial No. Information";
        RecRef: RecordRef;
        SerialNoInformationList: TestPage "Serial No. Information List";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381315] Entries should not be added to Change Log when Item Tracking Comments is opened from Serial No. Information List
        Initialize();

        // [GIVEN] Insert option is activated in Change Log Setup for Serial No. Information table
        SetTableForChangeLog(DATABASE::"Serial No. Information", LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // [GIVEN] Serial No. Information with Item = "X" and 2 entries in Change Log
        LibraryInventory.CreateSerialNoInformation(SerialNoInformation, LibraryInventory.CreateItemNo(), '', LibraryUtility.GenerateGUID());
        RecRef.GetTable(SerialNoInformation);
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 2);

        // [WHEN] Open Item Tracking Comments from Serial No. Information List for Item "X"
        SerialNoInformationList.OpenView();
        SerialNoInformationList.GotoRecord(SerialNoInformation);
        ItemTrackingComments.Trap();
        SerialNoInformationList.Comment.Invoke();
        ItemTrackingComments.Close();

        // [THEN] No additional entries records created in Change Log Entries for Serial No. Information with Item = "X"
        AssertNoOfEntriesForPK(RecRef, TypeOfChangeOption::Insertion, 2);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('REP510RequestPageHandlerFilterSet')]
    [Scope('OnPrem')]
    procedure DeleteLogEntriesRequestPageFilterSet()
    begin
        // [SCENARIO] User wants to delete log entries (REP510). Date filter should be preset
        // [GIVEN] The user has admin rights
        DeleteAllLogEntries();

        // [WHEN] User Starts Delete Change Log Entries
        REPORT.RunModal(REPORT::"Change Log - Delete");

        // [THEN] The report request page has prefilled date filter
        // Verified in the requestpage handler: REP510RequestPageHandlerFilterSet
    end;

    [Test]
    [HandlerFunctions('REP510RequestPageHandlerNoFilterSet,ConfirmHandlerREP510Cancel')]
    [Scope('OnPrem')]
    procedure DeleteLogEntriesRequestPageNoFilterSet()
    begin
        // [SCENARIO] User wants to delete log entries (REP510). Warning should be shown if no date filter is shown
        // [GIVEN] The user has admin rights
        DeleteAllLogEntries();

        // [WHEN] User Starts Delete Change Log Entries and removes the date filter
        REPORT.RunModal(REPORT::"Change Log - Delete");

        // [THEN] The report request page displays a warning
        // Verified in the requestpage handler: REP510RequestPageHandlerNoFilterSet
    end;

    [Test]
    [HandlerFunctions('REP510RequestPageHandlerNothingToDelete,MessageHandlerNothingToDelete')]
    [Scope('OnPrem')]
    procedure DeleteLogEntriesRequestPageNothingToDelete()
    begin
        // [SCENARIO] User wants to delete log entries (REP510). Error that no entries exist
        // [GIVEN] The user has admin rights
        DeleteAllLogEntries();

        // [WHEN] User Starts Delete Change Log Entries
        REPORT.RunModal(REPORT::"Change Log - Delete");

        // [THEN] The report request page has prefilled date filter
        // Verified in the requestpage handler: REP510RequestPageHandlerNothingToDelete
    end;

    [Test]
    [HandlerFunctions('REP510RequestPageHandlerRunDeletion,MessageHandlerDeleted')]
    [Scope('OnPrem')]
    procedure DeleteLogEntriesVerifyDeletion()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        // [SCENARIO] User wants to delete log entries (REP510). Verify that old entries are deleted
        // [GIVEN] The user has admin rights and a changelogentry exists
        DeleteAllLogEntries();
        CreateChangeLogEntry(CalcDate('<-2Y>', Today));
        Commit();
        Assert.AreNotEqual(0, ChangeLogEntry.Count, 'No entries created');

        // [WHEN] User Starts Delete Change Log Entries
        REPORT.RunModal(REPORT::"Change Log - Delete");

        // [THEN] The entries are deleted
        Assert.AreEqual(0, ChangeLogEntry.Count, 'Not all entries deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTenantPermissionSetRelsIsLogged()
    var
        ChangeLogSetup: Record "Change Log Setup";
        TenantPermissionSetA: Record "Tenant Permission Set";
        TenantPermissionSetB: Record "Tenant Permission Set";
        TenantPermissionSetRel: Record "Tenant Permission Set Rel.";
        ChangeLogEntry: Record "Change Log Entry";
        ZeroGuid: Guid;
    begin
        // [SCENARIO] Change log entry is created when Tenant Permission Set Rel record is inserted.
        Initialize();

        // [GIVEN] Change Log is activated.
        ChangeLogSetup.Get();
        ChangeLogSetup.Validate("Change Log Activated", true);
        ChangeLogSetup.Modify();

        // [GIVEN] Two tenant Permission Set.
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSetA, LibraryUtility.GenerateGUID(), ZeroGuid);
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSetB, LibraryUtility.GenerateGUID(), ZeroGuid);

        // [WHEN] A relation between the two is created
        TenantPermissionSetRel.Init();
        TenantPermissionSetRel."Role ID" := TenantPermissionSetA."Role ID";
        TenantPermissionSetRel."App ID" := TenantPermissionSetA."App ID";
        TenantPermissionSetRel."Related Role ID" := TenantPermissionSetB."Role ID";
        TenantPermissionSetRel."Related App ID" := TenantPermissionSetB."App ID";
        TenantPermissionSetRel."Related Scope" := TenantPermissionSetRel."Related Scope"::Tenant;
        TenantPermissionSetRel.Insert();

        // [THEN] Change Log Entry is created for Tenant Permission Set Rel.
        ChangeLogEntry.SetRange("Table No.", DATABASE::"Tenant Permission Set Rel.");
        ChangeLogEntry.SetRange("New Value", TenantPermissionSetRel."Role ID");
        Assert.RecordIsNotEmpty(ChangeLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTenantPermissionSetsIsLogged()
    var
        ChangeLogSetup: Record "Change Log Setup";
        TenantPermissionSet: Record "Tenant Permission Set";
        ChangeLogEntry: Record "Change Log Entry";
        ZeroGuid: Guid;
    begin
        // [SCENARIO 223616] Change log entry is created when Tenant Permission Set record is inserted.
        Initialize();

        // [GIVEN] Change Log is activated.
        ChangeLogSetup.Get();
        ChangeLogSetup.Validate("Change Log Activated", true);
        ChangeLogSetup.Modify();

        // [WHEN] Insert new Tenant Permission Set.
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID(), ZeroGuid);

        // [THEN] Change Log Entry is created for Tenant Permission Set.
        ChangeLogEntry.SetRange("Table No.", DATABASE::"Tenant Permission Set");
        ChangeLogEntry.SetRange("New Value", TenantPermissionSet."Role ID");
        Assert.RecordIsNotEmpty(ChangeLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTenantPermissionIsLogged()
    var
        ChangeLogSetup: Record "Change Log Setup";
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        ChangeLogEntry: Record "Change Log Entry";
        ZeroGuid: Guid;
    begin
        // [SCENARIO 223616] Change log entry is created when Tenant Permission record is inserted.
        Initialize();

        // [GIVEN] Change Log is activated.
        ChangeLogSetup.Get();
        ChangeLogSetup.Validate("Change Log Activated", true);
        ChangeLogSetup.Modify();

        // [WHEN] Insert new Tenant Permission.
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID(), ZeroGuid);
        CreateTenantPermission(TenantPermission, ZeroGuid, GenerateRandomTenantPermissionRoleID(),
          TenantPermission."Object Type"::Table, 0);

        // [THEN] Change Log Entry is created for Tenant Permission.
        ChangeLogEntry.SetRange("Table No.", DATABASE::"Tenant Permission");
        ChangeLogEntry.SetRange("New Value", TenantPermission."Role ID");
        Assert.RecordIsNotEmpty(ChangeLogEntry);
    end;

    [Test]
    procedure PageVariableBasedFieldsAreNotEditableInViewMode()
    var
        ChangeLogSetupTableListPage: TestPage "Change Log Setup (Table) List";
        ChangeLogSetupFieldListPage: TestPage "Change Log Setup (Field) List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 346691] Variable-based fields must not be editable when page is in View Mode
        ChangeLogSetupTableListPage.OpenView();
        Assert.IsFalse(ChangeLogSetupTableListPage.Editable(), '');
        Assert.IsFalse(ChangeLogSetupTableListPage.LogInsertion.Editable(), '');
        Assert.IsFalse(ChangeLogSetupTableListPage.LogModification.Editable(), '');
        Assert.IsFalse(ChangeLogSetupTableListPage.LogDeletion.Editable(), '');
        ChangeLogSetupTableListPage.Close();

        ChangeLogSetupFieldListPage.OpenView();
        Assert.IsFalse(ChangeLogSetupFieldListPage.Editable(), '');
        Assert.IsFalse(ChangeLogSetupFieldListPage."Log Insertion".Editable(), '');
        Assert.IsFalse(ChangeLogSetupFieldListPage."Log Modification".Editable(), '');
        Assert.IsFalse(ChangeLogSetupFieldListPage."Log Deletion".Editable(), '');
        ChangeLogSetupFieldListPage.Close();
    end;

    [Test]
    procedure PageVariableBasedFieldsAreEditableInEditMode()
    var
        ChangeLogSetupTableListPage: TestPage "Change Log Setup (Table) List";
        ChangeLogSetupFieldListPage: TestPage "Change Log Setup (Field) List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 346691] Variable-based fields must be editable when page is in Edit Mode
        ChangeLogSetupTableListPage.OpenEdit();
        Assert.IsTrue(ChangeLogSetupTableListPage.Editable(), '');
        Assert.IsTrue(ChangeLogSetupTableListPage.LogInsertion.Editable(), '');
        Assert.IsTrue(ChangeLogSetupTableListPage.LogModification.Editable(), '');
        Assert.IsTrue(ChangeLogSetupTableListPage.LogDeletion.Editable(), '');
        ChangeLogSetupTableListPage.Close();

        ChangeLogSetupFieldListPage.OpenEdit();
        Assert.IsTrue(ChangeLogSetupFieldListPage.Editable(), '');
        Assert.IsTrue(ChangeLogSetupFieldListPage."Log Insertion".Editable(), '');
        Assert.IsTrue(ChangeLogSetupFieldListPage."Log Modification".Editable(), '');
        Assert.IsTrue(ChangeLogSetupFieldListPage."Log Deletion".Editable(), '');
        ChangeLogSetupFieldListPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeLogEntryGetPrimaryKeyFriendlyNameForLongPrimaryKey()
    var
        ChangeLogEntry: Record "Change Log Entry";
        CustomReportSelection: Record "Custom Report Selection";
        TableNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 384259] Change Log Entry function GetPrimaryKeyFriendlyName doesn't throw error on records with long Primary Key.
        Initialize();

        // Mock table insert
        TableNo := DATABASE::"Custom Report Selection";
        CustomReportSelection."Source Type" := 1;
        CustomReportSelection."Source No." := LibraryUtility.GenerateRandomCode20(CustomReportSelection.FieldNo("Source No."), TableNo);
        CustomReportSelection.Usage := CustomReportSelection.Usage::JQ;
        CustomReportSelection.Sequence := 1000;
        CustomReportSelection.Insert();

        ChangeLogEntry."Table No." := TableNo;
        ChangeLogEntry."Primary Key" := CopyStr(CustomReportSelection.GetPosition(false), 1, MaxStrLen(ChangeLogEntry."Primary Key"));

        ChangeLogEntry.GetFullPrimaryKeyFriendlyName();
        CustomReportSelection.Delete();
    end;

    [Test]
    [HandlerFunctions('ChangeLogSetupTableListHandler')]
    procedure UsersCannotEnableLoggingOnChangeLogEntry()
    var
        ChangeLogEntry: Record "Change Log Entry";
        ChangeLogSetup: TestPage "Change Log Setup";
        CannotEnableChangeLogErr: Label 'Change log cannot be enabled for the table %1', Comment = '%1: Table caption';
    begin
        // [SCENARIO] Changelog cannot be enabled for the table "Change Log Entry"

        Initialize();

        // [GIVEN] Open the "Changelog Setup Tables List"
        // [WHEN] Select the table "Change Log Entry" and try to change the Insertion logging to "All Fields"
        // Test action is called in the page handler
        ChangeLogSetup.OpenEdit();
        ChangeLogSetup.Tables.Invoke();

        // [THEN] Modification fails with an error informing that the change log cannot be enabled for the Change Log Entry table
        Assert.ExpectedError(StrSubstNo(CannotEnableChangeLogErr, ChangeLogEntry.TableCaption));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if (Question <> RestartSessionQst) then begin
            Assert.ExpectedMessage(ActivateChangeLogQst, Question);
            Reply := true;
        end else
            Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerREP510Cancel(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, RunWithoutFilterQst) > 0, '');
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerDeleted(MessageText: Text)
    begin
        Assert.IsTrue(StrPos(MessageText, DeletedMsg) > 0, '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerNothingToDelete(MessageText: Text)
    begin
        Assert.IsTrue(StrPos(MessageText, NothingToDeleteErr) > 0, '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure REP510RequestPageHandlerFilterSet(var ChangeLogDelete: TestRequestPage "Change Log - Delete")
    begin
        Assert.AreNotEqual('', ChangeLogDelete."Change Log Entry".GetFilter("Date and Time"), '');
        ChangeLogDelete.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure REP510RequestPageHandlerNoFilterSet(var ChangeLogDelete: TestRequestPage "Change Log - Delete")
    begin
        ChangeLogDelete."Change Log Entry".SetFilter("Date and Time", '');
        ChangeLogDelete.OK().Invoke();
        // Raises a confirm dialog ConfirmHandlerREP510Cancel that should return 'no'
        ChangeLogDelete.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure REP510RequestPageHandlerNothingToDelete(var ChangeLogDelete: TestRequestPage "Change Log - Delete")
    begin
        ChangeLogDelete.OK().Invoke();
        ChangeLogDelete.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure REP510RequestPageHandlerRunDeletion(var ChangeLogDelete: TestRequestPage "Change Log - Delete")
    begin
        ChangeLogDelete.OK().Invoke();
    end;

    local procedure CreateTenantPermission(var TenantPermission: Record "Tenant Permission"; AppID: Guid; RoleID: Code[20]; ObjectType: Option; ObjectID: Integer);
    begin
        LibraryPermissions.AddTenantPermission(AppID, RoleID, ObjectType, ObjectID);
        TenantPermission.SetRange("App ID", AppID);
        TenantPermission.SetRange("Role ID", RoleID);
        TenantPermission.SetRange("Object Type", ObjectType);
        TenantPermission.SetRange("Object ID", ObjectID);
        TenantPermission.FindFirst();
    end;

    local procedure GenerateRandomTenantPermissionRoleID(): Code[20]
    var
        TenantPermission: Record "Tenant Permission";
    begin
        exit(LibraryUtility.GenerateRandomCode20(TenantPermission.FieldNo("Role ID"), DATABASE::"Tenant Permission"));
    end;

    local procedure CreateChangeLogEntry(EventDate: Date)
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.Init();
        ChangeLogEntry."Date and Time" := CreateDateTime(EventDate, 0T);
        ChangeLogEntry."Table No." := DATABASE::"Change Log Entry";
        ChangeLogEntry."Field No." := ChangeLogEntry.FieldNo("Field No.");
        ChangeLogEntry.Insert();
    end;

    local procedure DeleteAllLogEntries()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.Reset();
        ChangeLogEntry.DeleteAll();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateOutOfBoundIndexInChangeLog()
    var
        TenantWebService: Record "Tenant Web Service";
        ChangeLogEntry: Record "Change Log Entry";
        ChangelogManagement: Codeunit "Change Log Management";
        RecRef: RecordRef;
        LocalTableNo: Integer;
    begin
        // Setup
        Initialize();

        LocalTableNo := DATABASE::"Tenant Web Service";

        SetTableForChangeLog(LocalTableNo, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // Exercise: Setting the primary key value, exceeding the max length for ChangeLogEntry fields.
        TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
        TenantWebService."Service Name" :=
          CopyStr(LibraryRandom.RandText(MaxStrLen(ChangeLogEntry."Primary Key Field 2 Value") + 1),
            1, MaxStrLen(TenantWebService."Service Name"));

        RecRef.GetTable(TenantWebService);

        // Global trigger management may have cache the mask for this table. We need to call the method directly to unit test the functionality
        ChangelogManagement.LogInsertion(RecRef);

        // Verify: Check if the values are correctly logged in ChangeLogEntry
        ChangeLogEntry.SetRange("Table No.", LocalTableNo);
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Insertion);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(ChangeLogEntry."Primary Key")));
        ChangeLogEntry.SetRange("Field No.", TenantWebService.FieldNo("Service Name"));

        Assert.RecordCount(ChangeLogEntry, 1);
        ChangeLogEntry.FindFirst();

        Assert.AreEqual(TenantWebService."Service Name",
          ChangeLogEntry."New Value",
          'ChangelogEntry should have correct value for field: New Value.');
        Assert.AreEqual(CopyStr(TenantWebService."Service Name", 1, MaxStrLen(ChangeLogEntry."Primary Key Field 2 Value")),
          ChangeLogEntry."Primary Key Field 2 Value",
          'Primary key only contains the first max length allowed characters of the original value.');

        // Tear down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreventInsertChangeLogEntryTableIntoChangeLogSetupTable()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        // Setup
        Initialize();

        // [GIVEN] Change Log Setup Table with table "Change Log"
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := DATABASE::"Change Log Entry";
        ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"All Fields";
        ChangeLogSetupTable."Log Modification" := ChangeLogSetupTable."Log Modification"::"All Fields";
        ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"All Fields";

        // [WHEN] Change Log Setup Table is inserted, an error occurs
        asserterror ChangeLogSetupTable.Insert();

        // [THEN] Error is raised when trying to insert the record
        Assert.ExpectedError('Change log cannot be enabled for the table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreventRenameChangeLogEntryTableInChangeLogSetupTable()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        // Setup
        Initialize();

        // [GIVEN] Change Log Setup Table with table "Item" inserted
        SetTableForChangeLog(Database::Item, LogOption::"All Fields", LogOption::" ", LogOption::" ");

        // [WHEN] Change Log Setup Table with Item is modified to "Change Log Entry", an error occurs
        ChangeLogSetupTable.FindFirst();
        asserterror ChangeLogSetupTable.Rename(Database::"Change Log Entry");

        // [THEN] Error is raised when trying to insert the record
        Assert.ExpectedError('Change log cannot be enabled for the table');
    end;

    [ModalPageHandler]
    procedure ChangeLogSetupTableListHandler(var ChangeLogSetupTableList: TestPage "Change Log Setup (Table) List")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTableList.GoToKey(AllObjWithCaption."Object Type"::Table, Database::"Change Log Entry");
        asserterror ChangeLogSetupTableList.LogInsertion.SetValue(ChangeLogSetupTable."Log Insertion"::"All Fields");
    end;
}
