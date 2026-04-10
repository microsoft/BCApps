codeunit 134567 "Test Database Access Intent"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = TableData "Object Access Intent Override" = rimd;

    trigger OnRun()
    begin
        // TEST of page "Database Access Intent List" which modifies the system table "Database Access Intent"    
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenList()
    var
        DatabaseAccessIntentList: TestPage "Database Access Intent List";
    begin
        LibraryLowerPermissions.SetO365BusFull();
        DatabaseAccessIntentList.OpenView();
        DatabaseAccessIntentList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMarkAsReadOnly()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectAccessIntentOverride: Record "Object Access Intent Override";
        DatabaseAccessIntentList: TestPage "Database Access Intent List";
    begin
        // Open page and position on Report 4 Detail Trial Balance
        // Given: "Object Access Intent Override" for report 4 does not exist
        if ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance") then
            ObjectAccessIntentOverride.Delete();
        LibraryLowerPermissions.SetO365BusFull();
        AllObjWithCaption.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance");
        DatabaseAccessIntentList.OpenEdit();
        DatabaseAccessIntentList.GoToRecord(AllObjWithCaption);

        // Verify that current status is 'Default'
        Assert.AreEqual('Default', format(DatabaseAccessIntentList.AccessIntent), 'Wrong status shown');

        // Set value to "Read Only"
        DatabaseAccessIntentList.AccessIntent.SetValue('Read Only');
        DatabaseAccessIntentList.Close();

        // Verify that 'report 4' exists in the database access intent table
        ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance");
        Assert.AreEqual(ObjectAccessIntentOverride."Access Intent"::ReadOnly, ObjectAccessIntentOverride."Access Intent", 'Wrong value saved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMarkAsReadWrite()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectAccessIntentOverride: Record "Object Access Intent Override";
        DatabaseAccessIntentList: TestPage "Database Access Intent List";
    begin
        // Open page and position on Report 4 Detail Trial Balance
        // Given: "Object Access Intent Override" for report 4 does not exist
        if ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance") then
            ObjectAccessIntentOverride.Delete();
        LibraryLowerPermissions.SetO365BusFull();
        AllObjWithCaption.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance");
        DatabaseAccessIntentList.OpenEdit();
        DatabaseAccessIntentList.GoToRecord(AllObjWithCaption);

        // Set value to "Read Only"
        DatabaseAccessIntentList.AccessIntent.SetValue('Allow Write');
        DatabaseAccessIntentList.Close();

        // Verify that 'report 4' exists in the database access intent table
        ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance");
        Assert.AreEqual(ObjectAccessIntentOverride."Access Intent"::ReadWrite, ObjectAccessIntentOverride."Access Intent", 'Wrong value saved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenWithValueAndResetValue()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectAccessIntentOverride: Record "Object Access Intent Override";
        DatabaseAccessIntentList: TestPage "Database Access Intent List";
    begin
        // Open page and position on Report 4 Detail Trial Balance
        // Given: "Object Access Intent Override" for report 4 does exist
        if ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance") then
            ObjectAccessIntentOverride.Delete();
        ObjectAccessIntentOverride.Init();
        ObjectAccessIntentOverride."Object Type" := ObjectAccessIntentOverride."Object Type"::Report;
        ObjectAccessIntentOverride."Object ID" := Report::"Detail Trial Balance";
        ObjectAccessIntentOverride."Access Intent" := ObjectAccessIntentOverride."Access Intent"::ReadOnly;
        ObjectAccessIntentOverride.Insert();
        LibraryLowerPermissions.SetO365BusFull();
        AllObjWithCaption.Get(ObjectAccessIntentOverride."Object Type"::Report, report::"Detail Trial Balance");
        DatabaseAccessIntentList.OpenEdit();
        DatabaseAccessIntentList.GoToRecord(AllObjWithCaption);

        Assert.AreEqual('Read Only', format(DatabaseAccessIntentList.AccessIntent), 'Wrong status shown');

        // Set value to "Default"
        DatabaseAccessIntentList.AccessIntent.SetValue('Default');
        DatabaseAccessIntentList.Close();

        // Verify that 'report 4' exists in the database access intent table
        assert.AreEqual(false, ObjectAccessIntentOverride.Get(ObjectAccessIntentOverride."Object Type"::Report, Report::"Detail Trial Balance"), 'Record should not exist');
    end;
}