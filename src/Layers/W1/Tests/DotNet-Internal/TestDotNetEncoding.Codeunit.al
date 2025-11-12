codeunit 146026 Test_DotNet_Encoding
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [Encoding]
    end;

    var
        Assert: Codeunit Assert;
        DotNet_Encoding: Codeunit DotNet_Encoding;
        DotNet_String: Codeunit DotNet_String;
        DotNet_ArrayByte: Codeunit DotNet_Array;
        DotNet_ArrayChar: Codeunit DotNet_Array;

    [Test]
    [Scope('OnPrem')]
    procedure TestEncodingGetCharsMethod()
    var
        ExpectedChar: Char;
    begin
        // [Given] A byte array of raw utf-8 encoded data
        DotNet_ArrayByte.ByteArray(5);
        DotNet_ArrayByte.SetByteValue(196, 0);
        DotNet_ArrayByte.SetByteValue(133, 1);
        DotNet_ArrayByte.SetByteValue(196, 2);
        DotNet_ArrayByte.SetByteValue(141, 3);
        DotNet_ArrayByte.SetByteValue(100, 4);
        // [WHEN] byte array is converted to char array using UTF-8 encoding
        DotNet_Encoding.UTF8();
        DotNet_Encoding.GetChars(DotNet_ArrayByte, 0, DotNet_ArrayByte.Length(), DotNet_ArrayChar);
        // [THEN] Byte array must not be null
        Assert.AreEqual(false, DotNet_ArrayByte.IsNull(), 'Byte array check not null failed');
        // [THEN] Byte array length must be 5
        Assert.AreEqual(5, DotNet_ArrayByte.Length(), 'Byte array length check failed');
        // [THEN] First element of byte array must be 196
        Assert.AreEqual(196, DotNet_ArrayByte.GetValueAsInteger(0), 'Byte array first element check failed');
        // [THEN] Char array must not be null
        Assert.AreEqual(false, DotNet_ArrayChar.IsNull(), 'Char array check not null failed');
        // [THEN] Char array length must be 3
        Assert.AreEqual(3, DotNet_ArrayChar.Length(), 'Char array length check failed');
        // [THEN] First element of char array must be character with code 261
        ExpectedChar := 261;
        Assert.AreEqual(ExpectedChar, DotNet_ArrayChar.GetValueAsChar(0), 'Char array first element check failed');
        // [WHEN] char array is converted to string
        DotNet_String.FromCharArray(DotNet_ArrayChar);
        // [THEN] string must be not null
        Assert.AreEqual(false, DotNet_String.IsDotNetNull(), 'String check not null failed');
        // [THEN] string length must be 3
        Assert.AreEqual(3, DotNet_String.Length(), 'String length check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEncodingGetBytesMethod()
    var
        ExpectedChar: Char;
    begin
        // [Given] A char array with non-ansi characters
        DotNet_ArrayChar.CharArray(2);
        DotNet_ArrayChar.SetCharValue(261, 0);
        DotNet_ArrayChar.SetCharValue(100, 1);
        // [WHEN] char array is converted to byte array using UTF-8 encoding
        DotNet_Encoding.UTF8();
        DotNet_Encoding.GetBytes(DotNet_ArrayChar, 0, DotNet_ArrayChar.Length(), DotNet_ArrayByte);
        // [THEN] Char array must not be null
        Assert.AreEqual(false, DotNet_ArrayChar.IsNull(), 'Char array check not null failed');
        // [THEN] Char array length must be 2
        Assert.AreEqual(2, DotNet_ArrayChar.Length(), 'Char array length check failed');
        // [THEN] First element of char array must be character of code 261
        ExpectedChar := 261;
        Assert.AreEqual(ExpectedChar, DotNet_ArrayChar.GetValueAsChar(0), 'Char array first element check failed');
        // [THEN] Byte array must not be null
        Assert.AreEqual(false, DotNet_ArrayByte.IsNull(), 'Byte array check not null failed');
        // [THEN] Byte array length must be 3
        Assert.AreEqual(3, DotNet_ArrayByte.Length(), 'Byte array length check failed');
        // [THEN] First element of byte array must be 196
        Assert.AreEqual(196, DotNet_ArrayByte.GetValueAsInteger(0), 'Byte array first element check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEncodingGetBytesWithOffsetMethod()
    var
        ExpectedChar: Char;
    begin
        // [Given] A char array with non-ansi characters
        DotNet_ArrayChar.CharArray(2);
        DotNet_ArrayChar.SetCharValue(261, 0);
        DotNet_ArrayChar.SetCharValue(100, 1);
        // [Given] And a byte array of 5 elements filled with value 1
        DotNet_ArrayByte.ByteArray(5);
        DotNet_ArrayByte.SetByteValue(1, 0);
        DotNet_ArrayByte.SetByteValue(1, 1);
        DotNet_ArrayByte.SetByteValue(1, 2);
        DotNet_ArrayByte.SetByteValue(1, 3);
        DotNet_ArrayByte.SetByteValue(1, 4);
        // [WHEN] char array is converted to byte array using UTF-8 encoding
        DotNet_Encoding.UTF8();
        DotNet_Encoding.GetBytesWithOffset(DotNet_ArrayChar, 0, DotNet_ArrayChar.Length(), DotNet_ArrayByte, 2);
        // [THEN] Char array must not be null
        Assert.AreEqual(false, DotNet_ArrayChar.IsNull(), 'Char array check not null failed');
        // [THEN] Char array length must be 2
        Assert.AreEqual(2, DotNet_ArrayChar.Length(), 'Char array length check failed');
        // [THEN] First element of char array must be character of code 261
        ExpectedChar := 261;
        Assert.AreEqual(ExpectedChar, DotNet_ArrayChar.GetValueAsChar(0), 'Char array first element check failed');
        // [THEN] Byte array must not be null
        Assert.AreEqual(false, DotNet_ArrayByte.IsNull(), 'Byte array check not null failed');
        // [THEN] Byte array length must be 3
        Assert.AreEqual(5, DotNet_ArrayByte.Length(), 'Byte array length check failed');
        // [THEN] First element must be unchanged and third element of byte array must be 196
        Assert.AreEqual(1, DotNet_ArrayByte.GetValueAsInteger(0), 'Byte array first element check failed');
        Assert.AreEqual(196, DotNet_ArrayByte.GetValueAsInteger(2), 'Byte array third element check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEncodingGetStringMethod()
    begin
        // [Given] A byte array of raw utf-8 encoded data
        DotNet_ArrayByte.ByteArray(5);
        DotNet_ArrayByte.SetByteValue(196, 0);
        DotNet_ArrayByte.SetByteValue(133, 1);
        DotNet_ArrayByte.SetByteValue(196, 2);
        DotNet_ArrayByte.SetByteValue(141, 3);
        DotNet_ArrayByte.SetByteValue(100, 4);
        // [WHEN] byte array is converted to string using UTF-8 encoding
        DotNet_Encoding.UTF8();
        DotNet_Encoding.GetString(DotNet_ArrayByte, 0, DotNet_ArrayByte.Length());
        // [THEN] string must be not null
        Assert.AreEqual(false, DotNet_String.IsDotNetNull(), 'String check not null failed');
        // [THEN] string length must be 3
        Assert.AreEqual(3, DotNet_String.Length(), 'String length check failed');
    end;
}

