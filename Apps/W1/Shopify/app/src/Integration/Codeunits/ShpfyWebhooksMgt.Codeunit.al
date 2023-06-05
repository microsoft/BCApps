codeunit 30269 "Shpfy Webhooks Mgt."
{
    Access = Internal;
    Permissions = TableData "Webhook Subscription" = rimd;

    var
        ProcessingWebhookNotificationTxt: Label 'Processing webhook notification.', Locked = true;
        WebhookSubscriptionNotFoundTxt: Label 'Webhook subscription is not found.', Locked = true;
        ShopNotFoundTxt: Label 'Shop is not found.', Locked = true;
        ProcessingNotificationTxt: Label 'Processing notification.', Locked = true;
        ReadyJobFoundTxt: Label 'A job queue entry in ready state already exists. Skipping notification.', Locked = true;
        CategoryTok: Label 'Shopify Integration', Locked = true;
        JobQueueCategoryLbl: Label 'SHPFY', Locked = true;
        WebhookRegistrationFailedErr: Label 'Failed to register webhook with Shopify';

    [EventSubscriber(ObjectType::Table, Database::"Webhook Notification", 'OnAfterInsertEvent', '', false, false)]
    local procedure HandleOnWebhookNotificationInsert(var Rec: Record "Webhook Notification"; RunTrigger: Boolean);
    var
        WebhookSubscription: Record "Webhook Subscription";
        Shop: Record "Shpfy Shop";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if Rec.IsTemporary() then
            exit;

        Session.LogMessage('0000K8G', ProcessingWebhookNotificationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        WebhookSubscription.SetRange("Subscription ID", Rec."Subscription ID");
        WebhookSubscription.SetRange(Endpoint, Rec."Resource Type Name");
        if WebhookSubscription.IsEmpty() then begin
            Session.LogMessage('0000K8H', WebhookSubscriptionNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        Shop.SetRange("Shopify URL", GetShopUrl(Rec."Subscription ID"));
        Shop.SetRange("Order Created Webhooks", true);
        if not Shop.FindFirst() then begin
            Shop.SetRange("Shopify URL", GetShopUrl(Rec."Subscription ID").TrimEnd('/'));
            if not Shop.FindFirst() then begin
                Session.LogMessage('0000K8I', ShopNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                exit;
            end;
        end;

        Session.LogMessage('0000K8J', ProcessingNotificationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        FeatureTelemetry.LogUptake('0000K8D', 'Shopify Webhooks', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000K8F', 'Shopify Webhooks', 'Shopify sales order webhooks enabled.');
        ProcessNotification(Shop);
        Commit();
    end;

    internal procedure EnableOrderCreatedWebhook(var Shop: Record "Shpfy Shop")
    var
        ShpfyWebhooksAPI: Codeunit "Shpfy Webhooks API";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SubscriptionId: Text;
    begin
        if ShpfyWebhooksAPI.GetWebhookSubscription(Shop, 'orders/create', SubscriptionId) then
            ShpfyWebhooksAPI.DeleteWebhookSubscription(Shop, SubscriptionId);
        SubscriptionId := ShpfyWebhooksAPI.RegisterWebhookSubscription(Shop, 'orders/create');
        if SubscriptionId <> '' then begin
            CreateWebhookSubscription(Shop);
            Shop."Order Created Webhook Id" := CopyStr(SubscriptionId, 1, MaxStrLen(Shop."Order Created Webhook Id"));
            Shop.Modify();
        end else
            Error(WebhookRegistrationFailedErr);

        FeatureTelemetry.LogUptake('0000K8E', 'Shopify Webhooks', Enum::"Feature Uptake Status"::"Set up");
    end;

    internal procedure DisableOrderCreatedWebhook(var Shop: Record "Shpfy Shop")
    var
        WebhookSubscription: Record "Webhook Subscription";
        ShpfyWebhooksAPI: Codeunit "Shpfy Webhooks API";
    begin
        WebhookSubscription.SetRange("Subscription ID", GetShopDomain(Shop."Shopify URL"));
        WebhookSubscription.SetRange("Company Name", CopyStr(CompanyName(), 1, MaxStrLen(WebhookSubscription."Company Name")));
        WebhookSubscription.SetRange(Endpoint, 'orders/create');
        if WebhookSubscription.FindFirst() then begin
            ShpfyWebhooksAPI.DeleteWebhookSubscription(Shop, Shop."Order Created Webhook Id");
            Clear(Shop."Order Created Webhook Id");
            Shop.Modify();
            WebhookSubscription.Delete();
        end;
    end;

    local procedure CreateWebhookSubscription(var Shop: Record "Shpfy Shop")
    var
        WebhookSubscription: Record "Webhook Subscription";
    begin
        WebhookSubscription."Subscription ID" := CopyStr(GetShopDomain(Shop."Shopify URL"), 1, MaxStrLen(WebhookSubscription."Subscription ID"));
        WebhookSubscription."Created By" := Shop.Code;
        WebhookSubscription."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(WebhookSubscription."Company Name"));
        WebhookSubscription.Endpoint := 'orders/create';
        WebhookSubscription."Run Notification As" := SetWebhookSubscriptionUserAsCurrentUser(Shop);
        WebhookSubscription.Insert();
    end;

    local procedure SetWebhookSubscriptionUserAsCurrentUser(var Shop: Record "Shpfy Shop"): Guid
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        if Shop."Order Created Webhook User Id" <> UserSecurityID() then
            if WebhookManagement.IsValidNotificationRunAsUser(UserSecurityID()) then begin
                Shop.Validate("Order Created Webhook User Id", UserSecurityID());
                Shop.Modify();
            end;

        exit(Shop."Order Created Webhook User Id");
    end;

    local procedure ProcessNotification(Shop: Record "Shpfy Shop")
    var
        JobQueueEntry: Record "Job Queue Entry";
        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
    begin
        Shop.SetFilter(Code, Shop.Code);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Shpfy Sync Orders from Shopify");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet() then
            repeat
                if JobQueueEntry.GetXmlContent().Contains(Shop.GetView()) then begin // There is already a ready job for this shop, therefor no need to schedule a new one
                    Session.LogMessage('0000K8K', ReadyJobFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    exit;
                end;
            until JobQueueEntry.Next() = 0;
        BackgroundSyncs.SyncAllOrders(Shop);
    end;

    local procedure GetShopDomain(ShopUrl: Text[250]): Text
    begin
        exit(ShopUrl.Replace('https://', '').Replace('.myshopify.com', '').TrimEnd('/'));
    end;

    local procedure GetShopUrl(ShopDomain: Text): Text
    begin
        exit('https://' + ShopDomain + '.myshopify.com/');
    end;
}