codeunit 139008 "My Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Notifications] [UT]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableExistingNotification()
    var
        MyNotifications: Record "My Notifications";
        ID: array[2] of Guid;
    begin
        // [SCENARIO] Disable() returns TRUE if the notification is found and disabled
        // [GIVEN] Two notifications are enabled
        MyNotifications.DeleteAll();
        ID[1] := CreateGuid();
        MyNotifications.InsertDefault(ID[1], '', '', true);
        ID[2] := CreateGuid();
        MyNotifications.InsertDefault(ID[2], '', '', true);

        // [WHEN] Disable Notification 2
        Assert.IsTrue(MyNotifications.Disable(ID[2]), 'Should get TRUE for existing notification 2');
        // [THEN] Disable() returns TRUE; Notification 2 should be disabled,
        Assert.IsFalse(MyNotifications.IsEnabled(ID[2]), 'Notification 2 should be disabled');
        // [THEN] Notification 1 should be still enabled
        Assert.IsTrue(MyNotifications.IsEnabled(ID[1]), 'Notification 1 should be enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableNotExistingNotification()
    var
        MyNotifications: Record "My Notifications";
        ID: array[2] of Guid;
    begin
        // [SCENARIO] Disable() returns FALSE if the notification is not found
        // [GIVEN] One notifications is enabled
        MyNotifications.DeleteAll();
        ID[1] := CreateGuid();
        MyNotifications.InsertDefault(ID[1], '', '', true);

        // [WHEN] try to Disable() not existing Notification 2
        ID[2] := CreateGuid();
        Assert.IsFalse(MyNotifications.Disable(ID[2]), 'Should get FALSE for not existing notification 2');
        // [THEN] Disable() returns FALSE
        // [THEN] Notification 1 should be still enabled
        Assert.IsTrue(MyNotifications.IsEnabled(ID[1]), 'Notification 1 should be enabled');
    end;

    [Test]
    procedure RunInsertDefault()
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NotificationName: Text[128];
        DescriptionText: Text;
        DefaultState: Boolean;
    begin
        // [SCENARIO 406142] Run InsertDefault function of My Notifications table when no record with given Notification Id exists.

        NotificationId := CreateGuid();
        NotificationName := LibraryUtility.GenerateGUID();
        DescriptionText := LibraryUtility.GenerateGUID();
        DefaultState := (LibraryRandom.RandIntInRange(0, 1) = 1);

        // [WHEN] Run InsertDefault function of My Notifications table with Notification Id "I", NotificationName "N", DescriptionText "D", DefaultState "S".
        MyNotifications.InsertDefault(NotificationId, NotificationName, DescriptionText, DefaultState);

        // [THEN] My Notifications record was inserted into the table with Notification Id "I", Name "N", Description "D", Enabled "S".
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NotificationName, DescriptionText, DefaultState, 0, '');
    end;

    [Test]
    procedure RunInsertDefaultSameNotificationIdAndName()
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NotificationName: Text[128];
        DescriptionText: Text;
        DefaultState: Boolean;
    begin
        // [SCENARIO 406142] Run InsertDefault function of My Notifications table when record with given Notification Id and Name exists.

        // [GIVEN] My Notifications record with Notification Id = "I", Name = "N", Description = "D1", Enabled = true.
        NotificationId := CreateGuid();
        NotificationName := LibraryUtility.GenerateGUID();
        DescriptionText := LibraryUtility.GenerateGUID();
        DefaultState := (LibraryRandom.RandIntInRange(0, 1) = 1);
        MyNotifications.InsertDefault(NotificationId, NotificationName, DescriptionText, DefaultState);

        // [WHEN] Run InsertDefault function of My Notifications table with the same Notification Id "I" and NotificationName "N", but with different DescriptionText "D2" and DefaultState false.
        MyNotifications.InsertDefault(NotificationId, NotificationName, LibraryUtility.GenerateGUID(), not DefaultState);

        // [THEN] My Notifications record was not changed.
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NotificationName, DescriptionText, DefaultState, 0, '');
    end;

    [Test]
    procedure RunInsertDefaultSameNotificationIdDifferentName()
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NewNotificationName: Text[128];
        NewDescriptionText: Text;
        DefaultState: Boolean;
    begin
        // [SCENARIO 406142] Run InsertDefault function of My Notifications table when record with given Notification Id but with different Name exists.

        // [GIVEN] My Notifications record with Notification Id "I", Name "N1", Description "D1", Enabled "true".
        NotificationId := CreateGuid();
        DefaultState := (LibraryRandom.RandIntInRange(0, 1) = 1);
        MyNotifications.InsertDefault(NotificationId, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), DefaultState);

        // [WHEN] Run InsertDefault function of My Notifications table with the same Notification Id "I", but different NotificationName "N2", DescriptionText "D2" and DefaultState "false".
        NewNotificationName := LibraryUtility.GenerateGUID();
        NewDescriptionText := LibraryUtility.GenerateGUID();
        MyNotifications.InsertDefault(NotificationId, NewNotificationName, NewDescriptionText, not DefaultState);

        // [THEN] Name and Description were changed, Enabled was not changed.
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NewNotificationName, NewDescriptionText, DefaultState, 0, '');
    end;

    [Test]
    procedure RunInsertDefaultWithTableNum()
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NotificationName: Text[128];
        DescriptionText: Text;
        ApplyToTableId: Integer;
    begin
        // [SCENARIO 406142] Run InsertDefaultWithTableNum function of My Notifications table when no record with given Notification Id exists.

        NotificationId := CreateGuid();
        NotificationName := LibraryUtility.GenerateGUID();
        DescriptionText := LibraryUtility.GenerateGUID();
        ApplyToTableId := Database::Customer;

        // [WHEN] Run InsertDefaultWithTableNum function of My Notifications table with Notification Id "I", NotificationName "N", DescriptionText "D", Apply to Table Id "T".
        MyNotifications.InsertDefaultWithTableNum(NotificationId, NotificationName, DescriptionText, ApplyToTableId);

        // [THEN] My Notifications record was inserted into the table with Notification Id "I", Name "N", Description "D", Enabled "true", Apply to Table Id "T".
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NotificationName, DescriptionText, true, ApplyToTableId, '');
    end;

    [Test]
    procedure RunInsertDefaultWithTableNumSameNotificationIdDifferentName()
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NewNotificationName: Text[128];
        NewDescriptionText: Text;
        ApplyToTableId: Integer;
    begin
        // [SCENARIO 406142] Run InsertDefaultWithTableNum function of My Notifications table when record with given Notification Id but with different Name exists.

        // [GIVEN] My Notifications record with Notification Id "I", Name "N1", Description "D1", Apply to Table Id "T1".
        NotificationId := CreateGuid();
        ApplyToTableId := Database::Customer;
        MyNotifications.InsertDefaultWithTableNum(NotificationId, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), ApplyToTableId);

        // [WHEN] Run InsertDefaultWithTableNum function of My Notifications table with the same Notification Id "I", but different NotificationName "N2", DescriptionText "D2" and Apply to Table Id "T2".
        NewNotificationName := LibraryUtility.GenerateGUID();
        NewDescriptionText := LibraryUtility.GenerateGUID();
        MyNotifications.InsertDefaultWithTableNum(NotificationId, NewNotificationName, NewDescriptionText, Database::Vendor);

        // [THEN] Name and Description were changed, Apply to Table Id was not changed.
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NewNotificationName, NewDescriptionText, true, ApplyToTableId, '');
    end;

    [Test]
    procedure RunInsertDefaultWithTableNumAndFilter()
    var
        MyNotifications: Record "My Notifications";
        Customer: Record Customer;
        NotificationId: Guid;
        NotificationName: Text[128];
        DescriptionText: Text;
        ApplyToTableFilter: Text;
        ApplyToTableId: Integer;
    begin
        // [SCENARIO 406142] Run InsertDefaultWithTableNumAndFilter function of My Notifications table when no record with given Notification Id exists.

        NotificationId := CreateGuid();
        NotificationName := LibraryUtility.GenerateGUID();
        DescriptionText := LibraryUtility.GenerateGUID();
        ApplyToTableId := Database::Customer;
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        Customer.SetRange(Name, LibraryUtility.GenerateGUID());
        ApplyToTableFilter := Customer.GetFilters();

        // [WHEN] Run InsertDefaultWithTableNumAndFilter function of My Notifications table with Notification Id "I", NotificationName "N", DescriptionText "D", Apply to Table Id "T", Apply To Table Filter "F".
        MyNotifications.InsertDefaultWithTableNumAndFilter(NotificationId, NotificationName, DescriptionText, ApplyToTableId, ApplyToTableFilter);

        // [THEN] My Notifications record was inserted into the table with Notification Id "I", Name "N", Description "D", Enabled "true", Apply to Table Id "T", Apply To Table Filter "F".
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NotificationName, DescriptionText, true, ApplyToTableId, MyNotifications.GetXmlFromTableView(ApplyToTableId, ApplyToTableFilter));
    end;

    [Test]
    procedure RunInsertDefaultWithTableNumAndFilterZeroTableIdSameNotificationIdDifferentName()
    var
        MyNotifications: Record "My Notifications";
        Vendor: Record Vendor;
        NotificationId: Guid;
        NewNotificationName: Text[128];
        NewDescriptionText: Text;
        NewApplyToTableFilter: Text;
        NewApplyToTableId: Integer;
    begin
        // [SCENARIO 406142] Run InsertDefaultWithTableNumAndFilter function of My Notifications table when record with given Notification Id but with different Name exists. Apply to Table Id = 0 for initial record.
        // [GIVEN] My Notifications record with Notification Id "I", Name "N1", Description "D1", Apply to Table Id = 0, Apply To Table Filter = ''.
        NotificationId := CreateGuid();
        MyNotifications.InsertDefaultWithTableNumAndFilter(NotificationId, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), 0, '');

        // [WHEN] Run InsertDefaultWithTableNumAndFilter function of My Notifications table with the same Notification Id "I", but different NotificationName "N2", DescriptionText "D2", Apply to Table Id "T2", Apply To Table Filter "F2".
        NewNotificationName := LibraryUtility.GenerateGUID();
        NewDescriptionText := LibraryUtility.GenerateGUID();
        NewApplyToTableId := Database::Vendor;
        Vendor.SetRange("No.", LibraryUtility.GenerateGUID());
        Vendor.SetRange(Name, LibraryUtility.GenerateGUID());
        NewApplyToTableFilter := Vendor.GetFilters();
        MyNotifications.InsertDefaultWithTableNumAndFilter(NotificationId, NewNotificationName, NewDescriptionText, NewApplyToTableId, NewApplyToTableFilter);

        // [THEN] Name, Description, Apply to Table Id and Apply To Table Filter were changed.
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NewNotificationName, NewDescriptionText, true, NewApplyToTableId, MyNotifications.GetXmlFromTableView(NewApplyToTableId, NewApplyToTableFilter));
    end;

    [Test]
    procedure RunInsertDefaultWithTableNumAndFilterNonZeroTableIdSameNotificationIdDifferentName()
    var
        MyNotifications: Record "My Notifications";
        Customer: Record Customer;
        Vendor: Record Vendor;
        NotificationId: Guid;
        NewNotificationName: Text[128];
        NewDescriptionText: Text;
        ApplyToTableFilter: Text;
        NewApplyToTableFilter: Text;
        ApplyToTableId: Integer;
    begin
        // [SCENARIO 406142] Run InsertDefaultWithTableNumAndFilter function of My Notifications table when record with given Notification Id but with different Name exists. Apply to Table Id <> 0 for initial record.

        // [GIVEN] My Notifications record with Notification Id "I", Name "N1", Description "D1", Apply to Table Id "T1", Apply To Table Filter "F1".
        NotificationId := CreateGuid();
        ApplyToTableId := Database::Customer;
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        Customer.SetRange(Name, LibraryUtility.GenerateGUID());
        ApplyToTableFilter := Customer.GetFilters();
        MyNotifications.InsertDefaultWithTableNumAndFilter(NotificationId, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), ApplyToTableId, ApplyToTableFilter);

        // [WHEN] Run InsertDefaultWithTableNumAndFilter function of My Notifications table with the same Notification Id "I", but different NotificationName "N2", DescriptionText "D2", Apply to Table Id "T2", Apply To Table Filter "F2".
        NewNotificationName := LibraryUtility.GenerateGUID();
        NewDescriptionText := LibraryUtility.GenerateGUID();
        Vendor.SetRange("No.", LibraryUtility.GenerateGUID());
        Vendor.SetRange(Name, LibraryUtility.GenerateGUID());
        NewApplyToTableFilter := Vendor.GetFilters();
        MyNotifications.InsertDefaultWithTableNumAndFilter(NotificationId, NewNotificationName, NewDescriptionText, Database::Vendor, NewApplyToTableFilter);

        // [THEN] Name and Description were changed. Apply to Table Id and Apply To Table Filter were not changed.
        MyNotifications.Get(UserId(), NotificationId);
        VerifyMyNotificationsRec(MyNotifications, NewNotificationName, NewDescriptionText, true, ApplyToTableId, MyNotifications.GetXmlFromTableView(ApplyToTableId, ApplyToTableFilter));
    end;

    local procedure VerifyMyNotificationsRec(MyNotifications: Record "My Notifications"; ExpectedName: Text[128]; ExpectedDescription: Text; ExpectedState: Boolean; ExpApplyToTableId: Integer; ExpApplyToTableFilter: Text)
    var
        ActualDescription: Text;
        ActualApplyToTableFilter: Text;
        InStream: InStream;
    begin
        MyNotifications.TestField(Name, ExpectedName);
        MyNotifications.TestField("Apply to Table Id", ExpApplyToTableId);
        MyNotifications.TestField(Enabled, ExpectedState);

        MyNotifications.CalcFields(Description);
        MyNotifications.Description.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(ActualDescription);
        Assert.AreEqual(ExpectedDescription, ActualDescription, '');

        MyNotifications.CalcFields("Apply to Table Filter");
        MyNotifications."Apply to Table Filter".CreateInStream(InStream);
        InStream.Read(ActualApplyToTableFilter);
        Assert.AreEqual(ExpApplyToTableFilter, ActualApplyToTableFilter, '');
    end;
}

