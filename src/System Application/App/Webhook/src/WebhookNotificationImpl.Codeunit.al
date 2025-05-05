// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

codeunit 9334 "Webhook Notification Impl."
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        WebhookNotification: Codeunit "Webhook Notification";

    [EventSubscriber(ObjectType::Table, Database::"Webhook Notification", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnWebhookNotificationInsert(var Rec: Record "Webhook Notification"; RunTrigger: Boolean)
    begin
        WebhookNotification.OnWebhookNotificationInsert(Rec.ID, Rec."Resource Type Name", Rec."Sequence Number", Rec."Subscription ID", Rec.IsTemporary());
    end;

    internal procedure GetNotificationJson(ID: Guid; ResourceTypeName: Text[250]; SequenceNumber: Integer; SubscriptionId: Text[150]): JsonObject
    var
        WebhookNotificationRec: Record "Webhook Notification";
        NotificationInStream: InStream;
        NotificationText: Text;
        NotificationJsonObject: JsonObject;
    begin
        if not WebhookNotificationRec.Get(ID, ResourceTypeName, SequenceNumber, SubscriptionId) then
            exit;

        WebhookNotificationRec.CalcFields(Notification);
        WebhookNotificationRec.Notification.CreateInStream(NotificationInStream);
        NotificationInStream.ReadText(NotificationText);
        NotificationJsonObject.ReadFrom(NotificationText);
        exit(NotificationJsonObject);
    end;
}