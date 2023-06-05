codeunit 139612 "Shpfy Webhooks Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Shopify]
        IsInitialized := false;
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;

        WebhooksSubcriber: Codeunit "Shpfy Webhooks Subscriber";
        SubscriptionId: Text;
        IsInitialized: Boolean;

    local procedure Initialize()

    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        SubscriptionId := Any.AlphanumericText(10);
        WebhooksSubcriber.InitCreateWebhookResponse(CreateShopifyWebhookCreateJson(), CreateShopifyWebhookDeleteJson(), CreateShopifyEmptyWebhookJson());
        UnbindSubscription(WebhooksSubcriber);
    end;

    local procedure Clear()
    var
        JobQueueEntry: Record "Job Queue Entry";
        WebhookNotification: Record "Webhook Notification";
    begin
        UnbindSubscription(WebhooksSubcriber);
        JobQueueEntry.DeleteAll();
        WebhookNotification.DeleteAll();
    end;

    [Test]
    procedure TestEnableOrderCreatedWebhooks()
    var
        Shop: Record "Shpfy Shop";
        WebhookSubscription: Record "Webhook Subscription";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        // [SCENARIO] Enabling order created webhooks registers webhook with Shopify and creates a subscription

        // [GINVEN] A Shop record
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        BindSubscription(WebhooksSubcriber);

        // [WHEN] Order created webhooks are enabled
        Shop.Validate("Order Created Webhooks", true);

        // [THEN] Subscription is created and id field is filled
        LibraryAssert.AreEqual(Shop."Order Created Webhook Id", SubscriptionId, 'Subscription id should be filled.');
        LibraryAssert.RecordCount(WebhookSubscription, 1);
        Clear();
    end;

    [Test]
    procedure TestDisableOrderCreatedWebhooks()
    var
        Shop: Record "Shpfy Shop";
        WebhookSubscription: Record "Webhook Subscription";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        // [SCENARIO] Disabling order created webhooks deletes the webhook from Shopify and deletes the subscription

        // [GINVEN] A Shop record with order created webhooks enabled
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        BindSubscription(WebhooksSubcriber);
        if not Shop."Order Created Webhooks" then begin
            Shop.Validate("Order Created Webhooks", true);
            Shop.Modify();
        end;

        // [WHEN] Order created webhooks are disabled
        Shop.Validate("Order Created Webhooks", false);

        // [THEN] Subscription is deleted and id field is cleared
        LibraryAssert.AreEqual(Shop."Order Created Webhook Id", '', 'Subscription id should be cleared.');
        LibraryAssert.RecordIsEmpty(WebhookSubscription);
        Clear();
    end;

    [Test]
    procedure TestNotificationSchedulesOrderSyncJob()
    var
        Shop: Record "Shpfy Shop";
        JobQueueEntry: Record "Job Queue Entry";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        // [SCENARIO] Creating a webhook notification for orders/create schedules order sync

        // [GINVEN] A Shop record with order created webhooks enabled
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        BindSubscription(WebhooksSubcriber);
        if not Shop."Order Created Webhooks" then begin
            Shop.Validate("Order Created Webhooks", true);
            Shop.Modify();
        end;

        // [WHEN] A notification is inserted
        InsertOrderCreatedNotification(Shop."Shopify URL");

        // [THEN] Subscription is deleted and id field is cleared
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Shpfy Sync Orders from Shopify");
        JobQueueEntry.FindFirst();
        LibraryAssert.AreEqual(JobQueueEntry."Job Queue Category Code", 'SHPFY', 'Job queue category should be SHPFY.');
        Clear();
    end;

    [Test]
    procedure TestNotificationDoesNotScheduleOrderSyncJobIfAlreadyExists()
    var
        Shop: Record "Shpfy Shop";
        JobQueueEntry: Record "Job Queue Entry";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO] Creating a webhook notification for orders/create does not schedule order sync if there is a ready job queue already

        // [GINVEN] A Shop record with order created webhooks enabled and a ready job queue entry
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        BindSubscription(WebhooksSubcriber);
        if not Shop."Order Created Webhooks" then begin
            Shop.Validate("Order Created Webhooks", true);
            Shop.Modify();
        end;
        JobQueueEntryId := CreateJobQueueEntry(Shop, Report::"Shpfy Sync Orders from Shopify");

        // [WHEN] A notification is inserted
        InsertOrderCreatedNotification(Shop."Shopify URL");

        // [THEN] Subscription is deleted and id field is cleared
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Shpfy Sync Orders from Shopify");
        LibraryAssert.RecordCount(JobQueueEntry, 1);
        Clear();
    end;

    local procedure InsertOrderCreatedNotification(ShopifyURL: Text[250])
    var
        WebhookNotification: Record "Webhook Notification";
    begin
        WebhookNotification.Init();
        WebhookNotification."Subscription ID" := GetShopDomain(ShopifyURL);
        WebhookNotification."Resource Type Name" := 'orders/create';
        WebhookNotification."Sequence Number" := -1;
        WebhookNotification.Insert();
    end;

    local procedure CreateJobQueueEntry(Shop: Record "Shpfy Shop"; ReportId: Integer): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
        OrderParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Sync Orders from Shopify" id="30104"><DataItems><DataItem name="Shop">%1</DataItem><DataItem name="OrdersToImport">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Comment = '%1 = Shop Record View', Locked = true;
    begin
        Shop.SetFilter(Code, Shop.Code);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ReportId;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry."No. of Attempts to Run" := 5;
        JobQueueEntry."Job Queue Category Code" := 'SHPFY';
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();
        JobQueueEntry.SetXmlContent(StrSubstNo(OrderParametersTxt, Shop.GetView()));
        exit(JobQueueEntry.ID);
    end;

    local procedure CreateShopifyWebhookCreateJson(): JsonObject
    var
        JData: JsonObject;
        JWebhook: JsonObject;
    begin
        JWebhook.Add('id', SubscriptionId);
        JWebhook.Add('address', 'https://example.app/api/webhooks');
        JWebhook.Add('topic', 'orders/create');
        JWebhook.Add('format', 'JSON');
        JData.Add('webhook', JWebhook);
        exit(JData);
    end;

    local procedure CreateShopifyWebhookDeleteJson(): JsonObject
    var
        JData: JsonObject;
    begin
        exit(JData);
    end;

    local procedure CreateShopifyEmptyWebhookJson(): JsonObject
    var
        JData: JsonObject;
        JWebhooks: JsonArray;
    begin
        JData.Add('webhooks', JWebhooks);
        exit(JData);
    end;

    local procedure GetShopDomain(ShopUrl: Text[250]): Text
    begin
        exit(ShopUrl.Replace('https://', '').Replace('.myshopify.com', '').TrimEnd('/'));
    end;
}