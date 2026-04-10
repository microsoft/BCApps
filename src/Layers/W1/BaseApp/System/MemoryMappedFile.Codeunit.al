namespace System.IO;

using System;
using System.Reflection;
using System.Utilities;

codeunit 491 "Memory Mapped File"
{

    trigger OnRun()
    begin
    end;

    var
        MemoryMappedFile: DotNet MemoryMappedFile;
        MemFileName: Text;
        NoNameSpecifiedErr: Label 'You need to specify a name for the memory mapped file.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure CreateMemoryMappedFileFromTempBlob(var TempBlob: Codeunit "Temp Blob"; Name: Text)
    var
        MemoryMappedViewStream: DotNet MemoryMappedViewStream;
        InStream: InStream;
    begin
        // clean up previous use
        if not IsNull(MemoryMappedFile) then
            if Dispose() then;
        if not TempBlob.HasValue() then
            exit;

        MemFileName := Name;
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        MemoryMappedFile := MemoryMappedFile.CreateOrOpen(Name, TempBlob.Length());
        MemoryMappedViewStream := MemoryMappedFile.CreateViewStream();
        CopyStream(MemoryMappedViewStream, InStream);
        MemoryMappedViewStream.Flush();
        MemoryMappedViewStream.Dispose();
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure OpenMemoryMappedFile(Name: Text)
    begin
        if Name = '' then
            Error(NoNameSpecifiedErr);
        MemFileName := Name;
        MemoryMappedFile := MemoryMappedFile.OpenExisting(MemFileName);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ReadTextFromMemoryMappedFile(var Text: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        MemoryMappedViewStream: DotNet MemoryMappedViewStream;
    begin
        if MemFileName = '' then
            Error(NoNameSpecifiedErr);

        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF8);
        MemoryMappedViewStream := MemoryMappedFile.CreateViewStream();
        MemoryMappedViewStream.CopyTo(InStr);
        InStr.ReadText(Text);
        MemoryMappedViewStream.Dispose();
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ReadTextWithSeparatorsFromMemoryMappedFile(var Text: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        MemoryMappedViewStream: DotNet MemoryMappedViewStream;
    begin
        if MemFileName = '' then
            Error(NoNameSpecifiedErr);
        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF8);
        MemoryMappedViewStream := MemoryMappedFile.CreateViewStream();
        MemoryMappedViewStream.CopyTo(InStr);

        Text := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        Text := DelChr(Text, '>', TypeHelper.LFSeparator());
        MemoryMappedViewStream.Dispose();
    end;

    [Scope('OnPrem')]
    procedure GetName(): Text
    begin
        exit(MemFileName);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure Dispose()
    begin
        MemoryMappedFile.Dispose();
        MemFileName := '';
    end;
}

