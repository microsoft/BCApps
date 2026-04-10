codeunit 136207 "Marketing Batch Jobs"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryService: Codeunit "Library - Service";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        ExistError: Label '%1 for %2 must not exist.';
        Description: Label 'Follow-up on segment %1';
        DescriptionForPage: Text[50];
        SearchResultError: Label '%1 must be empty.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Batch Jobs");
        // Clearing global variable.
        DescriptionForPage := '';
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Batch Jobs");

        BindSubscription(LibraryJobQueue);
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryTemplates.EnableTemplatesFeature();

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Batch Jobs");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogSegmentWithCampaignEntry()
    var
        SegmentHeader: Record "Segment Header";
        Campaign: Record Campaign;
        CampaignEntry: Record "Campaign Entry";
        InteractionTemplate: Record "Interaction Template";
        LoggedSegment: Record "Logged Segment";
        SegmentHeader2: Record "Segment Header";
    begin
        // Covers document number 129051,129055, CU7030 - refer to TFS ID 161415, 167035.
        // Test Logged segment, Follow Up Segment and Campaign Entries.

        // 1. Setup: Create Campaign, Interaction Template, Segment Header and Segment Line with Contact No.
        Initialize();
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateSegment(SegmentHeader, Campaign."No.", InteractionTemplate.Code);

        // 2. Exercise: Run Log Segment Batch Job for Created Segment.
        RunLogSegment(SegmentHeader."No.", true);

        // 3. Verify: Verify Campaign Entry, Logged Segment, Follow Up Segment created.
        CampaignEntry.SetRange("Campaign No.", SegmentHeader."Campaign No.");
        CampaignEntry.FindFirst();
        CampaignEntry.TestField("Segment No.", SegmentHeader."No.");

        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        LoggedSegment.FindFirst();
        LoggedSegment.CalcFields("No. of Campaign Entries");
        LoggedSegment.TestField("No. of Campaign Entries", 1);

        SegmentHeader2.SetRange("Campaign No.", Campaign."No.");
        SegmentHeader2.FindFirst();
        SegmentHeader2.TestField(Description, StrSubstNo(Description, SegmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CanceledCampaignEntry()
    var
        SegmentHeader: Record "Segment Header";
        CampaignEntry: Record "Campaign Entry";
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // Covers document number 129055 - refer to TFS ID 161415.
        // Test Campaign Entries successfully Canceled.

        // 1. Setup: Create Campaign, Interaction Template, Segment Header and Segment Line with Contact No.
        Initialize();
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateSegment(SegmentHeader, Campaign."No.", InteractionTemplate.Code);

        // 2. Exercise: Run Log Segment Batch Job for Created Segment and Canceled the Created Logged Segment.
        RunLogSegment(SegmentHeader."No.", false);
        CancelCampaignEntry(SegmentHeader."Campaign No.");

        // 3. Verify: Verify Campaign Entry and Interaction Log Entry successfully Canceled.
        CampaignEntry.SetRange("Campaign No.", SegmentHeader."Campaign No.");
        CampaignEntry.FindFirst();
        CampaignEntry.TestField("Segment No.", SegmentHeader."No.");
        CampaignEntry.TestField(Canceled, true);

        InteractionLogEntry.SetRange("Segment No.", SegmentHeader."No.");
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField(Canceled, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteCampaignEntry()
    var
        SegmentHeader: Record "Segment Header";
        CampaignEntry: Record "Campaign Entry";
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        DeleteCampaignEntries: Report "Delete Campaign Entries";
    begin
        // Covers document number 129055 - refer to TFS ID 161415.
        // Test Campaign Entries successfully Deleted.

        // 1. Setup: Create Campaign, Interaction Template, Segment Header, Segment Line with Contact No., Run Log Segment Batch Job
        // for Created Segment and Canceled the Created Logged Segment.
        Initialize();
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        CreateSegment(SegmentHeader, Campaign."No.", InteractionTemplate.Code);
        RunLogSegment(SegmentHeader."No.", false);
        CancelCampaignEntry(SegmentHeader."Campaign No.");

        // 2. Exercise: Run Delete Campaign Entries Batch Job.
        CampaignEntry.SetRange("Campaign No.", SegmentHeader."Campaign No.");
        DeleteCampaignEntries.SetTableView(CampaignEntry);
        DeleteCampaignEntries.UseRequestPage(false);
        DeleteCampaignEntries.RunModal();

        // 3. Verify: Verify Campaign Entries and Interaction Log Entry are successfully Deleted.
        Assert.IsFalse(CampaignEntry.FindFirst(), StrSubstNo(ExistError, CampaignEntry.TableCaption(), SegmentHeader."Campaign No."));

        InteractionLogEntry.SetRange("Campaign No.", SegmentHeader."Campaign No.");
        Assert.IsFalse(
          InteractionLogEntry.FindFirst(), StrSubstNo(ExistError, InteractionLogEntry.TableCaption(), InteractionLogEntry."Campaign No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteLogSegment()
    var
        SegmentHeader: Record "Segment Header";
        LoggedSegment: Record "Logged Segment";
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        DeleteLoggedSegments: Report "Delete Logged Segments";
    begin
        // Covers document number 129057 - refer to TFS ID 161415.
        // Test Logged segment successfully deleted.

        // 1. Setup: Create Interaction Template Code, Segment Header, Segment Line with Contact, Run Logged Segment Batch Job for Created
        // Segment and Canceled the Created Logged Segment.
        Initialize();
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateSegment(SegmentHeader, Campaign."No.", InteractionTemplate.Code);
        RunLogSegment(SegmentHeader."No.", false);
        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        LoggedSegment.FindFirst();
        LoggedSegment.ToggleCanceledCheckmark();

        // 2. Exercise: Run Delete Logged Segments Batch Report.
        DeleteLoggedSegments.SetTableView(LoggedSegment);
        DeleteLoggedSegments.UseRequestPage(false);
        DeleteLoggedSegments.RunModal();

        // 3. Verify: Verify Logged Segment deleted.
        Assert.IsFalse(LoggedSegment.FindFirst(), StrSubstNo(ExistError, LoggedSegment.TableCaption(), SegmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalFormCloseOpportunity,MessageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpportunity()
    var
        Opportunity: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        DefaultSalesCycleCode: Code[10];
        ContactNo: Code[20];
    begin
        // Covers document number 129048 - refer to TFS ID 161415.
        // Test Opportunity successfully closed.

        // 1. Setup: Update Sale Cycle Code on Marketing Setup, Create Contact and Create opportunity for Contact.
        CreateOpportunityWithContact(DefaultSalesCycleCode, ContactNo);

        // 2. Exercise: Close the Created Opportunity.
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        // 3. Verify: Verify Opportunity successfully closed and Opportunity Entry created.
        Opportunity.FindFirst();
        Opportunity.TestField(Closed, true);
        Opportunity.TestField("Date Closed", WorkDate());

        OpportunityEntry.SetRange("Opportunity No.", Opportunity."No.");
        OpportunityEntry.FindFirst();
        OpportunityEntry.TestField("Contact No.", ContactNo);
        OpportunityEntry.TestField("Date Closed", WorkDate());

        // 4. Teardown: Rollback Default Sale Cycle Code on Marketing Setup.
        UpdateDefaultSalesCycleCode(DefaultSalesCycleCode);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalFormCloseOpportunity,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOpportunity()
    var
        Opportunity: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        DeleteOpportunities: Report "Delete Opportunities";
        DefaultSalesCycleCode: Code[10];
        ContactNo: Code[20];
    begin
        // Covers document number 129048 - refer to TFS ID 161415.
        // Test Opportunity successfully deleted.

        // 1. Setup: Update Sale Cycle Code on Marketing Setup, Create Contact, Create opportunity for Contact and Close the Created
        // Opportunity.
        CreateOpportunityWithContact(DefaultSalesCycleCode, ContactNo);
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        // 2. Exercise: Run Delete Opportunity Batch Job.
        DeleteOpportunities.SetTableView(Opportunity);
        DeleteOpportunities.UseRequestPage(false);
        DeleteOpportunities.RunModal();

        // 3. Verify: Verify Opportunity and Opportunity Entry are deleted.
        Assert.IsFalse(Opportunity.FindFirst(), StrSubstNo(ExistError, Opportunity.TableCaption(), ContactNo));

        OpportunityEntry.SetRange("Opportunity No.", Opportunity."No.");
        Assert.IsFalse(OpportunityEntry.FindFirst(), StrSubstNo(ExistError, OpportunityEntry.TableCaption(), Opportunity."No."));

        // 4. Teardown: Rollback Default Sale Cycle Code on Marketing Setup.
        UpdateDefaultSalesCycleCode(DefaultSalesCycleCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceEMailQueue()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceEmailQueue: Record "Service Email Queue";
    begin
        // Covers document number 129098 - refer to TFS ID 161415.
        // [SCENARIO 275807] Processing Service Email Queue with Job Queue.
        Initialize();

        // [GIVEN] Customer with Service Order with Email.
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Mail" := LibraryUtility.GenerateGUID() + '@microsoft.com';
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Service Order Status changed to Finished.
        ServiceHeader.Validate("Notify Customer", ServiceHeader."Notify Customer"::"By Email");
        ServiceHeader.Validate(Status, ServiceHeader.Status::Finished);
        ServiceHeader.Modify(true);

        // [THEN] Service Email Queue created.
        ServiceEmailQueue.SetRange("Document Type", ServiceEmailQueue."Document Type"::"Service Order");
        ServiceEmailQueue.SetRange("Document No.", ServiceHeader."No.");
        ServiceEmailQueue.FindFirst();
        ServiceEmailQueue.TestField("To Address", Customer."E-Mail");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteServiceEmailQueue()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceEmailQueue: Record "Service Email Queue";
        DeleteServiceEmailQueue: Report "Delete Service Email Queue";
        LibraryService: Codeunit "Library - Service";
    begin
        // Covers document number 129098 - refer to TFS ID 161415.
        // Test Service E-Mail Queue successfully deleted.

        // 1. Setup: Create Service Header, Update Notify Customer to By E-Mail and Status to Finished on Service Header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Notify Customer", ServiceHeader."Notify Customer"::"By Email");
        ServiceHeader.Validate(Status, ServiceHeader.Status::Finished);
        ServiceHeader.Modify(true);

        // 2. Exercise: Run Delete Service E-Mail Queue Batch Job.
        ServiceEmailQueue.SetRange("Document Type", ServiceEmailQueue."Document Type"::"Service Order");
        ServiceEmailQueue.SetRange("Document No.", ServiceHeader."No.");
        DeleteServiceEmailQueue.SetTableView(ServiceEmailQueue);
        DeleteServiceEmailQueue.UseRequestPage(false);
        DeleteServiceEmailQueue.RunModal();

        // 3. Verify: Verify Service E-Mail Queue deleted.
        Assert.IsFalse(ServiceEmailQueue.FindFirst(), StrSubstNo(ExistError, ServiceEmailQueue.TableCaption(), ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerTask')]
    [Scope('OnPrem')]
    procedure CanceledTeamTask()
    var
        Team: Record Team;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number 129054 - refer to TFS ID 161415.
        // Test To do successfully canceled with Type Team.

        // 1. Setup: Create Team.
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        DescriptionForPage := Team.Code;  // Assigning value to Global Variable.

        // 2. Exercise: Create To-Do for Team and Canceled the Created To-Do.
        Task.SetRange("Team Code", Team.Code);
        TempTask.CreateTaskFromTask(Task);

        Task.FindFirst();
        Task.Validate(Canceled, true);
        Task.Modify(true);

        // 3. Verify: Verify To-Do Canceled.
        Task.FindFirst();
        Task.TestField(Canceled, true);
        Task.TestField(Status, Task.Status::Completed);
        Task.TestField("Date Closed", Today);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerTask')]
    [Scope('OnPrem')]
    procedure DeleteTask()
    var
        Team: Record Team;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        DeleteTasks: Report "Delete Tasks";
    begin
        // Covers document number 129054 - refer to TFS ID 161415.
        // Test To do successfully deleted.

        // 1. Setup: Create Team, Create To-Do for Team and Canceled the Created To-Do.
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        DescriptionForPage := Team.Code;  // Assigning value to Global Variable.
        Task.SetRange("Team Code", Team.Code);
        TempTask.CreateTaskFromTask(Task);
        Task.FindFirst();
        Task.Validate(Canceled, true);
        Task.Modify(true);

        // 2. Exercise: Run Delete To-Dos Batch Job.
        DeleteTasks.SetTableView(Task);
        DeleteTasks.UseRequestPage(false);
        DeleteTasks.RunModal();

        // 3. Verify: Verify To-Do deleted.
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(ExistError, Task.TableCaption(), Team.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDuplicateContactSearchStringData()
    var
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check that no data exists in Contact Duplicate Search String Table after deleting the data from it.

        // 1. Setup: Update Marketing Setup.
        Initialize();
        MarketingSetup.Get();
        UpdateMarketingSetup(false, false);

        // 2. Exercise: Delete all the data from Contact Duplicate Search String Table.
        ContDuplicateSearchString.DeleteAll();

        // 3. Verify: Verify that no data exists in the table.
        Assert.IsTrue(ContDuplicateSearchString.IsEmpty, StrSubstNo(SearchResultError, ContDuplicateSearchString.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('GenerateDuplSearchStringRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GenerateDuplicateConactSearchString()
    var
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check that data generated automatically in Contact Duplicate Search String Table after running Generate Duplicate Search String Batch Job.

        // 1. Setup: Update Marketing Setup and delete all the data from Contact Duplicate Search String Table.
        Initialize();
        MarketingSetup.Get();
        UpdateMarketingSetup(false, false);
        ContDuplicateSearchString.DeleteAll();

        // 2. Exercise.
        RunGenerateDuplSearchStringReport();

        // 3. Verify: Verify that data exists in Contact Duplicate Search String Table.
        Assert.IsFalse(
          ContDuplicateSearchString.IsEmpty,
          StrSubstNo(ExistError, ContDuplicateSearchString.FieldCaption("Contact Company No."), ContDuplicateSearchString.TableCaption()));
    end;

    local procedure CancelCampaignEntry(CampaignNo: Code[20])
    var
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.SetRange("Campaign No.", CampaignNo);
        CampaignEntry.FindFirst();
        CampaignEntry.ToggleCanceledCheckmark();
    end;

    local procedure CreateOpportunityWithContact(var DefaultSalesCycleCode: Code[10]; var ContactNo: Code[20])
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
        SalesCycle: Record "Sales Cycle";
    begin
        // Update Sale Cycle Code on Marketing Setup, Create Contact and Create opportunity for Contact.
        Initialize();
        DescriptionForPage := LibraryUtility.GenerateGUID();  // Assigning value to Global Variable.
        SalesCycle.FindFirst();
        DefaultSalesCycleCode := UpdateDefaultSalesCycleCode(SalesCycle.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Commit();

        Opportunity.SetRange("Contact No.", Contact."No.");
        TempOpportunity.CreateOppFromOpp(Opportunity);

        ContactNo := Contact."No.";
    end;

    local procedure CreateSegment(var SegmentHeader: Record "Segment Header"; CampaignNo: Code[20]; InteractionTemplateCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // Create Campaign, Interaction Template, Segment Header and Segment Line with Contact No.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        Contact.SetFilter("Salesperson Code", '<>''''');
        Contact.FindFirst();
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);
    end;

    local procedure RunGenerateDuplSearchStringReport()
    var
        GenerateDuplSearchString: Report "Generate Dupl. Search String";
    begin
        Commit();  // Required to run test case successfully.
        Clear(GenerateDuplSearchString);
        GenerateDuplSearchString.Run();
    end;

    local procedure RunLogSegment(SegmentNo: Code[20]; FollowUp: Boolean)
    var
        LogSegment: Report "Log Segment";
    begin
        LogSegment.SetSegmentNo(SegmentNo);
        LogSegment.InitializeRequest(false, FollowUp);
        LogSegment.UseRequestPage(false);
        LogSegment.RunModal();
    end;

    local procedure UpdateMarketingSetup(MaintainDuplSearchStrings: Boolean; AutosearchForDuplicates: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Maintain Dupl. Search Strings", MaintainDuplSearchStrings);
        MarketingSetup.Validate("Autosearch for Duplicates", AutosearchForDuplicates);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateDefaultSalesCycleCode(DefaultSalesCycleCode: Code[10]) SalesCycleCode: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        SalesCycleCode := MarketingSetup."Default Sales Cycle Code";
        MarketingSetup.Validate("Default Sales Cycle Code", DefaultSalesCycleCode);
        MarketingSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormCloseOpportunity(var CloseOpportunity: Page "Close Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.Validate("Action Taken", TempOpportunityEntry."Action Taken"::Won);

        CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Won);
        CloseOpportunityCode.FindFirst();

        TempOpportunityEntry.Validate("Close Opportunity Code", CloseOpportunityCode.Code);
        TempOpportunityEntry.Validate("Calcd. Current Value (LCY)", Random(10));  // Use Randon because value is not important.
        TempOpportunityEntry.CheckStatus();
        TempOpportunityEntry.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(Type, TempTask.Type::" ");
        TempTask.Validate(Description, DescriptionForPage);
        TempTask.Validate(Date, WorkDate());

        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerOpportunity(var CreateOpportunity: Page "Create Opportunity"; var Response: Action)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();  // For inserting in Temporary Table.
        TempOpportunity.Validate(Description, DescriptionForPage);

        TempOpportunity.CheckStatus();
        TempOpportunity.FinishWizard();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GenerateDuplSearchStringRequestPageHandler(var GenerateDuplSearchString: TestRequestPage "Generate Dupl. Search String")
    begin
        GenerateDuplSearchString.OK().Invoke();
    end;
}

