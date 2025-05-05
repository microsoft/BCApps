// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// Provides methods to handle webhook notifications from external resources
/// </summary>
codeunit 9333 "Webhook Notification"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        WebhookSubscriptionImpl: Codeunit "Webhook Subscription Impl.";
        WebhookNotificationImpl: Codeunit "Webhook Notification Impl.";
        CallerModuleInfo: ModuleInfo;

    /// <summary>
    /// Gets the notification JSON object for the given parameters.
    /// </summary>
    /// <param name="ID">The ID of the notification.</param>
    /// <param name="ResourceTypeName">The resource type name.</param>
    /// <param name="SequenceNumber">The sequence number of the notification.</param>
    /// <param name="SubscriptionId">The subscription ID.</param>
    /// <returns>The JSON object representing the notification.</returns>
    procedure GetNotificationJson(ID: Guid; ResourceTypeName: Text[250]; SequenceNumber: Integer; SubscriptionId: Text[150]): JsonObject
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        exit(WebhookNotificationImpl.GetNotificationJson(ID, ResourceTypeName, SequenceNumber, SubscriptionId));
    end;

    /// <summary>
    /// Integration event, raised when a webhook notification is inserted.
    /// </summary>
    /// <param name="NotificationSystemId">The system ID of the notification.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [NonDebuggable]
    internal procedure OnWebhookNotificationInsert(ID: Guid; ResourceTypeName: Text[250]; SequenceNumber: Integer; SubscriptionId: Text[150]; IsTemporary: Boolean)
    begin
    end;
}