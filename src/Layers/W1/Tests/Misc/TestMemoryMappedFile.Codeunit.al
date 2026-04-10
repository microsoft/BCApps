codeunit 134690 "Test Memory Mapped File"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Memory Mapped File]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure CreateMemoryMappedFileFromTempBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        MemoryMappedFile: Codeunit "Memory Mapped File";
        OutStream: OutStream;
        Name: Text;
        Value: Text;
        ValueRead: Text;
    begin
        // Init
        LibraryLowerPermissions.SetO365Basic();
        Name := Format(CreateGuid());
        Value := '<doc>' + Format(CreateGuid()) + '</doc>'; // Expects an xml

        // Execute
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(Value);
        MemoryMappedFile.CreateMemoryMappedFileFromTempBlob(TempBlob, Name);
        MemoryMappedFile.ReadTextFromMemoryMappedFile(ValueRead);

        // Verify
        Assert.AreEqual(Value, ValueRead, 'Wrong value returned');
        Assert.AreEqual(Name, MemoryMappedFile.GetName(), 'Wrong name');
        MemoryMappedFile.Dispose();
        Assert.AreEqual('', MemoryMappedFile.GetName(), 'Wrong name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetName()
    var
        MemoryMappedFile: Codeunit "Memory Mapped File";
        Value: Text;
    begin
        // Init
        LibraryLowerPermissions.SetO365Basic();
        Value := '';

        // Verify
        Assert.AreEqual('', MemoryMappedFile.GetName(), 'Wrong name');
        asserterror MemoryMappedFile.ReadTextFromMemoryMappedFile(Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadMemoryMappedFileWithLFSeparatorFromTempBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        MemoryMappedFile: Codeunit "Memory Mapped File";
        TypeHelper: Codeunit "Type Helper";
        OutStream: OutStream;
        Value: Text;
        ValueRead: Text;
    begin
        // [SCENARIO 390224] Test reading from memory mapped file that contains LF separators
        // [GIVEN] Text with LF line separators place in blob and memory mapped file
        LibraryLowerPermissions.SetO365Basic();
        Value := '<doc>' + Format(CreateGuid()) + TypeHelper.LFSeparator() + Format(CreateGuid()) + '</doc>'; // Expects an xml

        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(Value);
        MemoryMappedFile.CreateMemoryMappedFileFromTempBlob(TempBlob, Format(CreateGuid()));

        // [WHEN] Text is read back from memory mapped file
        MemoryMappedFile.ReadTextWithSeparatorsFromMemoryMappedFile(ValueRead);

        // [THEN] Text value is equal to initial text put in memory mapped file
        Assert.AreEqual(Value, ValueRead, 'Wrong value returned');
        MemoryMappedFile.Dispose();
    end;
}

