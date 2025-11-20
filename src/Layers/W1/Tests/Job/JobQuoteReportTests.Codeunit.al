codeunit 136314 "Job Quote Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [New Job Reports]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        ReportLayoutSelection: Record "Report Layout Selection";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        AmountErr: Label 'Total amount must be equal.';
        RollingBackChangesErr: Label 'Rolling back changes...';
        CurrencyField: Option "Local Currency","Foreign Currency";
        AmountField: Option " ",Quantity,"Unit Price","Total Price";
        ValueNotFoundErr: Label 'Value must exist.';
        QuantityTxt: Label 'Quantity';
        UnitCostTxt: Label 'Unit Cost';
        TotalCostTxt: Label 'Total Cost';
        JobTaskNoTxt: Label 'Project Task No.';

    [HandlerFunctions('PostandSendPageHandlerYes,EmailEditorHandler,CloseEmailEditorHandler')]
    [Test]
    Procedure SendProjectTaskQuoteFromProjectTaskCardDoesNotProvideWithTheSsameFileNameAsSendProjectQuotefromProjectCard()
    var
        JobTaskLine: Record "Job Task";
        LibraryEmail: Codeunit "Library - Email";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        JobTaskCard: TestPage "Job Task Card";
    begin
        // [SCENARIO 578185] Send Project Task Quote from Project Task Card while using Multiple Customers Task Billing Method does not provide with the same file name structure as Send Project Quote from Project Card
        Initialize();

        //[GIVEN] Setup Email
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        Job."Task Billing Method" := Job."Task Billing Method"::"Multiple customers";
        Job.Modify();

        // [GIVEN] Create Job Task Line
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine."Bill-to Customer No." := Job."Bill-to Customer No.";
        JobTaskLine.Modify();
        JobTaskCard.Trap();
        PAGE.Run(PAGE::"Job Task Card", JobTaskLine);

        // [WHEN] Run "Send Job Quote" action
        JobTaskCard."Send Job Task Quote".Invoke();

        //[THEN] Verify Project Task Quote Report Name
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Quote Report Tests");
        BindActiveDirectoryMockEvents();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Quote Report Tests");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        RemoveReportLayout();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Quote Report Tests");
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        asserterror Error(RollingBackChangesErr);
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPlanningLineReportHeading()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        SetReportLayoutForRDLC();
        // [WHEN] Job Quote report is run
        SetupForJobQuote(JobPlanningLine);

        // [THEN] Verify Job Quote report header information
        VerifyJobQuoteReportHeading(Job);

        // Cleanup
        RemoveReportLayout();
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintPreviewJobQuoteFromJobCard()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        SetReportLayoutForRDLC();
        // [WHEN] Job Quote report is run
        SetupForJobQuote(JobPlanningLine);

        // [THEN] Verify contents on Job Quote report
        VerifyJobQuoteReport(JobPlanningLine, QuantityTxt, UnitCostTxt, TotalCostTxt, JobTaskNoTxt);

        // Cleanup
        RemoveReportLayout();
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,PostandSendPageHandlerNo')]
    [Scope('OnPrem')]
    procedure PrintPreviewJobQuoteFromJobList()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobList: TestPage "Job List";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        SetReportLayoutForCustomWord();
        SetupForJobQuote(JobPlanningLine);

        // [WHEN] Job list is opened with the newly-created job
        JobList.Trap();
        PAGE.Run(PAGE::"Job List", Job);

        // [WHEN] Run "Send Job Quote" action
        JobList."Send Job Quote".Invoke();

        // [THEN] Post and Send Confirmation for the Job Quote page appears -- Page 365

        // Cleanup
        RemoveReportLayout();
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,JobAnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCustomPreviewJobQuoteFromJobList()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobList: TestPage "Job List";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 416894] The Job List use Report selection for runs report "Preview Job Queue"
        Initialize();
        SetReportLayoutForCustomWord();
        CreateJobQueueReportSelection();
        SetupForJobQuote(JobPlanningLine);

        JobList.Trap();
        Page.Run(Page::"Job List", Job);

        JobList."Report Job Quote".Invoke();

        // Cleanup
        RemoveReportLayout();
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,PostandSendPageHandlerYes,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SendJobQuoteFromJobCard()
    begin
        SendJobQuoteFromJobCardInternal();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCurrencyValueOnJobQuoteReport()
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        ResQuantity: Decimal;
        UnitPrice: Decimal;
        DocNo: Code[20];
        ValueNotFoundErr: Label 'Value must exist.';
    begin
        // [SCENARIO 454648] Missing currecy identifier in the job quote preview report
        Initialize();

        // [GIVEN] Create Job:
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        Job.Modify();

        // [GIVEN] Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // [GIVEN] Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTaskLine, JobPlanningLine);
        LibraryResource.CreateResource(Resource, '');
        ResQuantity := LibraryRandom.RandDec(100, 2);
        UnitPrice := 10 + LibraryRandom.RandDec(10, 2);
        DocNo := LibraryUtility.GenerateRandomCode20(JobPlanningLine.FieldNo("Document No."), Database::"Job Planning Line");
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("No.", Resource."No.");
        JobPlanningLine.Validate(Quantity, ResQuantity);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Validate("Unit Cost", UnitPrice);
        JobPlanningLine.Modify();

        // [WHEN] Run Jobs Quote Report:
        RunJobQuoteReport(Job."No.");

        // [THEN] Result
        LibraryReportDataset.GetLastRow();
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Total Price"), true, ValueNotFoundErr);
    end;

    procedure SendJobQuoteFromJobCardInternal()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        LibraryEmail: Codeunit "Library - Email";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        SetReportLayoutForRDLC();
        SetupForJobQuote(JobPlanningLine);
        LibraryEmail.SetUpEmailAccount();

        // [THEN] Verify contents on Job Quote report
        VerifyJobQuoteReport(JobPlanningLine, QuantityTxt, UnitCostTxt, TotalCostTxt, JobTaskNoTxt);

        // [WHEN] Job card is opened with the newly-created job
        JobCard.Trap();
        PAGE.Run(PAGE::"Job Card", Job);

        // [WHEN] Run "Send Job Quote" action
        CreateDocumentLayoutForCustomer(Job);
        JobCard."Send Job Quote".Invoke();

        // [THEN] Post and Send Confirmation for the Job Quote page appears -- Page 365

        // Cleanup
        RemoveReportLayout();
        TearDown();
    end;

    local procedure RunJobQuoteReport(No: Code[20])
    var
        Job: Record Job;
        JobQuote: Report "Job Quote";
    begin
        Job.SetRange("No.", No);
        Clear(JobQuote);
        JobQuote.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobQuote.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure CreateJobQueueReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::JQ;
        ReportSelections."Report ID" := REPORT::"Job Analysis";
        ReportSelections.Insert();

        CustomReportSelection.Init();
    end;

    local procedure VerifyJobQuoteReport(JobPlanningLine: Record "Job Planning Line"; Column: Text[250]; Column2: Text[250]; Column3: Text[250]; Column4: Text[250])
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobPlanningLine.FieldCaption("Job Task No."), Format(JobPlanningLine."Job Task No."));
        LibraryReportValidation.SetColumn(Column);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine.Quantity), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column2);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Unit Price"), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column3);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Total Price"), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column4);
        Assert.AreEqual(LibraryReportValidation.CheckIfValueExists(JobPlanningLine."Job Task No."), true, ValueNotFoundErr);

        Assert.AreEqual(JobPlanningLine.Quantity * JobPlanningLine."Unit Price", JobPlanningLine."Total Price", AmountErr);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [Scope('OnPrem')]
    procedure SetupAmountArray(var NewAmountField: array[8] of Option ,Quantity,"Unit Cost","Total Cost"; AmountOption: Option; AmountOption2: Option; AmountOption3: Option)
    begin
        NewAmountField[1] := AmountOption;
        NewAmountField[2] := AmountOption2;
        NewAmountField[3] := AmountOption3;
        NewAmountField[4] := AmountField::" ";
        NewAmountField[5] := AmountField::" ";
        NewAmountField[6] := AmountField::" ";
        NewAmountField[7] := AmountField::" ";
        NewAmountField[8] := AmountField::" ";
    end;

    [Scope('OnPrem')]
    procedure SetupCurrencyArray(var NewCurrencyField: array[8] of Option)
    var
        Counter: Integer;
    begin
        for Counter := 1 to 8 do
            NewCurrencyField[Counter] := CurrencyField;
    end;

    local procedure SetReportLayoutForRDLC()
    begin
        SetReportLayout(ReportLayoutSelection.Type::"RDLC (built-in)", '');
    end;

    local procedure SetReportLayoutForCustomWord()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        Clear(CustomReportLayout);
        CustomReportLayout.SetRange("Report ID", REPORT::"Job Quote");
        CustomReportLayout.SetRange("Company Name", CompanyName);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst() then
            CustomReportLayoutCode := CustomReportLayout.Code;

        SetReportLayout(ReportLayoutSelection.Type::"Custom Layout", CustomReportLayoutCode);
    end;

    local procedure SetReportLayout(LayoutSelection: Integer; CustomReportLayoutCode: Code[20])
    begin
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := REPORT::"Job Quote";
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := LayoutSelection;
        ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayoutCode;
        ReportLayoutSelection.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostandSendPageHandlerNo(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.No().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostandSendPageHandlerYes(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes().Invoke();
    end;

    local procedure SetupForJobQuote(var JobPlanningLine: Record "Job Planning Line")
    var
        JobReportsII: Codeunit "Job Reports II";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        JobReportsII.CreateInitialSetupForJob(Job);

        // 1. Setup: Create Job and Job Task with Currency and create Job Planning Lines for Schedule.
        SetupAmountArray(NewAmountField, AmountField::Quantity, AmountField::"Unit Price", AmountField::"Total Price");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Run Jobs Quote Report.
        RunJobQuoteReport(Job."No.");

        // 3. Set up table buffer for report
        JobPlanningLine.SetFilter("Job No.", '=%1', Job."No.");
        JobPlanningLine.SetFilter("Line Type", '>%1', JobPlanningLine."Line Type"::Budget);
        JobPlanningLine.FindFirst();
    end;

    local procedure RemoveReportLayout()
    begin
        Clear(ReportLayoutSelection);
        ReportLayoutSelection.SetRange("Report ID", REPORT::"Job Quote");
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        ReportLayoutSelection.DeleteAll();
    end;

    local procedure VerifyJobQuoteReportHeading(Job: Record Job)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExists(StrSubstNo('%1: %2: %3', Job.TableCaption(), Job.FieldCaption("No."), Job."No.")),
              ValueNotFoundErr);
    end;

    local procedure CreateDocumentLayoutForCustomer(var Job: Record Job)
    var
        Customer: Record Customer;
        CustomReportSelection: Record "Custom Report Selection";
    begin
        if Customer.Get(Job."Bill-to Customer No.") then begin
            CustomReportSelection.DeleteAll();
            CustomReportSelection.Init();
            CustomReportSelection."Source Type" := DATABASE::Customer;
            CustomReportSelection."Source No." := Customer."No.";
            CustomReportSelection.Usage := CustomReportSelection.Usage::JQ;
            CustomReportSelection.Sequence := 1;
            CustomReportSelection."Report ID" := REPORT::"Job Quote";
            CustomReportSelection."Use for Email Attachment" := true;
            CustomReportSelection.Insert();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobAnalysisRequestPageHandler(var RequestPage: TestRequestPage "Job Analysis")
    begin
        RequestPage.Cancel().Invoke();
    end;
}

