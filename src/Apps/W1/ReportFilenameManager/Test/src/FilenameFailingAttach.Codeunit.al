// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Attachment;

codeunit 149538 "Filename Failing Attach"
{
    // Raises an error in Document Attachment.OnAfterInitFieldsFromRecRef. In Attach as PDF,
    // Report Selections.SaveDocumentAttachmentFromRecRef calls InitFieldsFromRecRef after
    // OnBeforeSaveDocumentAttachmentFromRecRef and before SaveAttachment, so Attach as PDF fails
    // after arming and before saving. Bound manually.

    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure FailBeforeTheSave(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
        Error(AttachFailedErr);
    end;

    internal procedure FailureText(): Text
    begin
        exit(AttachFailedErr);
    end;

    var
        AttachFailedErr: Label 'Attach as PDF failed before saving.', Locked = true;
}
