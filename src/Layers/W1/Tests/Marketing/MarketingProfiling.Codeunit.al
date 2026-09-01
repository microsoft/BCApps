codeunit 136206 "Marketing Profiling"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Profile Questionnaire] [Marketing]
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        DateFormulaCurrentDayTok: Label '<CD>', Locked = true;
        IncorrectFieldValueErr: Label 'Field %1 contains incorrect value', Comment = '%1 - field name';
        ContactClassificationErr: Label 'Contact Classification was not updated';
        DateFormulaStartDayTok: Label '<CY-1Y+1D>', Locked = true;
        IncorrectQuestionnaireLineCountErr: Label 'Incorrect count questionnaire lines.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateQuestionnairesWithRating()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Covers document number TC0015 - refer to TFS ID 21734.
        // Test that creating profile questionnaires with the list of questions and answers with Contact Class as Rating,
        // On Running Update Classification Updates No. of Contact Assigned.

        ProfileQuestionnaires(ProfileQuestionnaireLine."Contact Class. Field"::Rating);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateQuestionnairesWithNoFilter()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ProfileQuestionnaireCode: Code[10];
    begin
        // 1. Setup: Create Profile Questionnaires Header and Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        CreateQuestionnairesLines(ProfileQuestionnaireCode, ProfileQuestionnaireLine."Contact Class. Field"::Rating);

        // 2. Exercise: Run the Update Classification Report with no filter.
        UpdateClassification('');

        // 3. Verify: Check No. of Contact Assigned to the Questionnaire Lines.
        VerifyNoOfContacts(ProfileQuestionnaireCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesInteractionQty()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Covers document number TC0015 - refer to TFS ID 21734.
        // Test that creating profile questionnaires with the list of questions and answers with Contact Class as Interaction Quantity,
        // On Running Update Classification Updates No. of Contact Assigned.

        ProfileQuestionnaires(ProfileQuestionnaireLine."Contact Class. Field"::"Interaction Quantity")
    end;

    local procedure ProfileQuestionnaires(ContactClass: Enum "Profile Quest. Cont. Class. Field")
    var
        ProfileQuestionnaireCode: Code[10];
    begin
        // 1. Setup: Create Profile Questionnaires Header and Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        CreateQuestionnairesLines(ProfileQuestionnaireCode, ContactClass);

        // 2. Exercise: Run the Update Classification Report to update the No of Contact.
        UpdateClassification(ProfileQuestionnaireCode);

        // 3. Verify: Check No. of Contact Assigned to the Questionnaire Lines.
        VerifyNoOfContacts(ProfileQuestionnaireCode);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateRating,ModalFormHandlerAnswerPoints')]
    [Scope('OnPrem')]
    procedure CreatingContactRatingAuto()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
        ProfileQuestionnaireCode: Code[10];
        WizardFromValue: Decimal;
        WizardToValue: Decimal;
    begin
        // Covers document number TC0016 - refer to TFS ID 21734.
        // Test that it is possible to create the contact rating automatically and assigning answer points.

        // 1. Setup: Create Profile Questionnaires Header.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();

        // Set global variables for Form Handler.
        WizardFromValue := LibraryRandom.RandInt(10);  // Wizard From Value and Wizard To Value is not important for the test Case.
        WizardToValue := WizardFromValue + LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(WizardFromValue);
        LibraryVariableStorage.Enqueue(WizardToValue);

        // 2. Exercise: Create Contact Rating automatically, assigning answer points.
        ProfileQuestionnaireLine.Validate("Profile Questionnaire Code", ProfileQuestionnaireCode);
        TempProfileQuestionnaireLine.CreateRatingFromProfQuestnLine(ProfileQuestionnaireLine);

        // 3. Verify: Check Answers are created with values of From Value and To Value. Check No. of Contact Assigned
        // to the Questionnaire Lines.
        VerifyAnswerRating(ProfileQuestionnaireCode, WizardFromValue, WizardToValue);
    end;

    [Test]
    [HandlerFunctions('ModalFormContactProfileAnswers')]
    [Scope('OnPrem')]
    procedure CreateContactProfileManually()
    var
        ProfileQuestionnaireCode: Code[10];
    begin
        // Covers document number TC0017 - refer to TFS ID 21734.
        // Test that filling in a contact profile manually on a contact card updates the No. of Contact on Profile Questionnaires Line.

        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        QuestionnairesLinesWOClass(ProfileQuestionnaireCode);

        // 2. Exercise: Manually set the Answer on Contact Profile.
        ManuallySetAnswerOnContProfile(ProfileQuestionnaireCode);

        // 3. Verify: Check No. of Contact assigned to the Profile Questionnaire Line.
        VerifyNoOfContactsManualAssign(ProfileQuestionnaireCode);
    end;

    [Test]
    [HandlerFunctions('ModalFormContactProfileAnswers,ModalFormHandlerSegCriteria,ModalFrmHandleSavedSegCriteria')]
    [Scope('OnPrem')]
    procedure ContactToSegmentUsingProfile()
    var
        SegmentHeader: Record "Segment Header";
        ProfileQuestionnaireCode: Code[10];
        SegmentNo: Code[20];
    begin
        // Covers document number TC0018 - refer to TFS ID 21734.
        // Test that contacts can be added to the segments using the questionnaire profiles.

        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        // Manually set the Answer on Contact Profile.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        QuestionnairesLinesWOClass(ProfileQuestionnaireCode);
        ManuallySetAnswerOnContProfile(ProfileQuestionnaireCode);

        // 2. Exercise: Create Segment Header. Assign Contact to the Segment with Add Contact Report. Save Criteria, Create another
        // Segment and Reuse the Saved Criteria.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentNo := SegmentHeader."No.";
        AddContact(SegmentHeader, ProfileQuestionnaireCode);
        SegmentHeader.SaveCriteria();

        Clear(SegmentHeader);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.ReuseCriteria();

        // 3. Verify: Contacts added to the segments Header and Segment Line.
        VerifyCriteriaActionOnSegment(SegmentNo);
        VerifyContactsOnSegmentLine(SegmentNo, ProfileQuestionnaireCode);
        VerifyCriteriaActionOnSegment(SegmentHeader."No.");
        VerifyContactsOnSegmentLine(SegmentHeader."No.", ProfileQuestionnaireCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesCustomerSaleFreq()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Covers document number TC0019 - refer to TFS ID 21734.
        // Test that creating profile questionnaires with the list of questions and answers with Customer Class to
        // Sales Frequency (Invoices/Year) On Running Update Classification Updates No. of Contact Assigned.

        QuestionnairesCustomerClass(ProfileQuestionnaireLine."Customer Class. Field"::"Sales Frequency (Invoices/Year)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesCustomerProfit()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Covers document number TC0019 - refer to TFS ID 21734.
        // Test that creating profile questionnaires with the list of questions and answers with Customer Class to
        // Profit (LCY) On Running Update Classification Updates No. of Contact Assigned.

        QuestionnairesCustomerClass(ProfileQuestionnaireLine."Customer Class. Field"::"Profit (LCY)");
    end;

    local procedure QuestionnairesCustomerClass(CustomerClass: Enum "Profile Quest. Cust. Class. Field")
    var
        ProfileQuestionnaireCode: Code[10];
    begin
        // Covers document number TC0019 - refer to TFS ID 21734.
        // Test that creating profile questionnaires with the list of questions and answers with Customer Class to
        // Profit (LCY) On Running Update Classification Updates No. of Contact Assigned.

        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        QuestionnairesLinesCustClass(ProfileQuestionnaireCode, CustomerClass);

        // 2. Exercise: Run the Update Classification Report to update the No of Contact.
        UpdateClassification(ProfileQuestionnaireCode);

        // 3. Verify: Check No. of Contact Assigned to the Questionnaire.
        VerifyNoOfContacts(ProfileQuestionnaireCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesTestReport()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        QuestionnaireTest: Report "Questionnaire - Test";
        ProfileQuestionnaireCode: Code[10];
        FilePath: Text[1024];
    begin
        // Covers document number TC0020 - refer to TFS ID 21734.
        // Test that profile questionnaires Test Report generates correct output.

        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();

        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0);

        // 2. Exercise: Save Test Report as XML and XLSX in local Temp folder.
        ProfileQuestionnaireHeader.SetRange(Code, ProfileQuestionnaireHeader.Code);
        QuestionnaireTest.SetTableView(ProfileQuestionnaireHeader);
        FilePath := TemporaryPath + ProfileQuestionnaireHeader.Code + '.xlsx';
        QuestionnaireTest.SaveAsExcel(FilePath);

        // 3. Verify: Verify that saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandoutsWithoutClassification()
    begin
        // Covers document number TC0020 - refer to TFS ID 21734.
        // Test that profile questionnaires Handouts Report without print classification set generates correct output.

        QuestionnairesHandoutsReport(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandoutsWithClassification()
    begin
        // Covers document number TC0020 - refer to TFS ID 21734.
        // Test that profile questionnaires Handouts Report with print classification set generates correct output.

        QuestionnairesHandoutsReport(true);
    end;

    local procedure QuestionnairesHandoutsReport(PrintClassification: Boolean)
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        QuestionnaireHandouts: Report "Questionnaire - Handouts";
        ProfileQuestionnaireCode: Code[10];
        FilePath: Text[1024];
    begin
        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0);

        // 2. Exercise: Save Handouts Report as XML and XLSX in local Temp folder.
        ProfileQuestionnaireHeader.SetRange(Code, ProfileQuestionnaireHeader.Code);
        QuestionnaireHandouts.SetTableView(ProfileQuestionnaireHeader);
        if PrintClassification then
            QuestionnaireHandouts.InitializeRequest(true);

        FilePath := TemporaryPath + ProfileQuestionnaireHeader.Code + '.xlsx';
        QuestionnaireHandouts.SaveAsExcel(FilePath);

        // 3. Verify: Verify that saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('SettingTwoAnswerUnCheckOneOnQuestionnaireHandler')]
    [Scope('OnPrem')]
    procedure UncheckTheSecondOneAfterTwoAnswersBeSelectedOnQuestionnaire()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        Contact: Record Contact;
        ProfileManagement: Codeunit ProfileManagement;
        ProfileQuestionnaireCode: Code[10];
    begin
        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        QuestionnairesLinesWOClassWithMultipleAnswerOptions(ProfileQuestionnaireCode);

        // Create contact and set the Type in the Contact Card.
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Modify(true);

        // 2. Exercise: Check the 1st answer and check the 2nd answer, then uncheck the 2nd answer.
        ProfileManagement.ShowContactQuestionnaireCard(Contact, ProfileQuestionnaireCode, ProfileQuestionnaireLine."Line No.");
        // 3. Verify: No error pops up after uncheck the 2nd answer.
    end;

    [Test]
    [HandlerFunctions('CheckQuestionThenUndoOnQuestionnaireHandler')]
    [Scope('OnPrem')]
    procedure UncheckQuestionAfterQuestionBeSelectedOnQuestionnaire()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        Contact: Record Contact;
        ProfileManagement: Codeunit ProfileManagement;
        ProfileQuestionnaireCode: Code[10];
    begin
        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        QuestionnairesLinesWOClassWithMultipleAnswerOptions(ProfileQuestionnaireCode);

        // Create contact and set the Type in the Contact Card.
        FindFirstQuestionOnProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Modify(true);

        // 2. Exercise: Check the question, then uncheck it.
        ProfileManagement.ShowContactQuestionnaireCard(Contact, ProfileQuestionnaireCode, ProfileQuestionnaireLine."Line No.");
        // 3. Verify: No error pops up after uncheck the question.
    end;

    [Test]
    [HandlerFunctions('ProfileQuestionnaireSetupPageHandler')]
    [Scope('OnPrem')]
    procedure ProfileQuestionnaireSetupPage()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ProfileQuestionnaireCode: Code[10];
        FromValue: Decimal;
        ToValue: Decimal;
    begin
        // 1. Setup: Create Profile Questionnaires - Questionnaires Header and Questionnaires Line.
        Initialize();
        ProfileQuestionnaireCode := CreateQuestionnairesHeader();
        CreateQuestionnairesLinesWithValues(ProfileQuestionnaireCode, FromValue, ToValue);

        // 2. Exercise: Set values via Profile Questionnaire Setup
        Commit();
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        PAGE.RunModal(PAGE::"Profile Questionnaire Setup", ProfileQuestionnaireLine);

        // 3. Verify: No error pops up after uncheck the question and stored values are correct
        VerifyQuestionariesLineFromValueAndToValue(ProfileQuestionnaireCode, FromValue, ToValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesVendorPurchaseLCY()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ContactProfileAnswer: Record "Contact Profile Answer";
        InvoiceAmount: Decimal;
        ProfileQuestionnaireCode: Code[10];
        VendorNo: Code[20];
        ContactNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 375341] A Contact having posted Purchase Invoice with positive amount should be included in Answer with positive range of total value
        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(100, 200);
        ProfileQuestionnaireCode := CreateQuestionnairesHeaderWithContactType(ProfileQuestionnaireHeader."Contact Type"::Companies);

        // [GIVEN] Question with 2 answers
        CreateQuestionnairesLineQuestion(
          ProfileQuestionnaireLine, ProfileQuestionnaireCode, ProfileQuestionnaireLine."Contact Class. Field"::" ");
        UpdateVendorClass(ProfileQuestionnaireLine, ProfileQuestionnaireLine."Vendor Class. Field"::"Purchase (LCY)");

        // [GIVEN] "Answer 1" with total value range = (-<unlimited>;-50]
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0, InvoiceAmount / 2);
        // [GIVEN] "Answer 2" with total value range = [50;<unlimited>)
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, InvoiceAmount / 2, 0);

        // [GIVEN] Vendor "V" with linked Contact "C"
        CreateVendorWithContact(VendorNo, ContactNo);

        // [GIVEN] Purchase Invoice with Amount 100 for Vendor "V"
        PostPurchaseInvoice(VendorNo, InvoiceAmount);

        // [WHEN] Run the Update Classification Report to update answers
        UpdateClassification(ProfileQuestionnaireCode);

        // [THEN] Contact "C" is not included in "Answer 1"
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        ContactProfileAnswer.Init();
        ContactProfileAnswer.SetRange("Contact No.", ContactNo);
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        ContactProfileAnswer.SetRange("Line No.", ProfileQuestionnaireLine."Line No.");
        Assert.RecordIsEmpty(ContactProfileAnswer);

        // [THEN] Contact "C" is included in "Answer 2"
        ProfileQuestionnaireLine.Next();
        ContactProfileAnswer.SetRange("Line No.", ProfileQuestionnaireLine."Line No.");
        Assert.RecordIsNotEmpty(ContactProfileAnswer);
    end;

    [Test]
    [HandlerFunctions('AnswerPointsModalPageHandler')]
    [Scope('OnPrem')]
    procedure UT_FinishWizardWithMultipleQuestionnareLinesAfterPerformLastWizStep()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 375354] When finish "Create Rating" wizard with multiple profile questionnaire lines all the lines are added to Questionnaire setup

        Initialize();
        // [GIVEN] Questionnaire with one heading line and two answers
        LibraryMarketing.CreateQuestionnaireHeader(ProfileQuestionnaireHeader);
        ProfileQuestionnaireLine."Profile Questionnaire Code" := ProfileQuestionnaireHeader.Code;
        ProfileQuestionnaireLine."Answer Option" := ProfileQuestionnaireLine."Answer Option"::HighLow;
        ProfileQuestionnaireLine.ValidateAnswerOption();

        // [GIVEN] Handled answers by the last Wizard step
        ProfileQuestionnaireLine."Wizard Step" := 3;
        ProfileQuestionnaireLine.PerformNextWizardStatus();

        // [WHEN] Finish "Create Rating" Wizard
        ProfileQuestionnaireLine.FinishWizard();

        // [THEN] The count of questionnaire lines added is 3 (heading + two answers)
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", ProfileQuestionnaireLine."Profile Questionnaire Code");
        Assert.AreEqual(3, ProfileQuestionnaireLine.Count, IncorrectQuestionnaireLineCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnairesClassificationMethodPercentageOfValue()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ContactProfileAnswer: Record "Contact Profile Answer";
        InvoiceAmount: Decimal;
        ProfileQuestionnaireCode: Code[10];
        VendorNo: array[3] of Code[20];
        ContactNo: array[3] of Code[20];
        Index: Integer;
        OldWorkDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 381660] Stan calls "Update Contacts Classification" report when question's classification method is "Percentage of Value"
        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(10, 20);
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<2Y>', WorkDate()); // move to clean year.
        ProfileQuestionnaireCode := CreateQuestionnairesHeaderWithContactType(ProfileQuestionnaireHeader."Contact Type"::Companies);

        // [GIVEN] Question with "Classification Method" = "Percentage of Value"
        CreateQuestionnairesLineQuestion(
          ProfileQuestionnaireLine, ProfileQuestionnaireCode, ProfileQuestionnaireLine."Contact Class. Field"::" ");
        UpdateVendorClass(ProfileQuestionnaireLine, ProfileQuestionnaireLine."Vendor Class. Field"::"Purchase (LCY)");
        UpdateQuestionClassificationMethod(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine."Classification Method"::"Percentage of Value");

        // [GIVEN] "Answer 1" with range = [0;20]
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0, 20);
        // [GIVEN] "Answer 2" with range = [21;40]
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 21, 40);
        // [GIVEN] "Answer 3" with range = [41;100]
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 41, 100);

        // [GIVEN] Posted invoice with Amount = 100 for contact "C1"
        // [GIVEN] Posted invoice with Amount = 200 for contact "C2"
        // [GIVEN] Posted invoice with Amount = 300 for contact "C3"
        for Index := 1 to ArrayLen(VendorNo) do begin
            CreateVendorWithContact(VendorNo[Index], ContactNo[Index]);
            PostPurchaseInvoice(VendorNo[Index], InvoiceAmount * Index);
        end;

        // [WHEN] Run the Update Classification Report to update answers
        UpdateClassification(ProfileQuestionnaireCode);

        WorkDate := OldWorkDate;

        // [THEN] Total amount = 600
        // [THEN] Contact "C1" is only included in "Answer 1" => 100 / 600 => 0% .. 16.67% .. 20%
        // [THEN] Contact "C2" is only included in "Answer 2" => 200 / 600 => 21% .. 33.33% .. 40%
        // [THEN] Contact "C3" is only included in "Answer 3" => 300 / 600 => 41% .. 50% .. 100%
        ContactProfileAnswer.Init();
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        for Index := 1 to ArrayLen(ContactNo) do begin
            ContactProfileAnswer.SetRange("Contact No.", ContactNo[Index]);
            ContactProfileAnswer.SetRange("Line No.", ProfileQuestionnaireLine."Line No.");
            Assert.RecordIsNotEmpty(ContactProfileAnswer);
            ContactProfileAnswer.SetFilter("Line No.", '<>%1', ProfileQuestionnaireLine."Line No.");
            Assert.RecordIsEmpty(ContactProfileAnswer);
            ProfileQuestionnaireLine.Next();
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Profiling");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Profiling");

        LibrarySales.SetCreditWarningsToNoWarnings();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Profiling");
    end;

    local procedure AddContact(SegmentHeader: Record "Segment Header"; ProfileQuestionnaireCode: Code[10])
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        LibraryVariableStorageVariant: Codeunit "Library - Variable Storage";
    begin
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);

        LibraryVariableStorageVariant.Enqueue(SegmentHeader);
        LibraryVariableStorageVariant.Enqueue(ContactProfileAnswer);
        LibraryMarketing.RunAddContactsReport(LibraryVariableStorageVariant, false);
    end;

    local procedure InitializeFromValueAndToValue(var NoOfDecimals: Integer; var FromValue: Decimal; var ToValue: Decimal)
    begin
        NoOfDecimals := LibraryRandom.RandInt(7);
        FromValue := LibraryRandom.RandDec(50, NoOfDecimals);
        ToValue := FromValue + LibraryRandom.RandDec(50, NoOfDecimals);
    end;

    local procedure CreateQuestionnairesHeader(): Code[10]
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
    begin
        exit(CreateQuestionnairesHeaderWithContactType(ProfileQuestionnaireHeader."Contact Type"::People));
    end;

    local procedure CreateQuestionnairesHeaderWithContactType(ContactType: Enum "Profile Questionnaire Contact Type"): Code[10]
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
    begin
        LibraryMarketing.CreateQuestionnaireHeader(ProfileQuestionnaireHeader);
        ProfileQuestionnaireHeader.Validate(Priority, ProfileQuestionnaireHeader.Priority::Normal);
        ProfileQuestionnaireHeader.Validate("Contact Type", ContactType);
        ProfileQuestionnaireHeader.Modify(true);
        exit(ProfileQuestionnaireHeader.Code);
    end;

    local procedure CreateQuestionnairesLines(ProfileQuestionnaireCode: Code[10]; ContactClass: Enum "Profile Quest. Cont. Class. Field")
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Create Questionnaires Lines of Type Question and Answer.
        CreateQuestionnairesLineQuestion(ProfileQuestionnaireLine, ProfileQuestionnaireCode, ContactClass);

        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, LibraryRandom.RandInt(10));
    end;

    local procedure CreateQuestionnairesLineQuestion(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ProfileQuestionnaireCode: Code[10]; ContactClass: Enum "Profile Quest. Cont. Class. Field")
    begin
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);
        UpdateQuestionnairesLineClass(ProfileQuestionnaireLine, true, ContactClass);
    end;

    local procedure CreateVendorWithContact(var VendorNo: Code[20]; var ContactNo: Code[20])
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        CreateContsFromVendors: Report "Create Conts. from Vendors";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();
        CreateContsFromVendors.UseRequestPage(false);
        CreateContsFromVendors.SetTableView(Vendor);
        CreateContsFromVendors.Run();

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();
        ContactNo := ContactBusinessRelation."Contact No.";
        VendorNo := Vendor."No.";
    end;

    local procedure PerformNextOnWizard(var TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary; FromValue: Decimal; ToValue: Decimal)
    begin
        TempProfileQuestionnaireLine.Validate("Wizard From Value", FromValue);
        TempProfileQuestionnaireLine.Validate("Wizard To Value", ToValue);
        NextStepToDoWizard(TempProfileQuestionnaireLine);
    end;

    local procedure PostPurchaseInvoice(VendorNo: Code[20]; InvoiceAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", InvoiceAmount);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure QuestionnairesLinesCustClass(ProfileQuestionnaireCode: Code[10]; CustomerClass: Enum "Profile Quest. Cust. Class. Field")
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Create Questionnaires Lines of Type Question and Answer. Update Customer Class as per parameter on Type Question.
        CreateQuestionnairesLineQuestion(
          ProfileQuestionnaireLine, ProfileQuestionnaireCode, ProfileQuestionnaireLine."Contact Class. Field"::" ");

        UpdateCustomerClass(ProfileQuestionnaireLine, CustomerClass);

        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(
          ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, LibraryRandom.RandIntInRange(100, 200));
    end;

    local procedure QuestionnairesLinesWOClass(ProfileQuestionnaireCode: Code[10])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Create Questionnaires Lines of Type Question and Answer.
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0);
    end;

    local procedure QuestionnairesLinesWOClassWithMultipleAnswerOptions(ProfileQuestionnaireCode: Code[10])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        // Create Questionnaires Lines of Type Question and two Answer options.
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);  // The question does not allow Multiple Answers.
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, 0);
    end;

    local procedure CreateQuestionnairesLinesWithValues(ProfileQuestionnaireCode: Code[10]; var FromValue: Decimal; var ToValue: Decimal)
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        NoOfDecimals: Integer;
    begin
        // Create Questionnaires Lines of Type Question and two Answer options.
        InitializeFromValueAndToValue(NoOfDecimals, FromValue, ToValue);

        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Question, 0);

        ProfileQuestionnaireLine.Validate("No. of Decimals", NoOfDecimals);
        ProfileQuestionnaireLine.Modify(true);

        LibraryVariableStorage.Enqueue(FromValue);
        LibraryVariableStorage.Enqueue(ToValue);

        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, FromValue, ToValue);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        UpdateQuestionnairesLineWithFromValue(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, FromValue, ToValue);
    end;

    local procedure FindProfileQuestionnaireLine(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ProfileQuestionnaireCode: Code[20])
    begin
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        ProfileQuestionnaireLine.SetRange(Type, ProfileQuestionnaireLine.Type::Answer);
        ProfileQuestionnaireLine.FindFirst();
    end;

    local procedure FindFirstQuestionOnProfileQuestionnaireLine(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ProfileQuestionnaireCode: Code[20])
    begin
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        ProfileQuestionnaireLine.SetRange(Type, ProfileQuestionnaireLine.Type::Question);
        ProfileQuestionnaireLine.FindFirst();
    end;

    local procedure FinishStepToDoWizard(var TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary)
    begin
        TempProfileQuestionnaireLine.Modify();
        TempProfileQuestionnaireLine.CheckStatus();
        TempProfileQuestionnaireLine.FinishWizard();
    end;

    local procedure ManuallySetAnswerOnContProfile(ProfileQuestionnaireCode: Code[10])
    var
        Contact: Record Contact;
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ContactProfileAnswers: Page "Contact Profile Answers";
    begin
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);

        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Company No.", '<>''''');
        Contact.FindFirst();

        ContactProfileAnswers.SetTableView(ProfileQuestionnaireLine);
        ContactProfileAnswers.SetRunFromForm(ProfileQuestionnaireLine, Contact, ProfileQuestionnaireCode);
        ContactProfileAnswers.RunModal();
    end;

    local procedure NextStepToDoWizard(var TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary)
    begin
        TempProfileQuestionnaireLine.Modify();
        TempProfileQuestionnaireLine.CheckStatus();
        TempProfileQuestionnaireLine.PerformNextWizardStatus();
    end;

    local procedure UpdateClassification(ProfileQuestionnaireCode: Code[10])
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        UpdateContactClassification: Report "Update Contact Classification";
    begin
        ProfileQuestionnaireHeader.SetRange(Code, ProfileQuestionnaireCode);
        UpdateContactClassification.SetTableView(ProfileQuestionnaireHeader);
        UpdateContactClassification.UseRequestPage(false);
        UpdateContactClassification.RunModal();
    end;

    local procedure UpdateCustomerClass(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; CustomerClass: Enum "Profile Quest. Cust. Class. Field")
    begin
        ProfileQuestionnaireLine.Validate("Customer Class. Field", CustomerClass);
        Evaluate(ProfileQuestionnaireLine."Starting Date Formula", DateFormulaStartDayTok);
        Evaluate(ProfileQuestionnaireLine."Ending Date Formula", DateFormulaCurrentDayTok);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure UpdateVendorClass(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; VendorClass: Enum "Profile Quest. Vend. Class. Field")
    begin
        ProfileQuestionnaireLine.Validate("Vendor Class. Field", VendorClass);
        Evaluate(ProfileQuestionnaireLine."Starting Date Formula", DateFormulaStartDayTok);
        Evaluate(ProfileQuestionnaireLine."Ending Date Formula", DateFormulaCurrentDayTok);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure UpdateQuestionClassificationMethod(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ClassificationMethod: Option)
    begin
        ProfileQuestionnaireLine.Validate("Classification Method", ClassificationMethod);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure UpdateQuestionnairesLineType(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; Type: Enum "Profile Questionnaire Line Type"; ToValue: Decimal)
    begin
        ProfileQuestionnaireLine.Validate(
          Description,
          CopyStr(
            LibraryUtility.GenerateRandomCode(ProfileQuestionnaireLine.FieldNo(Description), DATABASE::"Profile Questionnaire Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Profile Questionnaire Line", ProfileQuestionnaireLine.FieldNo(Description))));

        ProfileQuestionnaireLine.Validate(Type, Type);
        ProfileQuestionnaireLine.Validate("To Value", ToValue);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure UpdateQuestionnairesLineClass(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; AutoContactClassification: Boolean; ContactClassField: Enum "Profile Quest. Cont. Class. Field")
    begin
        ProfileQuestionnaireLine.Validate("Auto Contact Classification", AutoContactClassification);
        ProfileQuestionnaireLine.Validate("Contact Class. Field", ContactClassField);
        Evaluate(ProfileQuestionnaireLine."Starting Date Formula", DateFormulaStartDayTok);
        Evaluate(ProfileQuestionnaireLine."Ending Date Formula", DateFormulaCurrentDayTok);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure UpdateQuestionnairesLineWithFromValue(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; Type: Enum "Profile Questionnaire Line Type"; FromValue: Decimal; ToValue: Decimal)
    begin
        UpdateQuestionnairesLineType(ProfileQuestionnaireLine, Type, ToValue);
        ProfileQuestionnaireLine.Validate("From Value", FromValue);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure VerifyAnswerRating(ProfileQuestionnaireCode: Code[10]; FromValue: Decimal; ToValue: Decimal)
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        ProfileQuestionnaireLine.TestField("From Value", FromValue);
        ProfileQuestionnaireLine.TestField("To Value", ToValue);
    end;

    local procedure VerifyContactsOnSegmentLine(SegmentNo: Code[20]; ProfileQuestionnaireCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        ContactProfileAnswer: Record "Contact Profile Answer";
    begin
        SegmentLine.SetRange("Segment No.", SegmentNo);
        SegmentLine.FindFirst();
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        ContactProfileAnswer.FindFirst();
        SegmentLine.TestField("Contact No.", ContactProfileAnswer."Contact No.");
    end;

    local procedure VerifyCriteriaActionOnSegment(SegmentNo: Code[20])
    var
        SegmentHeader: Record "Segment Header";
    begin
        SegmentHeader.Get(SegmentNo);
        SegmentHeader.CalcFields("No. of Criteria Actions");
        SegmentHeader.TestField("No. of Criteria Actions", 1);  // Validates that Critria has been set on the Segment.
    end;

    local procedure VerifyNoOfContacts(ProfileQuestionnaireCode: Code[10])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ContactProfileAnswer: Record "Contact Profile Answer";
    begin
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireCode);
        Assert.IsFalse(ContactProfileAnswer.IsEmpty, ContactClassificationErr);
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        ProfileQuestionnaireLine.CalcFields("No. of Contacts");
        ProfileQuestionnaireLine.TestField("No. of Contacts", ContactProfileAnswer.Count);
    end;

    local procedure VerifyNoOfContactsManualAssign(ProfileQuestionnaireCode: Code[10])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);
        ProfileQuestionnaireLine.CalcFields("No. of Contacts");
        ProfileQuestionnaireLine.TestField("No. of Contacts", 1);  // Contact Assigned to Profile Questionnaire line.
    end;

    local procedure VerifyQuestionariesLineFromValueAndToValue(ProfileQuestionnaireCode: Code[10]; FromValue: Variant; ToValue: Variant)
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        FindProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireCode);

        Assert.AreEqual(
          FromValue,
          ProfileQuestionnaireLine."From Value",
          StrSubstNo(IncorrectFieldValueErr, ProfileQuestionnaireLine.FieldCaption("From Value")));
        Assert.AreEqual(
          ToValue,
          ProfileQuestionnaireLine."To Value",
          StrSubstNo(IncorrectFieldValueErr, ProfileQuestionnaireLine.FieldCaption("To Value")));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerCreateRating(var CreateRating: Page "Create Rating"; var Response: Action)
    var
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
        WizardFromValue: Decimal;
        WizardToValue: Decimal;
    begin
        TempProfileQuestionnaireLine.Init();
        CreateRating.GetRecord(TempProfileQuestionnaireLine);
        TempProfileQuestionnaireLine.Insert();  // Use of Insert in case of Temporary Table.

        TempProfileQuestionnaireLine.Validate(Description, TempProfileQuestionnaireLine."Profile Questionnaire Code");
        TempProfileQuestionnaireLine.Validate("Min. % Questions Answered", LibraryRandom.RandInt(10));  // Value is not important for the test Case.
        NextStepToDoWizard(TempProfileQuestionnaireLine);

        TempProfileQuestionnaireLine.Validate("Answer Option", TempProfileQuestionnaireLine."Answer Option"::ABC);
        TempProfileQuestionnaireLine.ValidateAnswerOption();
        NextStepToDoWizard(TempProfileQuestionnaireLine);

        WizardFromValue := LibraryVariableStorage.DequeueDecimal();
        WizardToValue := LibraryVariableStorage.DequeueDecimal();

        PerformNextOnWizard(TempProfileQuestionnaireLine, WizardFromValue, WizardToValue);
        PerformNextOnWizard(TempProfileQuestionnaireLine, WizardFromValue, WizardToValue);
        PerformNextOnWizard(TempProfileQuestionnaireLine, WizardFromValue, WizardToValue);

        FinishStepToDoWizard(TempProfileQuestionnaireLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerAnswerPoints(var AnswerPoints: Page "Answer Points"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerSegCriteria(var SaveSegmentCriteria: Page "Save Segment Criteria"; var Response: Action)
    var
        SavedSegmentCriteria: Record "Saved Segment Criteria";
        SegmentCriteria: Code[10];
    begin
        SegmentCriteria :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(SavedSegmentCriteria.FieldNo(Code), DATABASE::"Saved Segment Criteria"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Profile Questionnaire Line", SavedSegmentCriteria.FieldNo(Code)));

        LibraryVariableStorage.Enqueue(SegmentCriteria);

        SaveSegmentCriteria.SetValues(ACTION::OK, SegmentCriteria, SegmentCriteria);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFrmHandleSavedSegCriteria(var SavedSegmentCriteriaList: Page "Saved Segment Criteria List"; var Response: Action)
    var
        SavedSegmentCriteria: Record "Saved Segment Criteria";
    begin
        SavedSegmentCriteria.SetRange(Code, LibraryVariableStorage.DequeueText());
        SavedSegmentCriteria.FindFirst();
        SavedSegmentCriteriaList.SetRecord(SavedSegmentCriteria);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormContactProfileAnswers(var ContactProfileAnswers: Page "Contact Profile Answers"; var Response: Action)
    begin
        ContactProfileAnswers.UpdateProfileAnswer();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SettingTwoAnswerUnCheckOneOnQuestionnaireHandler(var ContactProfAnswers: TestPage "Contact Profile Answers")
    begin
        ContactProfAnswers.Set.SetValue(true);
        ContactProfAnswers.Next();
        asserterror ContactProfAnswers.Set.SetValue(true);
        ContactProfAnswers.Set.SetValue(false);
        ContactProfAnswers.OK().Invoke(); // No error pops up after uncheck the 2nd answer.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckQuestionThenUndoOnQuestionnaireHandler(var ContactProfAnswers: TestPage "Contact Profile Answers")
    begin
        asserterror ContactProfAnswers.Set.SetValue(true);
        ContactProfAnswers.Set.SetValue(false); // No error pops up after uncheck the question.
        ContactProfAnswers.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProfileQuestionnaireSetupPageHandler(var TestPage: TestPage "Profile Questionnaire Setup")
    var
        FromValue: Variant;
        ToValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FromValue);
        LibraryVariableStorage.Dequeue(ToValue);

        TestPage.First();
        TestPage.Next();
        TestPage."From Value".SetValue(FromValue);
        TestPage."To Value".SetValue(ToValue);

        TestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnswerPointsModalPageHandler(var AnswerPoints: TestPage "Answer Points")
    begin
        AnswerPoints.OK().Invoke();
    end;
}

