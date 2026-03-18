codeunit 146034 Test_DotNet_StreamAndBuffer
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [StreamAndBuffer]
    end;

    var
        Assert: Codeunit Assert;
        DotNet_Buffer: Codeunit DotNet_Buffer;
        DotNet_Stream: Codeunit DotNet_Stream;
        DotNet_MemoryStream: Codeunit DotNet_MemoryStream;
        Byte_DotNet_Array: Codeunit DotNet_Array;
        ExpectedByte_DotNet_Array: Codeunit DotNet_Array;
        DotNet_SeekOrigin: Codeunit DotNet_SeekOrigin;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadingWritingUsingMemoryStream()
    begin
        CreateStream();
        Assert.AreEqual(true, DotNet_Stream.CanRead(), 'CanRead check failed');
        Assert.AreEqual(true, DotNet_Stream.CanWrite(), 'CanWrite check failed');
        Assert.AreEqual(true, DotNet_Stream.CanSeek(), 'CanSeek check failed');
        Assert.AreEqual(false, DotNet_Stream.IsDotNetNull(), 'Null check failed');
        DotNet_Stream.WriteByte(1);
        CreateExampleByteArray();
        DotNet_Stream.Write(Byte_DotNet_Array, 0, 4);
        // Seek to the start of stream but skip first byte
        DotNet_SeekOrigin.SeekBegin();
        DotNet_Stream.Seek(1, DotNet_SeekOrigin);
        ClearActualArray();
        DotNet_Stream.Read(Byte_DotNet_Array, 0, 4);
        CheckArrayItems(Byte_DotNet_Array, ExpectedByte_DotNet_Array);
        DotNet_Stream.Seek(0, DotNet_SeekOrigin);
        Assert.AreEqual(1, DotNet_Stream.ReadByte(), 'ReadByte check failed');
        DotNet_Stream.Close();
        DotNet_Stream.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadingWritingUsingTempBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        InputData: InStream;
        OutputData: OutStream;
    begin
        TempBlob.CreateOutStream(OutputData);
        DotNet_Stream.FromOutStream(OutputData);
        Assert.AreEqual(true, DotNet_Stream.CanRead(), 'CanRead check failed');
        Assert.AreEqual(true, DotNet_Stream.CanWrite(), 'CanWrite check failed');
        Assert.AreEqual(true, DotNet_Stream.CanSeek(), 'CanSeek check failed');
        Assert.AreEqual(false, DotNet_Stream.IsDotNetNull(), 'Null check failed');
        DotNet_Stream.WriteByte(1);
        CreateExampleByteArray();
        DotNet_Stream.Write(Byte_DotNet_Array, 0, 4);
        DotNet_Stream.Close();
        DotNet_Stream.Dispose();
        TempBlob.CreateInStream(InputData);
        DotNet_Stream.FromInStream(InputData);
        Assert.AreEqual(true, DotNet_Stream.CanRead(), 'CanRead check failed');
        Assert.AreEqual(true, DotNet_Stream.CanWrite(), 'CanWrite check failed');
        Assert.AreEqual(true, DotNet_Stream.CanSeek(), 'CanSeek check failed');
        Assert.AreEqual(false, DotNet_Stream.IsDotNetNull(), 'Null check failed');
        Assert.AreEqual(1, DotNet_Stream.ReadByte(), 'ReadByte check failed');
        ClearActualArray();
        DotNet_Stream.Read(Byte_DotNet_Array, 0, 4);
        CheckArrayItems(Byte_DotNet_Array, ExpectedByte_DotNet_Array);
        DotNet_Stream.Close();
        DotNet_Stream.Dispose();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBufferMethods()
    var
        DotNetString: Codeunit DotNet_String;
        Char_DotNet_Array: Codeunit DotNet_Array;
        TestChar: Char;
    begin
        TestChar := 261;
        DotNetString.Set(Format(TestChar) + Format(TestChar));
        DotNetString.ToCharArray(0, 2, Char_DotNet_Array);
        Assert.AreEqual(4, DotNet_Buffer.ByteLength(Char_DotNet_Array), 'ByteLength check failed');
        CreateExampleByteArray();
        Assert.AreEqual(10, DotNet_Buffer.GetByte(Byte_DotNet_Array, 0), 'GetByte Check failed');
        Assert.AreEqual(11, DotNet_Buffer.GetByte(Byte_DotNet_Array, 1), 'GetByte Check failed');
        Assert.AreEqual(12, DotNet_Buffer.GetByte(Byte_DotNet_Array, 2), 'GetByte Check failed');
        Assert.AreEqual(13, DotNet_Buffer.GetByte(Byte_DotNet_Array, 3), 'GetByte Check failed');
        Assert.AreEqual(5, DotNet_Buffer.GetByte(Char_DotNet_Array, 0), 'GetByte Check failed');
        Assert.AreEqual(1, DotNet_Buffer.GetByte(Char_DotNet_Array, 1), 'GetByte Check failed');
        Assert.AreEqual(5, DotNet_Buffer.GetByte(Char_DotNet_Array, 2), 'GetByte Check failed');
        Assert.AreEqual(1, DotNet_Buffer.GetByte(Char_DotNet_Array, 3), 'GetByte Check failed');

        DotNet_Buffer.BlockCopy(Char_DotNet_Array, 0, Byte_DotNet_Array, 0, 4);
        Assert.AreEqual(5, DotNet_Buffer.GetByte(Byte_DotNet_Array, 0), 'GetByte Check failed');
        Assert.AreEqual(1, DotNet_Buffer.GetByte(Byte_DotNet_Array, 1), 'GetByte Check failed');
        Assert.AreEqual(5, DotNet_Buffer.GetByte(Byte_DotNet_Array, 2), 'GetByte Check failed');
        Assert.AreEqual(1, DotNet_Buffer.GetByte(Byte_DotNet_Array, 3), 'GetByte Check failed');
        DotNet_Buffer.SetByte(Byte_DotNet_Array, 0, 15);
        Assert.AreEqual(15, DotNet_Buffer.GetByte(Byte_DotNet_Array, 0), 'GetByte Check failed');
    end;

    local procedure CreateStream()
    var
        DotNetStream: DotNet Stream;
    begin
        DotNet_MemoryStream.MemoryStream();
        DotNet_MemoryStream.GetMemoryStream(DotNetStream);
        DotNet_Stream.SetStream(DotNetStream);
    end;

    local procedure CreateExampleByteArray()
    var
        DotNetArray: DotNet Array;
        DotNetByte: DotNet Byte;
        DotNetConvert: DotNet Convert;
        DotNetByteType: DotNet Type;
    begin
        DotNetByteType := GetDotNetType(DotNetByte);
        DotNetArray := DotNetArray.CreateInstance(DotNetByteType, 4);
        DotNetByte := DotNetConvert.ChangeType(10, DotNetByteType);
        DotNetArray.SetValue(DotNetByte, 0);
        DotNetByte := DotNetConvert.ChangeType(11, DotNetByteType);
        DotNetArray.SetValue(DotNetByte, 1);
        DotNetByte := DotNetConvert.ChangeType(12, DotNetByteType);
        DotNetArray.SetValue(DotNetByte, 2);
        DotNetByte := DotNetConvert.ChangeType(13, DotNetByteType);
        DotNetArray.SetValue(DotNetByte, 3);
        Byte_DotNet_Array.SetArray(DotNetArray);
        ExpectedByte_DotNet_Array.SetArray(DotNetArray);
    end;

    local procedure ClearActualArray()
    var
        DotNetArray: DotNet Array;
        DotNetByte: DotNet Byte;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(DotNetByte), 4);
        Byte_DotNet_Array.SetArray(DotNetArray);
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

