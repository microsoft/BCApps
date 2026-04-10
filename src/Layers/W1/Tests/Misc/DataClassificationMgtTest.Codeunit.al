codeunit 135158 "Data Classification Mgt. Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Classification]
    end;

    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassificationMgtTest: Codeunit "Data Classification Mgt. Test";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestMasterTablesRegistration()
    var
        DataPrivacyEntities: Record "Data Privacy Entities" temporary;
    begin
        // [SCENARIO] NAV Developer can register a new Privacy Master Table by subscribing to an event

        // [GIVEN] NAV Developer has subscribed to event OnGetDataPrivacyEntities
        BindSubscription(DataClassificationMgtTest);

        // [WHEN] The OnGetDataPrivacyEntities is fired
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(DataPrivacyEntities);

        // [THEN] The returned Table contains the default Master Tables and those specified by the NAV Developer
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::Customer),
          'Customer table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::Vendor),
          'Vendor table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::Resource),
          'Resourse table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::Contact),
          'Contact table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::Employee),
          'Employee table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::"Salesperson/Purchaser"),
          'SalesPerson/Purchaser table should have been registered as Master Table');
        Assert.IsTrue(
          DataPrivacyEntities.Get(Database::User),
          'User table should have been registered as Master Table');
        // Added by the test
        Assert.IsTrue(
          DataPrivacyEntities.Get(DATABASE::"Payment Terms"),
          'Payment Terms table should have been registered as Master Table');

        UnbindSubscription(DataClassificationMgtTest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataPrivacyEntitiesExist()
    var
        TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
        RecordRef: RecordRef;
    begin
        // [GIVEN] The privacy master tables (Customer, Vendor, etc)
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);

        // [GIVEN] All the privacy master tables are empty
        if TempDataPrivacyEntities.FindSet() then;
        repeat
            RecordRef.Open(TempDataPrivacyEntities."Table No.");
            if (not RecordRef.IsEmpty()) and (TempDataPrivacyEntities."Table No." <> DATABASE::User) then
                RecordRef.DeleteAll();
            RecordRef.Close();
        until TempDataPrivacyEntities.Next() = 0;

        // [WHEN] Querying whether any data privacy entities exist
        // [THEN] The result should be false
        Assert.IsFalse(DataClassificationMgt.DataPrivacyEntitiesExist(), 'There should not exist any entities');

        if TempDataPrivacyEntities.FindFirst() then;
        // [GIVEN] One data privacy entity exists
        RecordRef.Open(TempDataPrivacyEntities."Table No.");
        RecordRef.Init();
        RecordRef.Insert();

        // [WHEN] Querying whether any data privacy entities exist
        // [THEN] The result should be true
        Assert.IsTrue(DataClassificationMgt.DataPrivacyEntitiesExist(), 'Exactly one entity should exist');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Mgt.", 'OnGetDataPrivacyEntities', '', false, false)]
    local procedure OnGetDataPrivacyEntitiesSubscriber(var DataPrivacyEntities: Record "Data Privacy Entities")
    begin
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, 3, 7, 1, '', 0);
    end;
}
