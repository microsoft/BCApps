codeunit 135088 "API Webhook Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Webhook]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        APIWebhookSendingEvents: Codeunit "API Webhook Sending Events";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        IsInitialized: Boolean;
        NotificationUrlTxt: Label 'https://localhost:8080/ApiWebhook/%1/status%2', Locked = true;
        ClientStateTxt: Label 'API WEBHOOK NOTIFICATION TEST', Locked = true;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;
        NoNotificationErr: Label 'No API webhook notification was created';
        MultipleNotificationsErr: Label 'Multiple API webhook notifications were created';
        UnexpectedNotificationErr: Label 'An unexpected API webhook notification was created';
        NoSubscriptionButNotificationErr: Label 'No API Webhook Notification should be generated when no API Webhook Subscription exists';
        JobQueueCountErr: Label 'The number of Job Queue Entries created does not correspond with the API Webhook Notification expected';
        ProcessingTime: DateTime;
        ChangeType: Option Created,Updated,Deleted,Collection;

    local procedure Initialize()
    begin
        Reset();

        APIWebhookSendingEvents.SetApiEnabled(true);
        APIWebhookSendingEvents.SetApiSubscriptionsEnabled(true);
        DisableCDSConnection();

        if IsInitialized then
            exit;

        IsInitialized := true;

        BindSubscription(LibraryJobQueue);
        BindSubscription(APIWebhookSendingEvents);

        InitializeDatabaseTableTriggerSetup();
        Reset();
    end;

    local procedure InitializeCDSConnectionSetup()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        ClientSecret: Text;
    begin
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup."Business Events Enabled" := true;
        CDSConnectionSetup."User Name" := 'user@test.net';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
    end;

    local procedure DisableCDSConnection()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        CDSConnectionSetup.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationIfApiServicesDisabled()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscription(false);
        // [GIVEN] API services are disabled
        APIWebhookSendingEvents.SetApiEnabled(false);

        // [WHEN] we INSERT an item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationIfBusinessEventsDisabled()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create a Dataverse Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        DisableCDSConnection();
        SubscriptionID := CreateDataverseItemWebhookSubscription(false);
        // [GIVEN] API services are enabled
        APIWebhookSendingEvents.SetApiEnabled(true);

        // [WHEN] we INSERT an item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationIfApiSubscriptionsDisabled()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscription(false);
        // [GIVEN] API subscriptions are disabled
        APIWebhookSendingEvents.SetApiSubscriptionsEnabled(false);

        // [WHEN] we INSERT an item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateItem()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we INSERT an item
        CreateItem();

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Created, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnCreateItem()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(false);

        // [WHEN] we INSERT an item
        CreateItem();

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Created, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateItem()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item modification
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnUpdateItem()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item modification
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(false);

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameItem()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item renaming
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnRenameItem()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item renaming
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(false);

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenamePackage()
    var
        ConfigPackage: Record "Config. Package";
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if two notifications and a Job Queue Entry is created on configuration package renaming
        // [GIVEN] a configuration package
        Initialize();
        ConfigPackage.Code := CopyStr(LibraryRandom.RandText(MaxStrLen(ConfigPackage.Code)), 1, MaxStrLen(ConfigPackage.Code));
        ConfigPackage.Insert(true);

        // [GIVEN] a Package API Webhook Subscription
        SubscriptionID := CreatePackageWebhookSubscription();

        // [WHEN] we RENAME the package
        ConfigPackage.Rename(CopyStr(LibraryRandom.RandText(MaxStrLen(ConfigPackage.Code)), 1, MaxStrLen(ConfigPackage.Code)));

        // [THEN] Two notifications and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Deleted, true, false);
        VerifyNotificationCreated(SubscriptionID, ChangeType::Created, true, false);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteItem()
    var
        SubscriptionID: Text[150];
        ItemCode: Code[20];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item deletion
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Deleted, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnDeleteItem()
    var
        SubscriptionID: Text[150];
        ItemCode: Code[20];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check if an API Webhook Notification and Job Queue Entry is created on an item deletion
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(false);

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] an API Webhook Notification and a Job Queue Entity should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Deleted, true, true);
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateTempItem()
    var
        TempItem: Record Item temporary;
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check check that an API Webhook Notification is not created on item creation
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we INSERT an item
        CreateTempItem(TempItem);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateTempItem()
    var
        TempItem: Record Item temporary;
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check check that an API Webhook Notification is not created on temp item modification
        // [GIVEN] an Item
        Initialize();
        CreateTempItem(TempItem);

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we UPDATE the item
        UpdateTempItem(TempItem);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameTempItem()
    var
        TempItem: Record Item temporary;
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check check that an API Webhook Notification is not created on temp item renaming
        // [GIVEN] an Item
        Initialize();
        CreateTempItem(TempItem);

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we RENAME the item
        RenameTempItem(TempItem);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteTempItem()
    var
        TempItem: Record Item temporary;
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an Item API Webhook Subscription and check check that an API Webhook Notification is not created on item deletion
        // [GIVEN] an Item
        Initialize();
        CreateTempItem(TempItem);

        // [GIVEN] an Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(false);

        // [WHEN] we DELETE the item
        DeleteTempItem(TempItem);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateItemExpiredSubscription()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created  on item creation
        // [GIVEN] an expired Item API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscription(true);

        // [WHEN] we INSERT the item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnCreateItemExpiredSubscription()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created  on item creation
        // [GIVEN] an expired Item API Webhook Subscription
        Initialize();
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(true);

        // [WHEN] we INSERT the item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateItemExpiredSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created on item modification
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(true);

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnUpdateItemExpiredSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created on item modification
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(true);

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameItemExpiredSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created on an item key renaming
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(true);

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnRenameItemExpiredSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created on an item key renaming
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(true);

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteItemExpiredSubscription()
    var
        SubscriptionID: Text[150];
        ItemCode: Code[20];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created   on item deletion
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        SubscriptionID := CreateItemWebhookSubscription(true);

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataverseWebhookNotificationOnDeleteItemExpiredSubscription()
    var
        SubscriptionID: Text[150];
        ItemCode: Code[20];
    begin
        // [SCENARIO] Create an expired Item API Webhook Subscription and check that an API Webhook Notification is not created   on item deletion
        // [GIVEN] an Item
        Initialize();
        ItemCode := CreateItem();

        // [GIVEN] an expired Item API Webhook Subscription
        InitializeCDSConnectionSetup();
        SubscriptionID := CreateDataverseItemWebhookSubscription(true);

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateItemBrokenSubscription()
    var
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create a broken Item API Webhook Subscription and check that an API Webhook Notification is not created on item creation
        // [GIVEN] a broken Resource URL API Webhook Subscription
        Initialize();
        SubscriptionID := CreateItemWebhookSubscriptionBrokenResourceURL();

        // [WHEN] we CREATE the item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateItemBrokenSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create a broken Item API Webhook Subscription and check that an API Webhook Notification is not created on item modification
        // [GIVEN] a broken Resource URL API Webhook Subscription and an Item
        Initialize();
        ItemCode := CreateItem();
        SubscriptionID := CreateItemWebhookSubscriptionBrokenResourceURL();

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameItemBrokenSubscription()
    var
        ItemCode: Code[20];
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Create a broken Item API Webhook Subscription and check that an API Webhook Notification is not created on an item key renaming
        // [GIVEN] a broken Resource URL API Webhook Subscription and an Item
        Initialize();
        ItemCode := CreateItem();
        SubscriptionID := CreateItemWebhookSubscriptionBrokenResourceURL();

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteItemBrokenSubscription()
    var
        SubscriptionID: Text[150];
        ItemCode: Code[20];
    begin
        // [SCENARIO] Create a broken Item API Webhook Subscription and check that an API Webhook Notification is not created on item deletion
        // [GIVEN] a broken Resource URL API Webhook Subscription and an Item
        Initialize();
        ItemCode := CreateItem();
        SubscriptionID := CreateItemWebhookSubscriptionBrokenResourceURL();

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated(SubscriptionID);
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateItemNoSubscription()
    begin
        // [SCENARIO] Check that an API Webhook Notification is not created on item creation when API Webhook Subscription doesn't exist
        // [GIVEN] no API Webhook Subscription
        Initialize();

        // [WHEN] we CREATE the item
        CreateItem();

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated('');
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateItemNoSubscription()
    var
        ItemCode: Code[20];
    begin
        // [SCENARIO] Check that an API Webhook Notification is not created on item modification when API Webhook Subscription doesn't exist
        // [GIVEN] an Item and no API Webhook Subscription
        Initialize();
        ItemCode := CreateItem();

        // [WHEN] we UPDATE the item
        UpdateItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated('');
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameItemNoSubscription()
    var
        ItemCode: Code[20];
    begin
        // [SCENARIO] Check that an API Webhook Notification is not created on an item key renaming when API Webhook Subscription doesn't exist
        // [GIVEN] an Item and no API Webhook Subscription
        Initialize();
        ItemCode := CreateItem();

        // [WHEN] we RENAME the item
        RenameItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated('');
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteItemNoSubscription()
    var
        ItemCode: Code[20];
    begin
        // [SCENARIO] Check that an API Webhook Notification is not created on item deletion when API Webhook Subscription doesn't exist
        // [GIVEN] an Item and no API Webhook Subscription
        Initialize();
        ItemCode := CreateItem();

        // [WHEN] we DELETE the item
        DeleteItem(ItemCode);

        // [THEN] no API Webhook Notification and no Job Queue Entity should be created
        VerifyNotificationNotCreated('');
        VerifyJobQueueEntryOnWebhookSubscription(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleItemsReuseSameJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Check that only one Job Queue Entity is created when an Item API Webhook Subscription exists and multiple items are created in shortly
        // [GIVEN] an Item API Webhook Subscription
        Initialize();
        CreateItemWebhookSubscription(false);

        // [WHEN] we CREATE one item
        CreateItem();

        // [WHEN] we UPDATE the asociated Job Queue Entity's status to Ready
        MockJobsStatus(JobQueueEntry.Status::Ready, true);

        // [WHEN] we CREATE another item
        CreateItem();

        // [THEN] one Job Queue Entity should be created
        VerifyJobQueueEntryOnWebhookSubscription(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleItemsCreateSeparateJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Check that multiple Job Queue Entities are created when an Item API Webhook Subscription exists and multiple items are created outside of the aggregation criteria
        // [GIVEN] an Item API Webhook Subscription and multiple items
        Initialize();
        CreateItemWebhookSubscription(false);

        // [GIVEN] a Job Queue Entry Delay to 500 miliseconds
        APIWebhookSendingEvents.SetDelayTime(500);

        // [WHEN] we CREATE one item
        CreateItem();

        // [WHEN] we UPDATE the asociated Job Queue Entity's status to "In Process"
        MockJobsStatus(JobQueueEntry.Status::"In Process", false);
        Sleep(2000);

        // [WHEN] we CREATE another item
        CreateItem();

        // [THEN] two Job Queue Entities should be created
        VerifyJobQueueEntryOnWebhookSubscription(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewJobQueueEntryNotCreatedWhenExceedMaxNumberOfJobs()
    var
        I: Integer;
    begin
        // [SCENARIO] Check that a new job queue entry is not created when we exceed max number of jobs
        Initialize();
        // [GIVEN] an Item API Webhook Subscription
        CreateItemWebhookSubscription(false);
        // [GIVEN] Max number of job queue entries
        for I := 1 to 20 do
            CreateApiWebhookJobQueueEntry(ProcessingTime + I * MillisecondsPerHour(), true);

        // [WHEN] we CREATE an item
        CreateItem();

        // [THEN] Number of job queue entries still equals to max number of jobs
        VerifyJobQueueEntryOnWebhookSubscription(20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteHangingJobQueueEntryWhenExceedMaxNumberOfJobs()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobId: Guid;
        I: Integer;
    begin
        // [SCENARIO] Check that a hanging job queue entry is deleted when we exceed max number of jobs
        Initialize();
        // [GIVEN] an Item API Webhook Subscription
        CreateItemWebhookSubscription(false);
        // [GIVEN] Max number of job queue entries, one job is hanging
        for I := 1 to 19 do
            CreateApiWebhookJobQueueEntry(ProcessingTime + I * MillisecondsPerHour(), true);
        JobId := CreateApiWebhookJobQueueEntry(ProcessingTime, true);
        JobQueueEntry.Get(JobId);
        MockJobStatus(JobId, JobQueueEntry.Status::"In Process", false);

        // [WHEN] we CREATE an item
        CreateItem();

        // [THEN] The hanging job is deleted
        Assert.IsFalse(JobQueueEntry.Get(JobId), 'Hanging job has not been deleted');
        // [THEN] Number of job queue entries still equals to max number of jobs
        VerifyJobQueueEntryOnWebhookSubscription(20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewJobQueueEntryCreatedWhenAnotherNotReadyJobExists()
    begin
        // [SCENARIO] Check that a new job queue entry is created when other not ready jobs exist
        Initialize();
        // [GIVEN] an Item API Webhook Subscription
        CreateItemWebhookSubscription(false);
        // [GIVEN] A job queue entry with "On Hold" status
        CreateApiWebhookJobQueueEntry(ProcessingTime - MillisecondsPerHour(), false);

        // [WHEN] we CREATE an item
        CreateItem();

        // [THEN] the new Job Queue Entity is created
        VerifyJobQueueEntryOnWebhookSubscription(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewJobQueueEntryCreatedWhenAnotherReadyScheduledJobExists()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Check that a new job queue entry is created when other ready jobs exist
        Initialize();
        // [GIVEN] an Item API Webhook Subscription
        CreateItemWebhookSubscription(false);
        // [GIVEN] an Ready and Scheduled job queue entry with Earliest Start Date/Time in the future 
        CreateApiWebhookJobQueueEntry(ProcessingTime + MillisecondsPerHour(), true);
        MockJobsStatus(JobQueueEntry.Status::Ready, true);

        // [WHEN] we CREATE an item
        CreateItem();

        // [THEN] the new Job Queue Entity is created
        VerifyJobQueueEntryOnWebhookSubscription(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewJobQueueEntryCreatedWhenAnotherReadyNotScheduledJobExists()
    begin
        // [SCENARIO] Check that a new job queue entry is created when other ready jobs exist
        Initialize();
        // [GIVEN] an Item API Webhook Subscription
        CreateItemWebhookSubscription(false);
        // [GIVEN] A job queue entry with Ready status
        CreateApiWebhookJobQueueEntry(ProcessingTime + MillisecondsPerHour(), true);

        // [WHEN] we CREATE an item
        CreateItem();

        // [THEN] the new Job Queue Entity is created
        VerifyJobQueueEntryOnWebhookSubscription(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnCreateJobQueueEntry()
    begin
        // [SCENARIO] Check that no API Webhook Notification is created on Job Queue creation
        // [GIVEN] no API Webhook Subscription
        Initialize();

        // [WHEN] we CREATE a Job Queue Entry
        CreateJobQueue();

        // [THEN] no API Webhook Notification should be created
        VerifyNotificationNotCreated('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnUpdateJobQueueEntry()
    var
        JobQueueID: Guid;
    begin
        // [SCENARIO] Check that no API Webhook Notification is created on Job Queue modification
        // [GIVEN] a Job Queue Entity AND no API Webhook Subscription
        Initialize();
        JobQueueID := CreateJobQueue();

        // [WHEN] we UPDATE the Job Queue Entry
        UpdateJobQueue(JobQueueID);

        // [THEN] no API Webhook Notification should be created
        VerifyNotificationNotCreated('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnRenameJobQueueEntry()
    var
        JobQueueID: Guid;
    begin
        // [SCENARIO] Check that no API Webhook Notification is created on Job Queue renaming
        // [GIVEN] a Job Queue Entity AND no API Webhook Subscription
        Initialize();
        JobQueueID := CreateJobQueue();

        // [WHEN] we UPDATE the Job Queue Entry
        RenameJobQueue(JobQueueID);

        // [THEN] no API Webhook Notification should be created
        VerifyNotificationNotCreated('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnDeleteJobQueueEntry()
    var
        JobQueueID: Guid;
    begin
        // [SCENARIO] Check that no API Webhook Notification is created on Job Queue deletion
        // [GIVEN] a Job Queue Entity AND no API Webhook Subscription
        Initialize();
        JobQueueID := CreateJobQueue();

        // [WHEN] we DELETE the Job Queue Entry
        DeleteJobQueue(JobQueueID);

        // [THEN] no API Webhook Notification should be created
        VerifyNotificationNotCreated('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnPostingSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Check that proper notifications are created on posting a Sales Invoice
        // [GIVEN] a Draft Sales Invoice and an API Webhook Subscription to salesInvoices entity
        Initialize();
        CreateDraftSalesInvoice(SalesHeader);
        SubscriptionID := CreateSalesInvoiceWebhookSubscription();

        // [WHEN] we POST the draft Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] proper API Webhook Notifications should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnInsertPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SubscriptionID: Text[150];
        Key1: Text;
        Key2: Text;
    begin
        // [SCENARIO] Check that proper notifications are created on inserting a Posted Sales Invoice
        // [GIVEN] a Draft Sales Invoice and an API Webhook Subscription to salesInvoices entity
        Initialize();
        CreateDraftSalesInvoice(SalesHeader);
        SubscriptionID := CreateSalesInvoiceWebhookSubscription();

        // [WHEN] create a Posted Sales Invoice and delete the Draft Sales Invoice
        SalesInvoiceHeader.TransferFields(SalesHeader, true);
        SalesInvoiceHeader."Pre-Assigned No." := SalesHeader."No.";
        SalesInvoiceHeader.Insert(true);
        SalesHeader.Delete(true);

        // [THEN] proper API Webhook Notifications should be created
        Key1 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(SalesInvoiceHeader.SystemId));
        Key2 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(SalesHeader.SystemId));
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Created, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Deleted, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key2, ChangeType::Updated, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnPostingSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Check that proper notifications are created on posting a Sales Credit Memo
        // [GIVEN] a Draft Sales Credit Memo and an API Webhook Subscription to salesCreditMemos entity
        Initialize();
        CreateDraftSalesCreditMemo(SalesHeader);
        SubscriptionID := CreateSalesCreditMemoWebhookSubscription();

        // [WHEN] we POST the draft Sales Credit Memo
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] proper API Webhook Notifications should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnInsertPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SubscriptionID: Text[150];
        Key1: Text;
        Key2: Text;
    begin
        // [SCENARIO] Check that proper notifications are created on inserting a Posted Sales Credit Memo
        // [GIVEN] a Draft Sales Credit Memo and an API Webhook Subscription to salesCreditMemos entity
        Initialize();
        CreateDraftSalesCreditMemo(SalesHeader);
        SubscriptionID := CreateSalesCreditMemoWebhookSubscription();

        // [WHEN] create a Posted Sales Credit Memo and delete the Draft Sales Credit Memo
        SalesCrMemoHeader.TransferFields(SalesHeader, true);
        SalesCrMemoHeader."Pre-Assigned No." := SalesHeader."No.";
        SalesCrMemoHeader.Insert(true);
        SalesHeader.Delete(true);

        // [THEN] proper API Webhook Notifications should be created
        Key1 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(SalesCrMemoHeader.SystemId));
        Key2 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(SalesHeader.SystemId));
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Created, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Deleted, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key2, ChangeType::Updated, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnPostingPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        SubscriptionID: Text[150];
    begin
        // [SCENARIO] Check that proper notifications are created on posting a Purchase Invoice
        // [GIVEN] a Draft Purchase Invoice and an API Webhook Subscription to purchaseInvoices entity
        Initialize();
        CreateDraftPurchaseInvoice(PurchaseHeader);
        SubscriptionID := CreatePurchaseInvoiceWebhookSubscription();

        // [WHEN] we POST the draft Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] proper API Webhook Notifications should be created
        VerifyNotificationCreated(SubscriptionID, ChangeType::Updated, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebhookNotificationOnInsertPostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SubscriptionID: Text[150];
        Key1: Text;
        Key2: Text;
    begin
        // [SCENARIO] Check that proper notifications are created on inserting a Posted Purchase Invoice
        // [GIVEN] a Draft Purchase Invoice and an API Webhook Subscription to purchaseInvoices entity
        Initialize();
        CreateDraftPurchaseInvoice(PurchaseHeader);
        SubscriptionID := CreatePurchaseInvoiceWebhookSubscription();

        // [WHEN] create a Posted Purchase Invoice and delete the Draft Purchase Invoice
        PurchInvHeader.TransferFields(PurchaseHeader, true);
        PurchInvHeader."Pre-Assigned No." := PurchaseHeader."No.";
        PurchInvHeader.Insert(true);
        PurchaseHeader.Delete(true);

        // [THEN] proper API Webhook Notifications should be created
        Key1 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(PurchInvHeader.SystemId));
        Key2 := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(PurchaseHeader.SystemId));
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Created, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key1, ChangeType::Deleted, true, false);
        VerifyNotificationCreatedForEntityKey(SubscriptionID, Key2, ChangeType::Updated, false, true);
    end;


    local procedure GetPackageWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntity(ApiWebhookEntity, PAGE::"Mock - Configuration Package", DATABASE::"Config. Package");
    end;

    local procedure GetItemWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntity(ApiWebhookEntity, PAGE::"Mock - Item Entity", DATABASE::Item);
    end;

    local procedure GetSalesInvoiceWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntity(ApiWebhookEntity, PAGE::"Mock - Sales Invoice Entity", DATABASE::"Sales Invoice Entity Aggregate");
    end;

    local procedure GetSalesCreditMemoWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntity(ApiWebhookEntity, PAGE::"Mock - Sales Cr. Memo Entity", DATABASE::"Sales Cr. Memo Entity Buffer");
    end;

    local procedure GetPurchaseInvoiceWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntity(ApiWebhookEntity, PAGE::"Mock - Purchase Invoice Entity", DATABASE::"Purch. Inv. Entity Aggregate");
    end;


    local procedure GetWebhookEntity(var ApiWebhookEntity: Record "Api Webhook Entity"; PageId: Integer; TableId: Integer)
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PageId);
        ApiWebhookEntity.SetRange("Table No.", TableId);
        ApiWebhookEntity.FindFirst();
    end;

    local procedure CreateApiWebhookJobQueueEntry(EarliestStartDateTime: DateTime; Ready: Boolean): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateApiWebhookJobCategoryIfMissing();

        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"API Webhook Notification Send";
        JobQueueEntry."Job Queue Category Code" := CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueEntry."Job Queue Category Code"));
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert();
        if Ready then
            MockJobStatus(JobQueueEntry.ID, JobQueueEntry.Status::Ready, true);
        exit(JobQueueEntry.ID);
    end;

    local procedure CreateApiWebhookJobCategoryIfMissing()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if not JobQueueCategory.Get(JobQueueCategoryCodeLbl) then begin
            JobQueueCategory.Validate(Code, CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)));
            JobQueueCategory.Insert(true);
        end;
    end;

    local procedure CreateSalesInvoiceWebhookSubscription(): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionId: Text[150];
    begin
        GetSalesInvoiceWebhookEntity(ApiWebhookEntity);
        SubscriptionId := CreateSubscriptionForEntity(ApiWebhookEntity, false);
        exit(SubscriptionId);
    end;

    local procedure CreateSalesCreditMemoWebhookSubscription(): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionId: Text[150];
    begin
        GetSalesCreditMemoWebhookEntity(ApiWebhookEntity);
        SubscriptionId := CreateSubscriptionForEntity(ApiWebhookEntity, false);
        exit(SubscriptionId);
    end;

    local procedure CreatePurchaseInvoiceWebhookSubscription(): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionId: Text[150];
    begin
        GetPurchaseInvoiceWebhookEntity(ApiWebhookEntity);
        SubscriptionId := CreateSubscriptionForEntity(ApiWebhookEntity, false);
        exit(SubscriptionId);
    end;

    local procedure CreatePackageWebhookSubscription(): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionId: Text[150];
    begin
        GetPackageWebhookEntity(ApiWebhookEntity);
        SubscriptionId := CreateSubscriptionForEntity(ApiWebhookEntity, false);
        exit(SubscriptionId);
    end;

    local procedure CreateItemWebhookSubscription(IsExpired: Boolean): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text[150];
    begin
        GetItemWebhookEntity(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, false);
        if IsExpired then begin
            APIWebhookSubscription.Get(SubscriptionID);
            APIWebhookSubscription."Expiration Date Time" := ProcessingTime - MillisecondsPerDay();
            APIWebhookSubscription.Modify();
        end;
        exit(SubscriptionID);
    end;

    local procedure CreateDataverseItemWebhookSubscription(IsExpired: Boolean): Text[150]
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text[150];
    begin
        GetItemWebhookEntity(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, true);
        if IsExpired then begin
            APIWebhookSubscription.Get(SubscriptionID);
            APIWebhookSubscription."Expiration Date Time" := ProcessingTime - MillisecondsPerDay();
            APIWebhookSubscription.Modify();
        end;
        exit(SubscriptionID);
    end;

    local procedure CreateItemWebhookSubscriptionBrokenResourceURL(): Text[150]
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text[150];
    begin
        SubscriptionID := CreateItemWebhookSubscription(false);
        APIWebhookSubscription.Get(SubscriptionID);
        APIWebhookSubscription."Entity Publisher" := 'mock';
        APIWebhookSubscription."Entity Group" := 'test';
        APIWebhookSubscription."Entity Version" := 'v9999.9';
        APIWebhookSubscription."Entity Set Name" := 'fake';
        APIWebhookSubscription.Modify();
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntity(var ApiWebhookEntity: Record "Api Webhook Entity"; DataverseSubscription: Boolean): Text[150]
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text;
    begin
        SubscriptionID := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        APIWebhookSubscription."Subscription Id" :=
          CopyStr(SubscriptionID, 1, MaxStrLen(APIWebhookSubscription."Subscription Id"));
        APIWebhookSubscription."Entity Publisher" := ApiWebhookEntity.Publisher;
        APIWebhookSubscription."Entity Group" := ApiWebhookEntity.Group;
        APIWebhookSubscription."Entity Version" := ApiWebhookEntity.Version;
        APIWebhookSubscription."Entity Set Name" := ApiWebhookEntity.Name;
        APIWebhookSubscription."User Id" := UserSecurityId();
        APIWebhookSubscription."Last Modified Date Time" := ProcessingTime;
        APIWebhookSubscription."Client State" := CopyStr(ClientStateTxt, 1, MaxStrLen(APIWebhookSubscription."Client State"));
        APIWebhookSubscription."Expiration Date Time" := ProcessingTime + MillisecondsPerDay();
        APIWebhookSubscription."Source Table Id" := ApiWebhookEntity."Table No.";
        if DataverseSubscription then
            APIWebhookSubscription."Subscription Type" := APIWebhookSubscription."Subscription Type"::Dataverse
        else
            APIWebhookSubscription."Company Name" := CompanyName;
        APIWebhookSubscription.Insert();
        SetResourceUrl(SubscriptionID, ApiWebhookEntity."Object ID");
        SetNotificationUrl(SubscriptionID, 1, 200);
        exit(APIWebhookSubscription."Subscription Id");
    end;

    local procedure SetNotificationUrl(SubscriptionID: Text; Number: Integer; ResponseCode: Integer)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        RecRef: RecordRef;
        OutStream: OutStream;
        NotificationUrl: Text;
    begin
        APIWebhookSubscription.Get(SubscriptionID);
        RecRef.GetTable(APIWebhookSubscription);
        NotificationUrl := StrSubstNo(NotificationUrlTxt, Number, ResponseCode);
        APIWebhookSubscription."Notification Url Prefix" :=
          CopyStr(NotificationUrl, 1, MaxStrLen(APIWebhookSubscription."Notification Url Prefix"));

        APIWebhookSubscription."Notification Url Blob".CreateOutStream(OutStream);
        OutStream.Write(NotificationUrl);

        RecRef.Modify();
    end;

    local procedure SetResourceUrl(SubscriptionID: Text; PageID: Integer)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        RecRef: RecordRef;
        OutStream: OutStream;
        ResourceUrl: Text;
    begin
        APIWebhookSubscription.Get(SubscriptionID);
        RecRef.GetTable(APIWebhookSubscription);
        ResourceUrl := GetUrl(CLIENTTYPE::Api, CompanyName, OBJECTTYPE::Page, PageID);

        APIWebhookSubscription."Resource Url Blob".CreateOutStream(OutStream);
        OutStream.Write(ResourceUrl);

        RecRef.Modify();
    end;

    local procedure ResetApiWebhookSubscriptionsAndNotifications()
    var
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        APIWebhookSubscription: Record "API Webhook Subscription";
    begin
        APIWebhookNotificationAggr.DeleteAll(true);
        APIWebhookNotification.DeleteAll(true);
        APIWebhookSubscription.DeleteAll(true);
    end;

    local procedure ResetJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.ModifyAll(Status, JobQueueEntry.Status::"On Hold", true);
        JobQueueEntry.DeleteAll(true);
    end;

    local procedure VerifyNotificationNotCreated(SubscriptionID: Text[150])
    var
        APIWebhookNotification: Record "API Webhook Notification";
    begin
        if SubscriptionID <> '' then begin
            APIWebhookNotification.SetRange("Subscription ID", SubscriptionID);
            Assert.IsTrue(APIWebhookNotification.IsEmpty, NoNotificationErr);
            exit;
        end;

        Assert.IsTrue(APIWebhookNotification.IsEmpty, NoSubscriptionButNotificationErr);
    end;

    local procedure VerifyNotificationCreated(SubscriptionID: Text[150]; ChangeType: Option; SingleOfThisType: Boolean; NoneOfOtherType: Boolean)
    var
        APIWebhookNotification: Record "API Webhook Notification";
        "Count": Integer;
    begin
        APIWebhookNotification.SetRange("Subscription ID", SubscriptionID);
        APIWebhookNotification.SetRange("Change Type", ChangeType);
        Count := APIWebhookNotification.Count();
        Assert.IsTrue(Count > 0, NoNotificationErr);
        if SingleOfThisType then
            Assert.IsTrue(Count = 1, MultipleNotificationsErr);
        if NoneOfOtherType then begin
            APIWebhookNotification.SetFilter("Change Type", '<>%1', ChangeType);
            Assert.IsTrue(APIWebhookNotification.IsEmpty, UnexpectedNotificationErr);
        end;
    end;

    local procedure VerifyNotificationCreatedForEntityKey(SubscriptionID: Text[150]; EntityKeyValue: Text; ChangeType: Option; SingleOfThisType: Boolean; NoneOfOtherType: Boolean)
    var
        APIWebhookNotification: Record "API Webhook Notification";
        "Count": Integer;
    begin
        APIWebhookNotification.SetRange("Subscription ID", SubscriptionID);
        APIWebhookNotification.SetRange("Entity Key Value", EntityKeyValue);
        APIWebhookNotification.SetRange("Change Type", ChangeType);
        Count := APIWebhookNotification.Count();
        Assert.IsTrue(Count > 0, NoNotificationErr);
        if SingleOfThisType then
            Assert.IsTrue(Count = 1, MultipleNotificationsErr);
        if NoneOfOtherType then begin
            APIWebhookNotification.SetFilter("Change Type", '<>%1', ChangeType);
            Assert.IsTrue(APIWebhookNotification.IsEmpty, UnexpectedNotificationErr);
        end;
    end;

    local procedure VerifyJobQueueEntryOnWebhookSubscription(RecordCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        Assert.AreEqual(RecordCount, JobQueueEntry.Count, JobQueueCountErr);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        Item.Init();
        ItemNo := CopyStr(LibraryRandom.RandText(20), 1, 20);
        Item."No." := ItemNo;
        Item.Insert(true);
        exit(ItemNo);
    end;

    local procedure UpdateItem(ItemCode: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemCode);
        Item.Validate(Description, LibraryRandom.RandText(50));
        Item.Modify(true);
    end;

    local procedure RenameItem(ItemCode: Code[20])
    var
        Item: Record Item;
        NewKey: Code[20];
    begin
        Item.Get(ItemCode);
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        Item.Rename(NewKey);
    end;

    local procedure DeleteItem(ItemCode: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemCode);
        Item.Delete(true);
    end;

    local procedure CreateTempItem(var TempItem: Record Item temporary)
    var
        ItemNo: Code[20];
    begin
        TempItem.Init();
        ItemNo := CopyStr(LibraryRandom.RandText(20), 1, 20);
        TempItem."No." := ItemNo;
        TempItem.Insert(true);
    end;

    local procedure UpdateTempItem(var TempItem: Record Item temporary)
    begin
        TempItem.Validate(Description, LibraryRandom.RandText(50));
        TempItem.Modify(true);
    end;

    local procedure RenameTempItem(var TempItem: Record Item temporary)
    var
        NewKey: Code[20];
    begin
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        TempItem.Rename(NewKey);
    end;

    local procedure DeleteTempItem(var TempItem: Record Item temporary)
    begin
        TempItem.Delete(true);
    end;

    local procedure CreateJobQueue(): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueID: Guid;
    begin
        JobQueueEntry.Init();
        JobQueueID := CreateGuid();
        JobQueueEntry.ID := JobQueueID;
        JobQueueEntry.Insert(true);
        exit(JobQueueID);
    end;

    local procedure UpdateJobQueue(JobQueueID: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(JobQueueID);
        JobQueueEntry.Validate(Description, LibraryRandom.RandText(250));
        JobQueueEntry.Modify(true);
    end;

    local procedure RenameJobQueue(JobQueueID: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(JobQueueID);
        JobQueueEntry.Validate(Description, LibraryRandom.RandText(250));
        JobQueueEntry.Rename(CreateGuid());
    end;

    local procedure DeleteJobQueue(JobQueueID: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(JobQueueID);
        JobQueueEntry.Delete(true);
    end;

    local procedure CreateDraftSalesInvoice(var SalesHeader: Record "Sales Header"): Guid
    begin
        LibrarySales.SetAllowDocumentDeletionBeforeDate(WorkDate() + 1);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate());
        exit(SalesHeader.SystemId);
    end;

    local procedure CreateDraftSalesCreditMemo(var SalesHeader: Record "Sales Header"): Guid
    begin
        LibrarySales.SetAllowDocumentDeletionBeforeDate(WorkDate() + 1);
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate());
        exit(SalesHeader.SystemId);
    end;

    local procedure CreateDraftPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"): Guid
    begin
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(WorkDate() + 1);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        ModifyPurchaseHeaderPostingDate(PurchaseHeader, WorkDate());
        exit(PurchaseHeader.SystemId);
    end;

    local procedure ModifySalesHeaderPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure ModifyPurchaseHeaderPostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure InitializeDatabaseTableTriggerSetup()
    var
        Item: Record Item;
        ConfigPackage: Record "Config. Package";
    begin
        APIWebhookSendingEvents.SetApiSubscriptionsEnabled(false);
        Item."No." := CopyStr(LibraryRandom.RandText(20), 1, 20);
        Item.Insert(true);
        Item.Rename(CopyStr(LibraryRandom.RandText(20), 1, 20));
        Item.Validate(Description, LibraryRandom.RandText(50));
        Item.Modify(true);
        Item.Delete(true);
        ConfigPackage.Code := CopyStr(LibraryRandom.RandText(20), 1, 20);
        ConfigPackage.Insert(true);
        ConfigPackage.Rename(CopyStr(LibraryRandom.RandText(20), 1, 20));
    end;

    local procedure MockJobsStatus(Status: Integer; Scheduled: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        if JobQueueEntry.FindSet(true) then
            repeat
                MockJobStatus(JobQueueEntry.ID, Status, Scheduled);
            until JobQueueEntry.Next() = 0;
    end;

    local procedure MockJobStatus(JobId: Guid; Status: Integer; Scheduled: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
    begin
        JobQueueEntry.Get(JobId);
        JobQueueEntry.Status := Status;
        if Scheduled then begin
            if IsNullGuid(JobQueueEntry."System Task ID") then
                JobQueueEntry."System Task ID" := CreateGuid();
            if not ScheduledTask.Get(JobQueueEntry."System Task ID") then begin
                ScheduledTask.ID := JobQueueEntry."System Task ID";
                ScheduledTask.Insert();
            end;
        end else
            if not IsNullGuid(JobQueueEntry."System Task ID") then begin
                if ScheduledTask.Get(JobQueueEntry."System Task ID") then
                    ScheduledTask.Delete();
                Clear(JobQueueEntry."System Task ID");
            end;
        JobQueueEntry.Modify();
    end;

    local procedure Reset()
    begin
        ProcessingTime := CurrentDateTime;
        ResetApiWebhookSubscriptionsAndNotifications();
        ResetJobQueueEntries();
        APIWebhookNotificationMgt.Reset();
        APIWebhookSendingEvents.Reset();
    end;

    local procedure MillisecondsPerDay(): BigInteger
    begin
        exit(86400000);
    end;

    local procedure MillisecondsPerHour(): BigInteger
    begin
        exit(3600000);
    end;
}
