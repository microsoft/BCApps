// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

codeunit 7100 "Contact Sync UserSubscriber"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertContactSyncUser(var Rec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        Rec.EnforceRecordOwnership();
        Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyContactSyncUser(var Rec: Record "Contact Sync User"; var xRec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin

        // Allow upgrade/data-fix updates on legacy rows unless Delta Url is being changed.
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;
        Rec.EnforceRecordOwnershipOnModify(xRec."User ID");
        if Rec."Delta Url" <> xRec."Delta Url" then
            Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url");
    end;
}