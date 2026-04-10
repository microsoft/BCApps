codeunit 136212 "Marketing Contacts Search II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Duplicate Contact] [Marketing]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        OriginalContactNo: Code[20];
        DuplicateContactNo: Code[20];
        ContactCompany: Label 'Contact Company';
        ContactPerson: Label 'Contact Person';
        ContactNotExistError: Label '%1 must not exists in %2.';
        ContactExistError: Label '%1 must exists in %2.';
        MarketingDuplicateSetupErr: Label 'Marketing duplicate search setup is incorrect.';
        WrongFieldSelectedErr: Label 'Wrong Field Selected.';
        ContactDuplicateDetailsErr: Label 'Wrong contact duplicate details.';
        EmptySetupErr: Label 'The Duplicate Search String Setup table is empty.';

    local procedure Initialize()
    var
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Contacts Search II");
        // Clear Global Variables.
        Clear(OriginalContactNo);
        Clear(DuplicateContactNo);

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Contacts Search II");

        LibraryService.SetupServiceMgtNoSeries();

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Contacts Search II");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContactDuplicatesPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyContactDuplicatesTrue()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check that Company Contacts with Similar Name will be listed in Contact Duplicate Page when Autosearch for Duplicate = TRUE.

        // 1. Setup: Update Marketing Setup, Create a new Contact of company type. Take 10 as Hit percent to match only one field's
        // value while searching duplicate. Value important for test. Assign Contact Nos. to global variables.
        Initialize();
        MarketingSetup.Get();
        UpdateMarketingSetup(true, 10);
        DuplicateContactNo := CreateContactCard(Contact.Type::Company, ContactCompany);

        // 2. Exercise: Create another Contact of Company Type with Same Name.
        OriginalContactNo := CreateContactCard(Contact.Type::Company, ContactCompany);

        // 3. Verify: Verify that duplicate Contact of company type is listed in Contact Duplicates Page.
        // Verification done in ContactDuplicatesPageHandler.

        // 4. Tear Down: Rollback setup done.
        UpdateMarketingSetup(MarketingSetup."Autosearch for Duplicates", MarketingSetup."Search Hit %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyContactDuplicatesFalse()
    var
        Contact: Record Contact;
        ContactDuplicate: Record "Contact Duplicate";
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check that Company Contacts with Similar Name will be listed in Contact Duplicate table when Autosearch for Duplicate = FALSE.

        // 1. Setup: Update Marketing Setup, Create a new Contact of company type. Take 10 as Hit percent to match only one field's
        // value while searching duplicate. Value important for test. Assign Duplicate Contact No. to global variable.
        Initialize();
        MarketingSetup.Get();
        UpdateMarketingSetup(false, 10);
        DuplicateContactNo := CreateContactCard(Contact.Type::Company, ContactCompany);

        // 2. Exercise: Create another Contact of Company Type with Same Name.
        CreateContactCard(Contact.Type::Company, ContactCompany);

        // 3. Verify: Verify that duplicate Contact of company type is listed in Contact Duplicates Table however no page opened.
        ContactDuplicate.SetRange("Duplicate Contact No.", DuplicateContactNo);
        Assert.IsTrue(
          ContactDuplicate.FindFirst(),
          StrSubstNo(ContactExistError, ContactDuplicate."Duplicate Contact No.", ContactDuplicate.TableCaption()));

        // 4. Tear Down: Rollback setup done.
        UpdateMarketingSetup(MarketingSetup."Autosearch for Duplicates", MarketingSetup."Search Hit %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonContactDuplicatesTrue()
    var
        Contact: Record Contact;
    begin
        // Check that Person Contacts with Similar Name are not searched for duplicate contacts.

        // Take 10 as Hit percent to match only one field's value while searching duplicate. Value important for test.
        DuplicateContacts(Contact.Type::Person, 10, ContactPerson);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleDuplicatesOnContact()
    var
        Contact: Record Contact;
    begin
        // Check that Company Contacts with Similar Name are not present in Contact Duplicate Page when search hit percent is 90.

        // Take 90 as Hit percent to match atleast Nine field values while searching duplicate. Value important for test.
        DuplicateContacts(Contact.Type::Company, 90, ContactCompany);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,GenerateDuplSearchStringReportHandler')]
    [Scope('OnPrem')]
    procedure MaintainDuplicateSearchStrings()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 180153] User enables "Maintain Dupl. Search Strings" in Marketing Setup
        Initialize();

        // [GIVEN] Marketing Setup with disabled duplicate search setup
        UpdateMarketingDuplicateSearchSetup(false, false);
        Commit();
        // [WHEN] User sets "Maintain Dupl. Search Strings" = TRUE
        MarketingSetup.Get();
        MarketingSetup.Validate("Maintain Dupl. Search Strings", true);
        // [THEN] Confirmation dialog to run report "Generate Dupl. Search String"
        // [THEN] Report "Generate Dupl. Search String" run (GenerateDuplSearchStringReportHandler)
        // [THEN] "Autosearch for Duplicates" = TRUE
        Assert.IsTrue(MarketingSetup."Autosearch for Duplicates", MarketingDuplicateSetupErr);
        // [THEN] "Maintain Dupl. Search Strings" = TRUE
        Assert.IsTrue(MarketingSetup."Maintain Dupl. Search Strings", MarketingDuplicateSetupErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,GenerateDuplSearchStringReportHandler')]
    [Scope('OnPrem')]
    procedure AutosearchAndMaintainDuplicates()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 180153] User enables "Autosearch for Duplicates" in Marketing Setup
        Initialize();

        // [GIVEN] Marketing Setup with disabled duplicate search setup
        UpdateMarketingDuplicateSearchSetup(false, false);
        Commit();
        // [WHEN] User sets "Autosearch for Duplicates" = TRUE
        MarketingSetup.Get();
        MarketingSetup.Validate("Autosearch for Duplicates", true);
        // [THEN] Confirmation dialog to run report "Generate Dupl. Search String"
        // [THEN] Report "Generate Dupl. Search String" run (GenerateDuplSearchStringReportHandler)
        // [THEN] "Maintain Dupl. Search Strings" = TRUE
        Assert.IsTrue(MarketingSetup."Maintain Dupl. Search Strings", MarketingDuplicateSetupErr);
        // [THEN] "Autosearch for Duplicates" = TRUE
        Assert.IsTrue(MarketingSetup."Autosearch for Duplicates", MarketingDuplicateSetupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutosearchDuplicates()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 180153] User enables "Autosearch for Duplicates" in Marketing Setup. "Maintain Dupl. Search Strings" already enabled.
        Initialize();

        // [GIVEN] Marketing Setup with enabled "Maintain Dupl. Search Strings"
        UpdateMarketingDuplicateSearchSetup(true, false);
        Commit();
        // [WHEN] User sets "Autosearch for Duplicates" = TRUE
        MarketingSetup.Get();
        MarketingSetup.Validate("Autosearch for Duplicates", true);
        // [THEN] No confirmation dialog
        // [THEN] No report run
        // [THEN] "Maintain Dupl. Search Strings" = TRUE
        Assert.IsTrue(MarketingSetup."Maintain Dupl. Search Strings", MarketingDuplicateSetupErr);
        // [THEN] "Autosearch for Duplicates" = TRUE
        Assert.IsTrue(MarketingSetup."Maintain Dupl. Search Strings", MarketingDuplicateSetupErr);
    end;

    [Test]
    [HandlerFunctions('FieldListPageHandler')]
    [Scope('OnPrem')]
    procedure DuplicateSearchStringSetupFieldNameLookup()
    var
        Contact: Record Contact;
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
        DuplicateSearchStringSetupPage: TestPage "Duplicate Search String Setup";
    begin
        // [SCENARIO] User selects field from the "Field List" page for "Duplicate Search String Setup"
        Initialize();

        // [GIVEN] Duplicate Search String Setup
        DuplicateSearchStringSetup.DeleteAll();
        // [WHEN] Run "Duplicate Search String Setup" page
        DuplicateSearchStringSetupPage.OpenNew();
        // [WHEN] Look up via assist edit in the "Field Name" field and select any from suggested (FieldListPageHandler)
        DuplicateSearchStringSetupPage."Field Name".AssistEdit();
        DuplicateSearchStringSetupPage.Close();
        // [THEN] Duplicate Search String created with selected field
        DuplicateSearchStringSetup.FindFirst();
        Assert.AreEqual(Contact.FieldName("No."), DuplicateSearchStringSetup."Field Name", WrongFieldSelectedErr);
    end;

    [Test]
    [HandlerFunctions('GenerateDuplSearchStringReportHandler')]
    [Scope('OnPrem')]
    procedure DuplcatesSearchFromContactDuplicatesPage()
    var
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        // [SCENARIO] Open Contact Duplicates page and click "Generate Duplicate Search String" action
        Initialize();

        // [GIVEN] "Contact Duplicates" page
        ContactDuplicates.OpenEdit();
        Commit();
        // [WHEN] Click "Generate Duplicate Search String" action
        ContactDuplicates.GenerateDuplicateSearchString.Invoke();
        // [THEN] Report "Generate Dupl. Search String" run (GenerateDuplSearchStringReportHandler)
    end;

    [Test]
    [HandlerFunctions('ContactDuplicateDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure ContactDuplicateDetails()
    var
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        // [SCENARIO] Open Contact Duplicates page and click "Contact Duplicate Details" action
        Initialize();

        // [GIVEN] Field "Name" of the Contact table is set up for duplication search
        // [GIVEN] Two Contacts: C1 and C2, C1.Name = X, C2.Name = Y
        MockDuplicateContactsAndSetup();
        // [GIVEN] "Contact Duplicates" page with duplicate contacts C1 and C2
        ContactDuplicates.OpenView();
        // [WHEN] Click "Contact Duplicate Details" action
        ContactDuplicates.ContactDuplicateDetails.Invoke();
        // [THEN] Page "Contact Duplicate Details" shows one line
        // [THEN] "Field Name" = "Name", "Field Value" = X, "Duplicate Field Value" = Y
    end;

    [Test]
    [HandlerFunctions('ContactDuplicateDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure ContactDuplicateDetailsWithoutSetup()
    var
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        // [SCENARIO] Open Contact Duplicates page and click "Contact Duplicate Details" action, "Duplicate Search String Setup" is empty.
        Initialize();

        // [GIVEN] Field "Name" of the Contact table is set up for duplication search
        // [GIVEN] Two Contacts: C1 and C2, C1.Name = X, C2.Name = Y
        MockDuplicateContactsAndSetup();
        // [GIVEN] "Contact Duplicates" page with duplicate contacts C1 and C2
        ContactDuplicates.OpenView();
        // [GIVEN] Empty "Duplicate Search String Setup" table
        DuplicateSearchStringSetup.DeleteAll();
        // [WHEN] Click "Contact Duplicate Details" action
        asserterror ContactDuplicates.ContactDuplicateDetails.Invoke();
        // [THEN] "Contact Duplicate Details" page failed to open with error message
        Assert.ExpectedError(EmptySetupErr);
    end;

    local procedure DuplicateContacts(Type: Enum "Contact Type"; SearchHitPct: Integer; ContactName: Text[50])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // 1. Setup: Update Marketing Setup, Create a new Contact. Assign Duplicate Contact No. to global variable.
        Initialize();
        MarketingSetup.Get();
        UpdateMarketingSetup(true, SearchHitPct);
        DuplicateContactNo := CreateContactCard(Type, ContactName);

        // 2. Exercise: Create another Contact with same name.
        CreateContactCard(Type, ContactName);

        // 3. Verify: Verify that duplicate Contact is not listed in Contact Duplicates Table.
        VerifyNoContactExists(DuplicateContactNo);

        // 4. Tear Down: Rollback setup done.
        UpdateMarketingSetup(MarketingSetup."Autosearch for Duplicates", MarketingSetup."Search Hit %");
    end;

    local procedure CreateContactCard(Type: Enum "Contact Type"; Name: Text[50]) ContactNo: Code[20]
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenNew();
        ContactCard.Type.Activate();
        ContactCard.Type.SetValue(Type);
        ContactCard.Name.SetValue(Name);
        ContactNo := ContactCard."No.".Value();
        ContactCard.OK().Invoke();
    end;

    local procedure UpdateMarketingSetup(AutosearchForDuplicates: Boolean; SearchHitPct: Integer)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Autosearch for Duplicates", AutosearchForDuplicates);
        MarketingSetup.Validate("Search Hit %", SearchHitPct);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateMarketingDuplicateSearchSetup(MaintainDuplicateSearch: Boolean; AutosearchDuplicates: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup."Maintain Dupl. Search Strings" := MaintainDuplicateSearch;
        MarketingSetup."Autosearch for Duplicates" := AutosearchDuplicates;
        MarketingSetup.Modify();
    end;

    local procedure MockDuplicateContactsAndSetup()
    var
        Contact: Record Contact;
        DuplicateContact: Record Contact;
        ContactDuplicate: Record "Contact Duplicate";
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
    begin
        UpdateMarketingDuplicateSearchSetup(false, false);

        DuplicateSearchStringSetup.DeleteAll();
        DuplicateSearchStringSetup.Init();
        DuplicateSearchStringSetup.Validate("Field No.", Contact.FieldNo(Name));
        DuplicateSearchStringSetup.Insert();
        LibraryVariableStorage.Enqueue(DuplicateSearchStringSetup."Field Name");

        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(Contact.Name);
        LibraryMarketing.CreateCompanyContact(DuplicateContact);
        LibraryVariableStorage.Enqueue(DuplicateContact.Name);

        ContactDuplicate.DeleteAll();
        ContactDuplicate.Init();
        ContactDuplicate."Contact No." := Contact."No.";
        ContactDuplicate."Duplicate Contact No." := DuplicateContact."No.";
        ContactDuplicate.Insert();
    end;

    local procedure VerifyNoContactExists(ContactNo: Code[20])
    var
        ContactDuplicate: Record "Contact Duplicate";
    begin
        ContactDuplicate.SetRange("Duplicate Contact No.", ContactNo);
        Assert.IsFalse(
          ContactDuplicate.FindFirst(),
          StrSubstNo(ContactNotExistError, ContactDuplicate."Duplicate Contact No.", ContactDuplicate.TableCaption()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactDuplicatesPageHandler(var ContactDuplicates: TestPage "Contact Duplicates")
    begin
        ContactDuplicates."Contact No.".AssertEquals(OriginalContactNo);
        ContactDuplicates."Duplicate Contact No.".AssertEquals(DuplicateContactNo);
        ContactDuplicates.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GenerateDuplSearchStringReportHandler(var GenerateDuplSearchString: TestRequestPage "Generate Dupl. Search String")
    begin
        GenerateDuplSearchString.Cancel().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ContactDuplicateDetailsPageHandler(var ContactDuplicateDetails: TestPage "Contact Duplicate Details")
    var
        FieldValue: Variant;
    begin
        ContactDuplicateDetails.First();
        LibraryVariableStorage.Dequeue(FieldValue);
        Assert.AreEqual(FieldValue, ContactDuplicateDetails."Field Name".Value, ContactDuplicateDetailsErr);
        LibraryVariableStorage.Dequeue(FieldValue);
        Assert.AreEqual(FieldValue, ContactDuplicateDetails."Field Value".Value, ContactDuplicateDetailsErr);
        LibraryVariableStorage.Dequeue(FieldValue);
        Assert.AreEqual(FieldValue, ContactDuplicateDetails."Duplicate Field Value".Value, ContactDuplicateDetailsErr);
        Assert.IsFalse(ContactDuplicateDetails.Next(), ContactDuplicateDetailsErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldListPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    begin
        // Select first field from the Contact table
        FieldsLookup.First();
        FieldsLookup.OK().Invoke();
    end;
}

