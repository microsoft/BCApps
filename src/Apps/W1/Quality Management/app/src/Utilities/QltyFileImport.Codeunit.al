// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

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
}
