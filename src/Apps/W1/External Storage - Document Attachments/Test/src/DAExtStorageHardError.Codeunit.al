// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.Foundation.Attachment;

codeunit 136821 "DA Ext. Storage Hard Error"
{
    EventSubscriberInstance = Manual;

    var
        FailureRecordId: RecordId;
        FailureMessage: Text;
        Enabled: Boolean;

    procedure FailOnModify(DocumentAttachment: Record "Document Attachment"; NewFailureMessage: Text)
    begin
        FailureRecordId := DocumentAttachment.RecordId();
        FailureMessage := NewFailureMessage;
        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeModifyEvent, '', false, false)]
    local procedure DocumentAttachmentOnBeforeModify(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    begin
        if not Enabled then
            exit;
        if Rec.RecordId() <> FailureRecordId then
            exit;

        Enabled := false;
        Error(FailureMessage);
    end;
}
