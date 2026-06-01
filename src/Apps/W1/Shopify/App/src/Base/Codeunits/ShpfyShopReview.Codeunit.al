// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30407 "Shpfy Shop Review"
{
    Access = Internal;

    procedure OpenReviewLink(Notification: Notification)
    var
        StoreURL: Text;
    begin
        Hyperlink(GetReviewLink());

        StoreURL := Notification.GetData(GetStoreNameKey());
        if StoreURL <> '' then
            MarkStoreAsReviewed(StoreURL);
    end;

    procedure OpenReviewLinkFromShop(StoreURL: Text)
    begin
        Hyperlink(GetReviewLink());

        MarkStoreAsReviewed(StoreURL);
    end;

    procedure MarkReviewCompleted(Notification: Notification)
    var
        StoreURL: Text;
    begin
        StoreURL := Notification.GetData(GetStoreNameKey());
        if StoreURL <> '' then
            MarkStoreAsReviewed(StoreURL);
    end;

    local procedure MarkStoreAsReviewed(StoreURL: Text)
    var
        RegisteredStore: Record "Shpfy Registered Store New";
    begin
        if not RegisteredStore.Get(StoreURL) then
            exit;

        RegisteredStore."Review Completed" := true;
        RegisteredStore.Modify(true);
    end;

    local procedure GetReviewLink(): Text
    begin
        exit('https://aka.ms/bcshopifyvote');
    end;

    procedure MaybeShowReviewReminder(StoreURL: Text)
    var
        RegisteredStore: Record "Shpfy Registered Store New";
        OrderHeader: Record "Shpfy Order Header";
    begin
        if not RegisteredStore.Get(StoreURL) then
            exit;

        if RegisteredStore."Review Completed" then
            exit;

        if RegisteredStore."Review Prompt Date" <> 0D then
            if RegisteredStore."Review Prompt Date" > CalcDate('<-60D>', Today()) then
                exit;

        OrderHeader.SetRange(Processed, true);
        if OrderHeader.Count() < GetReviewReminderMinimumProcessedOrders() then
            exit;

        ShowReviewReminder(RegisteredStore);
    end;

    local procedure ShowReviewReminder(var RegisteredStore: Record "Shpfy Registered Store New")
    var
        ReminderNotification: Notification;
    begin
        RegisteredStore."Review Prompt Date" := Today();
        RegisteredStore.Modify(true);

        ReminderNotification.Id := GetReviewReminderNotificationId();
        ReminderNotification.Message := ReviewReminderMessageTxt;
        ReminderNotification.Scope := NotificationScope::LocalScope;
        ReminderNotification.SetData(GetStoreNameKey(), RegisteredStore.Store);
        ReminderNotification.AddAction(ReviewReminderReviewActionLbl, Codeunit::"Shpfy Shop Review", 'OpenReviewLink');
        ReminderNotification.AddAction(ReviewReminderAlreadyDidActionLbl, Codeunit::"Shpfy Shop Review", 'MarkReviewCompleted');
        ReminderNotification.Send();

        LogReviewReminderTelemetry();
    end;

    local procedure LogReviewReminderTelemetry()
    begin
        Session.LogMessage('0000QN1', ReviewReminderTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure GetReviewReminderNotificationId(): Guid
    begin
        exit('5aab1677-6f6a-4f86-9eca-3ad3dfd986b2');
    end;

    local procedure GetReviewReminderMinimumProcessedOrders(): Integer
    begin
        exit(10);
    end;

    local procedure GetStoreNameKey(): Text
    begin
        exit('StoreURL');
    end;

    var
        ReviewReminderMessageTxt: Label 'Relying on the Shopify connector for integration? Leave a review in the Shopify App Store to help others discover it.';
        ReviewReminderReviewActionLbl: Label 'Review';
        ReviewReminderAlreadyDidActionLbl: Label 'Already did';
        ReviewReminderTelemetryMsg: Label 'Shopify review reminder notification displayed.', Locked = true;
        CategoryTok: Label 'Shopify Integration', Locked = true;
}
