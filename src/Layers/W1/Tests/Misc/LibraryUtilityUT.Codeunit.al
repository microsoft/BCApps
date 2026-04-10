codeunit 132552 "Library - Utility UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        FieldOptionTypeErr: Label 'Field %1 in Table %2 must be option type.', Comment = '%1 - Field Name, %2 - Table Name';

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxOptionIndexWithFromSingleOption()
    begin
        // [SCENARIO] "Library - Utility".GetMaxOptionIndex('Option1') returns 0
        Assert.AreEqual(0, LibraryUtility.GetMaxOptionIndex('Option1'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxOptionIndexWithFromTwoOptions()
    begin
        // [SCENARIO] "Library - Utility".GetMaxOptionIndex('Option1,Option2') returns 1
        Assert.AreEqual(1, LibraryUtility.GetMaxOptionIndex('Option1,Option2'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxFieldOptionIndexWithOptionField()
    begin
        // [SCENARIO] "Library - Utility".GetMaxFieldOptionIndex(4,12) returns 2
        Assert.AreEqual(2, LibraryUtility.GetMaxFieldOptionIndex(4, 12), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxFieldOptionIndexWithNonOptionField()
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // [SCENARIO] "Library - Utility".GetMaxFieldOptionIndex(4,15) returns error
        RecRef.Open(4);
        FieldRef := RecRef.Field(15);
        asserterror LibraryUtility.GetMaxFieldOptionIndex(4, 15);
        Assert.ExpectedError(StrSubstNo(FieldOptionTypeErr, FieldRef.Name, RecRef.Name));
    end;
}

