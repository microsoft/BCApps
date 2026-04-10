codeunit 135151 "Data Class. Notification Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Data Classification] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DataClassificationNotificationMsg: Label 'It looks like you are either doing business in the EU or you have EU vendors, customers, contacts, resources or employees. Have you classified your data? We can help you do that.';
        UnclassifiedFieldsNotificationMsg: Label 'Unclassified fields notification';
        SyncFieldsNotificationMsg: Label 'Sync fields notification';
        NumberOfEntriesOnClassificationWorksheetPage: Integer;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDataClassificationNotification()
    var
        DataSensitivity: Record "Data Sensitivity";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Contact: Record Contact;
        Resource: Record Resource;
        CountryRegion: Record "Country/Region";
        BusinessManagerRoleCenter: TestPage "Business Manager Role Center";
    begin
        // [SCENARIO] User gets notified about the Data Classification feature only if he has not classified
        // any data and he is not in Demo Company

        LibraryLowerPermissions.SetO365BusFull();
        Clear(LibraryVariableStorage);
        DataSensitivity.DeleteAll();

        // [GIVEN] The company is not an EU company
        // [GIVEN] The company is a demo company
        SetCompanyToDemo(true);
        SetCompanyInEU(false);

        // [GIVEN] There is a Customer in EU
        CountryRegion.Code := 'MYCODE';
        CountryRegion."EU Country/Region Code" := 'MYCODE';
        CountryRegion.Insert();

        LibrarySales.CreateCustomer(Customer);
        Customer."Partner Type" := Customer."Partner Type"::Person;
        Customer."Country/Region Code" := 'MYCODE';
        Customer.Modify();

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] No Data Classification Notification is shown
        LibraryVariableStorage.AssertEmpty();

        BusinessManagerRoleCenter.Close();

        // [GIVEN] The company is not a demo nor an EU company, but they have a customer in the EU
        SetCompanyToDemo(false);

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] The data classification notification is sent
        Assert.ExpectedMessage(DataClassificationNotificationMsg, LibraryVariableStorage.DequeueText());

        BusinessManagerRoleCenter.Close();

        // [GIVEN] The company is an EU company
        SetCompanyInEU(true);

        // [GIVEN] User has not classified any fields
        DataSensitivity.DeleteAll();

        // [GIVEN] There are no Data Privacy Entities
        Customer.DeleteAll();
        Vendor.DeleteAll();
        Contact.DeleteAll();
        SalespersonPurchaser.DeleteAll();
        Employee.DeleteAll();
        Resource.DeleteAll();

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] No Data Classification Notification is shown
        LibraryVariableStorage.AssertEmpty();

        BusinessManagerRoleCenter.Close();

        // [GIVEN] User has not classified any fields
        DataSensitivity.DeleteAll();

        // [GIVEN] At least one entity exists
        Customer."No." := '1';
        Customer.Name := 'Customer1';
        Customer.Insert();

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] The data classification notification is sent
        Assert.ExpectedMessage(DataClassificationNotificationMsg, LibraryVariableStorage.DequeueText());

        BusinessManagerRoleCenter.Close();
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestUnclassifiedNotification()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        BusinessManagerRoleCenter: TestPage "Business Manager Role Center";
    begin
        // [SCENARIO] User gets notified to sync the fields again after 30 days since last sync
        Clear(LibraryVariableStorage);
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] The company is not an EU company
        // [GIVEN] The company is not a demo company
        SetCompanyToDemo(false);
        SetCompanyInEU(false);

        // [GIVEN] User has unclassified fields
        DataSensitivity.DeleteAll();
        DataClassificationMgt.InsertDataSensitivityForField(3, 1, DataSensitivity."Data Sensitivity"::Unclassified);

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] The Unclassified fields notification shows
        Assert.ExpectedMessage(UnclassifiedFieldsNotificationMsg, LibraryVariableStorage.DequeueText());

        BusinessManagerRoleCenter.Close();
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSyncFieldsNotification()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        LibraryDataClassification: Codeunit "Library - Data Classification";
        BusinessManagerRoleCenter: TestPage "Business Manager Role Center";
        LastFieldsSyncStatusDate: DateTime;
    begin
        // [SCENARIO] User gets notified that are unclassified field
        Clear(LibraryVariableStorage);
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] The company is not an EU company
        // [GIVEN] The company is not a demo company
        SetCompanyToDemo(false);
        SetCompanyInEU(false);

        // [GIVEN] User has classified some fields
        DataSensitivity.DeleteAll();
        DataClassificationMgt.InsertDataSensitivityForField(3, 1, DataSensitivity."Data Sensitivity"::Personal);

        // [GIVEN] 30 days have pass since last sync
        LastFieldsSyncStatusDate := CreateDateTime(CalcDate('<-31D>', Today), Time);
        LibraryDataClassification.ModifyLastFieldsSyncStatusDate(LastFieldsSyncStatusDate);

        // [WHEN] Busines Manager Role Center Opens
        BusinessManagerRoleCenter.OpenView();

        // [THEN] The Sync fields notification shows
        Assert.ExpectedMessage(SyncFieldsNotificationMsg, LibraryVariableStorage.DequeueText());

        BusinessManagerRoleCenter.Close();
    end;

    [Test]
    [HandlerFunctions('DataClassWizardHandler,DataClassWorksheetHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyNotificationActionsExist()
    var
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        DummyNotification: Notification;
    begin
        // [SCENARIO] Notification actions exist
        LibraryLowerPermissions.SetO365BusFull();

        DataClassNotificationMgt.DisableNotifications(DummyNotification);
        DataClassNotificationMgt.OpenClassificationWorksheetPage(DummyNotification);
        DataClassNotificationMgt.OpenDataClassificationWizard(DummyNotification);
        DataClassNotificationMgt.SyncAllFieldsFromNotification(DummyNotification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    var
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
    begin
        LibraryLowerPermissions.SetO365BusFull();

        case Notification.Id of
            DataClassNotificationMgt.GetDataClassificationNotificationId():
                LibraryVariableStorage.Enqueue(DataClassificationNotificationMsg);
            DataClassNotificationMgt.GetSyncFieldsNotificationId():
                LibraryVariableStorage.Enqueue(SyncFieldsNotificationMsg);
            DataClassNotificationMgt.GetUnclassifiedFieldsNotificationId():
                LibraryVariableStorage.Enqueue(UnclassifiedFieldsNotificationMsg);
        end;
    end;

    [Test]
    [HandlerFunctions('OpenClassificationWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure TestOpenClassificationWorksheetPage()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DummyNotification: Notification;
    begin
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Three entries in the Data Sensitivity table - one classified and two unclassified
        DataSensitivity.DeleteAll();
        DataClassificationMgt.InsertDataSensitivityForField(27, 4, DataSensitivity."Data Sensitivity"::Unclassified);
        DataClassificationMgt.InsertDataSensitivityForField(18, 3, DataSensitivity."Data Sensitivity"::"Company Confidential");
        DataClassificationMgt.InsertDataSensitivityForField(25, 5, DataSensitivity."Data Sensitivity"::Unclassified);

        // [WHEN] Opening the Data Classification Worksheet page
        DataClassNotificationMgt.OpenClassificationWorksheetPage(DummyNotification);

        // [THEN] The page should only list the unclassified entries

        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        Assert.AreEqual(DataSensitivity.Count, NumberOfEntriesOnClassificationWorksheetPage,
          'The Number of entries on the Data Classification Worksheet page is incorrect');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DataClassWizardHandler(var DataClassificationWizard: Page "Data Classification Wizard")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DataClassWorksheetHandler(var DataClassificationWorksheet: Page "Data Classification Worksheet")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OpenClassificationWorksheetPageHandler(var DataClassificationWorksheet: TestPage "Data Classification Worksheet")
    begin
        if DataClassificationWorksheet.First() then
            repeat
                NumberOfEntriesOnClassificationWorksheetPage += 1;
            until not DataClassificationWorksheet.Next();
    end;

    local procedure SetCompanyToDemo(SetToDemo: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := SetToDemo;
        CompanyInformation.Modify();
    end;

    local procedure SetCompanyInEU(IsEU: Boolean)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        if not IsEU then
            CompanyInformation."Country/Region Code" := 'NotEUCode'
        else begin
            CountryRegion.Init();
            CountryRegion.Code := 'EUCode';
            CountryRegion."EU Country/Region Code" := 'EUCode';
            CountryRegion.Insert();
            CompanyInformation."Country/Region Code" := 'EUCode';
        end;

        CompanyInformation.Modify();
    end;
}

