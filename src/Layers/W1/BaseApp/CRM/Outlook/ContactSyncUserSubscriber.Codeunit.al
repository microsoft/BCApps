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
        Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url", true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Sync User", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyContactSyncUser(var Rec: Record "Contact Sync User"; var xRec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        Session.LogMessage('0000V1Z', StrSubstNo(UserModifiedMsg, xRec."User ID", Rec."User ID"), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Contact Sync');

        // Allow upgrade/data-fix updates on legacy rows unless Delta Url is being changed.
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;
        Rec.EnforceRecordOwnershipOnModify(xRec."User ID");
        Session.LogMessage('0000V20', StrSubstNo(OnBeforeModifyTelemetryMsg, xRec."Delta Url", Rec."Delta Url"), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Contact Sync');
        if Rec."Delta Url" <> xRec."Delta Url" then
            Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url", true);
    end;

    var
        OnBeforeModifyTelemetryMsg: Label 'Contact Sync User OnBeforeModifyEvent was triggered. xRec Delta URL: %1; Rec Delta URL: %2', Locked = true, Comment = '%1 = existing record delta URL (xRec), %2 = incoming record delta URL (Rec)';
        UserModifiedMsg: Label 'Contact Sync User OnBeforeModifyEvent was triggered. xRec User ID: %1; Rec User ID: %2', Locked = true, Comment = '%1 = existing record user ID (xRec), %2 = incoming record user ID (Rec)';
}