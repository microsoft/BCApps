namespace System.IO;

using System;

codeunit 704 "MemoryStream Wrapper"
{

    trigger OnRun()
    begin
    end;

    var
        MemoryStream: DotNet MemoryStream;
        StreamWriter: DotNet StreamWriter;
        StreamReader: DotNet StreamReader;

    procedure Create(Capacity: Integer)
    begin
        MemoryStream := MemoryStream.MemoryStream(Capacity);
    end;

    procedure SetPosition(Position: Integer)
    begin
        MemoryStream.Position := Position;
    end;

    procedure GetPosition(): Integer
    begin
        exit(MemoryStream.Position);
    end;

    procedure CopyTo(OutStream: OutStream)
    begin
        MemoryStream.CopyTo(OutStream);
    end;

    procedure GetInStream(var InStream: InStream)
    begin
        InStream := MemoryStream;
    end;

    procedure ReadFrom(var InStream: InStream)
    begin
        CopyStream(MemoryStream, InStream);
    end;

    procedure ToText(): Text
    begin
        MemoryStream.Position := 0;
        if IsNull(StreamReader) then
            StreamReader := StreamReader.StreamReader(MemoryStream);
        exit(StreamReader.ReadToEnd());
    end;

    procedure AddText(Txt: Text)
    begin
        if IsNull(StreamWriter) then
            StreamWriter := StreamWriter.StreamWriter(MemoryStream);
        StreamWriter.Write(Txt);
        StreamWriter.Flush();
    end;

    procedure Length(): Integer
    begin
        exit(MemoryStream.Length);
    end;
}

