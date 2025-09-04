// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Utilities;

/// <summary>
/// Event subscribers for External Storage functionality.
/// Handles automatic upload of new attachments and cleanup operations.
/// </summary>
codeunit 8752 "DA External Storage Subs."
{
    Access = Internal;
    Permissions = tabledata "DA External Storage Setup" = r;

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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Exit early if trigger is not running
        if not RunTrigger then
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
        if not ExternalStorageProcessor.UploadToExternalStorage(Rec) then
            exit;

        // Check if it should be immediately deleted
        if ExternalStorageProcessor.ShouldBeDeleted() then
            ExternalStorageProcessor.DeleteFromInternalStorage(Rec);
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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Exit early if trigger is not running
        if not RunTrigger then
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
        ExternalStorageProcessor.DeleteFromExternalStorage(Rec);
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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageProcessor.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        ExternalStorageProcessor.DownloadFromExternalStorageToStream(DocumentAttachment."External File Path", AttachmentOutStream);
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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageProcessor.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        ExternalStorageProcessor.DownloadFromExternalStorageToTempBlob(DocumentAttachment."External File Path", TempBlob);
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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageProcessor.IsFileUploadedToExternalStorageAndDeletedInternally(Rec) then
            exit;

        ExternalStorageProcessor.FileExtensionToContentMimeType(Rec, ContentType);
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
        ExternalStorageProcessor: Codeunit "DA External Storage Processor";
    begin
        // Only handle if file is uploaded externally and not available internally
        if not ExternalStorageProcessor.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment) then
            exit;

        AttachmentIsAvailable := ExternalStorageProcessor.CheckIfFileExistInExternalStorage(DocumentAttachment."External File Path");
        IsHandled := true;
    end;
    #endregion
}
