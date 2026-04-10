codeunit 139066 "Monitor Field Pages Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WorksheetPageUI()
    var
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] Verify UI in Monitored Fields Worksheet page
        // [WHEN] Open Monitored Fields Worksheet page
        MonitoredFieldsWorksheet.OpenEdit();

        // [THEN] Check editable fields and initial value
        Assert.AreEqual(MonitoredFieldsWorksheet.Editable(), true, 'Page must be editable');
        Assert.IsTrue(MonitoredFieldsWorksheet.TableNo.Editable(), '"Table No" field must be editable');
        Assert.IsTrue(MonitoredFieldsWorksheet."Field No".Editable(), '"Field No" field must be editable');
        Assert.IsTrue(MonitoredFieldsWorksheet.Notify.Editable(), '"Notify" field must be editable');
        Assert.IsFalse(MonitoredFieldsWorksheet."Field Caption".Editable(), '"Table Caption" must not be editable');
        Assert.IsFalse(MonitoredFieldsWorksheet."Table Caption".Editable(), '"Field Caption" must not be editable');

        MonitoredFieldsWorksheet.Close();
    end;

    [Test]
    procedure WorksheetLinkedPages()
    var
        FieldMonitoringSetupPage: TestPage "Field Monitoring Setup";
        MonitoredFieldLogEntries: TestPage "Monitored Field Log Entries";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] Verify linked pages in Monitored Fields Worksheet page
        MonitoredFieldsWorksheet.OpenEdit();

        // [WHEN] Clicking on Setup Monitor action
        // [THEN] Setup page should be opened
        FieldMonitoringSetupPage.Trap();
        MonitoredFieldsWorksheet."Setup Monitor".Invoke();
        FieldMonitoringSetupPage.Close();

        // [WHEN] Clicking on Entries action
        // [THEN] Entries page should be opened
        MonitoredFieldLogEntries.Trap();
        MonitoredFieldsWorksheet."Changes Entries".Invoke();
        MonitoredFieldLogEntries.Close();

        MonitoredFieldsWorksheet.Close();
    end;

    [Test]
    procedure AddFieldToMonitor()
    var
        TestTableC: Record "Test Table C";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] Add field in worksheet page will create records in Chnage Log Setup Table and Feild 
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();
        MonitoredFieldsWorksheet.OpenEdit();

        // [WHEN] Opening the page and inseting system table field through UI
        MonitoredFieldsWorksheet.New();
        MonitoredFieldsWorksheet.TableNo.Value(Format(Database::"Test Table C"));
        MonitoredFieldsWorksheet."Field No".Value(Format(TestTableC.FieldNo("Integer Field")));
        MonitoredFieldsWorksheet.Close();
        MonitorFieldTestHelper.AssertMonitoredFieldAddedCorrectly(Database::"Test Table C", TestTableC.FieldNo("Integer Field"));
    end;

    [Test]
    [HandlerFunctions('HandleObjectsPage,HandleFieldsPage')]
    procedure AddFieldUsingTableAndFieldLookup()
    var
        TestTableC: Record "Test Table C";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
        Objects: TestPage Objects;
        FieldsPage: TestPage "Fields Lookup";
    begin
        // [SCENARIO] Add a record in Monitored Fields Worksheet page through lookup
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Opening the page and inseting field through lookup pages
        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.New();

        Objects.Trap();
        MonitoredFieldsWorksheet.TableNo.Lookup();

        FieldsPage.Trap();
        MonitoredFieldsWorksheet."Field No".Lookup();

        MonitoredFieldsWorksheet.Close();

        // [THEN] Validate inserted record
        MonitorFieldTestHelper.AssertMonitoredFieldAddedCorrectly(Database::"Test Table C", TestTableC.FieldNo("Integer Field"));
    end;

    [Test]
    [HandlerFunctions('HandleFieldsPage')]
    procedure AddFieldUsingFieldLookup()
    var
        TestTableC: Record "Test Table C";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
        FieldsPage: TestPage "Fields Lookup";
    begin
        // [SCENARIO] Add a record in Monitored Fields Worksheet page using only field lookup
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();
        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.New();

        // [WHEN] Inserting a field through field lookup page
        FieldsPage.Trap();
        MonitoredFieldsWorksheet."Field No".Lookup();
        MonitoredFieldsWorksheet.Close();

        // [THEN] Validate inserted record
        MonitorFieldTestHelper.AssertMonitoredFieldAddedCorrectly(Database::"Test Table C", TestTableC.FieldNo("Integer Field"));
    end;

    [Test]
    procedure AddSystemTableFields()
    var
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] User can not add a system table field
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();
        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.New();

        // [WHEN] Opening the page and inseting system table field through page
        asserterror MonitoredFieldsWorksheet.TableNo.SetValue(Format(Database::"Table Metadata"));
        Assert.ExpectedError(SystemTableErr);

        MonitoredFieldsWorksheet.Close();
    end;

    [Test]
    procedure AddFieldsMonitoredInChangeLog()
    var
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] User can not use table that are monitored in change log
        // [GIVEN] Clean change log and monitor table and monitor test table in change log
        MonitorFieldTestHelper.InitMonitor();
        SetTableForChangeLog(Database::"Test Table C");

        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.New();

        // [WHEN] Opening the page and inseting field through field lookup page
        asserterror MonitoredFieldsWorksheet.TableNo.Value(Format(Database::"Test Table C"));
        Assert.ExpectedError(TableMonitoredInChangeLogErr);

        MonitoredFieldsWorksheet.Close();
    end;

    [Test]
    procedure WorksheetPageRecords()
    var
        TestTableC: Record "Test Table C";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] Monitored Fields Worksheet page must only display monitor records
        // [GIVEN] Clean change log and monitor tables and set company information table to be monitored in Change Log
        MonitorFieldTestHelper.InitMonitor();
        SetTableForChangeLog(Database::"Company Information");

        // [WHEN] Inserting records in the table
        MonitorSensitiveField.AddMonitoredField(Database::"Test Table C", TestTableC.FieldNo("Integer Field"), true);
        MonitorSensitiveField.AddMonitoredField(Database::"Test Table C", TestTableC.FieldNo("Text Field"), true);

        // [THEN] The page must display only monitored records
        MonitoredFieldsWorksheet.OpenEdit();
        AssertOnlyMonitorFieldsAreDisplayed();
    end;

    [Test]
    procedure MonitorFieldsPageChangeNotificationActions()
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        TestTableC: Record "Test Table C";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
    begin
        // [SCENARIO] Test set and clear notification actions on Monitor Fields Worksheet page 
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Inserting a record and clicking on change notification status action
        MonitorSensitiveField.AddMonitoredField(Database::"Test Table C", TestTableC.FieldNo("Integer Field"), false);
        MonitoredFieldsWorksheet.OpenEdit();

        // [THEN] Notification status will be changed
        ChangeLogSetupField.FindFirst();
        MonitoredFieldsWorksheet.GoToRecord(ChangeLogSetupField);

        MonitoredFieldsWorksheet."Set Notification".Invoke();
        Assert.IsTrue(GetMonitoredFieldNotifyValue(Database::"Test Table C", TestTableC.FieldNo("Integer Field")), '');

        MonitoredFieldsWorksheet."Clear Notification".Invoke();
        Assert.IsFalse(GetMonitoredFieldNotifyValue(Database::"Test Table C", TestTableC.FieldNo("Integer Field")), '');

        MonitoredFieldsWorksheet.Close();
    end;

    [Test]
    procedure MonitorEntriesPageUI()
    var
        TestTableC: Record "Test Table C";
        ChangeLogEntry: Record "Change Log Entry";
        MonitoredFieldLogEntries: TestPage "Monitored Field Log Entries";
        FieldLogEntryFeature: enum "Field Log Entry Feature";
    begin
        // [SCENARIO] Verify UI in Entries page
        // [GIVEN] Clean change log and monitor tables
        MonitorFieldTestHelper.InitMonitor();
        FieldLogEntryFeature := FieldLogEntryFeature::"Monitor Sensitive Fields";
        MonitorFieldTestHelper.InsertLogEntry(1, '0', '1', Database::"Test Table C", TestTableC.FieldNo("Option Field"), FieldLogEntryFeature::"Monitor Sensitive Fields");

        // [WHEN] Open Entries page
        MonitoredFieldLogEntries.OpenEdit();

        // [THEN] Check that page is not editable
        Assert.IsFalse(MonitoredFieldLogEntries.Editable(), 'Page must not be editable');
        ChangeLogEntry.SetRange("Table No.", Database::"Test Table C");
        ChangeLogEntry.SetRange("Field No.", TestTableC.FieldNo("Option Field"));
        ChangeLogEntry.FindFirst();
        MonitoredFieldLogEntries.GoToRecord(ChangeLogEntry);
        MonitoredFieldLogEntries.Close();
    end;

    [Test]
    procedure MonitorEntriesRecords()
    var
        MonitoredFieldLogEntries: TestPage "Monitored Field Log Entries";
        FieldLogEntryFeature: enum "Field Log Entry Feature";
    begin
        // [SCENARIO] Monitor entries page must only display records marked in Monitor Field Feature filed as Monitor Sensitive Data or All.
        // [GIVEN] Entries marked as: Change Log, Monitor Sensitive Field and All

        MonitorFieldTestHelper.InsertLogEntry(Random(10), FieldLogEntryFeature::"Monitor Sensitive Fields");
        MonitorFieldTestHelper.InsertLogEntry(Random(10), FieldLogEntryFeature::"Change Log");
        MonitorFieldTestHelper.InsertLogEntry(Random(10), FieldLogEntryFeature::All);

        // [THEN] Only records marked as Monitor Sensitive Fields or All should be displayed
        AssertOnlyMonitorEntriesAreDisplayed(MonitoredFieldLogEntries);
    end;

    [Test]
    procedure MonitorSetupPageUI()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        FieldMonitoringSetupPage: TestPage "Field Monitoring Setup";
    begin
        // [SCENARIO] Validate that editable fields and that setup table is initialized when opening setup page.
        // [GIVEN] Clean Entry and setup table 
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Open the setup page.
        FieldMonitoringSetupPage.OpenEdit();

        // [THEN] Check editable fields and initial value.
        Assert.IsTrue(FieldMonitoringSetupPage."User ID".Editable(), 'User Id field must be editable');
        Assert.IsFalse(FieldMonitoringSetupPage."Monitor Status".Editable(), 'Monitor status field must not be editable');
        Assert.IsFalse(FieldMonitoringSetupPage."Email Account Name".Editable(), 'Email account name field must not be editable');
        Assert.AreEqual(FieldMonitoringSetupPage."Monitor Status".Value, 'No', 'Initial monitor status must be set to false');

        FieldMonitoringSetupPage.Close();

        // [THEN] Check that setup page has been initialized.
        Assert.IsTrue(FieldMonitoringSetup.Get(), 'Setup table must be initialized after opening setup page');
    end;

    [Test]
    procedure MonitorChangesSetupPageActionsUI()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        FieldMonitoringSetupPage: TestPage "Field Monitoring Setup";
    begin
        // [SCENARIO] Validate enabled actions when monitor is enabled/disabeld
        // [GIVEN] Clean Entry and setup table 
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Open the setup page
        FieldMonitoringSetupPage.OpenEdit();

        // [THEN] Check UI when monitor is disabled
        Assert.AreEqual(FieldMonitoringSetupPage.Start.Enabled(), true, 'Enable button must be enabled when status is false');
        Assert.AreEqual(FieldMonitoringSetupPage.Stop.Enabled(), false, 'Disable button must be disabled when status is false');

        FieldMonitoringSetupPage.Close();

        // [GIVEN] Monitor is enabled
        FieldMonitoringSetup.Get();
        FieldMonitoringSetup."Monitor Status" := true;
        FieldMonitoringSetup.Modify();

        // [WHEN] Open the setup page
        FieldMonitoringSetupPage.OpenEdit();

        // [THEN] Check UI when monitor is enabled
        Assert.AreEqual(FieldMonitoringSetupPage.Start.Enabled(), false, 'Enable button must be enabled when status is false');
        Assert.AreEqual(FieldMonitoringSetupPage.Stop.Enabled(), true, 'Disable button must be disabled when status is false');
        FieldMonitoringSetupPage.Close();
    end;

    local procedure AssertOnlyMonitorEntriesAreDisplayed(var MonitoredFieldLogEntries: TestPage "Monitored Field Log Entries")
    var
        ChangeLogEntry: record "Change Log Entry";
    begin
        MonitoredFieldLogEntries.OpenEdit();

        if ChangeLogEntry.FindSet() then;
        repeat
            Assert.AreEqual(MonitoredFieldLogEntries.GoToRecord(ChangeLogEntry), ChangeLogEntry."Field Log Entry Feature" <> ChangeLogEntry."Field Log Entry Feature"::"Change Log", 'Change loge entries must not be displayed in Monitor entries page.');
        until ChangeLogEntry.Next() <> 0;

        MonitoredFieldLogEntries.Close();
    end;

    local procedure SetTableForChangeLog(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTable.Validate("Table No.", TableNo);
        ChangeLogSetupTable.Validate("Log Insertion", ChangeLogSetupTable."Log Insertion"::"All Fields");
        ChangeLogSetupTable.Validate("Log Modification", ChangeLogSetupTable."Log Modification"::"All Fields");
        ChangeLogSetupTable.Validate("Log Deletion", ChangeLogSetupTable."Log Deletion"::"All Fields");
        ChangeLogSetupTable.Insert();
    end;

    local procedure AssertOnlyMonitorFieldsAreDisplayed(): Boolean
    var
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        MonitoredFieldsWorksheet.OpenEdit();
        if ChangeLogSetupField.FindSet() then;
        repeat
            Assert.AreEqual(MonitoredFieldsWorksheet.GoToRecord(ChangeLogSetupField),
            ChangeLogSetupField."Monitor Sensitive Field" and ChangeLogSetupField."Log Insertion" and ChangeLogSetupField."Log Modification" and ChangeLogSetupField."Log Deletion", 'Only Monitor Fields must be displayed.');
        until ChangeLogSetupField.Next() <> 0;

        MonitoredFieldsWorksheet.Close();
    end;

    local procedure GetMonitoredFieldNotifyValue(TableNo: Integer; FieldNo: Integer): Boolean
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.Get(TableNo, FieldNo);
        exit(ChangeLogSetupField.Notify)
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleObjectsPage(var Objects: Page Objects; var Response: Action)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(ObjectType::Table, Database::"Test Table C");
        Objects.SetRecord(AllObjWithCaption);
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleFieldsPage(var FieldsLookUp: Page "Fields Lookup"; var Response: Action)
    var
        TestTableC: Record "Test Table C";
        FieldLookup: Record Field;
    begin
        FieldLookup.Get(Database::"Test Table C", TestTableC.FieldNo("Integer Field"));
        FieldsLookUp.SetRecord(FieldLookup);
        Response := Action::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    var
        Assert: Codeunit "Library Assert";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        MonitorFieldTestHelper: Codeunit "Monitor Field Test Helper";
        TableMonitoredInChangeLogErr: Label 'This table is monitored in Change log. If you want to monitor it here, please remove it from change log setup.', Locked = true;
        SystemTableErr: Label 'You cannot monitor fields on the specified table. For example, the table ID might not exist or it might be a system table.', Locked = true;
}