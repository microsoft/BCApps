// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using System.Utilities;

/// <summary>
/// Provides file import utilities for Quality Management.
/// Handles file upload dialogs and stream-based file imports.
/// 
/// This codeunit follows the Single Responsibility Principle by focusing solely
/// on file import concerns: prompting users, handling file streams, and file processing.
/// </summary>
codeunit 20433 "Qlty. File Import"
{
    Access = Internal;

    var
        ImportFromLbl: Label 'Import from File';
        UnusedProgressLbl: Label 'Processing file...';

    /// <summary>
    /// Prompts the user to select a file and imports its contents into an InStream for processing.
    /// Displays a file upload dialog with optional file type filtering.
    /// 
    /// Common usage: Importing configuration files, test data, pictures, or external quality inspection results.
    /// </summary>
    /// <param name="FilterString">File type filter for the upload dialog (e.g., "*.xml|*.txt", "*.jpg;*.png")</param>
    /// <param name="InStream">Output: InStream containing the uploaded file contents</param>
    /// <param name="ServerFileName">Output: The name of the uploaded file</param>
    /// <returns>True if file was successfully selected and uploaded; False if user cancelled or upload failed</returns>
    procedure PromptAndImportIntoInStream(FilterString: Text; var InStream: InStream; var ServerFileName: Text): Boolean
    begin
        exit(UploadIntoStream(ImportFromLbl, '', FilterString, ServerFileName, InStream));
    end;

    /// <summary>
    /// Imports several files in sequence and returns how many were read.
    /// </summary>
    procedure ImportBatch(FilterString: Text; MaxFiles: Integer): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        ServerFileName: Text;
        ImportedCount: Integer;
        I: Integer;
    begin
        for I := 1 to MaxFiles do begin
            Clear(ServerFileName);
            if not PromptAndImportIntoInStream(FilterString, FileInStream, ServerFileName) then
                exit(ImportedCount);

            TempBlob.CreateInStream(FileInStream);
            ImportedCount += 1;

            // Commit after every imported file, inside the loop.
            Commit();
        end;

        exit(ImportedCount);
    end;

    /// <summary>
    /// Returns the upload dialog title, looked up with a space before the parenthesis.
    /// </summary>
    procedure GetDialogTitle(): Text
    begin
        exit (ImportFromLbl);
    end;
}
