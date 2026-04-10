codeunit 139844 "Cost Adj. Sch. Notif. Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;
    SingleInstance = true;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NotificationSent: Boolean;
        ScheduleNotificationTxt: Label 'If you turn off automatic cost adjustments or posting, you must do those tasks manually or schedule a job queue entry to run in the background.';

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure ShouldShowNotificationWhenAutomaticCostPostingIsDisabled()
    var
        InventorySetup: TestPage "Inventory Setup";
        CostAdjSchNotifTests: Codeunit "Cost Adj. Sch. Notif. Tests";
    begin
        // [GIVEN] Automatic Cost Posting initially set to true.
        Initialize(true);
        NotificationSent := false;
        BindSubscription(CostAdjSchNotifTests);

        // [WHEN] Setting Automatic Cost Posting to false.
        InventorySetup.OpenEdit();
        InventorySetup."Automatic Cost Posting".SetValue(false);
        InventorySetup.Close();

        // [THEN] A notification is sent.
        Assert.AreEqual(ScheduleNotificationTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification message.');
        Assert.IsTrue(NotificationSent, 'Expected notification sent event to be triggered.');

        UnbindSubscription(CostAdjSchNotifTests);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure ShouldShowNotificationWhenAutomaticCostdjustmentIsDisabled()
    var
        InventorySetup: TestPage "Inventory Setup";
        CostAdjSchNotifTests: Codeunit "Cost Adj. Sch. Notif. Tests";
    begin
        // [GIVEN] Automatic Cost Adjustment initially to 'Always'.
        Initialize(true);
        NotificationSent := false;
        BindSubscription(CostAdjSchNotifTests);

        // [WHEN] Setting Automatic Cost Adjustment to 'Never'.
        InventorySetup.OpenEdit();
        InventorySetup."Automatic Cost Adjustment".SetValue('Never');
        InventorySetup.Close();

        // [THEN] A notification is sent.
        Assert.AreEqual(ScheduleNotificationTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification message.');
        Assert.IsTrue(NotificationSent, 'Expected notification sent event to be triggered.');

        UnbindSubscription(CostAdjSchNotifTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldNotShowNotificationWhenAutomaticCostPostingIsEnabled()
    var
        InventorySetup: TestPage "Inventory Setup";
        CostAdjSchNotifTests: Codeunit "Cost Adj. Sch. Notif. Tests";
    begin
        // [GIVEN] Automatic Cost Posting initially set to false.
        Initialize(false);
        NotificationSent := false;
        BindSubscription(CostAdjSchNotifTests);

        // [WHEN] Setting Automatic Cost Posting to true.
        InventorySetup.OpenEdit();
        InventorySetup."Automatic Cost Posting".SetValue(true);
        InventorySetup.Close();

        // [THEN] No notification is sent.
        Assert.IsFalse(NotificationSent, 'Did not expect an notification sent event to be triggered.');

        UnbindSubscription(CostAdjSchNotifTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldNotShowNotificationWhenAutomaticCostAdjustmentIsEnabled()
    var
        InventorySetup: TestPage "Inventory Setup";
        CostAdjSchNotifTests: Codeunit "Cost Adj. Sch. Notif. Tests";
    begin
        // [GIVEN] Automatic Cost Adjustment initially set to 'Never'.
        Initialize(false);
        NotificationSent := false;
        BindSubscription(CostAdjSchNotifTests);

        // [WHEN] Setting Automatic Cost Adjustment to 'Always'.
        InventorySetup.OpenEdit();
        InventorySetup."Automatic Cost Adjustment".SetValue('Always');
        InventorySetup.Close();

        // [THEN] No notification is sent.
        Assert.IsFalse(NotificationSent, 'Did not expect an notification sent event to be triggered.');

        UnbindSubscription(CostAdjSchNotifTests);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adj. Scheduling Notifier", 'OnNotificationSent', '', false, false)]
    local procedure SubscribeToNotificationSent()
    begin
        NotificationSent := true;
    end;

    local procedure Initialize(EnableAutomaticCost: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
        JobQueueEntry: Record "Job Queue Entry";
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        if not InventorySetup.Get() then begin
            InventorySetup.Init();
            InventorySetup.Insert();
        end;

        InventorySetup.Get();
        if EnableAutomaticCost then begin
            InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
            InventorySetup."Automatic Cost Posting" := true;
        end else begin
            InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
            InventorySetup."Automatic Cost Posting" := false;
        end;
        InventorySetup.Modify();

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        JobQueueEntry.DeleteAll();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Post Inventory Cost to G/L");
        JobQueueEntry.DeleteAll();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        JobQueueEntry.DeleteAll();

        Item.SetRange("Allow Online Adjustment", false);
        if Item.FindSet() then
            repeat
                Item."Allow Online Adjustment" := true;
                Item.Modify();
            until Item.Next() = 0;

        InvtAdjmtEntryOrder.SetRange("Allow Online Adjustment", false);
        if InvtAdjmtEntryOrder.FindSet() then
            repeat
                InvtAdjmtEntryOrder."Allow Online Adjustment" := true;
                InvtAdjmtEntryOrder.Modify();
            until InvtAdjmtEntryOrder.Next() = 0;
    end;
}