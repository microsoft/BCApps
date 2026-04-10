codeunit 132555 "Lib Text File Valid. UnitTest"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Text File Validation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        WrongFieldValueErr: Label 'Wrong field value.';
        NoSuchFieldPositionErr: Label 'There is no field position %1 in the line.';

    [Test]
    [Scope('OnPrem')]
    procedure UTRead1stFieldInEmptyLine()
    begin
        Assert.AreEqual('', LibraryTextFileValidation.ReadField('', 1, '^'), WrongFieldValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRead1stFieldIn1FieldLine()
    begin
        Assert.AreEqual('XXX', LibraryTextFileValidation.ReadField('XXX', 1, '^'), WrongFieldValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRead1stFieldIn2FieldsLine()
    begin
        Assert.AreEqual('XXX', LibraryTextFileValidation.ReadField('XXX^YYY', 1, '^'), WrongFieldValueErr);
        Assert.AreEqual('', LibraryTextFileValidation.ReadField('^YYY', 1, '^'), WrongFieldValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRead2ndFieldIn2FieldsLine()
    begin
        Assert.AreEqual('YYY', LibraryTextFileValidation.ReadField('XXX^YYY', 2, '^'), WrongFieldValueErr);
        Assert.AreEqual('', LibraryTextFileValidation.ReadField('XXX^', 2, '^'), WrongFieldValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRead2ndFieldIn3FieldsLine()
    begin
        Assert.AreEqual('YYY', LibraryTextFileValidation.ReadField('XXX^YYY^ZZZ', 2, '^'), WrongFieldValueErr);
        Assert.AreEqual('', LibraryTextFileValidation.ReadField('XXX^^ZZZ', 2, '^'), WrongFieldValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRead3rdFieldIn2FieldsLine()
    begin
        asserterror LibraryTextFileValidation.ReadField('XXX^YYY', 3, '^');
        Assert.ExpectedError(StrSubstNo(NoSuchFieldPositionErr, 3));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReadZeroFieldInEmptyLine()
    begin
        asserterror LibraryTextFileValidation.ReadField('', 0, '^');
        Assert.ExpectedError(StrSubstNo(NoSuchFieldPositionErr, 0));
    end;
}

