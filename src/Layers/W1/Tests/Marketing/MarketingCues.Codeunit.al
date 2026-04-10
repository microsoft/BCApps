codeunit 136216 "Marketing Cues"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [Role Center] [Contacts]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ContactsNumberErr: Label 'Wrong number of contacts.';

    [Test]
    [Scope('OnPrem')]
    procedure ContactsCompany()
    var
        RelationshipMgmtCue: Record "Relationship Mgmt. Cue";
        I: Integer;
    begin
        // [SCENARIO 180152] User can easily review "company" contacts in the Sales & Relationship Manager role center
        Initialize();

        // [GIVEN] Number of Contacts "Company" type
        for I := 1 to LibraryRandom.RandInt(5) do
            MockContactCompany();
        // [WHEN] Calculate "Contacts - Companies" flow field for the "Relationship Mgmt. Cue"
        RelationshipMgmtCue.CalcFields("Contacts - Companies");
        // [THEN] "Relationship Mgmt. Cue"."Contacts - Companies" shows number of created contacts
        Assert.AreEqual(I, RelationshipMgmtCue."Contacts - Companies", ContactsNumberErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactsPerson()
    var
        RelationshipMgmtCue: Record "Relationship Mgmt. Cue";
        I: Integer;
    begin
        // [SCENARIO 180152] User can easily review "person" contacts in the Sales & Relationship Manager role center
        Initialize();

        // [GIVEN] Number of Contacts "Person" type
        for I := 1 to LibraryRandom.RandInt(5) do
            MockContactPerson();
        // [WHEN] Calculate "Contacts - Persons" flow field for the "Relationship Mgmt. Cue"
        RelationshipMgmtCue.CalcFields("Contacts - Persons");
        // [THEN] "Relationship Mgmt. Cue"."Contacts - Persons" shows number of created contacts
        Assert.AreEqual(I, RelationshipMgmtCue."Contacts - Persons", ContactsNumberErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactsDuplicate()
    var
        RelationshipMgmtCue: Record "Relationship Mgmt. Cue";
        I: Integer;
    begin
        // [SCENARIO 180152] User can easily review contacts duplicates in the Sales & Relationship Manager role center
        Initialize();

        // [GIVEN] Number of contacts that are duplicates
        CreateDuplicateSearchStringSetup();
        for I := 1 to LibraryRandom.RandInt(5) do
            MockContactDuplicate();
        // [WHEN] Calculate "Contacts - Duplicates" flow field for the "Relationship Mgmt. Cue"
        REPORT.Run(REPORT::"Generate Dupl. Search String", false);
        RelationshipMgmtCue.CalcFields("Contacts - Duplicates");
        // [THEN] "Relationship Mgmt. Cue"."Contacts - Duplicates" shows number of duplicate contacts
        Assert.AreEqual(I, RelationshipMgmtCue."Contacts - Duplicates", ContactsNumberErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Cues");
        ClearRecords();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Cues");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Cues");
    end;

    local procedure ClearRecords()
    var
        Contact: Record Contact;
        ContactDuplicate: Record "Contact Duplicate";
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
    begin
        Contact.DeleteAll();
        ContactDuplicate.DeleteAll();
        DuplicateSearchStringSetup.DeleteAll();
    end;

    local procedure CreateDuplicateSearchStringSetup()
    var
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
        Contact: Record Contact;
    begin
        DuplicateSearchStringSetup.Init();
        DuplicateSearchStringSetup."Field No." := Contact.FieldNo(Name);
        DuplicateSearchStringSetup."Part of Field" := DuplicateSearchStringSetup."Part of Field"::First;
        DuplicateSearchStringSetup.Insert();
    end;

    local procedure MockContact(var Contact: Record Contact)
    begin
        Contact.Init();
        Contact."No." := LibraryUtility.GenerateRandomCode(Contact.FieldNo("No."), DATABASE::Contact);
        Contact.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.Name)), 1, MaxStrLen(Contact.Name));
        Contact.Insert();
    end;

    local procedure MockContactCompany()
    var
        Contact: Record Contact;
    begin
        MockContact(Contact);
        Contact.Type := Contact.Type::Company;
        Contact.Modify();
    end;

    local procedure MockContactPerson()
    var
        Contact: Record Contact;
    begin
        MockContact(Contact);
        Contact.Type := Contact.Type::Person;
        Contact.Modify();
    end;

    local procedure MockContactDuplicate()
    var
        Contact: Record Contact;
        DuplicateContact: Record Contact;
    begin
        MockContactCompany();
        Contact.FindLast();

        MockContact(DuplicateContact);
        DuplicateContact.Name := Contact.Name;
        DuplicateContact.Type := DuplicateContact.Type::Company;
        DuplicateContact.Modify();
    end;
}

