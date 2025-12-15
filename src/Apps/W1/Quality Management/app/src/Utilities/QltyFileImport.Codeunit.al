// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Provides file import utilities for Quality Management.
/// Handles user prompts for file selection and streaming file contents.
/// </summary>
codeunit 20597 "Qlty. File Import"
{
    var
        ImportFromLbl: Label 'Import From File';

    /// <summary>
    /// Prompts the user to select a file and imports its contents into an InStream for processing.
    /// Displays a file upload dialog with optional file type filtering.
    /// 
    /// Common usage: Importing configuration files, test data, or external quality inspection results.
    /// </summary>
    /// <param name="FilterString">File type filter for the upload dialog (e.g., "*.xml|*.txt")</param>
    /// <param name="InStream">Output: InStream containing the uploaded file contents</param>
    /// <returns>True if file was successfully selected and uploaded; False if user cancelled or upload failed</returns>
    procedure PromptAndImportIntoInStream(FilterString: Text; var InStream: InStream) Worked: Boolean
    var
        ServerFile: Text;
    begin
        Worked := UploadIntoStream(ImportFromLbl, '', FilterString, ServerFile, InStream);
    end;
}
