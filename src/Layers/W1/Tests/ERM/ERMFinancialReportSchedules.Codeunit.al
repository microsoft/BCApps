codeunit 135005 "ERM Financial Report Schedules"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GLSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        FileMgt: Codeunit "File Management";
        IsInitialized: Boolean;
        ExcelContentTypeTxt: Label 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Locked = true;
        PDFContentTypeTxt: Label 'application/pdf', Locked = true;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    [Test]
    procedure StartEndDateFilterFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the start and end date filter formulas will dynamically set the date filter on the financial report
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a start and end date filter formula
        FinancialReport.Get(AccScheduleName.Name);
        Evaluate(FinancialReport.StartDateFilterFormula, '-CY');
        Evaluate(FinancialReport.EndDateFilterFormula, 'CY');
        FinancialReport.Modify();

        // [WHEN] The financial report is opened
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // [THEN] The date filter is set based on the formulas
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
    end;

    [Test]
    procedure DateFilterPeriodFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the date filter period formula will dynamically set the date filter on the financial report
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a date filter period formula
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.DateFilterPeriodFormula := 'FY[1..LP]'; // Current fiscal year first period to last period
        FinancialReport.DateFilterPeriodFormulaLID := 1033; // en-US
        FinancialReport.Modify();

        // [WHEN] The financial report is opened
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // [THEN] The date filter is set based on the formula
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
    end;

    [Test]
    procedure StartEndDateFilterFormulaOverride()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the start and end date filter formulas on the page will clear the period formula
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a period formula
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.DateFilterPeriodFormula := 'FY[1..LP]';
        FinancialReport.DateFilterPeriodFormulaLID := 1033;
        FinancialReport.Modify();

        // [WHEN] The start and end date filter formulas are set on the page
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        AccSchedOverview.StartDateFilterFormula.SetValue('CM+1D');
        AccSchedOverview.EndDateFilterFormula.SetValue('CM+1M');

        // [THEN] The date filter is updated based on the new formulas, and the period formula is cleared
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<CM+1D>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CM+1M>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
        AccSchedOverview.Close();
        FinancialReport.Find();
        Assert.AreEqual('', FinancialReport.DateFilterPeriodFormula, 'The date filter period formula should be empty');
        Assert.AreEqual(0, FinancialReport.DateFilterPeriodFormulaLID, 'The date filter period formula language ID should be 0');
    end;

    [Test]
    procedure DateFilterPeriodFormulaOverride()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
        LastLangId: Integer;
    begin
        // [SCENARIO] Setting the period formula on the page will clear the start and end date filter formulas
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with start and end date filter formulas
        FinancialReport.Get(AccScheduleName.Name);
        Evaluate(FinancialReport.StartDateFilterFormula, '-CY');
        Evaluate(FinancialReport.EndDateFilterFormula, 'CY');
        FinancialReport.Modify();

        // [WHEN] The period formula is set on the page
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        LastLangId := GlobalLanguage();
        GlobalLanguage(1033);
        AccSchedOverview.DateFilterPeriodFormula.SetValue('1P');
        GlobalLanguage(LastLangId);

        // [THEN] The date filter is updated based on the new formula, and the start and end date filter formulas are cleared
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<CM+1D>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<1M+CM>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
        AccSchedOverview.Close();
        FinancialReport.Find();
        Assert.AreEqual('', Format(FinancialReport.StartDateFilterFormula), 'The start date filter formula should be empty');
        Assert.AreEqual('', Format(FinancialReport.EndDateFilterFormula), 'The end date filter formula should be empty');
    end;

    [Test]
    procedure ExportScheduleToEmailAndInbox()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        EmailAccount: Record "Email Account";
        FinancialReportSchedule: Record "Financial Report Schedule";
        FinancialReportExportLog: Record "Financial Report Export Log";
        ReportInbox: Record "Report Inbox";
        User: Record User;
        EmailMessage: Codeunit "Email Message";
        EmailScenario: Codeunit "Email Scenario";
        FinancialReportExportJob: Codeunit "Financial Report Export Job";
        NewUserId: Code[50];
        UserEmail: Text[100];
        Recipients: List of [Text];
        AttachmentTypes: List of [Text];
    begin
        // [SCENARIO] Exporting a financial report schedule will send an email and create inbox entries
        Initialize();
        ClearSchedules();
        ClearScheduleJobQueueEntry();

        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(EmailAccount, Enum::"Email Connector"::"Test Email Connector");
        EmailScenario.SetEmailAccount(Enum::"Email Scenario"::"Financial Report", EmailAccount);

        NewUserId := LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), Database::User);
        UserEmail := 'user@cronus.com';
        CreateUserSetupWithEmail(NewUserId, UserEmail);

        // [GIVEN] A financial report
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithAmount(AccScheduleName.Name);

        // [GIVEN] A financial report schedule with a recipient
        FinancialReportSchedule := CreateSchedule(AccScheduleName.Name, true, true, true);
        CreateUserRecipient(NewUserId, AccScheduleName.Name, FinancialReportSchedule.Code);

        Commit();

        // [WHEN] The financial report schedule export job is run
        FinancialReportExportJob.Run();

        // [THEN] An export log entry is created
        FinancialReportExportLog.SetRange("Financial Report Schedule Code", FinancialReportSchedule.Code);
        Assert.IsTrue(FinancialReportExportLog.FindFirst(), 'The financial report export log entry was not created');

        // [THEN] An email containing both attachments is sent to the recipient
        EmailMessage.Get(ConnectorMock.GetEmailMessageID());
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"To", Recipients);
        Assert.AreEqual(1, Recipients.Count(), 'There should be 1 recipient');
        Assert.AreEqual(UserEmail, Recipients.Get(1), 'Recipient email does not match');

        AttachmentTypes.Add(ExcelContentTypeTxt);
        AttachmentTypes.Add(PDFContentTypeTxt);

        Assert.IsTrue(EmailMessage.Attachments_First(), 'There should be the first attachment');
        AttachmentTypes.Remove(EmailMessage.Attachments_GetContentType());
        Assert.AreEqual(1, EmailMessage.Attachments_Next(), 'There should be the second and last attachment');
        AttachmentTypes.Remove(EmailMessage.Attachments_GetContentType());
        Assert.AreEqual(0, AttachmentTypes.Count(), 'Not all attachment types were found');

        // [THEN] An inbox entry is created for the PDF and Excel reports
        ReportInbox.SetRange("User ID", NewUserId);
        ReportInbox.SetRange("Report ID", Report::"Account Schedule");
        Assert.IsTrue(ReportInbox.FindFirst(), 'The PDF report inbox entry was not created');
        ReportInbox.SetRange("Report ID", Report::"Export Acc. Sched. to Excel");
        Assert.IsFalse(ReportInbox.IsEmpty(), 'The Excel report inbox entry was not created');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    procedure StoreScheduleFilter()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        DimensionValue: Record "Dimension Value";
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        // [SCENARIO] Editing filters on the financial report schedule page will store the filters
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");

        // [GIVEN] A financial report schedule
        FinancialReportSchedule := CreateSchedule(AccScheduleName.Name, false, false, false);

        // [WHEN] The alternating shading and dimension 1 filter are set on the request page
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        EditScheduleFilters(FinancialReportSchedule);

        // [THEN] The filters are stored on the schedule
        AccScheduleLine.SetView(FinancialReportSchedule.GetReportFilters());
        Assert.AreEqual(DimensionValue.Code, AccScheduleLine.GetFilter("Dimension 1 Filter"), 'The dimension 1 filter was not stored');
    end;

    [Test]
    procedure ExportDefaultFilteredPDFReport()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        DimensionValue: Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        EmailMessage: Codeunit "Email Message";
        FinancialReportExportJob: Codeunit "Financial Report Export Job";
        FinReportExportPDFHandler: Codeunit "Fin. Report Export Handler";
        UserNames: List of [Text[65]];
    begin
        // [SCENARIO] Exporting a financial report schedule will use the default filters if no filters are set on the schedule
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithAmount(AccScheduleName.Name);
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        FinancialReport.Get(AccScheduleName.Name);
        UserNames.Add(UserId());

        // [GIVEN] A financial report with a dimension 1 filter
        FinancialReport.Dim1Filter := DimensionValue.Code;
        FinancialReport.Modify();

        // [GIVEN] A financial report schedule with no filters
        FinancialReportSchedule := CreateSchedule(AccScheduleName.Name, false, true, false);

        // [WHEN] The financial report schedule is exported
        BindSubscription(FinReportExportPDFHandler);
        FinancialReportExportJob.ExportPdf(FinancialReportSchedule, FinancialReport, '', CreateGuid(), UserNames, EmailMessage);
        UnbindSubscription(FinReportExportPDFHandler);

        // [THEN] The report is filtered based on the default filters
        LibraryReportDataSet.LoadFromInStream(FinReportExportPDFHandler.GetStream());
        AccScheduleLine.SetRange("Dimension 1 Filter", DimensionValue.Code);
        Assert.IsTrue(LibraryReportDataset.FindRow('AccSchedLineFilter', AccScheduleLine.GetFilters()) >= 0, 'The report was not filtered based on the schedule');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    procedure ExportScheduleFilteredPDFReport()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        DimensionValueA: Record "Dimension Value";
        DimensionValueB: Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        EmailMessage: Codeunit "Email Message";
        FinancialReportExportJob: Codeunit "Financial Report Export Job";
        FinReportExportHandler: Codeunit "Fin. Report Export Handler";
        UserNames: List of [Text[65]];
    begin
        // [SCENARIO] Exporting a financial report schedule will filter the report based on the schedule, overriding the default filters
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithAmount(AccScheduleName.Name);
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValueA, GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValueB, GLSetup."Global Dimension 1 Code");
        FinancialReport.Get(AccScheduleName.Name);
        UserNames.Add(UserId());

        // [GIVEN] A financial report with a dimension 1 filter
        FinancialReport.Dim1Filter := DimensionValueA.Code;
        FinancialReport.Modify();

        // [GIVEN] A financial report schedule with a different dimension 1 filter
        FinancialReportSchedule := CreateSchedule(AccScheduleName.Name, false, true, false);
        LibraryVariableStorage.Enqueue(DimensionValueB.Code);
        EditScheduleFilters(FinancialReportSchedule);

        // [WHEN] The financial report schedule is exported
        BindSubscription(FinReportExportHandler);
        FinancialReportExportJob.ExportPdf(FinancialReportSchedule, FinancialReport, '', CreateGuid(), UserNames, EmailMessage);

        // [THEN] The report is filtered based on the schedule
        LibraryReportDataSet.LoadFromInStream(FinReportExportHandler.GetStream());
        AccScheduleLine.SetRange("Dimension 1 Filter", DimensionValueB.Code);
        Assert.IsTrue(LibraryReportDataset.FindRow('AccSchedLineFilter', AccScheduleLine.GetFilters()) >= 0, 'The report was not filtered based on the schedule');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    procedure ExportScheduleFilteredExcelReport()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        DimensionValueA: Record "Dimension Value";
        DimensionValueB: Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        EmailMessage: Codeunit "Email Message";
        FinancialReportExportJob: Codeunit "Financial Report Export Job";
        FinReportExportHandler: Codeunit "Fin. Report Export Handler";
        TempBlob: Codeunit "Temp Blob";
        UserNames: List of [Text[65]];
    begin

        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithAmount(AccScheduleName.Name);
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValueA, GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValueB, GLSetup."Global Dimension 1 Code");
        FinancialReport.Get(AccScheduleName.Name);
        UserNames.Add(UserId());

        // [GIVEN] A financial report with a dimension 1 filter
        FinancialReport.Dim1Filter := DimensionValueA.Code;
        FinancialReport.Modify();

        // [GIVEN] A financial report schedule with a different dimension 1 filter
        FinancialReportSchedule := CreateSchedule(AccScheduleName.Name, true, false, false);
        LibraryVariableStorage.Enqueue(DimensionValueB.Code);
        EditScheduleFilters(FinancialReportSchedule);

        BindSubscription(FinReportExportHandler);
        FinancialReportExportJob.ExportExcel(FinancialReportSchedule, FinancialReport, '', CreateGuid(), UserNames, EmailMessage);

        FinReportExportHandler.GetBlob(TempBlob);
        LibraryReportValidation.SetFileName(AccScheduleName.Name);
        FileMgt.DeleteServerFile(LibraryReportValidation.GetFileName());
        FileMgt.BLOBExportToServerFile(TempBlob, LibraryReportValidation.GetFileName());
        LibraryReportValidation.VerifyCellValue(3, 2, DimensionValueB.Code);
    end;

    [RequestPageHandler]
    procedure AccountScheduleRequestPageHandler(var RequestPage: TestRequestPage "Account Schedule")
    begin
        RequestPage.Dim1Filter.SetValue(LibraryVariableStorage.DequeueText());
        RequestPage.OK().Invoke();
    end;

    local procedure Initialize()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        FinancialReportMgt.Initialize();
        IsInitialized := true;
        Commit();
    end;

    local procedure OpenAccountScheduleOverviewPage(Name: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        FinancialReports.Overview.Invoke();
    end;

    local procedure CreateGLAccountWithNetChange(NetChange: Decimal) GLAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo, NetChange);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAccScheduleLineWithAmount(Name: Code[10]) AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, Name);
        AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::"Posting Accounts";
        AccScheduleLine.Totaling := CreateGLAccountWithNetChange(LibraryRandom.RandDecInRange(1000, 2000, 2));
        AccScheduleLine.Modify();
    end;

    local procedure ClearSchedules()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.DeleteAll(true);
    end;

    local procedure ClearScheduleJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Financial Report Export Job");
        JobQueueEntry.DeleteAll();
    end;

    local procedure CreateSchedule(Name: Text[10]; ExportExcel: Boolean; ExportPDF: Boolean; SendEmail: Boolean) FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.Init();
        FinancialReportSchedule."Financial Report Name" := Name;
        FinancialReportSchedule.Code := LibraryUtility.GenerateGUID();
        FinancialReportSchedule."Export to Excel" := ExportExcel;
        FinancialReportSchedule."Export to PDF" := ExportPDF;
        FinancialReportSchedule."Send Email" := SendEmail;
        FinancialReportSchedule."Next Run Date/Time" := CurrentDateTime();
        FinancialReportSchedule.Insert(true);
    end;

    local procedure CreateUserSetupWithEmail(NewUserId: Code[50]; Email: Text[100])
    var
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        User.SetRange("User Name", NewUserId);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := NewUserId;
            User.Insert();
        end else
            if User.State = User.State::Disabled then begin
                User."State" := User.State::Enabled;
                User.Modify();
            end;

        if not UserSetup.Get(NewUserId) then begin
            UserSetup.Init();
            UserSetup."User ID" := NewUserId;
            UserSetup.Insert();
        end;
        UserSetup."E-Mail" := Email;
        UserSetup.Modify();
    end;

    local procedure CreateUserRecipient(NewUserId: Code[50]; Name: Text[10]; ScheduleCode: Code[20]) FinancialReportRecipient: Record "Financial Report Recipient";
    begin
        FinancialReportRecipient.Init();
        FinancialReportRecipient."Financial Report Name" := Name;
        FinancialReportRecipient."Financial Report Schedule Code" := ScheduleCode;
        FinancialReportRecipient.Validate("User ID", NewUserId);
        FinancialReportRecipient.Insert(true);
    end;

    local procedure EditScheduleFilters(var FinancialReportSchedule: Record "Financial Report Schedule")
    var
        FinancialReportSchedules: TestPage "Financial Report Schedules";
    begin
        Commit();
        FinancialReportSchedules.OpenEdit();
        FinancialReportSchedules.GoToRecord(FinancialReportSchedule);
        FinancialReportSchedules.CustomFilters.Invoke();
        FinancialReportSchedule.Find();
    end;

}
