codeunit 146000 Test_DotNet_Array
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [Array]
    end;

    var
        Assert: Codeunit Assert;
        DotNet_Array: Codeunit DotNet_Array;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringArrayManipulation()
    var
        Index: Integer;
        Actual: Text;
        Expected: Text;
    begin
        // [WHEN] String array of four elements are created
        DotNet_Array.StringArray(4);
        DotNet_Array.SetTextValue('One', 0);
        DotNet_Array.SetTextValue('Two', 1);
        DotNet_Array.SetTextValue('Three', 2);
        DotNet_Array.SetTextValue('Four', 3);
        // [WHEN] And all values are concatinated
        Actual := '';
        for Index := 0 to DotNet_Array.Length() - 1 do
            Actual += DotNet_Array.GetValueAsText(Index);
        // [THEN] Array must be not null
        Assert.AreEqual(false, DotNet_Array.IsNull(), 'Null check failed');
        // [THEN] Expected array length is 4
        Assert.AreEqual(4, DotNet_Array.Length(), 'Array length check failed');
        // [THEN] First element should be 'One'
        Assert.AreEqual('One', DotNet_Array.GetValueAsText(0), 'First element check failed');
        // [THEN] Concatenated values are 'OneTwoThreeFour'
        Expected := 'OneTwoThreeFour';
        Assert.AreEqual(Expected, Actual, 'All values check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestByteArrayManipulation()
    var
        Index: Integer;
        Actual: Text;
        Expected: Text;
    begin
        // [WHEN] Byte array of four elements are created
        DotNet_Array.ByteArray(4);
        DotNet_Array.SetByteValue(1, 0);
        DotNet_Array.SetByteValue(2, 1);
        DotNet_Array.SetByteValue(3, 2);
        DotNet_Array.SetByteValue(4, 3);
        // [WHEN] And all values are concatinated
        Actual := '';
        for Index := 0 to DotNet_Array.Length() - 1 do
            Actual += Format(DotNet_Array.GetValueAsInteger(Index));
        // [THEN] Array must be not null
        Assert.AreEqual(false, DotNet_Array.IsNull(), 'Null check failed');
        // [THEN] Expected array length is 4
        Assert.AreEqual(4, DotNet_Array.Length(), 'Array length check failed');
        // [THEN] First element should be 1
        Assert.AreEqual(1, DotNet_Array.GetValueAsInteger(0), 'First element check failed');
        // [THEN] Concatenated values are '1234'
        Expected := '1234';
        Assert.AreEqual(Expected, Actual, 'All values check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInt32ArrayManipulation()
    var
        Index: Integer;
        Actual: Text;
        Expected: Text;
    begin
        // [WHEN] Int32 array of four elements are created
        DotNet_Array.Int32Array(4);
        DotNet_Array.SetByteValue(1, 0);
        DotNet_Array.SetByteValue(2, 1);
        DotNet_Array.SetByteValue(3, 2);
        DotNet_Array.SetByteValue(4, 3);
        // [WHEN] And all values are concatinated
        Actual := '';
        for Index := 0 to DotNet_Array.Length() - 1 do
            Actual += Format(DotNet_Array.GetValueAsInteger(Index));
        // [THEN] Array must be not null
        Assert.AreEqual(false, DotNet_Array.IsNull(), 'Null check failed');
        // [THEN] Expected array length is 4
        Assert.AreEqual(4, DotNet_Array.Length(), 'Array length check failed');
        // [THEN] First element should be 1
        Assert.AreEqual(1, DotNet_Array.GetValueAsInteger(0), 'First element check failed');
        // [THEN] Concatenated values are '1234'
        Expected := '1234';
        Assert.AreEqual(Expected, Actual, 'All values check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCharArrayManipulation()
    var
        Index: Integer;
        Actual: Text;
        Expected: Text;
    begin
        // [WHEN] Char array of four elements are created
        DotNet_Array.CharArray(4);
        DotNet_Array.SetByteValue('1', 0);
        DotNet_Array.SetByteValue('2', 1);
        DotNet_Array.SetByteValue('3', 2);
        DotNet_Array.SetByteValue('4', 3);
        // [WHEN] And all values are concatinated
        Actual := '';
        for Index := 0 to DotNet_Array.Length() - 1 do
            Actual += Format(DotNet_Array.GetValueAsChar(Index));
        // [THEN] Array must be not null
        Assert.AreEqual(false, DotNet_Array.IsNull(), 'Null check failed');
        // [THEN] Expected array length is 4
        Assert.AreEqual(4, DotNet_Array.Length(), 'Array length check failed');
        // [THEN] First element should be 1
        Assert.AreEqual('1', DotNet_Array.GetValueAsChar(0), 'First element check failed');
        // [THEN] Concatenated values are '1234'
        Expected := '1234';
        Assert.AreEqual(Expected, Actual, 'All values check failed');
    end;
}

