codeunit 146027 Test_DotNet_StreamReader
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [StreamReader]
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        DotNet_StreamWriter: Codeunit DotNet_StreamWriter;
        DotNet_StreamReader: Codeunit DotNet_StreamReader;
        DotNet_Encoding: Codeunit DotNet_Encoding;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadingUsingReadLine()
    var
        Expected: Text;
        Actual: Text;
        "Count": Integer;
        ActualCodepage: Integer;
    begin
        // [WHEN] One-lined text file with encoding 1252 is created as read line by line
        CreateSampleStreamFromText('Test', 1, 1252);
        ReadLineByLineInGivenCodepage(1252, Count, Actual, ActualCodepage);
        // [THEN] Expected line count is 1 and concatenation of all lines should be 'Test'
        Assert.AreEqual(1252, ActualCodepage, 'Codepage check failed');
        Assert.AreEqual(1, Count, 'Line count check failed');
        Expected := 'Test';
        Assert.AreEqual(Expected, Actual, 'Simple text file read failed');

        // [WHEN] Two-lined text file with encoding 1252 is created
        CreateSampleStreamFromText('Test', 2, 1252);
        ReadLineByLineInGivenCodepage(1252, Count, Actual, ActualCodepage);
        // [THEN] Expected line count is 2 and concatenation of all lines should be 'TestTest'
        Assert.AreEqual(2, Count, 'Line count check failed');
        Expected := 'TestTest';
        Assert.AreEqual(Expected, Actual, 'Simple text file read failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadingUsingReadToEnd()
    var
        Expected: Text;
        Actual: Text;
    begin
        // [WHEN] One-lined text file with encoding 1252 is created and whole content is read
        CreateSampleStreamFromText('Test', 0, 1252);
        Actual := ReadToEndInGivenCodepage(1252);
        // [THEN] Actual content that was read should be 'Test'
        Expected := 'Test';
        Assert.AreEqual(Expected, Actual, 'Simple text file read failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadingFromStreamsInBalticEncodings()
    var
        Expected: Text;
        Actual: Text;
    begin
        // [GIVEN] A sample text full of Baltic specific characters encoded using Utf8
        CreateSampleStreamFromBase64('xIXEjcSZxJfEr8WhxbPFq8W+xITEjMSYxJbErsWgxbLFqsW9YWJjZA==');
        Expected := ReadToEndInGivenCodepage(0);

        // [WHEN] The same text is read from stream in Windows-1257 encoding:
        CreateSampleStreamFromBase64('4Ojm6+Hw+Pv+wMjGy8HQ2NveYWJjZA==');
        Actual := ReadToEndInGivenCodepage(1257);
        // [THEN] Final string from Windows-1257 encoded stream should be the same to string from Utf-8 stream
        Assert.AreEqual(Expected, Actual, 'Windows-1257 stream check failed');

        // [WHEN] The same text is read from stream in OEM-775 encoding:
        CreateSampleStreamFromBase64('0NHS09TV1tfYtba3uL2+xsfPYWJjZA==');
        Actual := ReadToEndInGivenCodepage(775);
        // [THEN] Final string from OEM-775 encoded stream should be the same to string from Utf-8 stream
        Assert.AreEqual(Expected, Actual, 'OEM-775 stream check failed');

        // [WHEN] The same text is read from stream in ISO-8859-4 (Windows-28594) encoding:
        CreateSampleStreamFromBase64('sejq7Oe5+f6+ocjKzMep2d6uYWJjZA==');
        Actual := ReadToEndInGivenCodepage(28594);
        // [THEN] Final string from ISO-8859-4 encoded stream should be the same to string from Utf-8 stream
        Assert.AreEqual(Expected, Actual, 'ISO-8859-4 stream check failed');

        // [WHEN] The same text is read from stream in ISO-8859-13 (Windows-28603) encoding:
        CreateSampleStreamFromBase64('4Ojm6+Hw+Pv+wMjGy8HQ2NveYWJjZA==');
        Actual := ReadToEndInGivenCodepage(28603);
        // [THEN] Final string from ISO-8859-13 encoded stream should be the same to string from Utf-8 stream
        Assert.AreEqual(Expected, Actual, 'ISO-8859-13 stream check failed');
    end;

    [Scope('OnPrem')]
    procedure CreateSampleStreamFromText(SampleText: Text; LineCount: Integer; Codepage: Integer)
    var
        OutputStream: OutStream;
        LineNo: Integer;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutputStream);
        DotNet_Encoding.Encoding(Codepage);
        DotNet_StreamWriter.StreamWriter(OutputStream, DotNet_Encoding);
        for LineNo := 1 to LineCount do
            DotNet_StreamWriter.WriteLine(SampleText);
        if LineCount = 0 then
            DotNet_StreamWriter.Write(SampleText);

        DotNet_StreamWriter.Close();
        DotNet_StreamWriter.Dispose();
    end;

    [Scope('OnPrem')]
    procedure CreateSampleStreamFromBase64(Base64: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64, OutStream);
    end;

    [Scope('OnPrem')]
    procedure ReadToEndInGivenCodepage(Codepage: Integer): Text
    var
        InputStream: InStream;
        ResultText: Text;
    begin
        TempBlob.CreateInStream(InputStream);
        if Codepage > 0 then
            DotNet_Encoding.Encoding(Codepage)
        else
            DotNet_Encoding.UTF8();

        DotNet_StreamReader.StreamReader(InputStream, DotNet_Encoding);
        ResultText := DotNet_StreamReader.ReadToEnd();
        DotNet_StreamReader.Close();
        DotNet_StreamReader.Dispose();
        exit(ResultText);
    end;

    [Scope('OnPrem')]
    procedure ReadLineByLineInGivenCodepage(Codepage: Integer; var LineCount: Integer; var ResultText: Text; var StreamCodepage: Integer)
    var
        InputStream: InStream;
        CurrentLine: Text;
        LineIsEmpty: Boolean;
    begin
        TempBlob.CreateInStream(InputStream);
        if Codepage > 0 then
            DotNet_Encoding.Encoding(Codepage)
        else
            DotNet_Encoding.UTF8();

        DotNet_StreamReader.StreamReader(InputStream, DotNet_Encoding);
        LineCount := 0;
        ResultText := '';
        repeat
            CurrentLine := DotNet_StreamReader.ReadLine();
            LineIsEmpty := (CurrentLine = '') and DotNet_StreamReader.EndOfStream();
            if not LineIsEmpty then begin
                LineCount += 1;
                ResultText += CurrentLine;
            end;
        until LineIsEmpty;

        DotNet_StreamReader.CurrentEncoding(DotNet_Encoding);
        StreamCodepage := DotNet_Encoding.Codepage();
        DotNet_StreamReader.Close();
        DotNet_StreamReader.Dispose();
    end;
}

