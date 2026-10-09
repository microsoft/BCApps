// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50152 "Filename Filter Tests"
{
    // Filter placeholders: a FlowFilter field a report's request page declares, such as the Date
    // Filter on Detail Trial Balance. Available Placeholders offers them with Source "Filter", so the
    // promise it makes - nothing is offered that cannot be filled in - holds only if a run that
    // sets the filter is named from it. A FlowFilter holds no value on a record; the value exists
    // only as the filter the run was given.
    //
    // Named through the manager with the platform's own filterviews payload, the one source every
    // route carries, rather than through a page.
    //
    // Also here, because it is the other rule about what a run is named from rather than which
    // records: the language of a record that names none. It is the company's default, which is
    // Microsoft's own rule, and not the language of whoever produces the file.
    //
    // And the financial report's period, [Period], which is the same idea for report 25: the
    // period is a variable of the report rather than a filter, and is captured as the request page
    // closes. Those tests drive Base Application's own entry points - Financial Report Mgt.Print,
    // the Acc. Schedule Overview's Print action, a Financial Report Export Log row - with the
    // feature switched off while the report runs, so the run's subject and period are still
    // recorded afterwards, and then name the run through the manager exactly as the naming hook
    // does. Switched on during the run, the preview's own naming hook would take them first.

    Subtype = Test;
    TestPermissions = Disabled;

    var
        TypedFirst: Date;
        TypedLast: Date;
        ClearTheDates: Boolean;
        SwitchTo: Code[10];

    [Test]
    procedure ThePeriodIsOfferedForFinancialReportsOnly()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Prepare();
        Pattern.Init();
        Pattern."Report ID" := Report::"Account Schedule";
        Pattern.Validate("Table No.", Database::"Financial Report");
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::Computed);
        TempPlaceholderBuffer.SetRange(Placeholder, PeriodPlaceholderTok);
        if TempPlaceholderBuffer.IsEmpty() then
            Error(NotOfferedForFinancialReportErr, PeriodPlaceholderTok);

        Clear(Pattern);
        Clear(TempPlaceholderBuffer);
        TempPlaceholderBuffer.DeleteAll();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Detail Trial Balance");
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        TempPlaceholderBuffer.SetRange(Placeholder, PeriodPlaceholderTok);
        if not TempPlaceholderBuffer.IsEmpty() then
            Error(OfferedElsewhereErr, PeriodPlaceholderTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure AFinancialReportIsNamedByTheDatesTypedOnItsRequestPage()
    begin
        PrepareFinancialReportRun(PeriodPatternTok);
        TypedFirst := 20260101D;
        TypedLast := 20261231D;

        PrintFromTheList(PeriodColumnsReport());

        AssertNamed(FinancialReportPrefixTok + TypedYearTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure ClearedDatesAreNamedByTheReportsOwnDefaults()
    begin
        // Report 25's UpdateFilters: no Ending Date is the work date, no Starting Date the first of
        // that month.
        PrepareFinancialReportRun(PeriodPatternTok);
        WorkDate(20260915D);
        ClearTheDates := true;

        PrintFromTheList(PeriodColumnsReport());

        AssertNamed(FinancialReportPrefixTok + MonthToWorkDateTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure TheOverviewsPeriodNamesTheReportItPrints()
    begin
        PrepareFinancialReportRun(PeriodPatternTok);

        PrintFromTheOverview(PeriodColumnsReport(), StrSubstNo(DateRangeTok, 20260101D, 20260331D));

        AssertNamed(FinancialReportPrefixTok + FirstQuarterTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure ABalanceAtDateReportIsNamedByItsLastDate()
    begin
        // From the overview, report 25 switches Starting Date off for columns that are all Balance
        // at Date and prints "Period Ending" with the last date alone.
        PrepareFinancialReportRun(PeriodPatternTok);

        PrintFromTheOverview(BalanceOnlyReport(), StrSubstNo(DateRangeTok, 20260101D, 20260331D));

        AssertNamed(FinancialReportPrefixTok + EndOfFirstQuarterTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure AFinancialReportChosenOnTheRequestPageIsTheOneNamed()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // The overview's request page lets the Financial Report be changed, and report 25 then runs
        // the one chosen. The name must follow it rather than the one the overview was opened on.
        PrepareFinancialReportRun(NamedPatternTok);
        SwitchTo := BalanceOnlyReport();
        FinancialReport.Get(SwitchTo);

        PrintFromTheOverview(PeriodColumnsReport(), StrSubstNo(DateRangeTok, 20260101D, 20260331D));

        AssertNamed(ReportFilenameMgt.Sanitise(FinancialReport.Description) + '-' + EndOfFirstQuarterTok);
    end;

    [Test]
    [HandlerFunctions('PeriodRequestPageHandler')]
    procedure AFinancialReportRunFromARoleCentreIsNamedByWhatItsRequestPageChose()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // A role centre runs report 25 as RunObject, with nothing recorded beforehand: the financial
        // report and the period are chosen on the request page, and are what the run is about.
        PrepareFinancialReportRun(NamedPatternTok);
        SwitchTo := PeriodColumnsReport();
        FinancialReport.Get(SwitchTo);
        TypedFirst := 20260101D;
        TypedLast := 20261231D;

        Commit();
        Report.Run(Report::"Account Schedule");

        AssertRunRecorded(FinancialReport.Name);
        AssertNamed(ReportFilenameMgt.Sanitise(FinancialReport.Description) + '-' + TypedYearTok);
    end;

    [Test]
    procedure APeriodNamesOneRunAndNoOther()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        SubjectRecRef: RecordRef;
        Filename: Text;
    begin
        // Recorded with a period, named once; recorded again without one, the same financial report
        // must decline rather than be named after the period that went before.
        PrepareFinancialReportRun(PeriodPatternTok);
        SetFeature(true);
        FinancialReport.Get(PeriodColumnsReport());
        SubjectRecRef.GetTable(FinancialReport);

        ReportFilenameContext.SetRunSubject(SubjectRecRef, Report::"Account Schedule");
        ReportFilenameContext.SetRunSubjectPeriod(20260101D, 20261231D);
        AssertNamed(FinancialReportPrefixTok + TypedYearTok);

        ReportFilenameContext.SetRunSubject(SubjectRecRef, Report::"Account Schedule");
        if TryNameFinancialReportRun(Filename) then
            Error(PeriodOutlivedItsRunErr, Filename);
    end;

    [Test]
    procedure AScheduledFinancialReportIsNamedByItsSchedulesPeriod()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
        ReportInbox: Record "Report Inbox";
    begin
        // The export job's own first step is the export log row, and the schedule's date formulas
        // decide the period; the Report Inbox row inserted afterwards is named from both.
        PrepareFinancialReportRun(PeriodPatternTok);
        SetFeature(true);
        WorkDate(20260915D);
        StartScheduledExport(FinancialReportSchedule);

        ReportInbox.Init();
        ReportInbox."Entry No." := 0;
        ReportInbox."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Report ID" := Report::"Account Schedule";
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Created Date-Time" := CurrentDateTime();
        ReportInbox.Insert(true);
        ReportInbox.Get(ReportInbox."Entry No.");
        // Finished as the job finishes it, so the export's subject does not outlive this test.
        FinancialReportSchedule.Modify();

        if ReportInbox."File Name" <> FinancialReportPrefixTok + TypedYearTok then
            Error(WrongScheduledNameErr, FinancialReportPrefixTok + TypedYearTok, ReportInbox."File Name");
    end;

    /// <summary>
    /// A Time field has no file name form - resolving one gives nothing - so offering it would make
    /// a pattern that never names a file. Found by the documentation audit on 6 October: the picker
    /// offered Time fields with an example, while the design said they were excluded. Checked on
    /// whichever table holds a public Time field, with the table's other fields as the control.
    /// </summary>
    [Test]
    procedure ATimeFieldIsNotOfferedAsAPlaceholder()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        TimeField: Record Field;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Prepare();
        TimeField.SetRange(Type, TimeField.Type::Time);
        TimeField.SetRange(Class, TimeField.Class::Normal);
        TimeField.SetRange(Enabled, true);
        TimeField.SetRange(ObsoleteState, TimeField.ObsoleteState::No);
        TimeField.SetRange(Access, TimeField.Access::Public);
        TimeField.SetFilter(TableNo, '<%1', 2000000000);
        if not TimeField.FindFirst() then
            Error(NoTimeFieldErr);
        Pattern.Init();
        Pattern.Validate("Table No.", TimeField.TableNo);

        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::"Record Field");
        if TempPlaceholderBuffer.IsEmpty() then
            Error(NoFieldsOfferedErr, TimeField.TableNo);
        TempPlaceholderBuffer.SetRange("Field No.", TimeField."No.");
        if not TempPlaceholderBuffer.IsEmpty() then
            Error(TimeFieldOfferedErr, TimeField."Field Caption", TimeField.TableNo);
    end;

    /// <summary>
    /// Decided by the user on 7 October: in Available Placeholders the filters come straight after
    /// the computed values, then the record's fields, then the tables one relation away. Read in the
    /// page's own order (its Tree key) for Detail Trial Balance, whose request page offers Date
    /// Filter, so every kind is present.
    /// </summary>
    [Test]
    procedure TheFiltersFollowTheComputedPlaceholders()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        Seen: List of [Integer];
        Rank: Integer;
        Highest: Integer;
        Order: Text;
    begin
        Prepare();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Detail Trial Balance");
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);

        TempPlaceholderBuffer.SetCurrentKey("Sort Order", Source, "Group Name", Indentation, Placeholder);
        Highest := 0;
        if TempPlaceholderBuffer.FindSet() then
            repeat
                Rank := ExpectedRank(TempPlaceholderBuffer.Source);
                if not Seen.Contains(Rank) then begin
                    Seen.Add(Rank);
                    Order += Format(TempPlaceholderBuffer.Source) + ' ';
                end;
                if Rank < Highest then
                    Error(WrongPlaceholderOrderErr, TempPlaceholderBuffer.Placeholder, Order);
                Highest := Rank;
            until TempPlaceholderBuffer.Next() = 0;
        if Seen.Count() <> 4 then
            Error(NotEveryKindOfferedErr, Order);
    end;

    local procedure ExpectedRank(PlaceholderSource: Enum "Report Filename Plh. Source"): Integer
    begin
        case PlaceholderSource of
            PlaceholderSource::Computed:
                exit(1);
            PlaceholderSource::"Request Filter":
                exit(2);
            PlaceholderSource::"Record Field":
                exit(3);
            PlaceholderSource::"Related Field":
                exit(4);
        end;
        Error(UnknownPlaceholderKindErr, PlaceholderSource);
    end;

    [Test]
    procedure TheDateFilterIsOfferedAsAPlaceholder()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Prepare();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Detail Trial Balance");

        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::"Request Filter");
        TempPlaceholderBuffer.SetRange(Placeholder, DateFilterPlaceholderTok);
        if TempPlaceholderBuffer.IsEmpty() then
            Error(NotOfferedErr, DateFilterPlaceholderTok);
    end;

    [Test]
    procedure ARunIsNamedFromItsDateFilter()
    var
        Pattern: Record "Report Filename Pattern";
        GLAccount: Record "G/L Account";
        Filename: Text;
    begin
        Prepare();
        CreatePattern(Pattern);

        GLAccount.SetRange("Date Filter", 20250101D, 20250131D);
        Filename := NameRun(GLAccount);

        if StrPos(Filename, ExpectedRangeTok) = 0 then
            Error(WrongNameErr, ExpectedRangeTok, Filename);
    end;

    [Test]
    procedure ASingleDateIsNamedOnce()
    var
        Pattern: Record "Report Filename Pattern";
        GLAccount: Record "G/L Account";
        Filename: Text;
    begin
        Prepare();
        CreatePattern(Pattern);

        GLAccount.SetRange("Date Filter", 20250131D);
        Filename := NameRun(GLAccount);

        if StrPos(Filename, ExpectedSingleTok) = 0 then
            Error(WrongNameErr, ExpectedSingleTok, Filename);
        if StrPos(Filename, ExpectedRangeTok) > 0 then
            Error(WrongNameErr, ExpectedSingleTok, Filename);
    end;

    [Test]
    procedure ARunWithoutTheFilterIsNotNamedWithAGap()
    var
        Pattern: Record "Report Filename Pattern";
        GLAccount: Record "G/L Account";
        Filename: Text;
    begin
        // No date filter means the placeholder has no value, and a pattern is used only when every
        // placeholder has one - so the run keeps Business Central's own name rather than becoming
        // "TB-.pdf".
        Prepare();
        CreatePattern(Pattern);

        GLAccount.SetRange("No.", '1000', '9999');
        if TryNameRun(GLAccount, Filename) then
            Error(NamedWithAGapErr, Filename);
    end;

    [Test]
    procedure AnOpenEndedRangeIsNotNamed()
    var
        Pattern: Record "Report Filename Pattern";
        GLAccount: Record "G/L Account";
        Filename: Text;
    begin
        // "Up to the end of January" has no first date, so the placeholder has no one answer.
        Prepare();
        CreatePattern(Pattern);

        GLAccount.SetFilter("Date Filter", '..%1', 20250131D);
        if TryNameRun(GLAccount, Filename) then
            Error(ShouldNotBeNamedErr, GLAccount.GetFilters(), Filename);
    end;

    [Test]
    procedure AListOfDatesIsNotNamed()
    var
        Pattern: Record "Report Filename Pattern";
        GLAccount: Record "G/L Account";
        Filename: Text;
    begin
        // Two separate dates are not a range, and naming the file after the span between them
        // would claim the days in between.
        Prepare();
        CreatePattern(Pattern);

        GLAccount.SetFilter("Date Filter", '%1|%2', 20250101D, 20250131D);
        if TryNameRun(GLAccount, Filename) then
            Error(ShouldNotBeNamedErr, GLAccount.GetFilters(), Filename);
    end;

    [Test]
    procedure ARecordWithNoLanguageTakesTheCompanyDefault()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInformation: Record "Company Information";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        NoRecord: RecordRef;
        Filename: Text;
    begin
        // The session is English (Prepare), the invoice names no language, and the company's
        // default is German - so a pattern for DEU applies only if the company's default is what
        // decides. Falling back to the user's language, as naming once did, leaves it unnamed.
        Prepare();
        SalesInvoiceHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader."Language Code" := '';
        SalesInvoiceHeader.Modify();
        CompanyInformation.Get();
        CompanyInformation."Default Language Code" := GermanLanguageTok;
        CompanyInformation.Modify();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Language Code", GermanLanguageTok);
        Pattern.Validate("File Name Pattern", GermanPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download,
            NoRecord, FilenameProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Filename)
        then
            Error(CompanyLanguageIgnoredErr, GermanLanguageTok, SalesInvoiceHeader."No.");
        if StrPos(Filename, GermanPrefixTok + SalesInvoiceHeader."No.") = 0 then
            Error(WrongNameErr, GermanPrefixTok + SalesInvoiceHeader."No.", Filename);
    end;

    local procedure NameRun(var GLAccount: Record "G/L Account") Filename: Text
    begin
        if not TryNameRun(GLAccount, Filename) then
            Error(NotNamedErr, GLAccount.GetFilters());
    end;

    local procedure TryNameRun(var GLAccount: Record "G/L Account"; var Filename: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        NoRecord: RecordRef;
    begin
        exit(ReportFilenameMgt.TryResolve(
            Report::"Detail Trial Balance", Enum::"Report Filename Output Route"::Download, NoRecord, FilterViewsFor(GLAccount), Filename));
    end;

    /// <summary>
    /// The filterviews payload the platform hands the naming hook for a Detail Trial Balance run with the
    /// G/L Account's filters: one entry per data item, the view written with field numbers.
    /// </summary>
    local procedure FilterViewsFor(var GLAccount: Record "G/L Account") Payload: Text
    var
        Entry: JsonObject;
        Views: JsonArray;
    begin
        Entry.Add('name', GLAccountDataItemTok);
        Entry.Add('tableid', Database::"G/L Account");
        Entry.Add('view', GLAccount.GetView(false));
        Views.Add(Entry);
        Views.WriteTo(Payload);
    end;

    [Test]
    procedure AScheduledExportNamesEveryFileItProduces()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
        ReportInbox: Record "Report Inbox";
        WorkbookInbox: Record "Report Inbox";
    begin
        // Measured on 28 September: a schedule exporting a workbook and a PDF named neither. The
        // export writes the workbook rows (report 29) first, and naming one cleared the subject
        // the PDF rows (report 25) then needed. Here the workbook row comes first, as it does there.
        // Report 29 is processing-only and can have no pattern, so the workbook is named by the
        // financial report's own pattern: the same name as the PDF, another extension.
        PrepareFinancialReportRun(PeriodPatternTok);
        SetFeature(true);
        WorkDate(20260915D);
        StartScheduledExport(FinancialReportSchedule);

        WorkbookInbox.Get(InsertExportInboxRow(Report::"Export Acc. Sched. to Excel", ReportInbox."Output Type"::Excel));
        ReportInbox.Get(InsertExportInboxRow(Report::"Account Schedule", ReportInbox."Output Type"::PDF));
        // Finished as the job finishes it, so the export's subject does not outlive this test.
        FinancialReportSchedule.Modify();

        if ReportInbox."File Name" <> FinancialReportPrefixTok + TypedYearTok then
            Error(WrongScheduledNameErr, FinancialReportPrefixTok + TypedYearTok, ReportInbox."File Name");
        if WorkbookInbox."File Name" <> ReportInbox."File Name" then
            Error(WorkbookNotNamedLikeThePdfErr, ReportInbox."File Name", WorkbookInbox."File Name");
    end;

    [Test]
    procedure AWorkbookOpenedFromTheOverviewIsNamedLikeItsPdf()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
        FileName: Text;
    begin
        // What the overview's Open in Excel records, with the same financial report and date filter
        // TheOverviewsPeriodNamesTheReportItPrints prints: the workbook takes the same name.
        PrepareFinancialReportRun(PeriodPatternTok);
        SetFeature(true);
        FinancialReport.Get(PeriodColumnsReport());

        ReportFilenameFinRepSub.RecordExcelExport(FinancialReport.Name, FinancialReport."Financial Report Column Group",
            FinancialReport."Financial Report Row Group" <> '', StrSubstNo(DateRangeTok, 20260101D, 20260331D));

        if not ReportFilenameFinRepSub.TryNameExcelDownload(FileName) then
            Error(WorkbookNotNamedErr, FinancialReportPrefixTok + FirstQuarterTok + ExcelExtensionTok);
        if FileName <> FinancialReportPrefixTok + FirstQuarterTok + ExcelExtensionTok then
            Error(WorkbookNamedWronglyErr, FinancialReportPrefixTok + FirstQuarterTok + ExcelExtensionTok, FileName);
        // Taken: a second workbook is not named after this export.
        if ReportFilenameFinRepSub.TryNameExcelDownload(FileName) then
            Error(WorkbookNamedTwiceErr, FileName);
    end;

    [Test]
    procedure AnExportsSubjectEndsWithTheExport()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
        ReportInbox: Record "Report Inbox";
    begin
        // The export ends by modifying its schedule (next run date). After that nothing may be
        // named after its financial report, or a later run in the same session would inherit it.
        PrepareFinancialReportRun(PeriodPatternTok);
        SetFeature(true);
        WorkDate(20260915D);
        StartScheduledExport(FinancialReportSchedule);

        FinancialReportSchedule.Get(FinancialReportSchedule."Financial Report Name", FinancialReportSchedule.Code);
        FinancialReportSchedule.Modify();
        ReportInbox.Get(InsertExportInboxRow(Report::"Account Schedule", ReportInbox."Output Type"::PDF));

        if ReportInbox."File Name" <> '' then
            Error(NamedAfterTheExportErr, ReportInbox."File Name");
    end;

    /// <summary>
    /// What Financial Report Export Job does first: a schedule with date formulas for this year, and
    /// the export log row that names the financial report.
    /// </summary>
    local procedure StartScheduledExport(var FinancialReportSchedule: Record "Financial Report Schedule")
    var
        FinancialReport: Record "Financial Report";
        FinancialReportExportLog: Record "Financial Report Export Log";
    begin
        FinancialReport.Get(PeriodColumnsReport());
        // Tests share one rollback per codeunit, so an earlier test's schedule may still be here.
        if FinancialReportSchedule.Get(FinancialReport.Name, ScheduleCodeTok) then
            FinancialReportSchedule.Delete(false);
        FinancialReportSchedule.Init();
        FinancialReportSchedule."Financial Report Name" := FinancialReport.Name;
        FinancialReportSchedule.Code := ScheduleCodeTok;
        Evaluate(FinancialReportSchedule."Start Date Filter Formula", StartOfYearTok);
        Evaluate(FinancialReportSchedule."End Date Filter Formula", EndOfYearTok);
        FinancialReportSchedule.Insert(false);

        FinancialReportExportLog.Init();
        FinancialReportExportLog."Financial Report Name" := FinancialReport.Name;
        FinancialReportExportLog."Financial Report Schedule Code" := FinancialReportSchedule.Code;
        FinancialReportExportLog."Start Date/Time" := CurrentDateTime();
        FinancialReportExportLog.Insert();
    end;

    /// <summary>
    /// A Report Inbox row as the export's CreateInboxEntries inserts it.
    /// </summary>
    local procedure InsertExportInboxRow(ReportId: Integer; OutputType: Enum "Report Inbox Output Type"): Integer
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Init();
        ReportInbox."Entry No." := 0;
        ReportInbox."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Report ID" := ReportId;
        ReportInbox."Output Type" := OutputType;
        ReportInbox."Created Date-Time" := CurrentDateTime();
        ReportInbox.Insert(true);
        exit(ReportInbox."Entry No.");
    end;

    /// <summary>
    /// A financial report run with its request page, the way the Financial Reports list prints one.
    /// </summary>
    local procedure PrintFromTheList(FinancialReportName: Code[10])
    var
        FinancialReport: Record "Financial Report";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReport.Get(FinancialReportName);
        // The request page is modal and cannot open inside the write transaction the test's own
        // setup started ("An error occurred and the transaction is stopped"). The runner rolls the
        // whole codeunit back afterwards, committed changes included.
        Commit();
        FinancialReportMgt.Print(FinancialReport);
    end;

    /// <summary>
    /// A financial report printed from its overview, with the overview's own date filter - the
    /// overview's Print action, pressed on the page.
    /// </summary>
    local procedure PrintFromTheOverview(FinancialReportName: Code[10]; DateFilterText: Text)
    var
        FinancialReports: TestPage "Financial Reports";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // As in PrintFromTheList: the request page cannot open inside the setup's transaction.
        Commit();
        FinancialReports.OpenView();
        FinancialReports.GoToKey(FinancialReportName);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.DateFilter.SetValue(DateFilterText);
        // The client commits each page interaction on its own; a test page does not, so the
        // overview's writes as its date filter is set would otherwise hold the request page off.
        Commit();
        AccScheduleOverview.Print.Invoke();
        AccScheduleOverview.Close();
        FinancialReports.Close();
    end;

    [RequestPageHandler]
    procedure PeriodRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        if SwitchTo <> '' then
            AccountSchedule.FinancialReport.SetValue(SwitchTo);
        if ClearTheDates then begin
            AccountSchedule.StartDate.SetValue('');
            AccountSchedule.EndDate.SetValue('');
        end;
        if TypedLast <> 0D then begin
            AccountSchedule.StartDate.SetValue(TypedFirst);
            AccountSchedule.EndDate.SetValue(TypedLast);
        end;
        // A report's request page has no OK; Preview closes it the way Print and Send to do.
        AccountSchedule.Preview().Invoke();
    end;

    /// <summary>
    /// Names the run just made, as the naming hook does: report 25, printed, no record handed over.
    /// </summary>
    local procedure AssertNamed(Expected: Text)
    var
        Filename: Text;
    begin
        SetFeature(true);
        if not TryNameFinancialReportRun(Filename) then
            Error(FinancialReportNotNamedErr, Expected);
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);
    end;

    /// <summary>
    /// That the run's request page recorded this financial report, with a period - read back
    /// without taking either, so a failure says which half is missing.
    /// </summary>
    local procedure AssertRunRecorded(ExpectedName: Code[10])
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        Subject: RecordRef;
        FirstDate: Date;
        LastDate: Date;
    begin
        if not ReportFilenameContext.HasRunSubjectFor(Report::"Account Schedule") then
            Error(NothingRecordedErr, ExpectedName);
        ReportFilenameContext.TryPeekRunSubject(Report::"Account Schedule", Subject);
        Subject.FindFirst();
        Subject.SetTable(FinancialReport);
        if FinancialReport.Name <> ExpectedName then
            Error(WrongReportRecordedErr, ExpectedName, FinancialReport.Name);
        if not ReportFilenameContext.TryGetNamingPeriod(Subject, FirstDate, LastDate) then
            Error(NoPeriodRecordedErr, ExpectedName);
        ReportFilenameContext.ClearNamingPeriod();
    end;

    local procedure TryNameFinancialReportRun(var Filename: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        NoRecord: RecordRef;
    begin
        exit(ReportFilenameMgt.TryResolve(Report::"Account Schedule", Enum::"Report Filename Output Route"::Print, NoRecord, '', Filename));
    end;

    local procedure PrepareFinancialReportRun(PatternText: Text)
    begin
        Prepare();
        TypedFirst := 0D;
        TypedLast := 0D;
        ClearTheDates := false;
        SwitchTo := '';
        // Before the feature is switched off: the proof guard's ClearPatterns, which this calls,
        // switches it back on.
        CreateFinancialReportPattern(PatternText);
        // Off while the report runs, so the preview's own naming hook does not take the run's
        // subject and period before the test names the run itself.
        SetFeature(false);
    end;

    local procedure CreateFinancialReportPattern(PatternText: Text)
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern."Report ID" := Report::"Account Schedule";
        Pattern.Validate("Table No.", Database::"Financial Report");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure SetFeature(Enabled: Boolean)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := Enabled;
        ReportFilenameSetup.Modify();
    end;

    /// <summary>
    /// A financial report whose columns include one that is not Balance at Date, so report 25
    /// keeps Starting Date.
    /// </summary>
    local procedure PeriodColumnsReport(): Code[10]
    begin
        exit(FindFinancialReport(true));
    end;

    /// <summary>
    /// A financial report whose columns are all Balance at Date, so report 25 can switch Starting
    /// Date off.
    /// </summary>
    local procedure BalanceOnlyReport(): Code[10]
    begin
        exit(FindFinancialReport(false));
    end;

    local procedure FindFinancialReport(WithPeriodColumn: Boolean): Code[10]
    var
        FinancialReport: Record "Financial Report";
        ColumnLayout: Record "Column Layout";
    begin
        FinancialReport.SetFilter("Financial Report Column Group", '<>%1', '');
        FinancialReport.SetFilter("Financial Report Row Group", '<>%1', '');
        FinancialReport.SetFilter(Description, '<>%1', '');
        if FinancialReport.FindSet() then
            repeat
                ColumnLayout.SetRange("Column Layout Name", FinancialReport."Financial Report Column Group");
                ColumnLayout.SetFilter("Column Type", '<>%1', ColumnLayout."Column Type"::"Balance at Date");
                if WithPeriodColumn = not ColumnLayout.IsEmpty() then
                    exit(FinancialReport.Name);
            until FinancialReport.Next() = 0;
        Error(NoFinancialReportErr, WithPeriodColumn);
    end;

    local procedure CreatePattern(var Pattern: Record "Report Filename Pattern")
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Detail Trial Balance");
        Pattern.Validate("File Name Pattern", PatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure Prepare()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        FilenameProofGuard.ClearPatterns();
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Insert();
        end;
        ReportFilenameSetup.Enabled := true;
        ReportFilenameSetup.Modify();
    end;

    var
        PatternTok: Label 'TB-[Date Filter]', Locked = true;
        DateFilterPlaceholderTok: Label '[Date Filter]', Locked = true;
        GLAccountDataItemTok: Label 'G/L Account', Locked = true;
        // Year-Month-Day, the default date format, joined by the default separator and range word.
        ExpectedRangeTok: Label '2025-01-01-to-2025-01-31', Locked = true;
        ExpectedSingleTok: Label '2025-01-31', Locked = true;
        NotOfferedErr: Label 'Available Placeholders does not offer %1 for Detail Trial Balance.', Comment = '%1 the placeholder';
        WrongPlaceholderOrderErr: Label 'Available Placeholders shows %1 out of order; the kinds appear as: %2. Expected computed values, then filters, then fields, then related tables.', Comment = '%1 the placeholder, %2 the kinds in the order shown';
        NotEveryKindOfferedErr: Label 'Detail Trial Balance should offer all four kinds of placeholder, but the page shows only: %1', Comment = '%1 the kinds shown';
        UnknownPlaceholderKindErr: Label 'A placeholder of an unknown kind is offered: %1.', Comment = '%1 the kind';
        NoTimeFieldErr: Label 'No table in this installation has a public Time field, so the check cannot be made.';
        NoFieldsOfferedErr: Label 'Available Placeholders offers no field of table %1 at all, so the check would prove nothing.', Comment = '%1 the table number';
        TimeFieldOfferedErr: Label 'Available Placeholders offers the Time field %1 of table %2, which can never name a file.', Comment = '%1 the field caption, %2 the table number';
        NotNamedErr: Label 'A Detail Trial Balance run filtered to %1 was not named by the pattern.', Comment = '%1 the filters';
        WrongNameErr: Label 'The file name should contain %1, but it is %2.', Comment = '%1 expected part, %2 the name';
        GermanLanguageTok: Label 'DEU', Locked = true;
        GermanPatternTok: Label 'DE-[No.]', Locked = true;
        GermanPrefixTok: Label 'DE-', Locked = true;
        CompanyLanguageIgnoredErr: Label 'A %1 pattern did not name invoice %2, which names no language, although the company''s default language is %1.', Comment = '%1 language code, %2 invoice';
        ShouldNotBeNamedErr: Label 'A run filtered to %1 has no one date to name it after, but was named %2.', Comment = '%1 the filters, %2 the name';
        NamedWithAGapErr: Label 'A run with no date filter was named %1, with a gap where the date should be.', Comment = '%1 the name';
        PeriodPlaceholderTok: Label '[Period]', Locked = true;
        PeriodPatternTok: Label 'FR-[Period]', Locked = true;
        NamedPatternTok: Label '[Description]-[Period]', Locked = true;
        FinancialReportPrefixTok: Label 'FR-', Locked = true;
        DateRangeTok: Label '%1..%2', Locked = true;
        ScheduleCodeTok: Label 'FNPROOF', Locked = true;
        ExcelExtensionTok: Label '.xlsx', Locked = true;
        WorkbookNotNamedErr: Label 'The workbook opened from the overview was not named; expected %1.', Comment = '%1 expected name';
        WorkbookNamedWronglyErr: Label 'The workbook opened from the overview should be named %1, but is named %2.', Comment = '%1 expected, %2 actual';
        WorkbookNamedTwiceErr: Label 'A second workbook was named %1 after an export that had already been named.', Comment = '%1 the name';
        WorkbookNotNamedLikeThePdfErr: Label 'The scheduled workbook should be named like its PDF, %1, but its Report Inbox row is named %2.', Comment = '%1 the PDF''s name, %2 the workbook''s';
        StartOfYearTok: Label '<-CY>', Locked = true;
        EndOfYearTok: Label '<CY>', Locked = true;
        // In the default date format, joined by the default separator and range word.
        TypedYearTok: Label '2026-01-01-to-2026-12-31', Locked = true;
        MonthToWorkDateTok: Label '2026-09-01-to-2026-09-15', Locked = true;
        FirstQuarterTok: Label '2026-01-01-to-2026-03-31', Locked = true;
        EndOfFirstQuarterTok: Label '2026-03-31', Locked = true;
        NotOfferedForFinancialReportErr: Label 'Available Placeholders does not offer %1 for a financial report.', Comment = '%1 the placeholder';
        OfferedElsewhereErr: Label 'Available Placeholders offers %1 on Detail Trial Balance, which has no period of its own.', Comment = '%1 the placeholder';
        FinancialReportNotNamedErr: Label 'The financial report run was not named; expected %1.', Comment = '%1 expected name';
        PeriodOutlivedItsRunErr: Label 'A financial report recorded without a period was named %1, after the period of the run before.', Comment = '%1 the name';
        WrongScheduledNameErr: Label 'The scheduled financial report should be named %1, but its Report Inbox row is named %2.', Comment = '%1 expected, %2 actual';
        NamedAfterTheExportErr: Label 'A Report Inbox row inserted after the export had finished was named %1, after the export''s financial report.', Comment = '%1 the name';
        NothingRecordedErr: Label 'The request page closed with financial report %1, but no run was recorded.', Comment = '%1 financial report';
        WrongReportRecordedErr: Label 'The request page closed with financial report %1, but the run was recorded as %2.', Comment = '%1 expected, %2 recorded';
        NoPeriodRecordedErr: Label 'The run of financial report %1 was recorded without a period.', Comment = '%1 financial report';
        NoFinancialReportErr: Label 'This company has no financial report with rows, columns and a description whose columns include a period column = %1.', Comment = '%1 true or false';
}
