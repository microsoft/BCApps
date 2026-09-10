// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using System.Utilities;

codeunit 148350 "Expense Attach. Failure Mock"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        AttachmentRetrievalFailedErr: Label 'The attachment could not be retrieved.', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeGetAsTempBlob, '', false, false)]
    local procedure FailOnBeforeGetAsTempBlob(var DocumentAttachment: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
        Error(AttachmentRetrievalFailedErr);
    end;
}
