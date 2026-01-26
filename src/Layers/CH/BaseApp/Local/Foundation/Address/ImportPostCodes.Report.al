// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using System.IO;
using System.Utilities;

report 11502 "Import Post Codes"
{
    Caption = 'Import Post Codes';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FileManagement: Codeunit "File Management";
        TempServerFilePath: Text;
    begin
        if FileName = '' then
            TempServerFilePath := FileManagement.UploadFile(TitleTxt, '*.*')
        else
            TempServerFilePath := FileName;
        if TempServerFilePath = '' then
            Error('');
        if not Confirm(EntriesWillBeDeletedQst, true) then
            Error('');
        ImportPostCodes(TempServerFilePath);
        FileManagement.DeleteServerFile(TempServerFilePath);
        Message(ImportSuccessfulMsg);
    end;

    var
        EntriesWillBeDeletedQst: Label 'The existing entries in the range of 1000 to 9999 will be deleted before the import. Do you want to continue?';
        PostCode: Record "Post Code";
        ImportSuccessfulMsg: Label 'The new post codes have been successfully imported.';
        FileName: Text;
        TitleTxt: Label 'Upload CSV or ZIP file';
        StatusMsg: Label 'Number of post codes imported: #1#########', Comment = '#1##: Number of imported post codes';

    [Scope('OnPrem')]
    procedure ImportPostCodes(TempServerFilePath: Text)
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        EntryList: List of [Text];
        OutStream: OutStream;
        OriginalInStream: InStream;
        ExtractedInStream: InStream;
        TempServerFile: File;
        Window: Dialog;
        NumberOfPostCodes: Integer;
    begin
        Window.Open(StatusMsg);
        PostCode.Reset();
        PostCode.SetRange(Code, '1000', '9999');
        PostCode.DeleteAll();
        PostCode.Reset();

        TempServerFile.Open(TempServerFilePath);
        TempServerFile.CreateInStream(OriginalInStream);
        if FileManagement.GetExtension(TempServerFilePath) <> 'zip' then
            TempCSVBuffer.InitializeReaderFromStream(OriginalInStream, ';')
        else begin
            DataCompression.OpenZipArchive(OriginalInStream, false);
            DataCompression.GetEntryList(EntryList);
            if EntryList.Count() > 0 then begin
                TempBlob.CreateOutStream(OutStream);
                DataCompression.ExtractEntry(EntryList.Get(1), OutStream);
                TempBlob.CreateInStream(ExtractedInStream);
                TempCSVBuffer.InitializeReaderFromStream(ExtractedInStream, ';');
                DataCompression.CloseZipArchive()
            end
        end;

        while TempCSVBuffer.ReadLines(100) do begin
            TempCSVBuffer.SetRange("Field No.", 1);
            TempCSVBuffer.SetFilter(Value, '1000..9999');
            if TempCSVBuffer.FindSet() then
                repeat
                    PostCode.Init();
                    PostCode.Code := CopyStr(TempCSVBuffer.GetValueOfLineAt(1), 1, 20);
                    PostCode.City := CopyStr(TempCSVBuffer.GetValueOfLineAt(2), 1, 30);
                    PostCode."Search City" := PostCode.City;
                    PostCode.County := CopyStr(TempCSVBuffer.GetValueOfLineAt(3), 1, 30);
                    PostCode.Insert();
                    NumberOfPostCodes += 1;
                    if NumberOfPostCodes mod 10 = 0 then
                        Window.Update(1, Format(NumberOfPostCodes));
                until TempCSVBuffer.Next() = 0
            else
                exit;
            TempCSVBuffer.ResetFilters();
            TempCSVBuffer.DeleteAll();
        end;
        TempServerFile.Close();
        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(ServerFileName: Text)
    begin
        FileName := ServerFileName;
    end;
}

