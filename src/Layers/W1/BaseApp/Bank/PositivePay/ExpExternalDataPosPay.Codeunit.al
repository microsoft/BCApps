// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;
using System.Utilities;

/// <summary>
/// Handles the external file creation and download processes for positive pay exports.
/// This codeunit manages the final step of converting data exchange content into downloadable files.
/// </summary>
/// <remarks>
/// The Export External Data Positive Pay codeunit is responsible for creating the physical export files
/// from processed data exchange records. It handles file content validation, temporary file creation,
/// and provides download functionality for users. The codeunit supports both interactive and batch
/// processing modes, allowing users to download files immediately or process them in background jobs.
/// File management operations include proper error handling and cleanup of temporary resources.
/// </remarks>
codeunit 1709 "Exp. External Data Pos. Pay"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        ExternalContentErr: Label '%1 is empty.';
#pragma warning restore AA0470
        DownloadFromStreamErr: Label 'The file has not been saved.';

    /// <summary>
    /// Creates and downloads the export file from the processed data exchange content.
    /// </summary>
    /// <param name="DataExch">The data exchange record containing the processed file content.</param>
    /// <param name="ShowDialog">Indicates whether to show download dialog to the user.</param>
    /// <remarks>
    /// This procedure handles the final file creation step by extracting the processed content from the data exchange
    /// record and making it available for download. It validates that file content exists and manages the download
    /// process through the file management framework. Error handling ensures appropriate user feedback when file
    /// content is missing or download operations fail.
    /// </remarks>
    [Scope('OnPrem')]
    procedure CreateExportFile(DataExch: Record "Data Exch."; ShowDialog: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ExportFileName: Text;
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            Error(ExternalContentErr, DataExch.FieldCaption("File Content"));

        TempBlob.FromRecord(DataExch, DataExch.FieldNo("File Content"));
        ExportFileName := DataExch."Data Exch. Def Code" + Format(Today, 0, '<Month,2><Day,2><Year4>') + '.txt';
        if FileMgt.BLOBExport(TempBlob, ExportFileName, ShowDialog) = '' then
            Error(DownloadFromStreamErr);
    end;
}

