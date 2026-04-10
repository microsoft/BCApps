codeunit 139480 "Notification Lifecycle Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        NotificationMsg: Label 'Notification message.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Cleanup()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextCreationWithAdditionalContext()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        NotificationId: Guid;
        AdditionalContextId: Guid;
    begin
        // [SCENARIO] Create a notification context with an additional context GUID, and check it is created correctly
        Initialize();

        // [GIVEN] A notification, a record that triggered the notification and a context of the creation of the notification (a cause)
        NotificationId := CreateGuid();
        Notification.Id := NotificationId;
        Notification.Message := NotificationMsg;
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        AdditionalContextId := CreateGuid(); // Represents the cause of the notification (why?)

        // [WHEN] I register the context of the notification
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          Notification, Customer.RecordId, AdditionalContextId);

        // [THEN] The context is stored
        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          Customer.RecordId, AdditionalContextId, TempNotificationContext, true);

        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records');
        TempNotificationContext.FindFirst();
        Assert.AreEqual(
          NotificationId, TempNotificationContext."Notification ID", 'Unexpected notification GUID in NotificationContext');
        Assert.AreEqual(Customer.RecordId, TempNotificationContext."Record ID", 'Unexpected Record ID in NotificationContext');
        Assert.AreEqual(
          AdditionalContextId, TempNotificationContext."Additional Context ID",
          'Unexpected additional context GUID in NotificationContext');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextCreation()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        NotificationId: Guid;
    begin
        // [SCENARIO] Create a notification context without an additional context GUID, and check it is created correctly
        Initialize();

        // [GIVEN] A notification, a record that triggered the notification and a context of the creation of the notification (a cause)
        NotificationId := CreateGuid();
        Notification.Id := NotificationId;
        Notification.Message := NotificationMsg;
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)

        // [WHEN] I register the context of the notification
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.SendNotification(Notification, Customer.RecordId);

        // [THEN] The context is stored
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true);
        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records');
        TempNotificationContext.FindFirst();
        Assert.IsTrue(
          IsNullGuid(TempNotificationContext."Additional Context ID"),
          'Unexpected additional context GUID in NotificationContext (should be null GUID)');
        Assert.AreEqual(
          NotificationId, TempNotificationContext."Notification ID", 'Unexpected notification GUID in NotificationContext');
        Assert.AreEqual(Customer.RecordId, TempNotificationContext."Record ID", 'Unexpected Record ID in NotificationContext');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextCreationWithNoGuid()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DummyNotificationWithContext: Notification;
        DummyNotification: Notification;
        AdditionalContextId: Guid;
    begin
        // [SCENARIO] Create 2 notification contexts with and without an additional context GUID and without setting their GUID, and check they are created correctly
        Initialize();

        // [GIVEN] 2 notifications with no GUID, a record that triggered the notifications and a context of the creation of one of the notifications (a cause)
        DummyNotification.Message := NotificationMsg;
        DummyNotificationWithContext.Message := NotificationMsg;
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        AdditionalContextId := CreateGuid();

        // [WHEN] I register the context of the notification
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.SendNotification(DummyNotification, Customer.RecordId);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          DummyNotificationWithContext, Customer.RecordId, AdditionalContextId);

        // [THEN] The context is stored
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true);
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records');
        TempNotificationContext.FindSet();
        repeat
            Assert.IsFalse(IsNullGuid(TempNotificationContext."Notification ID"), 'Unexpected notification GUID in NotificationContext');
            Assert.AreEqual(Customer.RecordId, TempNotificationContext."Record ID", 'Unexpected Record ID in NotificationContext');
        until TempNotificationContext.Next() = 0;
        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextRemovalWithAdditionalContext()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToRemove1: Notification;
        NotificationToRemove2: Notification;
        AdditionalContextId: Guid;
    begin
        // [SCENARIO] Create 2 notification contexts without an additional context GUID, and check they are removed correctly
        Initialize();

        // [GIVEN] A notification, a record that triggered the notification and a context of the creation of the notification (a cause)
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        AdditionalContextId := CreateGuid(); // Represents the cause of the notification (why?)
        NotificationToRemove1.Id := CreateGuid();
        NotificationToRemove1.Message := NotificationMsg;
        NotificationToRemove2.Id := CreateGuid();
        NotificationToRemove2.Message := NotificationMsg;
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToRemove1, Customer.RecordId, AdditionalContextId);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToRemove2, Customer.RecordId, AdditionalContextId);

        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records'); // just check the inserts succeeded

        // [WHEN] I recall the context of the notification
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(Customer.RecordId, AdditionalContextId, true);

        // [THEN] The context is removed
        TempNotificationContext.Reset();
        Assert.AreEqual(0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextRemovalTargetsCorrectRecordsWithAdditionalContext()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToRecall1: Notification;
        NotificationToRecall2: Notification;
        NotificationToKeep: Notification;
        AdditionalContextIdThatRemains: Guid;
        AdditionalContextId: Guid;
    begin
        // [SCENARIO] Create 3 notification contexts without an additional context GUID: 2 with the same GUID, one with another GUID. Remove the 2 notification contexts with the same GUID, and check that the third one remains
        Initialize();

        // [GIVEN] 3 notifications, a record that triggered the notifications and 2 different contexts of the creation of the notifications (2 different causes)
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        NotificationToRecall1.Id := CreateGuid();
        NotificationToRecall1.Message := NotificationMsg;
        NotificationToRecall2.Id := CreateGuid();
        NotificationToRecall2.Message := NotificationMsg;
        NotificationToKeep.Id := CreateGuid();
        NotificationToKeep.Message := NotificationMsg;
        AdditionalContextId := CreateGuid(); // Represents the cause of the notification that will be deleted (why?)
        AdditionalContextIdThatRemains := CreateGuid(); // Represents the cause of the notification that will remain (why?)
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToRecall1, Customer.RecordId, AdditionalContextId);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToRecall2, Customer.RecordId, AdditionalContextId);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          NotificationToKeep, Customer.RecordId, AdditionalContextIdThatRemains);

        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          Customer.RecordId, AdditionalContextId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records'); // just check the inserts succeeded
        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          Customer.RecordId, AdditionalContextIdThatRemains, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records'); // just check the inserts succeeded

        // [WHEN] I recall the first notification context (2 notification context lines)
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(Customer.RecordId, AdditionalContextId, true);

        // [THEN] The context is removed for the 2 notifications, but not for the third
        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          Customer.RecordId, AdditionalContextId, TempNotificationContext, true); // get the temp notification context that was deleted
        Assert.AreEqual(
          0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the additional context that was removed');
        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          Customer.RecordId, AdditionalContextIdThatRemains, TempNotificationContext, true); // get the temp notification context that should still be here
        Assert.AreEqual(
          1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the additional context that should stay unaffected');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextReplacement()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToInsertTwice: Notification;
        NotificationId: Guid;
    begin
        // [SCENARIO] Create a notification context without an additional context GUID, then insert it again. No error expected.
        Initialize();

        // [GIVEN] A notification, a record that triggered the notification and a context of the creation of the notification (a cause)
        NotificationId := CreateGuid(); // Represents the notification
        NotificationToInsertTwice.Id := NotificationId;
        NotificationToInsertTwice.Message := NotificationMsg;
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        NotificationLifecycleMgt.SendNotification(NotificationToInsertTwice, Customer.RecordId); // save the notification context

        // [WHEN] I register the context of the notification a second time
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.SendNotification(NotificationToInsertTwice, Customer.RecordId);

        // [THEN] The context is stored successfully
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true);
        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records after replacement');
        TempNotificationContext.FindFirst();
        Assert.AreEqual(
          NotificationId, TempNotificationContext."Notification ID",
          'Unexpected notification GUID in NotificationContext after replacement');
        Assert.IsTrue(
          IsNullGuid(TempNotificationContext."Additional Context ID"),
          'Unexpected additional context GUID in NotificationContext (should be null GUID) after replacement');
        Assert.AreEqual(
          Customer.RecordId, TempNotificationContext."Record ID", 'Unexpected Record ID in NotificationContext after replacement');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextRemoval()
    var
        Customer: Record Customer;
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToRecall1: Notification;
        NotificationToRecall2: Notification;
    begin
        // [SCENARIO] Create two notification contexts without an additional context GUID, remove the notifications, and check they are correctly removed
        Initialize();

        // [GIVEN] Two notifications, a record that triggered the notification
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        NotificationToRecall1.Id := CreateGuid();
        NotificationToRecall1.Message := NotificationMsg;
        NotificationToRecall2.Id := CreateGuid();
        NotificationToRecall2.Message := NotificationMsg;
        NotificationLifecycleMgt.SendNotification(NotificationToRecall1, Customer.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToRecall2, Customer.RecordId);

        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records'); // just check the inserts succeeded

        // [WHEN] I recall the context of the notification for this record ID
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.RecallNotificationsForRecord(Customer.RecordId, true);

        // [THEN] The context is removed for all of them
        Assert.AreEqual(0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextRemovalTargetsCorrectRecords()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToRecall1: Notification;
        NotificationToRecall2: Notification;
        NotificationToKeep: Notification;
    begin
        // [SCENARIO] Create 3 notification contexts without an additional context GUID: 2 with the same, one with another GUID. Remove the 2 notification contexts, and check that the third one remains
        Initialize();

        // [GIVEN] 3 notifications, 2 records that triggered the notifications
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the notification (on what?)
        LibrarySales.CreateSalesInvoice(SalesHeader); // Represents the cause object of a third notification
        NotificationToRecall1.Id := CreateGuid();
        NotificationToRecall1.Message := NotificationMsg;
        NotificationToRecall2.Id := CreateGuid();
        NotificationToRecall2.Message := NotificationMsg;
        NotificationToKeep.Id := CreateGuid();
        NotificationToKeep.Message := NotificationMsg;
        NotificationLifecycleMgt.SendNotification(NotificationToRecall1, Customer.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToRecall2, Customer.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToKeep, SalesHeader.RecordId);

        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records for the Customer'); // just check the inserts succeeded
        NotificationLifecycleMgt.GetNotificationsForRecord(SalesHeader.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records for the SalesHeader'); // just check the inserts succeeded

        // [WHEN] I recall the notifications related to the customer (2 notification context lines)
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.RecallNotificationsForRecord(Customer.RecordId, true);

        // [THEN] The context is removed for the 2 notifications related to the customer, but not the third notification related to the SalesHeader
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context that was deleted
        Assert.AreEqual(0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the Customer');
        NotificationLifecycleMgt.GetNotificationsForRecord(SalesHeader.RecordId, TempNotificationContext, true); // get the temp notification context that should still be here
        Assert.AreEqual(1, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the SalesHeader');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestAllNotificationContextRemoval()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToRecall1: Notification;
        NotificationToRecall2: Notification;
        NotificationToRecall3: Notification;
        NotificationToRecall4: Notification;
    begin
        // [SCENARIO] Create 4 notification contexts and remove them all. Check that they are gone.
        Initialize();

        // [GIVEN] 4 notifications, 2 records that triggered the notifications
        LibrarySales.CreateCustomer(Customer); // Represents the cause object of the first 2 notifications
        LibrarySales.CreateSalesInvoice(SalesHeader); // Represents the cause object of the next 2 notifications
        NotificationToRecall1.Id := CreateGuid();
        NotificationToRecall1.Message := NotificationMsg;
        NotificationToRecall2.Id := CreateGuid();
        NotificationToRecall2.Message := NotificationMsg;
        NotificationToRecall3.Id := CreateGuid();
        NotificationToRecall3.Message := NotificationMsg;
        NotificationToRecall4.Id := CreateGuid();
        NotificationToRecall4.Message := NotificationMsg;
        NotificationLifecycleMgt.SendNotification(NotificationToRecall1, Customer.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToRecall2, Customer.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToRecall3, SalesHeader.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToRecall4, SalesHeader.RecordId);

        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records for the Customer'); // just check the inserts succeeded
        NotificationLifecycleMgt.GetNotificationsForRecord(SalesHeader.RecordId, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(2, TempNotificationContext.Count, 'Unexpected number of NotificationContext records for the SalesHeader'); // just check the inserts succeeded

        // [WHEN] I recall all notifications
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.RecallAllNotifications();

        // [THEN] The context is removed for the 4 notifications
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context that was deleted
        Assert.AreEqual(0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the Customer');
        NotificationLifecycleMgt.GetNotificationsForRecord(SalesHeader.RecordId, TempNotificationContext, true); // get the temp notification context that was deleted
        Assert.AreEqual(0, TempNotificationContext.Count, 'Unexpected number of NotificationContext records, for the SalesHeader');

        Cleanup();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationContextUpdateRecordId()
    var
        InitialCustomer: Record Customer;
        FinalCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToUpdate: Notification;
        NotificationToKeep: Notification;
    begin
        // [SCENARIO] Create 2 notification contexts without an additional context GUID. Update the record ID of one of them. Check the state is correct.
        Initialize();

        // [GIVEN] 2 notifications, 3 records that triggered the notifications
        LibrarySales.CreateCustomer(InitialCustomer); // Represents the cause object of the notification (on what?)
        LibrarySales.CreateCustomer(FinalCustomer);
        LibrarySales.CreateSalesInvoice(SalesHeader); // Represents the cause object of a third notification
        NotificationToKeep.Id := CreateGuid();
        NotificationToKeep.Message := NotificationMsg;
        NotificationToUpdate.Id := CreateGuid();
        NotificationToUpdate.Message := NotificationMsg;

        NotificationLifecycleMgt.SendNotification(NotificationToKeep, SalesHeader.RecordId);
        NotificationLifecycleMgt.SendNotification(NotificationToUpdate, InitialCustomer.RecordId);

        ChecksForUpdateRecordId(InitialCustomer.RecordId, SalesHeader.RecordId, FinalCustomer.RecordId); // just check the inserts are as expected

        // [WHEN] I update the record ID of the notification to update (change the notification from the initial customer to the final customer)
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.UpdateRecordID(InitialCustomer.RecordId, FinalCustomer.RecordId);

        // [THEN] The context is updated correctly
        ChecksForUpdateRecordId(FinalCustomer.RecordId, SalesHeader.RecordId, InitialCustomer.RecordId);

        Cleanup();
    end;

    [Scope('OnPrem')]
    procedure ChecksForUpdateRecordId(FirstRecordIdWithOneOccurence: RecordID; SecondRecordIdWithOneOccurence: RecordID; RecordIdWithNoOccurrences: RecordID)
    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetNotificationsForRecord(FirstRecordIdWithOneOccurence, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(1, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');
        NotificationLifecycleMgt.GetNotificationsForRecord(SecondRecordIdWithOneOccurence, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(1, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');
        NotificationLifecycleMgt.GetNotificationsForRecord(RecordIdWithNoOccurrences, TempNotificationContext, true); // get the temp notification context
        Assert.AreEqual(0, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDelayedInsert()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerNotification: Notification;
        SalesHeaderNotification: Notification;
        UninitializedCustomerRecId: RecordID;
        UninitializedSalesHeaderRecId: RecordID;
        AdditionalContextId: Guid;
    begin
        // [SCENARIO] Create objects with record IDs not existing in the database to simulate delayed insertion, and check these are handled correctly
        Initialize();

        // [GIVEN] 2 records initialized to simulate the delayed insert issue: an incomplete record ID that does not correspond to any existing object
        UninitializedCustomerRecId := Customer.RecordId;
        UninitializedSalesHeaderRecId := SalesHeader.RecordId;
        LibrarySales.CreateSalesInvoice(SalesHeader); // create the objects
        LibrarySales.CreateCustomer(Customer);
        Customer.Delete(); // delete them from the database. They have now a record ID but they do not exist in the database.
        SalesHeader.Delete();

        CustomerNotification.Id := CreateGuid();
        CustomerNotification.Message := NotificationMsg;
        SalesHeaderNotification.Id := CreateGuid();
        SalesHeaderNotification.Message := NotificationMsg;
        AdditionalContextId := CreateGuid();

        // [WHEN] We send the notifications for these records
        LibraryLowerPermissions.SetO365Basic();
        NotificationLifecycleMgt.SendNotification(CustomerNotification, Customer.RecordId); // will insert with an empty record ID
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(SalesHeaderNotification, SalesHeader.RecordId, AdditionalContextId); // will insert with an empty record ID

        // [THEN] The records are inserted as expected
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, true); // get the temp notification context, handle delayed insert
        Assert.AreEqual(1, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');
        Assert.AreEqual(UninitializedCustomerRecId, TempNotificationContext."Record ID", 'Unexpected record ID');
        NotificationLifecycleMgt.GetNotificationsForRecord(Customer.RecordId, TempNotificationContext, false); // get the temp notification context, do not handle delayed insert
        Assert.AreEqual(0, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');

        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          SalesHeader.RecordId, AdditionalContextId, TempNotificationContext, true); // get the temp notification context, handle delayed insert
        Assert.AreEqual(1, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');
        Assert.AreEqual(UninitializedSalesHeaderRecId, TempNotificationContext."Record ID", 'Unexpected record ID');
        NotificationLifecycleMgt.GetNotificationsForRecordWithAdditionalContext(
          SalesHeader.RecordId, AdditionalContextId, TempNotificationContext, false); // get the temp notification context, do not handle delayed insert
        Assert.AreEqual(0, TempNotificationContext.Count,
          'Unexpected number of NotificationContext records');

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisabledStateResetOnOpenPageAndClosePage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        SalesInvoice: TestPage "Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        AssemblyOrder: TestPage "Assembly Order";
        AssemblyQuote: TestPage "Assembly Quote";
        ItemJournalLines: TestPage "Item Journal Lines";
    begin
        Initialize();

        LibraryLowerPermissions.SetO365BusFull();

        // [THEN] The Notification Licecycle Mgt framework is enabled, in case it was disabled and never enabled back (rare)
        // [WHEN] We close a page that allows for posting
        // [THEN] The Notification Licecycle Mgt framework is enabled,
        // in case the posting failed and the after posting subscriber was not called to enable the framework again.
        NotificationLifecycleMgt.DisableSubscribers();
        AssemblyOrder.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening assembly order.');
        NotificationLifecycleMgt.DisableSubscribers();
        AssemblyOrder.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing assembly order.');

        NotificationLifecycleMgt.DisableSubscribers();
        AssemblyQuote.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening assembly quote.');
        NotificationLifecycleMgt.DisableSubscribers();
        AssemblyQuote.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing assembly quote.');

        NotificationLifecycleMgt.DisableSubscribers();
        SalesQuote.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening sales quote.');
        NotificationLifecycleMgt.DisableSubscribers();
        SalesQuote.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing sales quote.');

        NotificationLifecycleMgt.DisableSubscribers();
        SalesOrder.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening sales order.');
        NotificationLifecycleMgt.DisableSubscribers();
        SalesOrder.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing sales order.');

        NotificationLifecycleMgt.DisableSubscribers();
        SalesInvoice.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening sales invoice.');
        NotificationLifecycleMgt.DisableSubscribers();
        SalesInvoice.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled closing sales invoice.');

        NotificationLifecycleMgt.DisableSubscribers();
        SalesCreditMemo.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening sales credit memo.');
        NotificationLifecycleMgt.DisableSubscribers();
        SalesCreditMemo.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing sales credit memo.');

        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseQuote.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening purchase quote.');
        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseQuote.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing purchase quote.');

        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseOrder.OpenView();
        PurchaseOrder.New(); // to make sure the confirm handler will not be called
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening purchase order.');
        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseOrder.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing purchase order.');

        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseInvoice.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening purchase invoice.');
        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseInvoice.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled closing purchase invoice.');

        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseCreditMemo.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening purchase credit memo.');
        NotificationLifecycleMgt.DisableSubscribers();
        PurchaseCreditMemo.Close();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after closing purchase credit memo.');

        NotificationLifecycleMgt.DisableSubscribers();
        ItemJournalLines.OpenView();
        Assert.IsFalse(NotificationLifecycleMgt.AreSubscribersDisabled(),
          'Notification Lifecycle Mgt should be enabled after opening item journal lines.');
        ItemJournalLines.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Notification Lifecycle Tests");

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var NotificationToRecall: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var NotificationToSend: Notification): Boolean
    begin
    end;
}

