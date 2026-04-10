codeunit 135100 "CSV Buffer Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [CSV Buffer]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestFillBuffer()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        ServerTempFileName: Text;
    begin
        // [SCENARIO] Load a CSV file into the buffer

        // [GIVEN] A CSV file
        ServerTempFileName := CreateSampleCSVFile();

        // [WHEN] The file is loaded into the buffer
        TempCSVBuffer.LoadData(ServerTempFileName, ';');
        TempCSVBuffer.FindLast();

        // [THEN] Every field in the CSV file results in one record
        Assert.AreEqual(12, TempCSVBuffer.Count, 'The number of records do not match.');

        // [THEN] The number of lines/index in the file machtes the number of lines/index in the buffer
        Assert.AreEqual(4, TempCSVBuffer."Line No.", 'The number of lines do not match.');
        Assert.AreEqual(3, TempCSVBuffer."Field No.", 'The indexes do not match.');

        // [THEN] All the values are loaded correctly into the buffer
        Assert.AreEqual('01', TempCSVBuffer.GetValue(1, 1), 'The value does not match in line 1, field 1.');
        Assert.AreEqual('Test 1', TempCSVBuffer.GetValue(1, 2), 'The value does not match in line 1, field 2.');
        Assert.AreEqual('1234', TempCSVBuffer.GetValue(1, 3), 'The value does not match in line 1, field 3.');
        Assert.AreEqual('02', TempCSVBuffer.GetValue(2, 1), 'The value does not match in line 2, field 1.');
        Assert.AreEqual('Test 2', TempCSVBuffer.GetValue(2, 2), 'The value does not match in line 2, field 2.');
        Assert.AreEqual('5678', TempCSVBuffer.GetValue(2, 3), 'The value does not match in line 2, field 3.');
        Assert.AreEqual('02', TempCSVBuffer.GetValue(3, 1), 'The value does not match in line 3, field 1.');
        Assert.AreEqual('Test 1', TempCSVBuffer.GetValue(3, 2), 'The value does not match in line 3, field 2.');
        Assert.AreEqual('9012', TempCSVBuffer.GetValue(3, 3), 'The value does not match in line 3, field 3.');
        Assert.AreEqual('03', TempCSVBuffer.GetValue(4, 1), 'The value does not match in line 4, field 1.');
        Assert.AreEqual('Test 2', TempCSVBuffer.GetValue(4, 2), 'The value does not match in line 4, field 2.');
        Assert.AreEqual('3456', TempCSVBuffer.GetValue(4, 3), 'The value does not match in line 4, field 3.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFillBufferWithCharactersToTrim()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        ServerTempFileName: Text;
    begin
        // [SCENARIO] Load a CSV file into the buffer with characters to skip

        // [GIVEN] A CSV file
        ServerTempFileName := CreateSampleCSVFile();

        // [WHEN] The file is loaded into the buffer and all the 1-s are skipped
        TempCSVBuffer.LoadData(ServerTempFileName, ';', '1');
        TempCSVBuffer.FindLast();

        // [THEN] Every field in the CSV file results in one record
        Assert.AreEqual(12, TempCSVBuffer.Count(), 'The number of records do not match.');

        // [THEN] The number of lines/index in the file machtes the number of lines/index in the buffer
        Assert.AreEqual(4, TempCSVBuffer."Line No.", 'The number of lines do not match.');
        Assert.AreEqual(3, TempCSVBuffer."Field No.", 'The indexes do not match.');

        // [THEN] All the values are loaded correctly into the buffer
        Assert.AreEqual('0', TempCSVBuffer.GetValue(1, 1), 'The value does not match in line 1, field 1.');
        Assert.AreEqual('Test ', TempCSVBuffer.GetValue(1, 2), 'The value does not match in line 1, field 2.');
        Assert.AreEqual('234', TempCSVBuffer.GetValue(1, 3), 'The value does not match in line 1, field 3.');
        Assert.AreEqual('02', TempCSVBuffer.GetValue(2, 1), 'The value does not match in line 2, field 1.');
        Assert.AreEqual('Test 2', TempCSVBuffer.GetValue(2, 2), 'The value does not match in line 2, field 2.');
        Assert.AreEqual('5678', TempCSVBuffer.GetValue(2, 3), 'The value does not match in line 2, field 3.');
        Assert.AreEqual('02', TempCSVBuffer.GetValue(3, 1), 'The value does not match in line 3, field 1.');
        Assert.AreEqual('Test ', TempCSVBuffer.GetValue(3, 2), 'The value does not match in line 3, field 2.');
        Assert.AreEqual('9012', TempCSVBuffer.GetValue(3, 3), 'The value does not match in line 3, field 3.');
        Assert.AreEqual('03', TempCSVBuffer.GetValue(4, 1), 'The value does not match in line 4, field 1.');
        Assert.AreEqual('Test 2', TempCSVBuffer.GetValue(4, 2), 'The value does not match in line 4, field 2.');
        Assert.AreEqual('3456', TempCSVBuffer.GetValue(4, 3), 'The value does not match in line 4, field 3.');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyFile()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        ServerTempFileName: Text;
    begin
        // [SCENARIO] Load an empty CSV file into the buffer

        // [GIVEN] An empty CSV file
        ServerTempFileName := CreateEmptyCSVFile();

        // [WHEN] The file is loaded into the buffer
        TempCSVBuffer.LoadData(ServerTempFileName, ';');

        // [THEN] The empty CSV file results in one record
        Assert.AreEqual(1, TempCSVBuffer.Count, 'The number of records do not match.');

        // [THEN] There is one empty value in the buffer
        Assert.AreEqual('', TempCSVBuffer.GetValue(1, 1), 'The value does not match in line 1, field 1.');
        asserterror TempCSVBuffer.GetValue(1, 2);
        asserterror TempCSVBuffer.GetValue(2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterOnBuffer()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempResultCSVBuffer: Record "CSV Buffer" temporary;
        ServerTempFileName: Text;
    begin
        // [SCENARIO] Apply a filter on the buffer and retrieve data from buffer

        // [GIVEN] A CSV file
        ServerTempFileName := CreateSampleCSVFile();

        // [WHEN] The file is loaded into the buffer
        TempCSVBuffer.LoadData(ServerTempFileName, ';');

        // [WHEN] A filter is applied to the buffer
        TempCSVBuffer.GetCSVLinesWhere(1, '02', TempResultCSVBuffer);
        TempResultCSVBuffer.FindSet();

        // [THEN] The number of lines matches the number of lines after the filter application
        Assert.AreEqual(2, TempResultCSVBuffer.Count, 'The number of records do not match.');

        Assert.AreEqual('Test 2', TempResultCSVBuffer.GetValueOfLineAt(2), 'The value does not match in line 1, field 2.');
        Assert.AreEqual('5678', TempResultCSVBuffer.GetValueOfLineAt(3), 'The value does not match in line 1, field 3.');
        TempResultCSVBuffer.Next();
        Assert.AreEqual('Test 1', TempResultCSVBuffer.GetValueOfLineAt(2), 'The value does not match in line 2, field 2.');
        Assert.AreEqual('9012', TempResultCSVBuffer.GetValueOfLineAt(3), 'The value does not match in line 2, field 3.');
        Assert.IsTrue(TempResultCSVBuffer.Next() = 0, 'The filter did not work as expected.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadAndSaveData()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        FileManagement: Codeunit "File Management";
        TestFileSource: File;
        TestFileTarget: File;
        TestInStreamSource: InStream;
        TestInStreamTarget: InStream;
        ServerTempFileNameSource: Text;
        ServerTempFileNameTarget: Text;
        SourceText: Text;
        TargetText: Text;
    begin
        // [SCENARIO] Data from CSV Buffer is loaded from file and saved to file, resulting in identical files

        // [GIVEN] A source file which is loaded into the CSV Buffer
        ServerTempFileNameSource := CreateSampleCSVFile();
        TempCSVBuffer.LoadData(ServerTempFileNameSource, ';');
        Assert.AreEqual(12, TempCSVBuffer.Count, 'The number of records do not match.');

        // [WHEN] The SaveData function is called
        ServerTempFileNameTarget := FileManagement.ServerTempFileName('csv');
        TempCSVBuffer.SaveData(ServerTempFileNameTarget, ';');

        // [THEN] A CSV file containing the same data as the source file is created
        TestFileSource.Open(ServerTempFileNameSource);
        TestFileTarget.Open(ServerTempFileNameTarget);
        TestFileSource.CreateInStream(TestInStreamSource);
        TestFileTarget.CreateInStream(TestInStreamTarget);

        while not TestInStreamSource.EOS do begin
            TestInStreamSource.ReadText(SourceText, 100);
            TestInStreamTarget.ReadText(TargetText, 100);
            Assert.AreEqual(SourceText, TargetText, 'The source text differs from the target text. Save failed.');
        end;

        TestFileSource.Close();
        TestFileTarget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadAndSaveDataWithStreams()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        TestFileSource: File;
        TestInStreamSource: InStream;
        TestInStreamTarget: InStream;
        ServerTempFileNameSource: Text;
        SourceText: Text;
        TargetText: Text;
    begin
        // [SCENARIO] Data from CSV Buffer can be loaded from stream and saved to a blob

        // [GIVEN] A source stream which is loaded into the CSV Buffer
        ServerTempFileNameSource := CreateSampleCSVFile();
        TestFileSource.Open(ServerTempFileNameSource);
        TestFileSource.CreateInStream(TestInStreamSource);
        TempCSVBuffer.LoadDataFromStream(TestInStreamSource, ';');
        TestFileSource.Close();

        Assert.AreEqual(12, TempCSVBuffer.Count, 'The number of records do not match.');

        // [WHEN] The SaveDataToBlob function is called
        TempCSVBuffer.SaveDataToBlob(TempBlob, ';');

        // [THEN] The blob contains the same data as the source file.
        TestFileSource.Open(ServerTempFileNameSource);

        TestFileSource.CreateInStream(TestInStreamSource);
        TempBlob.CreateInStream(TestInStreamTarget);

        while not TestInStreamSource.EOS do begin
            TestInStreamSource.ReadText(SourceText, 100);
            TestInStreamTarget.ReadText(TargetText, 100);
            Assert.AreEqual(SourceText, TargetText, 'The source text differs from the target text. Save failed.');
        end;

        TestFileSource.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadDataWithColumnDelimiterInColumnValue()
    begin
        // [SCENARIO] Load a CSV file with column delimiter in column value

        LoadDataWithColumnDelimiterInColumnValue(',');
        LoadDataWithColumnDelimiterInColumnValue(';');
    end;

    local procedure LoadDataWithColumnDelimiterInColumnValue(ColumnDelimiter: Text[1])
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TestFileSource: File;
        TestInStreamSource: InStream;
        ServerTempFileNameSource: Text;
    begin
        // [GIVEN] A source stream which is loaded into the CSV Buffer
        ServerTempFileNameSource := CreateSampleCSVFileWithColumnDelimiterInColumnValue(ColumnDelimiter);
        TestFileSource.Open(ServerTempFileNameSource);
        TestFileSource.CreateInStream(TestInStreamSource);

        // [WHEN] Data is loaded into the CSV Buffer
        TempCSVBuffer.LoadDataFromStream(TestInStreamSource, ColumnDelimiter);
        TestFileSource.Close();

        // [THEN] The number of records and data in the records matches the expected value
        Assert.AreEqual(12, TempCSVBuffer.Count(), 'The number of records do not match.');
        TempCSVBuffer.FindSet();
        TempCSVBuffer.TestField(Value, '01');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '"Test' + ColumnDelimiter + ' 1"');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '3456');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '02');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, 'Test 2');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '"34' + ColumnDelimiter + '56"');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '"0' + ColumnDelimiter + '3"');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, 'Test 3');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '3456');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '04');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, 'Test 4');
        TempCSVBuffer.Next();
        TempCSVBuffer.TestField(Value, '3456');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeReaderWithEncoding()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        Encoding: DotNet Encoding;
        ServerTempFileName: Text;
        SpecialEncodingCode: Text;
        EncodedText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413075] Load an CSV file with some encoding which is not default

        // [GIVEN] CSV file with "Windows-1252" encoding
        SpecialEncodingCode := 'Windows-1252';
        EncodedText := 'ÅåØøÆæ';
        ServerTempFileName := CreateSampleCSVFileWithSpecialEncoding(SpecialEncodingCode, EncodedText);

        // [GIVEN] Run InitializeReader with "Windows-1252" encoding
        Encoding := Encoding.GetEncoding(SpecialEncodingCode);
        TempCSVBuffer.InitializeReader(ServerTempFileName, ';', '', Encoding);
        // [WHEN] The file is loaded into the buffer
        TempCSVBuffer.ReadLines(0);

        // [THEN] Loaded value properly encoded
        Assert.AreEqual(EncodedText, TempCSVBuffer.GetValue(1, 1), 'The loaded value is incorrect.');
    end;

    local procedure CreateSampleCSVFile() ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('csv');
        File.Create(ServerTempFileName);
        File.CreateOutStream(OutStream);
        OutStream.WriteText('01;Test 1;1234');
        OutStream.WriteText();
        OutStream.WriteText('02;Test 2;5678');
        OutStream.WriteText();
        OutStream.WriteText('02;Test 1;9012');
        OutStream.WriteText();
        OutStream.WriteText('03;Test 2;3456');
        File.Close();
    end;

    local procedure CreateSampleCSVFileWithSpecialEncoding(EncodingCode: Text; EncodedText: Text) ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        Writer: DotNet StreamWriter;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('csv');

        File.Create(ServerTempFileName);
        File.CreateOutStream(OutStream);

        Encoding := Encoding.GetEncoding(EncodingCode);
        Writer := Writer.StreamWriter(OutStream, Encoding);
        Writer.Write(Encoding.GetString(Encoding.GetBytes(EncodedText)));
        Writer.Close();
        File.Close();
    end;

    local procedure CreateEmptyCSVFile() ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('csv');
        File.Create(ServerTempFileName);
        File.CreateOutStream(OutStream);
        OutStream.WriteText();
        File.Close();
    end;

    local procedure CreateSampleCSVFileWithColumnDelimiterInColumnValue(ColumnDelimiter: Text[1]) ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('csv');
        File.Create(ServerTempFileName);
        File.CreateOutStream(OutStream);
        OutStream.WriteText('01' + ColumnDelimiter + '"Test' + ColumnDelimiter + ' 1"' + ColumnDelimiter + '3456');
        OutStream.WriteText();
        OutStream.WriteText('02' + ColumnDelimiter + 'Test 2' + ColumnDelimiter + '"34' + ColumnDelimiter + '56"');
        OutStream.WriteText();
        OutStream.WriteText('"0' + ColumnDelimiter + '3"' + ColumnDelimiter + 'Test 3' + ColumnDelimiter + '3456');
        OutStream.WriteText();
        OutStream.WriteText('04' + ColumnDelimiter + 'Test 4' + ColumnDelimiter + '3456');
        File.Close();
    end;
}

