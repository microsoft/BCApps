// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.Reflection;

codeunit 149502 "Filename Filter Tests"
{
    // What a run is named from beyond its records: request-page filters (a FlowFilter has no value on
    // a record, only as the run's filter, passed here in the platform's filterviews payload), the
    // financial report's [Period] (a report 25 variable captured as the request page closes), and the
    // language of a record that names none (the company's default, not the user's).

    Subtype = Test;
    TestPermissions = Disabled;

    var
        NamingCapture: Codeunit "Filename Naming Capture";
        TestData: Codeunit "Filename Test Data";
        TypedFirst: Date;
        TypedLast: Date;
        ClearTheDates: Boolean;
        SwitchTo: Code[10];
        NamingCaptureBound: Boolean;

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
        // The name follows the financial report chosen on the request page, not the one the overview
        // was opened on.
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
        // A role centre runs report 25 with nothing recorded beforehand: report and period come from
        // the request page.
        PrepareFinancialReportRun(NamedPatternTok);
        SwitchTo := PeriodColumnsReport();
        FinancialReport.Get(SwitchTo);
        TypedFirst := 20260101D;
        TypedLast := 20261231D;

        Commit();
        Report.Run(Report::"Account Schedule");

        // Naming takes what was recorded, so it can be read back only if the run's hook did not name it.
        if not NamingCapture.HasNameFor(Report::"Account Schedule") then
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
        // Recorded again without a period, the run must not be named after the previous period.
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
        // The Report Inbox row is named from the export log row and the schedule's date formulas.
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
    /// A Time field resolves to nothing, so offering it would make a pattern that never names a file.
    /// The table's other fields are the control.
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
    /// Available Placeholders order: computed values, filters, record fields, related tables. Read in
    /// the page's Tree key order for Detail Trial Balance, which offers every kind.
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
        // A placeholder without a value means the pattern is not used, rather than naming "TB-.pdf".
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
        // Naming two separate dates as a span would claim the days in between.
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
        CompanyLanguageCode: Code[10];
        Filename: Text;
        Named: Boolean;
    begin
        // Session English, invoice without a language, company default German: the DEU pattern applies
        // only if the company's default decides.
        Prepare();
        TestData.EnsureLanguage(GermanLanguageTok, FilenameProofSupport.GermanLanguageId());
        TestData.PostNewInvoice(SalesInvoiceHeader);
        SalesInvoiceHeader."Language Code" := '';
        SalesInvoiceHeader.Modify();
        CompanyInformation.Get();
        CompanyLanguageCode := CompanyInformation."Default Language Code";
        CompanyInformation."Default Language Code" := GermanLanguageTok;
        CompanyInformation.Modify();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Language Code", GermanLanguageTok);
        Pattern.Validate("File Name Pattern", GermanPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        Named := ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download,
            NoRecord, FilenameProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Filename);

        // Restored before asserting: with codeunit isolation the runner rolls back only when the
        // codeunit ends, and later tests depend on the company's language.
        CompanyInformation."Default Language Code" := CompanyLanguageCode;
        CompanyInformation.Modify();

        if not Named then
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
    /// The filterviews payload as the platform gives it to the naming hook: one entry per data item.
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
        // The export writes the workbook row (report 29) before the PDF row (report 25); naming the
        // first must not clear the subject the second needs. Report 29 can have no pattern, so the
        // workbook takes the PDF's name.
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
        // Open in Excel from the overview, with the same input as TheOverviewsPeriodNamesTheReportItPrints.
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
        // The export ends by modifying its schedule; after that a later run must not inherit its subject.
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
    /// A schedule for this year, and the export log row Financial Report Export Job inserts first.
    /// </summary>
    local procedure StartScheduledExport(var FinancialReportSchedule: Record "Financial Report Schedule")
    var
        FinancialReport: Record "Financial Report";
        FinancialReportExportLog: Record "Financial Report Export Log";
    begin
        FinancialReport.Get(PeriodColumnsReport());
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

    // Inserted as the export's CreateInboxEntries inserts a row (Entry No. 0, Insert(true)), without the output.
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

    local procedure PrintFromTheList(FinancialReportName: Code[10])
    var
        FinancialReport: Record "Financial Report";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReport.Get(FinancialReportName);
        // The modal request page cannot open inside the setup's write transaction. With codeunit
        // isolation the runner still rolls back committed changes when the codeunit ends.
        Commit();
        FinancialReportMgt.Print(FinancialReport);
    end;

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
        // A test page does not commit each interaction as the client does; the overview's writes would
        // otherwise block the request page.
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
        // Only a processing-only report's request page has OK; report 25 is run with Preview.
        AccountSchedule.Preview().Invoke();
    end;

    /// <summary>
    /// Takes the name the run's naming hook gave, or else names the run as the hook does (report 25,
    /// printed, no record).
    /// </summary>
    local procedure AssertNamed(Expected: Text)
    var
        Filename: Text;
    begin
        SetFeature(true);
        Filename := NamingCapture.TakeNameWithoutExtension(Report::"Account Schedule");
        if Filename = '' then
            if not TryNameFinancialReportRun(Filename) then
                Error(FinancialReportNotNamedErr, Expected);
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);
    end;

    /// <summary>
    /// Peeks rather than takes, so a failure says whether the report or the period is missing.
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
        CreateFinancialReportPattern(PatternText);
        // The feature stays on while the report runs: subject and period are recorded only while it
        // can name something. The hook's name is captured; if no hook names the run, AssertNamed does.
        NamingCapture.Reset();
        if not NamingCaptureBound then
            NamingCaptureBound := BindSubscription(NamingCapture);
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

    local procedure PeriodColumnsReport(): Code[10]
    begin
        exit(TestData.CreateFinancialReport(PeriodColumnsDescriptionTok, true));
    end;

    // Described differently from PeriodColumnsReport, so a name built from the description says which ran.
    local procedure BalanceOnlyReport(): Code[10]
    begin
        exit(TestData.CreateFinancialReport(BalanceOnlyDescriptionTok, false));
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
        TestData.Initialize();
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
        PeriodColumnsDescriptionTok: Label 'Report Filename Test Periods', Locked = true;
        BalanceOnlyDescriptionTok: Label 'Report Filename Test Balances', Locked = true;
}
