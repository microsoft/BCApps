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
    local procedure OnBeforeModifyContactSyncUser(var Rec: Record "Contact Sync User"; RunTrigger: Boolean)
    begin
        // Allow upgrade/data-fix updates on legacy rows unless Delta Url is being changed.
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;
        Rec.EnforceRecordOwnershipOnModify(Rec."User ID");
        Session.LogMessage('0000V20', StrSubstNo(OnBeforeModifyTelemetryMsg, 'Record user passed', Rec."Delta Url"), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Contact Sync');
        Rec.ValidateApprovedGraphDeltaUrl(Rec."Delta Url", true);
    end;

    var
        OnBeforeModifyTelemetryMsg: Label 'Contact Sync User OnBeforeModifyEvent was triggered. xRec Delta URL: %1; Rec Delta URL: %2', Locked = true, Comment = '%1 = existing record delta URL (xRec), %2 = incoming record delta URL (Rec)';
}