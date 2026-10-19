// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Utilities;

/// <summary>
/// The document a Payables Agent v2 task works on.
/// </summary>
table 3330 "Payables Agent Task Data"
{
    Caption = 'Payables Agent Task Data';
    Access = Internal;
    DataClassification = CustomerContent;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        #region Pdf
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(11; "File Content"; Media)
        {
            Caption = 'File Content';
            DataClassification = CustomerContent;
        }
        field(12; "File Content As Text"; Blob)
        {
            Caption = 'File Content As Text';
            DataClassification = CustomerContent;
        }
        #endregion
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure GetFileContent(var TempBlob: Codeunit "Temp Blob")
    var
        FileOutStream: OutStream;
    begin
        if not Rec."File Content".HasValue() then
            Error(NoFileContentErr);
        TempBlob.CreateOutStream(FileOutStream);
        Rec."File Content".ExportStream(FileOutStream);
    end;

    procedure DownloadFileContent()
    var
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileName: Text;
    begin
        GetFileContent(TempBlob);
        TempBlob.CreateInStream(FileInStream);
        FileName := Rec."File Name";
        DownloadFromStream(FileInStream, '', '', '', FileName);
    end;

    /// <summary>
    /// Opens the file in the client's file viewer, falling back to a download when the client cannot show it.
    /// </summary>
    procedure ViewFileContent()
    var
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileName: Text;
    begin
        GetFileContent(TempBlob);
        TempBlob.CreateInStream(FileInStream);
        if File.ViewFromStream(FileInStream, Rec."File Name", true) then
            exit;
        TempBlob.CreateInStream(FileInStream);
        FileName := Rec."File Name";
        DownloadFromStream(FileInStream, '', '', '', FileName);
    end;

    procedure HasFileContentAsText(): Boolean
    begin
        Rec.CalcFields("File Content As Text");
        exit(Rec."File Content As Text".HasValue());
    end;

    procedure GetFileContentAsText() FileContentAsText: Text
    var
        TextInStream: InStream;
    begin
        if not HasFileContentAsText() then
            exit('');
        Rec."File Content As Text".CreateInStream(TextInStream, TextEncoding::UTF8);
        TextInStream.Read(FileContentAsText);
    end;

    procedure SetFileContentAsText(NewFileContentAsText: Text)
    var
        TextOutStream: OutStream;
    begin
        Clear(Rec."File Content As Text");
        Rec."File Content As Text".CreateOutStream(TextOutStream, TextEncoding::UTF8);
        TextOutStream.WriteText(NewFileContentAsText);
    end;

    var
        NoFileContentErr: Label 'There is no file to show.';
}
