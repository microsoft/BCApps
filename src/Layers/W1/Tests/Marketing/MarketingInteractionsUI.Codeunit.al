codeunit 136215 "Marketing Interactions UI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Interaction] [Marketing]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        CorrTypeNoAtachmentErr: Label 'The correspondence type for this interaction is Email, which requires an interaction template with an attachment or Word template. To continue, you can either change the correspondence type for the contact, select an interaction template that has a different correspondence type, or select a template that ignores the contact correspondence type.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateOpportunityActionEnabledInInteractionLogList()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntriesPage: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [Opportunity] [UI]
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        // [GIVEN] The Interaction Log Entry "A", where "Opportunity No." is <blank>
        InteractionLogEntry."Entry No." += 1;
        InteractionLogEntry.Canceled := false;
        InteractionLogEntry.Insert();
        // [GIVEN] The Interaction Log Entry "B", where "Opportunity No." is <blank>, Status is Cancelled
        InteractionLogEntry."Entry No." += 1;
        InteractionLogEntry.Canceled := true;
        InteractionLogEntry.Insert();
        // [GIVEN] The Interaction Log Entry "C", where "Opportunity No." is "X"
        InteractionLogEntry."Entry No." += 1;
        InteractionLogEntry.Canceled := false;
        InteractionLogEntry."Opportunity No." := 'X';
        InteractionLogEntry.Insert();

        // [WHEN] Open "Interaction Log Entries" page
        InteractionLogEntriesPage.OpenView();

        // [THEN] Action "Create Opportunity" is enabled for "A", disabled for "B" and "C"
        InteractionLogEntriesPage.First();
        Assert.IsTrue(
          InteractionLogEntriesPage.CreateOpportunity.Enabled(),
          'Should be enabled for blank Opportunity No.');
        InteractionLogEntriesPage.Next();
        Assert.IsFalse(
          InteractionLogEntriesPage.CreateOpportunity.Enabled(),
          'Should be disabled for cancelled entry');
        InteractionLogEntriesPage.Next();
        Assert.IsFalse(
          InteractionLogEntriesPage.CreateOpportunity.Enabled(),
          'Should be disabled for filled Opportunity No.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateOpportunityForInteractionLogEntry()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntriesPage: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [Opportunity] [UI]
        Initialize();
        // [GIVEN] Contact
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] Interaction Log Entry, where "Opportunity No." is <blank>
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
        InteractionLogEntry.Insert();
        InteractionLogEntriesPage.OpenView();
        // [WHEN] Create opportunity for the entry
        InteractionLogEntriesPage.CreateOpportunity.Invoke();

        // [THEN] Interaction Log Entry, where "Opportunity No." is defined
        InteractionLogEntry.Find();
        InteractionLogEntry.TestField("Opportunity No.");
        // [THEN] New opportunity is created
        VerifyOpportunity(Contact, InteractionLogEntry."Opportunity No.");
    end;

    [Test]
    [HandlerFunctions('ModalHandlerGetContactNameFromCreateInteraction')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionContactCanBeDefinedByName()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [Create Interaction] [Contact] [UI]
        // [GIVEN] Person Contact "A", where Name is 'Adam';
        CreateCompanyWithContact(CompanyContact[1], PersonContact[1]);
        // [GIVEN] Person Contact "B", where Name is 'Bob'
        CreateCompanyWithContact(CompanyContact[2], PersonContact[2]);
        // [GIVEN] Run "Create Interaction" for Salesperson
        SalespersonPurchaser.Get(CompanyContact[2]."Salesperson Code");

        // [WHEN] Enter "Contact" as 'bob'
        LibraryVariableStorage.Enqueue(LowerCase(PersonContact[1].Name));
        SalespersonPurchaser.CreateInteraction();
        // handled by ModalHandlerGetContactNameFromCreateInteraction

        // [THEN] "Contact" becomes 'Bob', as Contact "B" is found
        Assert.AreEqual(PersonContact[1].Name, LibraryVariableStorage.DequeueText(), 'Should be an existing Contact name');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerGetContactNameFromCreateInteraction')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionContactBlankIfNameNotExists()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [Create Interaction] [Contact] [UI]
        // [GIVEN] Person Contact "A", where Name is 'Adam';
        CreateCompanyWithContact(CompanyContact[1], PersonContact[1]);
        // [GIVEN] Person Contact "B", where Name is 'Bob'
        CreateCompanyWithContact(CompanyContact[2], PersonContact[2]);
        // [GIVEN] Run "Create Interaction" for Salesperson
        SalespersonPurchaser.Get(CompanyContact[2]."Salesperson Code");

        // [WHEN] Enter "Contact" as 'Eve'
        LibraryVariableStorage.Enqueue(LowerCase('X' + PersonContact[1].Name));
        SalespersonPurchaser.CreateInteraction();
        // handled by ModalHandlerGetContactNameFromCreateInteraction

        // [THEN] "Contact" becomes '', as Contact Name 'Eve' is not found
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Should be empty Contact name');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerGetContactNameEditableFromCreateInteraction')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionContactNameNotEditableIfCalledFromContact()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [FEATURE] [Create Interaction] [Contact] [UI]
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"
        CreateCompanyWithContact(CompanyContact, PersonContact);

        // [WHEN] Open "Create Interaction" page from Person Contact "A"
        // by ModalHandlerGetContactNameEditableFromCreateInteraction
        PersonContact.CreateInteraction();

        // [THEN] "Contact" control is NOT editable
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Contact name should not be editable.');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionFromContact,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionOpportunitiesExcludeClosedOpportunities()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
    begin
        // [FEATURE] [Create Interaction] [Salesperson] [Person] [UI]
        // [SCENARIO 175341] Opportunity list page should include records, where "Closed" is 'No'.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);
        // [GIVEN] 1 Opportunity for Person Contact "A" and set Salesperson "AH" is "Closed"
        CloseOpportunity(PersonContact[1]."No.", PersonContact[1]."Salesperson Code");

        // [GIVEN] Open "Create Interaction" page from Person Contact "A" and set <blank> Salesperson
        LibraryVariableStorage.Enqueue('');
        PersonContact[1].CreateInteraction();

        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerCreateInteractionFromContact and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 2 records, where "Contact No." = "A" for "RL" and "B" for "AH"
        Assert.AreEqual(2, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
        PersonContact[1]."Salesperson Code" := PersonContact[2]."Salesperson Code";
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionFromSalesPerson,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionOpportunitiesFilteredToCompanyContactAndSalesperson()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [Create Interaction] [Salesperson] [Company] [UI]
        // [SCENARIO 175341] Opportunity list page should include records related to the chosen Contact and Salesperson pair.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);

        // [GIVEN] Open "Create Interaction" page from Salesperson "AH" and set Company Contact "B"
        LibraryVariableStorage.Enqueue(CompanyContact[1].Name);
        SalespersonPurchaser.Get(CompanyContact[1]."Salesperson Code");
        SalespersonPurchaser.CreateInteraction();

        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerCreateInteractionFromSalesperson and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 2 records, where "Contact No." = "A" or "B" and Salesperson = "AH"
        Assert.AreEqual(2, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionFromContact,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionOpportunitiesFilteredToPersonContactAndSalesperson()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
    begin
        // [FEATURE] [Create Interaction] [Salesperson] [Person] [UI]
        // [SCENARIO 175341] Opportunity list page should include records related to the chosen Contact and Salesperson pair.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);

        // [GIVEN] Open "Create Interaction" page from Person Contact "A" and set Salesperson "AH"
        LibraryVariableStorage.Enqueue(CompanyContact[1]."Salesperson Code");
        PersonContact[1].CreateInteraction();

        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerCreateInteractionFromContact and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 2 records, where "Contact No." = "A" or "B" and Salesperson = "AH"
        Assert.AreEqual(2, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionBlankOpportunity,SendNotificationHandlerCreateOpportunityOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionOpportunityCreatedIfConfirmed()
    var
        CompanyContact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        PersonContact: Record Contact;
    begin
        // [SCENARIO 175341] Opportunity is created from data on Create Interaction page, if "Create Opportunity" notification confirmed
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; No related opportunities
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Open "Create Interaction" page from Person Contact "A" and set Salesperson "AH"
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue(CompanyContact."Salesperson Code");
        PersonContact.CreateInteraction();
        // [GIVEN] Push OK on "Create Interaction" page, where Opportunity is <blank>
        // by ModalHandlerCreateInteractionBlankOpportunity
        // [WHEN] Confirm received notification "Do you want to create an opportunity?"

        // [THEN] Interaction, where "Opportunity No." is defined and Opportunity is created
        VerifyLastInteractionOpportunity(PersonContact);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionBlankOpportunity,SendNotificationHandlerCreateOpportunityCancel')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionOpportunityBlankIfNotConfirmed()
    var
        CompanyContact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        PersonContact: Record Contact;
    begin
        // [SCENARIO 175341] Opportunity is not created from data on Create Interaction page, if "Create Opportunity" notification not confirmed.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; No related opportunities
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Open "Create Interaction" page from Person Contact "A" and set Salesperson "AH"
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue(CompanyContact."Salesperson Code");
        PersonContact.CreateInteraction();
        // [GIVEN] Push OK on "Create Interaction" page, where Opportunity is <blank>
        // by ModalHandlerCreateInteractionBlankOpportunity
        // [WHEN] Do not confirm the notification "Do you want to create an opportunity?"

        // [THEN] Interaction, where "Opportunity No." is <blank>, Opportunity is not created
        VerifyLastInteractionOpportunityBlank(PersonContact);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCall,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallOpportunitiesFilteredToCompanyContactAndSalesperson()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
    begin
        // [FEATURE] [Make Phone Call] [Salesperson] [Company] [UI]
        // [SCENARIO 175341] Opportunity list page should include records related to the chosen Contact and Salesperson pair.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);
        // [GIVEN] Open "Make Phone Call" page from Company Contact "B" and set Salesperson "AH"
        LibraryVariableStorage.Enqueue(CompanyContact[1]."Salesperson Code");
        MakePhoneCallToContact(CompanyContact[1]);
        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerMakePhoneCall and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 2 records, where "Contact No." = "A", "B" and Salesperson = "AH"
        Assert.AreEqual(2, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCall,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallOpportunitiesFilteredToPersonContact()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
    begin
        // [FEATURE] [Make Phone Call] [Salesperson] [Person] [UI]
        // [SCENARIO 175341] Opportunity list page should include records related to the chosen Contact, while Salesperson is not defined.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);
        // [GIVEN] Open "Make Phone Call" page from Person Contact "A" and set <blank> Salesperson
        LibraryVariableStorage.Enqueue('');
        MakePhoneCallToContact(PersonContact[1]);

        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerMakePhoneCall and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 3 records, where "Contact No." = "A", "B" for "AH", and "A" for "RL"
        Assert.AreEqual(3, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
        PersonContact[1]."Salesperson Code" := PersonContact[2]."Salesperson Code";
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCall,ModalHandlerOpportunityList')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallOpportunitiesFilteredToPersonContactAndSalesperson()
    var
        CompanyContact: array[2] of Record Contact;
        PersonContact: array[2] of Record Contact;
    begin
        // [FEATURE] [Make Phone Call] [Salesperson] [Person] [UI]
        // [SCENARIO 175341] Opportunity list page should include records related to the chosen Contact and Salesperson pair.
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; Person Contact "C" belongs to Company "D"
        // [GIVEN] 6 Opportunities: Salesperson "AH" with "A", "B", "C"; Salesperson "RL" with "A", "C", "D"
        CreateContactsWithOpportunities(CompanyContact, PersonContact);
        // [GIVEN] Open "Make Phone Call" page from Person Contact "A" and set Salesperson "AH"
        LibraryVariableStorage.Enqueue(PersonContact[1]."Salesperson Code");
        MakePhoneCallToContact(PersonContact[1]);

        // [WHEN] Assist edit on "Opportunity" control
        // by ModalHandlerMakePhoneCall and ModalHandlerOpportunityList

        // [THEN] Opportunities List page will shows 2 records, where "Contact No." = "A", "B" and Salesperson = "AH"
        Assert.AreEqual(2, LibraryVariableStorage.Length(), 'No of opportunities is wrong');
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), PersonContact[1]);
        VerifyOpportunityContact(LibraryVariableStorage.DequeueText(), CompanyContact[1]);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCallBlankOpportunity,ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallOpportunityCreatedIfConfirmed()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 175341] Opportunity is created from data on Make Phone Call page, if confirmed
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; No related opportunities
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Open "Make Phone Call" page from Person Contact "A" and set Salesperson "AH"
        LibraryVariableStorage.Enqueue(CompanyContact."Salesperson Code");
        MakePhoneCallToContact(PersonContact);
        // [GIVEN] Push OK on "Make Phone Call" page, where Opportunity is <blank>
        // by ModalHandlerMakePhoneCallBlankOpportunity
        // [WHEN] Confirm "Do you want to create an opportunity?"
        // by ConfirmHandlerYes

        // [THEN] Interaction, where "Opportunity No." is defined, Opportunity is created
        VerifyLastInteractionOpportunity(PersonContact);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCallBlankOpportunity,ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallOpportunityBlankIfNotConfirmed()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 175341] Opportunity is NOT created from data on Make Phone Call page, if not confirmed
        Initialize();
        // [GIVEN] Person Contact "A" belongs to Company "B"; No related opportunities
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Open "Make Phone Call" page from Person Contact "A" and set Salesperson "AH"
        LibraryVariableStorage.Enqueue(CompanyContact."Salesperson Code");
        MakePhoneCallToContact(PersonContact);
        // [GIVEN] Push OK on "Make Phone Call" page, where Opportunity is <blank>
        // by ModalHandlerMakePhoneCallBlankOpportunity
        // [WHEN] Confirm "Do you want to create an opportunity?"
        // by ConfirmHandlerNo

        // [THEN] Interaction, where "Opportunity No." is <blank>, Opportunity is not created
        VerifyLastInteractionOpportunityBlank(PersonContact);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCallGetPhoneNo,ModalHandlerPhoneNoListPickLast')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallGetsPhoneNoByAssistEdit()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [Make Phone Call] [UI] [CLIENTTYPE::Windows]
        Initialize();
        // [GIVEN] User is on the "Desktop" client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);

        // [GIVEN] Person Contact "A" belongs to Company "B"
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Person "A", where "Phone No." is '1234' and "Mobile Phone No." is '9876'
        PersonContact.Validate("Phone No.", '1234');
        PersonContact.Validate("Mobile Phone No.", '9876');
        PersonContact.Modify();
        // [GIVEN] Open "Make Phone Call" page from Person Contact "A", where "Contact Phone No." is '1234'
        MakePhoneCallToContact(PersonContact);

        // [WHEN] Assist edit on "Contact Phone No." control and pick the phone number '9876'
        // by ModalHandlerMakePhoneCallGetPhoneNo and ModalHandlerPhoneNoListPickLast

        // [THEN] "Contact Phone No." becomes '9876'
        Assert.AreEqual(PersonContact."Phone No.", LibraryVariableStorage.DequeueText(), 'Phone No. before is wrong');
        Assert.AreEqual(PersonContact."Mobile Phone No.", LibraryVariableStorage.DequeueText(), 'Phone No. after is wrong');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerMakePhoneCallGetPhoneNo,ModalHandlerPhoneNoListPickFirst')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhoneCallGetsMobilePhoneAsDefaultOnMobileClient()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [Make Phone Call] [UI] [CLIENTTYPE::Phone]
        Initialize();
        // [GIVEN] User is on the "Phone" client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);

        // [GIVEN] Person Contact "A" belongs to Company "B"
        CreateCompanyWithContact(CompanyContact, PersonContact);
        // [GIVEN] Person "A", where "Phone No." is '1234' and "Mobile Phone No." is '9876'
        PersonContact.Validate("Phone No.", '1234');
        PersonContact.Validate("Mobile Phone No.", '9876');
        PersonContact.Modify();
        // [WHEN] Open "Make Phone Call" page from Person Contact "A", where "Contact Phone No." is '9876'
        MakePhoneCallToContact(PersonContact);

        // [WHEN] Assist edit on "Contact Phone No." control and pick the phone number '9876'
        // by ModalHandlerMakePhoneCallGetPhoneNo and ModalHandlerPhoneNoListPickFirst

        // [THEN] "Contact Phone No." becomes '1234'
        Assert.AreEqual(PersonContact."Mobile Phone No.", LibraryVariableStorage.DequeueText(), 'Phone No. before is wrong');
        Assert.AreEqual(PersonContact."Phone No.", LibraryVariableStorage.DequeueText(), 'Phone No. after is wrong');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SegmentLineDescriptionDefaultsFromTemplate()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        SegmentLine: Record "Segment Line";
    begin
        // [FEATURE] [Segment Line] [UT]
        Initialize();
        SegmentLine.DeleteAll();
        // [GIVEN] Interaction Template "GOLF", where Description = 'Golf event'
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] New Segment Line, where "Description" is <blank>
        SegmentLine.Init();
        LibraryMarketing.CreatePersonContact(Contact);
        SegmentLine."Contact No." := Contact."No.";
        SegmentLine.Description := '';
        SegmentLine.Insert();
        // [WHEN] Set "Interaction Template Code" to "GOLF"
        SegmentLine.Validate("Interaction Template Code", InteractionTemplate.Code);
        // [THEN] Segment Line's "Description" = 'Golf event'
        SegmentLine.TestField(Description, InteractionTemplate.Description);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SegmentLineDescriptionNotChangedByTemplateIfNotBlank()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        SegmentLine: Record "Segment Line";
        ExpectedDescription: Text[50];
    begin
        // [FEATURE] [Segment Line] [UT]
        Initialize();
        SegmentLine.DeleteAll();
        // [GIVEN] Interaction Template "GOLF", where Description = 'Golf event'
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] New Segment Line, where "Description" is 'Playing golf'
        SegmentLine.Init();
        LibraryMarketing.CreatePersonContact(Contact);
        SegmentLine."Contact No." := Contact."No.";
        ExpectedDescription := 'Line Description';
        SegmentLine.Description := ExpectedDescription;
        SegmentLine.Insert();
        // [WHEN] Set "Interaction Template Code" to "GOLF"
        SegmentLine.Validate("Interaction Template Code", InteractionTemplate.Code);
        // [THEN] Segment Line's "Description" = 'Playing golf'
        SegmentLine.TestField(Description, ExpectedDescription);
    end;

    [Test]
    [HandlerFunctions('ModalHandlerGetTimeFromCreateInteraction')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SegmentLineDefaultTimeShouldBeNOWRoundedUpToNextMinute()
    var
        Contact: Record Contact;
        ExpectedTimeAsText: Text;
    begin
        // [FEATURE] [UI]
        Initialize();
        // [GIVEN] Current time is '12:33:59'
        ExpectedTimeAsText := Format(DT2Time(RoundDateTime(CurrentDateTime + 1000, 60000, '>')), 0, 9);

        // [WHEN] Start "Create Interaction" for a Contact
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.CreateInteraction();

        // [THEN] "Time of Interaction" = '12:34:00'
        // by ModalHandlerGetTimeFromCreateInteraction
        Assert.AreEqual(ExpectedTimeAsText, LibraryVariableStorage.DequeueText(), 'Wrong Time of Interaction');
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerContactThrough')]
    [Scope('OnPrem')]
    procedure OnlyContactNumbersShownOnShowNumbersOfTAPIManagement()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        TAPIManagement: Codeunit TAPIManagement;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 221715] "TAPIManagement"."ShowNumbers" must open page with phone numbers of Contact and Contact's Company
        Initialize();

        // [GIVEN] Contact of Company "CC" with "Phone No." = "789654123", "Mobile Phone No." = "987456321"
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        LibraryUtility.FillFieldMaxText(CompanyContact, CompanyContact.FieldNo("Phone No."));
        CompanyContact.Get(CompanyContact."No.");
        LibraryUtility.FillFieldMaxText(CompanyContact, CompanyContact.FieldNo("Mobile Phone No."));
        CompanyContact.Get(CompanyContact."No.");

        // [GIVEN] Contact of Person with "Phone No." = "123456789", "Mobile Phone No." = "987654321", "Company No." = "CC"
        LibraryMarketing.CreatePersonContact(PersonContact);
        LibraryUtility.FillFieldMaxText(PersonContact, PersonContact.FieldNo("Phone No."));
        PersonContact.Get(PersonContact."No.");
        LibraryUtility.FillFieldMaxText(PersonContact, PersonContact.FieldNo("Mobile Phone No."));
        PersonContact.Get(PersonContact."No.");
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify(true);

        // [WHEN] Invoke "TAPIManagement"."ShowNumbers" for Contact of Person
        TAPIManagement.ShowNumbers(PersonContact."No.", '');

        // [THEN] Page "Contact Through" 5145 is showing all nubmers:
        // [THEN] The first number = "123456789"
        Assert.AreEqual(PersonContact."Phone No.", LibraryVariableStorage.DequeueText(), 'Wrong Phone No. of Person Contact');

        // [THEN] The second number = "987654321"
        Assert.AreEqual(PersonContact."Mobile Phone No.", LibraryVariableStorage.DequeueText(), 'Wrong Mobile Phone No. of Person Contact');

        // [THEN] The third number = "789654123"
        Assert.AreEqual(CompanyContact."Phone No.", LibraryVariableStorage.DequeueText(), 'Wrong Phone No. of Company Contact');

        // [THEN] The fourth number = "987456321"
        Assert.AreEqual(
          CompanyContact."Mobile Phone No.", LibraryVariableStorage.DequeueText(), 'Wrong Mobile Phone No. of Company Contact');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionSetTemplate')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateInteractionIgnoreContactCorresType()
    var
        PersonContact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 392150] Correspondence Type = empty when user creates interaction from template with "Ignore Contact Corres. Type" = Yes
        Initialize();

        // [GIVEN] Set "Marketing Setup"."Default Correspondence Type" = Email
        UpdateMarketingSetupDefaultCorrType("Correspondence Type"::Email);
        // [GIVEN] Person Contact "A" 
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.TestField("Correspondence Type", "Correspondence Type"::Email);

        // [GIVEN] Interaction template "IT" with "Ignore Contact Corres. Type" := true
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Ignore Contact Corres. Type" := true;
        InteractionTemplate.Modify();

        // [WHEN] Open "Create Interaction" page from Person Contact "A" and set "Interaction Template Code" = "IT"
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        // by ModalHandlerCreateInteractionSetTemplate
        PersonContact.CreateInteraction();

        // [THEN] "Corresponding Type" = empty
        Assert.AreEqual("Correspondence Type"::" ".AsInteger(), LibraryVariableStorage.DequeueInteger(), 'Invalid Correspondence Type');
    end;

    [Test]
    [HandlerFunctions('ModalHandlerCreateInteractionSetTemplateAndCorrType')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InteractionTemplateNoAttachmentError()
    var
        PersonContact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 392150] Create interaction with Email "Correspondence Type" without attachment leads to error
        Initialize();

        // [GIVEN] Person Contact "A" 
        LibraryMarketing.CreatePersonContact(PersonContact);

        // [GIVEN] Interaction template "IT" without attachment 
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.CalcFields("Attachment No.");
        InteractionTemplate.TestField("Attachment No.", 0);

        // [WHEN] Open "Create Interaction" page from Person Contact "A" and set "Interaction Template Code" = "IT" and "Correspondence Type" = Email 
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue("Correspondence Type"::Email.AsInteger());
        // by ModalHandlerCreateInteractionSetTemplate
        asserterror PersonContact.CreateInteraction();

        // [THEN] Error "Correspondence type set for this interaction is Email and it requires interaction template with attachment..."
        Assert.ExpectedError(CorrTypeNoAtachmentErr);
    end;

    local procedure Initialize()
    var
        Opportunity: Record Opportunity;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Interactions UI");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Opportunity.DeleteAll();
        FillMarketingSetupDefaultSalesCycleCode();

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Interactions UI");
    end;

    local procedure CloseOpportunity(ContactNo: Code[20]; SalesPersonCode: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.SetRange("Salesperson Code", SalesPersonCode);
        Opportunity.ModifyAll(Closed, true);
    end;

    local procedure CreateCompanyWithContact(var CompanyContact: Record Contact; var PersonContact: Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        CreateSalesperson(SalespersonPurchaser);
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        CompanyContact."Salesperson Code" := SalespersonPurchaser.Code;
        CompanyContact."Correspondence Type" := CompanyContact."Correspondence Type"::" ";
        CompanyContact.Modify();
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact."Correspondence Type" := CompanyContact."Correspondence Type"::" ";
        PersonContact."Company No." := CompanyContact."No.";
        PersonContact."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        PersonContact."Mobile Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        PersonContact."Salesperson Code" := SalespersonPurchaser.Code;
        PersonContact.Modify();
    end;

    local procedure CreateOpportunitiesPerContact(Contact: array[3] of Record Contact)
    var
        Opportunity: Record Opportunity;
        i: Integer;
    begin
        for i := 1 to 3 do begin
            LibraryMarketing.CreateOpportunity(Opportunity, Contact[i]."No.");
            Opportunity."Salesperson Code" := Contact[3]."Salesperson Code";
            Opportunity.Modify();
        end;
    end;

    local procedure CreateContactsWithOpportunities(var CompanyContact: array[2] of Record Contact; var PersonContact: array[2] of Record Contact)
    var
        Contact: array[3] of Record Contact;
    begin
        CreateCompanyWithContact(CompanyContact[1], PersonContact[1]);
        CreateCompanyWithContact(CompanyContact[2], PersonContact[2]);
        Contact[1] := PersonContact[1];
        Contact[2] := PersonContact[2];
        Contact[3] := CompanyContact[1];
        CreateOpportunitiesPerContact(Contact);
        Contact[3] := CompanyContact[2];
        CreateOpportunitiesPerContact(Contact);
    end;

    local procedure CreateSalesperson(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Validate(Code, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(SalespersonPurchaser.Code), 1));
        SalespersonPurchaser.Validate(Name, SalespersonPurchaser.Code);  // Validating Name as Code because value is not important.
        SalespersonPurchaser.Insert(true);
    end;

    local procedure FillMarketingSetupDefaultSalesCycleCode()
    var
        MarketingSetup: Record "Marketing Setup";
        SalesCycle: Record "Sales Cycle";
    begin
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        MarketingSetup.Get();
        MarketingSetup."Default Sales Cycle Code" := SalesCycle.Code;
        MarketingSetup.Modify();
    end;

    local procedure MakePhoneCallToContact(Contact: Record Contact)
    var
        ContactListPage: TestPage "Contact List";
    begin
        ContactListPage.OpenView();
        ContactListPage.GotoRecord(Contact);
        ContactListPage.MakePhoneCall.Invoke();
        ContactListPage.Close();
    end;

    local procedure UpdateMarketingSetupDefaultCorrType(CorrespondenceType: Enum "Correspondence Type")
    var
        MarketingSetup: Record "Marketing Setup";
    begin

        MarketingSetup.Get();
        MarketingSetup."Default Correspondence Type" := CorrespondenceType;
        MarketingSetup.Modify();
    end;

    local procedure VerifyLastInteractionOpportunity(Contact: Record Contact)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField("Opportunity No.");
        VerifyOpportunity(Contact, InteractionLogEntry."Opportunity No.");
    end;

    local procedure VerifyLastInteractionOpportunityBlank(Contact: Record Contact)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField("Opportunity No.", '');
        asserterror VerifyOpportunity(Contact, '');
        Assert.ExpectedError('There is no Opportunity within the filter.');
    end;

    local procedure VerifyOpportunity(Contact: Record Contact; OpportunityNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.SetRange("Salesperson Code", Contact."Salesperson Code");
        Opportunity.FindLast();
        Opportunity.TestField("No.", OpportunityNo);
        Opportunity.TestField("Sales Cycle Code");
    end;

    local procedure VerifyOpportunityContact(OpportunityNo: Text; Contact: Record Contact)
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.Get(CopyStr(OpportunityNo, 1, MaxStrLen(Opportunity."No.")));
        Opportunity.TestField("Contact No.", Contact."No.");
        Opportunity.TestField("Salesperson Code", Contact."Salesperson Code");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerCreateInteractionBlankOpportunity(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteractionPage."Salesperson Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteractionPage."Opportunity Description".AssertEquals('');
        CreateInteractionPage.NextInteraction.Invoke();
        CreateInteractionPage.NextInteraction.Invoke();
        CreateInteractionPage.FinishInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerCreateInteractionFromContact(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Salesperson Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteractionPage."Opportunity Description".AssistEdit();
        // handled by ModalHandlerOpportunityList
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerCreateInteractionFromSalesPerson(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Wizard Contact Name".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteractionPage."Opportunity Description".AssistEdit();
        // handled by ModalHandlerOpportunityList
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerGetContactNameFromCreateInteraction(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Wizard Contact Name".SetValue(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(Format(CreateInteractionPage."Wizard Contact Name".Value));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerGetContactNameEditableFromCreateInteraction(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        LibraryVariableStorage.Enqueue(CreateInteractionPage."Wizard Contact Name".Editable());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerGetTimeFromCreateInteraction(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        LibraryVariableStorage.Enqueue(Format(CreateInteractionPage."Time of Interaction".AsTime(), 0, 9));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerCreateInteractionSetTemplate(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(CreateInteractionPage."Correspondence Type".AsInteger());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerCreateInteractionSetTemplateAndCorrType(var CreateInteractionPage: TestPage "Create Interaction")
    begin
        CreateInteractionPage."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteractionPage."Correspondence Type".SetValue(LibraryVariableStorage.DequeueInteger());
        CreateInteractionPage.NextInteraction.Invoke();
        CreateInteractionPage.NextInteraction.Invoke();
        CreateInteractionPage.FinishInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerMakePhoneCall(var MakePhoneCallPage: TestPage "Make Phone Call")
    begin
        MakePhoneCallPage."Salesperson Code".SetValue(LibraryVariableStorage.DequeueText());
        MakePhoneCallPage."Opportunity Description".AssistEdit();
        // handled by ModalHandlerOpportunityList
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerMakePhoneCallBlankOpportunity(var MakePhoneCallPage: TestPage "Make Phone Call")
    begin
        MakePhoneCallPage."Salesperson Code".SetValue(LibraryVariableStorage.DequeueText());
        MakePhoneCallPage."Opportunity Description".AssertEquals('');
        MakePhoneCallPage.Finish.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerMakePhoneCallGetPhoneNo(var MakePhoneCallPage: TestPage "Make Phone Call")
    begin
        LibraryVariableStorage.Enqueue(MakePhoneCallPage."Contact Via".Value); // Phone No. before
        MakePhoneCallPage."Contact Via".AssistEdit();
        // handled by ModalHandlerPhoneNoList
        LibraryVariableStorage.Enqueue(MakePhoneCallPage."Contact Via".Value); // Phone No. after
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerPhoneNoListPickFirst(var ContactThroughPage: TestPage "Contact Through")
    begin
        ContactThroughPage.First();
        ContactThroughPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerPhoneNoListPickLast(var ContactThroughPage: TestPage "Contact Through")
    begin
        ContactThroughPage.Last();
        ContactThroughPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerOpportunityList(var OpportunityListPage: TestPage "Opportunity List")
    begin
        LibraryVariableStorage.Clear();
        if OpportunityListPage.First() then
            repeat
                LibraryVariableStorage.Enqueue(OpportunityListPage."No.".Value);
            until not OpportunityListPage.Next();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandlerCreateOpportunityOk(var CreateOpporunityNotification: Notification): Boolean
    var
        RelationshipPerformanceMgt: Codeunit "Relationship Performance Mgt.";
    begin
        // EXIT(TRUE) - does not call attached action.
        RelationshipPerformanceMgt.CreateOpportunityFromSegmentLineNotification(CreateOpporunityNotification);
        exit(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandlerCreateOpportunityCancel(var CreateOpporunityNotification: Notification): Boolean
    begin
        exit(false);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerContactThrough(var ContactThrough: TestPage "Contact Through")
    begin
        LibraryVariableStorage.Enqueue(ContactThrough.Number.Value);
        ContactThrough.Next();
        LibraryVariableStorage.Enqueue(ContactThrough.Number.Value);
        ContactThrough.Next();
        LibraryVariableStorage.Enqueue(ContactThrough.Number.Value);
        ContactThrough.Next();
        LibraryVariableStorage.Enqueue(ContactThrough.Number.Value);
        ContactThrough.OK().Invoke();
    end;
}

