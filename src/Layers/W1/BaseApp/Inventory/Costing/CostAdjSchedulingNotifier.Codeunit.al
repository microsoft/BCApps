// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Setup;

codeunit 2848 "Cost Adj. Scheduling Notifier"
{
    SingleInstance = true;

    var
        NotificationHandler: Codeunit "Cost Adj. Sch. Notif. Handler";
        ScheduleNotificationTxt: Label 'If you turn off automatic cost adjustments or posting, you must do those tasks manually or schedule a job queue entry to run in the background.';
        ScheduleActionLbl: Label 'Schedule a job queue entry';
        LearnMoreActionLbl: Label 'Learn more';

    local procedure ShowScheduleJobNotification()
    var
        ScheduleJobNotification: Notification;
    begin
        ScheduleJobNotification.Id := GetNotificationId();
        ScheduleJobNotification.Message(ScheduleNotificationTxt);
        ScheduleJobNotification.AddAction(ScheduleActionLbl, Codeunit::"Cost Adj. Scheduling Notifier", 'OnActionSchedule');
        ScheduleJobNotification.AddAction(LearnMoreActionLbl, Codeunit::"Cost Adj. Scheduling Notifier", 'OnActionLearnMore');
        ScheduleJobNotification.Send();
        OnNotificationSent();
    end;

    procedure OnActionSchedule(Notification: Notification)
    begin
        NotificationHandler.OnActionSchedule();
    end;

    procedure OnActionLearnMore(Notification: Notification)
    begin
        NotificationHandler.OnActionLearnMore();
    end;

    local procedure GetNotificationId(): Guid
    begin
        exit('88be0de1-dcdd-4c4b-aaef-a63aec203661');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Inventory Setup", 'OnAfterValidateEvent', 'Automatic Cost Posting', false, false)]
    local procedure OnAfterValidateAutomaticCostPosting(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup")
    begin
        if NotificationHandler.ShouldDisplayNotification(Rec, xRec) then
            ShowScheduleJobNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Inventory Setup", 'OnAfterValidateEvent', 'Automatic Cost Adjustment', false, false)]
    local procedure OnAfterValidateAutomaticCostAdjustment(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup")
    begin
        if NotificationHandler.ShouldDisplayNotification(Rec, xRec) then
            ShowScheduleJobNotification();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNotificationSent()
    begin
    end;
}
