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
        // [SCENARIO] Reading empty or whitespace JSON clears the buffer without causing errors
        LibraryLowerPermissions.SetO365Basic();
        TempJSONBuffer.ReadFromText('{"value":1}');
        TempJSONBuffer.ReadFromText('');
        Assert.RecordIsEmpty(TempJSONBuffer);
        TempJSONBuffer.ReadFromText('   ');
        Assert.RecordIsEmpty(TempJSONBuffer);
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
        asserterror TempJSONBuffer.ReadFromText('true false');
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
    procedure ReadRootJSONArray()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] JSON Buffer supports a JSON array at the root
        LibraryLowerPermissions.SetO365Basic();

        TempJSONBuffer.ReadFromText('[1,{"value":"x"},[]]');

        Assert.AreEqual(9, TempJSONBuffer.Count(), 'Not all JSON elements were read');
        TempJSONBuffer.FindFirst();
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"Start Array", '', '', '');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Integer, '1', 'System.Int64', '[0]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Start Object", '', '', '[1]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Property Name", 'value', 'System.String', '[1].value');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::String, 'x', 'System.String', '[1].value');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"End Object", '', '', '[1]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Start Array", '', '', '[2]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"End Array", '', '', '[2]');
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"End Array", '', '', '');
        VerifyContiguousEntryNumbers(TempJSONBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadRootJSONScalars()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] JSON Buffer supports each standard JSON scalar at the root
        LibraryLowerPermissions.SetO365Basic();

        TempJSONBuffer.ReadFromText('"root"');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root string must create one row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::String, 'root', 'System.String', '');

        TempJSONBuffer.ReadFromText('42');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root integer must replace the previous row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::Integer, '42', 'System.Int64', '');

        TempJSONBuffer.ReadFromText('2.5');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root decimal must replace the previous row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::Decimal, Format(2.5), 'System.Double', '');

        TempJSONBuffer.ReadFromText('true');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root Boolean must replace the previous row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::Boolean, 'Yes', 'System.Boolean', '');

        TempJSONBuffer.ReadFromText('false');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root Boolean must replace the previous row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::Boolean, 'No', 'System.Boolean', '');

        TempJSONBuffer.ReadFromText('null');
        Assert.AreEqual(1, TempJSONBuffer.Count(), 'A root null must replace the previous row');
        TempJSONBuffer.FindFirst();
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::Null, '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadNestedJSONAndPunctuationPathsInPropertyOrder()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] JSON Buffer preserves object order and native paths through nested and empty containers
        LibraryLowerPermissions.SetO365Basic();

        TempJSONBuffer.ReadFromText('{"z":1,"a.b":{"emptyArray":[],"nested":[{"flag":true}]},"a":null,"emptyObject":{}}');

        Assert.AreEqual(22, TempJSONBuffer.Count(), 'Not all JSON elements were read');
        TempJSONBuffer.FindFirst();
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"Start Object", '', '', '');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'z', 'System.String', 'z');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Integer, '1', 'System.Int64', 'z');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'a.b', 'System.String', '[''a.b'']');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Start Object", '', '', '[''a.b'']');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Property Name", 'emptyArray', 'System.String', '[''a.b''].emptyArray');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Start Array", '', '', '[''a.b''].emptyArray');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"End Array", '', '', '[''a.b''].emptyArray');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Property Name", 'nested', 'System.String', '[''a.b''].nested');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"Start Array", '', '', '[''a.b''].nested');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::"Start Object", '', '', '[''a.b''].nested[0]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 4, TempJSONBuffer."Token type"::"Property Name", 'flag', 'System.String', '[''a.b''].nested[0].flag');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 4, TempJSONBuffer."Token type"::Boolean, 'Yes', 'System.Boolean', '[''a.b''].nested[0].flag');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 3, TempJSONBuffer."Token type"::"End Object", '', '', '[''a.b''].nested[0]');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 2, TempJSONBuffer."Token type"::"End Array", '', '', '[''a.b''].nested');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"End Object", '', '', '[''a.b'']');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'a', 'System.String', 'a');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Null, '', '', 'a');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'emptyObject', 'System.String', 'emptyObject');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Start Object", '', '', 'emptyObject');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"End Object", '', '', 'emptyObject');
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"End Object", '', '', '');
        VerifyContiguousEntryNumbers(TempJSONBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadJSONNumberTypes()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        ExponentValue: Decimal;
        LargeIntegerValue: BigInteger;
    begin
        // [SCENARIO] JSON Buffer distinguishes integer and floating-point JSON number syntax
        LibraryLowerPermissions.SetO365Basic();
        ExponentValue := 1000;
        Evaluate(LargeIntegerValue, '3000000000');

        TempJSONBuffer.ReadFromText('{"integer":42,"negative":-7,"largeInteger":3000000000,"decimal":2.3,"exponent":1e3}');

        Assert.AreEqual(12, TempJSONBuffer.Count(), 'Not all JSON elements were read');
        TempJSONBuffer.FindFirst();
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"Start Object", '', '', '');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'integer', 'System.String', 'integer');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Integer, '42', 'System.Int64', 'integer');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'negative', 'System.String', 'negative');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Integer, '-7', 'System.Int64', 'negative');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'largeInteger', 'System.String', 'largeInteger');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Integer, Format(LargeIntegerValue), 'System.Int64', 'largeInteger');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'decimal', 'System.String', 'decimal');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Decimal, Format(2.3), 'System.Double', 'decimal');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::"Property Name", 'exponent', 'System.String', 'exponent');
        VerifyJSONBufferAndFindNext(TempJSONBuffer, 1, TempJSONBuffer."Token type"::Decimal, Format(ExponentValue), 'System.Double', 'exponent');
        VerifyJSONBuffer(TempJSONBuffer, 0, TempJSONBuffer."Token type"::"End Object", '', '', '');
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
        TempJSONBuffer.SetRange("Token type", TempJSONBuffer."Token type"::String);
        TempJSONBuffer.FindFirst();
        TempJSONBuffer.CalcFields("Value BLOB");
        Assert.IsTrue(TempJSONBuffer."Value BLOB".HasValue(), 'The long value was not stored in the BLOB');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadJSONFromBlob()
    var
        SourceJSONBuffer: Record "JSON Buffer" temporary;
        TempJSONBuffer: Record "JSON Buffer" temporary;
        BlobFieldRef: FieldRef;
        SourceRecordRef: RecordRef;
        OutStream: OutStream;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer continues to support UTF-8 JSON stored in a BLOB field
        LibraryLowerPermissions.SetO365Basic();
        SourceJSONBuffer."Entry No." := 1;
        SourceJSONBuffer."Value BLOB".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText('{"fromBlob":true}');
        SourceJSONBuffer.Insert();
        SourceRecordRef.GetTable(SourceJSONBuffer);
        BlobFieldRef := SourceRecordRef.Field(SourceJSONBuffer.FieldNo("Value BLOB"));

        TempJSONBuffer.ReadFromBlob(BlobFieldRef);

        Assert.AreEqual(4, TempJSONBuffer.Count(), 'Not all JSON elements were read from the BLOB');
        Assert.IsTrue(TempJSONBuffer.GetPropertyValue(PropertyValue, 'fromBlob'), 'The BLOB property was not found');
        Assert.AreEqual('Yes', PropertyValue, 'The BLOB property value is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectJsonNetOnlyInput()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] Native JSON parsing rejects Json.NET extensions that are not standard JSON
        LibraryLowerPermissions.SetO365Basic();

        asserterror TempJSONBuffer.ReadFromText('{"value":1/*comment*/}');
        asserterror TempJSONBuffer.ReadFromText('new Date(123)');
        asserterror TempJSONBuffer.ReadFromText('undefined');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadCommentMarkersInsideJSONString()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        PropertyValue: Text;
    begin
        // [SCENARIO] Comment markers inside a JSON string are ordinary string content
        LibraryLowerPermissions.SetO365Basic();

        TempJSONBuffer.ReadFromText('{"url":"https://example.test/path/*segment*/"}');

        Assert.IsTrue(TempJSONBuffer.GetPropertyValue(PropertyValue, 'url'), 'The URL property was not found');
        Assert.AreEqual('https://example.test/path/*segment*/', PropertyValue, 'The URL property value is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatJSONDateTimeWithoutSeconds()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        DateTimeString: Text;
        PropertyValue: Text;
    begin
        // [SCENARIO] A date-time-like string without seconds remains a string
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] A JSON string containing a DateTime without seconds or milliseconds is read
        DateTimeString := '2025-12-31T23:59';
        TempJSONBuffer.ReadFromText(StrSubstNo('{"Variable":"%1"}', DateTimeString));

        // [THEN] JSON Buffer preserves the value as a string without seconds or milliseconds
        TempJSONBuffer.GetPropertyValue(PropertyValue, 'Variable');
        Assert.IsFalse(PropertyValue.Contains('.'), 'DateTime contains seconds and milliseconds');
        TempJSONBuffer.SetRange("Token type", TempJSONBuffer."Token type"::String);
        Assert.IsTrue(TempJSONBuffer.FindFirst(), 'The date-time-like value was not preserved as a string');
        Assert.AreEqual('System.String', TempJSONBuffer."Value Type", 'The string value type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatJSONDateTimeWithSeconds()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        DateTimeString: Text;
        PropertyValue: Text;
    begin
        // [SCENARIO] JSON Buffer supports formatting DateTime containing seconds and milliseconds
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] A JSON string containing a DateTime with seconds and milliseconds is read
        DateTimeString := '2025-12-31T23:59:59.999';
        TempJSONBuffer.ReadFromText(StrSubstNo('{"Variable":"%1"}', DateTimeString));

        // [THEN] JSON Buffer contains formatted DateTime with seconds and milliseconds
        TempJSONBuffer.GetPropertyValue(PropertyValue, 'Variable');
        Assert.IsTrue(PropertyValue.Contains('.'), StrSubstNo('DateTime does not contain seconds and milliseconds. DateTimeString: %1, PropertyValue: %2', DateTimeString, PropertyValue));
        TempJSONBuffer.SetRange("Token type", TempJSONBuffer."Token type"::Date);
        Assert.IsTrue(TempJSONBuffer.FindFirst(), 'The ISO DateTime was not recognized');
        Assert.AreEqual('System.DateTime', TempJSONBuffer."Value Type", 'The DateTime value type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateLikeNonDateRemainsString()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        // [SCENARIO] A date-like string is only classified as Date when it is a valid ISO DateTime
        LibraryLowerPermissions.SetO365Basic();

        TempJSONBuffer.ReadFromText('{"dateOnly":"2025-12-31","invalidDateTime":"2025-13-40T25:61"}');

        TempJSONBuffer.SetRange("Token type", TempJSONBuffer."Token type"::String);
        Assert.AreEqual(2, TempJSONBuffer.Count(), 'Date-like strings were classified as DateTime values');
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

    local procedure VerifyContiguousEntryNumbers(var TempJSONBuffer: Record "JSON Buffer" temporary)
    var
        ExpectedEntryNo: Integer;
    begin
        TempJSONBuffer.Reset();
        if TempJSONBuffer.FindSet() then
            repeat
                ExpectedEntryNo += 1;
                Assert.AreEqual(ExpectedEntryNo, TempJSONBuffer."Entry No.", 'JSON buffer entry numbers are not contiguous');
            until TempJSONBuffer.Next() = 0;
    end;
}
