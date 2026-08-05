// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;

codeunit 6907 "Expense Doc. Att. Subscribers"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnInsertOnBeforeCheckDocRefID, '', false, false)]
    local procedure OnInsertOnBeforeCheckDocRefID(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
        //This will ensure that Document attachment is not checking attachment content on insert trigger when sending 
        //Expense report line documents through API as there will be a POST and PUT request from agent.
        IsHandled := true;
    end;
}