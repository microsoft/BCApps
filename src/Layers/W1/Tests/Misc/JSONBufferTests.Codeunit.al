codeunit 139210 "JSON Buffer Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [JSON Buffer]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';

    [Test]
    [Scope('OnPrem')]
    procedure ReadEmptyJSONString()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] Reading empty string does not cause errors
        LibraryLowerPermissions.SetO365Basic();
        TempJSONBuffer.ReadFromText('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadInvalidJSONStrings()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] Reading invalid JSON does produce errors
        LibraryLowerPermissions.SetO365Basic();
        asserterror TempJSONBuffer.ReadFromText('Test');
        asserterror TempJSONBuffer.ReadFromText('{Test}');
        asserterror TempJSONBuffer.ReadFromText('{Test - 5}');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotInsertNonTemporaryJSONString()
    var
        JSONBuffer: Record "JSON Buffer";
    begin
        // [SCENARIO] It is only possible to use JSON Buffer as a temporary table
        LibraryLowerPermissions.SetO365Basic();
        asserterror JSONBuffer.ReadFromText('{Test : 5}');
        Assert.ExpectedError(DevMsgNotTemporaryErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadJSONArray()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        TempResultArrayJSONBuffer: Record "JSON Buffer" temporary;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports reading arrays
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] A JSON string containing an array is read
        TempJSONBuffer.ReadFromText('{"Result":[{"MyVar":"5"},{"OtherVar":"TestValue"}]}');
        // [THEN] The structure of the JSON buffer matches that JSON string
        Assert.AreEqual(13, TempJSONBuffer.Count, 'Not all JSON elements were read');
        TempJSONBuffer.FindFirst();
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"Start Object", '', '', '');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'Result', 'System.String', 'Result');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Start Array", '', '', 'Result');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Start Object", '', '', 'Result[0]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::"Property Name", 'MyVar', 'System.String', 'Result[0].MyVar');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::String, '5', 'System.String', 'Result[0].MyVar');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"End Object", '', '', 'Result[0]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Start Object", '', '', 'Result[1]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::"Property Name", 'OtherVar', 'System.String', 'Result[1].OtherVar');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::String, 'TestValue', 'System.String', 'Result[1].OtherVar');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"End Object", '', '', 'Result[1]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"End Array", '', '', 'Result');
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"End Object", '', '', '');
        // [THEN] We can fetch the array and variables using FindArray and GetPropertyValue
        TempJSONBuffer.FindFirst();
        Assert.IsTrue(TempJSONBuffer.FindArray(TempResultArrayJSONBuffer, 'Result'), 'Could not find result array');
        Assert.AreEqual(2, TempResultArrayJSONBuffer.Count, 'Wrong number of array entries');
        Assert.IsTrue(TempResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'MyVar'), 'could not find property value for MyVar');
        Assert.AreEqual('5', PropertyValue, '');
        Assert.IsTrue(TempResultArrayJSONBuffer.Next() <> 0, 'There are no more elements');
        Assert.IsTrue(
          TempResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'OtherVar'), 'could not find property value for OtherVar');
        Assert.AreEqual('TestValue', PropertyValue, '');
        Assert.IsTrue(TempResultArrayJSONBuffer.Next() = 0, 'There should not be any more elements');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadJSONVariables()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        PropertyValue: Text;
        DecimalPropertyValue: Decimal;
    begin
        // [SCENARIO] JSON Buffer supports reading variables
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] A JSON string containing variables is read
        TempJSONBuffer.ReadFromText('{"test1":"value1","test2":2.3,"test3":"value3"}');
        // [THEN] The structure of the JSON buffer matches that JSON string
        Assert.AreEqual(8, TempJSONBuffer.Count, 'Not all JSON elements were read');
        TempJSONBuffer.FindFirst();
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"Start Object", '', '', '');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'test1', 'System.String', 'test1');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::String, 'value1', 'System.String', 'test1');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'test2', 'System.String', 'test2');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Decimal, Format(2.3), 'System.Double', 'test2');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'test3', 'System.String', 'test3');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::String, 'value3', 'System.String', 'test3');
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"End Object", '', '', '');
        // [THEN] We can fetch the variables using GetPropertyValue
        Assert.IsTrue(TempJSONBuffer.GetPropertyValue(PropertyValue, 'test1'), 'could not find property value for test1');
        Assert.AreEqual('value1', PropertyValue, '');
        Assert.IsTrue(TempJSONBuffer.GetDecimalPropertyValue(DecimalPropertyValue, 'test2'), 'could not find property value for test2');
        Assert.AreEqual(2.3, DecimalPropertyValue, '');
        Assert.IsTrue(TempJSONBuffer.GetPropertyValue(PropertyValue, 'test3'), 'could not find property value for test3');
        Assert.AreEqual('value3', PropertyValue, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadTwoNestedJSONArrays()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        TempOuterResultArrayJSONBuffer: Record "JSON Buffer" temporary;
        TempInnerResultArrayJSONBuffer: Record "JSON Buffer" temporary;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports reading nested arrays
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] A JSON string containing two nested arrays is read
        TempJSONBuffer.ReadFromText(
          '{"Result":[{"MyVar":"5","Result":[{"InnerContent1":"InnerValue1","InnerContent2":"InnerValue2"}]},{"OtherVar":"TestValue"}]}');

        // [THEN] We can find these two arrays
        Assert.IsTrue(TempJSONBuffer.FindArray(TempOuterResultArrayJSONBuffer, 'Result'), 'Could not find outer result array');
        Assert.IsTrue(
          TempOuterResultArrayJSONBuffer.FindArray(TempInnerResultArrayJSONBuffer, 'Result'), 'Could not find inner result array');

        // [THEN] The inner array cannot find variables in the outer
        Assert.IsFalse(
          TempInnerResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'MyVar'),
          'MyVar should not be in the scope of the inner result array');
        Assert.IsFalse(
          TempInnerResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'OtherVar'),
          'OtherVar should not be in the scope of the inner result array');
        // [THEN] The inner array has property values for variables in it
        Assert.IsTrue(
          TempInnerResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'InnerContent2'), 'could not find property value for MyVar');
        Assert.AreEqual('InnerValue2', PropertyValue, '');
        Assert.IsTrue(
          TempInnerResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'InnerContent1'), 'could not find property value for MyVar');
        Assert.AreEqual('InnerValue1', PropertyValue, ''); // We can get these array values in any order we like :)

        // [THEN] The outer array has property values for variables in it
        Assert.IsTrue(TempOuterResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'MyVar'), 'could not find property value for MyVar');
        Assert.AreEqual('5', PropertyValue, '');
        Assert.IsFalse(
          TempOuterResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'OtherVar'),
          'OtherVar should not be accessible from first index of outer array');
        TempOuterResultArrayJSONBuffer.Next();
        Assert.IsTrue(
          TempOuterResultArrayJSONBuffer.GetPropertyValue(PropertyValue, 'OtherVar'),
          'OtherVar should be accessible from first index of outer array');
        Assert.AreEqual('TestValue', PropertyValue, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadTwoSeperateJSONArrays()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        TempArray1JSONBuffer: Record "JSON Buffer" temporary;
        TempArray2JSONBuffer: Record "JSON Buffer" temporary;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports reading consecutive arrays
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] A JSON string containing two consecutive arrays is read
        TempJSONBuffer.ReadFromText('{"Array1":[{"Arr1Var":"Arr1Val"}],"Array2":[{"Arr2Var":"Arr2Val"}]}');

        // [THEN] We can find these two arrays
        Assert.IsTrue(TempJSONBuffer.FindArray(TempArray1JSONBuffer, 'Array1'), 'Could not find array 1');
        Assert.IsTrue(TempJSONBuffer.FindArray(TempArray2JSONBuffer, 'Array2'), 'Could not find array 2');

        // [THEN] The array 1 cannot access variables in array 2
        Assert.IsFalse(TempArray1JSONBuffer.GetPropertyValue(PropertyValue, 'Arr2Var'), 'Arr2Var should not be in the scope of array 1');
        // [THEN] The array 1 can access variables in array 1
        Assert.IsTrue(TempArray1JSONBuffer.GetPropertyValue(PropertyValue, 'Arr1Var'), 'could not find property value for MyVar');
        Assert.AreEqual('Arr1Val', PropertyValue, '');

        // [THEN] The array 2 cannot access variables in array 1
        Assert.IsFalse(TempArray2JSONBuffer.GetPropertyValue(PropertyValue, 'Arr1Var'), 'Arr1Var should not be in the scope of array 2');
        // [THEN] The array 2 can access variables in array 2
        Assert.IsTrue(TempArray2JSONBuffer.GetPropertyValue(PropertyValue, 'Arr2Var'), 'could not find property value for MyVar');
        Assert.AreEqual('Arr2Val', PropertyValue, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadLargeVariableValue()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        LongString: Text;
        PropertyValue: Text;
        i: Integer;
    begin
        // [SCENARIO] JSON Buffer supports large values
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] A JSON string containing a very long value is read
        LongString := 'ABCDEFGHIJKLMOPQRTSTUVWXYZÆØÅ1234567890+´!#¤%&/()=?`,.-;:_@£${[]}<>abcdefghijklmnopqrstuvwxyzæøå½§';
        for i := 1 to 1000 do
            LongString += 'fillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfillfill';
        TempJSONBuffer.ReadFromText(StrSubstNo('{"Variable":"%1"}', LongString));
        TempJSONBuffer.GetPropertyValue(PropertyValue, 'Variable');
        Assert.AreEqual(LongString, PropertyValue, 'Invalid string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatJSONDateTimeWithoutSeconds()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        DateTime: DotNet DateTime;
        CultureInfo: DotNet CultureInfo;
        DateTimeString: Text;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports formatting DateTime containing no seconds and milliseconds
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] A JSON string containing a DateTime without seconds or milliseconds is read
        DateTimeString := DateTime.UtcNow.ToString('yyyy-MM-ddTHH:mm', CultureInfo.InvariantCulture);
        TempJSONBuffer.ReadFromText(StrSubstNo('{"Variable":"%1"}', DateTimeString));

        // [THEN] JSON Buffer contains formatted DateTime without seconds or milliseconds
        TempJSONBuffer.GetPropertyValue(PropertyValue, 'Variable');
        Assert.IsFalse(PropertyValue.Contains('.'), 'DateTime contains seconds and milliseconds');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatJSONDateTimeWithSeconds()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        DateTime: DotNet DateTime;
        CultureInfo: DotNet CultureInfo;
        DateTimeString: Text;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports formatting DateTime containing seconds and milliseconds
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] A JSON string containing a DateTime with seconds and milliseconds is read
        DateTimeString := DateTime.UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fff', CultureInfo.InvariantCulture);

        // For unknown reasons, the DateTime.UtcNow.ToString method call above does not always return a string with seconds and milliseconds.
        if not DateTimeString.Contains('.') then
            DateTimeString := '2025-12-31T23:59:59.999';

        TempJSONBuffer.ReadFromText(StrSubstNo('{"Variable":"%1"}', DateTimeString));

        // [THEN] JSON Buffer contains formatted DateTime with seconds and milliseconds
        TempJSONBuffer.GetPropertyValue(PropertyValue, 'Variable');
        Assert.IsTrue(PropertyValue.Contains('.'), StrSubstNo('DateTime does not contain seconds and milliseconds. DateTimeString: %1, PropertyValue: %2', DateTimeString, PropertyValue));
    end;

    local procedure VerifyJSONBuffer(var TempJSONBuffer: Record "JSON Buffer" temporary; Depth: Integer; TokenType: Option; Value: Text; ValueType: Text[250]; Path: Text[250])
    begin
        Assert.AreEqual(Depth, TempJSONBuffer.Depth, 'Incorrect depth');
        Assert.AreEqual(TokenType, TempJSONBuffer."Token type", 'Incorrect token type');
        Assert.AreEqual(Value, TempJSONBuffer.GetValue(), 'Incorrect JSON value');
        Assert.AreEqual(ValueType, TempJSONBuffer."Value Type", 'Incorrect JSON value type');
        Assert.AreEqual(Path, TempJSONBuffer.Path, 'Incorrect JSON path');
    end;

    local procedure VerifyJSONBufferAndFindNext(var TempJSONBuffer: Record "JSON Buffer" temporary; Depth: Integer; TokenType: Option; Value: Text; ValueType: Text[250]; Path: Text[250])
    begin
        Assert.AreEqual(Depth, TempJSONBuffer.Depth, 'Incorrect depth');
        Assert.AreEqual(TokenType, TempJSONBuffer."Token type", 'Incorrect token type');
        Assert.AreEqual(Value, TempJSONBuffer.GetValue(), 'Incorrect JSON value');
        Assert.AreEqual(ValueType, TempJSONBuffer."Value Type", 'Incorrect JSON value type');
        Assert.AreEqual(Path, TempJSONBuffer.Path, 'Incorrect JSON path');
        Assert.IsTrue(TempJSONBuffer.Next() <> 0, 'There are no more elements');
    end;
}

