codeunit 135089 "API Webhook Sending Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Webhook]
    end;

    var
        Assert: Codeunit Assert;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        APIWebhookSendingEvents: Codeunit "API Webhook Sending Events";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        IsInitialized: Boolean;
        NotificationUrlTxt: Label 'https://localhost:8080/ApiWebhook/%1/status%2', Locked = true;
        ClientStateTxt: Label 'API WEBHOOK NOTIFICATION TEST', Locked = true;
        ProcessingTime: DateTime;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;
        ActivityLogContextLbl: Label 'APIWEBHOOK', Locked = true;
        DeleteObsoleteSubscriptionTitleTxt: Label 'Delete obsolete subscription.', Locked = true;
        DeleteExpiredSubscriptionTitleTxt: Label 'Delete expired subscription.', Locked = true;
        DeleteSubscriptionWithTooManyFailuresTitleTxt: Label 'Delete subscription with too many failures.', Locked = true;
        IncreaseAttemptNumberTitleTxt: Label 'Increase attempt number.', Locked = true;
        NotificationFailedTitleTxt: Label 'Notification failed.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteExpiredSubscriptions()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Processing deletes expired subscription
        Initialize();

        // [GIVEN] An expired subscription
        SubscriptionID := CreateExpiredSubscription();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] An aggregate notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Aggregate notification has been deleted
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID);
        // [THEN] Message has been logged
        VerifyActivityLogExists(DeleteExpiredSubscriptionTitleTxt);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteObsoleteSubscriptions()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Processing deletes obsolete subscription
        Initialize();

        // [GIVEN] An obsolete subscription
        SubscriptionID := CreateObsoleteSubscription();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] An aggregate notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Aggregate notification has been deleted
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID);
        // [THEN] Message has been logged
        VerifyActivityLogExists(DeleteObsoleteSubscriptionTitleTxt);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteObsoleteNotifications()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: array[2] of Text;
        NotificationID: array[2] of Guid;
        AggregateNotificationID: array[2] of Guid;
    begin
        // [SCENARIO] Processing deletes obsolete notifications
        Initialize();

        // [GIVEN] Notifications for an active subscription
        SubscriptionID[1] := CreateActiveSubscriptionForEntityWithGuidKey();
        NotificationID[1] := CreateNotificationOnCreate(SubscriptionID[1], ProcessingTime);
        AggregateNotificationID[1] := CreateAggregateNotificationOnCreate(SubscriptionID[1], ProcessingTime - 1000, 1);
        // [GIVEN] Notifications for a deleted subscription
        SubscriptionID[2] := CreateActiveSubscriptionForEntityWithGuidKey();
        NotificationID[2] := CreateNotificationOnCreate(SubscriptionID[2], ProcessingTime - 2000);
        AggregateNotificationID[2] := CreateAggregateNotificationOnCreate(SubscriptionID[2], ProcessingTime - 3000, 1);
        APIWebhookSubscription.Get(SubscriptionID[2]);
        APIWebhookSubscription.Delete();

        // [GIVEN] Expecting only two notifications on the active subscription in payload
        EnqueueNotificationUrl(SubscriptionID[1]);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID[1]);
        EnqueueSingleEntity(NotificationID[1]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Notifications for the active subscription have been processed
        VerifyNotificationDoesNotExist(NotificationID[1]);
        VerifyAggregateNotificationDoesNotExist(NotificationID[1]);
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID[1]);
        // [THEN] Notifications for the deleted subscription have been deleted
        VerifyNotificationDoesNotExist(NotificationID[2]);
        VerifyAggregateNotificationDoesNotExist(NotificationID[2]);
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID[2]);
        // [THEN] Job has not been re-scheduled
        VerifyJobCount(0);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProcessingNotStartedIfApiServicesDisabled()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Processing is not started if APIs are disabled
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] An aggregate notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] API services are disabled
        APIWebhookSendingEvents.SetApiEnabled(false);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has not been deleted
        VerifyNotificationExists(NotificationID);
        // [THEN] Aggregate notification has not been deleted
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationCount(1);
        // [THEN] Attempts number has not been increased
        VerifyAttemptNumber(AggregateNotificationID, 1);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProcessingNotStartedIfApiSubscriptionDisabled()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Processing is not started if APIs are disabled
        Initialize();

        // [GIVEN] An obsolete subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] An aggregate notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] API subscriptions are disabled
        APIWebhookSendingEvents.SetApiSubscriptionsEnabled(false);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has not been deleted
        VerifyNotificationExists(NotificationID);
        // [THEN] Aggregate notification has not been deleted
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationCount(1);
        // [THEN] Attempts number has not been increased
        VerifyAttemptNumber(AggregateNotificationID, 1);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProcessingNotStartedIfNoActiveSubscriptions()
    var
        ExpiredSubscriptionID: Text;
        ObsoleteSubscriptionID: Text;
    begin
        // [SCENARIO] Processing is not started if no active subscriptions
        Initialize();

        // [GIVEN] An expired subscription
        ExpiredSubscriptionID := CreateExpiredSubscription();
        // [GIVEN] An obsolete subscription
        ObsoleteSubscriptionID := CreateObsoleteSubscription();
        // [GIVEN] An expired notification
        CreateNotificationOnCreate(ExpiredSubscriptionID, ProcessingTime - 1000);
        // [GIVEN] An obsolete notification
        CreateNotificationOnCreate(ObsoleteSubscriptionID, ProcessingTime);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Expired subscription has been deleted
        VerifySubscriptionDoesNotExist(ExpiredSubscriptionID);
        // [THEN] Obsolete subscription has been deleted
        VerifySubscriptionDoesNotExist(ObsoleteSubscriptionID);
        // [THEN] Expired notification has been deleted
        VerifyNotificationDoesNotExist(ExpiredSubscriptionID);
        // [THEN] Obsolete notification has been deleted
        VerifyNotificationDoesNotExist(ObsoleteSubscriptionID);
        // [THEN] Expired Notification has not failed
        VerifyAggregateNotificationDoesNotExist(ExpiredSubscriptionID);
        // [THEN] Obsolete Notification has not failed
        VerifyAggregateNotificationDoesNotExist(ObsoleteSubscriptionID);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationSentForSubscriptionIdWithSpecialChars()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: array[200] of Text;
        NotificationID: Text;
        SubscriptionIDTemplate: Text;
        I: Integer;
    begin
        // [SCENARIO] Filter by SubscriptionID works in case of many subscriptions
        Initialize();

        // [GIVEN] A subscription that has special chars in ID
        SubscriptionID[100] := CreateActiveSubscriptionForEntityWithGuidKey('{`@}#%$+-*)^( _\-''\''"');
        // [GIVEN] 199 more subscriptions with long IDs
        SubscriptionIDTemplate := '%1 ';
        while StrLen(SubscriptionIDTemplate) < MaxStrLen(APIWebhookSubscription."Subscription Id") - 4 do
            SubscriptionIDTemplate += '#';
        for I := 1 to 200 do
            if I <> 100 then
                SubscriptionID[I] := CreateActiveSubscriptionForEntityWithGuidKey(StrSubstNo(SubscriptionIDTemplate, I));
        // [GIVEN] A notification on the chosen subscription
        NotificationID := CreateNotificationOnCreate(SubscriptionID[100], ProcessingTime);
        // [GIVEN] Expecting the notification on the chosen subscription in payload
        EnqueueNotificationUrl(SubscriptionID[100]);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] The notification has been processed
        VerifyNotificationDoesNotExist(NotificationID);
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationNotSentIfSubscriptionForAnotherCompany()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        CurrentCompanySubscriptionID: Text;
        AnotherCompanySubscriptionID: Text;
        CurrentCompanyNotificationID: Text;
        AnotherCompanyNotificationID: Text;
    begin
        // [SCENARIO] Notification is not sent if the subscription is for another company
        Initialize();

        // [GIVEN] A subscription for the current company
        CurrentCompanySubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A subscription for another company
        AnotherCompanySubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        APIWebhookSubscription.Get(AnotherCompanySubscriptionID);
        APIWebhookSubscription."Company Name" := 'Another';
        APIWebhookSubscription.Modify();
        // [GIVEN] A notification on the subscription for the current company 
        CurrentCompanyNotificationID := CreateNotificationOnCreate(CurrentCompanySubscriptionID, ProcessingTime);
        // [GIVEN] A notification on the subscription for another company 
        AnotherCompanyNotificationID := CreateNotificationOnCreate(AnotherCompanySubscriptionID, ProcessingTime);
        // [GIVEN] Expecting the notification on the subscription for the current company in payload
        EnqueueNotificationUrl(CurrentCompanySubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(CurrentCompanyNotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] The subscription for the current company has not been deleted
        VerifySubscriptionExists(CurrentCompanySubscriptionID);
        // [THEN] The notification on the subscription for the current company has been processed
        VerifyNotificationDoesNotExist(CurrentCompanyNotificationID);
        VerifyAggregateNotificationDoesNotExist(CurrentCompanyNotificationID);
        // [THEN] The subscription for another company has not been deleted
        VerifySubscriptionExists(AnotherCompanySubscriptionID);
        // [THEN] The notification on the subscription for another company has not been processed
        VerifyNotificationExists(AnotherCompanyNotificationID);
        VerifyAggregateNotificationDoesNotExist(AnotherCompanyNotificationID);
        // [THEN] Processing finished
        VerifyProcessingFinished();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationNotSentForEntityWithCompositeKey()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Notification is not sent for an entity with a composite key
        Initialize();

        // [GIVEN] A subscription for an entity with a composite key
        SubscriptionID := CreateActiveSubscriptionForEntityWithCompositeKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has not been been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationNotSentForEntityWithTemporarySource()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Notification is not sent for an entity with a temporary source table
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithTemporarySource();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting empty payload
        APIWebhookSendingEvents.AssertEmptyQueue();

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has not been started
        VerifyProcessingNotStarted();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEntityWithCompositeKeyExcludedFromPayload()
    var
        SimpleKeySubscriptionID: Text;
        CompositeKeySubscriptionID: Text;
        SimpleKeyNotificationID: Guid;
        CompositeKeyNotificationID: Guid;
    begin
        // [SCENARIO] Entity with a composite key is excluded from payload
        Initialize();

        // [GIVEN] A subscription for an entity with a simple key
        SimpleKeySubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A subscription for an entity with a composite key
        CompositeKeySubscriptionID := CreateActiveSubscriptionForEntityWithCompositeKey();

        // [GIVEN] A notification for an entity with a simple key
        SimpleKeyNotificationID := CreateNotificationOnCreate(SimpleKeySubscriptionID, ProcessingTime - 1000);
        // [GIVEN] A notification for an entity with a composite key
        CompositeKeyNotificationID := CreateNotificationOnCreate(CompositeKeySubscriptionID, ProcessingTime);
        // [GIVEN] Expecting one notifications in payload
        EnqueueNotificationUrl(SimpleKeySubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(SimpleKeyNotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription (simple key) has not been deleted
        VerifySubscriptionExists(SimpleKeySubscriptionID);
        // [THEN] Subscription (composite key) has been deleted
        VerifySubscriptionDoesNotExist(CompositeKeySubscriptionID);
        // [THEN] Notification (simple key) has been deleted
        VerifyNotificationDoesNotExist(SimpleKeyNotificationID);
        // [THEN] Notification (composite key) has been deleted
        VerifyNotificationDoesNotExist(CompositeKeyNotificationID);
        // [THEN] Notification (simple key) has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(SimpleKeyNotificationID);
        // [THEN] Notification (composite key) has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(CompositeKeyNotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithoutChangesAfterFailureResending()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO] Failed notification of type collection without any changes after failure has been resent
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A failed notification of change type collection
        LastModifiedDateTime := ProcessingTime - 2000;
        FirstModifiedDateTime := LastModifiedDateTime - 1000;
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, FirstModifiedDateTime, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, LastModifiedDateTime, 1);
        // [GIVEN] Expecting one notification of type collection in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, false);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Aggregate notification have been deleted
        VerifyAggregateNotificationDoesNotExist(FirstAggregateNotificationID);
        VerifyAggregateNotificationDoesNotExist(LastAggregateNotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithoutDeletesResending()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        NotificationID: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO] Failed notification of type collection without deletes has been resent
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A failed notification of change type collection
        LastModifiedDateTime := ProcessingTime - 2000;
        FirstModifiedDateTime := LastModifiedDateTime - 1000;
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, FirstModifiedDateTime, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, LastModifiedDateTime, 1);
        // [GIVEN] A new notification for the same subscription
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000);
        // [GIVEN] Expecting one notification of type collection in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, false);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Aggregate notification have been deleted
        VerifyAggregateNotificationDoesNotExist(FirstAggregateNotificationID);
        VerifyAggregateNotificationDoesNotExist(LastAggregateNotificationID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithOldDeletesResending()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        NotificationID: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO] Failed notification of type collection with old deletes has been resent
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A failed notification of change type collection with deletes
        LastModifiedDateTime := ProcessingTime - 2000;
        FirstModifiedDateTime := 0DT;
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, FirstModifiedDateTime, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, LastModifiedDateTime, 1);
        // [GIVEN] A new notification for the same subscription
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000);
        // [GIVEN] Expecting one notification of type collection in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, true);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Aggregate notification have been deleted
        VerifyAggregateNotificationDoesNotExist(FirstAggregateNotificationID);
        VerifyAggregateNotificationDoesNotExist(LastAggregateNotificationID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithNewDeletesResending()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        NotificationID: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO] Failed notification of type collection with new deletes has been resent
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A failed notification of change type collection without deletes
        LastModifiedDateTime := ProcessingTime - 2000;
        FirstModifiedDateTime := LastModifiedDateTime - 1000;
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, FirstModifiedDateTime, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, LastModifiedDateTime, 1);
        // [GIVEN] A new notification on delete for the same subscription
        NotificationID := CreateNotificationOnDelete(SubscriptionID, ProcessingTime - 1000);
        // [GIVEN] Expecting one notification of type collection in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, true);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Aggregate notification have been deleted
        VerifyAggregateNotificationDoesNotExist(FirstAggregateNotificationID);
        VerifyAggregateNotificationDoesNotExist(LastAggregateNotificationID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithLastDateTimeModifiedWithDeletes()
    var
        SubscriptionID: Text;
        NotificationID: array[3] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Entities with a "Last DateTime Modified" field are correctly aggregated in payload
        Initialize();

        // [GIVEN] A subscription for an entity with a "Last DateTime Modified" field
        SubscriptionID := CreateActiveSubscriptionForEntityWithLastDateTimeModified();
        // [GIVEN] Three notifications including notification on delete
        NotificationID[1] := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - 2000);
        NotificationID[2] := CreateNotificationOnUpdate(SubscriptionID, ProcessingTime - 1000);
        NotificationID[3] := CreateNotificationOnDelete(SubscriptionID, ProcessingTime);
        // [GIVEN] Notifications should be aggregated
        APIWebhookSendingEvents.SetMaxNumberOfNotifications(2);
        // [GIVEN] Expecting one notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(NotificationID[1], true);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notifications have been deleted
        for I := 1 to 3 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 3 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithLastDateTimeModifiedWithoutDeletes()
    var
        SubscriptionID: Text;
        NotificationID: array[3] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Entities with a "Last DateTime Modified" field are correctly aggregated in payload
        Initialize();

        // [GIVEN] A subscription for an entity with a "Last DateTime Modified" field
        SubscriptionID := CreateActiveSubscriptionForEntityWithLastDateTimeModified();
        // [GIVEN] Three notifications without notification on delete
        NotificationID[1] := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - 2000);
        NotificationID[2] := CreateNotificationOnUpdate(SubscriptionID, ProcessingTime - 1000);
        NotificationID[3] := CreateNotificationOnUpdate(SubscriptionID, ProcessingTime);
        // [GIVEN] Notifications should be aggregated
        APIWebhookSendingEvents.SetMaxNumberOfNotifications(2);
        // [GIVEN] Expecting one notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(NotificationID[1], false);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notifications have been deleted
        for I := 1 to 3 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 3 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadCollectionWithoutLastDateTimeModified()
    var
        SubscriptionID: Text;
        NotificationID: array[3] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Entities without a "Last DateTime Modified" field are correctly aggregated in payload
        Initialize();

        // [GIVEN] A subscription for an entity without a "Last DateTime Modified" field
        SubscriptionID := CreateActiveSubscriptionForEntityWithoutLastDateTimeModified();
        // [GIVEN] Three notifications
        NotificationID[1] := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - 2000);
        NotificationID[2] := CreateNotificationOnUpdate(SubscriptionID, ProcessingTime - 1000);
        NotificationID[3] := CreateNotificationOnUpdate(SubscriptionID, ProcessingTime);
        // [GIVEN] Notifications should be groupped
        APIWebhookSendingEvents.SetMaxNumberOfNotifications(2);
        // [GIVEN] Expecting one notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(NotificationID[1], false);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notifications have been deleted
        for I := 1 to 3 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 3 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadSingleEntityWithGuidKey()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Payload is correct for a single entity with a guid key
        Initialize();

        // [GIVEN] A subscription for an entity with a guid key
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting a single notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadSingleEntityWithIntegerKey()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Payload is correct for a single entity with an integer key
        Initialize();

        // [GIVEN] A subscription for an entity with an integer key
        SubscriptionID := CreateActiveSubscriptionForEntityWithIntegerKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting a single notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadSingleEntityWithCodeKey()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Payload is correct for a single entity with a code key
        Initialize();

        // [GIVEN] A subscription for an entity with a code key
        SubscriptionID := CreateActiveSubscriptionForEntityWithCodeKey();
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting a single notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadMultipleEntitiesSingleSubscription()
    var
        SubscriptionID: Text;
        NotificationID: array[5] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Payload is correct for multiple entities for a single subscription
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications
        for I := 1 to 2 do
            NotificationID[I] := CreateNotificationOnCreate(SubscriptionID, ProcessingTime - (2 - I) * 1000);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        for I := 1 to 2 do
            EnqueueSingleEntity(NotificationID[I]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notifications have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadMultipleEntitiesMultipleSubscriptionsSingleNotificationUrl()
    var
        SubscriptionID: array[10] of Text;
        NotificationID: array[2] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Payload is correct for multiple entities from different subscriptions with the same notification url
        Initialize();

        // [GIVEN] Many subscriptions with the same notification URL
        for I := 1 to 10 do
            SubscriptionID[I] := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications for two first subscriptions
        for I := 1 to 2 do
            NotificationID[I] := CreateNotificationOnCreate(SubscriptionID[I], ProcessingTime - (2 - I) * 1000);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID[1]);
        EnqueueEntityCount(2);
        if SubscriptionID[1] < SubscriptionID[2] then begin
            EnqueueSingleEntity(NotificationID[1]);
            EnqueueSingleEntity(NotificationID[2]);
        end else begin
            EnqueueSingleEntity(NotificationID[2]);
            EnqueueSingleEntity(NotificationID[1]);
        end;
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscriptions have not been deleted
        for I := 1 to 10 do
            VerifySubscriptionExists(SubscriptionID[I]);
        // [THEN] Notifications have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayloadMultipleEntitiesMultipleSubscriptionsMultipleNotificationUrls()
    var
        SubscriptionID: array[2] of Text;
        NotificationID: array[2] of Guid;
        I: Integer;
    begin
        // [SCENARIO] Payload is correct for multiple entities from different subscriptions with different notification url
        Initialize();

        // [GIVEN] Two subscriptions with different notification URLs
        for I := 1 to 2 do begin
            SubscriptionID[I] := CreateActiveSubscriptionForEntityWithGuidKey();
            SetNotificationUrl(SubscriptionID[I], I, 200);
        end;
        // [GIVEN] Two notifications
        for I := 1 to 2 do
            NotificationID[I] := CreateNotificationOnCreate(SubscriptionID[I], ProcessingTime - (2 - I) * 1000);
        // [GIVEN] Expecting two notifications in payload
        if SubscriptionID[1] < SubscriptionID[2] then
            for I := 1 to 2 do begin
                EnqueueNotificationUrl(SubscriptionID[I]);
                EnqueueEntityCount(1);
                EnqueueSingleEntity(NotificationID[I]);
                EnqueueResponseCode(200);
            end
        else
            for I := 2 downto 1 do begin
                EnqueueNotificationUrl(SubscriptionID[I]);
                EnqueueEntityCount(1);
                EnqueueSingleEntity(NotificationID[I]);
                EnqueueResponseCode(200);
            end;

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription have not been deleted
        for I := 1 to 2 do
            VerifySubscriptionExists(SubscriptionID[I]);
        // [THEN] Notifications have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertsNotAggregated()
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        SubscriptionID: Text;
        NotificationID: array[2] of Guid;
        EntityKeyValue: Text;
        ChangeType: Option;
        I: Integer;
    begin
        // [SCENARIO] Notifications on inserts are not aggregated in payload
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications on insert of entity with the same key value
        EntityKeyValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        ChangeType := TempAPIWebhookNotification."Change Type"::Created;
        for I := 1 to 2 do
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, ProcessingTime - (2 - I) * 1000, ChangeType);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        for I := 1 to 2 do
            EnqueueSingleEntity(NotificationID[I]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletesNotAggregated()
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        SubscriptionID: Text;
        NotificationID: array[2] of Guid;
        EntityKeyValue: Text;
        ChangeType: Option;
        I: Integer;
    begin
        // [SCENARIO] Notifications on deletes are not aggregated in payload
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications on delete of entity with the same key value
        EntityKeyValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        ChangeType := TempAPIWebhookNotification."Change Type"::Deleted;
        for I := 1 to 2 do
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, ProcessingTime - (2 - I) * 1000, ChangeType);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        for I := 1 to 2 do
            EnqueueSingleEntity(NotificationID[I]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonSequentialUpdatesNotAggregated()
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        SubscriptionID: Text;
        NotificationID: array[3] of Guid;
        EntityKeyValue: Text;
        ChangeType: Option;
        I: Integer;
    begin
        // [SCENARIO] Notifications on non-sequential updates are not aggregated in payload
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications on insert of entity with the same key value
        EntityKeyValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        for I := 1 to 3 do begin
            if I = 2 then
                ChangeType := TempAPIWebhookNotification."Change Type"::Deleted
            else
                ChangeType := TempAPIWebhookNotification."Change Type"::Updated;
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, ProcessingTime - (3 - I) * 1000, ChangeType);
        end;
        // [GIVEN] Expecting three notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(3);
        for I := 1 to 3 do
            EnqueueSingleEntity(NotificationID[I]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification have been deleted
        for I := 1 to 3 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 3 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSequentialUpdatesAggregated()
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        SubscriptionID: Text;
        NotificationID: array[2] of Guid;
        EntityKeyValue: Text;
        ChangeType: Option;
        I: Integer;
    begin
        // [SCENARIO] Notifications on sequential updates are aggregated in payload
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Two notifications on update of entity with the same key value
        EntityKeyValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        ChangeType := TempAPIWebhookNotification."Change Type"::Updated;
        for I := 1 to 2 do
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, ProcessingTime - (2 - I) * 1000, ChangeType);
        // [GIVEN] Expecting one notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID[2]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification have been deleted
        for I := 1 to 2 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 2 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatesAggregatedWhenCreateAndDeleteWithSameLastDateTimeModified()
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        SubscriptionID: Text;
        NotificationID: array[7] of Guid;
        EntityKeyValue: Text;
        LastModifiedDateTime: DateTime;
        I: Integer;
    begin
        // [SCENARIO] Notifications on sequential updates are aggregated in payload when there are notifications on create and delete with the same LastDateTimeModified
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Notifications on create, update and delete of entity with the same key value and the same LastDateTimeModified
        EntityKeyValue := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));

        LastModifiedDateTime := ProcessingTime - 1000;

        for I := 1 to 3 do
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, LastModifiedDateTime, TempAPIWebhookNotification."Change Type"::Updated);

        NotificationID[4] :=
          CreateNotification(SubscriptionID, EntityKeyValue, LastModifiedDateTime, TempAPIWebhookNotification."Change Type"::Deleted);
        NotificationID[5] :=
          CreateNotification(SubscriptionID, EntityKeyValue, LastModifiedDateTime, TempAPIWebhookNotification."Change Type"::Created);

        for I := 6 to 7 do
            NotificationID[I] :=
              CreateNotification(SubscriptionID, EntityKeyValue, LastModifiedDateTime, TempAPIWebhookNotification."Change Type"::Updated);

        // [GIVEN] Expecting three notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(3);
        EnqueueSingleEntity(NotificationID[5]);
        EnqueueSingleEntity(NotificationID[1]);
        EnqueueSingleEntity(NotificationID[4]);
        EnqueueResponseCode(200);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification have been deleted
        for I := 1 to 7 do
            VerifyNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Notifications have not been converted to aggregate
        for I := 1 to 7 do
            VerifyAggregateNotificationDoesNotExist(NotificationID[I]);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCollectionNotificationRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        NotificationID: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO] Notification of type collection is rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A failed notification
        LastModifiedDateTime := ProcessingTime - 1000;
        FirstModifiedDateTime := LastModifiedDateTime - 1000;
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, FirstModifiedDateTime, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, LastModifiedDateTime, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, false);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Aggregate notifications have not been deleted
        VerifyAggregateNotificationExists(FirstAggregateNotificationID);
        VerifyAggregateNotificationExists(LastAggregateNotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(FirstAggregateNotificationID, 2);
        VerifyAttemptNumber(LastAggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCollectionNotificationWithMissingRecordRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        AggregateNotificationID: Guid;
        NotificationID: Guid;
    begin
        // [SCENARIO] Notification of type collection is rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(AggregateNotificationID, true);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] The second aggregate notification has been inserted
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(AggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCollectionNotificationWithExtraRecordRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        FirstAggregateNotificationID: Guid;
        MiddleAggregateNotificationID: Guid;
        LastAggregateNotificationID: Guid;
        NotificationID: Guid;
    begin
        // [SCENARIO] Notification of type collection is rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A failed notification
        FirstAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, ProcessingTime - 3000, 1);
        MiddleAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, ProcessingTime - 2000, 1);
        LastAggregateNotificationID := CreateAggregateNotificationCollection(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueCollection(FirstAggregateNotificationID, false);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not been converted to aggregate
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] First and last aggregate notification have not been deleted
        VerifyAggregateNotificationExists(FirstAggregateNotificationID);
        VerifyAggregateNotificationExists(LastAggregateNotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Middle aggregate notification has been deleted
        VerifyAggregateNotificationDoesNotExist(MiddleAggregateNotificationID);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(FirstAggregateNotificationID, 2);
        VerifyAttemptNumber(LastAggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNormalNotificationRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
    begin
        // [SCENARIO] Normal notification is rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting one notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] One aggregate notification exist
        VerifyAggregateNotificationExists(NotificationID);
        VerifyAggregateNotificationCount(1);
        // [THEN] The first attempt number
        VerifyAttemptNumber(NotificationID, 1);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateNotificationRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Aggregate notification is rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime, 1);
        // [GIVEN] Expecting one notification in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(1);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Two aggregate notifications exist
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationCount(1);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(AggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationsRescheduledOnServerErrorFailure()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Notifications are rescheduled on error 500
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Two aggregate notifications exist
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationExists(NotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(AggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationsRescheduledOnRequestTimeoutFailure()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Notifications are rescheduled on error 408
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Request Timeout
        SetNotificationUrl(SubscriptionID, 1, 408);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(408);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Two aggregate notifications exist
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationExists(NotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(AggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationsRescheduledOnTooManyRequestsFailure()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Notifications are rescheduled on error 429
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Too Many Requests
        SetNotificationUrl(SubscriptionID, 1, 429);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(429);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has not been deleted
        VerifySubscriptionExists(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Two aggregate notifications exist
        VerifyAggregateNotificationExists(AggregateNotificationID);
        VerifyAggregateNotificationExists(NotificationID);
        VerifyAggregateNotificationCount(2);
        // [THEN] Attempts number has been increased
        VerifyAttemptNumber(AggregateNotificationID, 2);
        // [THEN] New job has correctly been scheduled
        VerifyJobRescheduled();
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubscriptionDeletedOnNotFoundFailure()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Subscription is deleted on error 404
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Not Found
        SetNotificationUrl(SubscriptionID, 1, 404);
        // [GIVEN] A failed notification
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 1);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(404);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Aggregate Notification has been deleted
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID);
        // [THEN] Job has not been scheduled
        VerifyJobCount(0);
        VerifyActivityLogExists(NotificationFailedTitleTxt);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubscriptionDeletedAfterManyFailures()
    var
        SubscriptionID: Text;
        NotificationID: Guid;
        AggregateNotificationID: Guid;
    begin
        // [SCENARIO] Subscription is deleted after many failures
        Initialize();

        // [GIVEN] A subscription
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        // [GIVEN] Expecting Server Error
        SetNotificationUrl(SubscriptionID, 1, 500);
        // [GIVEN] A notification has failed 2 times
        AggregateNotificationID := CreateAggregateNotificationOnCreate(SubscriptionID, ProcessingTime - 1000, 3);
        // [GIVEN] A notification
        NotificationID := CreateNotificationOnCreate(SubscriptionID, ProcessingTime);
        // [GIVEN] Max 3 attempts allowed
        APIWebhookSendingEvents.SetMaxNumberOfAttempts(2);
        // [GIVEN] Expecting two notifications in payload
        EnqueueNotificationUrl(SubscriptionID);
        EnqueueEntityCount(2);
        EnqueueSingleEntity(AggregateNotificationID);
        EnqueueSingleEntity(NotificationID);
        EnqueueResponseCode(500);

        // [WHEN] Process notifications
        ProcessNotifications();

        // [THEN] Correct payload has been sent
        APIWebhookSendingEvents.AssertEmptyQueue();
        // [THEN] Subscription has been deleted
        VerifySubscriptionDoesNotExist(SubscriptionID);
        // [THEN] Notification has been deleted
        VerifyNotificationDoesNotExist(NotificationID);
        // [THEN] Notification has not failed
        VerifyAggregateNotificationDoesNotExist(NotificationID);
        // [THEN] Aggregate notification has been deleted
        VerifyAggregateNotificationDoesNotExist(AggregateNotificationID);
        // [THEN] Job has not been scheduled
        VerifyJobCount(0);
        // [THEN] Messages have been logged
        VerifyActivityLogExists(NotificationFailedTitleTxt);
        VerifyActivityLogExists(IncreaseAttemptNumberTitleTxt);
        VerifyActivityLogExists(DeleteSubscriptionWithTooManyFailuresTitleTxt);
        // [THEN] Processing has been finished
        VerifyProcessingFinished();
    end;

    local procedure Initialize()
    begin
        Reset();

        APIWebhookSendingEvents.SetApiEnabled(true);
        APIWebhookSendingEvents.SetApiSubscriptionsEnabled(true);

        if IsInitialized then
            exit;

        BindSubscription(LibraryJobQueue);
        BindSubscription(APIWebhookSendingEvents);
        IsInitialized := true;
    end;

    local procedure Reset()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        JobQueueEntry: Record "Job Queue Entry";
        ActivityLog: Record "Activity Log";
    begin
        ProcessingTime := CurrentDateTime;
        APIWebhookSendingEvents.Reset();

        APIWebhookSubscription.DeleteAll();
        APIWebhookNotification.DeleteAll();
        APIWebhookNotificationAggr.DeleteAll();

        ActivityLog.SetRange(Context, ActivityLogContextLbl);
        ActivityLog.DeleteAll();

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);

        JobQueueEntry.ModifyAll(Status, JobQueueEntry.Status::"On Hold", true);
        JobQueueEntry.DeleteAll(true);
    end;

    local procedure ProcessNotifications()
    begin
        VerifyProcessingNotStarted();
        CODEUNIT.Run(CODEUNIT::"API Webhook Notification Send");
    end;

    local procedure GetWebhookEntityWithGuidKey(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - Item Entity");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::Item);
        ApiWebhookEntity.FindFirst();
    end;

    local procedure GetWebhookEntityWithIntegerKey(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - G/L Entry Entity");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::"G/L Entry");
        ApiWebhookEntity.FindFirst();
    end;

    local procedure GetWebhookEntityWithCodeKey(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - Configuration Package");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::"Config. Package");
        ApiWebhookEntity.FindFirst();
    end;

    local procedure GetWebhookEntityWithCompositeKey(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - Aut. Permission Sets");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::"Aggregate Permission Set");
        ApiWebhookEntity.FindFirst();
    end;

    local procedure GetWebhookEntityWithTemporarySource(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - Tax Area Entity");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::"Tax Area Buffer");
        ApiWebhookEntity.FindFirst();
    end;

    local procedure GetWebhookEntityWithLastDateTimeModified(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        GetWebhookEntityWithGuidKey(ApiWebhookEntity);
    end;

    local procedure GetWebhookEntityWithoutLastDateTimeModified(var ApiWebhookEntity: Record "Api Webhook Entity")
    begin
        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Object ID", PAGE::"Mock - Aut. Company Entity");
        ApiWebhookEntity.SetRange("Table No.", DATABASE::Company);
        ApiWebhookEntity.FindFirst();
    end;

    local procedure HasCodeKeyField(var APIWebhookSubscription: Record "API Webhook Subscription"): Boolean
    begin
        exit(APIWebhookSubscription."Source Table Id" = DATABASE::"Config. Package");
    end;

    local procedure HasLastDateTimeModifiedField(var APIWebhookSubscription: Record "API Webhook Subscription"): Boolean
    begin
        exit(APIWebhookSubscription."Source Table Id" = DATABASE::Item);
    end;

    local procedure GetResourceUrl(var APIWebhookSubscription: Record "API Webhook Subscription"; EntityKeyValue: Text; FirstModifiedDateTime: DateTime; Collection: Boolean): Text
    var
        APIWebhookNotificationSend: Codeunit "API Webhook Notification Send";
        InStream: InStream;
        ResourceUrl: Text;
        FirstModifiedDateTimeAdjusted: DateTime;
        FirstModifiedDateTimeUtcString: Text;
    begin
        APIWebhookSubscription."Resource Url Blob".CreateInStream(InStream);
        InStream.Read(ResourceUrl);

        if Collection then begin
            if FirstModifiedDateTime <> 0DT then
                if HasLastDateTimeModifiedField(APIWebhookSubscription) then begin
                    FirstModifiedDateTimeAdjusted := FirstModifiedDateTime - 50;
                    FirstModifiedDateTimeUtcString := APIWebhookNotificationSend.DateTimeToUtcString(FirstModifiedDateTimeAdjusted);
                    ResourceUrl += '?$filter=lastModifiedDateTime%20gt%20' + FirstModifiedDateTimeUtcString;
                end;
            exit(ResourceUrl);
        end;

        if HasCodeKeyField(APIWebhookSubscription) then
            ResourceUrl := StrSubstNo('%1(''%2'')', ResourceUrl, EntityKeyValue)
        else
            ResourceUrl := StrSubstNo('%1(%2)', ResourceUrl, EntityKeyValue);
        exit(ResourceUrl);
    end;

    local procedure GetNotificationUrl(var APIWebhookSubscription: Record "API Webhook Subscription"): Text
    var
        InStream: InStream;
        NotificationUrl: Text;
    begin
        APIWebhookSubscription."Notification Url Blob".CreateInStream(InStream);
        InStream.Read(NotificationUrl);
        exit(NotificationUrl);
    end;

    local procedure CreateExpiredSubscription(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime - MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithGuidKey(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateObsoleteSubscription(): Text
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text;
    begin
        SubscriptionID := CreateActiveSubscriptionForEntityWithGuidKey();
        APIWebhookSubscription.Get(SubscriptionID);
        APIWebhookSubscription."Entity Publisher" := 'mock';
        APIWebhookSubscription."Entity Group" := 'test';
        APIWebhookSubscription."Entity Version" := 'v9999.9';
        APIWebhookSubscription."Entity Set Name" := 'fake';
        APIWebhookSubscription.Modify();
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithGuidKey(SubscriptionID: Text): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        ExpirationDateTime: DateTime;
    begin
        GetWebhookEntityWithGuidKey(ApiWebhookEntity);
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime, SubscriptionID);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithGuidKey(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithGuidKey(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithIntegerKey(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithIntegerKey(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithCodeKey(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithCodeKey(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithCompositeKey(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithCompositeKey(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithTemporarySource(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithTemporarySource(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithLastDateTimeModified(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithLastDateTimeModified(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateActiveSubscriptionForEntityWithoutLastDateTimeModified(): Text
    var
        SubscriptionID: Text;
        ExpirationDateTime: DateTime;
    begin
        ExpirationDateTime := ProcessingTime + MillisecondsPerDay();
        SubscriptionID := CreateSubscriptionForEntityWithoutLastDateTimeModified(ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithGuidKey(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithGuidKey(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithIntegerKey(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithIntegerKey(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithCodeKey(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithCodeKey(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithCompositeKey(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithCompositeKey(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithTemporarySource(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithTemporarySource(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithLastDateTimeModified(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithLastDateTimeModified(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntityWithoutLastDateTimeModified(ExpirationDateTime: DateTime): Text
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        SubscriptionID: Text;
    begin
        GetWebhookEntityWithoutLastDateTimeModified(ApiWebhookEntity);
        SubscriptionID := CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime);
        exit(SubscriptionID);
    end;

    local procedure CreateSubscriptionForEntity(var ApiWebhookEntity: Record "Api Webhook Entity"; ExpirationDateTime: DateTime): Text
    begin
        exit(CreateSubscriptionForEntity(ApiWebhookEntity, ExpirationDateTime, ''));
    end;

    local procedure CreateSubscriptionForEntity(var ApiWebhookEntity: Record "Api Webhook Entity"; ExpirationDateTime: DateTime; SubscriptionID: Text[150]): Text
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
    begin
        if SubscriptionID = '' then
            SubscriptionID := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));
        APIWebhookSubscription."Subscription Id" :=
          CopyStr(SubscriptionID, 1, MaxStrLen(APIWebhookSubscription."Subscription Id"));
        APIWebhookSubscription."Entity Publisher" := ApiWebhookEntity.Publisher;
        APIWebhookSubscription."Entity Group" := ApiWebhookEntity.Group;
        APIWebhookSubscription."Entity Version" := ApiWebhookEntity.Version;
        APIWebhookSubscription."Entity Set Name" := ApiWebhookEntity.Name;
        APIWebhookSubscription."Company Name" := CompanyName;
        APIWebhookSubscription."User Id" := UserSecurityId();
        APIWebhookSubscription."Last Modified Date Time" := ProcessingTime;
        APIWebhookSubscription."Client State" := CopyStr(ClientStateTxt, 1, MaxStrLen(APIWebhookSubscription."Client State"));
        APIWebhookSubscription."Expiration Date Time" := ExpirationDateTime;
        APIWebhookSubscription."Source Table Id" := ApiWebhookEntity."Table No.";
        APIWebhookSubscription.Insert();
        SetResourceUrl(SubscriptionID, ApiWebhookEntity."Object ID");
        SetNotificationUrl(SubscriptionID, 1, 200);
        exit(SubscriptionID);
    end;

    local procedure CreateNotificationOnCreate(SubscriptionID: Text; LastModifiedDateTime: DateTime): Guid
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        NotificationID: Guid;
    begin
        NotificationID := CreateNotification(
            SubscriptionID,
            LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid())),
            LastModifiedDateTime,
            TempAPIWebhookNotification."Change Type"::Created);
        exit(NotificationID);
    end;

    local procedure CreateNotificationOnUpdate(SubscriptionID: Text; LastModifiedDateTime: DateTime): Guid
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        NotificationID: Guid;
    begin
        NotificationID := CreateNotification(
            SubscriptionID,
            LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid())),
            LastModifiedDateTime,
            TempAPIWebhookNotification."Change Type"::Updated);
        exit(NotificationID);
    end;

    local procedure CreateNotificationOnDelete(SubscriptionID: Text; LastModifiedDateTime: DateTime): Guid
    var
        TempAPIWebhookNotification: Record "API Webhook Notification" temporary;
        NotificationID: Guid;
    begin
        NotificationID := CreateNotification(
            SubscriptionID,
            LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid())),
            LastModifiedDateTime,
            TempAPIWebhookNotification."Change Type"::Deleted);
        exit(NotificationID);
    end;

    local procedure CreateNotification(SubscriptionID: Text; EntityKeyValue: Text; LastModifiedDateTime: DateTime; ChangeType: Option): Guid
    var
        APIWebhookNotification: Record "API Webhook Notification";
        NotificationID: Guid;
    begin
        NotificationID := CreateGuid();
        APIWebhookNotification.ID := NotificationID;
        APIWebhookNotification."Subscription ID" :=
          CopyStr(SubscriptionID, 1, MaxStrLen(APIWebhookNotification."Subscription ID"));
        APIWebhookNotification."Created By User SID" := UserSecurityId();
        APIWebhookNotification."Entity Key Value" :=
          CopyStr(EntityKeyValue, 1, MaxStrLen(APIWebhookNotification."Entity Key Value"));
        APIWebhookNotification."Last Modified Date Time" := LastModifiedDateTime;
        APIWebhookNotification."Change Type" := ChangeType;
        APIWebhookNotification.Insert();
        exit(NotificationID);
    end;

    local procedure CreateAggregateNotificationOnCreate(SubscriptionID: Text; LastModifiedDateTime: DateTime; AttemptNumber: Integer): Guid
    var
        TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary;
        NotificationID: Guid;
    begin
        NotificationID := CreateAggregateNotification(
            SubscriptionID, TempAPIWebhookNotificationAggr."Change Type"::Created, LastModifiedDateTime, AttemptNumber);
        exit(NotificationID);
    end;

    local procedure CreateAggregateNotificationCollection(SubscriptionID: Text; LastModifiedDateTime: DateTime; AttemptNumber: Integer): Guid
    var
        TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary;
        NotificationID: Guid;
    begin
        NotificationID := CreateAggregateNotification(
            SubscriptionID, TempAPIWebhookNotificationAggr."Change Type"::Collection, LastModifiedDateTime, AttemptNumber);
        exit(NotificationID);
    end;

    local procedure CreateAggregateNotification(SubscriptionID: Text; ChangeType: Option; LastModifiedDateTime: DateTime; AttemptNumber: Integer): Guid
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        NotificationID: Guid;
    begin
        NotificationID := CreateGuid();
        APIWebhookNotificationAggr.ID := NotificationID;
        APIWebhookNotificationAggr."Subscription ID" := CopyStr(SubscriptionID, 1,
            MaxStrLen(APIWebhookNotificationAggr."Subscription ID"));
        APIWebhookNotificationAggr."Created By User SID" := UserSecurityId();
        APIWebhookNotificationAggr."Entity Key Value" := CopyStr(LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid())), 1,
            MaxStrLen(APIWebhookNotificationAggr."Entity Key Value"));
        APIWebhookNotificationAggr."Last Modified Date Time" := LastModifiedDateTime;
        APIWebhookNotificationAggr."Change Type" := ChangeType;
        APIWebhookNotificationAggr."Attempt No." := AttemptNumber;
        APIWebhookNotificationAggr."Sending Scheduled Date Time" := 0DT;
        APIWebhookNotificationAggr.Insert();
        exit(NotificationID);
    end;

    local procedure SetNotificationUrl(SubscriptionID: Text; Number: Integer; ResponseCode: Integer)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        OutStream: OutStream;
        NotificationUrl: Text;
    begin
        APIWebhookSubscription.Get(SubscriptionID);
        NotificationUrl := StrSubstNo(NotificationUrlTxt, Number, ResponseCode);
        APIWebhookSubscription."Notification Url Prefix" :=
          CopyStr(NotificationUrl, 1, MaxStrLen(APIWebhookSubscription."Notification Url Prefix"));

        APIWebhookSubscription."Notification Url Blob".CreateOutStream(OutStream);
        OutStream.Write(NotificationUrl);

        APIWebhookSubscription.Modify();
    end;

    local procedure SetResourceUrl(SubscriptionID: Text; PageID: Integer)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        OutStream: OutStream;
        ResourceUrl: Text;
    begin
        APIWebhookSubscription.Get(SubscriptionID);
        ResourceUrl := GetUrl(CLIENTTYPE::Api, CompanyName, OBJECTTYPE::Page, PageID);

        APIWebhookSubscription."Resource Url Blob".CreateOutStream(OutStream);
        OutStream.Write(ResourceUrl);

        APIWebhookSubscription.Modify();
    end;

    local procedure GetJobCount(): Integer
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        JobQueueEntry.SetFilter(Status, '<>%1', JobQueueEntry.Status::"In Process");
        exit(JobQueueEntry.Count);
    end;

    local procedure FindSubscription(SubscriptionID: Text): Boolean
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
    begin
        exit(APIWebhookSubscription.Get(SubscriptionID));
    end;

    local procedure FindNotification(NotificationID: Guid): Boolean
    var
        APIWebhookNotification: Record "API Webhook Notification";
    begin
        exit(APIWebhookNotification.Get(NotificationID));
    end;

    local procedure FindAggregateNotification(NotificationID: Guid): Boolean
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
    begin
        exit(APIWebhookNotificationAggr.Get(NotificationID));
    end;

    local procedure EnqueueNotificationUrl(SubscriptionID: Text)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        NotificationUrl: Text;
    begin
        APIWebhookSubscription.SetAutoCalcFields("Notification Url Blob", "Resource Url Blob");
        APIWebhookSubscription.Get(SubscriptionID);
        NotificationUrl := GetNotificationUrl(APIWebhookSubscription);
        APIWebhookSendingEvents.EnqueueVariable(NotificationUrl);
    end;

    local procedure EnqueueResponseCode(ResponseCode: Integer)
    begin
        APIWebhookSendingEvents.EnqueueVariable(ResponseCode);
    end;

    local procedure EnqueueEntityCount(EntityCount: Integer)
    begin
        APIWebhookSendingEvents.EnqueueVariable(EntityCount);
    end;

    local procedure EnqueueSingleEntity(NotificationID: Guid)
    var
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text;
        ChangeType: Text;
        ResourceUrl: Text;
    begin
        if APIWebhookNotification.Get(NotificationID) then begin
            SubscriptionID := APIWebhookNotification."Subscription ID";
            ChangeType := LowerCase(Format(APIWebhookNotification."Change Type"));
            APIWebhookSubscription.SetAutoCalcFields("Resource Url Blob");
            APIWebhookSubscription.Get(SubscriptionID);
            ResourceUrl := GetResourceUrl(
                APIWebhookSubscription, APIWebhookNotification."Entity Key Value",
                APIWebhookNotification."Last Modified Date Time",
                false);
            APIWebhookSendingEvents.EnqueueVariable(SubscriptionID);
            APIWebhookSendingEvents.EnqueueVariable(ChangeType);
            APIWebhookSendingEvents.EnqueueVariable(ResourceUrl);
            exit;
        end;
        if APIWebhookNotificationAggr.Get(NotificationID) then begin
            SubscriptionID := APIWebhookNotificationAggr."Subscription ID";
            ChangeType := LowerCase(Format(APIWebhookNotificationAggr."Change Type"));
            APIWebhookSubscription.SetAutoCalcFields("Resource Url Blob");
            APIWebhookSubscription.Get(SubscriptionID);
            ResourceUrl := GetResourceUrl(
                APIWebhookSubscription, APIWebhookNotificationAggr."Entity Key Value",
                APIWebhookNotificationAggr."Last Modified Date Time", false);
            APIWebhookSendingEvents.EnqueueVariable(SubscriptionID);
            APIWebhookSendingEvents.EnqueueVariable(ChangeType);
            APIWebhookSendingEvents.EnqueueVariable(ResourceUrl);
        end;
    end;

    local procedure EnqueueCollection(FirstNotificationID: Guid; HasDeletes: Boolean)
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionID: Text;
        ChangeType: Text;
        ResourceUrl: Text;
        FirstModifiedDateTime: DateTime;
    begin
        if APIWebhookNotification.Get(FirstNotificationID) then begin
            SubscriptionID := APIWebhookNotification."Subscription ID";
            if not HasDeletes then
                FirstModifiedDateTime := APIWebhookNotification."Last Modified Date Time";
        end else begin
            APIWebhookNotificationAggr.Get(FirstNotificationID);
            SubscriptionID := APIWebhookNotificationAggr."Subscription ID";
            if not HasDeletes then
                FirstModifiedDateTime := APIWebhookNotificationAggr."Last Modified Date Time";
        end;
        ChangeType := LowerCase(Format(APIWebhookNotification."Change Type"::Collection));
        APIWebhookSubscription.SetAutoCalcFields("Resource Url Blob");
        APIWebhookSubscription.Get(SubscriptionID);
        ResourceUrl := GetResourceUrl(APIWebhookSubscription, '', FirstModifiedDateTime, true);
        APIWebhookSendingEvents.EnqueueVariable(SubscriptionID);
        APIWebhookSendingEvents.EnqueueVariable(ChangeType);
        APIWebhookSendingEvents.EnqueueVariable(ResourceUrl);
    end;

    local procedure MillisecondsPerDay(): BigInteger
    begin
        exit(86400000);
    end;

    local procedure VerifySubscriptionExists(SubscriptionID: Text)
    begin
        Assert.IsTrue(FindSubscription(SubscriptionID), 'Subscription is not found');
    end;

    local procedure VerifyNotificationExists(NotificationID: Guid)
    begin
        Assert.IsTrue(FindNotification(NotificationID), 'Notification is not found');
    end;

    local procedure VerifyAggregateNotificationExists(NotificationID: Guid)
    begin
        Assert.IsTrue(FindAggregateNotification(NotificationID), 'Aggregate notification is not found');
    end;

    local procedure VerifyAttemptNumber(NotificationID: Guid; AttemptNumber: Integer)
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
    begin
        Assert.IsTrue(APIWebhookNotificationAggr.Get(NotificationID), 'Attempt number is incorrect');
        Assert.AreEqual(AttemptNumber, APIWebhookNotificationAggr."Attempt No.", 'Attempt number is incorrect');
    end;

    local procedure VerifySubscriptionDoesNotExist(SubscriptionID: Text)
    begin
        Assert.IsFalse(FindSubscription(SubscriptionID), 'Subscription is found');
    end;

    local procedure VerifyNotificationDoesNotExist(NotificationID: Guid)
    begin
        Assert.IsFalse(FindNotification(NotificationID), 'Notification is found');
    end;

    local procedure VerifyAggregateNotificationDoesNotExist(NotificationID: Guid)
    begin
        Assert.IsFalse(FindAggregateNotification(NotificationID), 'Aggregate notification is found');
    end;

    local procedure VerifyAggregateNotificationCount(ExpectedCount: Integer)
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
    begin
        Assert.AreEqual(ExpectedCount, APIWebhookNotificationAggr.Count, 'Wrong number of aggregate notifications');
    end;

    local procedure VerifyProcessingNotStarted()
    var
        ActualStatus: Text;
    begin
        ActualStatus := APIWebhookSendingEvents.GetProcessingStatus();
        Assert.IsTrue((ActualStatus <> 'Started') and (ActualStatus <> 'Finished'), 'Incorrect processing status');
    end;

    local procedure VerifyProcessingFinished()
    var
        ActualStatus: Text;
    begin
        ActualStatus := APIWebhookSendingEvents.GetProcessingStatus();
        Assert.AreEqual('Finished', ActualStatus, 'Incorrect processing status');
    end;

    local procedure VerifyJobRescheduled()
    begin
        VerifyJobCount(1);
        VerifyActivityLogExists(NotificationFailedTitleTxt);
        VerifyActivityLogExists(IncreaseAttemptNumberTitleTxt);
    end;

    local procedure VerifyJobCount(ExpectedCount: Integer)
    begin
        Assert.AreEqual(ExpectedCount, GetJobCount(), 'Unexpected job count');
    end;

    local procedure VerifyActivityLogExists(ExpectedMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange(Context, ActivityLogContextLbl);
        ActivityLog.SetRange(Description, ExpectedMessage);
        Assert.IsTrue(ActivityLog.FindFirst(), 'Activity log is not found');
    end;
}
