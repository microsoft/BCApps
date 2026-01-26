// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Reporting;
using System.IO;
using System.Utilities;

codeunit 12185 "Export Self-Billing Documents"
{
    Permissions = TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        SelfBillingDocumentNotExportedErr: Label 'The self-billing document has not been created.';
        MultipleEntriesQst: Label 'There are multiple VAT entries for the selected document. Do you want to export all?';

    procedure Run(var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        ExportSelfBillingDocuments(TempBlob, ClientFileName, SelectedVATEntry, AllVATEntry);
        ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientFileName);
    end;

    procedure RunWithFileNameSave(var ServerFilePath: Text[250]; var ClientFileName: Text[250]; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FilePath: Text;
    begin
        RunWithStreamSave(TempBlob, ClientFileName, SelectedVATEntry, AllVATEntry);
        FilePath := FileManagement.ServerTempFileName(FileManagement.GetExtension(ClientFileName));
        FileManagement.BLOBExportToServerFile(TempBlob, FilePath);
        ServerFilePath := CopyStr(FilePath, 1, MaxStrLen(ServerFilePath));
    end;

    procedure RunWithStreamSave(var TempBlob: Codeunit "Temp Blob"; var ClientFileName: Text[250]; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    begin
        ExportSelfBillingDocuments(TempBlob, ClientFileName, SelectedVATEntry, AllVATEntry);
    end;

    local procedure ExportSelfBillingDocuments(var TempBlob: Codeunit "Temp Blob"; var ClientFileName: Text[250]; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        TempVATEntry: Record "VAT Entry" temporary;
        RecordExportBuffer: Record "Record Export Buffer";
        TempErrorMessage: Record "Error Message" temporary;
        DataCompression: Codeunit "Data Compression";
        EntryTempBlob: Codeunit "Temp Blob";
        ServerTempFileInStream: InStream;
        ZipFileOutStream: OutStream;
        IsMissingFileContent: Boolean;
        StartID: Integer;
        EndID: Integer;
    begin
        SelectedVATEntry.SetCurrentKey("Document No.", "Posting Date", "Unrealized VAT Entry No.");
        if SelectedVATEntry.FindSet() then
            repeat
                CopyVATEntriesByDocNoAndPostingDateToBuffer(TempVATEntry, SelectedVATEntry, AllVATEntry);
                DoExport(TempVATEntry, TempErrorMessage, RecordExportBuffer);
                if not RecordExportBuffer."File Content".HasValue() then
                    IsMissingFileContent := true;
                if StartID = 0 then
                    StartID := RecordExportBuffer.ID;
                EndID := RecordExportBuffer.ID;
            until SelectedVATEntry.Next() = 0;

        TempErrorMessage.ShowErrorMessages(true);
        if IsMissingFileContent then
            Error(SelfBillingDocumentNotExportedErr);

        RecordExportBuffer.SetRange(ID, StartID, EndID);
        if RecordExportBuffer.Count > 1 then begin
            ClientFileName := CopyStr(RecordExportBuffer.ZipFileName, 1, 250);
            TempBlob.CreateOutStream(ZipFileOutStream);
            DataCompression.CreateZipArchive();
            RecordExportBuffer.FindSet();
            repeat
                RecordExportBuffer.GetFileContent(EntryTempBlob);
                EntryTempBlob.CreateInStream(ServerTempFileInStream);
                DataCompression.AddEntry(ServerTempFileInStream, RecordExportBuffer.ClientFileName);
            until RecordExportBuffer.Next() = 0;
            DataCompression.SaveZipArchive(ZipFileOutStream);
            DataCompression.CloseZipArchive();
        end else
            if RecordExportBuffer.FindFirst() then begin
                RecordExportBuffer.GetFileContent(TempBlob);
                ClientFileName := RecordExportBuffer.ClientFileName;
            end;

        RecordExportBuffer.DeleteAll();
    end;

    local procedure CopyVATEntriesByDocNoAndPostingDateToBuffer(var TempVATEntry: Record "VAT Entry" temporary; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        HeaderEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.DeleteAll();
        SelectedVATEntry.SetRange("Document No.", SelectedVATEntry."Document No.");
        SelectedVATEntry.SetRange("Posting Date", SelectedVATEntry."Posting Date");
        repeat
            TempVATEntry := SelectedVATEntry;
            TempVATEntry.Insert();
            if TempVATEntry."Related Entry No." = 0 then
                HeaderEntryNo := TempVATEntry."Entry No.";
        until SelectedVATEntry.Next() = 0;

        SelectedVATEntry.CopyFilter("Document No.", AllVATEntry."Document No.");
        SelectedVATEntry.CopyFilter("Posting Date", AllVATEntry."Posting Date");
        AllVATEntry.SetRange("Related Entry No.", HeaderEntryNo);
        if not AllVATEntry.IsEmpty() then
            if Confirm(MultipleEntriesQst, false) then begin
                AllVATEntry.FindSet();
                repeat
                    TempVATEntry := AllVATEntry;
                    if TempVATEntry.Insert() then;
                until AllVATEntry.Next() = 0;
            end;
        AllVATEntry.SetRange("Related Entry No.");

        SelectedVATEntry.SetRange("Document No.");
        SelectedVATEntry.SetRange("Posting Date");
    end;

    local procedure DoExport(var TempVATEntry: Record "VAT Entry" temporary; var TempErrorMessage: Record "Error Message" temporary; var RecordExportBuffer: Record "Record Export Buffer")
    var
        ErrorMessage: Record "Error Message";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        ExportFatturaPADocument: Codeunit "Export FatturaPA Document";
        TempBlob: Codeunit "Temp Blob";
    begin
        ErrorMessage.SetContext(TempVATEntry);
        ErrorMessage.ClearLog();

        FatturaDocHelper.InitializeErrorLog(TempVATEntry);
        FatturaDocHelper.CollectSelfBillingDocInformation(TempFatturaHeader, TempFatturaLine, TempVATEntry);

        Clear(RecordExportBuffer);
        RecordExportBuffer.RecordID := TempVATEntry.RecordId;
        if not FatturaDocHelper.HasErrors() then begin
            RecordExportBuffer.ClientFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.xml';
            RecordExportBuffer.ZipFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.zip';
            ExportFatturaPADocument.GenerateXMLFile(TempBlob, TempFatturaLine, TempFatturaHeader, RecordExportBuffer.ClientFileName);
            RecordExportBuffer.SetFileContent(TempBlob);
        end;
        RecordExportBuffer.Insert(true);
        MarkVATEntryAsExported(TempVATEntry);

        TempErrorMessage.CopyFromContext(TempVATEntry);
        ErrorMessage.ClearLog();
    end;

    local procedure MarkVATEntryAsExported(var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATEntry: Record "VAT Entry";
    begin
        if not VATEntry.Get(TempVATEntry."Entry No.") then
            exit;

        VATEntry."Fattura File Exported" := true;
        VATEntry.Modify();
    end;
}

