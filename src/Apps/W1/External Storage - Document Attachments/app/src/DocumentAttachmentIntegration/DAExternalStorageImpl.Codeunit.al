// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.ExternalFileStorage;
using System.Utilities;
using System.Environment;
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
        ConfirmManagement: Codeunit "Confirm Management";
        DisclaimerMsg: Label 'You are about to enable External Storage!!!\\This feature is provided as-is, and you use it at your own risk.\Microsoft is not responsible for any issues or data loss that may occur.\\Do you wish to continue?';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage") then
            exit;

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
        // Validate input parameters
        if not DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);

        // Check if document is already uploaded
        if DocumentAttachment."External File Path" <> '' then
            exit(false);

        // Get file content from document attachment
        TempBlob.CreateOutStream(OutStream);
        DocumentAttachment.ExportToStream(OutStream);
        TempBlob.CreateInStream(InStream);

        // Generate unique filename to prevent collisions
        FileName := DocumentAttachment."File Name" + '-' + Format(CreateGuid()) + '.' + DocumentAttachment."File Extension";

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
            DocumentAttachment.Modify();
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

        exit(DownloadFromStream(InStream, '', '', '', FileName));
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
        // Validate input parameters
        if DocumentAttachment."External File Path" = '' then
            exit(false);

        if not DocumentAttachment."Uploaded Externally" then
            exit(false);

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

        if not ExternalStorageSetup."Auto Upload" then
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

        if not ExternalStorageSetup."Auto Delete" then
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
}