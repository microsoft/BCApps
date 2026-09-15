codeunit 146007 Test_DotNet_String
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [String]
    end;

    var
        Assert: Codeunit Assert;
        NotNormalizedStringErr: Label 'The string is expected to be normalized.';

    [Test]
    [Scope('OnPrem')]
    procedure TestDotNetStringSplit()
    var
        DotNet_String: Codeunit DotNet_String;
        DotNet_ArraySplit: Codeunit DotNet_Array;
        DotNet_ArrayResult: Codeunit DotNet_Array;
        SplitChar: Char;
        TestValue: array[4] of Text;
    begin
        // [SCENARIO] Split a string

        // [GIVEN] A split char in an array
        SplitChar := 9;
        DotNet_String.Set(Format(SplitChar));
        DotNet_String.ToCharArray(0, 1, DotNet_ArraySplit);

        // [GIVEN] Some strings
        TestValue[1] := 'This is the first value';
        TestValue[2] := 'This is the second value';
        TestValue[3] := PadStr('This is a long value', 1000, 'A');
        TestValue[3] := PadStr('This is a longer value', 5000, 'B');

        DotNet_String.Set(
          TestValue[1] + Format(SplitChar) +
          TestValue[2] + Format(SplitChar) +
          TestValue[3] + Format(SplitChar) +
          TestValue[4]);

        // [WHEN] The Split method is called
        DotNet_String.Split(DotNet_ArraySplit, DotNet_ArrayResult);

        // [THEN] The String is split
        Assert.AreEqual(TestValue[1], DotNet_ArrayResult.GetValueAsText(0), 'Incorrect result value from split');
        Assert.AreEqual(TestValue[2], DotNet_ArrayResult.GetValueAsText(1), 'Incorrect result value from split');
        Assert.AreEqual(TestValue[3], DotNet_ArrayResult.GetValueAsText(2), 'Incorrect result value from split');
        Assert.AreEqual(TestValue[4], DotNet_ArrayResult.GetValueAsText(3), 'Incorrect result value from split');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDotNetStringEndsWith()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [SCENARIO] Verify the end of a string

        // [GIVEN] A default string
        DotNet_String.Set('The quick brown fox jumped over the lazy dog');

        // [THEN] The end should be 'dog'
        Assert.IsTrue(DotNet_String.EndsWith('dog'), 'Incorrect result value from EndsWith');
        Assert.IsFalse(DotNet_String.EndsWith('fox'), 'Incorrect result value from EndsWith');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDotNetStringBeginsWith()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [SCENARIO] Verify the start of a string

        // [GIVEN] A default string
        DotNet_String.Set('The quick brown fox jumped over the lazy dog');

        // [THEN] The start should be 'The'
        Assert.IsTrue(DotNet_String.StartsWith('The'), 'Incorrect result value from StartsWith');
        Assert.IsFalse(DotNet_String.StartsWith('dog'), 'Incorrect result value from StartsWith');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringLengthMethod()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] an empty string
        DotNet_String.Set('');
        // [THEN] string length should be 0
        Assert.AreEqual(0, DotNet_String.Length(), 'String length check failed');
        // [Given] a string 'Test'
        DotNet_String.Set('Test');
        // [THEN] string length should be 4
        Assert.AreEqual(4, DotNet_String.Length(), 'String length check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringPadMethods()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] a string 'T'
        DotNet_String.Set('T');
        // [WHEN] when we pad it right with spaces by 10 characters
        // [THEN] string actual value must be 'T         '
        Assert.AreEqual('T         ', DotNet_String.PadRight(10, ' '), 'String value check failed');
        // [WHEN] when we pad it right with spaces by 10 characters
        // [THEN] string actual value must be '          T'
        Assert.AreEqual('         T', DotNet_String.PadLeft(10, ' '), 'String value check failed');
        // [WHEN] when we pad it left and right with spaces by 10 characters
        // [THEN] string actual value must be '          T          '
        DotNet_String.Set(DotNet_String.PadLeft(10, ' '));
        DotNet_String.Set(DotNet_String.PadRight(20, ' '));
        Assert.AreEqual('         T          ', DotNet_String.ToString(), 'String value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringTrimMethods()
    var
        DotNet_ArrayChar: Codeunit DotNet_Array;
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] a string ' ,T,'
        DotNet_String.Set(' ,T,');
        // [WHEN] when we trim it
        // [THEN] string actual value must be ',T,'
        Assert.AreEqual(',T,', DotNet_String.Trim(), 'String value check failed');
        DotNet_ArrayChar.CharArray(2);
        DotNet_ArrayChar.SetCharValue(',', 0);
        DotNet_ArrayChar.SetCharValue(' ', 1);
        // [WHEN] when we trim it from left with trim char ','
        // [THEN] string actual value must be 'T,'
        Assert.AreEqual('T,', DotNet_String.TrimStart(DotNet_ArrayChar), 'String value check failed');
        // [WHEN] when we trim it from right with trim char ','
        // [THEN] string actual value must be 'T'
        Assert.AreEqual(' ,T', DotNet_String.TrimEnd(DotNet_ArrayChar), 'String value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringSubstringMethod()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] a string 'ABCD'
        DotNet_String.Set('ABCD');
        // [WHEN] when we trim it;
        // [THEN] string actual value must be 'BC'
        Assert.AreEqual('BC', DotNet_String.Substring(1, 2), 'String value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringIndexOfMethods()
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] a string 'ABCDBC'
        DotNet_String.Set('ABCDBC');
        // [THEN] first index of char 'B' must be 1
        Assert.AreEqual(1, DotNet_String.IndexOfChar('B', 0), 'Index of check failed');
        // [THEN] second index of char 'B' must be 4
        Assert.AreEqual(4, DotNet_String.IndexOfChar('B', 2), 'Index of check failed');
        // [THEN] first index of string 'BC' must be 1
        Assert.AreEqual(1, DotNet_String.IndexOfString('BC', 0), 'Index of check failed');
        // [THEN] second index of string 'BC' must be 4
        Assert.AreEqual(4, DotNet_String.IndexOfString('BC', 2), 'Index of check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringFromCharArrayMethod()
    var
        DotNet_ArrayChar: Codeunit DotNet_Array;
        DotNet_String: Codeunit DotNet_String;
    begin
        // [Given] a string 'ABCDBC'
        DotNet_String.Set('ABCDBC');
        // [WHEN] we convert it to char array and convert back
        DotNet_String.ToCharArray(0, DotNet_String.Length(), DotNet_ArrayChar);
        Clear(DotNet_String);
        DotNet_String.FromCharArray(DotNet_ArrayChar);
        // [THEN] length of string must be 6
        Assert.AreEqual(6, DotNet_String.Length(), 'String length check failed');
        // [THEN] value of string must be 'ABCDBC'
        Assert.AreEqual('ABCDBC', DotNet_String.ToString(), 'String value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStringNormalize()
    var
        DotNet_String: Codeunit DotNet_String;
        DotNet_StringNormalized: Codeunit DotNet_String;
        DotNet_NormalizationForm: Codeunit DotNet_NormalizationForm;
    begin
        // [Given] Text with a cedilla and a fraction
        DotNet_String.Set('ca̧⅓');

        // [WHEN] the string is normalized to form C
        DotNet_NormalizationForm.FormC();
        DotNet_StringNormalized.Set(DotNet_String.Normalize(DotNet_NormalizationForm));
        // [THEN] value of the string corresponds to normalized form C
        Assert.IsTrue(DotNet_StringNormalized.IsNormalized(DotNet_NormalizationForm), NotNormalizedStringErr);

        // [WHEN] the string is normalized to form D
        DotNet_NormalizationForm.FormD();
        DotNet_StringNormalized.Set(DotNet_String.Normalize(DotNet_NormalizationForm));
        // [THEN] value of the string corresponds to normalized form D
        Assert.IsTrue(DotNet_StringNormalized.IsNormalized(DotNet_NormalizationForm), NotNormalizedStringErr);

        // [WHEN] the string is normalized to form KC
        DotNet_NormalizationForm.FormKC();
        DotNet_StringNormalized.Set(DotNet_String.Normalize(DotNet_NormalizationForm));
        // [THEN] value of the string corresponds to normalized form KC
        Assert.IsTrue(DotNet_StringNormalized.IsNormalized(DotNet_NormalizationForm), NotNormalizedStringErr);

        // [WHEN] the string is normalized to form KD
        DotNet_NormalizationForm.FormKD();
        DotNet_StringNormalized.Set(DotNet_String.Normalize(DotNet_NormalizationForm));
        // [THEN] value of the string corresponds to normalized form KD
        Assert.IsTrue(DotNet_StringNormalized.IsNormalized(DotNet_NormalizationForm), NotNormalizedStringErr);
    end;
}

