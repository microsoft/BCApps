codeunit 135024 "Data Migration Notifier Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        ListEmptyMsg: Label 'There isn''t data here yet. Want to import', Locked = true;
        ListEmptyNotificationSent: Boolean;

    [Test]
    [HandlerFunctions('ListEmptySendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemListNotificationShownWhenNoItemsAndNoGLEntries()
    var
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 13275] The "list is empty" notification is shown on an unused company without items
        Initialize();

        // [GIVEN] No items and no G/L entries exist
        DeleteItemsAndGLEntries();

        // [WHEN] Open the Item List
        ItemList.OpenView();
        ItemList.Close();

        // [THEN] The notification is sent
        Assert.IsTrue(ListEmptyNotificationSent, 'The list empty notification should be sent.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemListNotificationNotShownWhenGLEntriesExist()
    var
        GLEntry: Record "G/L Entry";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 13275] The notification is not shown in a company that is in use (posted G/L entries exist), even if there are no items
        Initialize();

        // [GIVEN] No items, but a G/L entry exists
        DeleteItemsAndGLEntries();
        GLEntry.Init();
        GLEntry."Entry No." := 1;
        GLEntry.Insert();

        // [WHEN] Open the Item List
        ItemList.OpenView();
        ItemList.Close();

        // [THEN] No notification is sent (an unexpected notification would fail the test as no handler is defined)
        Assert.IsFalse(ListEmptyNotificationSent, 'The list empty notification should not be sent.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemListNotificationNotShownWhenItemsExist()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 13275] The notification is not shown when the table contains records
        Initialize();

        // [GIVEN] No G/L entries, but an item exists
        DeleteItemsAndGLEntries();
        Item.Init();
        Item."No." := 'NOTIF13275';
        Item.Insert();

        // [WHEN] Open the Item List
        ItemList.OpenView();
        ItemList.Close();

        // [THEN] No notification is sent
        Assert.IsFalse(ListEmptyNotificationSent, 'The list empty notification should not be sent.');
    end;

    local procedure Initialize()
    var
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
    begin
        ListEmptyNotificationSent := false;
        DataMigrationMgt.InsertDefaultItemListEmptyNotification(true);
    end;

    local procedure DeleteItemsAndGLEntries()
    var
        Item: Record Item;
        GLEntry: Record "G/L Entry";
    begin
        Item.DeleteAll();
        GLEntry.DeleteAll();
    end;

    [SendNotificationHandler]
    procedure ListEmptySendNotificationHandler(var Notification: Notification): Boolean
    begin
        if StrPos(Notification.Message, ListEmptyMsg) = 1 then
            ListEmptyNotificationSent := true;
        exit(true);
    end;
}
