codeunit 136620 "Table Field ObsoleteState"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ObsoleteState]
    end;

    var
        Assert: Codeunit Assert;
        FieldObsoleteErr: Label 'Field Obsolete Field Removed (2) of table Table With Removed Field (136603) is obsoleted';

    [Test]
    [Scope('OnPrem')]
    procedure T100_GetKeyAsStringForPendingFieldInKey()
    var
        TableWithRemovedField: Record "Table With Removed Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        // [SCENARIO] Pending field is shown as part of the key
        Assert.AreEqual(
              'Obsolete Field Pending,' + TableWithRemovedField.FieldCaption("Normal Field"),
              TypeHelper.GetKeyAsString(TableWithRemovedField, 3), 'key with Obsolete Pending field');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_GetKeyAsStringForPendingKey()
    var
        TableWithRemovedField: Record "Table With Removed Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        // [SCENARIO] Pending key is accesible
        Assert.AreEqual(
              'Obsolete Field Pending,' + TableWithRemovedField.FieldCaption(Key),
              TypeHelper.GetKeyAsString(TableWithRemovedField, 2), 'key with Obsolete = Pending');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_RemovedFieldIsSkippedByFldRefCOUNT()
    var
        TableWithRemovedField: Record "Table With Removed Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(TableWithRemovedField);
        Assert.AreEqual(3, RecRef.FieldCount, 'Removed field should be skipped');
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            Assert.AreNotEqual(2, FieldRef.Number, 'Obsolete Field Removed should not be in the loop');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_RemovedFieldSkippedByFIELDEXIST()
    var
        TableWithRemovedField: Record "Table With Removed Field";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TableWithRemovedField);
        Assert.IsFalse(
          RecRef.FieldExist(2), 'FIELDEXIST Obsolete Field Removed');
        RecRef.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T122_RemovedFieldFailsOnRecRefFIELD()
    var
        TableWithRemovedField: Record "Table With Removed Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(TableWithRemovedField);
        asserterror FieldRef := RecRef.Field(2);
        Assert.ExpectedError(FieldObsoleteErr);
        RecRef.Close();
    end;
}

