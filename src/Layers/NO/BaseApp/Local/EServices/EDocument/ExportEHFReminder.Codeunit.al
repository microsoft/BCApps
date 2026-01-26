// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Peppol;
using Microsoft.Sales.Reminder;
using System.IO;
using System.Utilities;

codeunit 10630 "Export EHF Reminder"
{

    trigger OnRun()
    begin
    end;

    procedure ExportEFHReminder30(DocumentVariant: Variant; DocumentView: Text)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        TempRecordExportBuffer: Record "Record Export Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocumentVariant);
        RecRef.SetView(DocumentView);
        if not RecRef.FindSet() then
            exit;

        repeat
            TempRecordExportBuffer.Init();
            TempRecordExportBuffer.ID += 1;
            TempRecordExportBuffer.RecordID := RecRef.RecordId();
            TempRecordExportBuffer.Insert();
        until RecRef.Next() = 0;

        TempRecordExportBuffer.FindSet();
        repeat
            RecRef.Get(TempRecordExportBuffer.RecordID);
            case RecRef.Number() of
                DATABASE::"Issued Reminder Header":
                    begin
                        RecRef.SetTable(IssuedReminderHeader);
                        GenerateXMLFile(TempBlob, IssuedReminderHeader);
                        TempRecordExportBuffer.SetFileContent(TempBlob);
                        TempRecordExportBuffer.ClientFileName := GetClientFileName(IssuedReminderHeader.TableCaption(), IssuedReminderHeader."No.");
                        TempRecordExportBuffer.ZipFileName := GetZipFileName(IssuedReminderHeader.TableCaption(), IssuedReminderHeader."No.");
                        TempRecordExportBuffer.Modify();
                    end;
                DATABASE::"Issued Fin. Charge Memo Header":
                    begin
                        RecRef.SetTable(IssuedFinChargeMemoHeader);
                        GenerateXMLFile(TempBlob, IssuedFinChargeMemoHeader);
                        TempRecordExportBuffer.SetFileContent(TempBlob);
                        TempRecordExportBuffer.ClientFileName := GetClientFileName(IssuedFinChargeMemoHeader.TableCaption(), IssuedFinChargeMemoHeader."No.");
                        TempRecordExportBuffer.ZipFileName := GetZipFileName(IssuedFinChargeMemoHeader.TableCaption(), IssuedFinChargeMemoHeader."No.");
                        TempRecordExportBuffer.Modify();
                    end;
            end;
        until TempRecordExportBuffer.Next() = 0;

        SendElectronically(TempRecordExportBuffer);
    end;

    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        EHFReminder30: XMLport "EHF Reminder 3.0";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        EHFReminder30.Initialize(VariantRec);
        EHFReminder30.SetDestination(OutStream);
        EHFReminder30.Export();
        OutFile.Close();

        exit(CopyStr(XmlServerPath, 1, 250));
    end;

    procedure GenerateXMLFile(var TempBlob: Codeunit "Temp Blob"; VariantRec: Variant)
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        EHFReminder30: XMLport "EHF Reminder 3.0";
        OutFile: File;
        InStream: InStream;
        OutStream: OutStream;
        BlobOutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        EHFReminder30.Initialize(VariantRec);
        EHFReminder30.SetDestination(OutStream);
        EHFReminder30.Export();

        TempBlob.CreateOutStream(BlobOutStream);
        OutFile.CreateInStream(InStream);
        CopyStream(BlobOutStream, InStream);
        OutFile.Close();
    end;

    local procedure GetClientFileName(TableCaption2: Text; DocumentNo: Code[20]): Text[250]
    begin
        exit(
          CopyStr(StrSubstNo('%1 - %2.xml', TableCaption2, DocumentNo), 1, 250));
    end;

    local procedure GetZipFileName(TableCaption2: Text; DocumentNo: Code[20]): Text[250]
    begin
        exit(
          CopyStr(StrSubstNo('%1 - %2.zip', TableCaption2, DocumentNo), 1, 250));
    end;

    local procedure SendElectronically(var RecordExportBuffer: Record "Record Export Buffer")
    var
        EntryTempBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        EntryFileInStream: InStream;
        ZipFileOutStream: OutStream;
        ClientFile: Text;
    begin
        if not RecordExportBuffer.FindSet() then
            exit;

        if RecordExportBuffer.Count() > 1 then begin
            TempBlob.CreateOutStream(ZipFileOutStream);
            DataCompression.CreateZipArchive();
            ClientFile := RecordExportBuffer.ZipFileName;
            repeat
                RecordExportBuffer.GetFileContent(EntryTempBlob);
                EntryTempBlob.CreateInStream(EntryFileInStream);
                DataCompression.AddEntry(EntryFileInStream, RecordExportBuffer.ClientFileName);
            until RecordExportBuffer.Next() = 0;
            DataCompression.SaveZipArchive(ZipFileOutStream);
            DataCompression.CloseZipArchive();
        end else begin
            RecordExportBuffer.GetFileContent(TempBlob);
            ClientFile := RecordExportBuffer.ClientFileName;
        end;

        ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientFile);
    end;
}

