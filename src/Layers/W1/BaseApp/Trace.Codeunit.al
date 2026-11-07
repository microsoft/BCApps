// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Utilities;

using System;
using System.IO;

codeunit 1292 Trace
{

    trigger OnRun()
    begin
    end;

    var
        TraceLogInStream: InStream;
        TraceStreamLogAlreadyInUseErr: Label 'Debug stream logging is already in use.';

    [Scope('OnPrem')]
    procedure LogStreamToTempFile(var ToLogInStream: InStream; Name: Text; var TempBlobTraceLog: Codeunit "Temp Blob") Filename: Text
    var
        FileManagement: Codeunit "File Management";
        OutStream: OutStream;
    begin
        if TempBlobTraceLog.HasValue() then
            if not TraceLogInStream.EOS then
                Error(TraceStreamLogAlreadyInUseErr);

        TempBlobTraceLog.CreateOutStream(OutStream);
        CopyStream(OutStream, ToLogInStream);

        Filename := FileManagement.ServerTempFileName(Name + '.XML');

        FileManagement.BLOBExportToServerFile(TempBlobTraceLog, Filename);

        TempBlobTraceLog.CreateInStream(TraceLogInStream);
        ToLogInStream := TraceLogInStream;
    end;

    [Scope('OnPrem')]
    procedure LogXmlDocToTempFile(var XmlDoc: DotNet XmlDocument; Name: Text) Filename: Text
    var
        FileManagement: Codeunit "File Management";
    begin
        Filename := FileManagement.ServerTempFileName(Name + '.XML');
        FileManagement.IsAllowedPath(Filename, false);

        XmlDoc.Save(Filename);
    end;

    [Scope('OnPrem')]
    procedure LogTextToTempFile(TextToLog: Text; FileName: Text)
    var
        FileManagement: Codeunit "File Management";
        OutStream: OutStream;
        TempFile: File;
    begin
        TempFile.Create(FileManagement.ServerTempFileName(FileName + '.txt'));
        TempFile.CreateOutStream(OutStream);
        OutStream.WriteText(TextToLog);
        TempFile.Close();
    end;
}

