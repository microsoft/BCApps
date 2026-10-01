// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

codeunit 7100 "Contact Sync User Subscriber"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertContactSyncUser(var Rec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        Rec.EnforceRecordOwnership();
        if not Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url") then
            Error(InvalidDeltaUrlErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyContactSyncUser(RunTrigger: Boolean; var Rec: Record "Contact Sync User"; var xRec: Record "Contact Sync User")
    begin
        // Allow upgrade/data-fix updates on legacy rows unless Delta Url is being changed.
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;
        Rec.EnforceRecordOwnershipOnModify(xRec."User ID");
        if not Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url") then
            Error(InvalidDeltaUrlErr);
    end;

    var
        InvalidDeltaUrlErr: Label 'The Delta URL must be an HTTPS Microsoft Graph URL.';
}

