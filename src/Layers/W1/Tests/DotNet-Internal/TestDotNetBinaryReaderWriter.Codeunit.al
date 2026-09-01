codeunit 146032 Test_DotNet_BinaryReaderWriter
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [BinaryReaderWriter]
    end;

    var
        Assert: Codeunit Assert;
        DotNet_BinaryReader: Codeunit DotNet_BinaryReader;
        DotNet_BinaryWriter: Codeunit DotNet_BinaryWriter;
        DotNet_SeekOrigin: Codeunit DotNet_SeekOrigin;
        DotNet_Stream: Codeunit DotNet_Stream;
        DotNet_MemoryStream: Codeunit DotNet_MemoryStream;
        DotNet_Encoding: Codeunit DotNet_Encoding;
        Byte_DotNet_Array: Codeunit DotNet_Array;
        ExpectedByte_DotNet_Array: Codeunit DotNet_Array;
        Char_DotNet_Array: Codeunit DotNet_Array;
        ExpectedChar_DotNet_Array: Codeunit DotNet_Array;

    [Test]
    [Scope('OnPrem')]
    procedure TestWritingDifferentDataTypes()
    var
        ExpectedChar: Char;
        ExpectedDec: Decimal;
        Byte: Byte;
    begin
        DotNet_Encoding.UTF32();
        DotNet_SeekOrigin.SeekBegin();

        CreateStream();
        DotNet_BinaryWriter.BinaryWriterWithEncoding(DotNet_Stream, DotNet_Encoding);
        DotNet_BinaryWriter.WriteChar('A');
        DotNet_BinaryWriter.WriteChar('B');
        DotNet_BinaryWriter.WriteByte(1);
        DotNet_BinaryWriter.WriteInt16(2);
        DotNet_BinaryWriter.WriteInt32(3);
        DotNet_BinaryWriter.WriteUInt16(4);
        DotNet_BinaryWriter.WriteUInt32(5);
        DotNet_BinaryWriter.WriteBoolean(true);
        DotNet_BinaryWriter.WriteDecimal(6);
        DotNet_BinaryWriter.WriteString('CDE');

        DotNet_BinaryWriter.Flush();

        DotNet_Stream.Seek(0, DotNet_SeekOrigin);
        DotNet_BinaryReader.BinaryReaderWithEncoding(DotNet_Stream, DotNet_Encoding);
        ExpectedChar := 'A';
        Assert.AreEqual(ExpectedChar, DotNet_BinaryReader.ReadChar(), 'ReadChar check failed');
        ExpectedChar := 'B';
        Assert.AreEqual(ExpectedChar, DotNet_BinaryReader.ReadChar(), 'ReadChar check failed');

        // Explicitly assigning 1 to a Byte variable, otherwise it appears as Integer
        Byte := 1;
        Assert.AreEqual(Byte, DotNet_BinaryReader.ReadByte(), 'ReadByte check failed');

        Assert.AreEqual(2, DotNet_BinaryReader.ReadInt16(), 'ReadInt16 check failed');
        Assert.AreEqual(3, DotNet_BinaryReader.ReadInt32(), 'ReadInt32 check failed');
        Assert.AreEqual(4, DotNet_BinaryReader.ReadUInt16(), 'ReadUInt16 check failed');
        Assert.AreEqual(5, DotNet_BinaryReader.ReadUInt32(), 'ReadUInt32 check failed');
        Assert.AreEqual(true, DotNet_BinaryReader.ReadBoolean(), 'ReadBoolean check failed');
        ExpectedDec := 6;
        Assert.AreEqual(ExpectedDec, DotNet_BinaryReader.ReadDecimal(), 'ReadDecimal check failed');
        Assert.AreEqual('CDE', DotNet_BinaryReader.ReadString(), 'ReadString check failed');
        Clear(Byte_DotNet_Array);
        DotNet_BinaryReader.ReadBytes(4, Byte_DotNet_Array);
        CheckArrayItems(Byte_DotNet_Array, ExpectedByte_DotNet_Array);
        Clear(Char_DotNet_Array);
        DotNet_BinaryReader.ReadChars(4, Char_DotNet_Array);
        CheckArrayItems(Char_DotNet_Array, ExpectedChar_DotNet_Array);

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteBool()
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteBoolTest
        DotNet_MemoryStream.MemoryStream();
        DotNet_MemoryStream.GetDotNetStream(DotNet_Stream);
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        DotNet_BinaryWriter.WriteBoolean(false);
        DotNet_BinaryWriter.WriteBoolean(false);
        DotNet_BinaryWriter.WriteBoolean(true);
        DotNet_BinaryWriter.WriteBoolean(false);
        DotNet_BinaryWriter.WriteBoolean(true);
        DotNet_BinaryWriter.WriteInt32(5);
        DotNet_BinaryWriter.WriteInt32(0);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        Assert.AreEqual(false, DotNet_BinaryReader.ReadBoolean(), 'Read check failed'); // false
        Assert.AreEqual(false, DotNet_BinaryReader.ReadBoolean(), 'Read check failed'); // false
        Assert.AreEqual(true, DotNet_BinaryReader.ReadBoolean(), 'Read check failed');  // true
        Assert.AreEqual(false, DotNet_BinaryReader.ReadBoolean(), 'Read check failed'); // false
        Assert.AreEqual(true, DotNet_BinaryReader.ReadBoolean(), 'Read check failed');  // true
        Assert.AreEqual(5, DotNet_BinaryReader.ReadInt32(), 'Read check failed');  // 5
        Assert.AreEqual(0, DotNet_BinaryReader.ReadInt32(), 'Read check failed'); // 0
        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteDecimal()
    var
        DecimalArray: array[13] of Decimal;
        Index: Integer;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteDecimalTest
        DecimalArray[1] := 1;
        DecimalArray[2] := 0;
        DecimalArray[3] := -1;
        DecimalArray[4] := -999999999999999.99;
        DecimalArray[5] := 999999999999999.99;
        DecimalArray[6] := -1000.5;
        DecimalArray[7] := Power(-10.0, -40);
        DecimalArray[8] := Power(3.4, -40898);
        DecimalArray[9] := Power(3.4, -28);
        DecimalArray[10] := Power(3.4, 28);
        DecimalArray[11] := 0.45;
        DecimalArray[12] := 5.55;
        DecimalArray[13] := Power(3.4899, 23);

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(DecimalArray) do
            DotNet_BinaryWriter.WriteDecimal(DecimalArray[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(DecimalArray) do
            Assert.AreEqual(DecimalArray[Index], DotNet_BinaryReader.ReadDecimal(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteInt16()
    var
        Int16Array: array[7] of Integer;
        Index: Integer;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteInt16Test
        Int16Array[1] := -32768;
        Int16Array[2] := 32767;
        Int16Array[3] := 0;
        Int16Array[4] := -10000;
        Int16Array[5] := 10000;
        Int16Array[6] := -50;
        Int16Array[7] := 50;

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(Int16Array) do
            DotNet_BinaryWriter.WriteInt16(Int16Array[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(Int16Array) do
            Assert.AreEqual(Int16Array[Index], DotNet_BinaryReader.ReadInt16(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteInt32()
    var
        Int32Array: array[7] of Integer;
        Index: Integer;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteInt32Test
        Int32Array[1] := -2147483647;
        Int32Array[1] := Int32Array[1] - 1;
        Int32Array[2] := 2147483647;
        Int32Array[3] := 0;
        Int32Array[4] := -10000;
        Int32Array[5] := 10000;
        Int32Array[6] := -50;
        Int32Array[7] := 50;

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(Int32Array) do
            DotNet_BinaryWriter.WriteInt32(Int32Array[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(Int32Array) do
            Assert.AreEqual(Int32Array[Index], DotNet_BinaryReader.ReadInt32(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteUInt16()
    var
        Unsignedint16Array: array[7] of Integer;
        Index: Integer;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteUInt16Test
        Unsignedint16Array[1] := 0;
        Unsignedint16Array[2] := 65535;
        Unsignedint16Array[3] := 0;
        Unsignedint16Array[4] := 100;
        Unsignedint16Array[5] := 1000;
        Unsignedint16Array[6] := 10000;
        Unsignedint16Array[7] := 65535 - 100;

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(Unsignedint16Array) do
            DotNet_BinaryWriter.WriteUInt16(Unsignedint16Array[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(Unsignedint16Array) do
            Assert.AreEqual(Unsignedint16Array[Index], DotNet_BinaryReader.ReadUInt16(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteUInt32()
    var
        Unsignedint32Array: array[7] of Integer;
        Index: Integer;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteUInt32Test
        Unsignedint32Array[1] := 0;
        Unsignedint32Array[2] := 2147483647;
        Unsignedint32Array[3] := 0;
        Unsignedint32Array[4] := 100;
        Unsignedint32Array[5] := 1000;
        Unsignedint32Array[6] := 10000;
        Unsignedint32Array[7] := 2147483647 - 100;

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(Unsignedint32Array) do
            DotNet_BinaryWriter.WriteUInt32(Unsignedint32Array[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(Unsignedint32Array) do
            Assert.AreEqual(Unsignedint32Array[Index], DotNet_BinaryReader.ReadUInt32(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWriteString()
    var
        DotNet_StringBuilder: Codeunit DotNet_StringBuilder;
        StringArray: array[10] of Text;
        Index: Integer;
        String: Text;
        TempChar: Char;
    begin
        DotNet_SeekOrigin.SeekBegin();

        // Based on https://github.com/dotnet/corefx/ BinaryWriter.WriteTests.cs BinaryWriter_WriteStringTest
        DotNet_StringBuilder.InitStringBuilder('');
        for Index := 1 to 5 do
            DotNet_StringBuilder.Append('abc');
        String := DotNet_StringBuilder.ToString();

        StringArray[1] := 'ABC';
        TempChar := 9;
        StringArray[2] := '';
        StringArray[2] += Format(TempChar);
        StringArray[2] += Format(TempChar);
        TempChar := 10;
        StringArray[2] += Format(TempChar);
        StringArray[2] += Format(TempChar);
        StringArray[2] += Format(TempChar);
        TempChar := 0;
        StringArray[2] += Format(TempChar);
        TempChar := 13;
        StringArray[2] += Format(TempChar);
        StringArray[2] += Format(TempChar);
        TempChar := 11;
        StringArray[2] += Format(TempChar);
        StringArray[2] += Format(TempChar);
        TempChar := 9;
        StringArray[2] += Format(TempChar);
        TempChar := 0;
        StringArray[2] += Format(TempChar);
        TempChar := 13;
        StringArray[2] += Format(TempChar);
        StringArray[2] += 'Hello';
        StringArray[3] := 'This is a normal string';
        StringArray[4] := '12345667789!@#$%^&&())_+_)@#';
        StringArray[5] := 'ABSDAFJPIRUETROPEWTGRUOGHJDOLJHLDHWEROTYIETYWsdifhsiudyoweurscnkjhdfusiyugjlskdjfoiwueriye';
        StringArray[6] := '     ';
        StringArray[7] := '';
        TempChar := 0;
        StringArray[7] += Format(TempChar);
        StringArray[7] += Format(TempChar);
        StringArray[7] += Format(TempChar);
        TempChar := 9;
        StringArray[7] += Format(TempChar);
        StringArray[7] += Format(TempChar);
        StringArray[7] += Format(TempChar);
        StringArray[7] += 'Hey""';
        StringArray[8] := '';
        TempChar := 37;
        StringArray[8] += Format(TempChar);
        TempChar := 17;
        StringArray[8] += Format(TempChar);
        StringArray[9] := String;
        StringArray[10] := '';

        CreateStream();
        DotNet_BinaryWriter.BinaryWriter(DotNet_Stream);
        DotNet_BinaryReader.BinaryReader(DotNet_Stream);
        for Index := 1 to ArrayLen(StringArray) do
            DotNet_BinaryWriter.WriteString(StringArray[Index]);

        DotNet_BinaryWriter.Flush();
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);

        for Index := 1 to ArrayLen(StringArray) do
            Assert.AreEqual(StringArray[Index], DotNet_BinaryReader.ReadString(), 'Read check failed');

        DotNet_BinaryReader.Close();
        DotNet_BinaryWriter.Close();
        DotNet_BinaryReader.Dispose();
        DotNet_BinaryWriter.Dispose();
    end;

    local procedure CreateStream()
    var
        DotNetStream: DotNet Stream;
    begin
        DotNet_MemoryStream.MemoryStream();
        DotNet_MemoryStream.GetMemoryStream(DotNetStream);
        DotNet_Stream.SetStream(DotNetStream);
    end;

    local procedure CheckArrayItems(var Actual_DotNet_Array: Codeunit DotNet_Array; var Expected_DotNet_Array: Codeunit DotNet_Array)
    var
        DotNetActualArray: DotNet Array;
        DotNetExpectedArray: DotNet Array;
        Index: Integer;
    begin
        Actual_DotNet_Array.GetArray(DotNetActualArray);
        Expected_DotNet_Array.GetArray(DotNetExpectedArray);
        for Index := 0 to DotNetActualArray.Length - 1 do
            Assert.AreEqual(DotNetExpectedArray.GetValue(Index), DotNetActualArray.GetValue(Index), 'Array item check failed');
    end;
}

