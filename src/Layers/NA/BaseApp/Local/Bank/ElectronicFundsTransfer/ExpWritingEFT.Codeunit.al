// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Utilities;
using System.IO;

codeunit 10322 "Exp. Writing EFT"
{
    Permissions = TableData "Data Exch." = rimd;

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure ExportEFT(DataExchEntryCodeDetail: Integer; DataExchEntryCodeFooter: Integer; FilePath: Text; Filename: Text; ACHFileName: Text; DataExchEntryCodeFooterArray: array[100] of Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var ZipFileName: Text; var DataCompression: Codeunit "Data Compression")
    var
        DataExchFooter: Record "Data Exch.";
        DataExchDetail: Record "Data Exch.";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        ExportFile: File;
        OutStream: OutStream;
        InStream: InStream;
        Filename2: Text[250];
        RecordCount: Integer;
        ArrayLength: Integer;
        FileIsOpened: Boolean;
    begin
        DataExchDetail.SetRange("Entry No.", DataExchEntryCodeDetail);
        if DataExchDetail.FindFirst() then begin
            // Need to copy the File Name and File from the footer to the Detail record.
            ExportFile.WriteMode := true;
            ExportFile.TextMode := true;
            ExportFile.Open(Filename);
            Filename2 := CopyStr(Filename, 1, 250);
            DataExchDetail."File Name" := Filename2;

            // Copy current file contents to Blob
            ExportFile.CreateInStream(InStream);
            DataExchDetail."File Content".CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            DataExchDetail.Modify();
            FileIsOpened := true;
        end;

        ExportEFTACH.AddFileToClientZip(Filename, ACHFileName, TempNameValueBuffer, ZipFileName, DataCompression);
        if not FileIsOpened then begin
            ExportFile.TextMode := true;
            ExportFile.Open(Filename);
        end;
        ExportFile.CreateInStream(InStream);
        TempNameValueBuffer."Value BLOB".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TempNameValueBuffer.Modify();
        ExportFile.Close();

        // Need to clear out the File Name and blob (File Content) for the footer record(s)
        DataExchFooter.SetRange("Entry No.", DataExchEntryCodeFooter);
        if DataExchFooter.FindFirst() then begin
            ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
            RecordCount := 1;
            while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
                DataExchFooter."Entry No." := DataExchEntryCodeFooterArray[RecordCount];
                DataExchFooter."File Name" := '';
                Clear(DataExchFooter."File Content");
                DataExchFooter.Modify();
                RecordCount := RecordCount + 1;
            end;
        end;
    end;

    procedure CleanUpEFTWorkTables(DataExchEntryCodeHeaderArray: array[100] of Integer; DataExchEntryCodeDetailArray: array[100] of Integer; DataExchEntryCodeFooterArray: array[100] of Integer)
    var
        ACHUSHeader: Record "ACH US Header";
        ACHUSDetail: Record "ACH US Detail";
        ACHUSFooter: Record "ACH US Footer";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
        ACHRBFooter: Record "ACH RB Footer";
        ACHCecobanHeader: Record "ACH Cecoban Header";
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        ACHCecobanFooter: Record "ACH Cecoban Footer";
        RecordCount: Integer;
        ArrayLength: Integer;
    begin
        ArrayLength := ArrayLen(DataExchEntryCodeHeaderArray);
        RecordCount := 1;
        while (DataExchEntryCodeHeaderArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHUSHeader.SetRange("Data Exch. Entry No.", DataExchEntryCodeHeaderArray[RecordCount]);
            ACHUSHeader.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeDetailArray);
        RecordCount := 1;
        while (DataExchEntryCodeDetailArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHUSDetail.SetRange("Data Exch. Entry No.", DataExchEntryCodeDetailArray[RecordCount]);
            ACHUSDetail.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
        RecordCount := 1;
        while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHUSFooter.SetRange("Data Exch. Entry No.", DataExchEntryCodeFooterArray[RecordCount]);
            ACHUSFooter.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeHeaderArray);
        RecordCount := 1;
        while (DataExchEntryCodeHeaderArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHRBHeader.SetRange("Data Exch. Entry No.", DataExchEntryCodeHeaderArray[RecordCount]);
            ACHRBHeader.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeDetailArray);
        RecordCount := 1;
        while (DataExchEntryCodeDetailArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHRBDetail.SetRange("Data Exch. Entry No.", DataExchEntryCodeDetailArray[RecordCount]);
            ACHRBDetail.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
        RecordCount := 1;
        while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHRBFooter.SetRange("Data Exch. Entry No.", DataExchEntryCodeFooterArray[RecordCount]);
            ACHRBFooter.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeHeaderArray);
        RecordCount := 1;
        while (DataExchEntryCodeHeaderArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHCecobanHeader.SetRange("Data Exch. Entry No.", DataExchEntryCodeHeaderArray[RecordCount]);
            ACHCecobanHeader.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeDetailArray);
        RecordCount := 1;
        while (DataExchEntryCodeDetailArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHCecobanDetail.SetRange("Data Exch. Entry No.", DataExchEntryCodeDetailArray[RecordCount]);
            ACHCecobanDetail.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
        RecordCount := 1;
        while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            ACHCecobanFooter.SetRange("Data Exch. Entry No.", DataExchEntryCodeFooterArray[RecordCount]);
            ACHCecobanFooter.DeleteAll();
            RecordCount := RecordCount + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure PreCleanUpUSWorkTables()
    var
        ACHUSHeader: Record "ACH US Header";
        ACHUSDetail: Record "ACH US Detail";
        ACHUSFooter: Record "ACH US Footer";
    begin
        ACHUSHeader.DeleteAll();
        ACHUSDetail.DeleteAll();
        ACHUSFooter.DeleteAll();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure PreCleanUpCAWorkTables()
    var
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
        ACHRBFooter: Record "ACH RB Footer";
    begin
        ACHRBHeader.DeleteAll();
        ACHRBDetail.DeleteAll();
        ACHRBFooter.DeleteAll();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure PreCleanUpMXWorkTables()
    var
        ACHCecobanHeader: Record "ACH Cecoban Header";
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        ACHCecobanFooter: Record "ACH Cecoban Footer";
    begin
        ACHCecobanHeader.DeleteAll();
        ACHCecobanDetail.DeleteAll();
        ACHCecobanFooter.DeleteAll();
        Commit();
    end;
}

