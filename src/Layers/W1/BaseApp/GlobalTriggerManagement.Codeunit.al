// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.API.Webhooks;
using Microsoft.Integration.Dataverse;
using System.Diagnostics;

codeunit 49 GlobalTriggerManagement
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure GetGlobalTableTriggerMask(TableID: Integer; var TableTriggerMask: Integer)
    begin
        OnAfterGetGlobalTableTriggerMask(TableID, TableTriggerMask);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    begin
        OnAfterOnGlobalInsert(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        OnAfterOnGlobalModify(RecRef, xRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    begin
        OnAfterOnGlobalDelete(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        OnAfterOnGlobalRename(RecRef, xRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
    begin
        CRMIntegrationManagement.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        APIWebhookNotificationMgt.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        OnAfterGetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);

        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then
            ChangeLogMgt.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then
            ChangeLogMgt.LogInsertion(RecRef);

        IsHandled := false;
        OnBeforeOnDatabaseInsert(RecRef, IsHandled);
        if not IsHandled then begin
            CRMIntegrationManagement.OnDatabaseInsert(RecRef);
            APIWebhookNotificationMgt.OnDatabaseInsert(RecRef);
        end;
        OnAfterOnDatabaseInsert(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then
            ChangeLogMgt.LogModification(RecRef);

        IsHandled := false;
        OnBeforeOnDatabaseModify(RecRef, IsHandled);
        if not IsHandled then begin
            CRMIntegrationManagement.OnDatabaseModify(RecRef);
            APIWebhookNotificationMgt.OnDatabaseModify(RecRef);
        end;
        OnAfterOnDatabaseModify(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then
            ChangeLogMgt.LogDeletion(RecRef);

        IsHandled := false;
        OnBeforeOnDatabaseDelete(RecRef, IsHandled);
        if not IsHandled then
            APIWebhookNotificationMgt.OnDatabaseDelete(RecRef);
        OnAfterOnDatabaseDelete(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then
            ChangeLogMgt.LogRename(RecRef, xRecRef);

        IsHandled := false;
        OnBeforeOnDatabaseRename(RecRef, xRecRef, IsHandled);
        if not IsHandled then begin
            CRMIntegrationManagement.OnDatabaseRename(RecRef, xRecRef);
            APIWebhookNotificationMgt.OnDatabaseRename(RecRef, xRecRef);
        end;
        OnAfterOnDatabaseRename(RecRef, xRecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGlobalTableTriggerMask(TableID: Integer; var TableTriggerMask: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalInsert(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalDelete(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseInsert(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseModify(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseDelete(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseInsert(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseModify(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseDelete(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;
}
