// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Handles the final writing and export operations for positive pay files after data processing is complete.
/// This codeunit orchestrates the file creation and output processes in the positive pay export workflow.
/// </summary>
/// <remarks>
/// The Export Writing Positive Pay codeunit is responsible for the final stages of positive pay file generation.
/// It manages the assembly of header, detail, and footer records into the final export file format and handles
/// the physical file creation process. The codeunit validates that data is available for export and coordinates
/// with other export components to ensure proper file structure and formatting. Error handling ensures that
/// users receive appropriate feedback when export conditions are not met.
/// </remarks>
codeunit 1708 "Exp. Writing Pos. Pay"
{
    Permissions = TableData "Data Exch." = rimd;

    var
        FileNotFoundErr: Label 'Positive Pay file was not created because there is no data to export. Ensure that there are entries for export and that the related data exchange definition is set up correctly.';

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Exports the positive pay data by combining header, detail, and footer records into the final file format.
    /// </summary>
    /// <param name="DataExchEntryCodeDetail">The data exchange entry number for detail records.</param>
    /// <param name="DataExchEntryCodeFooter">The data exchange entry number for footer records.</param>
    /// <param name="Filename">The target filename for the export file.</param>
    /// <param name="DataExchEntryCodeFooterArray">Array of footer entry codes for processing multiple footers.</param>
    /// <remarks>
    /// This procedure orchestrates the final file writing process by combining all processed positive pay components
    /// into a single export file. It validates that data is available and manages the file assembly process to ensure
    /// proper structure and formatting according to bank requirements.
    /// </remarks>
    [Scope('OnPrem')]
    procedure ExportPositivePay(DataExchEntryCodeDetail: Integer; DataExchEntryCodeFooter: Integer; Filename: Text; DataExchEntryCodeFooterArray: array[100] of Integer)
    var
        DataExchFooter: Record "Data Exch.";
        DataExchDetail: Record "Data Exch.";
        ExportFile: File;
        OutStream: OutStream;
        InStream: InStream;
        Filename2: Text[250];
        RecordCount: Integer;
        ArrayLength: Integer;
    begin
        // Need to copy the File Name and File from the footer to the Detail record.
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        if not Exists(Filename) then
            Error(FileNotFoundErr);
        ExportFile.Open(Filename);

        // Copy current file contents to TempBlob
        Filename2 := CopyStr(Filename, 1, 250);

        DataExchDetail.SetRange("Entry No.", DataExchEntryCodeDetail);
        if DataExchDetail.FindFirst() then begin
            DataExchDetail."File Name" := Filename2;
            ExportFile.CreateInStream(InStream);
            DataExchDetail."File Content".CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            DataExchDetail.Modify();
        end;
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

    /// <summary>
    /// Cleans up temporary positive pay work tables after the export process is complete.
    /// </summary>
    /// <param name="DataExchEntryCodeHeaderArray">Array of header entry codes to clean up.</param>
    /// <param name="DataExchEntryCodeDetailArray">Array of detail entry codes to clean up.</param>
    /// <param name="DataExchEntryCodeFooterArray">Array of footer entry codes to clean up.</param>
    /// <remarks>
    /// This procedure removes temporary records from positive pay work tables that were created during the export process.
    /// It processes header, detail, and footer records to ensure no temporary data remains after export completion.
    /// This cleanup maintains system performance and prevents accumulation of temporary export data.
    /// </remarks>
    procedure CleanUpPositivePayWorkTables(DataExchEntryCodeHeaderArray: array[100] of Integer; DataExchEntryCodeDetailArray: array[100] of Integer; DataExchEntryCodeFooterArray: array[100] of Integer)
    var
        PositivePayHeader: Record "Positive Pay Header";
        PositivePayDetail: Record "Positive Pay Detail";
        PositivePayFooter: Record "Positive Pay Footer";
        RecordCount: Integer;
        ArrayLength: Integer;
    begin
        ArrayLength := ArrayLen(DataExchEntryCodeHeaderArray);
        RecordCount := 1;
        while (DataExchEntryCodeHeaderArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayHeader.SetRange("Data Exch. Entry No.", DataExchEntryCodeHeaderArray[RecordCount]);
            PositivePayHeader.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeDetailArray);
        RecordCount := 1;
        while (DataExchEntryCodeDetailArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayDetail.SetRange("Data Exch. Entry No.", DataExchEntryCodeDetailArray[RecordCount]);
            PositivePayDetail.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
        RecordCount := 1;
        while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayFooter.SetRange("Data Exch. Entry No.", DataExchEntryCodeFooterArray[RecordCount]);
            PositivePayFooter.DeleteAll();
            RecordCount := RecordCount + 1;
        end;
    end;
}

