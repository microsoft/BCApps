namespace System.Utilities;

using System.Environment;

codeunit 9755 "Media Resources Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure InsertMediaFromInstream(MediaResourceCode: Code[50]; MediaInstream: InStream): Boolean
    var
        MediaResources: Record "Media Resources";
    begin
        if MediaResources.Get(MediaResourceCode) then
            exit(true);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourceCode);
        MediaResources."Media Reference".ImportStream(MediaInstream, MediaResourceCode);
        exit(MediaResources.Insert(true));
    end;

    procedure InsertMediaFromFile(MediaResourceCode: Code[50]; FileName: Text): Boolean
    var
        MediaResources: Record "Media Resources";
    begin
        if MediaResources.Get(MediaResourceCode) then
            exit(true);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourceCode);
        MediaResources."Media Reference".ImportFile(FileName, MediaResourceCode);
        exit(MediaResources.Insert(true));
    end;

    procedure InsertMediaSetFromFile(MediaResourceCode: Code[50]; FileName: Text): Boolean
    var
        MediaResources: Record "Media Resources";
    begin
        if MediaResources.Get(MediaResourceCode) then
            exit(true);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourceCode);
        MediaResources."MediaSet Reference".ImportFile(FileName, MediaResourceCode);
        exit(MediaResources.Insert(true));
    end;

    procedure InsertBLOBFromFile(FilePath: Text; FileName: Text): Code[50]
    var
        MediaResources: Record "Media Resources";
        File: File;
        BLOBInStream: InStream;
        BLOBOutStream: OutStream;
        MediaResourceCode: Code[50];
    begin
        MediaResourceCode := CopyStr(FileName, 1, MaxStrLen(MediaResourceCode));
        if MediaResources.Get(MediaResourceCode) then
            exit(MediaResourceCode);

        if not File.Open(FilePath + FileName) then
            exit('');
        File.CreateInStream(BLOBInStream);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourceCode);
        MediaResources.Blob.CreateOutStream(BLOBOutStream);
        CopyStream(BLOBOutStream, BLOBInStream);
        File.Close();
        MediaResources.Insert(true);

        exit(MediaResourceCode);
    end;

    procedure InsertBlobFromText(MediaResourcesCode: Code[50]; BlobContent: Text): Boolean
    var
        MediaResources: Record "Media Resources";
        TextOutStream: OutStream;
    begin
        if MediaResources.Get(MediaResourcesCode) then
            exit(true);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourcesCode);
        MediaResources.Blob.CreateOutStream(TextOutStream, TEXTENCODING::UTF8);
        TextOutStream.Write(BlobContent);

        exit(MediaResources.Insert(true));
    end;

    procedure ReadTextFromMediaResource(MediaResourcesCode: Code[50]) MediaText: Text
    var
        MediaResources: Record "Media Resources";
        TextInStream: InStream;
    begin
        if not MediaResources.Get(MediaResourcesCode) then
            exit;

        MediaResources.CalcFields(Blob);
        MediaResources.Blob.CreateInStream(TextInStream, TEXTENCODING::UTF8);
        TextInStream.Read(MediaText);
    end;
}

