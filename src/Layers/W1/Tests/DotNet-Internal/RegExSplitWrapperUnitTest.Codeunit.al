codeunit 132596 "RegEx Split Wrapper Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [Array] [RegEx Split]
    end;

    var
        Assert: Codeunit Assert;
        RegExSplitWrapper: Codeunit "RegEx Split Wrapper";
        ArrayIsEmptyErr: Label 'No split string has been supplied.';
        IndexOutOfBoundsErr: Label 'Index out of bounds.';

    [Test]
    [Scope('OnPrem')]
    procedure GetEmptyLength()
    begin
        // [WHEN] GetLength is called on an empty array
        // [THEN] An error is returned
        asserterror RegExSplitWrapper.GetLength();
        Assert.ExpectedError(ArrayIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmptyIndex()
    begin
        // [WHEN] GetIndex is called on an empty array
        // [THEN] An error is returned
        asserterror RegExSplitWrapper.GetIndex(7);
        Assert.ExpectedError(ArrayIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLowerBoundaryError()
    begin
        // [GIVEN] A string which is split
        RegExSplitWrapper.Split('1;2;3;4;5;6', ';');
        // [WHEN] GetIndex is called outside of bounds
        // [THEN] An error is returned
        asserterror RegExSplitWrapper.GetIndex(-10);
        Assert.ExpectedError(IndexOutOfBoundsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetUpperBoundaryError()
    begin
        // [GIVEN] A string which is split
        RegExSplitWrapper.Split('1;2;3;4;5;6', ';');
        // [WHEN] GetIndex is called outside of bounds
        // [THEN] An error is returned
        asserterror RegExSplitWrapper.GetIndex(10);
        Assert.ExpectedError(IndexOutOfBoundsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLength()
    begin
        // [GIVEN] A string which is split
        RegExSplitWrapper.Split('1;2;3;4;5;6', ';');
        // [WHEN] GetLength is called
        // [THEN] The correct length of that sting is returend
        Assert.AreEqual(6, RegExSplitWrapper.GetLength(), 'Wrong length of string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillArrayAndTestValues()
    begin
        // [GIVEN] A string which is split
        RegExSplitWrapper.Split('1;2;3;4;5;6', ';');
        // [WHEN] GetIndex is called
        // [THEN] The correct value is returned
        Assert.AreEqual('1', RegExSplitWrapper.GetIndex(0), 'Wrong value');
        Assert.AreEqual('2', RegExSplitWrapper.GetIndex(1), 'Wrong value');
        Assert.AreEqual('3', RegExSplitWrapper.GetIndex(2), 'Wrong value');
        Assert.AreEqual('4', RegExSplitWrapper.GetIndex(3), 'Wrong value');
        Assert.AreEqual('5', RegExSplitWrapper.GetIndex(4), 'Wrong value');
        Assert.AreEqual('6', RegExSplitWrapper.GetIndex(5), 'Wrong value');
        // [WHEN] GetIndex is called on a non-existing index
        // [THEN] A error is thrown
        asserterror RegExSplitWrapper.GetIndex(6);
        Assert.ExpectedError(IndexOutOfBoundsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyParameters()
    begin
        // [GIVEN] An empty string which is split
        RegExSplitWrapper.Split('', ';');
        // [WHEN] GetLength is called
        // [THEN] The array only contains one element
        Assert.AreEqual(1, RegExSplitWrapper.GetLength(), 'Array should only contain 1 element.');
    end;
}

