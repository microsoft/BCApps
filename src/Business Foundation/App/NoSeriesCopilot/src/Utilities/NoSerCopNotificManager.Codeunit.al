// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.NoSeries;

codeunit 348 "No. Ser. Cop. Notific. Manager"
{
    Access = Internal;
    local procedure GetNotificationId(): Guid
    begin
        exit('1fd2bfd6-6542-4574-8a88-f8247f4b8334');
    end;

    procedure RecallNotification()
    var
        Notification: Notification;
    begin
        Notification.Id := GetNotificationId();
        Notification.Recall();
    end;

    procedure SendNotification(NotificationMessage: Text)
    var
        Notification: Notification;
    begin
        Notification.Id := GetNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Recall();
        Notification.Message := NotificationMessage;
        Notification.Send();
    end;
}