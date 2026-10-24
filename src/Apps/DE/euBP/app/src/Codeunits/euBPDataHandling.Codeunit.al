// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Finance.AuditFileExport;
using System.Utilities;

codeunit 6543 "euBP Data Handling" implements "Audit File Export Data Handling"
{
    var
        LohnLineTxt: Label 'LOHN Payload';
        FibuLineTxt: Label 'FIBU Payload';

    procedure LoadStandardAccounts(StandardAccountType: Enum "Standard Account Type") Result: Boolean
    begin
    end;

    procedure CreateAuditFileExportLines(var AuditFileExportHeader: Record "Audit File Export Header")
    var
        AuditFileExportLine: Record "Audit File Export Line";
        AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
        LineNo: Integer;
    begin
        AuditFileExportLine.SetRange(ID, AuditFileExportHeader.ID);
        AuditFileExportLine.DeleteAll(true);

        AuditFileExportMgt.InsertAuditFileExportLine(
          AuditFileExportLine,
          LineNo,
          AuditFileExportHeader.ID,
          "Audit File Export Data Class"::Custom,
          LohnLineTxt,
          AuditFileExportHeader."Starting Date",
          AuditFileExportHeader."Ending Date");

        AuditFileExportMgt.InsertAuditFileExportLine(
          AuditFileExportLine,
          LineNo,
          AuditFileExportHeader.ID,
          "Audit File Export Data Class"::Custom,
          FibuLineTxt,
          AuditFileExportHeader."Starting Date",
          AuditFileExportHeader."Ending Date");
    end;

    procedure GenerateFileContentForAuditFileExportLine(var AuditFileExportLine: Record "Audit File Export Line"; var TempBlob: Codeunit "Temp Blob")
    var
        EUBPSetup: Record "euBP Setup";
        AuditFileExportHeader: Record "Audit File Export Header";
        EUBPXmlMgt: Codeunit "euBP XML Mgt.";
        OutputOutStream: OutStream;
        FileContent: Text;
    begin
        EUBPSetup.EnsureExists();
        EUBPSetup.Get();
        AuditFileExportHeader.Get(AuditFileExportLine.ID);

        if AuditFileExportLine."Line No." = 10000 then
            FileContent := EUBPXmlMgt.GenerateLohnEnvelope(EUBPSetup, AuditFileExportHeader."Starting Date", AuditFileExportHeader."Ending Date")
        else
            FileContent := EUBPXmlMgt.GenerateFibuEnvelope(EUBPSetup, AuditFileExportHeader."Starting Date", AuditFileExportHeader."Ending Date");

        TempBlob.CreateOutStream(OutputOutStream, TextEncoding::UTF8);
        OutputOutStream.WriteText(FileContent);
    end;

    procedure GetFileNameForAuditFileExportLine(var AuditFileExportLine: Record "Audit File Export Line") FileName: Text[1024]
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        ExportDateSuffix: Text;
    begin
        if not AuditFileExportHeader.Get(AuditFileExportLine.ID) then
            exit('');

        ExportDateSuffix := Format(AuditFileExportHeader."Ending Date", 0, '<Year4><Month,2><Day,2>');
        if AuditFileExportLine."Line No." = 10000 then
            exit(CopyStr('euBP_LOHN_' + ExportDateSuffix + '.xml', 1, MaxStrLen(FileName)));

        exit(CopyStr('euBP_FIBU_' + ExportDateSuffix + '.xml', 1, MaxStrLen(FileName)));
    end;

    procedure InitAuditExportDataTypeSetup()
    begin
    end;
}
