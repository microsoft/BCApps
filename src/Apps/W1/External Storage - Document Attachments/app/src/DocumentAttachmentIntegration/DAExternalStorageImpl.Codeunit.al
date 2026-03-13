// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Environment;
using System.ExternalFileStorage;
using System.Security.Encryption;
using System.Utilities;

codeunit 8751 "DA External Storage Impl." implements "File Scenario"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "Tenant Media" = rimd,
                  tabledata "Document Attachment" = rimd,
                  tabledata "File Account" = r,
                  tabledata "DA External Storage Setup" = r;

    #region File Scenario Interface Implementation
    /// <summary>
    /// Called before adding or modifying a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the operation is allowed, otherwise false.</returns>
    procedure BeforeAddOrModifyFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum "Ext. File Storage Connector"): Boolean;
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        FileAccount: Record "File Account";
        FileScenarioCU: Codeunit "File Scenario";
        ConfirmManagement: Codeunit "Confirm Management";
        ExternalStorageSetupPage: Page "DA External Storage Setup";
        CannotReassignScenarioErr: Label 'You cannot change the file storage account while External Storage is enabled and files are stored externally.\\To change the storage account:\1. Copy all files back to internal storage using the "Storage Sync" action.\2. Disable the External Storage feature.\3. Reassign the file scenario to the new storage account.\4. Re-enable the feature and sync files to the new storage.';
        ConfigureExternalStorageQst: Label 'Do you want to configure External Storage settings now?';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        // Check if scenario is already assigned to a different account
        if FileScenarioCU.GetSpecificFileAccount(Scenario, FileAccount) then
            // If feature is enabled and has uploaded files, don't allow reassignment
            if ExternalStorageSetup.Get() then
                if ExternalStorageSetup.Enabled then begin
                    ExternalStorageSetup.CalcFields("Has Uploaded Files");
                    if ExternalStorageSetup."Has Uploaded Files" then begin
                        Message(CannotReassignScenarioErr);
                        exit(true);
                    end;
                end;

        // Open setup page for additional configuration automatically
        if ConfirmManagement.GetResponseOrDefault(ConfigureExternalStorageQst, true) then
            ExternalStorageSetupPage.Run();
        exit(false);
    end;

    /// <summary>
    /// Called to get additional setup for a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if additional setup is available, otherwise false.</returns>
    procedure GetAdditionalScenarioSetup(Scenario: Enum "File Scenario"; Connector: Enum "Ext. File Storage Connector"): Boolean;
    var
        ExternalStorageSetup: Page "DA External Storage Setup";
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        ExternalStorageSetup.RunModal();
        exit(true);
    end;

    /// <summary>
    /// Called before deleting a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the delete operation is handled and should not proceed, otherwise false.</returns>
    procedure BeforeDeleteFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum "Ext. File Storage Connector"): Boolean;
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        NotPossibleToUnassignScenarioMsg: Label 'External Storage scenario can not be unassigned when there are uploaded files.';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        if not ExternalStorageSetup.Get() then
            exit;

        ExternalStorageSetup.CalcFields("Has Uploaded Files");
        if not ExternalStorageSetup."Has Uploaded Files" then
            exit;

        Message(NotPossibleToUnassignScenarioMsg);
        exit(true);
    end;

    procedure BeforeReassignFileScenarioCheck(Scenario: Enum "File Scenario"): Boolean
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        NotPossibleToReassignScenarioMsg: Label 'External Storage scenario can not be reassigned when there are uploaded files.';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        if not ExternalStorageSetup.Get() then
            exit;

        ExternalStorageSetup.CalcFields("Has Uploaded Files");
        if not ExternalStorageSetup."Has Uploaded Files" then
            exit;

        Message(NotPossibleToReassignScenarioMsg);
        exit(true);
    end;
    #endregion

    /// <summary>
    /// Provides functionality to manage document attachments in external storage systems.
    /// Handles upload, download, and deletion operations for Business Central attachments.
    /// </summary>
    #region External Storage Operations
    /// <summary>
    /// Uploads a document attachment to external storage.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to upload.</param>
    /// <returns>True if upload was successful, false otherwise.</returns>
    procedure UploadToExternalStorage(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
        TempBlob: Codeunit "Temp Blob";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text[2048];
    begin
        // Check if feature is enabled
        if not IsFeatureEnabled() then
            exit(false);

        // Validate input parameters
        if not DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);

        // Check if document is already uploaded
        if DocumentAttachment."External File Path" <> '' then
            exit(false);

        // Telemetry logging for feature usage
        DAFeatureTelemetry.LogFeatureUsed();

        // Get file content from document attachment
        TempBlob.CreateOutStream(OutStream);
        DocumentAttachment.ExportToStream(OutStream);
        TempBlob.CreateInStream(InStream);

        // Generate unique filename to prevent collisions
        FileName := GetFilePathWithRootFolder(DocumentAttachment);

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Create the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        if ExternalFileStorage.CreateFile(FileName, InStream) then begin
            DocumentAttachment."Stored Externally" := true;
            DocumentAttachment."External Upload Date" := CurrentDateTime();
            DocumentAttachment."External File Path" := FileName;
            DocumentAttachment."Source Environment Hash" := GetCurrentEnvironmentHash();
            DocumentAttachment.Modify();
            DAFeatureTelemetry.LogFileUploaded(DocumentAttachment);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Downloads a document attachment from external storage and prompts user to save it locally.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to download.</param>
    /// <returns>True if download was successful, false otherwise.</returns>
    procedure DownloadFromExternalStorage(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
        ExternalFilePath, FileName : Text;
    begin
        // Check if feature is enabled
        if not IsFeatureEnabled() then
            exit(false);

        // Validate input parameters
        if DocumentAttachment."External File Path" = '' then
            exit(false);

        if not DocumentAttachment."Stored Externally" then
            exit(false);

        // Use the stored external file path
        ExternalFilePath := DocumentAttachment."External File Path";
        FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        ExternalFileStorage.GetFile(ExternalFilePath, InStream);

        if DownloadFromStream(InStream, '', '', '', FileName) then begin
            DAFeatureTelemetry.LogFileDownloaded(DocumentAttachment);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Downloads a document attachment from external storage and saves it to internal storage.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to download and restore internally.</param>
    /// <returns>True if download and import was successful, false otherwise.</returns>
    procedure DownloadFromExternalStorageToInternal(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
        ExternalFilePath, FileName : Text;
    begin
        // Validate input parameters
        if DocumentAttachment."External File Path" = '' then
            exit(false);

        if not DocumentAttachment."Stored Externally" then
            exit(false);

        // Use the stored external file path
        ExternalFilePath := DocumentAttachment."External File Path";
        FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        if not ExternalFileStorage.GetFile(ExternalFilePath, InStream) then
            exit(false);

        // Import the file into the Document Attachment
        DocumentAttachment.ImportAttachment(InStream, FileName);
        DocumentAttachment."Stored Internally" := true;
        DocumentAttachment.Modify();

        exit(true);
    end;

    /// <summary>
    /// Downloads a document attachment from external storage to a stream.
    /// </summary>
    /// <param name="ExternalFilePath">The path of the external file to download.</param>
    /// <param name="AttachmentOutStream">The output stream to write the attachment to.</param>
    /// <returns>True if the download was successful, false otherwise.</returns>
    procedure DownloadFromExternalStorageToStream(ExternalFilePath: Text; var AttachmentOutStream: OutStream): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
    begin
        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file from external storage
        ExternalFileStorage.Initialize(FileScenario);
        if not ExternalFileStorage.GetFile(ExternalFilePath, InStream) then
            exit(false);

        // Copy to output stream
        CopyStream(AttachmentOutStream, InStream);
        exit(true);
    end;

    /// <summary>
    /// Downloads a document attachment from external storage to a Temp Blob.
    /// </summary>
    /// <param name="ExternalFilePath">The path of the external file to download.</param>
    /// <param name="TempBlob">The temporary blob to store the downloaded content.</param>
    /// <returns>True if the download was successful, false otherwise.</returns>
    procedure DownloadFromExternalStorageToTempBlob(ExternalFilePath: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
        OutStream: OutStream;
    begin
        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file from external storage
        ExternalFileStorage.Initialize(FileScenario);
        if not ExternalFileStorage.GetFile(ExternalFilePath, InStream) then
            exit(false);

        // Copy to TempBlob
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        exit(true);
    end;

    /// <summary>
    /// Checks if a file exists in external storage.
    /// </summary>
    /// <param name="ExternalFilePath">The path of the external file to check.</param>
    /// <returns>True if the file exists, false otherwise.</returns>
    procedure CheckIfFileExistInExternalStorage(ExternalFilePath: Text): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        FileScenario: Enum "File Scenario";
    begin
        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file from external storage
        ExternalFileStorage.Initialize(FileScenario);
        exit(ExternalFileStorage.FileExists(ExternalFilePath));
    end;

    /// <summary>
    /// Deletes a document attachment from external storage.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to delete from external storage.</param>
    /// <returns>True if deletion was successful, false otherwise.</returns>
    procedure DeleteFromExternalStorage(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
        FileScenario: Enum "File Scenario";
        ExternalFilePath: Text;
    begin
        // Check if feature is enabled
        if not IsFeatureEnabled() then
            exit(false);

        if not DocumentAttachment.Find() then
            exit(false);

        // Validate input parameters
        if DocumentAttachment."External File Path" = '' then
            exit(false);

        if not DocumentAttachment."Stored Externally" then
            exit(false);

        if DocumentAttachment."Skip Delete On Copy" then
            exit(false);

        // Check if file belongs to another environment - if so, just clear the reference
        if IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment) then begin
            DocumentAttachment.MarkAsNotUploadedToExternal();
            exit(true);
        end;

        // Use the stored external file path
        ExternalFilePath := DocumentAttachment."External File Path";

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Delete the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        if ExternalFileStorage.DeleteFile(ExternalFilePath) then begin
            DocumentAttachment.MarkAsNotUploadedToExternal();
            DAFeatureTelemetry.LogFileDeleted(DocumentAttachment);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Deletes a document attachment from internal storage.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to delete from internal storage.</param>
    /// <returns>True if deletion was successful, false otherwise.</returns>
    procedure DeleteFromInternalStorage(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        TenantMedia: Record "Tenant Media";
    begin
        // Validate input parameters
        if not DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);

        // Check if file is uploaded externally before deleting internally
        if not DocumentAttachment."Stored Externally" then
            exit(false);

        // Delete from Tenant Media
        if TenantMedia.Get(DocumentAttachment."Document Reference ID".MediaId()) then begin
            TenantMedia.Delete();

            // Mark Document Attachment as Not Stored Internally
            DocumentAttachment.MarkAsDeletedInternally();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Maps file extensions to their corresponding MIME types.
    /// </summary>
    /// <param name="Rec">The document attachment record.</param>
    /// <param name="ContentType">The content type to set based on the file extension.</param>
    procedure FileExtensionToContentMimeType(var Rec: Record "Document Attachment"; var ContentType: Text[100])
    begin
        // Determine content type based on file extension
        case LowerCase(Rec."File Extension") of
            'pdf':
                ContentType := 'application/pdf';
            'jpg', 'jpeg':
                ContentType := 'image/jpeg';
            'png':
                ContentType := 'image/png';
            'gif':
                ContentType := 'image/gif';
            'bmp':
                ContentType := 'image/bmp';
            'tiff', 'tif':
                ContentType := 'image/tiff';
            'doc':
                ContentType := 'application/msword';
            'docx':
                ContentType := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            'xls':
                ContentType := 'application/vnd.ms-excel';
            'xlsx':
                ContentType := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            'ppt':
                ContentType := 'application/vnd.ms-powerpoint';
            'pptx':
                ContentType := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
            'txt':
                ContentType := 'text/plain';
            'xml':
                ContentType := 'text/xml';
            'html', 'htm':
                ContentType := 'text/html';
            'zip':
                ContentType := 'application/zip';
            'rar':
                ContentType := 'application/x-rar-compressed';
            else
                ContentType := 'application/octet-stream';
        end;
    end;

    /// <summary>
    /// Checks if a Document Attachment file is uploaded to external storage and not stored internally.
    /// </summary>
    /// <param name="DocumentAttachment">The Document Attachment record to check.</param>
    /// <returns>True if the file is uploaded and not stored internally, false otherwise.</returns>
    procedure IsFileUploadedToExternalStorageAndDeletedInternally(var DocumentAttachment: Record "Document Attachment"): Boolean
    begin
        if DocumentAttachment."Stored Internally" then
            exit(false);

        if not DocumentAttachment."Stored Externally" then
            exit(false);

        if DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);

        if DocumentAttachment."External File Path" = '' then
            exit(false);
        exit(true);
    end;
    #endregion

    /// <summary>
    /// Opens a folder selection dialog for choosing the root folder.
    /// </summary>
    /// <returns>The selected folder path, or empty string if cancelled.</returns>
    procedure SelectRootFolder(): Text
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        SelectFolderPathLbl: Label 'Select Root Folder for Attachments';
        FileScenario: Enum "File Scenario";
    begin
        // Initialize external file storage with the scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit('');

        ExternalFileStorage.Initialize(FileScenario);
        exit(ExternalFileStorage.SelectAndGetFolderPath('', SelectFolderPathLbl));
    end;

    local procedure GetFilePathWithRootFolder(DocumentAttachment: Record "Document Attachment"): Text[2048]
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        FileName: Text;
        RootFolder: Text;
        TableNameFolder: Text[100];
        EnvironmentHashFolder: Text[32];
        FileNamePart: Text;
        FileNameFormatLbl: Label '%1-%2.%3', Comment = '%1 = File Name, %2 = GUID, %3 = File Extension', Locked = true;
    begin
        // Generate unique filename to prevent collisions
        FileNamePart := StrSubstNo(FileNameFormatLbl, DocumentAttachment."File Name", DelChr(Format(CreateGuid()), '=', '{}'), DocumentAttachment."File Extension");

        // Get table name folder (based on the source table of the attachment)
        TableNameFolder := GetTableNameFolder(DocumentAttachment."Table ID");

        // Get environment hash folder (based on tenant + environment + company)
        EnvironmentHashFolder := GetCurrentEnvironmentHash();

        // Get root folder from setup if configured
        if not ExternalStorageSetup.Get() then
            exit;

        RootFolder := ExternalStorageSetup."Root Folder";
        if RootFolder <> '' then begin
            // Ensure root folder ends with a separator
            if not RootFolder.EndsWith('/') and not RootFolder.EndsWith('\') then
                RootFolder := RootFolder + '/';

            // Ensure environment hash folder exists
            EnsureFolderExists(RootFolder + EnvironmentHashFolder);

            // Ensure environment hash folder exists within table folder
            EnsureFolderExists(RootFolder + EnvironmentHashFolder + '/' + TableNameFolder);

            FileName := RootFolder + EnvironmentHashFolder + '/' + TableNameFolder + '/' + FileNamePart;
        end else begin
            // No root folder, add environment folder at root level
            EnsureFolderExists(EnvironmentHashFolder);

            // Ensure environment hash folder exists within table folder
            EnsureFolderExists(EnvironmentHashFolder + '/' + TableNameFolder);

            FileName := EnvironmentHashFolder + '/' + TableNameFolder + '/' + FileNamePart;
        end;

        exit(CopyStr(FileName, 1, 2048));
    end;

    local procedure GetTableNameFolder(TableID: Integer): Text[100]
    var
        TableName: Text;
    begin
        // Try to get table name from metadata, fallback to table ID if not available
        if not TryGetTableName(TableID, TableName) then
            TableName := 'Table_' + Format(TableID);

        // Replace invalid characters for folder names
        TableName := DelChr(TableName, '=', '<>:"/\|?*');
        TableName := ConvertStr(TableName, ' ', '_');

        exit(CopyStr(TableName, 1, 100));
    end;

    [TryFunction]
    local procedure TryGetTableName(TableID: Integer; var TableName: Text)
    var
        RecRef: RecordRef;
    begin
        // Open the RecordRef to get table metadata
        // This will fail if the table no longer exists (e.g., after uninstalling a 3rd party app)
        RecRef.Open(TableID, false);
        TableName := RecRef.Name;
        RecRef.Close();
    end;

    local procedure EnsureFolderExists(CompanyFolderPath: Text)
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        FileScenario: Enum "File Scenario";
    begin
        // Initialize external file storage with the scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit;

        ExternalFileStorage.Initialize(FileScenario);

        // Check if directory exists, if not create it
        if not ExternalFileStorage.DirectoryExists(CompanyFolderPath) then
            ExternalFileStorage.CreateDirectory(CompanyFolderPath);
    end;

    /// <summary>
    /// Gets the current environment hash for use in folder structure.
    /// </summary>
    /// <returns>The hash value</returns>
    procedure GetCurrentEnvironmentHash(): Text[32]
    var
        Company: Record Company;
        EnvironmentInformation: Codeunit "Environment Information";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        IdentityString: Text;
    begin
        Company.Get(CompanyName());

        // Combine Tenant ID + Environment Name + Company System ID
        IdentityString := TenantId() + '|' + EnvironmentInformation.GetEnvironmentName() + '|' + Format(Company.SystemId);

        // Generate MD5 hash (32 characters)
        exit(CopyStr(CryptographyManagement.GenerateHash(IdentityString, HashAlgorithmType::MD5), 1, 32));
    end;

    /// <summary>
    /// Checks if a file belongs to another environment or company.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to check.</param>
    /// <returns>True if the file is from another environment or company, false otherwise.</returns>
    procedure IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment: Record "Document Attachment"): Boolean
    var
        CurrentEnvironmentHash: Text[32];
    begin
        // If no source environment hash is set, assume it belongs to current environment
        if DocumentAttachment."Source Environment Hash" = '' then
            exit(false);

        CurrentEnvironmentHash := GetCurrentEnvironmentHash();
        exit(DocumentAttachment."Source Environment Hash" <> CurrentEnvironmentHash);
    end;

    /// <summary>
    /// Migrates a file from a previous environment or company folder to the current one.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record to migrate.</param>
    /// <returns>True if migration was successful, false otherwise.</returns>
    procedure MigrateFileToCurrentEnvironment(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        FileAccount: Record "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileScenarioCU: Codeunit "File Scenario";
        TempBlob: Codeunit "Temp Blob";
        FileScenario: Enum "File Scenario";
        InStream: InStream;
        OutStream: OutStream;
        OldFilePath: Text;
        NewFilePath: Text[2048];
    begin
        if not DocumentAttachment."Stored Externally" then
            exit(false);

        if DocumentAttachment."External File Path" = '' then
            exit(false);

        // Initialize external file storage
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetSpecificFileAccount(FileScenario, FileAccount) then
            exit(false);

        ExternalFileStorage.Initialize(FileScenario);

        // Download file from old location
        OldFilePath := DocumentAttachment."External File Path";
        if not ExternalFileStorage.GetFile(OldFilePath, InStream) then
            exit(false);

        // Copy to TempBlob
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TempBlob.CreateInStream(InStream);

        // Generate new file path in current company folder
        NewFilePath := GetFilePathWithRootFolder(DocumentAttachment);

        // Upload to new location
        if not ExternalFileStorage.CreateFile(NewFilePath, InStream) then
            exit(false);

        // Update document attachment record
        DocumentAttachment."External File Path" := NewFilePath;
        DocumentAttachment."Source Environment Hash" := GetCurrentEnvironmentHash();
        DocumentAttachment."External Upload Date" := CurrentDateTime();
        DocumentAttachment.Modify();

        exit(true);
    end;

    /// <summary>
    /// Runs migration for all document attachments from a previous company.
    /// </summary>
    /// <returns>Number of files migrated.</returns>
    procedure RunCompanyMigration(): Integer
    var
        DocumentAttachment: Record "Document Attachment";
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
        MigratedCount: Integer;
        StartMigrationQst: Label 'This will migrate all document attachments from the previous company folder to the current company folder.\\Do you want to continue?';
        MigrationCompletedMsg: Label '%1 file(s) have been successfully migrated to the current company folder.', Comment = '%1 = Number of files';
    begin
        if not Confirm(StartMigrationQst, false) then
            exit(0);

        MigratedCount := 0;
        DocumentAttachment.SetRange("Stored Externally", true);
        DocumentAttachment.SetFilter("External File Path", '<>%1', '');
        if DocumentAttachment.FindSet(true) then
            repeat
                if IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment) then
                    if MigrateFileToCurrentEnvironment(DocumentAttachment) then
                        MigratedCount += 1;
            until DocumentAttachment.Next() = 0;

        if MigratedCount > 0 then begin
            DAFeatureTelemetry.LogCompanyMigration();
            Message(MigrationCompletedMsg, MigratedCount);
        end;

        exit(MigratedCount);
    end;

    #region Document Attachment Handling
    /// <summary>
    /// Handles automatic upload of new document attachments to external storage upon insertion of the attachment record.
    /// </summary>
    /// <param name="Rec">The document attachment record.</param>
    /// <param name="RunTrigger">Indicates if the trigger should run.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterInsertEvent, '', true, true)]
    local procedure OnAfterInsertDocumentAttachment(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Exit early if trigger is not running
        if not RunTrigger then
            exit;

        // Temporary records are not processed
        if Rec.IsTemporary() then
            exit;

        // Check if auto upload is enabled
        if not ExternalStorageSetup.Get() then
            exit;

        // Only process files with actual content
        if not Rec."Document Reference ID".HasValue() then
            exit;

        // Upload to external storage
        if not ExternalStorageImpl.UploadToExternalStorage(Rec) then
            exit;

        ExternalStorageImpl.DeleteFromInternalStorage(Rec);
    end;

    /// <summary>
    /// Handles automatic deletion of document attachments from external storage upon deletion of the attachment record.
    /// </summary>
    /// <param name="Rec">The document attachment record.</param>
    /// <param name="RunTrigger">Indicates if the trigger should run.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterDeleteEvent, '', true, true)]
    local procedure OnAfterDeleteDocumentAttachment(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Exit early if trigger is not running
        if not RunTrigger then
            exit;

        // Temporary records are not processed
        if Rec.IsTemporary() then
            exit;

        // Check if auto upload is enabled
        if not ExternalStorageSetup.Get() then
            exit;

        if not ExternalStorageSetup."Delete from External Storage" then
            exit;

        // Only process files that were uploaded to external storage
        if not Rec."Stored Externally" then
            exit;

        // Delete from external storage
        ExternalStorageImpl.DeleteFromExternalStorage(Rec);

        if Rec."Skip Delete On Copy" then begin
            Rec."Skip Delete On Copy" := false;
            Rec.Modify();
        end;
    end;

    /// <summary>
    /// Handles exporting document attachment content to a stream for externally stored attachments.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record.</param>
    /// <param name="AttachmentOutStream">The output stream for the attachment content.</param>
    /// <param name="IsHandled">Indicates if the event has been handled.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeExportToStream, '', false, false)]
    local procedure DocumentAttachment_OnBeforeExportToStream(var DocumentAttachment: Record "Document Attachment"; var AttachmentOutStream: OutStream; var IsHandled: Boolean)
    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        ExternalStorageImpl.DownloadFromExternalStorageToStream(DocumentAttachment."External File Path", AttachmentOutStream);
        IsHandled := true;
    end;

    /// <summary>
    /// Handles getting the temporary blob for externally stored document attachments.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record.</param>
    /// <param name="TempBlob">The temporary blob to be filled.</param>
    /// <param name="IsHandled">Indicates if the event has been handled.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeGetAsTempBlob, '', false, false)]
    local procedure DocumentAttachment_OnBeforeGetAsTempBlob(var DocumentAttachment: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        ExternalStorageImpl.DownloadFromExternalStorageToTempBlob(DocumentAttachment."External File Path", TempBlob);
        IsHandled := true;
    end;

    /// <summary>
    /// Handles getting content type for externally stored document attachments.
    /// </summary>
    /// <param name="Rec">The document attachment record.</param>
    /// <param name="ContentType">The content type to be set.</param>
    /// <param name="IsHandled">Indicates if the event has been handled.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeGetContentType, '', false, false)]
    local procedure DocumentAttachment_OnBeforeGetContentType(var Rec: Record "Document Attachment"; var ContentType: Text[100]; var IsHandled: Boolean)
    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(Rec) then
            exit;

        ExternalStorageImpl.FileExtensionToContentMimeType(Rec, ContentType);
        IsHandled := true;
    end;

    /// <summary>
    /// Handles checking if attachment content is available for externally stored document attachments.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record.</param>
    /// <param name="AttachmentIsAvailable">Indicates if the attachment is available.</param>
    /// <param name="IsHandled">Indicates if the event has been handled.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeHasContent, '', false, false)]
    local procedure DocumentAttachment_OnBeforeHasContent(var DocumentAttachment: Record "Document Attachment"; var AttachmentIsAvailable: Boolean; var IsHandled: Boolean)
    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        AttachmentIsAvailable := ExternalStorageImpl.CheckIfFileExistInExternalStorage(DocumentAttachment."External File Path");
        IsHandled := true;
    end;

    /// <summary>
    /// Event handler for before checking Document Reference ID on insert.
    /// </summary>
    /// <param name="DocumentAttachment">The document attachment record.</param>
    /// <param name="IsHandled">Indicates if the event has been handled.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnInsertOnBeforeCheckDocRefID, '', false, false)]
    local procedure "Document Attachment_OnInsertOnBeforeCheckDocRefID"(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
        if DocumentAttachment."Stored Externally" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnCopyAttachmentsOnAfterSetToDocumentFilters, '', false, false)]
    local procedure "Document Attachment Mgmt_OnCopyAttachmentsOnAfterSetToDocumentFilters"(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; ToAttachmentDocumentType: Enum "Attachment Document Type"; ToNo: Code[20]; ToLineNo: Integer)
    begin
        ToDocumentAttachment."Skip Delete On Copy" := ToDocumentAttachment."Stored Externally";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeOpenInOneDrive, '', false, false)]
    local procedure "Document Attachment_OnBeforeOpenInOneDrive"(var Rec: Record "Document Attachment"; var IsHandled: Boolean)
    var
        NotSupportedErr: Label 'Opening Document Attachments stored in External Storage via OneDrive is not supported.';
    begin
        if Rec."Stored Externally" then begin
            IsHandled := true;
            Error(NotSupportedErr);
        end;
    end;
    #endregion

    local procedure IsFeatureEnabled(): Boolean
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not ExternalStorageSetup.Get() then
            exit(false);

        exit(ExternalStorageSetup.Enabled);
    end;
}