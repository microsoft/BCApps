// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

codeunit 9332 "Webhook Subscription Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = TableData "Webhook Subscription" = rimd;

    var
        WebhookSubscription: Record "Webhook Subscription";
        CallExternalErr: Label 'Webhook module can only be used internally.';

    internal procedure AssertInternalCall(CallerModuleInfo: ModuleInfo)
    begin
        if CallerModuleInfo.Publisher <> 'Microsoft' then
            Error(CallExternalErr);
    end;

    internal procedure Initialize(SubscriptionId: Text[150]; Endpoint: Text[250]): Boolean
    begin
        WebhookSubscription.SetRange("Subscription ID", SubscriptionId);
        WebhookSubscription.SetRange(Endpoint, Endpoint);
        if WebhookSubscription.IsEmpty() then
            exit(false);

        WebhookSubscription.FindFirst();
        exit(true);
    end;

    internal procedure CompanyName(): Text[30]
    begin
        exit(WebhookSubscription."Company Name");
    end;

    internal procedure NotificationUserId(): Guid
    begin
        exit(WebhookSubscription."Run Notification As");
    end;

    internal procedure UpdateCompanyName(NewCompanyName: Text[30])
    begin
        WebhookSubscription."Company Name" := NewCompanyName;
        WebhookSubscription.Modify();
    end;

    internal procedure Create(SubscriptionId: Text[150]; Endpoint: Text[250]; CreatedBy: Code[50]; Company: Text[30]; UserId: Guid)
    var
        NewWebhookSubscription: Record "Webhook Subscription";
    begin
        NewWebhookSubscription."Subscription ID" := SubscriptionId;
        NewWebhookSubscription.Endpoint := Endpoint;
        NewWebhookSubscription."Created By" := CreatedBy;
        NewWebhookSubscription."Company Name" := Company;
        NewWebhookSubscription."Run Notification As" := UserId;
        NewWebhookSubscription.Insert();

        WebhookSubscription := NewWebhookSubscription;
    end;

    internal procedure Delete()
    begin
        WebhookSubscription.Delete();
    end;

    internal procedure UpdateAllEndpoints(OldEndpoint: Text; NewEndpoint: Text)
    var
        UpdateWebhookSubscription: Record "Webhook Subscription";
    begin
        UpdateWebhookSubscription.SetRange(Endpoint, OldEndpoint);
        UpdateWebhookSubscription.ModifyAll(Endpoint, NewEndpoint);
    end;
}