codeunit 136901 "Marketing Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Marketing]
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        CampaignNo2: Code[20];
        ContactNo2: Code[20];
        OpportunityNo: Code[20];
        InteractionTemplateCode: Code[10];
        TeamCode: Code[10];
        CurrentSalesCycleStage: Integer;
        NoAnswerError: Label 'No Answer created.';
        UnexpectedNumberOfRecordsError: Label 'Unexpected number of records in %1. Number of records must be %2', Comment = '%1 = Table Caption %2 = Number of records';
        FilterNotFoundinXMLErr: Label 'Field: %1 Value:%2 not found in xml', Locked = true;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Reports");
        Clear(LibraryReportDataset);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Reports");

        LibraryService.SetupServiceMgtNoSeries();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Reports");
    end;

    [Test]
    [HandlerFunctions('SegmentContactsReportHandler')]
    [Scope('OnPrem')]
    procedure SegmentContactsReport()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Cost (LCY) and Estimated Value (LCY) on Segment Contacts Report.

        // 1. Setup: Find Contact, Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run the Segment Contacts Report.
        RunSegmentContactsReport(SegmentHeader."No.");

        // 3. Verify: Verify Cost (LCY) and Estimated Value (LCY) on Segment Contacts report.
        VerifyCostAndEstimatedValue(Contact);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,OppurtunityDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure OpportunityDetailsReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Test Sales Cycle Stage and Activity Step on Opportunity Report.

        // 1. Setup: Create Contact with Salesperson, Activity, Activity Step, Sales Cycle, Sales Cycle Stage and Create Opportunity
        // for the Contact.
        Initialize();
        CreateContactWithSalesperson(Contact);
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);
        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");

        // 2. Exercise: Run Opportunity Details Report.
        RunOpportunityDetails(Contact."No.");

        // 3. Verify: Verify Description and Priority on Opportunity Report is Description of Sales Cycle Stage and Priority of Activity
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Stage_SalesCycleStage', Format(SalesCycleStage.Stage));

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Desc_SalescCycleStage', SalesCycleStage.Description);
        VerifyActivityStepOnReport(Activity.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ContactCompanySummaryReportHandler')]
    [Scope('OnPrem')]
    procedure ContactCompanySummary()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        ContactCompanySummary: Report "Contact - Company Summary";
    begin
        // Test that Contact of Type Peson related to another contact, seen properly in Contact Company Summary.

        // 1. Setup: Create two Contacts, one as Company and another as Person.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateContactAsPerson(Contact2);
        UpdateCompanyNo(Contact2, Contact."No.");

        // 2. Exercise: Generate the Contact Company Summary Report.
        Clear(ContactCompanySummary);
        Contact.SetRange("No.", Contact."No.");
        ContactCompanySummary.SetTableView(Contact);
        Commit();
        ContactCompanySummary.Run();

        // 3. Verify: Check that Contact of Type Peson related to another contact, seen properly in Contact Company Summary.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContactPerson___No__', Contact2."No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ContactPerson__Name', Contact2.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('Contact__Company_No__', Contact.Name);
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalPageHandler,CampaignDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure CampaignDetailsReport()
    var
        Campaign: Record Campaign;
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        CampaignEntry: Record "Campaign Entry";
        CampaignDetails: Report "Campaign - Details";
    begin
        // Test that values of Description, No. in Campaign - Details matches the value of Description,No. in corresponding Campaign.

        // 1. Setup: Create new Campaign Status and Campaign. Link the Campaign Status to the Campaign.Create Segment Header and also
        // Create new Interaction Template with Unit Cost (LCY) and Unit Duration (Min.).Create Interaction for a Contact.
        Initialize();
        CreateCampaignWithStatus(Campaign);
        CreateSegmentHeader(SegmentHeader, Campaign."No.");
        CreateInteractionTemplate(InteractionTemplate);
        Contact.SetFilter("Salesperson Code", '<>%1', '');
        Contact.FindFirst();
        ContactNo2 := Contact."No.";  // Assign Global variable for page handler.
        Contact.CreateInteraction();
        CampaignEntry.SetRange("Campaign No.", Campaign."No.");
        CampaignEntry.FindFirst();

        // 2. Exercise: Generate Campaign - Details Report.
        Clear(CampaignDetails);
        Campaign.SetRange("No.", Campaign."No.");
        CampaignDetails.SetTableView(Campaign);
        Commit();
        CampaignDetails.Run();

        // 3. Verify: Verify that the Campaign - Details Report print the correct Campaign and Segment Header Values.
        VerifyCampaign(Campaign, SegmentHeader, CampaignEntry);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerTask,ModalPageHandlerOpportunity,SalespersonTasksReportHandler')]
    [Scope('OnPrem')]
    procedure SalespersonTasksReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        SalesCycleStage: Record "Sales Cycle Stage";
        Contact: Record Contact;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Opportunity: Record Opportunity;
        SalespersonTasks: Report "Salesperson - Tasks";
    begin
        // Test Task details for Salesperson on Salesperson To Dos Report.

        // 1. Setup: Create Contact with Salesperson, Activity, Activity Step, Sales Cycle, Opportunity and Create Task.
        Initialize();
        CreateContactWithSalesperson(Contact);
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);
        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        OpportunityNo := Opportunity."No.";  // Assign Global Variable for page handler.
        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run the Salesperson To Dos Report.
        Clear(SalespersonTasks);
        Task.SetRange("Salesperson Code", Contact."Salesperson Code");
        SalespersonTasks.SetTableView(Task);
        Commit();
        SalespersonTasks.Run();

        // 3. Verify: Verify Task details on Salesperson To Dos Report.
        Task.FindFirst();
        VerifyTaskDetails(Task);
        LibraryReportDataset.AssertCurrentRowValueEquals('Task__Opportunity_No__', Task."Opportunity No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,SalesOpportunitiesReportHandler')]
    [Scope('OnPrem')]
    procedure SalespersonOpportunitiesReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        SalesCycleStage: Record "Sales Cycle Stage";
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalespersonOpportunities: Report "Salesperson - Opportunities";
    begin
        // Test Opportunity details on Salesperson Opportunities Report.

        // 1. Setup: Create Contact with Salesperson, Activity, Activity Step, Sales Cycle, Sales Cycle Stage, Create and Update
        // Opportunity.
        Initialize();
        CreateContactWithSalesperson(Contact);
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);
        CurrentSalesCycleStage := SalesCycleStage.Stage;  // Assign Global Variable for page handler.
        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        UpdateOpportunity(Contact."No.");

        // 2. Exercise: Run the Salesperson Opportunities Report.
        Commit();
        Clear(SalespersonOpportunities);
        Opportunity.SetRange("Salesperson Code", Contact."Salesperson Code");
        SalespersonOpportunities.SetTableView(Opportunity);
        SalespersonOpportunities.Run();

        // 3. Verify: Verify Opportunity details on Salesperson Opportunities Report.
        VerifyOpportunityDetails(Contact."Salesperson Code");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTeamTask,TeamTasksReportHandler')]
    [Scope('OnPrem')]
    procedure TeamTasksReport()
    var
        Contact: Record Contact;
        Team: Record Team;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        TeamTasks: Report "Team - Tasks";
    begin
        // Test Task details for Team on Team To Dos Report.

        // 1. Setup: Create Team, Contact with Salesperson and Create Task.
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        CreateContactWithSalesperson(Contact);
        TeamCode := Team.Code;  // Set global variable for Page Handler.
        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run the Team To Dos Report.
        Clear(TeamTasks);
        Commit();
        Task.SetRange("Team Code", Team.Code);
        TeamTasks.SetTableView(Task);
        TeamTasks.Run();

        // 3. Verify: Verify Task details on Team To Dos Report.
        Task.FindFirst();
        VerifyTaskDetails(Task);
        LibraryReportDataset.AssertCurrentRowValueEquals('Task__Salesperson_Code_', Task."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('QuestionnaireHandoutsReportHandler')]
    [Scope('OnPrem')]
    procedure QuestionnaireSingleAnswer()
    begin
        // Test Questionnaire details on Questionnaire Handouts Report with Multiple Answers False on Questionnaire Line.

        Questionnaire(false);
    end;

    [Test]
    [HandlerFunctions('QuestionnaireHandoutsReportHandler')]
    [Scope('OnPrem')]
    procedure QuestionnaireMultipleAnswer()
    begin
        // Test Questionnaire details on Questionnaire Handouts Report with Multiple Answers True on Questionnaire Line.

        Questionnaire(true);
    end;

    local procedure Questionnaire(MultipleAnswers: Boolean)
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        QuestionnaireHandouts: Report "Questionnaire - Handouts";
    begin
        // 1. Setup: Create Questionnaire Header and Questionnaire Line with Multiple Answers as per parameter.
        Initialize();
        CreateQuestionnaire(ProfileQuestionnaireLine);
        ModifyQuestionnaireLine(ProfileQuestionnaireLine, MultipleAnswers);

        // 2. Exercise: Run the Questionnaire Handouts Report.
        Clear(QuestionnaireHandouts);
        Commit();
        ProfileQuestionnaireHeader.SetRange(Code, ProfileQuestionnaireLine."Profile Questionnaire Code");
        QuestionnaireHandouts.SetTableView(ProfileQuestionnaireHeader);
        QuestionnaireHandouts.Run();

        // 3. Verify: Verify Questionnaire details on Questionnaire Handouts Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(
          'Profile_Questionnaire_Header_Code',
          ProfileQuestionnaireLine."Profile Questionnaire Code");
        LibraryReportDataset.GetNextRow();
        VerifyQuestionnaireDescription(ProfileQuestionnaireLine);
    end;

    [Test]
    [HandlerFunctions('QuestionnaireTestReportHandler')]
    [Scope('OnPrem')]
    procedure QuestionnaireTestReport()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        QuestionnaireTest: Report "Questionnaire - Test";
    begin
        // Test Questionnaire details on Questionnaire Test Report.

        // 1. Setup: Create Questionnaire Header and Questionnaire Line.
        Initialize();
        CreateQuestionnaire(ProfileQuestionnaireLine);
        ModifyQuestionnaireLine(ProfileQuestionnaireLine, false);

        // 2. Exercise: Run the Questionnaire Test Report.
        Commit();
        Clear(QuestionnaireTest);
        ProfileQuestionnaireHeader.SetRange(Code, ProfileQuestionnaireLine."Profile Questionnaire Code");
        QuestionnaireTest.SetTableView(ProfileQuestionnaireHeader);
        QuestionnaireTest.Run();

        // 3. Verify: Verify Questionnaire details on Questionnaire Test Report.
        VerifyQuestionnaireDetails(ProfileQuestionnaireLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('ErrorText_Number_', Format(NoAnswerError));
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerTask,CreateInteractModalPageHandler,ContactPersonSummaryReportHandler')]
    [Scope('OnPrem')]
    procedure ContactPersonSummary()
    var
        Contact: Record Contact;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        InteractionTemplate: Record "Interaction Template";
        ContactPersonSummary: Report "Contact - Person Summary";
    begin
        // Test To Do and Interaction details on Contact Person Summary Report.

        // 1. Setup: Create Contact with Type Person, To Do and Interaction for Contact.
        Initialize();
        CreateContactAsPerson(Contact);
        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        ContactNo2 := Contact."No.";  // Assign Global variable for page handler.
        CreateInteractionTemplate(InteractionTemplate);
        Contact.CreateInteraction();

        // 2. Exercise: Run Contact Person Summary Report.
        Commit();
        Clear(ContactPersonSummary);
        Contact.SetRange("No.", Contact."No.");
        ContactPersonSummary.SetTableView(Contact);
        ContactPersonSummary.Run();

        // 3. Verify: Verify To Do and Interaction details on Contact Person Summary Report.
        Task.FindFirst();
        VerifyTaskOnPersonSummary(Task);
        VerifyInteractionLogEntry(Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactCoverSheetWithText()
    var
        Contact: Record Contact;
        ContactCoverSheet: Report "Contact - Cover Sheet";
        Text: array[5] of Text[100];
    begin
        // Test Contact Cover Sheet Report with Texts.

        // 1. Setup: Find Contact and Create Texts.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateTexts(Text);

        // 2. Exercise: Run Contact Cover Sheet Report.
        Commit();
        Contact.SetRange("No.", Contact."No.");
        Clear(ContactCoverSheet);
        ContactCoverSheet.SetTableView(Contact);
        ContactCoverSheet.InitializeText(Text[1], Text[2], Text[3], Text[4], Text[5]);
        ContactCoverSheet.Run();

        // 3. Verify: Verify Texts on Contact Cover Sheet Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContactNo', Contact."No.");
        LibraryReportDataset.GetNextRow();
        VerifyTextsOnReport(Text);
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetAsAgreedUpon()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with As Agreed upon True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with As Agreed upon True.
        RunContactCoverSheetReport(Contact."No.",
          true, false, false,
          false, false, false);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(1, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetForYourInformation()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with For Your Information True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with For Your Information True.
        RunContactCoverSheetReport(Contact."No.",
          false, true, false,
          false, false, false);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(2, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetYourCommentsPlease()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with Your Comments Please True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with Your Comments Please True.
        RunContactCoverSheetReport(Contact."No.",
          false, false, true,
          false, false, false);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(3, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetForYourApproval()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with For Your Approval True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with For Your Approval True.
        RunContactCoverSheetReport(Contact."No.",
          false, false, false,
          true, false, false);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(4, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetPleaseCall()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with Please Call True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with Please Call True.
        RunContactCoverSheetReport(Contact."No.",
          false, false, false,
          false, true, false);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(5, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetReturnedAfterUse()
    var
        Contact: Record Contact;
    begin
        // Test Contact Cover Sheet Report with Returned After Use True.

        // 1. Setup: Find Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);

        // 2. Exercise: Run Contact Cover Sheet Report with Returned After Use True.
        RunContactCoverSheetReport(Contact."No.",
          false, false, false,
          false, false, true);

        // 3. Verify: Verify Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(6, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactSheetCustomRemarks()
    var
        Contact: Record Contact;
        ContactCoverSheet: Report "Contact - Cover Sheet";
        Text: Text[100];
    begin
        // Test Contact Cover Sheet Report with Custom Remarks.

        // 1. Setup: Find Contact and Create Text.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        Text := LibraryUtility.GenerateGUID();

        // 2. Exercise: Run Contact Cover Sheet Report with Custom Remarks.
        Commit();
        Contact.SetRange("No.", Contact."No.");
        Clear(ContactCoverSheet);
        ContactCoverSheet.SetTableView(Contact);
        ContactCoverSheet.InitializeCustomRemarks(true, Text);
        ContactCoverSheet.Run();

        // 3. Verify: Verify Custom Remarks on Contact Cover Sheet Report.
        VerifyRemarkOnContactReport(7, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentCoverSheetWithText()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentCoverSheet: Report "Segment - Cover Sheet";
        Text: array[5] of Text[100];
    begin
        // Test Segment Cover Sheet Report with Texts.

        // 1. Setup: Create Segment Header, Segment Line with Contact and Create Texts.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");
        CreateTexts(Text);

        // 2. Exercise: Run Segment Cover Sheet Report.
        Commit();
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        Clear(SegmentCoverSheet);
        SegmentCoverSheet.SetTableView(SegmentHeader);
        SegmentCoverSheet.InitializeText(Text[1], Text[2], Text[3], Text[4], Text[5]);
        SegmentCoverSheet.Run();

        // 3. Verify: Verify Texts on Segment Cover Sheet Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Contact_No_', Contact."No.");
        LibraryReportDataset.GetNextRow();
        VerifyTextsOnReport(Text);
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetAsAgreedUpon()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with As Agreed Upon True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with As Agreed Upon True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          true, false, false,
          false, false, false);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(1, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetForYourInformation()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with For Your Information True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with For Your Information True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          false, true, false,
          false, false, false);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(2, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetYourCommentsPlease()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with Your Comments Please True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with Your Comments Please True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          false, false, true,
          false, false, false);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(3, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetForYourApproval()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with For Your Approval True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with For Your Approval True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          false, false, false,
          true, false, false);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(4, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetPleaseCall()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with Please Call True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with Please Call True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          false, false, false,
          false, true, false);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(5, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetReturnedAfterUse()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
    begin
        // Test Segment Cover Sheet Report with Returned After Use True.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");

        // 2. Exercise: Run Segment Cover Sheet Report with Returned After Use True.
        RunSegmentCoverSheetReport(SegmentHeader."No.",
          false, false, false,
          false, false, true);

        // 3. Verify: Verify Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(6, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('SegmentCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentSheetCustomRemarks()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentCoverSheet: Report "Segment - Cover Sheet";
        Text: Text[100];
    begin
        // Test Segment Cover Sheet Report with Custom Remarks.

        // 1. Setup: Create Segment Header and Segment Line with Contact.
        Initialize();
        LibraryMarketing.FindContact(Contact);
        CreateSegmentWithContact(SegmentHeader, Contact."No.");
        Text := LibraryUtility.GenerateGUID();

        // 2. Exercise: Run Segment Cover Sheet Report with Custom Remarks.
        Commit();
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        Clear(SegmentCoverSheet);
        SegmentCoverSheet.SetTableView(SegmentHeader);
        SegmentCoverSheet.InitializeCustomRemarks(true, Text);
        SegmentCoverSheet.Run();

        // 3. Verify: Verify Custom Remarks on Segment Cover Sheet Report.
        VerifyRemarkOnSegmentCoverSheetReport(7, Contact."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalPageHandler,ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,ContactListReportHandler')]
    [Scope('OnPrem')]
    procedure ContactListReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        SalesCycleStage: Record "Sales Cycle Stage";
        ContactList: Report "Contact - List";
    begin
        // Test and verify Contact List Report.

        // 1. Setup: Create Contact with Salesperson, Interaction Template, Interaction from Contact, Activity, Activity Step,
        // Sales Cycle Stage, Opportunity from Contact, Update Opportunity.
        Initialize();
        InitGlobalVariables();
        CreateContactWithSalesperson(Contact);
        CreateInteractionTemplate(InteractionTemplate);

        ContactNo2 := Contact."No."; // Assign Global Variable for page handler.
        Contact.CreateInteraction();
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);

        CurrentSalesCycleStage := SalesCycleStage.Stage; // Assign Global Variable for page handler.

        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        UpdateOpportunity(Contact."No.");

        // 2. Exercise: Run Contact List Report.
        Commit();
        Contact.SetRange("No.", Contact."No.");
        Clear(ContactList);
        ContactList.SetTableView(Contact);
        ContactList.Run();

        // 3. Verify: Verify Values on Contact List Report.
        VerifyValuesonContactList(Contact);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalPageHandler,ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,OpportunityListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityListReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        OpportunityList: Report "Opportunity - List";
    begin
        // Test and verify Opportunity List Report.

        // 1. Setup: Create Contact with Salesperson, Interaction Template, Interaction from Contact, Activity, Activity Step,
        // Sales Cycle Stage, Opportunity from Contact, Update Opportunity.
        Initialize();
        InitGlobalVariables();
        CreateContactWithSalesperson(Contact);
        CreateInteractionTemplate(InteractionTemplate);

        ContactNo2 := Contact."No."; // Assign Global Variable for page handler.
        Contact.CreateInteraction();
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);

        CurrentSalesCycleStage := SalesCycleStage.Stage; // Assign Global Variable for page handler.

        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        UpdateOpportunity(Contact."No.");

        // 2. Exercise: Run Opportunity List Report.
        Commit();
        Opportunity.SetRange("Contact No.", Contact."No.");
        Clear(OpportunityList);
        OpportunityList.SetTableView(Opportunity);
        OpportunityList.Run();

        // 3. Verify: Verify Values on Opportunity List Report.
        Opportunity.FindFirst();
        VerifyValuesonOpportunityList(Opportunity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,OpportunityListToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityListToExcel()
    var
        Activity: Record Activity;
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // [SCENARIO 332702] Run report "Opportunity - List" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Cycle Stage, Opportunity.
        CreateContactWithSalesperson(Contact);
        LibraryMarketing.CreateActivity(Activity);
        CreateSalesCycleStage(SalesCycleStage, Activity.Code);

        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        Commit();

        // [WHEN] Run report "Opportunity - List", save report output to Excel file.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Report.Run(Report::"Opportunity - List", true, false, Opportunity);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 13, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Opportunity - List'), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerOpportunityAction,SalesCycleAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCycleAnalysisReport()
    var
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesCycleAnalysis: Report "Sales Cycle - Analysis";
        CurrentWorkDate: Date;
        FirstSalesCycleStage: Integer;
        SecondSalesCycleStage: Integer;
    begin
        // Test and verify Sales Cycle Analysis Report.

        // 1. Setup: Create Activity, Activity Step, Sales Cycle, First Sales Cycle Stage, First Contact with Salesperson,
        // Opportunity from first Contact, Update Opportunity, Second Contact with Salesperson, Opportunity from Second Contact,
        // Update Opportunity, Second Sales Cycle Stage, Update Opportunity.
        Initialize();
        InitGlobalVariables();
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        CreateSalesCycleSingleStage(SalesCycleStage, SalesCycle.Code, Activity.Code);

        CurrentSalesCycleStage := SalesCycleStage.Stage; // Assign Global Variable for page handler.
        FirstSalesCycleStage := SalesCycleStage.Stage;

        CreateContactWithSalesperson(Contact);
        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");
        UpdateOpportunity(Contact."No.");

        CreateContactWithSalesperson(Contact2);
        LibraryVariableStorage.Enqueue(SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact2."No.");
        UpdateOpportunity(Contact2."No.");

        CreateSalesCycleSingleStage(SalesCycleStage, SalesCycle.Code, Activity.Code);
        CurrentSalesCycleStage := SalesCycleStage.Stage; // Assign Global Variable for page handler.
        SecondSalesCycleStage := SalesCycleStage.Stage;
        CurrentWorkDate := WorkDate();

        // Use Random values for the days.
        WorkDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        UpdateOpportunity(Contact2."No.");

        // 2. Exercise: Run Sales Cycle Analysis Report.
        Commit();
        SalesCycle.SetRange(Code, SalesCycle.Code);
        Clear(SalesCycleAnalysis);
        SalesCycleAnalysis.SetTableView(SalesCycle);
        SalesCycleAnalysis.Run();

        // 3. Verify: Verify Values on Sales Cycle Analysis Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesSalesCycleAnalysis(SalesCycle.Code, FirstSalesCycleStage);
        VerifyValuesSalesCycleAnalysis(SalesCycle.Code, SecondSalesCycleStage);

        // 4. Tear Down: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactCountOnContactCoverSheetReport()
    var
        Contact: Record Contact;
    begin
        // Setup.
        Initialize();

        // Exercise.
        Commit();  // Commit required for Request Page Handler.
        REPORT.Run(REPORT::"Contact - Cover Sheet");

        // Verify.
        Assert.AreEqual(Contact.Count, GetRowCount(), StrSubstNo(UnexpectedNumberOfRecordsError, Contact.TableCaption(), Contact.Count));
    end;

    local procedure CreateCampaignWithStatus(var Campaign: Record Campaign)
    var
        CampaignStatus: Record "Campaign Status";
    begin
        LibraryMarketing.CreateCampaignStatus(CampaignStatus);
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Status Code", CampaignStatus.Code);
        Campaign.Modify(true);
        CampaignNo2 := Campaign."No.";  // Set global variable for form handler.
    end;

    local procedure CreateContactAsPerson(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Modify(true);
    end;

    local procedure CreateContactWithSalesperson(var Contact: Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateSalespersonWithEmail(SalespersonPurchaser);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Modify(true);
    end;

    local procedure CreateInteractionTemplate(var InteractionTemplate: Record "Interaction Template")
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Unit Cost (LCY)", LibraryUtility.GenerateRandomFraction());
        InteractionTemplate.Validate("Unit Duration (Min.)", LibraryUtility.GenerateRandomFraction());
        InteractionTemplate.Modify(true);
        InteractionTemplateCode := InteractionTemplate.Code;  // Set global variable for form handler.
    end;

    local procedure CreateOpportunity(ContactNo: Code[20])
    var
        TempOpportunity: Record Opportunity temporary;
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        TempOpportunity.CreateOppFromOpp(Opportunity);
    end;

    local procedure CreateSegmentHeader(var SegmentHeader: Record "Segment Header"; CampaignNo: Code[20])
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);
    end;

    local procedure CreateSalesCycleStage(var SalesCycleStage: Record "Sales Cycle Stage"; ActivityCode: Code[10])
    var
        SalesCycle: Record "Sales Cycle";
    begin
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
        SalesCycleStage.Validate(Description, SalesCycle.Code);
        SalesCycleStage.Validate("Activity Code", ActivityCode);
        SalesCycleStage.Validate("Completed %", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        SalesCycleStage.Modify(true);
    end;

    local procedure CreateSalesCycleSingleStage(var SalesCycleStage: Record "Sales Cycle Stage"; SalesCycleCode: Code[10]; ActivityCode: Code[10])
    begin
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycleCode);
        SalesCycleStage.Validate(Description, SalesCycleCode);
        SalesCycleStage.Validate("Activity Code", ActivityCode);

        // Use Random because value is not important.
        SalesCycleStage.Validate("Completed %", LibraryRandom.RandDec(100, 2));
        SalesCycleStage.Modify(true);
    end;

    local procedure CreateSegmentWithContact(var SegmentHeader: Record "Segment Header"; ContactNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Modify(true);
    end;

    local procedure CreateSalespersonWithEmail(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        SalespersonPurchaser.Modify(true);
    end;

    local procedure CreateTexts(var Text: array[5] of Text[100])
    var
        Counter: Integer;
    begin
        for Counter := 1 to ArrayLen(Text) do
            Text[Counter] := LibraryUtility.GenerateGUID();
    end;

    local procedure CreateQuestionnaire(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
    begin
        LibraryMarketing.CreateQuestionnaireHeader(ProfileQuestionnaireHeader);
        LibraryMarketing.CreateProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireHeader.Code);
    end;

    local procedure GetRowCount() RowCount: Integer
    begin
        LibraryReportDataset.LoadDataSetFile();
        RowCount := LibraryReportDataset.RowCount();
    end;

    local procedure InitGlobalVariables()
    begin
        CampaignNo2 := '';
        ContactNo2 := '';
        OpportunityNo := '';
        InteractionTemplateCode := '';
        TeamCode := '';
        CurrentSalesCycleStage := 0;
    end;

    local procedure ModifyQuestionnaireLine(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; MultipleAnswers: Boolean)
    begin
        ProfileQuestionnaireLine.Validate(
          Description,
          LibraryUtility.GenerateRandomCode(ProfileQuestionnaireLine.FieldNo(Description), DATABASE::"Profile Questionnaire Line"));
        ProfileQuestionnaireLine.Validate("Multiple Answers", MultipleAnswers);
        ProfileQuestionnaireLine.Modify(true);
    end;

    local procedure RunOpportunityDetails(ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
        OpportunityDetails: Report "Opportunity - Details";
    begin
        Clear(OpportunityDetails);
        Commit();
        Opportunity.SetRange("Contact No.", ContactNo);
        OpportunityDetails.SetTableView(Opportunity);
        // LibraryReportValidation.SetFileName(ContactNo);
        // OpportunityDetails.SAVEASEXCEL(LibraryReportValidation.GetFileName());
        OpportunityDetails.Run();
    end;

    local procedure RunSegmentContactsReport(No: Code[20])
    var
        SegmentHeader: Record "Segment Header";
        SegmentContacts: Report "Segment - Contacts";
    begin
        Clear(SegmentContacts);
        Commit();
        SegmentHeader.SetRange("No.", No);
        SegmentContacts.SetTableView(SegmentHeader);
        SegmentContacts.Run();
    end;

    local procedure UpdateCompanyNo(var Contact: Record Contact; CompanyNo: Code[20])
    begin
        Contact.Validate("Company No.", CompanyNo);
        Contact.Modify(true);
    end;

    local procedure UpdateOpportunity(ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.UpdateOpportunity();
    end;

    local procedure VerifyActivityStepOnReport(ActivityCode: Code[10])
    var
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", ActivityCode);
        ActivityStep.FindFirst();
        LibraryReportDataset.AssertCurrentRowValueEquals('Priority_ActivityStep', Format(ActivityStep.Priority));
    end;

    local procedure VerifyCostAndEstimatedValue(Contact: Record Contact)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Contact', Contact."No.");

        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            Contact.FieldCaption("No."),
            Contact."No."));

        Contact.CalcFields("Cost (LCY)", "Estimated Value (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostLCY_Cont',
          Contact."Cost (LCY)");

        LibraryReportDataset.AssertCurrentRowValueEquals('EstimatedValueLCY_Cont',
          Contact."Estimated Value (LCY)");
    end;

    local procedure VerifyCampaign(Campaign: Record Campaign; SegmentHeader: Record "Segment Header"; CampaignEntry: Record "Campaign Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Verify Campaign Table Detail.
        LibraryReportDataset.SetRange('No_Campaign', Campaign."No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_Campaign', Campaign.Description);

        // Verification for Segment Header Table Details.
        LibraryReportDataset.AssertCurrentRowValueEquals('No_SegmentHdr', SegmentHeader."No.");

        // Verification for Campaign Entry.
        LibraryReportDataset.SetRange('EntryNo_CampaignEntry', CampaignEntry."Entry No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Desc_Campaign', CampaignEntry.Description);
        CampaignEntry.CalcFields("Cost (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostLCY_CampaignEntry', CampaignEntry."Cost (LCY)");
    end;

    local procedure VerifyInteractionLogEntry(ContactNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.FindFirst();

        LibraryReportDataset.SetRange(
          'Interaction_Log_Entry___Entry_No__',
          InteractionLogEntry."Entry No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Interaction_Log_Entry___Contact_No__',
          InteractionLogEntry."Contact No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Interaction_Log_Entry___Information_Flow_',
          Format(InteractionLogEntry."Information Flow"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Interaction_Log_Entry___Initiated_By_',
          Format(InteractionLogEntry."Initiated By"));
    end;

    local procedure VerifyOpportunityDetails(SalespersonCode: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Salesperson Code", SalespersonCode);
        Opportunity.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Opportunity__No__', Opportunity."No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Contact_No__', Opportunity."Contact No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity_Status', Format(Opportunity.Status));
        Opportunity.CalcFields("Probability %", "Chances of Success %", "Completed %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Probability___', Opportunity."Probability %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Chances_of_Success___', Opportunity."Chances of Success %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Completed___', Opportunity."Completed %");
    end;

    local procedure VerifyRemarkOnReport(RemarkPosition: Integer; ElementName: Text; Value: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ElementName, Value);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals(
          StrSubstNo('MarksTxt_%1_', RemarkPosition),
          'x');
    end;

    local procedure VerifyRemarkOnContactReport(RemarkPosition: Integer; ContactNo: Variant)
    begin
        VerifyRemarkOnReport(RemarkPosition, 'ContactNo', ContactNo);
    end;

    local procedure VerifyRemarkOnSegmentCoverSheetReport(RemarkPosition: Integer; ContactNo: Variant)
    begin
        VerifyRemarkOnReport(RemarkPosition, 'Contact_No_', ContactNo);
    end;

    local procedure VerifyTextsOnReport(Text: array[5] of Text[250])
    var
        Counter: Integer;
    begin
        for Counter := 1 to ArrayLen(Text) do
            LibraryReportDataset.AssertCurrentRowValueEquals(
              StrSubstNo('Text_%1_', Counter),
              Text[Counter]);
    end;

    local procedure VerifyTaskDetails(Task: Record "To-do")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Task__No__', Task."No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Task__Contact_No__', Task."Contact No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Task_Status', Format(Task.Status));
        LibraryReportDataset.AssertCurrentRowValueEquals('Task_Priority', Format(Task.Priority));
    end;

    local procedure VerifyTaskOnPersonSummary(Task: Record "To-do")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Contact__Company_No__', Task."Contact No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Task__Salesperson_Code_', Task."Salesperson Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Task_Priority', Format(Task.Priority));
        LibraryReportDataset.AssertCurrentRowValueEquals('Task_Status', Format(Task.Status));
    end;

    local procedure VerifyQuestionnaireDescription(ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Profile_Questionnaire_Line_Description',
          ProfileQuestionnaireLine.Description);
    end;

    local procedure VerifyQuestionnaireDetails(ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(
          'Profile_Questionnaire_Header_Code',
          ProfileQuestionnaireLine."Profile Questionnaire Code");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Profile_Questionnaire_Line__Line_No__',
          ProfileQuestionnaireLine."Line No.");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Profile_Questionnaire_Line_Type',
          Format(ProfileQuestionnaireLine.Type));
        VerifyQuestionnaireDescription(ProfileQuestionnaireLine);
    end;

    local procedure VerifyValuesonContactList(Contact: Record Contact)
    begin
        LibraryReportDataset.LoadDataSetFile();
        Contact.CalcFields("Cost (LCY)", "Estimated Value (LCY)", "Calcd. Current Value (LCY)", "No. of Opportunities");

        LibraryReportDataset.SetRange('Contact__No__', Contact."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Contact__Cost__LCY__',
          Contact."Cost (LCY)");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Contact__Estimated_Value__LCY__',
          Contact."Estimated Value (LCY)");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Contact__Calcd__Current_Value__LCY__',
          Contact."Calcd. Current Value (LCY)");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Contact__No__of_Opportunities_',
          Contact."No. of Opportunities");
    end;

    local procedure VerifyValuesonOpportunityList(Opportunity: Record Opportunity)
    begin
        LibraryReportDataset.LoadDataSetFile();
        Opportunity.CalcFields("Current Sales Cycle Stage", "Probability %", "Completed %");
        LibraryReportDataset.SetRange('Opportunity__No__', Opportunity."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Sales_Cycle_Code_', Opportunity."Sales Cycle Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Salesperson_Code_', Opportunity."Salesperson Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Contact_No__', Opportunity."Contact No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Probability___', Opportunity."Probability %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Opportunity__Completed___', Opportunity."Completed %");
    end;

    local procedure VerifyValuesSalesCycleAnalysis(SalesCycleCode: Code[10]; Stage: Integer)
    var
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        SalesCycleStage.Get(SalesCycleCode, Stage);
        SalesCycleStage.CalcFields("No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)", "Average No. of Days");

        LibraryReportDataset.SetRange('Stage_SalesCycleStage', Format(Stage));

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Descriptn_SalesCycleStage', SalesCycleStage.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('ActyCode_SalesCycleStage', SalesCycleStage."Activity Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('NoOfOppt_SalesCycleStage', SalesCycleStage."No. of Opportunities");
        LibraryReportDataset.AssertCurrentRowValueEquals('EstValLCY_SalesCycleStage', SalesCycleStage."Estimated Value (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CurValLCY_SalesCycleStage', SalesCycleStage."Calcd. Current Value (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('AvgNoOfDay_SalesCycleStage', SalesCycleStage."Average No. of Days");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerOpportunity(var CreateOpportunity: Page "Create Opportunity"; var Response: Action)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();
        TempOpportunity.Validate(
          Description, LibraryUtility.GenerateRandomCode(TempOpportunity.FieldNo(Description), DATABASE::Opportunity));

        TempOpportunity.Validate("Sales Cycle Code", LibraryVariableStorage.DequeueText());
        TempOpportunity.CheckStatus();
        TempOpportunity.FinishWizard();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactCoverSheetRequestPageHandler(var ContactCoverSheet: TestRequestPage "Contact - Cover Sheet")
    begin
        ContactCoverSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractModalPageHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        TempSegmentLine.Validate("Contact No.", ContactNo2);
        TempSegmentLine.Validate("Interaction Template Code", InteractionTemplateCode);
        TempSegmentLine.Validate(Description, InteractionTemplateCode);
        TempSegmentLine.Validate("Campaign No.", CampaignNo2);
        TempSegmentLine.Validate("Information Flow", TempSegmentLine."Information Flow"::Outbound);
        TempSegmentLine.Validate("Initiated By", TempSegmentLine."Initiated By"::Us);
        TempSegmentLine.FinishSegLineWizard(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerForTeamTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate("Team Code", TeamCode);
        TempTask.Validate(Description, TeamCode);
        TempTask.Validate("Team To-do", true);
        TempTask.Validate(Date, WorkDate());
        TempTask.Modify();
        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(Description, TempTask."Contact No.");
        TempTask.Validate("Opportunity No.", OpportunityNo);
        TempTask.Validate(Date, WorkDate());
        TempTask.Modify();
        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerUpdateOpportunity(var UpdateOpportunity: Page "Update Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        ActionType: Option " ",First,Next,Previous,Skip,Update,Jump;
    begin
        TempOpportunityEntry.Init();
        UpdateOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.CreateStageList();
        TempOpportunityEntry.Validate("Action Type", ActionType::First);
        TempOpportunityEntry.Validate("Sales Cycle Stage", CurrentSalesCycleStage);

        // Use Random for Estimated Value (LCY) and Chances of Success % because values are not important.
        TempOpportunityEntry.Validate("Estimated Value (LCY)", LibraryRandom.RandInt(100));
        TempOpportunityEntry.Validate("Chances of Success %", LibraryRandom.RandInt(100));
        TempOpportunityEntry.Validate("Estimated Close Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        TempOpportunityEntry.Modify();

        TempOpportunityEntry.CheckStatus2();
        TempOpportunityEntry.FinishWizard2();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerOpportunityAction(var UpdateOpportunity: Page "Update Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
    begin
        TempOpportunityEntry.Init();
        UpdateOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.CreateStageList();
        TempOpportunityEntry.Validate("Sales Cycle Stage", CurrentSalesCycleStage);

        // Use Random for Estimated Value (LCY) and Chances of Success % because values are not important.
        TempOpportunityEntry.Validate("Estimated Value (LCY)", LibraryRandom.RandDec(100, 2));
        TempOpportunityEntry.Validate("Chances of Success %", LibraryRandom.RandDec(100, 2));
        TempOpportunityEntry.Validate("Estimated Close Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        TempOpportunityEntry.Modify();

        TempOpportunityEntry.CheckStatus2();
        TempOpportunityEntry.FinishWizard2();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SegmentContactsReportHandler(var SegmentContactsRequestPage: TestRequestPage "Segment - Contacts")
    begin
        SegmentContactsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OppurtunityDetailsReportHandler(var OpportunityDetailsRequestPage: TestRequestPage "Opportunity - Details")
    begin
        OpportunityDetailsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactCompanySummaryReportHandler(var ContactCompanySummaryRequestPage: TestRequestPage "Contact - Company Summary")
    begin
        ContactCompanySummaryRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CampaignDetailsReportHandler(var CampaignDetailsRequestPage: TestRequestPage "Campaign - Details")
    begin
        CampaignDetailsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonTasksReportHandler(var SalespersonTasks: TestRequestPage "Salesperson - Tasks")
    begin
        SalespersonTasks.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOpportunitiesReportHandler(var SalespersonOpportunities: TestRequestPage "Salesperson - Opportunities")
    begin
        SalespersonOpportunities.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TeamTasksReportHandler(var TeamTasks: TestRequestPage "Team - Tasks")
    begin
        TeamTasks.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuestionnaireHandoutsReportHandler(var QuestionnaireHandouts: TestRequestPage "Questionnaire - Handouts")
    begin
        QuestionnaireHandouts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuestionnaireTestReportHandler(var QuestionnaireTest: TestRequestPage "Questionnaire - Test")
    begin
        QuestionnaireTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactPersonSummaryReportHandler(var ContactPersonSummary: TestRequestPage "Contact - Person Summary")
    begin
        ContactPersonSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunContactCoverSheetReport(ContactNo: Code[20]; AsAgreedUpon: Boolean; ForYourInformation: Boolean; YourCommentsPlease: Boolean; ForYourApproval: Boolean; PleaseCall: Boolean; ReturnedAfterUse: Boolean)
    var
        Contact: Record Contact;
        ContactCoverSheet: Report "Contact - Cover Sheet";
    begin
        Commit();
        Contact.SetRange("No.", ContactNo);
        Clear(ContactCoverSheet);
        ContactCoverSheet.SetTableView(Contact);

        ContactCoverSheet.InitializeRemarks(AsAgreedUpon,
          ForYourInformation,
          YourCommentsPlease,
          ForYourApproval,
          PleaseCall,
          ReturnedAfterUse);

        ContactCoverSheet.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SegmentCoverSheetRequestPageHandler(var SegmentCoverSheet: TestRequestPage "Segment - Cover Sheet")
    begin
        SegmentCoverSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunSegmentCoverSheetReport(SegmentHeaderNo: Code[20]; AsAgreedUpon: Boolean; ForYourInformation: Boolean; YourCommentsPlease: Boolean; ForYourApproval: Boolean; PleaseCall: Boolean; ReturnedAfterUse: Boolean)
    var
        SegmentHeader: Record "Segment Header";
        SegmentCoverSheet: Report "Segment - Cover Sheet";
    begin
        Commit();
        SegmentHeader.SetRange("No.", SegmentHeaderNo);
        Clear(SegmentCoverSheet);
        SegmentCoverSheet.SetTableView(SegmentHeader);

        SegmentCoverSheet.InitializeRemarks(AsAgreedUpon,
          ForYourInformation,
          YourCommentsPlease,
          ForYourApproval,
          PleaseCall,
          ReturnedAfterUse);

        SegmentCoverSheet.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactListReportHandler(var ContactList: TestRequestPage "Contact - List")
    begin
        ContactList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpportunityListRequestPageHandler(var OpportunityList: TestRequestPage "Opportunity - List")
    begin
        OpportunityList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpportunityListToExcelRequestPageHandler(var OpportunityList: TestRequestPage "Opportunity - List")
    begin
        OpportunityList.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCycleAnalysisReportHandler(var SalesCycleAnalysis: TestRequestPage "Sales Cycle - Analysis")
    begin
        SalesCycleAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

