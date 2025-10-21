// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.ExternalFileStorage;
using System.Utilities;
using System.Environment;
using System.Security.Encryption;
using Microsoft.Foundation.Attachment;

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
    procedure BeforeAddOrModifyFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipInsertOrModify: Boolean;
    var
        FileAccount: Record "File Account";
        ConfirmManagement: Codeunit "Confirm Management";
        FileScenarioCU: Codeunit "File Scenario";
        DisclaimerMsg: Label 'You are about to enable External Storage!!!\\This feature is provided as-is, and you use it at your own risk.\Microsoft is not responsible for any issues or data loss that may occur.\\Do you wish to continue?';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        // Search for External Storage assigned File Scenario
        if FileScenarioCU.GetFileAccount(Scenario, FileAccount) then begin
            SkipInsertOrModify := true;
            exit;
        end;

        SkipInsertOrModify := not ConfirmManagement.GetResponseOrDefault(DisclaimerMsg);
    end;

    /// <summary>
    /// Called to get additional setup for a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if additional setup is available, otherwise false.</returns>
    procedure GetAdditionalScenarioSetup(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SetupExist: Boolean;
    var
        ExternalStorageSetup: Page "DA External Storage Setup";
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

        ExternalStorageSetup.RunModal();
        SetupExist := true;
    end;

    /// <summary>
    /// Called before deleting a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the delete operation is handled and should not proceed, otherwise false.</returns>
    procedure BeforeDeleteFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipDelete: Boolean;
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

        SkipDelete := true;
        Message(NotPossibleToUnassignScenarioMsg);
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
        LogFeatureUsedTelemetry();

        // Get file content from document attachment
        TempBlob.CreateOutStream(OutStream);
        DocumentAttachment.ExportToStream(OutStream);
        TempBlob.CreateInStream(InStream);

        // Generate unique filename to prevent collisions
        FileName := GetFilePathWithRootFolder(DocumentAttachment);

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Create the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        if ExternalFileStorage.CreateFile(FileName, InStream) then begin
            DocumentAttachment."Uploaded Externally" := true;
            DocumentAttachment."External Upload Date" := CurrentDateTime();
            DocumentAttachment."External File Path" := FileName;
            DocumentAttachment."Source Environment Hash" := GetCurrentEnvironmentHash();
            DocumentAttachment.Modify();
            LogFileUploadedTelemetry();
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

        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

        // Use the stored external file path
        ExternalFilePath := DocumentAttachment."External File Path";
        FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        ExternalFileStorage.GetFile(ExternalFilePath, InStream);

        if DownloadFromStream(InStream, '', '', '', FileName) then begin
            LogFileDownloadedTelemetry();
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

        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

        // Use the stored external file path
        ExternalFilePath := DocumentAttachment."External File Path";
        FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";

        // Search for External Storage assigned File Scenario
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Get the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        ExternalFileStorage.GetFile(ExternalFilePath, InStream);

        // Import the file into the Document Attachment
        DocumentAttachment.ImportAttachment(InStream, FileName);
        DocumentAttachment."Deleted Internally" := false;
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
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
        FileScenario: Enum "File Scenario";
        ExternalFilePath: Text;
    begin
        // Check if feature is enabled
        if not IsFeatureEnabled() then
            exit(false);

        // Validate input parameters
        if DocumentAttachment."External File Path" = '' then
            exit(false);

        if not DocumentAttachment."Uploaded Externally" then
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
            exit(false);

        // Delete the file with connector using the File Account framework
        ExternalFileStorage.Initialize(FileScenario);
        if ExternalFileStorage.DeleteFile(ExternalFilePath) then begin
            DocumentAttachment.MarkAsNotUploadedToExternal();
            LogFileDeletedTelemetry();
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
        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

        // Delete from Tenant Media
        if TenantMedia.Get(DocumentAttachment."Document Reference ID".MediaId()) then begin
            TenantMedia.Delete();

            // Mark Document Attachment as Deleted Internally
            DocumentAttachment.MarkAsDeletedInternally();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Determines if files should be deleted immediately based on external storage setup.
    /// </summary>
    /// <returns>True if files should be deleted immediately, false otherwise.</returns>
    procedure ShouldBeDeleted(): Boolean
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not ExternalStorageSetup.Get() then
            exit(false);

        exit(CalcDate(ExternalStorageSetup."Delete After", Today()) <= Today());
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
    /// Checks if a Document Attachment file is uploaded to external storage and deleted internally.
    /// </summary>
    /// <param name="DocumentAttachment">The Document Attachment record to check.</param>
    /// <returns>True if the file is uploaded and deleted, false otherwise.</returns>
    procedure IsFileUploadedToExternalStorageAndDeletedInternally(var DocumentAttachment: Record "Document Attachment"): Boolean
    begin
        if not DocumentAttachment."Deleted Internally" then
            exit(false);

        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

        if DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);

        if DocumentAttachment."External File Path" = '' then
            exit(false);
        exit(true);
    end;
    #endregion

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

        if not ExternalStorageSetup."Scheduled Upload" then
            exit;

        // Only process files with actual content
        if not Rec."Document Reference ID".HasValue() then
            exit;

        // Upload to external storage
        if not ExternalStorageImpl.UploadToExternalStorage(Rec) then
            exit;

        // Check if it should be immediately deleted
        if ExternalStorageImpl.ShouldBeDeleted() then
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
        if not Rec."Uploaded Externally" then
            exit;

        // Delete from external storage
        ExternalStorageImpl.DeleteFromExternalStorage(Rec);
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
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
        EnvironmentHashFolder: Text[16];
        FileNamePart: Text;
    begin
        // Generate unique filename to prevent collisions
        FileNamePart := DocumentAttachment."File Name" + '-' + DelChr(Format(CreateGuid()), '=', '{}') + '.' + DocumentAttachment."File Extension";

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
        RecRef: RecordRef;
        TableName: Text;
    begin
        // Open the RecordRef to get table metadata
        RecRef.Open(TableID, false);
        TableName := RecRef.Name;
        RecRef.Close();

        // Replace invalid characters for folder names
        TableName := DelChr(TableName, '=', '<>:"/\|?*');
        TableName := ConvertStr(TableName, ' ', '_');

        exit(CopyStr(TableName, 1, 100));
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
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
            exit;

        ExternalFileStorage.Initialize(FileScenario);

        // Check if directory exists, if not create it
        if not ExternalFileStorage.DirectoryExists(CompanyFolderPath) then
            ExternalFileStorage.CreateDirectory(CompanyFolderPath);
    end;

    local procedure GetCurrentEnvironmentHash(): Text[16]
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

        // Generate SHA256 hash and take first 16 characters
        exit(CopyStr(CryptographyManagement.GenerateHash(IdentityString, HashAlgorithmType::SHA256), 1, 16));
    end;

    local procedure IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment: Record "Document Attachment"): Boolean
    var
        CurrentEnvironmentHash: Text[16];
    begin
        // If no source environment hash is set, assume it belongs to current environment
        if DocumentAttachment."Source Environment Hash" = '' then
            exit(false);

        CurrentEnvironmentHash := GetCurrentEnvironmentHash();
        exit(DocumentAttachment."Source Environment Hash" <> CurrentEnvironmentHash);
    end;

    local procedure MigrateFileToCurrentEnvironment(var DocumentAttachment: Record "Document Attachment"): Boolean
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
        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

        if DocumentAttachment."External File Path" = '' then
            exit(false);

        // Initialize external file storage
        FileScenario := FileScenario::"Doc. Attach. - External Storage";
        if not FileScenarioCU.GetFileAccount(FileScenario, FileAccount) then
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
        MigratedCount: Integer;
        StartMigrationQst: Label 'This will migrate all document attachments from the previous company folder to the current company folder.\\Do you want to continue?';
        MigrationCompletedMsg: Label '%1 file(s) have been successfully migrated to the current company folder.', Comment = '%1 = Number of files';
    begin
        if not Confirm(StartMigrationQst, false) then
            exit(0);

        MigratedCount := 0;
        DocumentAttachment.SetRange("Uploaded Externally", true);
        DocumentAttachment.SetFilter("External File Path", '<>%1', '');
        if DocumentAttachment.FindSet(true) then
            repeat
                if IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment) then
                    if MigrateFileToCurrentEnvironment(DocumentAttachment) then
                        MigratedCount += 1;
            until DocumentAttachment.Next() = 0;

        if MigratedCount > 0 then begin
            LogCompanyMigrationTelemetry();
            Message(MigrationCompletedMsg, MigratedCount);
        end;

        exit(MigratedCount);
    end;

    /// <summary>
    /// Shows the current environment hash for use in another environment.
    /// </summary>
    procedure ShowCurrentEnvironmentHash()
    var
        CurrentHash: Text[16];
        HashCopiedMsg: Label 'Current environment hash: %1', Comment = '%1 = Hash value';
    begin
        CurrentHash := GetCurrentEnvironmentHash();
        Message(HashCopiedMsg, CurrentHash);
    end;

    #region Telemetry Logging
    local procedure LogFeatureUsedTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogFeatureUsed();
    end;

    local procedure LogFileUploadedTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogFileUploaded();
    end;

    local procedure LogFileDownloadedTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogFileDownloaded();
    end;

    local procedure LogFileDeletedTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogFileDeleted();
    end;

    local procedure LogCompanyMigrationTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogCompanyMigration();
    end;

    local procedure IsFeatureEnabled(): Boolean
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not ExternalStorageSetup.Get() then
            exit(false);

        exit(ExternalStorageSetup.Enabled);
    end;
    #endregion
}