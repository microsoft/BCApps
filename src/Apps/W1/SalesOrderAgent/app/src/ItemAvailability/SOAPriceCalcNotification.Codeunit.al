// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using System.Environment.Configuration;

codeunit 4414 "SOA Price Calc. Notification"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure ShowCallStack(PriceCalcNotification: Notification)
    begin
        Message(PriceCalcNotification.GetData('CallStack'));
    end;

    internal procedure DisableNotification(PriceCalcNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationId()) then
            MyNotifications.InsertDefault(GetNotificationId(), CopyStr(PriceCalcNotificationNameLbl, 1, 128), PriceCalcNotificationDescLbl, false);
    end;

    internal procedure IsEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationId()));
    end;

    internal procedure GetNotificationId(): Guid
    begin
        exit(NotificationIdTok);
    end;

    var
        NotificationIdTok: Label 'f90d8b42-1d6a-4e3c-8b5f-7a9c2e4d6b81', Locked = true;
        PriceCalcNotificationNameLbl: Label 'Price calculation errors on Item Availability page';
        PriceCalcNotificationDescLbl: Label 'Show a notification when price calculation fails on the Item Availability page.';
}
