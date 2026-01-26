codeunit 142005 "ERM Data Exp. Rec. Field"
{
    // Unit tests for the procedures in TAB11005

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        DataExportRecordField: Record "Data Export Record Field";
        Assert: Codeunit Assert;
        ExportCode: Code[10];
        RecordCode: Code[10];
        TableNo: Integer;
        SourceLineNo: Integer;
        NewLineNo: Integer;
        isInitialized: Boolean;
        FieldNoNotAsExpectedText: Label 'The field number is not as expected.';
        MoveUpShouldNotDoAnythingText: Label 'Move up of the top record should not do anything.';
        MoveUpDidnotWork: Label 'Move up of the last record didnot work.';
        MoveDownDidnotWork: Label 'Move down of the top record didnot work.';
        MoveDownShouldNotDoAnything: Label 'Move down of the last record should not do anything.';

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldTypeClass()
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.Init();
        DataExportRecordField."Table No." := DATABASE::"Data Export Record Source";
        DataExportRecordField.Validate("Field No.", 10);
        // Field 10 is "Period Field Name" FlowField Text in Tab11004
        Assert.AreEqual(
          DataExportRecordField."Field Class"::FlowField,
          DataExportRecordField."Field Class", Format(DATABASE::"Data Export Record Source"));
        Assert.AreEqual(
          DataExportRecordField."Field Type"::Text,
          DataExportRecordField."Field Type", Format(DATABASE::"Data Export Record Source"));

        // Field 10 is "Field Type" Normal Option in Tab11005
        DataExportRecordField.Validate("Table No.", DATABASE::"Data Export Record Field");
        Assert.AreEqual(
          DataExportRecordField."Field Class"::Normal,
          DataExportRecordField."Field Class", Format(DATABASE::"Data Export Record Field"));
        Assert.AreEqual(
          DataExportRecordField."Field Type"::Option,
          DataExportRecordField."Field Type", Format(DATABASE::"Data Export Record Field"));

        // Class and Type are zeros for unknown field
        DataExportRecordField.Validate("Table No.", 0);
        Assert.AreEqual(0, DataExportRecordField."Field Class", '');
        Assert.AreEqual(0, DataExportRecordField."Field Type", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveUpFirstRecord()
    begin
        Initialize();
        InitializeTestData();

        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        NewLineNo := DataExportRecordField.MoveRecordUp(DataExportRecordField);

        Assert.AreEqual(-1, NewLineNo, MoveUpShouldNotDoAnythingText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveUpLastRecord()
    begin
        Initialize();
        InitializeTestData();

        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        NewLineNo := DataExportRecordField.MoveRecordUp(DataExportRecordField);
        Assert.AreEqual(1000, NewLineNo, MoveUpDidnotWork);

        // Expected:
        // 1000 -> field 2
        // 2000 -> field 1
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, NewLineNo);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDownLastRecord()
    begin
        Initialize();

        InitializeTestData();
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);

        NewLineNo := DataExportRecordField.MoveRecordDown(DataExportRecordField);
        Assert.AreEqual(-1, NewLineNo, MoveDownShouldNotDoAnything);

        // Expected:
        // 1000 -> field 1
        // 2000 -> field 2
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDownFirstRecord()
    begin
        Initialize();
        InitializeTestData();

        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        NewLineNo := DataExportRecordField.MoveRecordDown(DataExportRecordField);
        Assert.AreEqual(2000, NewLineNo, MoveDownDidnotWork);

        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, NewLineNo);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAfterFirst()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        Fields.SetRange(TableNo, TableNo);
        Fields.SetFilter("No.", '3|4');
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 1000);

        // Expected:
        // 1000 -> field 1
        // 2000 -> field 3
        // 3000 -> field 4
        // 4000 -> field 2
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(3, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 3000);
        Assert.AreEqual(4, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 4000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAfterLast()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        Fields.SetRange(TableNo, TableNo);
        Fields.SetFilter("No.", '3|4');

        // Expected:
        // 1000 -> field 1
        // 2000 -> field 2
        // 3000 -> field 3
        // 4000 -> field 4
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 2000);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 3000);
        Assert.AreEqual(3, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 4000);
        Assert.AreEqual(4, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertDuplicateNormalField()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        Fields.SetRange(TableNo, TableNo);
        Fields.SetFilter("No.", '1');
        asserterror DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 1000);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertDuplicateFlowField()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        Fields.SetRange(TableNo, TableNo);
        Fields.SetRange("No.", GetFlowFieldNoFromTestData());
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 1000);
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 1000);

        // EXPECTED:
        // Line 1000 -> 1
        // Line 2000 -> FlowFieldNo
        // Line 3000 -> FlowFieldNo
        // Line 4000 -> 2
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(GetFlowFieldNoFromTestData(), DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 3000);
        Assert.AreEqual(GetFlowFieldNoFromTestData(), DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 4000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertOnEmpty()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        DeleteTestData();
        Fields.SetRange(TableNo, TableNo);
        Fields.SetFilter("No.", '1|2');
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 0);

        // EXPECTED:
        // Line 1000 -> 1
        // Line 2000 -> 2
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(2, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindUnusedNumberTest()
    var
        "Fields": Record "Field";
    begin
        Initialize();
        InitializeTestData();

        InsertTestRecord(-9999, 3);
        Fields.SetRange(TableNo, TableNo);
        Fields.SetFilter("No.", '4');
        DataExportRecordField.InsertSelectedFields(Fields, ExportCode, RecordCode, SourceLineNo, 1000);

        // EXPECTED:
        // Line 1000 -> 1
        // Line 2000 -> 4
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 1000);
        Assert.AreEqual(1, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);
        DataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, 2000);
        Assert.AreEqual(4, DataExportRecordField."Field No.", FieldNoNotAsExpectedText);

        TearDown();
    end;

    [Normal]
    local procedure TearDown()
    begin
    end;

    [Normal]
    local procedure InitializeTestData()
    begin
        // Delete the testdata and insert two records.
        ExportCode := 'TestCode';
        RecordCode := 'UnitTstRec';
        TableNo := GetTestDataTableNo();
        SourceLineNo := 10000;
        DeleteTestData();

        InsertTestRecord(1000, 1);
        InsertTestRecord(2000, 2);
    end;

    [Normal]
    local procedure DeleteTestData()
    begin
        DataExportRecordField.SetRange("Data Export Code", ExportCode);
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordField.SetRange("Table No.", TableNo);
        DataExportRecordField.DeleteAll();
    end;

    [Normal]
    local procedure GetFlowFieldNoFromTestData(): Integer
    var
        RecRef: RecordRef;
    begin
        // Field 58 'Balance' of Table 'Customer' is a FlowField, and will be used as test data.
        RecRef.Open(GetTestDataTableNo());
        if not (RecRef.Field(58).Class = FieldClass::FlowField) then
            Error('The testdata is wrong. FlowField is needed for the testcase.');
        exit(58);
    end;

    [Normal]
    local procedure GetTestDataTableNo(): Integer
    begin
        // Table 18 will be used as testdata
        exit(DATABASE::Customer);
    end;

    [Normal]
    local procedure InsertTestRecord(LineNo: Integer; FieldNo: Integer)
    begin
        DataExportRecordField.Init();
        DataExportRecordField."Data Export Code" := ExportCode;
        DataExportRecordField."Data Exp. Rec. Type Code" := RecordCode;
        DataExportRecordField."Table No." := TableNo;
        DataExportRecordField.Validate("Field No.", FieldNo);
        DataExportRecordField."Line No." := LineNo;
        DataExportRecordField."Source Line No." := 10000;
        DataExportRecordField.Insert();
    end;
}

