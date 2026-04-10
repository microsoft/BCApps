codeunit 131923 "Library - Tables UT"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;

    procedure CompareFieldTypeAndLength(Table1: Variant; Field1: Integer; Table2: Variant; Field2: Integer)
    var
        RecordRef1: RecordRef;
        RecordRef2: RecordRef;
        FieldRef1: FieldRef;
        FieldRef2: FieldRef;
    begin
        RecordRef1.GetTable(Table1);
        RecordRef2.GetTable(Table2);
        FieldRef1 := RecordRef1.Field(Field1);
        FieldRef2 := RecordRef2.Field(Field2);
        Assert.IsTrue(FieldRef1.Type = FieldRef2.Type, 'Fields Type mismatch');
        Assert.AreEqual(FieldRef1.Length, FieldRef2.Length, 'Fields Length mismatch');
    end;

    [Scope('OnPrem')]
    procedure FindField(var "Field": Record "Field"; RecVar: Variant; FieldNoFind: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetRange("No.", FieldNoFind);
        Field.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure AssertTableRelation(var "Field": Record "Field"; TableNoRelation: Integer; FieldNoRelation: Integer)
    begin
        Field.TestField(RelationTableNo, TableNoRelation);
        Field.TestField(RelationFieldNo, FieldNoRelation);
    end;
}

