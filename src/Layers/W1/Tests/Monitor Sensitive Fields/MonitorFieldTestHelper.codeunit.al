codeunit 139067 "Monitor Field Test Helper"
{
    trigger OnRun()
    begin

    end;

    procedure InitMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogEntry: Record "Change Log Entry";
        ChangeLogSetup: Record "Change Log Setup";
    begin
        FieldMonitoringSetup.DeleteAll();
        ChangeLogSetup.DeleteAll();
        ChangeLogSetupField.DeleteAll();
        ChangeLogSetupTable.DeleteAll();
        ChangeLogEntry.DeleteAll();
    end;

    procedure AssertMonitoredFieldAddedCorrectly(TableNo: Integer; FieldNo: Integer)
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        Assert.IsTrue(ChangeLogSetupField.Get(TableNo, FieldNo), 'Can not find the correct inserted record');
        Assert.IsTrue(ChangeLogSetupField."Monitor Sensitive Field", 'Change log record must be marked as a monitor record');
        Assert.IsTrue(ChangeLogSetupTable.Get(TableNo), 'Can not find the correct inserted record');
        Assert.IsTrue(ChangeLogSetupTable."Monitor Sensitive Field", 'Change log record must be marked as a monitor record');
    end;

    procedure InsertLogEntry(Days: Integer; FieldLogEntryFeature: enum "Field Log Entry Feature")
    var
        TestTableC: Record "Test Table C";
    begin
        InsertLogEntry(Days, DummyEntryTxt, DummyEntryTxt, Database::"Test Table C", TestTableC.FieldNo("Integer Field"), FieldLogEntryFeature);
    end;

    procedure InsertLogEntry(Days: Integer; OldValue: Text; NewValue: Text; TableNo: Integer; FieldNo: Integer; FieldLogEntryFeature: enum "Field Log Entry Feature")
    var
        ChangeLogEntry: record "Change Log Entry";
    begin
        ChangeLogEntry.Validate("Table No.", TableNo);
        ChangeLogEntry.Validate("Field No.", FieldNo);
        ChangeLogEntry."User ID" := '';
        ChangeLogEntry.Validate("Old Value", OldValue);
        ChangeLogEntry.Validate("New Value", NewValue);
        ChangeLogEntry.Validate("Changed Record SystemId", CreateGuid());
        ChangeLogEntry.Validate("Date and Time", CreateDateTime(Today - Days, 000000T));
        ChangeLogEntry.Validate("Field Log Entry Feature", FieldLogEntryFeature);
        ChangeLogEntry.Insert(false);
    end;

    procedure EntryExists(TableNo: Integer; FieldNo: Integer; OriginalValue: Text; NewValue: Text): Boolean
    var
        ChangeLogEntry: record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", TableNo);
        ChangeLogEntry.SetRange("Field No.", FieldNo);
        if OriginalValue <> '' then
            ChangeLogEntry.SetRange("Old Value", OriginalValue);
        if NewValue <> '' then
            ChangeLogEntry.SetRange("New Value", NewValue);

        if not ChangeLogEntry.IsEmpty() then
            exit(true);
    end;

    var
        Assert: Codeunit "Library Assert";
        DummyEntryTxt: Label 'Dummy Entry';
}