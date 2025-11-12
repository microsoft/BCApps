// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using Microsoft.Utilities;
using System;

codeunit 705 "Stream Management"
{

    trigger OnRun()
    begin
    end;

    var
        MemoryStream: DotNet MemoryStream;

    procedure MtomStreamToXmlStream(MtomStream: InStream; var XmlStream: InStream; ContentType: Text)
    var
        TextEncoding: DotNet Encoding;
        DotNetArray: DotNet Array;
        XmlDocument: DotNet XmlDocument;
        XmlDictionaryReader: DotNet XmlDictionaryReader;
        XmlDictionaryReaderQuotas: DotNet XmlDictionaryReaderQuotas;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(TextEncoding), 1);
        DotNetArray.SetValue(TextEncoding.UTF8, 0);
        XmlDictionaryReader := XmlDictionaryReader.CreateMtomReader(MtomStream, DotNetArray, ContentType, XmlDictionaryReaderQuotas.Max);
        XmlDictionaryReader.MoveToContent();

        XmlDocument := XmlDocument.XmlDocument();
        XmlDocument.PreserveWhitespace := true;
        XmlDocument.Load(XmlDictionaryReader);
        MemoryStream := MemoryStream.MemoryStream();
        XmlDocument.Save(MemoryStream);
        MemoryStream.Position := 0;
        XmlStream := MemoryStream;
    end;

    [TryFunction]
    procedure CreateNameValueBufferFromZipFileStream(Stream: InStream; var NameValueBufferOut: Record "Name/Value Buffer")
    var
        ZipArchive: DotNet ZipArchive;
        FileList: DotNet GenericIReadOnlyList1;
        ZipArchiveEntry: DotNet ZipArchiveEntry;
        FileStream: InStream;
        out: OutStream;
        NrFiles: Integer;
        I: Integer;
        LastId: Integer;
    begin
        ZipArchive := ZipArchive.ZipArchive(Stream);
        NrFiles := ZipArchive.Entries.Count();
        FileList := ZipArchive.Entries;
        for I := 0 to NrFiles - 1 do begin
            if NameValueBufferOut.FindLast() then
                LastId := NameValueBufferOut.ID;
            ZipArchiveEntry := FileList.Item(I);
            FileStream := ZipArchiveEntry.Open();
            NameValueBufferOut.ID := LastId + 1;
            NameValueBufferOut.Name := CopyStr(ZipArchiveEntry.Name, 1, 250);
            NameValueBufferOut."Value BLOB".CreateOutStream(out);
            CopyStream(out, FileStream);
            NameValueBufferOut.Insert();
        end;
    end;
}

